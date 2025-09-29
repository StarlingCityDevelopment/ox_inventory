return {
    ['handcuffs'] = {
        label = 'Menottes',
        weight = 2,
        stack = true,
        close = true,
    },

    ['bobby_pin'] = {
        label = 'Épingle à cheveux',
        weight = 2,
        stack = true,
        close = true,
    },

    ['tracking_bracelet'] = {
        label = 'Bracelet de surveillance',
        weight = 2,
        stack = true,
        close = true,
    },

    ["bodycam"] = {
        label = "bodycam",
        weight = 150,
        stack = false,
        close = true,
        description = "Bodycam",
        client = {
            event = "spy-bodycam:bodycamstatus"
        }
    },
    
    ["dashcam"] = {
        label = "dashcam",
        weight = 150,
        stack = false,
        close = true,
        description = "dashcam",
        client = {
            event = "spy-bodycam:toggleCarCam"
        }
    },
}
