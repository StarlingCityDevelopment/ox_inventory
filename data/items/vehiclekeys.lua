return {
    ["vehiclekeys"] = {
        label = "Clés",
        weight = 25,
        stack = false,
        close = false,
        consume = 0,
        client = {
            export = 'qs-vehiclekeys.useKey',
        },
    },

    ['plate'] = {
        label = 'Plaque',
        weight = 100,
        stack = true,
        close = false,
        consume = 0,
        client = {
            export = 'qs-vehiclekeys.usePlate',
        },
    },

    ['carlockpick'] = {
        label = 'Crochet de voiture',
        weight = 100,
        stack = true,
        close = false,
        description = "Crochet pour véhicule",
        client = {
            export = 'qs-vehiclekeys.useCarlockpick',
        },
    },

    ['caradvancedlockpick'] = {
        label = 'Crochet avancé',
        weight = 100,
        stack = true,
        close = false,
        description = "Crochet pour véhicule",
        client = {
            export = 'qs-vehiclekeys.useAdvancedCarlockpick',
        },
    },

    ['vehiclegps'] = {
        label = 'GPS de véhicule',
        weight = 100,
        stack = true,
        close = false,
        description = "Appareil GPS pour quoi...?",
        client = {
            export = 'qs-vehiclekeys.useVehiclegps',
        },
    },

    ['vehicletracker'] = {
        label = 'Traceur de véhicule',
        weight = 100,
        stack = true,
        close = false,
        description = "Il semble transmettre des sondes",
        client = {
            export = 'qs-vehiclekeys.useVehicletracker',
        },
    },

    ['rentalpaper'] = {
        label = 'Papier de location',
        weight = 10,
        stack = false,
    },
}
