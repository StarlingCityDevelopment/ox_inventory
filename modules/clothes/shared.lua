shared.clothing = {
    male = {
        -- Drawables
        ["masks"] = { drawable = 0, texture = 0, },
        ["torsos"] = { drawable = 15, texture = 0, },
        ["legs"] = { drawable = 14, texture = 1, },
        ["bags"] = { drawable = 0, texture = 0, },
        ["shoes"] = { drawable = 34, texture = 0, },
        ["neck"] = { drawable = 0, texture = 0, },
        ["shirts"] = { drawable = 15, texture = 0, },
        ["vest"] = { drawable = 0, texture = 0, },
        ["decals"] = { drawable = 0, texture = 0, },
        ["jackets"] = { drawable = 15, texture = 0, },
        -- Props
        ["hats"] = { drawable = -1, texture = -1, },
        ["glasses"] = { drawable = -1, texture = -1, },
        ["earrings"] = { drawable = -1, texture = -1, },
        ["watches"] = { drawable = -1, texture = -1, },
        ["bracelets"] = { drawable = -1, texture = -1, },
    },
    female = {
        -- Drawables
        ["masks"] = { drawable = 0, texture = 0, },
        ["torsos"] = { drawable = 15, texture = 0, },
        ["legs"] = { drawable = 14, texture = 1, },
        ["bags"] = { drawable = 0, texture = 0, },
        ["shoes"] = { drawable = 34, texture = 0, },
        ["neck"] = { drawable = 0, texture = 0, },
        ["shirts"] = { drawable = 15, texture = 0, },
        ["vest"] = { drawable = 0, texture = 0, },
        ["decals"] = { drawable = 0, texture = 0, },
        ["jackets"] = { drawable = 15, texture = 0, },
        -- Props
        ["hats"] = { drawable = -1, texture = -1, },
        ["glasses"] = { drawable = -1, texture = -1, },
        ["earrings"] = { drawable = -1, texture = -1, },
        ["watches"] = { drawable = -1, texture = -1, },
        ["bracelets"] = { drawable = -1, texture = -1, },
    },
    nameToSlots = { -- DO NOT MODIFY
        ["jackets"] = 1,
        ["shirts"] = 2,
        ["torsos"] = 3,
        ["bags"] = 4,
        ["vest"] = 5,
        ["legs"] = 6,
        ["shoes"] = 7,
        ["outfits"] = 8, -- Not used in clothing items, but reserved for outfits
        ["hats"] = 9,
        ["masks"] = 10,
        ["glasses"] = 11,
        ["earrings"] = 12,
        ["neck"] = 13,
        ["watches"] = 14,
        ["bracelets"] = 15,
        ["decals"] = 16,
    },
    slotToName = { -- DO NOT MODIFY
        [1] = "jackets",
        [2] = "shirts",
        [3] = "torsos",
        [4] = "bags",
        [5] = "vest",
        [6] = "legs",
        [7] = "shoes",
        [8] = "outfits", -- Not used in clothing items, but reserved for outfits
        [9] = "hats",
        [10] = "masks",
        [11] = "glasses",
        [12] = "earrings",
        [13] = "neck",
        [14] = "watches",
        [15] = "bracelets",
        [16] = "decals",
    },
}

shared.componentMap = {
    -- [0] = "head", Not used for clothing items
    [1] = "masks",
    -- [2] = "hair", Not used for clothing items
    [3] = "torsos",
    [4] = "legs",
    [5] = "bags",
    [6] = "shoes",
    [7] = "neck",
    [8] = "shirts",
    [9] = "vest",
    [10] = "decals",
    [11] = "jackets",
}

shared.propMap = {
    [0] = "hats",
    [1] = "glasses",
    [2] = "earrings",
    [6] = "watches",
    [7] = "bracelets",
}

shared.saveAppearanceClient = function(ped)
    local appearance = exports.bl_appearance:GetPedAppearance(ped)
    return appearance
end

shared.saveAppearanceServer = function(source, appearance)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then
        return
    end
    local cid = player.PlayerData and player.PlayerData.citizenid or "unknown"
    exports.bl_appearance:SavePlayerAppearance(cid, appearance)
end
