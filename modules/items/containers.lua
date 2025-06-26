local containers = {}

---@class ItemContainerProperties
---@field slots number
---@field maxWeight number
---@field whitelist? table<string, true> | string[]
---@field blacklist? table<string, true> | string[]

local function arrayToSet(tbl)
	local size = #tbl
	local set = table.create(0, size)

	for i = 1, size do
		set[tbl[i]] = true
	end

	return set
end

---Registers items with itemName as containers (i.e. backpacks, wallets).
---@param itemName string
---@param properties ItemContainerProperties
---@todo Rework containers for flexibility, improved data structure; then export this method.
local function setContainerProperties(itemName, properties)
	local blacklist, whitelist = properties.blacklist, properties.whitelist

	if blacklist then
		local tableType = table.type(blacklist)

		if tableType == 'array' then
			blacklist = arrayToSet(blacklist)
		elseif tableType ~= 'hash' then
			TypeError('blacklist', 'table', type(blacklist))
		end
	end

	if whitelist then
		local tableType = table.type(whitelist)

		if tableType == 'array' then
			whitelist = arrayToSet(whitelist)
		elseif tableType ~= 'hash' then
			TypeError('whitelist', 'table', type(whitelist))
		end
	end

	containers[itemName] = {
		size = { properties.slots, properties.maxWeight },
		blacklist = blacklist,
		whitelist = whitelist,
	}

	GlobalState['ox_inv_container_' .. itemName] = containers[itemName]
	shared.info(('runtime container registered: %s'):format(itemName))
end

exports('setContainerProperties', setContainerProperties)

-- Validate if an item is permitted to be placed inside a container
---@param containerName string Name of the container item (e.g. "paperbag")
---@param itemName string Name of the item being placed into the container
---@return boolean allowed True if the item can be stored in the container
local function validateItemForContainer(containerName, itemName)
	local container = containers[containerName]
	if not container then
		-- If the container has no special rules, allow any item
		return true
	end

	-- Whitelist has priority over blacklist. If a whitelist exists, the item must be on it.
	local whitelist = container.whitelist
	if whitelist then
		return whitelist[itemName] == true
	end

	-- Otherwise, check blacklist (if present). Items on the blacklist are not allowed.
	local blacklist = container.blacklist
	if blacklist then
		return blacklist[itemName] ~= true
	end

	-- No whitelist or blacklist => no restrictions
	return true
end

exports('ValidateItemForContainer', validateItemForContainer)

setContainerProperties('paperbag', {
	slots = 5,
	maxWeight = 1000,
	blacklist = { 'testburger' }
})

setContainerProperties('pizzabox', {
	slots = 5,
	maxWeight = 1000,
	whitelist = { 'pizza' }
})

return containers
