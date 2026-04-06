if not lib then
    return
end

local Inventory = require("modules.inventory.server")

local clothing = {}
local disabled = {}
local removed = {}
local added = {}

local function countItems(inv)
    local count = 0
    for _, item in pairs(inv.items) do
        if item and item.metadata then
            count = count + 1
        end
    end
    return count
end

local function getSlotId(slot)
    return type(slot) == "number" and slot or slot and slot.slot
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function sanitizeClothingData(name, data)
    if type(name) ~= "string" or name == "outfits" then
        return nil
    end

    if type(data) ~= "table" then
        return nil
    end

    local hasComponent = data.component_id ~= nil
    local hasProp = data.prop_id ~= nil

    if hasComponent == hasProp then
        return nil
    end

    local drawable = tonumber(data.drawable)
    local texture = tonumber(data.texture)

    if not drawable or not texture then
        return nil
    end

    if not isFiniteNumber(drawable) or not isFiniteNumber(texture) then
        return nil
    end

    drawable = math.floor(drawable)
    texture = math.floor(texture)

    if drawable < -1 or drawable > 4095 or texture < 0 or texture > 255 then
        return nil
    end

    local sanitized = {
        drawable = drawable,
        texture = texture,
        collection = data.collection,
    }

    if sanitized.collection ~= nil and type(sanitized.collection) ~= "string" then
        return nil
    end

    if sanitized.collection and #sanitized.collection > 64 then
        return nil
    end

    if data.localIndex ~= nil then
        local localIndex = tonumber(data.localIndex)
        if not localIndex then
            return nil
        end

        if not isFiniteNumber(localIndex) or localIndex < 0 or localIndex > 4095 then
            return nil
        end

        sanitized.localIndex = math.floor(localIndex)
    end

    if hasComponent then
        local componentId = tonumber(data.component_id)
        if not isFiniteNumber(componentId) then
            return nil
        end

        componentId = math.floor(componentId)

        if shared.componentMap[componentId] ~= name then
            return nil
        end

        sanitized.component_id = componentId
        sanitized.prop_id = nil
    else
        local propId = tonumber(data.prop_id)
        if not isFiniteNumber(propId) then
            return nil
        end

        propId = math.floor(propId)

        if shared.propMap[propId] ~= name then
            return nil
        end

        sanitized.prop_id = propId
        sanitized.component_id = nil
    end

    return sanitized
end

local function sanitizeClothesPayload(input)
    if type(input) ~= "table" then
        return nil
    end

    local sanitized = {}
    local count = 0

    for name, data in pairs(input) do
        local clean = sanitizeClothingData(name, data)
        if not clean then
            return nil
        end

        sanitized[name] = clean
        count = count + 1

        if count > 16 then
            return nil
        end
    end

    if count == 0 then
        return nil
    end

    return sanitized
end

local function getPaymentBalance(src, payment)
    local balance = exports.qbx_core:GetMoney(src, payment)
    if type(balance) == "number" then
        return balance
    end

    local coerced = tonumber(balance)
    if coerced then
        return coerced
    end

    return 0
end

local function handleClothingHook(payload)
    if disabled[payload.source] then
        return false
    end

    local action = payload.action
    if action ~= "move" and action ~= "swap" then
        return false
    end

    local toType = payload.toType
    local fromType = payload.fromType

    local toSlot = getSlotId(payload.toSlot)

    if toType == "clothes" or fromType == "clothes" then
        if toType == "clothes" then
            local slotName = toSlot and shared.clothing.slotToName[toSlot]
            if not slotName or ("clothes_" .. slotName) ~= payload.fromSlot.name then
                return false
            end
        end

        if action == "move" then
            return toType == "clothes" and clothing.addClothing(payload) or clothing.removeClothing(payload)
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
    local toType = payload.toType
    local fromType = payload.fromType
    local toSlot = getSlotId(payload.toSlot)

    if action == "move" then
        if toType == "clothes" then
            local slotName = toSlot and shared.clothing.slotToName[toSlot]
            if not slotName or ("clothes_" .. slotName) ~= payload.fromSlot.name then
                return false
            end
        end
        return toType == "clothes" and clothing.addOutfit(payload) or clothing.removeOutfit(payload)
    elseif action == "swap" then
        if toType == "clothes" or fromType == "clothes" then
            lib.notify(payload.source, {
                title = "Vêtements",
                description = "Vous ne pouvez pas échanger de tenues directement pour le moment.",
                type = "error",
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

    local clothes = Inventory("clothes-" .. player.owner)
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
        local result = lib.callback.await("ox_inventory:applyComponent", src, item.metadata)
        if not result then
            disabled[src] = false
            return false
        end
    elseif item.metadata.prop_id then
        local result = lib.callback.await("ox_inventory:applyProp", src, item.metadata)
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

    local clothes = Inventory("clothes-" .. player.owner)
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
        local result = lib.callback.await("ox_inventory:removeComponent", src, item.metadata.component_id)
        if not result then
            disabled[src] = false
            return false
        end
    elseif item.metadata.prop_id then
        local result = lib.callback.await("ox_inventory:removeProp", src, item.metadata.prop_id)
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

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    local outfit = sanitizeClothesPayload(item.metadata.outfit)
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

            success = Inventory.AddItem(player, "clothes_" .. name, 1, {
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
        local result = lib.callback.await("ox_inventory:applyComponent", src, componentsToApply)
        if not result then
            disabled[src] = false
            return false
        end

        for _, data in ipairs(componentsToApply) do
            local name = shared.componentMap[data.component_id]
            if name then
                local slot = shared.clothing.nameToSlots[name]
                local success = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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
        local result = lib.callback.await("ox_inventory:applyProp", src, propsToApply)
        if not result then
            disabled[src] = false
            return false
        end

        for _, data in ipairs(propsToApply) do
            local name = shared.propMap[data.prop_id]
            if name then
                local slot = shared.clothing.nameToSlots[name]
                local success = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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

    added[src] = true

    return true
end

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

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    local item = payload.fromSlot
    if not item or not item.metadata then
        disabled[src] = false
        return false
    end

    local outfit = sanitizeClothesPayload(item.metadata.outfit)
    if not outfit or next(outfit) == nil then
        disabled[src] = false
        return false
    end

    local current = {}
    local componentsToRemove = {}
    local propsToRemove = {}

    for index, data in pairs(clothes.items) do
        if index ~= 8 and data and data.metadata then
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
        local result = lib.callback.await("ox_inventory:removeComponent", src, componentsToRemove)
        if not result then
            disabled[src] = false
            return false
        end
    end

    if #propsToRemove > 0 then
        local result = lib.callback.await("ox_inventory:removeProp", src, propsToRemove)
        if not result then
            disabled[src] = false
            return false
        end
    end

    Inventory.Clear(clothes)

    removed[src] = {
        outfit = current,
        label = item.metadata.label or nil,
    }

    return true
end

CreateThread(function()
    exports.ox_inventory:registerHook("swapItems", handleClothingHook, {
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
        inventoryFilter = { "^clothes-[%w]+" },
    })

    exports.ox_inventory:registerHook("swapItems", handleOutfitHook, {
        disableCheck = true,
        itemFilter = { clothes_outfits = true },
        inventoryFilter = { "^clothes-[%w]+" },
    })

    exports.ox_inventory:registerHook("swappedItems", function(payload)
        local src = payload.source

        if not removed[src] and not added[src] then
            return
        end

        local removedOutfit = removed[src]
        local shouldUpdateClothes = removedOutfit ~= nil or added[src] ~= nil

        removed[src] = nil
        added[src] = nil

        if not shouldUpdateClothes then
            return
        end

        local toSlot = getSlotId(payload.toSlot)

        CreateThread(function()
            Wait(0)

            local player = Inventory(src)
            if not player then
                disabled[src] = false
                return
            end

            local clothes = Inventory("clothes-" .. player.owner)
            if not clothes then
                disabled[src] = false
                return
            end

            if removedOutfit and toSlot then
                Inventory.SetMetadata(player, toSlot, {
                    label = removedOutfit.label or nil,
                    outfit = removedOutfit.outfit,
                })
                Inventory.Save(player)
            end

            lib.callback.await("ox_inventory:setCurrentClothes", src, clothes)
            Inventory.Save(clothes)
            disabled[src] = false
        end)
    end, {
        disableCheck = true,
        itemFilter = { clothes_outfits = true },
        inventoryFilter = { "^clothes-[%w]+" },
    })
end)

lib.callback.register("ox_inventory:getClothesInventory", function(source)
    local src = source

    if disabled[src] then
        return false
    end

    local player = Inventory(src)
    if not player then
        return false
    end

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        return false
    end

    return clothes
end)

lib.callback.register("ox_inventory:syncClothes", function(source, playerClothes, save)
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

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    for name, slot in pairs(shared.clothing.nameToSlots) do
        if name ~= "outfits" then
            local actuelItem = Inventory.GetSlot(clothes, slot)

            if playerClothes[name] then
                if not actuelItem then
                    local success, response = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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
                    if
                        metadata.drawable ~= playerClothes[name].drawable
                        or metadata.texture ~= playerClothes[name].texture
                    then
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

lib.callback.register("ox_inventory:setClothes", function(source, changedClothes)
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

    local clothes = Inventory("clothes-" .. player.owner)
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
            local success, response = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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

lib.callback.register("ox_inventory:checkClothes", function(source, changedClothes, payment, type)
    local src = source

    if disabled[src] then
        return false
    end

    local sanitizedClothes = sanitizeClothesPayload(changedClothes)
    if not sanitizedClothes then
        return false
    end

    if payment ~= "cash" and payment ~= "bank" then
        return false
    end

    if type ~= "clothes" and type ~= "outfit" then
        return false
    end

    local amount = 0

    for name in pairs(sanitizedClothes) do
        amount = amount + (shared.clothing.nameToPrice[name] or 0)
    end

    local balance = getPaymentBalance(src, payment)
    if amount > 0 and balance < amount then
        lib.notify(src, {
            title = "Vêtements",
            description = "Vous n'avez pas assez d'argent",
            type = "error",
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

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        disabled[src] = false
        return false
    end

    if type == "clothes" then
        for name, data in pairs(sanitizedClothes) do
            local slot = shared.clothing.nameToSlots[name]
            if not slot then
                disabled[src] = false
                return false
            end

            local actuelItem = Inventory.GetSlot(clothes, slot)
            if actuelItem then
                local metadata = actuelItem.metadata or {}
                if metadata.drawable ~= data.drawable or metadata.texture ~= data.texture then
                    local success, response = Inventory.AddItem(player, "clothes_" .. name, 1, {
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
                local success, response = Inventory.AddItem(player, "clothes_" .. name, 1, {
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
        local success, response = Inventory.AddItem(player, "clothes_outfits", 1, {
            outfit = sanitizedClothes,
        })
        if not success then
            disabled[src] = false
            return false
        end
    end

    disabled[src] = false
    return exports.qbx_core:RemoveMoney(src, payment, amount, "Achat de vêtements")
end)

exports("EnableClothing", function(source)
    disabled[source] = false
end)

exports("DisableClothing", function(source)
    disabled[source] = true
end)

exports("GetPlayerClothes", function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory("clothes-" .. player.owner)
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

exports("SetPlayerClothes", function(source, clothesData)
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

    local clothes = Inventory("clothes-" .. player.owner)
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
                Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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

exports("IsClothingDisabled", function(source)
    return disabled[source] == true
end)

exports("SyncPlayerClothes", function(source, playerClothes, save)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    return lib.callback.await("ox_inventory:syncClothes", source, playerClothes, save)
end)

exports("GetClothesInventory", function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory("clothes-" .. player.owner)
    if not clothes then
        return false
    end

    return clothes
end)

exports("ClearPlayerClothes", function(source)
    if disabled[source] then
        return false
    end

    local player = Inventory(source)
    if not player then
        return false
    end

    local clothes = Inventory("clothes-" .. player.owner)
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

exports("ApplyClothingComponent", function(source, metadata)
    if disabled[source] then
        return false
    end

    return lib.callback.await("ox_inventory:applyComponent", source, metadata)
end)

exports("ApplyClothingProp", function(source, metadata)
    if disabled[source] then
        return false
    end

    return lib.callback.await("ox_inventory:applyProp", source, metadata)
end)

exports("RemoveClothingComponent", function(source, componentIds)
    if disabled[source] then
        return false
    end

    return lib.callback.await("ox_inventory:removeComponent", source, componentIds)
end)

exports("RemoveClothingProp", function(source, propIds)
    if disabled[source] then
        return false
    end

    return lib.callback.await("ox_inventory:removeProp", source, propIds)
end)

RegisterNetEvent("ox_inventory:enableClothings", function()
    local src = source
    disabled[src] = false
end)

RegisterNetEvent("ox_inventory:disableClothings", function()
    local src = source
    disabled[src] = true
end)

AddEventHandler("playerDropped", function()
    local src = source
    disabled[src] = nil
    removed[src] = nil
    added[src] = nil
end)
