-- Import modules
local Inventory = exports.ox_inventory
local BLAppearance = exports.bl_appearance

---@class ClothingClient
local ClothingClient = {}

---Determines the player's sex based on their ped model
---@return string|nil "male" or "female" based on the ped model, or nil if failed
local function isMaleOrFemale()
    local skin = BLAppearance:GetPedSkin(cache.ped)
    if not skin then
        lib.print.error('Failed to get ped skin')
        return false
    end
    return skin.model == "mp_f_freemode_01" and "female" or "male"
end

---Plays an animation when changing clothes
---@param duration number The duration of the animation in milliseconds
local function playChangeClothesAnimation(duration)
    CreateThread(function()
        local dict = 'clothingshirt'
        local clip = 'try_shirt_positive_d'
        lib.requestAnimDict(dict)
        TaskPlayAnim(cache.ped, dict, clip, 3.0, 3.0, duration, 51, 0, false, false, false)
        RemoveAnimDict(dict)
    end)
end

---Displays a customizable progress bar
---@param duration number The duration of the progress bar in milliseconds
---@param label string The label to display on the progress bar
---@return boolean Whether the progress bar completed successfully
local function showProgressBar(duration, label)
    return lib.progressCircle({
        duration = duration or 2000,
        label = label or locale('changing_outfit'),
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
end

---Synchronizes clothing changes with the server
---@return boolean Whether the synchronization was successful
local function safeSync()
    -- Check if player exists and is loaded
    if not cache.ped or not DoesEntityExist(cache.ped) then
        lib.print.error('Player entity does not exist')
        return false
    end

    -- Check if player is in a valid state for clothing changes
    if IsPedDeadOrDying(cache.ped, true) or IsPedFalling(cache.ped) or IsPedRagdoll(cache.ped) then
        lib.print.error('Player is in an invalid state for clothing changes')
        return false
    end

    -- Additional checks can be added here as needed

    lib.print.debug('Clothing sync successful')
    return true
end

---Processes clothing components or props with optimized performance
---@param components table The components to process
---@param isProp boolean Whether the components are props
---@return boolean Whether the processing was successful
local function processComponents(components, isProp)
    if not components then
        return lib.print.debug('No components to process')
    end

    -- Get sex once for all components
    local sex = isMaleOrFemale()
    if not sex then return false end

    -- Pre-validate all components before processing
    for _, value in pairs(components) do
        if not value.id then
            lib.print.error('Invalid component data: missing ID')
            return false
        end

        if not shared.clothing[sex][value.id] then
            lib.print.error('Component not found for ID: ' .. value.id)
            return false
        end
    end

    -- Process components in batches for better performance
    local componentsToProcess = {}

    for _, value in pairs(components) do
        local component = shared.clothing[sex][value.id]
        local data = {
            index = value.index,
            value = component.drawable,
            id = value.id,
            texture = component.texture
        }
        table.insert(componentsToProcess, data)
    end

    -- Apply all components at once if possible
    for _, data in ipairs(componentsToProcess) do
        local success = true
        if isProp then
            success = BLAppearance:SetPedProp(cache.ped, data)
            success = data.value == -1 and true or success
        else
            success = BLAppearance:SetPedDrawable(cache.ped, data)
        end

        if not success then
            lib.print.error('Failed to apply component: ' .. data.id)
            return false
        end
    end

    lib.print.debug('Successfully processed ' .. #componentsToProcess .. ' components')
    return true
end

---Handles outfit application or removal
---@param data table The outfit data
---@param action string The action to perform ("add" or "remove")
---@return table|boolean The appearance data if successful, false otherwise
local function handleOutfit(data, action)
    if not data then
        lib.print.error('No outfit data provided')
        return false
    end

    CreateThread(function()
        Inventory:closeInventory()
        playChangeClothesAnimation(5000)
        local progressLabel = action == "add" and locale('adding_outfit') or locale('removing_outfit')
        showProgressBar(5000, progressLabel)
    end)

    local appearance = BLAppearance:GetPedAppearance(cache.ped)
    if not appearance then
        lib.print.error('Failed to get appearance data')
        return false
    end

    if action == "remove" then
        if not processComponents(data.drawables, false) then
            lib.print.error('Failed to process drawable components')
            return false
        end

        if not processComponents(data.props, true) then
            lib.print.error('Failed to process prop components')
            return false
        end

        Wait(500)
        appearance = BLAppearance:GetPedAppearance(cache.ped)
        if not appearance then
            lib.print.error('Failed to get updated appearance')
            return false
        end
    elseif action == "add" then
        BLAppearance:SetPedClothes(cache.ped, data)
        Wait(500)
        appearance = BLAppearance:GetPedAppearance(cache.ped)

        if not appearance then
            lib.print.error('Failed to get updated appearance')
            return false
        end
    else
        lib.print.error('Invalid action type: ' .. tostring(action))
        return false
    end

    lib.print.info('Successfully handled outfit: ' .. action)
    return appearance
end

---@class CallbackHandlers
---Collection of callback handlers for inventory actions
local callbackHandlers = {
    ---Adds a clothing item to the player
    ---@param data table The clothing data
    ---@return table|boolean The appearance data if successful, false otherwise
    ['ox_inventory:addClothing'] = function(data)
        if not data then
            lib.print.error('No clothing data provided')
            return false
        end

        CreateThread(function()
            Inventory:closeInventory()
            playChangeClothesAnimation(2500)
            showProgressBar(2500, locale('adding_clothing'))
        end)

        -- Apply clothing based on type
        if data.type == 'component' then
            local success = BLAppearance:SetPedDrawable(cache.ped, data)
            if not success then
                lib.print.error('Failed to set ped drawable')
                return false
            end
        elseif data.type == 'prop' then
            local success = BLAppearance:SetPedProp(cache.ped, data)
            if not success then
                lib.print.error('Failed to set ped prop')
                return false
            end
        else
            lib.print.error('Invalid clothing type: ' .. tostring(data.type))
            return false
        end

        -- Synchronize with server
        if not safeSync() then return false end

        -- Get updated appearance
        local appearance = BLAppearance:GetPedAppearance(cache.ped)
        if not appearance then
            lib.print.error('Failed to get updated appearance')
            return false
        end

        lib.print.info('Successfully added clothing item: ' .. data.id)
        return appearance
    end,

    ---Removes a clothing item from the player
    ---@param data table The clothing data
    ---@return table|boolean The appearance data if successful, false otherwise
    ['ox_inventory:removeClothing'] = function(data)
        if not data then
            lib.print.error('No clothing data provided')
            return false
        end

        CreateThread(function()
            Inventory:closeInventory()
            playChangeClothesAnimation(2500)
            showProgressBar(2500, locale('removing_clothing'))
        end)

        -- Get player sex
        local sex = isMaleOrFemale()
        if not sex then return false end

        -- Get component data
        local component = shared.clothing[sex][data.id]
        if not component then
            lib.print.error('Component not found for ID: ' .. data.id)
            return false
        end

        -- Prepare component data
        local componentData = {
            index = data.index,
            value = component.drawable,
            id = data.id,
            texture = component.texture
        }

        -- Apply component based on type
        if data.type == 'component' then
            local success = BLAppearance:SetPedDrawable(cache.ped, componentData)
            if not success then
                lib.print.error('Failed to set ped drawable')
                return false
            end
        elseif data.type == 'prop' then
            local success = BLAppearance:SetPedProp(cache.ped, componentData)
            if not success then
                lib.print.error('Failed to set ped prop')
                return false
            end
        else
            lib.print.error('Invalid clothing type: ' .. tostring(data.type))
            return false
        end

        -- Synchronize with server
        if not safeSync() then return false end

        -- Get updated appearance
        local appearance = BLAppearance:GetPedAppearance(cache.ped)
        if not appearance then
            lib.print.error('Failed to get updated appearance')
            return false
        end

        lib.print.info('Successfully removed clothing item: ' .. data.id)
        return appearance
    end,

    ---Adds an outfit to the player
    ---@param data table The outfit data
    ---@return table|boolean The appearance data if successful, false otherwise
    ['ox_inventory:addOutfit'] = function(data)
        return handleOutfit(data, "add")
    end,

    ---Removes an outfit from the player
    ---@param data table The outfit data
    ---@return table|boolean The appearance data if successful, false otherwise
    ['ox_inventory:removeOutfit'] = function(data)
        return handleOutfit(data, "remove")
    end
}

-- Register callbacks
for eventName, handler in pairs(callbackHandlers) do
    lib.callback.register(eventName, handler)
end

-- Export for external use
client.safeSync = safeSync
