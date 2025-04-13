return {
    ["water_bottle"] = {
        label = "Bouteille d'eau",
        weight = 250,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true, combat = true },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = {
                model = 'h4_prop_club_water_bottle',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 }
            },
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
            disable = { sprint = true, combat = true },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = {
                model = 'prop_sandwich_01',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 }
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
            disable = { sprint = true, combat = true },
            usetime = 1500
        }
    },

    ["candy"] = {
        label = "Bonbon",
        weight = 10,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true, combat = true },
            usetime = 1500
        }
    },

    ["chocolatebar"] = {
        label = "Barre Chocolatée",
        weight = 50,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true, combat = true },
            usetime = 1500
        }
    },

    ["soda"] = {
        label = "Soda",
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true, combat = true },
            anim = { dict = 'mp_player_intdrink', clip = 'loop_bottle' },
            prop = {
                model = 'ng_proc_sodacan_01a',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 }
            },
            usetime = 3000
        }
    },

    ["chips"] = {
        label = "Chips",
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
        client = {
            disable = { sprint = true, combat = true },
            anim = { dict = 'mp_player_inteat@burger', clip = 'mp_player_int_eat_burger_fp' },
            prop = {
                model = 'v_ret_ml_chips1',
                pos = { x = 0.02, y = 0.02, z = -0.02 },
                rot = { x = 0.0, y = 0.0, z = 0.0 }
            },
            usetime = 3000
        }
    },
}
