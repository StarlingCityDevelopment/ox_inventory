if not lib then return end

local clothes = {
    data = {},
    stagedChanges = {},
    isInventoryOpen = false,
}
local VPed = require 'modules.VPed.client'

local CLOTHING_ANIM_DICT = 'clothingtie'
local CLOTHING_ANIM_CLIP = 'try_tie_positive_a'

local function getGender()
    local model = GetEntityModel(PlayerPedId())
    if model == joaat('mp_m_freemode_01') then
        return "male"
    end
    return "female"
end

local function countStagedChanges()
    local count = 0
    for _ in pairs(clothes.stagedChanges) do
        count = count + 1
    end
    return count
end

function clothes.init()
    local playerClothes = {}
    local gender = getGender()
    local defaultClothes = shared.clothing[gender]

    if not defaultClothes then
        clothes.data = {}
        return
    end

    for index, name in pairs(shared.componentMap) do
        local drawable = GetPedDrawableVariation(PlayerPedId(), index)
        local texture = GetPedTextureVariation(PlayerPedId(), index)

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or 0
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or 0

        if drawable ~= defaultDrawable or texture ~= defaultTexture then
            playerClothes[name] = {
                component_id = index,
                drawable = drawable,
                texture = texture,
            }
        end
    end

    for index, name in pairs(shared.propMap) do
        local drawable = GetPedPropIndex(PlayerPedId(), index) or 0
        local texture = GetPedPropTextureIndex(PlayerPedId(), index) or 0

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or -1
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or -1

        if drawable ~= defaultDrawable or texture ~= defaultTexture then
            playerClothes[name] = {
                prop_id = index,
                drawable = drawable,
                texture = texture,
            }
        end
    end

    clothes.data = playerClothes
end

function clothes.check()
    local changedClothes = {}

    local gender = getGender()
    local defaultClothes = shared.clothing[gender]

    if not defaultClothes then
        return false
    end

    for index, name in pairs(shared.componentMap) do
        local actualDrawable = GetPedDrawableVariation(PlayerPedId(), index)
        local actualTexture = GetPedTextureVariation(PlayerPedId(), index)

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or 0
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or 0

        local storedData = clothes.data[name]

        if storedData then
            if storedData.drawable ~= actualDrawable or storedData.texture ~= actualTexture then
                if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                    changedClothes[name] = {
                        component_id = index,
                        drawable = actualDrawable,
                        texture = actualTexture,
                    }
                end
            end
        else
            if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                changedClothes[name] = {
                    component_id = index,
                    drawable = actualDrawable,
                    texture = actualTexture,
                }
            end
        end
    end

    for index, name in pairs(shared.propMap) do
        local actualDrawable = GetPedPropIndex(PlayerPedId(), index) or 0
        local actualTexture = GetPedPropTextureIndex(PlayerPedId(), index) or 0

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or -1
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or -1

        local storedData = clothes.data[name]

        if storedData then
            if storedData.drawable ~= actualDrawable or storedData.texture ~= actualTexture then
                if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                    changedClothes[name] = {
                        prop_id = index,
                        drawable = actualDrawable,
                        texture = actualTexture,
                    }
                end
            end
        else
            if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                changedClothes[name] = {
                    prop_id = index,
                    drawable = actualDrawable,
                    texture = actualTexture,
                }
            end
        end
    end

    local changedCount = 0
    for _ in pairs(changedClothes) do changedCount = changedCount + 1 end

    if changedCount > 0 then
        local input = lib.inputDialog('Changement de vêtements',
            {
                {
                    type = 'select',
                    label = 'Type de changement',
                    options = {
                        { value = 'clothes', label = 'Vêtements' },
                        { value = 'outfit',  label = 'Outfit' }
                    },
                    default = 'clothes',
                    clearable = false,
                    required = true,
                }
            })

        if not input or not input[1] then
            return false
        end

        local success = lib.callback.await('ox_inventory:checkClothes', 2500, changedClothes, input[1])
        if not success then
            return false
        end

        for index, name in pairs(shared.componentMap) do
            if clothes.data[name] then
                SetPedComponentVariation(PlayerPedId(), index, clothes.data[name].drawable, clothes.data[name].texture, 0)
            else
                local defaultData = defaultClothes[name]
                if defaultData then
                    SetPedComponentVariation(PlayerPedId(), index, defaultData.drawable, defaultData.texture, 0)
                else
                    SetPedComponentVariation(PlayerPedId(), index, 0, 0, 0)
                end
            end
        end

        for index, name in pairs(shared.propMap) do
            if clothes.data[name] then
                if clothes.data[name].drawable == -1 then
                    ClearPedProp(PlayerPedId(), index)
                else
                    SetPedPropIndex(PlayerPedId(), index, clothes.data[name].drawable, clothes.data[name].texture, true)
                end
            else
                local defaultData = defaultClothes[name]
                if defaultData then
                    if defaultData.drawable == -1 then
                        ClearPedProp(PlayerPedId(), index)
                    else
                        SetPedPropIndex(PlayerPedId(), index, defaultData.drawable, defaultData.texture, true)
                    end
                else
                    ClearPedProp(PlayerPedId(), index)
                end
            end
        end

        return true
    end

    return false
end

function clothes.sync()
    local success = lib.callback.await('ox_inventory:syncClothes', 5000, clothes.data)
    if not success then
        return false
    end
    return true
end

function clothes.setInventoryOpen(isOpen)
    clothes.isInventoryOpen = isOpen

    if not isOpen then
        clothes.applyChangesToPlayer()
        clothes.stagedChanges = {}
    else
        clothes.stagedChanges = {}
        clothes.applyStagedChangesToVPed()
    end
end

function clothes.applyChangesToPlayer()
    local gender = getGender()
    local defaultClothes = shared.clothing[gender]

    local finalState = {}
    local hasActualChanges = false

    for name, data in pairs(clothes.data) do
        finalState[name] = data
    end

    for name, change in pairs(clothes.stagedChanges) do
        if change == "REMOVED" then
            finalState[name] = nil
        else
            finalState[name] = change
        end
    end

    for name, finalData in pairs(finalState) do
        if not clothes.data[name] or
            clothes.data[name].drawable ~= finalData.drawable or
            clothes.data[name].texture ~= finalData.texture then
            hasActualChanges = true
            break
        end
    end

    if not hasActualChanges then
        for name, currentData in pairs(clothes.data) do
            if not finalState[name] then
                hasActualChanges = true
                break
            end
        end
    end

    if not hasActualChanges then
        return true
    end

    if countStagedChanges() > 0 then
        LocalPlayer.state.invBusy = true
        lib.requestAnimDict(CLOTHING_ANIM_DICT, 2500)
        lib.progressCircle({
            duration = math.max(2000, countStagedChanges() * 500),
            position = 'middle',
            label = 'Application des changements...',
            useWhileDead = false,
            canCancel = false,
            anim = {
                dict = CLOTHING_ANIM_DICT,
                clip = CLOTHING_ANIM_CLIP
            }
        })
    end

    for name, change in pairs(clothes.stagedChanges) do
        if change == "REMOVED" then
            if clothes.data[name] then
                if clothes.data[name].component_id then
                    local componentId = clothes.data[name].component_id
                    local defaultData = defaultClothes and defaultClothes[name]
                    if defaultData then
                        SetPedComponentVariation(PlayerPedId(), componentId, defaultData.drawable, defaultData.texture, 0)
                    else
                        SetPedComponentVariation(PlayerPedId(), componentId, 0, 0, 0)
                    end
                elseif clothes.data[name].prop_id then
                    local propId = clothes.data[name].prop_id
                    local defaultData = defaultClothes and defaultClothes[name]
                    if defaultData then
                        if defaultData.drawable == -1 then
                            ClearPedProp(PlayerPedId(), propId)
                        else
                            SetPedPropIndex(PlayerPedId(), propId, defaultData.drawable, defaultData.texture, true)
                        end
                    else
                        ClearPedProp(PlayerPedId(), propId)
                    end
                end
                clothes.data[name] = nil
            end
        elseif change.component_id then
            SetPedComponentVariation(PlayerPedId(), change.component_id, change.drawable, change.texture, 0)
            clothes.data[name] = change
        elseif change.prop_id then
            if change.drawable == -1 then
                ClearPedProp(PlayerPedId(), change.prop_id)
            else
                SetPedPropIndex(PlayerPedId(), change.prop_id, change.drawable, change.texture, true)
            end
            clothes.data[name] = change
        end
    end

    Wait(100)

    local success = clothes.sync()
    if not success then
        LocalPlayer.state.invBusy = false
        return false
    end

    LocalPlayer.state.invBusy = false
end

function clothes.applyStagedChangesToVPed()
    local vped = VPed.getClonedPed()
    if not vped or vped == 0 then return end

    for name, data in pairs(clothes.data) do
        if data.component_id then
            SetPedComponentVariation(vped, data.component_id, data.drawable, data.texture, 0)
        elseif data.prop_id then
            if data.drawable == -1 then
                ClearPedProp(vped, data.prop_id)
            else
                SetPedPropIndex(vped, data.prop_id, data.drawable, data.texture, true)
            end
        end
    end
end

lib.callback.register('ox_inventory:getCurrentClothes', function()
    return clothes.data
end)

lib.callback.register('ox_inventory:setCurrentClothes', function(data)
    SendNUIMessage({
        action = 'setupInventory',
        data = {
            clothesInventory = data,
        }
    })
end)

lib.callback.register('ox_inventory:applyComponent', function(metadata)
    if not metadata then
        return false
    end

    local components = metadata.component_id and { metadata } or metadata
    if type(components) ~= "table" then
        return false
    end

    local targetPed = clothes.isInventoryOpen and VPed.getClonedPed() or PlayerPedId()
    if not targetPed or targetPed == 0 then
        return false
    end

    for _, component in pairs(components) do
        if component.component_id and shared.componentMap[component.component_id] then
            local componentId = component.component_id
            local drawable = component.drawable or 0
            local texture = component.texture or 0
            local componentName = shared.componentMap[componentId]

            if clothes.isInventoryOpen then
                clothes.stagedChanges[componentName] = {
                    component_id = componentId,
                    drawable = drawable,
                    texture = texture,
                }
            else
                clothes.data[componentName] = {
                    component_id = componentId,
                    drawable = drawable,
                    texture = texture,
                }
            end

            SetPedComponentVariation(targetPed, componentId, drawable, texture, 0)
        end
    end

    return true
end)

lib.callback.register('ox_inventory:applyProp', function(metadata)
    if not metadata then
        return false
    end

    local props = metadata.prop_id and { metadata } or metadata
    if type(props) ~= "table" then
        return false
    end

    local targetPed = clothes.isInventoryOpen and VPed.getClonedPed() or PlayerPedId()
    if not targetPed or targetPed == 0 then
        return false
    end

    for _, prop in pairs(props) do
        if prop.prop_id and shared.propMap[prop.prop_id] then
            local propId = prop.prop_id
            local drawable = prop.drawable or 0
            local texture = prop.texture or 0
            local propName = shared.propMap[propId]

            if clothes.isInventoryOpen then
                clothes.stagedChanges[propName] = {
                    prop_id = propId,
                    drawable = drawable,
                    texture = texture,
                }
            else
                clothes.data[propName] = {
                    prop_id = propId,
                    drawable = drawable,
                    texture = texture,
                }
            end

            SetPedPropIndex(targetPed, propId, drawable, texture, true)
        end
    end

    return true
end)

lib.callback.register('ox_inventory:removeComponent', function(componentIds)
    if not componentIds then
        return false
    end

    local ids = type(componentIds) == "table" and componentIds or { componentIds }

    local gender = getGender()
    local targetPed = clothes.isInventoryOpen and VPed.getClonedPed() or PlayerPedId()

    if not targetPed or targetPed == 0 then
        return false
    end

    for _, componentId in pairs(ids) do
        if shared.componentMap[componentId] then
            local name = shared.componentMap[componentId]
            local defaultClothes = shared.clothing[gender] and shared.clothing[gender][name]

            if defaultClothes then
                if clothes.isInventoryOpen then
                    clothes.stagedChanges[name] = "REMOVED"
                else
                    clothes.data[name] = nil
                end

                SetPedComponentVariation(targetPed, componentId, defaultClothes.drawable, defaultClothes.texture, 0)
            end
        end
    end

    return true
end)

lib.callback.register('ox_inventory:removeProp', function(propIds)
    if not propIds then
        return false
    end

    local ids = type(propIds) == "table" and propIds or { propIds }

    local gender = getGender()
    local targetPed = clothes.isInventoryOpen and VPed.getClonedPed() or PlayerPedId()

    if not targetPed or targetPed == 0 then
        return false
    end

    for _, propId in pairs(ids) do
        if shared.propMap[propId] then
            local name = shared.propMap[propId]
            local defaultClothes = shared.clothing[gender] and shared.clothing[gender][name]

            if defaultClothes then
                if clothes.isInventoryOpen then
                    clothes.stagedChanges[name] = "REMOVED"
                else
                    clothes.data[name] = nil
                end

                if defaultClothes.drawable == -1 then
                    ClearPedProp(targetPed, propId)
                else
                    SetPedPropIndex(targetPed, propId, defaultClothes.drawable, defaultClothes.texture, true)
                end
            end
        end
    end

    return true
end)

RegisterNetEvent('ox_inventory:checkClothes', clothes.check)

return clothes