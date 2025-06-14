---@class OxContainerManager
local ContainerManager = {}
local containers = {}

-- Lazy loading para evitar dependencia circular
local Items

local function getItems()
	if not Items then
		Items = require('modules.items.server')
		if not Items then
			lib.print.warn('Items module not yet available, will retry later')
		end
	end
	return Items
end

---@class ContainerProperties
---@field slots number Maximum number of slots
---@field maxWeight number Maximum weight in grams
---@field whitelist? table<string, true> | string[] Items allowed in container
---@field blacklist? table<string, true> | string[] Items prohibited in container
---@field consume? number Item consume on use (0-1)
---@field durability? boolean Whether container can degrade
---@field stack? boolean Whether container can stack (usually false)
---@field close? boolean Whether to close inventory after use
---@field groups? table<string, number> Required groups to use container

---@class ValidatedContainerProperties
---@field size table<number, number> [slots, maxWeight]
---@field whitelist? table<string, true>
---@field blacklist? table<string, true>
---@field consume number
---@field durability boolean
---@field stack boolean
---@field close boolean
---@field groups? table<string, number>

-- Security configuration
local SECURITY = {
	MAX_SLOTS = 100,   -- Maximum slots per container (user decides)
	MAX_WEIGHT = 100000, -- Maximum weight per container (100kg)
	MIN_SLOTS = 1,     -- Minimum slots per container
	MIN_WEIGHT = 100,  -- Minimum weight per container (100g)
	BLACKLISTED_ITEMS = { -- Items that can never be put in containers
		['money'] = true,
		['black_money'] = true,
	}
}

---Converts array to hash table for faster lookups
---@param tbl string[]
---@return table<string, true>
local function arrayToSet(tbl)
	if not tbl then return nil end

	local size = #tbl
	local set = table.create(0, size)

	for i = 1, size do
		if type(tbl[i]) == 'string' then
			set[tbl[i]] = true
		end
	end

	return next(set) and set or nil
end

---Validates container properties with security checks
---@param itemName string
---@param properties ContainerProperties
---@param invoker? string Resource that invoked the registration
---@return ValidatedContainerProperties?
local function validateContainerProperties(itemName, properties, invoker)
	if type(itemName) ~= 'string' or itemName == '' then
		lib.print.error('Container registration failed: Invalid item name')
		return nil
	end

	if type(properties) ~= 'table' then
		lib.print.error('Container registration failed: Properties must be a table')
		return nil
	end

	-- Validate slots
	local slots = properties.slots
	if type(slots) ~= 'number' or slots < SECURITY.MIN_SLOTS or slots > SECURITY.MAX_SLOTS then
		lib.print.error(('Container registration failed: Slots must be between %d and %d'):format(SECURITY.MIN_SLOTS,
			SECURITY.MAX_SLOTS))
		return nil
	end

	-- Validate weight
	local maxWeight = properties.maxWeight
	if type(maxWeight) ~= 'number' or maxWeight < SECURITY.MIN_WEIGHT or maxWeight > SECURITY.MAX_WEIGHT then
		lib.print.error(('Container registration failed: MaxWeight must be between %d and %d'):format(
			SECURITY.MIN_WEIGHT, SECURITY.MAX_WEIGHT))
		return nil
	end

	-- Validate and convert lists
	local blacklist = properties.blacklist
	local whitelist = properties.whitelist

	if blacklist then
		local tableType = table.type(blacklist)
		if tableType == 'array' then
			blacklist = arrayToSet(blacklist)
		elseif tableType ~= 'hash' then
			lib.print.error('Container registration failed: blacklist must be array or hash table')
			return nil
		end

		-- Add globally blacklisted items
		for item, _ in pairs(SECURITY.BLACKLISTED_ITEMS) do
			blacklist[item] = true
		end
	else
		blacklist = table.clone(SECURITY.BLACKLISTED_ITEMS)
	end

	if whitelist then
		local tableType = table.type(whitelist)
		if tableType == 'array' then
			whitelist = arrayToSet(whitelist)
		elseif tableType ~= 'hash' then
			lib.print.error('Container registration failed: whitelist must be array or hash table')
			return nil
		end

		-- Remove globally blacklisted items from whitelist
		for item, _ in pairs(SECURITY.BLACKLISTED_ITEMS) do
			whitelist[item] = nil
		end
	end

	-- Validate groups
	local groups = properties.groups
	if groups then
		if type(groups) ~= 'table' then
			lib.print.error('Container registration failed: groups must be a table')
			return nil
		end

		-- Validate group structure
		for group, grade in pairs(groups) do
			if type(group) ~= 'string' or type(grade) ~= 'number' then
				lib.print.error('Container registration failed: invalid group structure')
				return nil
			end
		end
	end

	-- Log registration for audit
	lib.print.info(('Container "%s" registered by resource "%s" with %d slots, %dg capacity'):format(
		itemName,
		invoker or 'unknown',
		slots,
		maxWeight
	))

	return {
		size = { slots, maxWeight },
		blacklist = blacklist,
		whitelist = whitelist,
		consume = math.max(0, math.min(1, properties.consume or 0)),
		durability = properties.durability == true,
		stack = properties.stack == true,
		close = properties.close ~= false,
		groups = groups
	}
end

---Registers a new container type with validation and security
---@param itemName string The item name to register as container
---@param properties ContainerProperties Container configuration
---@return boolean success
function ContainerManager.RegisterContainer(itemName, properties)
	local invoker = GetInvokingResource()

	if not invoker then
		lib.print.error('Container registration failed: No invoking resource')
		return false
	end

	local validated = validateContainerProperties(itemName, properties, invoker)
	if not validated then
		return false
	end

	-- Store with invoker info for cleanup
	containers[itemName] = validated
	containers[itemName]._invoker = invoker
	containers[itemName]._registered = os.time()

	-- Register the use callback for the container item if Items is available
	if getItems() then
		local item = getItems()(itemName)
		if item and not item.cb then
			item.cb = function(event, item, inventory, slot)
				if event == 'usingItem' then
					local slotData = inventory.items[slot]
					if not slotData or not slotData.metadata.container then return false end

					-- Check if player can use this container
					local canUse, reason = ContainerManager.CanPlayerUseContainer(inventory.id, item.name)
					if not canUse then
						TriggerClientEvent('ox_lib:notify', inventory.id, {
							type = 'error',
							description = reason or 'Cannot use container'
						})
						return false
					end

					-- Open the container inventory
					TriggerClientEvent('ox_inventory:openInventory', inventory.id, 'container', slot)
					return false -- Don't consume the item
				end
			end
			lib.print.info(('Container use callback registered for: %s'):format(itemName))
		end
	end

	return true
end

---Unregisters a container type (only by the resource that registered it)
---@param itemName string
---@return boolean success
function ContainerManager.UnregisterContainer(itemName)
	local invoker = GetInvokingResource()
	local container = containers[itemName]

	if not container then
		lib.print.warn(('Container "%s" is not registered'):format(itemName))
		return false
	end

	if container._invoker ~= invoker then
		lib.print.error(('Resource "%s" cannot unregister container "%s" (registered by "%s")'):format(
			invoker or 'unknown',
			itemName,
			container._invoker or 'unknown'
		))
		return false
	end

	containers[itemName] = nil
	lib.print.info(('Container "%s" unregistered by resource "%s"'):format(itemName, invoker))

	return true
end

---Gets container properties for an item
---@param itemName string
---@return ValidatedContainerProperties?
function ContainerManager.GetContainer(itemName)
	return containers[itemName]
end

---Gets all registered containers
---@return table<string, ValidatedContainerProperties>
function ContainerManager.GetAllContainers()
	local result = {}
	for name, props in pairs(containers) do
		result[name] = {
			size = props.size,
			blacklist = props.blacklist,
			whitelist = props.whitelist,
			consume = props.consume,
			durability = props.durability,
			stack = props.stack,
			close = props.close,
			groups = props.groups
		}
	end
	return result
end

---Validates if a player can use a specific container
---@param playerId number
---@param itemName string
---@return boolean canUse
---@return string? reason
function ContainerManager.CanPlayerUseContainer(playerId, itemName)
	local container = containers[itemName]
	if not container then
		return false, 'Container not registered'
	end

	-- Check group requirement
	if container.groups then
		local hasGroup = lib.callback.await('ox_inventory:hasGroupAccess', playerId, container.groups)
		if not hasGroup then
			return false, 'Insufficient group permissions'
		end
	end

	return true
end

---Validates if an item can be stored in a container
---@param containerItem string Container item name
---@param targetItem string Item to store
---@return boolean allowed
function ContainerManager.ValidateItemForContainer(containerItem, targetItem)
	local container = containers[containerItem]
	if not container then return false end

	local ItemsModule = getItems()
	if not ItemsModule then return false end

	local itemData = ItemsModule(targetItem)
	if not itemData then
		lib.print.warn(('Attempted to store non-existent item "%s" in container "%s"'):format(targetItem, containerItem))
		return false
	end

	if container.whitelist then
		return container.whitelist[targetItem] == true
	end

	if container.blacklist then
		return container.blacklist[targetItem] ~= true
	end

	return true
end

-- Clean up containers when resource stops
AddEventHandler('onResourceStop', function(resourceName)
	for itemName, container in pairs(containers) do
		if container._invoker == resourceName then
			containers[itemName] = nil
			lib.print.info(('Container "%s" auto-unregistered (resource "%s" stopped)'):format(itemName, resourceName))
		end
	end
end)

-- Export functions
exports('RegisterContainer', ContainerManager.RegisterContainer)
exports('UnregisterContainer', ContainerManager.UnregisterContainer)
exports('GetContainer', ContainerManager.GetContainer)
exports('GetAllContainers', ContainerManager.GetAllContainers)
exports('CanPlayerUseContainer', ContainerManager.CanPlayerUseContainer)
exports('ValidateItemForContainer', ContainerManager.ValidateItemForContainer)

-- Internal function to register default containers (bypasses invoker check)
local function registerDefaultContainers()
	local defaultContainers = {
		paperbag = {
			slots = 5,
			maxWeight = 1000,
			blacklist = { 'testburger' },
			consume = 0,
			stack = false,
			close = false
		},
		pizzabox = {
			slots = 5,
			maxWeight = 1000,
			whitelist = { 'pizza' },
			consume = 0,
			stack = false,
			close = false
		}
	}

	for itemName, properties in pairs(defaultContainers) do
		local validated = validateContainerProperties(itemName, properties, 'ox_inventory')
		if validated then
			containers[itemName] = validated
			containers[itemName]._invoker = 'ox_inventory'
			containers[itemName]._registered = os.time()
			lib.print.info(('Default container registered: %s'):format(itemName))
		end
	end
end

-- Initialize Items reference and register callbacks for existing containers
CreateThread(function()
	-- Register default containers first
	registerDefaultContainers()

	-- Wait for Items module to be available
	while not getItems() do
		Wait(100)
	end

	-- Register callbacks for already registered containers
	for itemName, _ in pairs(containers) do
		local item = getItems()(itemName)
		if item and not item.cb then
			item.cb = function(event, item, inventory, slot)
				if event == 'usingItem' then
					local slotData = inventory.items[slot]
					if not slotData or not slotData.metadata.container then return false end

					-- Check if player can use this container
					local canUse, reason = ContainerManager.CanPlayerUseContainer(inventory.id, item.name)
					if not canUse then
						TriggerClientEvent('ox_lib:notify', inventory.id, {
							type = 'error',
							description = reason or 'Cannot use container'
						})
						return false
					end

					-- Open the container inventory
					TriggerClientEvent('ox_inventory:openInventory', inventory.id, 'container', slot)
					return false -- Don't consume the item
				end
			end
			lib.print.info(('Container use callback registered for: %s'):format(itemName))
		end
	end
end)

-- Backward compatibility
setmetatable(containers, {
	__index = function(_, itemName)
		return ContainerManager.GetContainer(itemName)
	end
})

return containers
