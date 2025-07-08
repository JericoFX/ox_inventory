if not lib then return end

local InventoryTypes = {}
local RegisteredTypes = {}

local function getInventory()
	if not Inventory then
		Inventory = require 'modules.inventory.server'
	end
	return Inventory
end



---@class InventoryTypeConfig
---@field name string
---@field models number[]
---@field interaction table
---@field behavior table
---@field items table
---@field validation? table

---@class InventoryTypeItem
---@field name string
---@field min number
---@field max number
---@field chance number

local function validateItemConfig(items)
    if not items or type(items) ~= 'table' then
        return false, 'Items configuration must be a table'
    end
    
    if not items.maxItems or type(items.maxItems) ~= 'number' or items.maxItems <= 0 then
        return false, 'maxItems must be a positive number'
    end
    
    if not items.items or type(items.items) ~= 'table' then
        return false, 'items array must be a table'
    end
    
    for i, item in ipairs(items.items) do
        if not item.name or type(item.name) ~= 'string' then
            return false, ('Item %d: name must be a string'):format(i)
        end
        
        if not item.min or type(item.min) ~= 'number' or item.min < 0 then
            return false, ('Item %d: min must be a non-negative number'):format(i)
        end
        
        if not item.max or type(item.max) ~= 'number' or item.max < item.min then
            return false, ('Item %d: max must be a number >= min'):format(i)
        end
        
        if not item.chance or type(item.chance) ~= 'number' or item.chance < 0 or item.chance > 100 then
            return false, ('Item %d: chance must be a number between 0-100'):format(i)
        end
    end
    
    return true
end

local function validateTypeConfig(config)
    if not config or type(config) ~= 'table' then
        return false, 'Configuration must be a table'
    end
    
    if not config.name or type(config.name) ~= 'string' then
        return false, 'name must be a string'
    end
    
    if not config.models or type(config.models) ~= 'table' or #config.models == 0 then
        return false, 'models must be a non-empty array'
    end
    
    for i, model in ipairs(config.models) do
        if type(model) ~= 'number' then
            return false, ('Model %d must be a number'):format(i)
        end
    end
    
    if config.items then
        local valid, error = validateItemConfig(config.items)
        if not valid then
            return false, error
        end
    end
    
    return true
end

function InventoryTypes.Register(config)
    local valid, error = validateTypeConfig(config)
    if not valid then
        return false, error
    end
    
    if RegisteredTypes[config.name] then
        return false, ('Inventory type "%s" already exists'):format(config.name)
    end
    
    local typeData = {
        name = config.name,
        models = lib.array:new(table.unpack(config.models)),
        interaction = config.interaction or {},
        behavior = config.behavior or {},
        items = config.items,
        validation = config.validation or {},
        cache = {}
    }
    
    if typeData.behavior.useNetwork and typeData.items and typeData.items.maxItems then
        local maxItems = typeData.items.maxItems
        if maxItems > 10 then
            lib.print.warn(('Inventory type "%s" uses network synchronization with %d max items. High item counts may cause network synchronization issues. Consider reducing maxItems or setting useNetwork to false.'):format(config.name, maxItems))
        end
    end
    
    RegisteredTypes[config.name] = typeData
    
    return true
end

function InventoryTypes.Unregister(typeName)
    if not RegisteredTypes[typeName] then
        return false, ('Inventory type "%s" does not exist'):format(typeName)
    end
    
    RegisteredTypes[typeName] = nil
    return true
end

function InventoryTypes.GetType(typeName)
    return RegisteredTypes[typeName]
end

function InventoryTypes.GetTypes()
    return RegisteredTypes
end

function InventoryTypes.GetTypeByModel(model)
    for _, typeData in pairs(RegisteredTypes) do
        if typeData.models:includes(model) then
            return typeData
        end
    end
    return nil
end

function InventoryTypes.IsValidModel(model)
    return InventoryTypes.GetTypeByModel(model) ~= nil
end

function InventoryTypes.GenerateItems(typeName, inventoryId)
    local typeData = RegisteredTypes[typeName]
    if not typeData or not typeData.items then
        return {}
    end
    
    local itemsConfig = typeData.items
    local generatedItems = {}
    local itemCount = 0
    
    for _, itemConfig in ipairs(itemsConfig.items) do
        if math.random(100) <= itemConfig.chance and itemCount < itemsConfig.maxItems then
            local count = math.random(itemConfig.min, itemConfig.max)
            if count > 0 then
                table.insert(generatedItems, {
                    item = itemConfig.name,
                    count = count
                })
                itemCount = itemCount + 1
            end
        end
    end
    
    return generatedItems
end

function InventoryTypes.RefreshItems(typeName, inventoryId)
    local typeData = RegisteredTypes[typeName]
    if not typeData then
        return false, ('Inventory type "%s" does not exist'):format(typeName)
    end
    
    if typeData.cache[inventoryId] then
        typeData.cache[inventoryId] = nil
    end
    
    local newItems = InventoryTypes.GenerateItems(typeName, inventoryId)
    typeData.cache[inventoryId] = newItems
    
    return true, newItems
end

function InventoryTypes.GetCachedItems(typeName, inventoryId)
    local typeData = RegisteredTypes[typeName]
    if not typeData then
        return nil
    end
    
    return typeData.cache[inventoryId]
end

function InventoryTypes.ValidateAccess(typeName, playerId, entity)
    local typeData = RegisteredTypes[typeName]
    if not typeData then
        return false, 'Invalid inventory type'
    end
    
    if not entity or not DoesEntityExist(entity) then
        return false, 'Entity does not exist'
    end
    
    local model = GetEntityModel(entity)
    if not typeData.models:includes(model) then
        return false, 'Invalid model for this inventory type'
    end
    
    	if typeData.validation.groups then
		local inventory = getInventory()(playerId)
		if not inventory or not server.hasGroup(inventory, typeData.validation.groups) then
			return false, 'Insufficient permissions'
		end
	end
    
    return true
end

return InventoryTypes 