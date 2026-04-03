return {
    ['money'] = {
        label = 'Argent',
    },

    ['black_money'] = {
        label = 'Argent sale',
    },

    ['skateboard'] = {
        label = 'Skateboard',
        weight = 750,
        stack = false,
    },

    ['newspaper'] = {
        label = 'Journal',
        weight = 10,
        stack = false,
    },

    ['cigarette'] = {
        label = 'Cigarette',
        weight = 10,
        stack = true,
        close = true,
    },

    ['document'] = {
        label = 'Document',
        weight = 10,
        stack = false,
        client = {
            export = 'starling_documents.show',
        }
    },

    ["phone"] = {
        label = "Téléphone",
        weight = 190,
        stack = false,
        consume = 0,
        client = {
            export = "lb-phone.UsePhoneItem",
            remove = function()
                TriggerEvent("lb-phone:itemRemoved")
            end,
            add = function()
                TriggerEvent("lb-phone:itemAdded")
            end
        }
    },

    -- ['magazine'] = {
    --     label = 'Magazine',
    --     consume = 0,
    --     weight = 20,
    --     stack = false,
    --     client = {
    --         export = 'sleepless_inventory_addons.useMagazine',
    --     },
    --     magazine = true,
    -- },

    ["wallet"] = {
        label = "Porte monnaie",
        weight = 25,
        stack = false,
        close = false,
    },

    ["keyring"] = {
        label = "Porte-clés",
        weight = 25,
        stack = false,
        close = false,
    },

    ["bs_10p"] = {
        label = "Réduction 10% Burger Shot",
        weight = 1,
        stack = true,
        close = false,
    },

    ["ts_10p"] = {
        label = "Réduction 10% Tsubaki Sushi",
        weight = 1,
        stack = true,
        close = false,
    },

    ["vu_10p"] = {
        label = "Réduction 10% Vanilla Unicorn",
        weight = 1,
        stack = true,
        close = false,
    },

    ["cn_10p"] = {
        label = "Réduction 10% Coffee Noir",
        weight = 1,
        stack = true,
        close = false,
    },

    ["cc_10p"] = {
        label = "Réduction 10% Cruisin Craftsmen",
        weight = 1,
        stack = true,
        close = false,
    },

    ["lsc_10p"] = {
        label = "Réduction 10% Los Santos Customs",
        weight = 1,
        stack = true,
        close = false,
    },

    ["bs_15p"] = {
        label = "Réduction 15% Burger Shot",
        weight = 1,
        stack = true,
        close = false,
    },

    ["ts_15p"] = {
        label = "Réduction 15% Tsubaki Sushi",
        weight = 1,
        stack = true,
        close = false,
    },

    ["vu_15p"] = {
        label = "Réduction 15% Vanilla Unicorn",
        weight = 1,
        stack = true,
        close = false,
    },

    ["cn_15p"] = {
        label = "Réduction 15% Coffee Noir",
        weight = 1,
        stack = true,
        close = false,
    },

    ["cc_15p"] = {
        label = "Réduction 15% Cruisin Craftsmen",
        weight = 1,
        stack = true,
        close = false,
    },

    ["lsc_15p"] = {
        label = "Réduction 15% Los Santos Customs",
        weight = 1,
        stack = true,
        close = false,
    },

    -- EVENT

    ["easteregg"] = {
        label = "Oeuf de Pâques",
        weight = 50,
        stack = true,
        close = true,
    },

    ["easterrabbit"] = {
        label = "Oeuf de Pâques",
        weight = 200,
        stack = true,
        close = true,
    },
}