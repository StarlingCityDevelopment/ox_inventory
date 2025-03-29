return {
    ['ziptie'] = {
        label = 'Zips',
        weight = 100,
    },

    ['handcuffs'] = {
        label = 'Menottes',
        weight = 250,
    },

    ['cuffkeys'] = {
        label = 'Clé de menottes',
        weight = 50,
    },

    ['flush_cutter'] = {
        label = 'Coupeur affleurant',
        weight = 500,
    },

    ['bolt_cutter'] = {
        label = 'Coupe boulons',
        weight = 1000,
    },

    ['bobby_pin'] = {
        label = 'Pince à Cheveux',
        weight = 2,
        stack = true,
        close = true,
    },

    ["shield"] = {
        label = "Bouclier anti-émeute",
        weight = 8000,
        stack = false,
        consume = 1,
        client = {
            export = "cdx_police.useShield",
        }
    },

    ["spikestrip"] = {
        label = "Bande de clous",
        weight = 1500,
        consume = 1,
        client = {
            export = "cdx_police.deploySpikestrip",
        }
    },
}
