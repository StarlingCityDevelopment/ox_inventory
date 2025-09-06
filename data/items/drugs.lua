return {
    ['trap_phone'] = {
        label = 'Trap Phone',
        weight = 200,
    },

    ["watering_can"] = {
        label = "Arrosoir",
        weight = 500,
        stack = true,
        close = false,
        description = "Pour arroser des plantes",
    },

    ["fertilizer"] = {
        label = "Engrais",
        weight = 500,
        stack = true,
        close = false,
        description = "Boisson énergisante pour votre plante",
    },

    ["advanced_fertilizer"] = {
        label = "Engrais de Qualité",
        weight = 500,
        stack = true,
        close = false,
        description = "Le plat préféré de ta plante préféré",
    },

    ["liquid_fertilizer"] = {
        label = "Engrais Liquide",
        weight = 200,
        stack = true,
        close = false,
        description = "De l'eau enrichie. (Ne pas boire !)",
    },

    ["baggie"] = {
        label = "Pochon Vide",
        weight = 1,
        stack = true,
        close = false,
        description = "Un pochon qui ne contient rien",
    },

    ["weed_ak47_seed"] = {
        label = "Graine de AK-47",
        weight = 20,
        stack = true,
        close = true,
        description = "Une hybride connue pour son arôme puissant et ses effets équilibrés entre relaxation et euphorie.",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_ak47"] = {
        label = "Weed AK-47",
        weight = 20,
        stack = true,
        close = false,
        description = "Une hybride connue pour son arôme puissant et ses effets équilibrés entre relaxation et euphorie.",
    },

    ["baggie_ak47"] = {
        label = "Pochon de Weed \"AK47\"",
        weight = 2,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la weed \"AK47\"",
    },

    ["weed_purplekush_seed"] = {
        label = "Graine de Purple Kush",
        weight = 20,
        stack = true,
        close = true,
        description = "Une indica pure réputée pour ses saveurs sucrées et ses effets profondément relaxants et apaisants.",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_purplekush"] = {
        label = "Weed Purple Kush",
        weight = 20,
        stack = true,
        close = false,
        description = "Une indica pure réputée pour ses saveurs sucrées et ses effets profondément relaxants et apaisants.",
    },

    ["baggie_purplekush"] = {
        label = "Pochon de Weed \"Purple Kush\"",
        weight = 2,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la weed \"Purple Kush\"",
    },

    ["weed_creamcaramel_seed"] = {
        label = "Graine de Cream Caramel",
        weight = 20,
        stack = true,
        close = true,
        description = "Une hybride célèbre pour sa résine abondante et ses effets puissants, à la fois énergisants et cérébraux.",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_creamcaramel"] = {
        label = "Weed Cream Caramel",
        weight = 20,
        stack = true,
        close = false,
        description = "Une hybride célèbre pour sa résine abondante et ses effets puissants, à la fois énergisants et cérébraux.",
    },

    ["baggie_creamcaramel"] = {
        label = "Pochon de Weed \"Cream Caramel\"",
        weight = 2,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la weed \"\"",
    },

    ["weed_mooncookies_seed"] = {
        label = "Graine de Moon Cookies",
        weight = 20,
        stack = true,
        close = true,
        description = "Une hybride gourmande aux saveurs sucrées et terreuses, offrant des effets relaxants et légèrement euphoriques.",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_mooncookies"] = {
        label = "Weed Moon Cookies",
        weight = 20,
        stack = true,
        close = false,
        description = "Une hybride gourmande aux saveurs sucrées et terreuses, offrant des effets relaxants et légèrement euphoriques.",
    },

    ["baggie_mooncookies"] = {
        label = "Pochon de Weed \"Moon Cookies\"",
        weight = 2,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la weed \"Moon Cookies\"",
    },

    ["weed_sweetcheese_seed"] = {
        label = "Graine de Sweet Cheese",
        weight = 20,
        stack = true,
        close = true,
        description = "Une hybride au profil aromatique unique mêlant fromage et notes sucrées, avec des effets stimulants et créatifs.",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["weed_sweetcheese"] = {
        label = "Weed Sweet Cheese",
        weight = 20,
        stack = true,
        close = false,
        description = "Une hybride au profil aromatique unique mêlant fromage et notes sucrées, avec des effets stimulants et créatifs.",
        client = {
            image = "weed_sweetcheese.webp",
        }
    },

    ["baggie_sweetcheese"] = {
        label = "Pochon de Weed \"Sweet Cheese\"",
        weight = 2,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la weed \"Sweet Cheese\"",
    },

    ["coca_seed"] = {
        label = "Graine de Coca",
        weight = 20,
        stack = true,
        close = true,
        description = "Une plante \"thérapeuthique\"",
        server = {
            export = "it-drugs.useSeed"
        }
    },

    ["coca"] = {
        label = "Feuille de Coca",
        weight = 20,
        stack = true,
        close = false,
        description = "Ou comment la tortue à réellement battue la lièvre...",
    },

    ["paper"] = {
        label = "Papier à Rouler",
        weight = 50,
        stack = true,
        close = false,
        description = "Pour rouler un Teh",
    },

    ["nitrous"] = {
        label = "Azote",
        weight = 500,
        stack = true,
        close = false,
        description = "Ceci est de l'azote... Au cas où c'était pas clair...",
    },

    ["weed_processing_table"] = {
        label = "Table de Traitement de Weed",
        weight = 1000,
        stack = false,
        close = true,
        description = "Pour traiter de la verte",
        server = {
            export = "it-drugs.placeProcessingTable"
        }
    },

    ["cocaine_processing_table"] = {
        label = "Table de Traitement de Coke",
        weight = 1000,
        stack = false,
        close = true,
        description = "La traite des blanches",
        server = {
            export = "it-drugs.placeProcessingTable"
        }
    },

    ["cocaine"] = {
        label = "Cocaine",
        weight = 20,
        stack = true,
        close = true,
        description = "Blanche-neige t'emmène au pays des merveilles",
        server = {
            export = "it-drugs.takeDrug"
        },
    },

    ["joint"] = {
        label = "Joint",
        weight = 10,
        stack = true,
        close = true,
        description = "Ceci n'est pas un joint de culasse...",
        server = {
            export = "it-drugs.takeDrug"
        },
    },

    ["pochon_coke"] = {
        label = "Pochon de Cocaïne",
        weight = 1,
        stack = true,
        close = false,
        description = "Un pochon qui contient de la coke",
    },

    ["coke_olive"] = {
        label = "Olive de Coke",
        weight = 10,
        stack = true,
        close = false,
        description = "Un caillou de pure cocaïne",
    },

    ["bicarbonate"] = {
        label = "Bicarbonate de Soude",
        weight = 100,
        stack = true,
        close = false,
        description = "Une autre poudre magique",
    },

    ["sirop_codeine"] = {
        label = "Sirop à la Codéine",
        weight = 10,
        stack = true,
        close = true,
        description = "On va dire que c'est pour soigner un rhume...",
    },

    ["spunkgreen_drink"] = {
        label = "Spunk Vert",
        weight = 50,
        stack = true,
        close = true,
        description = "Un soda vert fluo. Surement plein de \"plantes\"...",
    },

    ["cola_drink"] = {
        label = "Cola",
        weight = 50,
        stack = true,
        close = true,
        description = "Le soda classique",
    },

    ["spunkblue_drink"] = {
        label = "Spunk Bleu",
        weight = 50,
        stack = true,
        close = true,
        description = "Un soda bleu clair. Surement plein d'\"eau\"...",
    },

    ["cup"] = {
        label = "Gobelet",
        weight = 1,
        stack = true,
        close = false,
        description =
        "Le gobelet en plastique allie légèreté, praticité et résistance, parfait pour toutes vos boissons en déplacement ou en fête.",
    },

    ["pochon_opium"] = {
        label = "Pochon d'Opium'",
        weight = 10,
        stack = true,
        close = false,
        description = "Elu meilleur produit de l'année 1839",
    },

    ["acetic_acid"] = {
        label = "Vinaigre Ménager",
        weight = 500,
        stack = true,
        close = false,
        description = "Un puissant nettoyant, à base d'acide acétique",
    },

    ["chloroforme"] = {
        label = "Chloroforme",
        weight = 100,
        stack = true,
        close = false,
        description = "Pour une nuit plus paisible.",
    },

    ["pseudoephedrine"] = {
        label = "Pseudoephedrine",
        weight = 10,
        stack = true,
        close = false,
        description = "C’est le coup de boost légal contre le nez bouché",
    },

    ["sulfuric_acid"] = {
        label = "Acide Sulfurique",
        weight = 10,
        stack = true,
        close = false,
        description = "L'acide le plus connu",
    },

    ["acetone"] = {
        label = "Acétone",
        weight = 100,
        stack = true,
        close = false,
        description = "Pour effacer tous vos problèmes",
    },

    ["baindebouche"] = {
        label = "Bain de Bouche",
        weight = 100,
        stack = true,
        close = false,
        description = "Ca ne remplacera pas une vraie hygiène...",
    },

    ["pile"] = {
        label = "Pile",
        weight = 10,
        stack = true,
        close = false,
        description = "Genre les piles rondes des montres là. (tu vois très bien desquels je parle)",
    },

    ["chili"] = {
        label = "Chili",
        weight = 100,
        stack = true,
        close = false,
        description = "The Capn's special recipe",
    },

    ["syringe"] = {
        label = "Seringue",
        weight = 1,
        stack = true,
        close = false,
        description = "Entre les orteils tmtc",
    },

    ["crack"] = {
        label = "Crack",
        weight = 1,
        stack = true,
        close = false,
        description =
        "Est-ce que parfois vous vous sentez irritable, fatigué, mal à l'aise, normal, ou juste pas assez défoncé ? Il est peut-être temps d'essayer le Crack™",
    },

    ["heroine"] = {
        label = "Heroïne",
        weight = 1,
        stack = true,
        close = false,
        description = "Qui a besoin d'une raison quand on a de l'heroïne ?",
    },

    ["meth"] = {
        label = "Méthamphétamine",
        weight = 1,
        stack = true,
        close = false,
        description = "Panzerschokolade der Führers",
    },

    ["bluesky"] = {
        label = "Blue Sky Meth",
        weight = 1,
        stack = true,
        close = false,
        description = "Es claro que Azul",
    },

    ["redice"] = {
        label = "Red Ice Meth",
        weight = 1,
        stack = true,
        close = false,
        description = "Une drogue quantique...",
    },

    ["meth_pipe"] = {
        label = "Pipe de Meth",
        weight = 1,
        stack = true,
        close = false,
        description = "Ceci n'est pas une pipe",
    },

    ["crack_pipe"] = {
        label = "Pipe de Crack",
        weight = 1,
        stack = true,
        close = false,
        description = "Ceci n'est pas une pipe",
    },
}
