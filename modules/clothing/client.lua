local function isMaleOrFemale()
    local skin = exports.bl_appearance:GetPedSkin(cache.ped)
    if not skin then
        error('Failed to get ped skin')
        return nil
    end
    return (skin.model == "mp_f_freemode_01") and "female" or "male"
end

local function playChangeClothesAnimation()
    CreateThread(function()
        local dict = 'clothingshirt'
        local clip = 'try_shirt_positive_d'
        lib.requestAnimDict(dict)
        TaskPlayAnim(cache.ped, dict, clip, 3.0, 3.0, 2000, 51, 0, false, false, false)
        RemoveAnimDict(dict)
    end)
end

local function showProgressBar(duration, label)
    return lib.progressBar({
        duration = duration or 2000,
        label = label or 'Changement de tenue...',
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        }
    })
end

local function safeSync()
    local targetPed = client.getPed()

    if targetPed == 0 then
        error('Invalid target ped')
        return false
    end

    local success, result = pcall(function()
        local outfit = exports.bl_appearance:GetPedAppearance(cache.ped)
        if not outfit then
            error('Failed to get ped appearance')
            return false
        end
        exports.bl_appearance:SetPedAppearance(targetPed, outfit)
        TriggerServerEvent('ox_inventory:syncPlayerClothes')
        return true
    end)

    if not success then
        error('Failed to sync appearance: ' .. tostring(result))
        return false
    end

    return true
end

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

            if isProp then
                exports.bl_appearance:SetPedProp(cache.ped, {
                    index = value.index,
                    value = component.drawable,
                    id = value.id,
                    texture = component.texture
                })
            else
                exports.bl_appearance:SetPedDrawable(cache.ped, {
                    index = value.index,
                    value = component.drawable,
                    id = value.id,
                    texture = component.texture
                })
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

local function handleOutfit(data, action)
    if not data then
        error('No outfit data provided')
        return false
    end

    TriggerEvent('ox_inventory:closeInventory')

    playChangeClothesAnimation()
    local progressSuccess = showProgressBar()

    if not progressSuccess then
        error('Progress cancelled by user')
        return false
    end

    local success, result = pcall(function()
        if action == "remove" then
            if not processComponents(data.drawables, false) then return false end
            if not processComponents(data.props, true) then return false end
        elseif action == "add" then
            exports.bl_appearance:SetPedClothes(cache.ped, data)
        else
            error('Invalid action type: ' .. tostring(action))
            return false
        end

        if not safeSync() then return false end
        return exports.bl_appearance:GetPedAppearance(cache.ped)
    end)

    if not success then
        error('Failed to handle outfit: ' .. tostring(result))
        return false
    end

    return result
end

local callbackHandlers = {
    ['ox_inventory:addClothing'] = function(data)
        if not data then
            error('No clothing data provided')
            return false
        end

        playChangeClothesAnimation()
        local progressSuccess = showProgressBar(1000, 'Ajout du vêtement...')

        if not progressSuccess then return false end

        local success, result = pcall(function()
            if data.type == 'component' then
                exports.bl_appearance:SetPedDrawable(cache.ped, data)
            elseif data.type == 'prop' then
                exports.bl_appearance:SetPedProp(cache.ped, data)
            else
                error('Invalid clothing type: ' .. tostring(data.type))
                return false
            end

            if not safeSync() then return false end
            return exports.bl_appearance:GetPedAppearance(cache.ped)
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

        playChangeClothesAnimation()
        local progressSuccess = showProgressBar(1000, 'Retrait du vêtement...')

        if not progressSuccess then return false end

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
                exports.bl_appearance:SetPedDrawable(cache.ped, componentData)
            elseif data.type == 'prop' then
                exports.bl_appearance:SetPedProp(cache.ped, componentData)
            else
                error('Invalid clothing type: ' .. tostring(data.type))
                return false
            end

            if not safeSync() then return false end
            return exports.bl_appearance:GetPedAppearance(cache.ped)
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

for eventName, handler in pairs(callbackHandlers) do
    lib.callback.register(eventName, handler)
end

client.safeSync = safeSync
