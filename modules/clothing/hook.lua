local disabled = {}
local clothing = require 'modules.clothing.server'

CreateThread(function()
    local function handleClothingHook(payload)
        if disabled[payload.source] then
            return false
        end

        if payload.action ~= 'move' and payload.action ~= 'swap' then
            return false
        end

        if payload.toType == 'clothes' or payload.fromType == 'clothes' then
            if payload.action == 'move' then
                return payload.toType == 'clothes'
                    and clothing.addClothing(payload)
                    or clothing.removeClothing(payload)
            elseif payload.action == 'swap' then

                local isClothingSwap = payload.fromSlot.name:match('clothes')
                    and payload.toSlot.name:match('clothes')
                return isClothingSwap and clothing.addClothing(payload) or false
            end
        end

        return false
    end

    local clothingItemFilter = {
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
        clothes_decals = true
    }

    exports.ox_inventory:registerHook('swapItems', handleClothingHook, {
        disableCheck = true,
        itemFilter = clothingItemFilter,
        inventoryFilter = { '^clothes_[%w]+' }
    })

    local function handleOutfitHook(payload)
        if disabled[payload.source] then
            return false
        end

        if payload.action == 'move' then
            return payload.toType == 'clothes' and clothing.addOutfit(payload) or clothing.removeOutfit(payload)
        elseif payload.action == 'swap' then
            if payload.toType == 'clothes' or payload.fromType == 'clothes' then
                lib.notify(payload.source, {
                    type = 'error',
                    title = 'Inventaire',
                    description = 'Impossible de déplacer un outfit si un outfit est déjà équipé.'
                })
                return false
            end
        end

        return true
    end

    exports.ox_inventory:registerHook('swapItems', handleOutfitHook, {
        disableCheck = true,
        itemFilter = { clothes_outfits = true },
        inventoryFilter = { '^clothes_[%w]+' }
    })
end)

RegisterNetEvent('ox_inventory:enableClothings', function()
    local src = source
    disabled[src] = false
end)

RegisterNetEvent('ox_inventory:disableClothings', function()
    local src = source
    disabled[src] = true
end)
