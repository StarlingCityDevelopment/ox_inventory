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
        consume = 0,
    },

    ["keyring"] = {
        label = "Porte-clés",
        weight = 25,
        stack = false,
        close = false,
        consume = 0,
    },

}
