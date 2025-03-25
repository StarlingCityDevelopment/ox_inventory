return {
    ["water_bottle"] = {
    label = "Bouteille d'eau",
    weight = 333,
    stack = true,
    close = true,
    consume = 1,
    client = {
        disable = {sprint = true},
        usetime = 2500
    }
},
    ["sandwich"] = {
    label = "Sandwich",
    weight = 500,
    stack = true,
    close = true,
    consume = 1,
    client = {
        disable = {sprint = true},
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
        prop = {
            model = 'prop_cs_burger_01',
            pos = { x = 0.02, y = 0.02, z = -0.02},
            rot = { x = 0.0, y = 0.0, z = 0.0}
        },
        usetime = 2500
    }
},
    ["cereal_stick"] = {
    label = "Barre de Céréales",
    weight = 50,
    stack = true,
    close = true,
    consume = 1,
    client = {
        disable = {sprint = true},
        usetime = 2500
    }
},
    ["candy"] = {
    label = "Bonbon",
    weight = 10,
    stack = true,
    close = true,
    consume = 1,
    client = {
        disable = {sprint = true},
        usetime = 2500
    }
},
    ["bread"] = {
    label = "Pain",
    weight = 250,
    stack = true,
    close = true,
    consume = 1,
    client = {
        disable = {sprint = true},
        anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
        prop = {
            model = 'prop_cs_burger_01',
            pos = { x = 0.02, y = 0.02, z = -0.02},
            rot = { x = 0.0, y = 0.0, z = 0.0}
        },
        usetime = 2500
    }
},
}