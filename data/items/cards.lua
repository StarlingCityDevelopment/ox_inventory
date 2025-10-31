return {
    ['mastercard'] = {
        label = 'Carte de crédit',
        stack = false,
        weight = 10,
    },

    ["id_card"] = {
        label = "Carte d'identité",
        weight = 10,
        stack = false,
        close = true,
        allowArmed = true,
        client = {
            disable = { combat = true },
        }
    },

    ["driver_license"] = {
        label = "Permis de conduire",
        weight = 10,
        stack = false,
        close = true,
        allowArmed = true,
        client = {
            disable = { combat = true },
        }
    },
}
