if not lib then return end

local clothes = {
    initial = false,
    data = {},
    stagedChanges = {},
    isInventoryOpen = false,
}
local VPed = require 'modules.VPed.client'

local CLOTHING_ANIM_DICT = 'clothingtie'
local CLOTHING_ANIM_CLIP = 'try_tie_positive_a'

lib.onCache('ped', function(value)
    if value then
        SetPedConfigFlag(value, 35, false)
        SetPedCanLosePropsOnDamage(value, false, 0)
    end
end)

local function getGender()
    local model = GetEntityModel(PlayerPedId())
    if model == joaat('mp_m_freemode_01') then
        return "male"
    end
    return "female"
end

local function getCollectionDataForComponent(ped, componentId, drawable)
    if drawable and drawable >= 0 then
        local collectionName = GetPedCollectionNameFromDrawable(ped, componentId, drawable)
        local localIndex = GetPedCollectionLocalIndexFromDrawable(ped, componentId, drawable)
        return collectionName, localIndex
    end
    return nil, nil
end

local function getCollectionDataForProp(ped, propId, drawable)
    if drawable and drawable >= 0 then
        local collectionName = GetPedCollectionNameFromProp(ped, propId, drawable)
        local localIndex = GetPedCollectionLocalIndexFromProp(ped, propId, drawable)
        return collectionName, localIndex
    end
    return nil, nil
end

local function updateClothingDataWithCollections(clothingData)
    for name, data in pairs(clothingData) do
        if data.component_id and not data.collection and data.drawable then
            local collectionName, localIndex = getCollectionDataForComponent(PlayerPedId(), data.component_id,
                data.drawable)
            if collectionName and localIndex then
                data.collection = collectionName
                data.localIndex = localIndex
            end
        elseif data.prop_id and not data.collection and data.drawable then
            local collectionName, localIndex = getCollectionDataForProp(PlayerPedId(), data.prop_id, data.drawable)
            if collectionName and localIndex then
                data.collection = collectionName
                data.localIndex = localIndex
            end
        end
    end
    return clothingData
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
        local collectionName, localIndex = getCollectionDataForComponent(PlayerPedId(), index, drawable)

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or 0
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or 0

        if drawable ~= defaultDrawable or texture ~= defaultTexture then
            playerClothes[name] = {
                component_id = index,
                drawable = drawable,
                texture = texture,
                collection = collectionName,
                localIndex = localIndex,
            }
        end
    end

    for index, name in pairs(shared.propMap) do
        local drawable = GetPedPropIndex(PlayerPedId(), index) or 0
        local texture = GetPedPropTextureIndex(PlayerPedId(), index) or 0
        local collectionName, localIndex = getCollectionDataForProp(PlayerPedId(), index, drawable)

        local defaultDrawable = defaultClothes[name] and defaultClothes[name].drawable or -1
        local defaultTexture = defaultClothes[name] and defaultClothes[name].texture or -1

        if drawable ~= defaultDrawable or texture ~= defaultTexture then
            playerClothes[name] = {
                prop_id = index,
                drawable = drawable,
                texture = texture,
                collection = collectionName,
                localIndex = localIndex,
            }
        end
    end

    clothes.data = playerClothes
    clothes.data = updateClothingDataWithCollections(clothes.data)
end

function clothes.setInitialCreation()
    clothes.initial = true
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
        local actualCollectionName, actualLocalIndex = getCollectionDataForComponent(PlayerPedId(), index, actualDrawable)

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
                        collection = actualCollectionName,
                        localIndex = actualLocalIndex,
                    }
                end
            end
        else
            if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                changedClothes[name] = {
                    component_id = index,
                    drawable = actualDrawable,
                    texture = actualTexture,
                    collection = actualCollectionName,
                    localIndex = actualLocalIndex,
                }
            end
        end
    end

    for index, name in pairs(shared.propMap) do
        local actualDrawable = GetPedPropIndex(PlayerPedId(), index) or 0
        local actualTexture = GetPedPropTextureIndex(PlayerPedId(), index) or 0
        local actualCollectionName, actualLocalIndex = getCollectionDataForProp(PlayerPedId(), index, actualDrawable)

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
                        collection = actualCollectionName,
                        localIndex = actualLocalIndex,
                    }
                end
            end
        else
            if actualDrawable ~= defaultDrawable or actualTexture ~= defaultTexture then
                changedClothes[name] = {
                    prop_id = index,
                    drawable = actualDrawable,
                    texture = actualTexture,
                    collection = actualCollectionName,
                    localIndex = actualLocalIndex,
                }
            end
        end
    end

    local changedCount = 0
    for _ in pairs(changedClothes) do changedCount = changedCount + 1 end

    if changedCount > 0 then
        if clothes.initial then
            clothes.initial = false
            clothes.init()
            return lib.callback.await('ox_inventory:setClothes', 10000, changedClothes)
        end

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
                if clothes.data[name].collection and clothes.data[name].localIndex then
                    SetPedCollectionComponentVariation(PlayerPedId(), index, clothes.data[name].collection,
                        clothes.data[name].localIndex, clothes.data[name].texture, 0)
                else
                    SetPedComponentVariation(PlayerPedId(), index, clothes.data[name].drawable,
                        clothes.data[name].texture, 0)
                end
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
                    if clothes.data[name].collection and clothes.data[name].localIndex then
                        SetPedCollectionPropIndex(PlayerPedId(), index, clothes.data[name].collection,
                            clothes.data[name].localIndex, clothes.data[name].texture, true)
                    else
                        SetPedPropIndex(PlayerPedId(), index, clothes.data[name].drawable, clothes.data[name].texture,
                            true)
                    end
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

        return clothes.sync()
    end

    return false
end

function clothes.sync()
    local ok, saveOrErr = pcall(shared.saveAppearanceClient, PlayerPedId())
    if not ok then
        return false
    end

    local ok2, successOrErr = pcall(function()
        return lib.callback.await('ox_inventory:syncClothes', 5000, clothes.data, saveOrErr)
    end)

    if not ok2 then
        return false
    end

    if not successOrErr then
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
            if change.collection and change.localIndex then
                SetPedCollectionComponentVariation(PlayerPedId(), change.component_id, change.collection,
                    change.localIndex, change.texture, 0)
            else
                SetPedComponentVariation(PlayerPedId(), change.component_id, change.drawable, change.texture, 0)
            end
            clothes.data[name] = change
        elseif change.prop_id then
            if change.drawable == -1 then
                ClearPedProp(PlayerPedId(), change.prop_id)
            else
                if change.collection and change.localIndex then
                    SetPedCollectionPropIndex(PlayerPedId(), change.prop_id, change.collection, change.localIndex,
                        change.texture, true)
                else
                    SetPedPropIndex(PlayerPedId(), change.prop_id, change.drawable, change.texture, true)
                end
            end
            clothes.data[name] = change
        end
    end

    Wait(100)
    LocalPlayer.state.invBusy = false

    return clothes.sync()
end

function clothes.applyStagedChangesToVPed()
    local vped = VPed.getClonedPed()
    if not vped or vped == 0 then return end

    for name, data in pairs(clothes.data) do
        if data.component_id then
            if data.collection and data.localIndex then
                SetPedCollectionComponentVariation(vped, data.component_id, data.collection, data.localIndex,
                    data.texture, 0)
            else
                SetPedComponentVariation(vped, data.component_id, data.drawable, data.texture, 0)
            end
        elseif data.prop_id then
            if data.drawable == -1 then
                ClearPedProp(vped, data.prop_id)
            else
                if data.collection and data.localIndex then
                    SetPedCollectionPropIndex(vped, data.prop_id, data.collection, data.localIndex, data.texture, true)
                else
                    SetPedPropIndex(vped, data.prop_id, data.drawable, data.texture, true)
                end
            end
        end
    end
end

lib.callback.register('ox_inventory:getCurrentClothes', function()
    return updateClothingDataWithCollections(clothes.data)
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
            local collection = component.collection
            local localIndex = component.localIndex
            local componentName = shared.componentMap[componentId]

            if not collection and drawable then
                collection, localIndex = getCollectionDataForComponent(targetPed, componentId, drawable)
            end

            if clothes.isInventoryOpen then
                clothes.stagedChanges[componentName] = {
                    component_id = componentId,
                    drawable = drawable,
                    texture = texture,
                    collection = collection,
                    localIndex = localIndex,
                }
            else
                clothes.data[componentName] = {
                    component_id = componentId,
                    drawable = drawable,
                    texture = texture,
                    collection = collection,
                    localIndex = localIndex,
                }
            end

            if collection and localIndex then
                SetPedCollectionComponentVariation(targetPed, componentId, collection, localIndex, texture, 0)
            else
                SetPedComponentVariation(targetPed, componentId, drawable, texture, 0)
            end
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
            local collection = prop.collection
            local localIndex = prop.localIndex
            local propName = shared.propMap[propId]

            if not collection and drawable and drawable >= 0 then
                collection, localIndex = getCollectionDataForProp(targetPed, propId, drawable)
            end

            if clothes.isInventoryOpen then
                clothes.stagedChanges[propName] = {
                    prop_id = propId,
                    drawable = drawable,
                    texture = texture,
                    collection = collection,
                    localIndex = localIndex,
                }
            else
                clothes.data[propName] = {
                    prop_id = propId,
                    drawable = drawable,
                    texture = texture,
                    collection = collection,
                    localIndex = localIndex,
                }
            end

            if collection and localIndex then
                SetPedCollectionPropIndex(targetPed, propId, collection, localIndex, texture, true)
            else
                SetPedPropIndex(targetPed, propId, drawable, texture, true)
            end
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
RegisterNetEvent('ox_inventory:setInitialCreation', clothes.setInitialCreation)

exports('GetCurrentClothes', function()
    return updateClothingDataWithCollections(clothes.data)
end)

exports('SetClothesData', function(data)
    if data and type(data) == "table" then
        clothes.data = data
        return true
    end
    return false
end)

exports('InitClothes', function()
    clothes.init()
    return true
end)

exports('CheckClothes', function()
    return clothes.check()
end)

exports('SyncClothes', function()
    return clothes.sync()
end)

exports('IsInitialCreation', function()
    return clothes.initial
end)

exports('GetGender', function()
    return getGender()
end)

exports('IsInventoryOpen', function()
    return clothes.isInventoryOpen
end)

exports('SetInventoryOpen', function(isOpen)
    clothes.setInventoryOpen(isOpen)
    return true
end)

exports('ApplyChangesToPlayer', function()
    return clothes.applyChangesToPlayer()
end)

exports('GetStagedChanges', function()
    return clothes.stagedChanges
end)

exports('SetStagedChanges', function(changes)
    if changes and type(changes) == "table" then
        clothes.stagedChanges = changes
        return true
    end
    return false
end)

exports('ClearStagedChanges', function()
    clothes.stagedChanges = {}
    return true
end)

exports('ClearClothes', function()
    clothes.data = {}
    clothes.stagedChanges = {}
    return true
end)

exports('GetCollectionDataForComponent', function(ped, componentId, drawable)
    local collectionName, localIndex = getCollectionDataForComponent(ped or PlayerPedId(), componentId, drawable)
    return { collectionName = collectionName, localIndex = localIndex }
end)

exports('GetCollectionDataForProp', function(ped, propId, drawable)
    local collectionName, localIndex = getCollectionDataForProp(ped or PlayerPedId(), propId, drawable)
    return { collectionName = collectionName, localIndex = localIndex }
end)

exports('UpdateClothingDataWithCollections', function(clothingData)
    return updateClothingDataWithCollections(clothingData)
end)

exports('CountStagedChanges', function()
    return countStagedChanges()
end)

exports('SetInitialCreation', function()
    clothes.setInitialCreation()
end)

exports('ApplyComponent', function(metadata)
    if not metadata then
        return false
    end

    local components = metadata.component_id and { metadata } or metadata
    if type(components) ~= "table" then
        return false
    end

    local targetPed = PlayerPedId()
    if not targetPed or targetPed == 0 then
        return false
    end

    for _, component in pairs(components) do
        if component.component_id and shared.componentMap[component.component_id] then
            local componentId = component.component_id
            local drawable = component.drawable or 0
            local texture = component.texture or 0
            local collection = component.collection
            local localIndex = component.localIndex
            local componentName = shared.componentMap[componentId]

            if not collection and drawable then
                collection, localIndex = getCollectionDataForComponent(targetPed, componentId, drawable)
            end

            clothes.data[componentName] = {
                component_id = componentId,
                drawable = drawable,
                texture = texture,
                collection = collection,
                localIndex = localIndex,
            }

            if collection and localIndex then
                SetPedCollectionComponentVariation(targetPed, componentId, collection, localIndex, texture, 0)
            else
                SetPedComponentVariation(targetPed, componentId, drawable, texture, 0)
            end
        end
    end

    return true
end)

exports('ApplyProp', function(metadata)
    if not metadata then
        return false
    end

    local props = metadata.prop_id and { metadata } or metadata
    if type(props) ~= "table" then
        return false
    end

    local targetPed = PlayerPedId()
    if not targetPed or targetPed == 0 then
        return false
    end

    for _, prop in pairs(props) do
        if prop.prop_id and shared.propMap[prop.prop_id] then
            local propId = prop.prop_id
            local drawable = prop.drawable or 0
            local texture = prop.texture or 0
            local collection = prop.collection
            local localIndex = prop.localIndex
            local propName = shared.propMap[propId]

            if not collection and drawable and drawable >= 0 then
                collection, localIndex = getCollectionDataForProp(targetPed, propId, drawable)
            end

            clothes.data[propName] = {
                prop_id = propId,
                drawable = drawable,
                texture = texture,
                collection = collection,
                localIndex = localIndex,
            }

            if collection and localIndex then
                SetPedCollectionPropIndex(targetPed, propId, collection, localIndex, texture, true)
            else
                SetPedPropIndex(targetPed, propId, drawable, texture, true)
            end
        end
    end

    return true
end)

exports('RemoveComponent', function(componentIds)
    if not componentIds then
        return false
    end

    local ids = type(componentIds) == "table" and componentIds or { componentIds }
    local gender = getGender()
    local targetPed = PlayerPedId()

    if not targetPed or targetPed == 0 then
        return false
    end

    for _, componentId in pairs(ids) do
        if shared.componentMap[componentId] then
            local name = shared.componentMap[componentId]
            local defaultClothes = shared.clothing[gender] and shared.clothing[gender][name]

            if defaultClothes then
                clothes.data[name] = nil
                SetPedComponentVariation(targetPed, componentId, defaultClothes.drawable, defaultClothes.texture, 0)
            end
        end
    end

    return true
end)

exports('RemoveProp', function(propIds)
    if not propIds then
        return false
    end

    local ids = type(propIds) == "table" and propIds or { propIds }
    local gender = getGender()
    local targetPed = PlayerPedId()

    if not targetPed or targetPed == 0 then
        return false
    end

    for _, propId in pairs(ids) do
        if shared.propMap[propId] then
            local name = shared.propMap[propId]
            local defaultClothes = shared.clothing[gender] and shared.clothing[gender][name]

            if defaultClothes then
                clothes.data[name] = nil

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

return clothes
