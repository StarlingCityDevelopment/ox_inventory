---@class ClothingServer
local clothing = {}

local QBox = exports.qbx_core
local BlAppearance = exports.bl_appearance
local Inventory = exports.ox_inventory
local sharedClothing = shared.clothing
local sharedClothingSlots = sharedClothing.slots

-- Cache for player appearance data to reduce database calls
local appearanceCache = {}

---Counts items in a table
---@param items table The table of items to count
---@return number The number of items in the table
local function countItems(items)
    if type(items) ~= 'table' then
        lib.print.error('Invalid items parameter: expected table, got ' .. type(items))
        return 0
    end
    local count = 0
    for _ in pairs(items) do count = count + 1 end
    return count
end

---Determines sex from ped model
---@param model number The ped model hash
---@return string "male" or "female" based on the model hash
local function getSexFromModel(model)
    return model == GetHashKey('mp_m_freemode_01') and 'male' or 'female'
end

---Validates clothing data
---@param data table The clothing data to validate
---@param sex string The sex to validate against ("male" or "female")
---@param itemType string The type of clothing item ("component" or "prop")
---@return boolean Whether the data is valid
local function validateClothingData(data, sex, itemType)
    if not data then
        lib.print.error('No clothing data provided')
        return false
    end
    if not sex then
        lib.print.error('No sex specified for clothing validation')
        return false
    end
    if not itemType then
        lib.print.error('No item type specified for clothing validation')
        return false
    end
    if not sharedClothing[sex] then
        lib.print.error('Invalid sex specified: ' .. tostring(sex))
        return false
    end
    return true
end

---Processes clothing items into inventory with optimized performance
---@param clothes table The clothes inventory
---@param sex string The sex of the player ("male" or "female")
---@param itemSet table The set of clothing items to process
---@param itemType string The type of clothing items ("component" or "prop")
---@return boolean Whether the processing was successful
local function processClothingItems(clothes, sex, itemSet, itemType)
    if not validateClothingData(itemSet, sex, itemType) then return false end

    -- Pre-validate all items before processing to avoid partial updates
    for key, _ in pairs(itemSet) do
        local slotKey = 'clothes_' .. key
        if sharedClothingSlots[slotKey] and not sharedClothing[sex][key] then
            lib.print.error('No base clothing found for key: ' .. key)
            return false
        end
    end

    -- Process items in batches for better performance
    local itemsToAdd = {}

    for key, data in pairs(itemSet) do
        local slotKey = 'clothes_' .. key
        if sharedClothingSlots[slotKey] then
            local baseClothing = sharedClothing[sex][key]
            if data.value ~= baseClothing.drawable then
                data.type = itemType
                table.insert(itemsToAdd, {
                    slot = slotKey,
                    count = 1,
                    metadata = data,
                    slotId = sharedClothingSlots[slotKey]
                })
            end
        end
    end

    -- Add items in a single batch if possible
    local success = true
    for _, item in ipairs(itemsToAdd) do
        if not Inventory:AddItem(clothes, item.slot, item.count, item.metadata, item.slotId) then
            success = false
            lib.print.error('Failed to add item to inventory: ' .. item.slot)
            break
        end
    end

    if not success then
        lib.print.error('Failed to process clothing items')
        return false
    end

    return true
end

-- Cache for clothing inventories to reduce database calls
local clothesInventoryCache = {}

---Retrieves clothing inventory for a player with caching
---@param src number The source of the player
---@param identifier string The identifier of the player
---@param forceRefresh boolean Whether to force a refresh of the cache
---@return table|nil The clothes inventory or nil if failed
function clothing.getClothesInv(src, identifier, forceRefresh)
    if not src or not identifier then
        lib.print.error('Invalid parameters for getClothesInv')
        return false
    end

    local cacheKey = src .. '_' .. identifier

    -- Return from cache if available and not forcing refresh
    if not forceRefresh and clothesInventoryCache[cacheKey] then
        lib.print.debug('Retrieved clothes inventory from cache for: ' .. cacheKey)
        return clothesInventoryCache[cacheKey]
    end

    local success, result = pcall(function()
        return require('modules.inventory.server')('clothes_' .. identifier, src, true)
    end)

    if not success then
        lib.print.error('Failed to get clothes inventory: ' .. tostring(result))
        return false
    end

    -- Cache the result
    clothesInventoryCache[cacheKey] = result

    -- Set up cache invalidation after 5 minutes
    SetTimeout(300000, function()
        clothesInventoryCache[cacheKey] = nil
        lib.print.debug('Invalidated clothes inventory cache for: ' .. cacheKey)
    end)

    return result
end

---Syncs player clothing with inventory
---@param src number The source of the player
---@param appearance table|nil The appearance data of the player (optional)
---@return boolean Whether the sync was successful
local function syncPlayerClothes(src, appearance)
    -- Get player data
    local player = QBox:GetPlayer(src)
    if not player then
        lib.print.error('Player not found')
    end

    local citizenid = player.PlayerData.citizenid

    -- Get appearance data if not provided
    if not appearance then
        -- Check cache first
        if appearanceCache[citizenid] then
            appearance = appearanceCache[citizenid]
            lib.print.debug('Using cached appearance for player: ' .. citizenid)
        else
            appearance = exports.bl_appearance:GetPlayerAppearance(citizenid)
            if not appearance then
                lib.print.error('Failed to get player appearance')
            end

            -- Cache the appearance data
            appearanceCache[citizenid] = appearance

            -- Set up cache invalidation after 5 minutes
            SetTimeout(300000, function()
                appearanceCache[citizenid] = nil
                lib.print.debug('Invalidated appearance cache for: ' .. citizenid)
            end)
        end
    end

    -- Get clothes inventory
    local clothes = clothing.getClothesInv(src, citizenid)
    if not clothes then
        lib.print.error('Failed to get clothes inventory')
    end

    -- Determine sex from model
    local sex = getSexFromModel(appearance.model)
    if not sex then
        lib.print.error('Failed to get sex from model')
    end

    -- Clear existing inventory
    Inventory:ClearInventory(clothes, 'clothes_outfits')

    -- Process prop items
    if not processClothingItems(clothes, sex, appearance.props, 'prop') then
        lib.print.error('Failed to process prop items')
    end

    -- Process drawable items
    if not processClothingItems(clothes, sex, appearance.drawables, 'component') then
        lib.print.error('Failed to process drawable items')
    end

    -- Sync slots with clients
    for i = 1, 16 do
        clothes:syncSlotsWithClients({
            slots = { item = { slot = i } },
            inventory = clothes.id,
        }, true)
    end

    lib.print.info('Successfully synced player clothes for: ' .. citizenid)
    return true
end

-- Callback to get inventory clothes
lib.callback.register('ox_inventory:getInventoryClothes', function(source)
    local success, result = pcall(function()
        local player = QBox:GetPlayer(source)
        if not player then
            error('Player not found')
            return false
        end

        local clothes = clothing.getClothesInv(source, player.PlayerData.citizenid)
        if not clothes then
            error('Failed to get clothes inventory')
            return false
        end

        return {
            id = clothes.id,
            label = clothes.label,
            type = clothes.type,
            slots = clothes.slots,
            weight = 0,
            maxWeight = 10000,
            items = clothes.items or {}
        }
    end)

    if not success then
        error('Failed to get inventory clothes: ' .. tostring(result))
        return false
    end
    return result
end)

-- Adds a clothing item
function clothing.addClothing(payload)
    local success, result = pcall(function()
        if not payload.source then
            error('No source provided in payload')
            return false
        end
        local player = QBox:GetPlayer(payload.source)
        if not player then
            error('Player not found')
            return false
        end
        if not payload.fromSlot.metadata then
            error('No metadata in payload slot')
            return false
        end

        local newAppearance = lib.callback.await('ox_inventory:addClothing', payload.source, payload.fromSlot.metadata)
        if not newAppearance then
            error('Failed to get new appearance')
            return false
        end

        BlAppearance:SavePlayerAppearance(player.PlayerData.citizenid, newAppearance)
        return true
    end)

    if not success then
        error('Failed to add clothing: ' .. tostring(result))
        return false
    end
    return result
end

---Removes a clothing item from the player's appearance
---@param payload table The payload containing the clothing data
---@return boolean Whether the clothing was removed successfully
function clothing.removeClothing(payload)
    if not payload.source then
        lib.print.error('No source provided in payload')
        return false
    end

    local player = QBox:GetPlayer(payload.source)
    if not player then
        lib.print.error('Player not found')
        return false
    end

    if not payload.fromSlot.metadata then
        lib.print.error('No metadata in payload slot')
        return false
    end

    local appearance
    local citizenid = player.PlayerData.citizenid

    if appearanceCache[citizenid] then
        appearance = appearanceCache[citizenid]
        lib.print.debug('Using cached appearance for player: ' .. citizenid)
    else
        appearance = BlAppearance:GetPlayerAppearance(citizenid)
        if not appearance then
            lib.print.error('Failed to get appearance data')
            return false
        end
    end

    local sex = getSexFromModel(appearance.model)
    if not sex then
        lib.print.error('Failed to determine sex from model')
        return false
    end

    local data = payload.fromSlot.metadata
    if data.type == 'component' then
        appearance.drawables[data.id] = {
            id = data.id,
            value = shared.clothing[sex][data.id].drawable,
            texture = shared.clothing[sex][data.id].texture,
            index = data.index
        }
        lib.print.debug('Removed component: ' .. data.id)
    elseif data.type == 'prop' then
        appearance.props[data.id] = {
            id = data.id,
            value = shared.clothing[sex][data.id].drawable,
            texture = shared.clothing[sex][data.id].texture,
            index = data.index
        }
        lib.print.debug('Removed prop: ' .. data.id)
    else
        lib.print.error('Invalid clothing type: ' .. tostring(data.type))
        return false
    end

    local newAppearance = lib.callback.await('ox_inventory:removeClothing', payload.source, payload.fromSlot.metadata)
    if not newAppearance then
        error('Failed to get new appearance')
        return false
    end

    local success = BlAppearance:SetPlayerAppearance(citizenid, newAppearance)
    if not success then
        lib.print.error('Failed to save new appearance data')
        return false
    end

    appearanceCache[citizenid] = newAppearance
    lib.print.info('Successfully removed clothing item for player: ' .. citizenid)
    return true
end

function clothing.addOutfit(payload)
    local success, result = pcall(function()
        local restrictedProps = { 'mouth', 'lhand', 'rhand' }
        local restrictedDrawables = { 'hair', 'face' }

        if payload.fromSlot.metadata.outfit.props then
            for _, prop in ipairs(restrictedProps) do
                payload.fromSlot.metadata.outfit.props[prop] = nil
            end
        end
        if payload.fromSlot.metadata.outfit.drawables then
            for _, drawable in ipairs(restrictedDrawables) do
                payload.fromSlot.metadata.outfit.drawables[drawable] = nil
            end
        end

        local player = QBox:GetPlayer(payload.source)
        if not player then
            error('Player not found')
            return false
        end

        local citizenid = player.PlayerData.citizenid
        local clothes = clothing.getClothesInv(payload.source, citizenid)
        local inv = Inventory:GetInventory(payload.source)

        local clothesItemCount = countItems(clothes.items)
        if clothesItemCount > 0 then
            if (countItems(inv.items) + clothesItemCount) >= shared.playerslots then
                lib.notify(payload.source, {
                    type = 'error',
                    title = 'Inventaire',
                    description = 'Vous n\'avez pas assez de place dans votre inventaire.'
                })
                return false
            end
            for _, item in pairs(clothes.items) do
                Inventory:RemoveItem(clothes, item.slot, 1)
                Inventory:AddItem(inv, item.name, 1, item.metadata)
            end
        end

        for i = 1, 16 do
            clothes:syncSlotsWithClients({ slots = { item = { slot = i } }, inventory = clothes.id }, true)
        end

        local newAppearance = lib.callback.await('ox_inventory:addOutfit', payload.source, payload.fromSlot.metadata.outfit)
        if not newAppearance then
            error('Failed to get new appearance')
            return false
        end

        BlAppearance:SavePlayerAppearance(citizenid, newAppearance)
        CreateThread(function()
            Wait(2000)
            syncPlayerClothes(payload.source, newAppearance)
        end)
        return true
    end)

    if not success then
        error('Failed to add outfit: ' .. tostring(result))
        return false
    end
    return result
end

function clothing.removeOutfit(payload)
    local success, result = pcall(function()
        if not payload.source then
            error('No source provided in payload')
            return false
        end

        local player = QBox:GetPlayer(payload.source)
        if not player then
            error('Player not found')
            return false
        end

        local restrictedProps = { 'mouth', 'lhand', 'rhand' }
        local restrictedDrawables = { 'hair', 'face' }

        if payload.fromSlot.metadata.outfit.props then
            for _, prop in ipairs(restrictedProps) do
                payload.fromSlot.metadata.outfit.props[prop] = nil
            end
        end
        if payload.fromSlot.metadata.outfit.drawables then
            for _, drawable in ipairs(restrictedDrawables) do
                payload.fromSlot.metadata.outfit.drawables[drawable] = nil
            end
        end

        local citizenid = player.PlayerData.citizenid
        local clothes = clothing.getClothesInv(payload.source, citizenid)
        if not clothes then
            error('Failed to get clothes inventory')
            return false
        end

        local newAppearance = lib.callback.await('ox_inventory:removeOutfit', payload.source,
            payload.fromSlot.metadata.outfit)
        if not newAppearance then
            error('Failed to get new appearance')
            return false
        end

        CreateThread(function()
            Wait(500)
            Inventory:SetMetadata(payload.toInventory, (type(payload.toSlot) == 'table' and payload.toSlot.slot or payload.toSlot), {
                outfit = { drawables = newAppearance.drawables, props = newAppearance.props }
            })
            Inventory:ClearInventory(clothes, 'clothes_outfits')
        end)

        for i = 1, 16 do
            clothes:syncSlotsWithClients({ slots = { item = { slot = i } }, inventory = clothes.id }, true)
        end

        BlAppearance:SavePlayerAppearance(citizenid, newAppearance)
        return true
    end)

    if not success then
        error('Failed to remove outfit: ' .. tostring(result))
        return false
    end
    return result
end

return clothing