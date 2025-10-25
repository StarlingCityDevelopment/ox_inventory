if not lib then return end

local Inventory = require 'modules.inventory.server'

local clothing = {}
local disabled = {}

local function countItems(inv)
    local count = 0
    for _, item in pairs(inv.items) do
        if item and item.metadata then
            count = count + 1
        end
    end
    return count
end

local function handleClothingHook(payload)
    if disabled[payload.source] then
        return false
    end

    local action = payload.action
    if action ~= 'move' and action ~= 'swap' then
        return false
    end

    local toType = payload.toType
    local fromType = payload.fromType

    local toSlot = type(payload.toSlot) == 'number' and payload.toSlot or payload.toSlot.slot

    if toType == 'clothes' or fromType == 'clothes' then
        if toType == 'clothes' then
            return ('clothes_' .. shared.clothing.slotToName[toSlot]) == payload.fromSlot.name
        end

        if action == 'move' then
            return toType == 'clothes' and clothing.addClothing(payload) or clothing.removeClothing(payload)
        else
            return clothing.addClothing(payload)
        end
    end

    return false
end

local function handleOutfitHook(payload)
    if disabled[payload.source] then
        return false
    end

    local action = payload.action
    if action == 'move' then
        return payload.toType == 'clothes' and clothing.addOutfit(payload) or clothing.removeOutfit(payload)
    elseif action == 'swap' then
        if payload.toType == 'clothes' or payload.fromType == 'clothes' then
            lib.notify(payload.source, {
                title = 'Vêtements',
                description = 'Vous ne pouvez pas échanger de tenues directement pour le moment.',
                type = 'error',
                duration = 7500,
            })
            return false
        end
    end

    return true
end

function clothing.addClothing(payload)
    local src = payload.source

    if disabled[src] then
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    if item.metadata.component_id then
        local result = lib.callback.await('ox_inventory:applyComponent', src, item.metadata)
        if not result then
            disabled[src] = false
            return false
        end
    elseif item.metadata.prop_id then
        local result = lib.callback.await('ox_inventory:applyProp', src, item.metadata)
        if not result then
            disabled[src] = false
            return false
        end
    else
        disabled[src] = false
        return false
    end

    Inventory.Save(player)
    Inventory.Save(clothes)

    disabled[src] = false
    return true
end

function clothing.removeClothing(payload)
    local src = payload.source

    if disabled[src] then
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    local outfitItem = Inventory.GetSlot(clothes, shared.clothing.nameToSlots.outfits)
    if outfitItem and countItems(clothes) == 2 then
        Inventory.RemoveItem(clothes, outfitItem.name, 1, nil, shared.clothing.nameToSlots.outfits)
    end

    if item.metadata.component_id then
        local result = lib.callback.await('ox_inventory:removeComponent', src, item.metadata.component_id)
        if not result then
            disabled[src] = false
            return false
        end
    elseif item.metadata.prop_id then
        local result = lib.callback.await('ox_inventory:removeProp', src, item.metadata.prop_id)
        if not result then
            disabled[src] = false
            return false
        end
    else
        disabled[src] = false
        return false
    end

    Inventory.Save(player)
    Inventory.Save(clothes)

    disabled[src] = false
    return true
end

function clothing.addOutfit(payload)
    local src = payload.source

    if disabled[src] then
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    local outfit = item.metadata.outfit
    if not outfit or next(outfit) == nil then
        disabled[src] = false
        return false
    end

    local componentsToApply = {}
    local propsToApply = {}

    for name, data in pairs(outfit) do
        local slot = shared.clothing.nameToSlots[name]
        if not slot then
            disabled[src] = false
            return false
        end

        local actuelItem = Inventory.GetSlot(clothes, slot)
        if actuelItem then
            local success = Inventory.RemoveItem(clothes, actuelItem.name, 1, nil, slot)

            if not success then
                disabled[src] = false
                return false
            end

            success = Inventory.AddItem(player, 'clothes_' .. name, 1, {
                label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                component_id = actuelItem.metadata.component_id or nil,
                prop_id = actuelItem.metadata.prop_id or nil,
                drawable = actuelItem.metadata.drawable,
                texture = actuelItem.metadata.texture,
                collection = actuelItem.metadata.collection,
                localIndex = actuelItem.metadata.localIndex,
            })

            if not success then
                success = Inventory.AddItem(clothes, actuelItem.name, 1, {
                    label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                    component_id = actuelItem.metadata.component_id or nil,
                    prop_id = actuelItem.metadata.prop_id or nil,
                    drawable = actuelItem.metadata.drawable,
                    texture = actuelItem.metadata.texture,
                    collection = actuelItem.metadata.collection,
                    localIndex = actuelItem.metadata.localIndex,
                }, slot)

                if not success then
                    disabled[src] = false
                    return false
                end
            end
        end

        if data.component_id then
            table.insert(componentsToApply, data)
        elseif data.prop_id then
            table.insert(propsToApply, data)
        else
            disabled[src] = false
            return false
        end
    end

    if #componentsToApply > 0 then
        local result = lib.callback.await('ox_inventory:applyComponent', src, componentsToApply)
        if not result then
            disabled[src] = false
            return false
        end

        for _, data in ipairs(componentsToApply) do
            local name = shared.componentMap[data.component_id]
            if name then
                local slot = shared.clothing.nameToSlots[name]
                local success = Inventory.AddItem(clothes, 'clothes_' .. name, 1, {
                    component_id = data.component_id,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                }, slot)
                if not success then
                    disabled[src] = false
                    return false
                end
            end
        end
    end

    if #propsToApply > 0 then
        local result = lib.callback.await('ox_inventory:applyProp', src, propsToApply)
        if not result then
            disabled[src] = false
            return false
        end

        for _, data in ipairs(propsToApply) do
            local name = shared.propMap[data.prop_id]
            if name then
                local slot = shared.clothing.nameToSlots[name]
                local success = Inventory.AddItem(clothes, 'clothes_' .. name, 1, {
                    prop_id = data.prop_id,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                }, slot)
                if not success then
                    disabled[src] = false
                    return false
                end
            end
        end
    end

    CreateThread(function()
        Wait(25)
        clothes = Inventory('clothes-' .. player.owner)
        Inventory.Save(clothes)
        lib.callback.await('ox_inventory:setCurrentClothes', src, clothes)
        disabled[src] = false
    end)

    return true
end

local removed = {}

function clothing.removeOutfit(payload)
    local src = payload.source

    if disabled[src] then
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    local outfit = item.metadata.outfit
    if not outfit or next(outfit) == nil then
        disabled[src] = false
        return false
    end

    local current = {}
    local componentsToRemove = {}
    local propsToRemove = {}

    for index, data in pairs(clothes.items) do
        if index ~= 8 then
            if data.metadata.component_id then
                table.insert(componentsToRemove, data.metadata.component_id)
            elseif data.metadata.prop_id then
                table.insert(propsToRemove, data.metadata.prop_id)
            end

            local name = shared.clothing.slotToName[index]
            current[name] = {
                component_id = data.metadata.component_id or nil,
                prop_id = data.metadata.prop_id or nil,
                drawable = data.metadata.drawable,
                texture = data.metadata.texture,
                collection = data.metadata.collection,
                localIndex = data.metadata.localIndex,
            }
        end
    end

    if #componentsToRemove > 0 then
        local result = lib.callback.await('ox_inventory:removeComponent', src, componentsToRemove)
        if not result then
            disabled[src] = false
            return false
        end
    end

    if #propsToRemove > 0 then
        local result = lib.callback.await('ox_inventory:removeProp', src, propsToRemove)
        if not result then
            disabled[src] = false
            return false
        end
    end

    Inventory.Clear(clothes)
    disabled[src] = false

    removed[src] = {
        outfit = current,
        label = item.metadata.label or nil,
    }

    CreateThread(function()
        Wait(25)
        Inventory.SetMetadata(player, payload.toSlot, {
            label = item.metadata.label or nil,
            outfit = current
        })
        Inventory.Save(clothes)
        Inventory.Save(player)
        lib.callback.await('ox_inventory:setCurrentClothes', src, clothes)
    end)
    return true
end

CreateThread(function()
    exports.ox_inventory:registerHook('swapItems', handleClothingHook, {
        disableCheck = true,
        itemFilter = {
            clothes_jackets = true,
            clothes_shirts = true,
            clothes_torsos = true,
            clothes_bags = true,
            clothes_vest = true,
            clothes_legs = true,
            clothes_shoes = true,
            clothes_hats = true,
            clothes_masks = true,
            clothes_glasses = true,
            clothes_earrings = true,
            clothes_neck = true,
            clothes_watches = true,
            clothes_bracelets = true,
            clothes_decals = true,
        },
        inventoryFilter = { '^clothes-[%w]+' }
    })

    exports.ox_inventory:registerHook('swapItems', handleOutfitHook, {
        disableCheck = true,
        itemFilter = { clothes_outfits = true },
        inventoryFilter = { '^clothes-[%w]+' }
    })

    exports.ox_inventory:registerHook('swappedItems', function(payload)
        local src = payload.source

        if disabled[src] or not removed[src] then
            return
        end

        local player = Inventory(src)
        if not player then
            return
        end

        local clothes = Inventory('clothes-' .. player.owner)
        if not clothes then
            return
        end

        local outfitData = removed[src]
        removed[src] = nil

        Inventory.SetMetadata(player, payload.toSlot, {
            label = outfitData.label or nil,
            outfit = outfitData.outfit
        })
        lib.callback.await('ox_inventory:setCurrentClothes', src, clothes)
        Inventory.Save(clothes)
        Inventory.Save(player)
    end, {
        disableCheck = true,
        itemFilter = { clothes_outfits = true },
        inventoryFilter = { '^clothes-[%w]+' }
    })
end)

lib.callback.register('ox_inventory:getClothesInventory', function(source)
    local src = source

    if disabled[src] then
        return false
    end

    local player = Inventory(src)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    return clothes
end)

lib.callback.register('ox_inventory:syncClothes', function(source, playerClothes, save)
    local src = source

    if save ~= nil then
        shared.saveAppearanceServer(src, save)
    end

    if disabled[src] then
        return false
    end

    if not playerClothes or next(playerClothes) == nil then
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    for name, slot in pairs(shared.clothing.nameToSlots) do
        if name ~= "outfits" then
            local actuelItem = Inventory.GetSlot(clothes, slot)

            if playerClothes[name] then
                if not actuelItem then
                    local success, response = Inventory.AddItem(clothes, 'clothes_' .. name, 1, {
                        component_id = playerClothes[name].component_id or nil,
                        prop_id = playerClothes[name].prop_id or nil,
                        drawable = playerClothes[name].drawable,
                        texture = playerClothes[name].texture,
                        collection = playerClothes[name].collection,
                        localIndex = playerClothes[name].localIndex,
                    }, slot)
                    if not success then
                        disabled[src] = false
                        return false
                    end
                else
                    local metadata = actuelItem.metadata or {}
                    if metadata.drawable ~= playerClothes[name].drawable or
                        metadata.texture ~= playerClothes[name].texture then
                        Inventory.SetMetadata(clothes, slot, {
                            component_id = playerClothes[name].component_id or nil,
                            prop_id = playerClothes[name].prop_id or nil,
                            drawable = playerClothes[name].drawable,
                            texture = playerClothes[name].texture,
                            collection = playerClothes[name].collection,
                            localIndex = playerClothes[name].localIndex,
                        })
                    end
                end
            else
                if actuelItem then
                    local success, response = Inventory.RemoveItem(clothes, actuelItem.name, 1, nil, slot)
                    if not success then
                        disabled[src] = false
                        return false
                    end
                end
            end
        end
    end

    disabled[src] = false
    return true
end)

lib.callback.register('ox_inventory:setClothes', function(source, changedClothes)
    local src = source

    if disabled[src] then
        return false
    end

    if not changedClothes or next(changedClothes) == nil then
        return false
    end

    local player = Inventory(src)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    disabled[src] = true

    for name, data in pairs(changedClothes) do
        local slot = shared.clothing.nameToSlots[name]

        if not slot then
            disabled[src] = false
            return false
        end

        local actuelItem = Inventory.GetSlot(clothes, slot)

        if actuelItem then
            local metadata = actuelItem.metadata or {}
            if metadata.drawable ~= data.drawable or metadata.texture ~= data.texture then
                Inventory.SetMetadata(clothes, slot, {
                    label = metadata.label or nil,
                    component_id = data.component_id or nil,
                    prop_id = data.prop_id or nil,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                })
            end
        else
            local success, response = Inventory.AddItem(clothes, 'clothes_' .. name, 1, {
                label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                component_id = data.component_id or nil,
                prop_id = data.prop_id or nil,
                drawable = data.drawable,
                texture = data.texture,
                collection = data.collection,
                localIndex = data.localIndex,
            }, slot)
            if not success then
                disabled[src] = false
                return false
            end
        end
    end

    disabled[src] = false
    return true
end)

lib.callback.register('ox_inventory:checkClothes', function(source, changedClothes, payment, type)
    local src = source

    if disabled[src] then
        return false
    end

    if not changedClothes or next(changedClothes) == nil then
        return false
    end

    if payment ~= 'cash' and payment ~= 'bank' then
        return false
    end

    local amount = 0

    for name, value in pairs(changedClothes) do
        amount = amount + (shared.clothing.nameToPrice[name] or 0)
    end

    if amount > 0 and not exports.qbx_core:GetMoney(src, payment) then
        lib.notify(src, {
            title = 'Vêtements',
            description = 'Vous n\'avez pas assez d\'argent',
            type = 'error',
            duration = 7500,
        })
        return false
    end

    disabled[src] = true

    local player = Inventory(src)
    if not player then
        disabled[src] = false
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    if type == 'clothes' then
        for name, data in pairs(changedClothes) do
            local slot = shared.clothing.nameToSlots[name]
            if not slot then
                disabled[src] = false
                return false
            end

            local actuelItem = Inventory.GetSlot(clothes, slot)
            if actuelItem then
                local metadata = actuelItem.metadata or {}
                if metadata.drawable ~= data.drawable or metadata.texture ~= data.texture then
                    local success, response = Inventory.AddItem(player, 'clothes_' .. name, 1, {
                        label = metadata.label or nil,
                        component_id = data.component_id or nil,
                        prop_id = data.prop_id or nil,
                        drawable = data.drawable,
                        texture = data.texture,
                        collection = data.collection,
                        localIndex = data.localIndex,
                    })
                    if not success then
                        disabled[src] = false
                        return false
                    end
                end
            else
                local success, response = Inventory.AddItem(player, 'clothes_' .. name, 1, {
                    label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                    component_id = data.component_id or nil,
                    prop_id = data.prop_id or nil,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                })
                if not success then
                    disabled[src] = false
                    return false
                end
            end
        end
    else
        local success, response = Inventory.AddItem(player, 'clothes_outfits', 1, {
            outfit = changedClothes
        })
        if not success then
            disabled[src] = false
            return false
        end
    end

    disabled[src] = false
    return exports.qbx_core:RemoveMoney(src, payment, amount, 'Achat de vêtements')
end)

exports('EnableClothing', function(source)
    disabled[source] = false
end)

exports('DisableClothing', function(source)
    disabled[source] = true
end)

exports('GetPlayerClothes', function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    local playerClothes = {}
    for name, slot in pairs(shared.clothing.nameToSlots) do
        if name ~= "outfits" then
            local item = Inventory.GetSlot(clothes, slot)
            if item and item.metadata then
                playerClothes[name] = {
                    component_id = item.metadata.component_id or nil,
                    prop_id = item.metadata.prop_id or nil,
                    drawable = item.metadata.drawable,
                    texture = item.metadata.texture,
                    collection = item.metadata.collection,
                    localIndex = item.metadata.localIndex,
                }
            end
        end
    end

    return playerClothes
end)

exports('SetPlayerClothes', function(source, clothesData)
    if disabled[source] then
        return false
    end

    if not clothesData or next(clothesData) == nil then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    disabled[source] = true

    for name, data in pairs(clothesData) do
        local slot = shared.clothing.nameToSlots[name]
        if slot then
            local actuelItem = Inventory.GetSlot(clothes, slot)
            if actuelItem then
                Inventory.SetMetadata(clothes, slot, {
                    label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                    component_id = data.component_id or nil,
                    prop_id = data.prop_id or nil,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                })
            else
                Inventory.AddItem(clothes, 'clothes_' .. name, 1, {
                    label = actuelItem and actuelItem.metadata and actuelItem.metadata.label or nil,
                    component_id = data.component_id or nil,
                    prop_id = data.prop_id or nil,
                    drawable = data.drawable,
                    texture = data.texture,
                    collection = data.collection,
                    localIndex = data.localIndex,
                }, slot)
            end
        end
    end

    Inventory.Save(clothes)
    disabled[source] = false
    return true
end)

exports('IsClothingDisabled', function(source)
    return disabled[source] == true
end)

exports('SyncPlayerClothes', function(source, playerClothes, save)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    return lib.callback.await('ox_inventory:syncClothes', source, playerClothes, save)
end)

exports('GetClothesInventory', function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    return clothes
end)

exports('ClearPlayerClothes', function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory('clothes-' .. player.owner)
    if not clothes then
        return false
    end

    disabled[source] = true

    for name, slot in pairs(shared.clothing.nameToSlots) do
        if name ~= "outfits" then
            local actuelItem = Inventory.GetSlot(clothes, slot)
            if actuelItem then
                Inventory.RemoveItem(clothes, actuelItem.name, 1, nil, slot)
            end
        end
    end

    Inventory.Save(clothes)
    disabled[source] = false
    return true
end)

exports('ApplyClothingComponent', function(source, metadata)
    if disabled[source] then
        return false
    end

    return lib.callback.await('ox_inventory:applyComponent', source, metadata)
end)

exports('ApplyClothingProp', function(source, metadata)
    if disabled[source] then
        return false
    end

    return lib.callback.await('ox_inventory:applyProp', source, metadata)
end)

exports('RemoveClothingComponent', function(source, componentIds)
    if disabled[source] then
        return false
    end

    return lib.callback.await('ox_inventory:removeComponent', source, componentIds)
end)

exports('RemoveClothingProp', function(source, propIds)
    if disabled[source] then
        return false
    end

    return lib.callback.await('ox_inventory:removeProp', source, propIds)
end)

RegisterNetEvent('ox_inventory:enableClothings', function()
    local src = source
    disabled[src] = false
end)

RegisterNetEvent('ox_inventory:disableClothings', function()
    local src = source
    disabled[src] = true
end)
