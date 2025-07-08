if not lib then return end

local InventoryTypesClient = {}
local detectedObjects = {}
local objectScanInterval = 3000

function InventoryTypesClient.DetectInventoryObject(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    
    local model = GetEntityModel(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    
    if not netId or netId == 0 then return false end
    
    local coords = GetEntityCoords(entity)
    local objKey = ('%s-%s-%s-%s'):format(model, math.floor(coords.x), math.floor(coords.y), math.floor(coords.z))
    
    if detectedObjects[objKey] then
        return detectedObjects[objKey]
    end
    
    TriggerServerEvent('ox_inventory:validateInventoryObject', netId, model)
    detectedObjects[objKey] = { entity = entity, model = model, netId = netId, coords = coords }
    
    return detectedObjects[objKey]
end

function InventoryTypesClient.OpenInventoryObject(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    
    local model = GetEntityModel(entity)
    local netId = NetworkGetNetworkIdFromEntity(entity)
    
    if not netId or netId == 0 then return false end
    
    TriggerServerEvent('ox_inventory:validateInventoryObject', netId, model)
    return true
end

function InventoryTypesClient.IsNearInventoryObject(entity)
    if not entity or not DoesEntityExist(entity) then return false end
    
    local coords = GetEntityCoords(entity)
    local playerCoords = GetEntityCoords(cache.ped)
    
    return #(playerCoords - coords) <= 2.0
end

if shared.target then
    RegisterNetEvent('ox_inventory:addInventoryTarget', function(models, interaction)
        if not models or not interaction then return end
        
        exports.ox_target:addModel(models, {
            icon = interaction.icon or 'fas fa-box',
            label = interaction.label or 'Open Inventory',
            distance = interaction.distance or 2.0,
            onSelect = function(data)
                return InventoryTypesClient.OpenInventoryObject(data.entity)
            end
        })
    end)
end

SetInterval(function()
    if not shared.target then
        local objects = GetGamePool('CObject')
        
        for i = 1, #objects do
            local object = objects[i]
            
            if InventoryTypesClient.IsNearInventoryObject(object) then
                InventoryTypesClient.DetectInventoryObject(object)
            end
        end
    end
end, objectScanInterval)

return InventoryTypesClient 