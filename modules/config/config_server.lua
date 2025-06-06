return {
    bulkstashsave = true,
    loglevel = 1,
    randomprices = false,
    randomloot = true,
    evidencegrade = 2,
    trimplate = true,
    vehicleloot = {},
    dumpsterloot = {},
    accounts = { 'money' },

    enablePhysicsSystem = false,
    enablePresetsSystem = false,

    physicsConfig = {
        weightThresholds = {
            light = 0.4,
            medium = 0.7,
            heavy = 0.9
        },
        movementPenalty = 0.3,
        staminaPenalty = 0.2,
        weaponPenalty = 0.1
    },

    presets = {
        police_basic = {
            label = "Police Basic Kit",
            items = {
                { item = "WEAPON_PISTOL", count = 1, metadata = { ammo = 50 } },
                { item = "handcuffs",     count = 2 },
                { item = "radio",         count = 1 }
            },
            jobs = { "police" },
            weight_check = true,
            max_uses = 1,                                 -- Solo 1 uso por jugador
            reset_on_death = false,                       -- No resetea al morir
            reset_on_job_change = true,                   -- Resetea al cambiar trabajo
            activator_item = "police_card",               -- Item que activa el preset
            activator_coords = vec3(441.0, -982.0, 30.0), -- Coordenadas donde se puede usar
            activator_distance = 3.0                      -- Distancia máxima
        },
        medic_basic = {
            label = "Medic Basic Kit",
            items = {
                { item = "bandage", count = 5 },
                { item = "medikit", count = 2 }
            },
            jobs = { "ambulance" },
            weight_check = true,
            max_uses = 1,
            reset_on_death = false,
            reset_on_job_change = true,
            activator_item = "medic_card",
            activator_coords = vec3(307.0, -1433.0, 29.0),
            activator_distance = 3.0
        },
        newbie_kit = {
            label = "Newbie Starter Kit",
            items = {
                { item = "phone", count = 1 },
                { item = "water", count = 2 },
                { item = "bread", count = 3 }
            },
            weight_check = true,
            max_uses = 1, -- Solo una vez en la vida
            reset_on_death = false,
            reset_on_job_change = false,
            new_player_only = true -- Solo para jugadores nuevos
        }
    }
}
