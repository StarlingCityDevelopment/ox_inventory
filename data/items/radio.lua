return {
    ['radio'] = {
        label = 'Radio',
        weight = 750,
        allowArmed = true,
        client = {
            event = 'mm_radio:client:use'
        }
    },

    ['jammer'] = {
        label = 'Brouilleur Radio',
        weight = 10000,
        allowArmed = true,
        close = true,
        consume = 0.1,
        client = {
            event = 'mm_radio:client:usejammer'
        }
    },

    ['radiocell'] = {
        label = 'Piles AAA',
        weight = 100,
        stack = true,
        consume = 2,
        client = {
            event = 'mm_radio:client:recharge'
        }
    },
}
