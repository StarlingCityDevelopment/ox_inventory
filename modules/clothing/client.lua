-- START CLIENT-SIDE

local Inventory = exports.ox_inventory
local BLAppearance = exports.bl_appearance

-- Determines the player's sex based on their ped model
local function isMaleOrFemale()
    local skin = BLAppearance:GetPedSkin(cache.ped)
    if not skin then
        error('Failed to get ped skin')
        return nil
    end
    return skin.model == "mp_f_freemode_01" and "female" or "male"
end

-- Plays an animation when changing clothes
local function playChangeClothesAnimation(duration)
    CreateThread(function()
        local dict = 'clothingshirt'
        local clip = 'try_shirt_positive_d'
        lib.requestAnimDict(dict)
        TaskPlayAnim(cache.ped, dict, clip, 3.0, 3.0, duration, 51, 0, false, false, false)
        RemoveAnimDict(dict)
    end)
end

-- Displays a customizable progress bar
local function showProgressBar(duration, label)
    return lib.progressCircle({
        duration = duration or 2000,
        label = label or 'Changement de tenue...',
        useWhileDead = false,
        canCancel = false,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
end

-- Placeholder for synchronization logic (can be expanded)
local function safeSync()
    return true
end

-- Processes clothing components or props with error handling
local function processComponents(components, isProp)
    if not components then return false end

    local success, result = pcall(function()
        for _, value in pairs(components) do
            if not value.id then
                error('Invalid component data: missing ID')
                return false
            end

            local sex = isMaleOrFemale()
            if not sex then return false end

            local component = shared.clothing[sex][value.id]
            if not component then
                error('Component not found for ID: ' .. value.id)
                return false
            end

            local data = {
                index = value.index,
                value = component.drawable,
                id = value.id,
                texture = component.texture
            }
            if isProp then
                BLAppearance:SetPedProp(cache.ped, data)
            else
                BLAppearance:SetPedDrawable(cache.ped, data)
            end
        end
        return true
    end)

    if not success then
        error('Failed to process components: ' .. tostring(result))
        return false
    end
    return true
end

-- Handles outfit application or removal
local function handleOutfit(data, action)
    if not data then
        error('No outfit data provided')
        return false
    end

    CreateThread(function()
        Inventory:closeInventory()
        playChangeClothesAnimation(5000)
        showProgressBar(5000, action == "add" and 'Ajout de la tenue...' or 'Retrait de la tenue...')
    end)

    local success, result = pcall(function()
        local appearance = BLAppearance:GetPedAppearance(cache.ped)
        if not appearance then return false end

        if action == "remove" then
            if not processComponents(data.drawables, false) then return false end
            if not processComponents(data.props, true) then return false end
        elseif action == "add" then
            BLAppearance:SetPedClothes(cache.ped, data)
            Wait(500)
            appearance = BLAppearance:GetPedAppearance(cache.ped)
        else
            error('Invalid action type: ' .. tostring(action))
            return false
        end
        return appearance
    end)

    if not success then
        error('Failed to handle outfit: ' .. tostring(result))
        return false
    end
    return result
end

-- Callback handlers for inventory actions
local callbackHandlers = {
    ['ox_inventory:addClothing'] = function(data)
        if not data then
            error('No clothing data provided')
            return false
        end

        CreateThread(function()
            Inventory:closeInventory()
            playChangeClothesAnimation(2500)
            showProgressBar(2500, 'Ajout du vêtement...')
        end)

        local success, result = pcall(function()
            if data.type == 'component' then
                BLAppearance:SetPedDrawable(cache.ped, data)
            elseif data.type == 'prop' then
                BLAppearance:SetPedProp(cache.ped, data)
            else
                error('Invalid clothing type: ' .. tostring(data.type))
                return false
            end
            if not safeSync() then return false end
            return BLAppearance:GetPedAppearance(cache.ped)
        end)

        if not success then
            error('Failed to add clothing: ' .. tostring(result))
            return false
        end
        return result
    end,
    ['ox_inventory:removeClothing'] = function(data)
        if not data then
            error('No clothing data provided')
            return false
        end

        CreateThread(function()
            Inventory:closeInventory()
            playChangeClothesAnimation(2500)
            showProgressBar(2500, 'Retrait du vêtement...')
        end)

        local success, result = pcall(function()
            local sex = isMaleOrFemale()
            if not sex then return false end

            local component = shared.clothing[sex][data.id]
            if not component then
                error('Component not found for ID: ' .. data.id)
                return false
            end

            local componentData = {
                index = data.index,
                value = component.drawable,
                id = data.id,
                texture = component.texture
            }

            if data.type == 'component' then
                BLAppearance:SetPedDrawable(cache.ped, componentData)
            elseif data.type == 'prop' then
                BLAppearance:SetPedProp(cache.ped, componentData)
            else
                error('Invalid clothing type: ' .. tostring(data.type))
                return false
            end
            if not safeSync() then return false end
            return BLAppearance:GetPedAppearance(cache.ped)
        end)

        if not success then
            error('Failed to remove clothing: ' .. tostring(result))
            return false
        end
        return result
    end,
    ['ox_inventory:addOutfit'] = function(data)
        return handleOutfit(data, "add")
    end,
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

-- END CLIENT-SIDE