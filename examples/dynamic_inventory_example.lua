-- Dynamic Inventory System Example
-- This example shows how to register and use dynamic inventory types

-- Example 1: Medical Cabinets
-- Register a medical cabinet inventory type
local success, error = exports.ox_inventory:RegisterInventoryType({
    name = 'medical_cabinet',
    models = { 
        -1700911976, -- prop_med_cabinet
        -1364697528  -- prop_med_cabinet_02
    },
    interaction = {
        distance = 2.5,
        icon = 'fas fa-plus-square',
        label = 'Open Medical Cabinet'
    },
    behavior = {
        useNetwork = true,
        freezeEntity = false
    },
    slots = 20,
    maxWeight = 25000,
    items = {
        maxItems = 6,
        items = {
            { name = 'bandage', min = 2, max = 5, chance = 90 },
            { name = 'medikit', min = 1, max = 2, chance = 60 },
            { name = 'painkillers', min = 1, max = 3, chance = 70 },
            { name = 'morphine', min = 1, max = 1, chance = 30 },
            { name = 'defibrillator', min = 1, max = 1, chance = 15 },
            { name = 'surgical_kit', min = 1, max = 1, chance = 10 }
        }
    },
    validation = {
        groups = { ['ambulance'] = 0, ['police'] = 2 }
    }
})

if success then
    print('Medical cabinet inventory type registered successfully')
else
    print('Failed to register medical cabinet:', error)
end

-- Example 2: Police Evidence Lockers
exports.ox_inventory:RegisterInventoryType({
    name = 'evidence_locker',
    models = { 
        -1730716938, -- prop_locker_01
        -1730716939  -- prop_locker_02
    },
    interaction = {
        distance = 2.0,
        icon = 'fas fa-archive',
        label = 'Access Evidence Locker'
    },
    behavior = {
        useNetwork = false
        -- freezeEntity is now automatic for all dynamic inventories
    },
    slots = 30,
    maxWeight = 100000,
    items = {
        maxItems = 8,
        items = {
            { name = 'handcuffs', min = 1, max = 2, chance = 60 },
            { name = 'flashlight', min = 1, max = 1, chance = 40 },
            { name = 'radio', min = 1, max = 1, chance = 50 },
            { name = 'evidence_bag', min = 3, max = 8, chance = 80 },
            { name = 'camera', min = 1, max = 1, chance = 25 },
            { name = 'taser', min = 1, max = 1, chance = 30 },
            { name = 'kevlar', min = 1, max = 1, chance = 20 },
            { name = 'lockpick', min = 1, max = 2, chance = 15 }
        }
    },
    validation = {
        groups = { ['police'] = 0 }
    }
})

-- Example 3: Weapon Caches (High Security)
exports.ox_inventory:RegisterInventoryType({
    name = 'weapon_cache',
    models = { 
        -1507515417, -- prop_gun_case_01
        -1507515418  -- prop_gun_case_02
    },
    interaction = {
        distance = 1.5,
        icon = 'fas fa-crosshairs',
        label = 'Open Weapon Cache'
    },
    behavior = {
        useNetwork = true
        -- freezeEntity is now automatic for all dynamic inventories
    },
    slots = 15,
    maxWeight = 75000,
    items = {
        maxItems = 4,
        items = {
            { name = 'WEAPON_PISTOL', min = 1, max = 1, chance = 70 },
            { name = 'WEAPON_SMG', min = 1, max = 1, chance = 40 },
            { name = 'WEAPON_ASSAULTRIFLE', min = 1, max = 1, chance = 20 },
            { name = 'ammo-9', min = 30, max = 120, chance = 80 },
            { name = 'ammo-rifle', min = 30, max = 90, chance = 50 },
            { name = 'armour', min = 1, max = 1, chance = 60 }
        }
    },
    validation = {
        groups = { ['police'] = 3, ['swat'] = 0 }
    }
})

-- Example 4: Civilian Storage Containers
exports.ox_inventory:RegisterInventoryType({
    name = 'storage_container',
    models = { 
        -1709866301, -- prop_container_01a
        -1709866302  -- prop_container_02a
    },
    interaction = {
        distance = 3.0,
        icon = 'fas fa-box',
        label = 'Search Container'
    },
    behavior = {
        useNetwork = true,
        freezeEntity = false
    },
    slots = 25,
    maxWeight = 150000,
    items = {
        maxItems = 5,
        items = {
            { name = 'water', min = 1, max = 3, chance = 60 },
            { name = 'bread', min = 1, max = 2, chance = 50 },
            { name = 'scrapmetal', min = 2, max = 8, chance = 70 },
            { name = 'plastic', min = 1, max = 5, chance = 40 },
            { name = 'money', min = 10, max = 500, chance = 15 }
        }
    }
})

-- Example 5: Refresh existing inventory types
CreateThread(function()
    Wait(60000 * 5) -- Wait 5 minutes
    
    -- Refresh all medical cabinets to regenerate items
    local refreshed = exports.ox_inventory:RefreshInventoryType('medical_cabinet')
    if refreshed then
        print('Medical cabinets refreshed successfully')
    end
end)

-- Example 6: Update item configuration at runtime
RegisterCommand('updatecabinet', function(source, args)
    if source ~= 0 then return end -- Console only
    
    local success = exports.ox_inventory:SetInventoryTypeItems('medical_cabinet', {
        maxItems = 8,
        items = {
            { name = 'bandage', min = 5, max = 10, chance = 100 },
            { name = 'medikit', min = 2, max = 4, chance = 80 },
            { name = 'adrenaline', min = 1, max = 2, chance = 50 }
        }
    })
    
    if success then
        print('Medical cabinet items updated')
        exports.ox_inventory:RefreshInventoryType('medical_cabinet')
    end
end)

-- Example 7: Get inventory type information
RegisterCommand('getinvtype', function(source, args)
    if source ~= 0 then return end -- Console only
    
    local typeName = args[1]
    if not typeName then
        print('Usage: getinvtype <type_name>')
        return
    end
    
    local config = exports.ox_inventory:GetInventoryType(typeName)
    if config then
        print(('Inventory type "%s" found with %d slots'):format(typeName, config.slots))
        print(('Models: %s'):format(table.concat(config.models, ', ')))
    else
        print(('Inventory type "%s" not found'):format(typeName))
    end
end)

-- Example 8: List all inventory types
RegisterCommand('listinvtypes', function(source, args)
    if source ~= 0 then return end -- Console only
    
    local allTypes = exports.ox_inventory:GetInventoryTypes()
    print('Registered inventory types:')
    
    for typeName, config in pairs(allTypes) do
        print(('- %s: %d slots, %d models'):format(typeName, config.slots, #config.models))
    end
end)

-- Example 9: Client-side interaction (if not using target system)
if not shared.target then
    CreateThread(function()
        while true do
            Wait(1000)
            
            local ped = cache.ped
            local coords = GetEntityCoords(ped)
            
            local objects = GetGamePool('CObject')
            for i = 1, #objects do
                local object = objects[i]
                local objCoords = GetEntityCoords(object)
                
                if #(coords - objCoords) <= 5.0 then
                    local model = GetEntityModel(object)
                    
                    -- Check if this model is registered for any inventory type
                    local allTypes = exports.ox_inventory:GetInventoryTypes()
                    for typeName, config in pairs(allTypes) do
                        for _, registeredModel in ipairs(config.models) do
                            if model == registeredModel then
                                -- Show interaction text or handle opening
                                if #(coords - objCoords) <= config.interaction.distance then
                                    -- Open inventory
                                    local netId = NetworkGetNetworkIdFromEntity(object)
                                    TriggerServerEvent('ox_inventory:validateInventoryObject', netId, model)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Example flow:
-- 1. Register inventory type (above examples)
-- 2. Player approaches registered object
-- 3. Client detects object and triggers server validation
-- 4. Server validates access and creates/opens inventory
-- 5. Player can interact with dynamically generated items 