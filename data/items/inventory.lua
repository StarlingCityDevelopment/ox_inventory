return {
    ['money'] = {
        label = 'Argent',
    },

    ['black_money'] = {
        label = 'Argent sale',
    },

    ['newspaper'] = {
        label = 'Journal',
        weight = 10,
        stack = false,
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
