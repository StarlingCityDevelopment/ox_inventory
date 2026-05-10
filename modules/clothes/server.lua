if not lib then
	return
end

local Inventory = require("modules.inventory.server")

local clothing = {}

local locks = {}
local disabled = {}

local pendingRemoved = {}
local pendingAdded = {}

local lastPurchase = {}
local PURCHASE_COOLDOWN_MS = 1000

local function isFiniteNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isLocked(src)
	return locks[src] == true or disabled[src] == true
end

local function lock(src)
	locks[src] = true
end

local function unlock(src)
	locks[src] = nil
end

local function getPlayerAndClothes(src)
	local player = Inventory(src)
	if not player then
		return nil, nil
	end

	local clothes = Inventory("clothes-" .. player.owner)
	if not clothes then
		return nil, nil
	end

	return player, clothes
end

local function countWornItems(clothes)
	local outfitSlot = shared.clothing.nameToSlots.outfits
	local count = 0
	for slot, item in pairs(clothes.items) do
		if slot ~= outfitSlot and item and item.metadata then
			count = count + 1
		end
	end
	return count
end

local function getSlotId(slot)
	return type(slot) == "number" and slot or (slot and slot.slot)
end

local function isPurchaseRateLimited(src)
	local now = GetGameTimer()
	local last = lastPurchase[src]
	if last and (now - last) < PURCHASE_COOLDOWN_MS then
		return true
	end
	lastPurchase[src] = now
	return false
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

	if drawable < -1 or drawable > 4095 then
		return nil
	end
	if texture < 0 or texture > 255 then
		return nil
	end

	local sanitized = { drawable = drawable, texture = texture }

	if data.collection ~= nil then
		if type(data.collection) ~= "string" or #data.collection > 64 then
			return nil
		end
		sanitized.collection = data.collection
	end

	if data.localIndex ~= nil then
		local li = tonumber(data.localIndex)
		if not li or not isFiniteNumber(li) or li < 0 or li > 4095 then
			return nil
		end
		sanitized.localIndex = math.floor(li)
	end

	if hasComponent then
		local cid = tonumber(data.component_id)
		if not cid or not isFiniteNumber(cid) then
			return nil
		end
		cid = math.floor(cid)

		if shared.componentMap[cid] ~= name then
			return nil
		end
		sanitized.component_id = cid
	else
		local pid = tonumber(data.prop_id)
		if not pid or not isFiniteNumber(pid) then
			return nil
		end
		pid = math.floor(pid)
		if shared.propMap[pid] ~= name then
			return nil
		end
		sanitized.prop_id = pid
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
	return tonumber(balance) or 0
end

function clothing.addClothing(payload)
	local src = payload.source
	if isLocked(src) then
		return false
	end
	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	local item = payload.fromSlot
	if not item or not item.metadata then
		unlock(src)
		return false
	end

	local meta = item.metadata
	if meta.component_id then
		TriggerClientEvent("ox_inventory:applyComponent", src, meta)
	elseif meta.prop_id then
		TriggerClientEvent("ox_inventory:applyProp", src, meta)
	else
		unlock(src)
		return false
	end

	unlock(src)
	return true
end

function clothing.removeClothing(payload)
	local src = payload.source
	if isLocked(src) then
		return false
	end
	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	local item = payload.fromSlot
	if not item or not item.metadata then
		unlock(src)
		return false
	end

	local outfitSlot = shared.clothing.nameToSlots.outfits
	local outfitItem = Inventory.GetSlot(clothes, outfitSlot)
	if outfitItem and countWornItems(clothes) == 1 then
		Inventory.RemoveItem(clothes, outfitItem.name, 1, nil, outfitSlot)
	end

	local meta = item.metadata
	if meta.component_id then
		TriggerClientEvent("ox_inventory:removeComponent", src, meta.component_id)
	elseif meta.prop_id then
		TriggerClientEvent("ox_inventory:removeProp", src, meta.prop_id)
	else
		unlock(src)
		return false
	end

	unlock(src)
	return true
end

function clothing.addOutfit(payload)
	local src = payload.source
	if isLocked(src) then
		return false
	end
	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	local item = payload.fromSlot
	if not item or not item.metadata then
		unlock(src)
		return false
	end

	local outfit = sanitizeClothesPayload(item.metadata.outfit)
	if not outfit or next(outfit) == nil then
		unlock(src)
		return false
	end

	for name in pairs(outfit) do
		if not shared.clothing.nameToSlots[name] then
			unlock(src)
			return false
		end
	end

	local componentsToApply = {}
	local propsToApply = {}

	local displaced = {}

	local function rollbackDisplaced()
		for _, d in ipairs(displaced) do
			Inventory.RemoveItem(player, d.name, 1, nil, d.playerSlot)
			Inventory.AddItem(clothes, d.name, 1, d.metadata, d.slot)
		end
	end

	for name, data in pairs(outfit) do
		local slot = shared.clothing.nameToSlots[name]
		local currentItem = Inventory.GetSlot(clothes, slot)

		if currentItem then
			if not Inventory.RemoveItem(clothes, currentItem.name, 1, nil, slot) then
				rollbackDisplaced()
				pendingAdded[src] = nil
				unlock(src)
				return false
			end

			local addedSlot = Inventory.AddItem(player, "clothes_" .. name, 1, currentItem.metadata)
			if not addedSlot then
				Inventory.AddItem(clothes, currentItem.name, 1, currentItem.metadata, slot)
				rollbackDisplaced()
				pendingAdded[src] = nil
				unlock(src)
				return false
			end

			local playerSlot = type(addedSlot) == "table" and addedSlot.slot or nil
			table.insert(displaced,
				{ name = "clothes_" .. name, metadata = currentItem.metadata, slot = slot, playerSlot = playerSlot })
		end

		if data.component_id then
			table.insert(componentsToApply, data)
		elseif data.prop_id then
			table.insert(propsToApply, data)
		else
			rollbackDisplaced()
			pendingAdded[src] = nil
			unlock(src)
			return false
		end
	end

	local addedItems = {}

	local function rollbackPhase2()
		for _, a in ipairs(addedItems) do
			Inventory.RemoveItem(clothes, a.name, 1, nil, a.slot)
		end
		rollbackDisplaced()
		pendingAdded[src] = nil
		unlock(src)
	end

	for _, data in ipairs(componentsToApply) do
		local name = shared.componentMap[data.component_id]
		if not name then
			rollbackPhase2()
			return false
		end

		local slot = shared.clothing.nameToSlots[name]
		local success = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
			component_id = data.component_id,
			drawable = data.drawable,
			texture = data.texture,
			collection = data.collection,
			localIndex = data.localIndex,
		}, slot)

		if not success then
			rollbackPhase2()
			return false
		end
		table.insert(addedItems, { name = "clothes_" .. name, slot = slot })
	end

	for _, data in ipairs(propsToApply) do
		local name = shared.propMap[data.prop_id]
		if not name then
			rollbackPhase2()
			return false
		end

		local slot = shared.clothing.nameToSlots[name]
		local success = Inventory.AddItem(clothes, "clothes_" .. name, 1, {
			prop_id = data.prop_id,
			drawable = data.drawable,
			texture = data.texture,
			collection = data.collection,
			localIndex = data.localIndex,
		}, slot)

		if not success then
			rollbackPhase2()
			return false
		end
		table.insert(addedItems, { name = "clothes_" .. name, slot = slot })
	end

	pendingAdded[src] = { components = componentsToApply, props = propsToApply }
	return true
end

function clothing.removeOutfit(payload)
	local src = payload.source
	if isLocked(src) then
		return false
	end
	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	local item = payload.fromSlot
	if not item or not item.metadata then
		unlock(src)
		return false
	end

	local outfitSlot = shared.clothing.nameToSlots.outfits
	local componentsToRemove = {}
	local propsToRemove = {}

	for slot, data in pairs(clothes.items) do
		if slot ~= outfitSlot and data then
			if data.metadata then
				if data.metadata.component_id then
					table.insert(componentsToRemove, data.metadata.component_id)
				elseif data.metadata.prop_id then
					table.insert(propsToRemove, data.metadata.prop_id)
				end
			end
			Inventory.RemoveItem(clothes, data.name, 1, nil, slot)
		end
	end

	pendingRemoved[src] = { components = componentsToRemove, props = propsToRemove }
	return true
end

local function handleClothingHook(payload)
	local src = payload.source
	local action = payload.action

	if isLocked(src) then
		return false
	end
	if action ~= "move" and action ~= "swap" then
		return false
	end

	local toType = payload.toType
	local fromType = payload.fromType
	local toSlot = getSlotId(payload.toSlot)

	if toType ~= "clothes" and fromType ~= "clothes" then
		return false
	end

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

local function handleOutfitHook(payload)
	local src = payload.source
	local action = payload.action

	if isLocked(src) then
		return false
	end

	local toType = payload.toType
	local fromType = payload.fromType
	local toSlot = getSlotId(payload.toSlot)

	if action == "move" then
		if payload.toInventory == "newdrop" then
			lib.notify(src, {
				title = "Vêtements",
				description = "Vous ne pouvez pas directement déposer de tenues pour le moment.",
				type = "error",
				duration = 7500,
			})
			return false
		end

		if toType == "clothes" then
			local slotName = toSlot and shared.clothing.slotToName[toSlot]
			if not slotName or ("clothes_" .. slotName) ~= payload.fromSlot.name then
				return false
			end
		end

		return toType == "clothes" and clothing.addOutfit(payload) or clothing.removeOutfit(payload)
	elseif action == "swap" then
		if toType == "clothes" or fromType == "clothes" then
			lib.notify(src, {
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

local CLOTHING_ITEM_FILTER = {}
local CLOTHES_INV_FILTER = { "^clothes-[%w]+" }

for _, name in pairs(shared.componentMap) do
	CLOTHING_ITEM_FILTER["clothes_" .. name] = true
end
for _, name in pairs(shared.propMap) do
	CLOTHING_ITEM_FILTER["clothes_" .. name] = true
end

CreateThread(function()
	exports.ox_inventory:registerHook("swapItems", handleClothingHook, {
		disableCheck = true,
		itemFilter = CLOTHING_ITEM_FILTER,
		inventoryFilter = CLOTHES_INV_FILTER,
	})

	exports.ox_inventory:registerHook("swapItems", handleOutfitHook, {
		disableCheck = true,
		itemFilter = { clothes_outfits = true },
		inventoryFilter = CLOTHES_INV_FILTER,
	})

	exports.ox_inventory:registerHook("swappedItems", function(payload)
		local src = payload.source
		local player, clothes = getPlayerAndClothes(src)
		if not player then
			return
		end

		if pendingRemoved[src] or pendingAdded[src] then
			return
		end

		local outfitSlot = shared.clothing.nameToSlots.outfits
		local outfitItem = clothes.items[outfitSlot]

		if outfitItem and outfitItem.metadata then
			local isLeaving = payload.action == "move"
				and payload.fromType == "clothes"
				and type(payload.fromSlot) == "table"
			local isArriving = payload.action == "move"
				and payload.toType == "clothes"
				and type(payload.toSlot) == "number"

			local current = {}
			for slot, data in pairs(clothes.items) do
				if slot ~= outfitSlot and data and data.metadata then
					if not (isLeaving and payload.fromSlot and slot == payload.fromSlot.slot) then
						local name = shared.clothing.slotToName[slot]
						if name then
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
				end
			end

			if isArriving and payload.fromSlot and payload.fromSlot.metadata then
				local name = shared.clothing.slotToName[payload.toSlot]
				if name then
					current[name] = {
						component_id = payload.fromSlot.metadata.component_id or nil,
						prop_id = payload.fromSlot.metadata.prop_id or nil,
						drawable = payload.fromSlot.metadata.drawable,
						texture = payload.fromSlot.metadata.texture,
						collection = payload.fromSlot.metadata.collection,
						localIndex = payload.fromSlot.metadata.localIndex,
					}
				end
			end

			local newMeta = table.clone(outfitItem.metadata)
			newMeta.outfit = current
			Inventory.SetMetadata(clothes, outfitSlot, newMeta)
			Inventory.Save(clothes)
		end
	end, {
		disableCheck = true,
		itemFilter = CLOTHING_ITEM_FILTER,
		inventoryFilter = CLOTHES_INV_FILTER,
	})

	exports.ox_inventory:registerHook("swappedItems", function(payload)
		local src = payload.source

		local removedOutfit = pendingRemoved[src]
		local addedOutfit = pendingAdded[src]
		if not removedOutfit and not addedOutfit then
			return
		end

		pendingRemoved[src] = nil
		pendingAdded[src] = nil

		local player, clothes = getPlayerAndClothes(src)
		if not player then
			unlock(src)
			return
		end

		if removedOutfit then
			if removedOutfit.components and #removedOutfit.components > 0 then
				TriggerClientEvent("ox_inventory:removeComponent", src, removedOutfit.components)
			end
			if removedOutfit.props and #removedOutfit.props > 0 then
				TriggerClientEvent("ox_inventory:removeProp", src, removedOutfit.props)
			end
		elseif addedOutfit then
			if addedOutfit.components and #addedOutfit.components > 0 then
				TriggerClientEvent("ox_inventory:applyComponent", src, addedOutfit.components)
			end
			if addedOutfit.props and #addedOutfit.props > 0 then
				TriggerClientEvent("ox_inventory:applyProp", src, addedOutfit.props)
			end
		end

		CreateThread(function()
			Wait(0)
			local _, updatedClothes = getPlayerAndClothes(src)
			if updatedClothes then
				lib.callback.await("ox_inventory:setCurrentClothes", src, updatedClothes)
				Inventory.Save(updatedClothes)
			end
			unlock(src)
		end)
	end, {
		disableCheck = true,
		itemFilter = { clothes_outfits = true },
		inventoryFilter = CLOTHES_INV_FILTER,
	})
end)

lib.callback.register("ox_inventory:getClothesInventory", function(source)
	local src = source
	if isLocked(src) then
		return false
	end

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		return false
	end

	return clothes
end)

lib.callback.register("ox_inventory:syncClothes", function(source, playerClothes, save)
	local src = source

	if isLocked(src) then
		return false
	end

	local sanitizedClothes = sanitizeClothesPayload(playerClothes)
	if not sanitizedClothes then
		return false
	end

	if save ~= nil then
		shared.saveAppearanceServer(src, save)
	end

	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	for name, slot in pairs(shared.clothing.nameToSlots) do
		if name ~= "outfits" then
			local currentItem = Inventory.GetSlot(clothes, slot)
			local clothData = sanitizedClothes[name]

			if clothData then
				if not currentItem then
					if
						not Inventory.AddItem(clothes, "clothes_" .. name, 1, {
							component_id = clothData.component_id or nil,
							prop_id = clothData.prop_id or nil,
							drawable = clothData.drawable,
							texture = clothData.texture,
							collection = clothData.collection,
							localIndex = clothData.localIndex,
						}, slot)
					then
						unlock(src)
						return false
					end
				else
					local meta = currentItem.metadata or {}
					if meta.drawable ~= clothData.drawable or meta.texture ~= clothData.texture then
						Inventory.SetMetadata(clothes, slot, {
							component_id = clothData.component_id or nil,
							prop_id = clothData.prop_id or nil,
							drawable = clothData.drawable,
							texture = clothData.texture,
							collection = clothData.collection,
							localIndex = clothData.localIndex,
						})
					end
				end
			else
				if currentItem then
					if not Inventory.RemoveItem(clothes, currentItem.name, 1, nil, slot) then
						unlock(src)
						return false
					end
				end
			end
		end
	end

	unlock(src)
	return true
end)

lib.callback.register("ox_inventory:setClothes", function(source, changedClothes)
	local src = source
	if isLocked(src) then
		return false
	end

	changedClothes = sanitizeClothesPayload(changedClothes)
	if not changedClothes then
		return false
	end

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		return false
	end

	local isEmpty = true
	if clothes.items then
		for _, item in pairs(clothes.items) do
			if item then
				isEmpty = false
				break
			end
		end
	end

	if not isEmpty then
		print(("[ox_inventory] WARNING: Player %s attempted to use setClothes but inventory is not empty."):format(src))
		return false
	end

	lock(src)

	for name, data in pairs(changedClothes) do
		local slot = shared.clothing.nameToSlots[name]
		if not slot then
			unlock(src)
			return false
		end

		local currentItem = Inventory.GetSlot(clothes, slot)
		if currentItem then
			local meta = currentItem.metadata or {}
			if meta.drawable ~= data.drawable or meta.texture ~= data.texture then
				Inventory.SetMetadata(clothes, slot, {
					label = meta.label or nil,
					component_id = data.component_id or nil,
					prop_id = data.prop_id or nil,
					drawable = data.drawable,
					texture = data.texture,
					collection = data.collection,
					localIndex = data.localIndex,
				})
			end
		else
			if
				not Inventory.AddItem(clothes, "clothes_" .. name, 1, {
					component_id = data.component_id or nil,
					prop_id = data.prop_id or nil,
					drawable = data.drawable,
					texture = data.texture,
					collection = data.collection,
					localIndex = data.localIndex,
				}, slot)
			then
				unlock(src)
				return false
			end
		end
	end

	unlock(src)
	return true
end)

lib.callback.register("ox_inventory:checkClothes", function(source, changedClothes, payment, clothingType)
	local src = source

	if isLocked(src) then
		return false
	end
	if isPurchaseRateLimited(src) then
		return false
	end

	local sanitizedClothes = sanitizeClothesPayload(changedClothes)
	if not sanitizedClothes then
		return false
	end

	if payment ~= "cash" and payment ~= "bank" then
		return false
	end
	if clothingType ~= "clothes" and clothingType ~= "outfit" then
		return false
	end

	local amount = 0
	for name in pairs(sanitizedClothes) do
		amount = amount + (shared.clothing.nameToPrice[name] or 0)
	end

	lock(src)

	local player, clothes = getPlayerAndClothes(src)
	if not player then
		unlock(src)
		return false
	end

	if amount > 0 then
		if getPaymentBalance(src, payment) < amount then
			unlock(src)
			lib.notify(src, {
				title = "Vêtements",
				description = "Vous n'avez pas assez d'argent",
				type = "error",
				duration = 7500,
			})
			return false
		end

		if not exports.qbx_core:RemoveMoney(src, payment, amount, "Achat de vêtements") then
			unlock(src)
			lib.notify(src, {
				title = "Vêtements",
				description = "Erreur lors du paiement",
				type = "error",
				duration = 7500,
			})
			return false
		end
	end

	if clothingType == "clothes" then
		for name, data in pairs(sanitizedClothes) do
			local slot = shared.clothing.nameToSlots[name]
			if not slot then
				unlock(src)
				if amount > 0 then
					exports.qbx_core:AddMoney(src, payment, amount, "Remboursement vêtements")
				end
				return false
			end

			local currentItem = Inventory.GetSlot(clothes, slot)
			local meta = currentItem and currentItem.metadata or {}

			if
				not Inventory.AddItem(player, "clothes_" .. name, 1, {
					label = meta.label or nil,
					component_id = data.component_id or nil,
					prop_id = data.prop_id or nil,
					drawable = data.drawable,
					texture = data.texture,
					collection = data.collection,
					localIndex = data.localIndex,
				})
			then
				unlock(src)
				if amount > 0 then
					exports.qbx_core:AddMoney(src, payment, amount, "Remboursement vêtements")
				end
				return false
			end
		end
	else
		if not Inventory.AddItem(player, "clothes_outfits", 1, { outfit = sanitizedClothes }) then
			unlock(src)
			if amount > 0 then
				exports.qbx_core:AddMoney(src, payment, amount, "Remboursement vêtements")
			end
			return false
		end
	end

	unlock(src)
	return true
end)

exports("EnableClothing", function(source)
	if type(source) ~= "number" or source <= 0 then return end
	disabled[source] = nil
end)

exports("DisableClothing", function(source)
	if type(source) ~= "number" or source <= 0 then return end
	disabled[source] = true
end)

exports("IsClothingDisabled", function(source)
	if type(source) ~= "number" or source <= 0 then return false end
	return disabled[source] == true
end)

exports("GetPlayerClothes", function(source)
	if isLocked(source) then
		return false
	end

	local player, clothes = getPlayerAndClothes(source)
	if not player then
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
	if isLocked(source) then
		return false
	end

	clothesData = sanitizeClothesPayload(clothesData)
	if not clothesData then
		return false
	end

	local player, clothes = getPlayerAndClothes(source)
	if not player then
		return false
	end

	lock(source)

	for name, data in pairs(clothesData) do
		local slot = shared.clothing.nameToSlots[name]
		if slot then
			local currentItem = Inventory.GetSlot(clothes, slot)
			if currentItem then
				Inventory.SetMetadata(clothes, slot, {
					label = currentItem.metadata and currentItem.metadata.label or nil,
					component_id = data.component_id or nil,
					prop_id = data.prop_id or nil,
					drawable = data.drawable,
					texture = data.texture,
					collection = data.collection,
					localIndex = data.localIndex,
				})
			else
				Inventory.AddItem(clothes, "clothes_" .. name, 1, {
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
	unlock(source)
	return true
end)

exports("SyncPlayerClothes", function(source, playerClothes, save)
	if isLocked(source) then
		return false
	end
	if not Inventory(source) then
		return false
	end
	return lib.callback.await("ox_inventory:syncClothes", source, playerClothes, save)
end)

exports("GetClothesInventory", function(source)
	if isLocked(source) then
		return false
	end

	local player, clothes = getPlayerAndClothes(source)
	if not player then
		return false
	end

	return clothes
end)

exports("ClearPlayerClothes", function(source)
	if isLocked(source) then
		return false
	end

	local player, clothes = getPlayerAndClothes(source)
	if not player then
		return false
	end

	lock(source)

	for name, slot in pairs(shared.clothing.nameToSlots) do
		if name ~= "outfits" then
			local currentItem = Inventory.GetSlot(clothes, slot)
			if currentItem then
				Inventory.RemoveItem(clothes, currentItem.name, 1, nil, slot)
			end
		end
	end

	Inventory.Save(clothes)
	unlock(source)
	return true
end)

exports("ApplyClothingComponent", function(source, metadata)
	if isLocked(source) then
		return false
	end
	return lib.callback.await("ox_inventory:applyComponent", source, metadata)
end)

exports("ApplyClothingProp", function(source, metadata)
	if isLocked(source) then
		return false
	end
	return lib.callback.await("ox_inventory:applyProp", source, metadata)
end)

exports("RemoveClothingComponent", function(source, componentIds)
	if isLocked(source) then
		return false
	end
	return lib.callback.await("ox_inventory:removeComponent", source, componentIds)
end)

exports("RemoveClothingProp", function(source, propIds)
	if isLocked(source) then
		return false
	end
	return lib.callback.await("ox_inventory:removeProp", source, propIds)
end)

AddEventHandler("playerDropped", function()
	local src = source
	locks[src] = nil
	disabled[src] = nil
	pendingRemoved[src] = nil
	pendingAdded[src] = nil
	lastPurchase[src] = nil
end)
