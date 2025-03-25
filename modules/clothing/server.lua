-- START SERVER-SIDE

local clothing = {}

local QBox = exports.qbx_core
local BlAppearance = exports.bl_appearance
local Inventory = exports.ox_inventory
local sharedClothing = shared.clothing
local sharedClothingSlots = sharedClothing.slots

-- Counts items in a table
local function countItems(items)
    if type(items) ~= 'table' then
        error('Invalid items parameter: expected table, got ' .. type(items))
        return 0
    end
    local count = 0
    for _ in pairs(items) do count = count + 1 end
    return count
end

-- Determines sex from ped model
local function getSexFromModel(model)
    return model == GetHashKey('mp_m_freemode_01') and 'male' or 'female'
end

-- Validates clothing data
local function validateClothingData(data, sex, itemType)
    if not data then
        error('No clothing data provided')
        return false
    end
    if not sex then
        error('No sex specified for clothing validation')
        return false
    end
    if not itemType then
        error('No item type specified for clothing validation')
        return false
    end
    if not sharedClothing[sex] then
        error('Invalid sex specified: ' .. tostring(sex))
        return false
    end
    return true
end

-- Processes clothing items into inventory
local function processClothingItems(clothes, sex, itemSet, itemType)
    if not validateClothingData(itemSet, sex, itemType) then return false end

    local success, result = pcall(function()
        for key, data in pairs(itemSet) do
            local slotKey = 'clothes_' .. key
            if sharedClothingSlots[slotKey] then
                local baseClothing = sharedClothing[sex][key]
                if not baseClothing then
                    error('No base clothing found for key: ' .. key)
                    return false
                end
                if data.value ~= baseClothing.drawable then
                    data.type = itemType
                    Inventory:AddItem(clothes, slotKey, 1, data, sharedClothingSlots[slotKey])
                end
            end
        end
        return true
    end)

    if not success then
        error('Failed to process clothing items: ' .. tostring(result))
        return false
    end
    return true
end

-- Retrieves clothing inventory for a player
function clothing.getClothesInv(src, identifier)
    if not src or not identifier then
        error('Invalid parameters for getClothesInv')
        return nil
    end

    local success, result = pcall(function()
        return require('modules.inventory.server')('clothes_' .. identifier, src, true)
    end)

    if not success then
        error('Failed to get clothes inventory: ' .. tostring(result))
        return nil
    end
    return result
end

-- Syncs player clothing with inventory
local function syncPlayerClothes(src, appearance)
    local success, result = pcall(function()
        local player = QBox:GetPlayer(src)
        if not player then
            error('Player not found')
            return false
        end

        local citizenid = player.PlayerData.citizenid
        if not appearance then
            appearance = exports.bl_appearance:GetPlayerAppearance(citizenid)
            if not appearance then
                error('Failed to get player appearance')
                return false
            end
        end

        local clothes = clothing.getClothesInv(src, citizenid)
        if not clothes then
            error('Failed to get clothes inventory')
            return false
        end

        local sex = getSexFromModel(appearance.model)
        if not sex then
            error('Failed to get sex from model')
            return false
        end

        Inventory:ClearInventory(clothes, 'clothes_outfits')

        if not processClothingItems(clothes, sex, appearance.props, 'prop') then
            error('Failed to process prop items')
            return false
        end

        if not processClothingItems(clothes, sex, appearance.drawables, 'component') then
            error('Failed to process drawable items')
            return false
        end

        for i = 1, 16 do
            clothes:syncSlotsWithClients({
                slots = { item = { slot = i } },
                inventory = clothes.id,
            }, true)
        end

        return true
    end)

    if not success then
        error('Failed to sync player clothes: ' .. tostring(result))
        return false
    end
    return result
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

-- Removes a clothing item
function clothing.removeClothing(payload)
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

        local newAppearance = lib.callback.await('ox_inventory:removeClothing', payload.source, payload.fromSlot
            .metadata)
        if not newAppearance then
            error('Failed to get new appearance')
            return false
        end

        BlAppearance:SavePlayerAppearance(player.PlayerData.citizenid, newAppearance)
        return true
    end)

    if not success then
        error('Failed to remove clothing: ' .. tostring(result))
        return false
    end
    return result
end

-- Adds an outfit
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

-- Removes an outfit
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
            Inventory:SetMetadata(payload.toInventory,
                (type(payload.toSlot) == 'table' and payload.toSlot.slot or payload.toSlot), {
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

-- END SERVER-SIDE
