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
        consume = 1
    },

    ['document'] = {
        label = 'Document',
        weight = 10,
        stack = false,
        client = {
            export = 'starling_documents.show',
        }
    },

    ['mastercard'] = {
        label = 'Carte de crédit',
        stack = false,
        weight = 10,
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

    ["tosti"] = {
        label = "Tosti",
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = {
                model = 'v_res_fa_bread03',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 }
            },
            usetime = 2500
        }
    },
}
