return {
    ['medikit'] = { -- Make sure not already a medikit
        label = 'Medikit',
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
		client = {
            anim = { dict = 'amb@medic@standing@kneel@idle_a', clip = 'idle_a' },
            prop = {
                model = 'm23_1_prop_m31_crate_medical',
                pos = { x = 0.02, y = 0.02, z = -0.02},
                rot = { x = 0.0, y = 0.0, z = 0.0}
            },
			disable = {sprint = true, car = true, combat = true, },
			usetime = 5000,
		}
    },
    ['medbag'] = {
        label = 'Sac Medical',
        weight = 500,
        stack = true,
        close = true,
        consume = 1,
		client = {
            anim = { dict = 'amb@medic@standing@kneel@idle_a', clip = 'idle_a' },
            prop = {
                model = 'prop_ld_health_pack',
                pos = { x = 0.02, y = 0.02, z = -0.02},
                rot = { x = 0.0, y = 0.0, z = 0.0}
            },
			disable = {sprint = true, car = true, combat = true, },
			usetime = 4000,
		}
    },

    ['tweezers'] = {
        label = 'Pince à Epiler',
        weight = 10,
        stack = true,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, car = true, combat = true, },
			usetime = 2500,
		}
    },

    ['suturekit'] = {
        label = 'Kit de Suture',
        weight = 150,
        stack = true,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, car = true, combat = true, },
			usetime = 3500,
		}
    },

    ['icepack'] = {
        label = 'Sac de Glace',
        weight = 100,
        stack = true,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, car = true, combat = true, },
			usetime = 2000,
		}
    },

    ['burncream'] = {
        label = 'Crême Anti-Brûlures',
        weight = 100,
        stack = true,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, car = true, combat = true, },
			usetime = 3000,
		}
    },

    ['defib'] = {
        label = 'Défibrilateur',
        weight = 1000,
        stack = false,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, car = true, combat = true},
			usetime = 8000,
		}
    },

    ['sedative'] = {
        label = 'Sédatif',
        weight = 50,
        stack = true,
        close = true,
        consume = 1,
		client = {
        	disable = {sprint = true},
			usetime = 4000,
		}
    },

    ['morphine30'] = {
        label = 'Morphine 30MG',
        weight = 6,
        stack = true,
        close = true,
        consume = 1,
		client = {
            disable = {sprint = true, combat = true},
			usetime = 6000,
		}
    },

    ['morphine15'] = {
        label = 'Morphine 15MG',
        weight = 3,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 3000,
		}
    },

    ['perc30'] = {
        label = 'Percocet 30MG',
        weight = 6,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 6000,
		}
    },

    ['perc10'] = {
        label = 'Percocet 10MG',
        weight = 2,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 2000,
		}
    },

    ['perc5'] = {
        label = 'Percocet 5MG',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 1000,
		}
    },

    ['vic10'] = {
        label = 'Vicodine 10MG',
        weight = 2,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 2000,
		}
    },

    ['vic5'] = {
        label = 'Vicodine 5MG',
        weight = 1,
        stack = true,
        close = true,
        consume = 1,
		client = {
			disable = {sprint = true, combat = true},
			usetime = 1000,
		}
    },

    ['recoveredbullet'] = {
        label = 'Balle Extraite',
        weight = 1,
        stack = true,
        close = false,
        consume = 1,
    },
}
