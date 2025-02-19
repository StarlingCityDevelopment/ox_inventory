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
        label = 'Paquet de Cigarette',
        weight = 10,
        stack = false,
    },

    ['document'] = {
        label = 'Document',
        weight = 10,
        stack = false,
        client = {
            export = 'k5_documents.show',
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
}