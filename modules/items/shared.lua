local function useExport(resource, export)
	return function(...)
		return exports[resource][export](nil, ...)
	end
end

local ItemList = {}
local isServer = IsDuplicityVersion()

local function setImagePath(path)
	if path then
		return path:match('^[%w]+://') and path or ('%s/%s'):format(client.imagepath, path)
	end
end

---@param data OxItem
local function newItem(data)
	data.weight = data.weight or 0

	if data.close == nil then
		data.close = true
	end

	if data.stack == nil then
		data.stack = true
	end

	local clientData, serverData = data.client, data.server
	---@cast clientData -nil
	---@cast serverData -nil

	if not data.consume and (clientData and (clientData.status or clientData.usetime or clientData.export) or serverData?.export) then
		data.consume = 1
	end

	if isServer then
		---@cast data OxServerItem
		serverData = data.server
		data.client = nil

		if not data.durability then
			if data.degrade or (data.consume and data.consume ~= 0 and data.consume < 1) then
				data.durability = true
			end
		end

		if not serverData then goto continue end

		if serverData.export then
			data.cb = useExport(string.strsplit('.', serverData.export))
		end
	else
		---@cast data OxClientItem
		clientData = data.client
		data.server = nil
		data.count = 0

		if not clientData then goto continue end

		if clientData.export then
			data.export = useExport(string.strsplit('.', clientData.export))
		end

		clientData.image = setImagePath(clientData.image)

		if clientData.propTwo then
			clientData.prop = clientData.prop and { clientData.prop, clientData.propTwo } or clientData.propTwo
			clientData.propTwo = nil
		end
	end

	::continue::
	ItemList[data.name] = data
end

for type, data in pairs(lib.load('data.weapons') or {}) do
	for k, v in pairs(data) do
		v.name = k
		v.close = type == 'Ammo' and true or false
		v.weight = v.weight or 0

		if type == 'Weapons' then
			---@cast v OxWeapon
			v.model = v.model or k -- actually weapon type or such? model for compatibility
			v.hash = joaat(v.model)
			v.stack = v.throwable and true or false
			v.durability = v.durability or 0.05
			v.weapon = true
		else
			v.stack = true
		end

		v[type == 'Ammo' and 'ammo' or type == 'Components' and 'component' or type == 'Tints' and 'tint' or 'weapon'] = true

		if isServer then
			v.client = nil
		else
			v.count = 0
			v.server = nil
			local clientData = v.client

			if clientData?.image then
				clientData.image = setImagePath(clientData.image)
			end
		end

		ItemList[k] = v
	end
end

for k, v in pairs(lib.load('data.items') or {}) do
	v.name = k
	local success, response = pcall(newItem, v)

	if not success then
		warn(('An error occurred while creating item "%s" callback!\n^1SCRIPT ERROR: %s^0'):format(k, response))
	end
end

ItemList.cash = ItemList.money

------------------------------------------------------------------------------------
------------------------------------------------------------------------------------

if not isServer then
	local Containers      = {}

	local itemPrefix      = 'ox_inv_item_'
	local containerPrefix = 'ox_inv_container_'

	for k, v in pairs(GlobalState) do
		if type(k) == 'string' then
			if k:sub(1, #itemPrefix) == itemPrefix then
				pcall(newItem, v)
			elseif k:sub(1, #containerPrefix) == containerPrefix then
				Containers[k:sub(#containerPrefix + 1)] = v
			end
		end
	end

	AddStateBagChangeHandler(itemPrefix .. '*', nil, function(_, key, value, _, replicated)
		if replicated and value then
			pcall(newItem, value)
		end
	end)

	AddStateBagChangeHandler(containerPrefix .. '*', nil, function(_, key, value, _, replicated)
		if replicated and value then
			Containers[key:sub(#containerPrefix + 1)] = value
		end
	end)

	exports('Containers', function() return Containers end)
end

if isServer then
	local function stripFunctions(data)
		if type(data) ~= 'table' then return data end
		local copy = {}

		for k, v in pairs(data) do
			local vt = type(v)
			if vt == 'table' then
				copy[k] = stripFunctions(v)
			elseif vt ~= 'function' and vt ~= 'userdata' and vt ~= 'thread' then
				copy[k] = v
			end
		end

		return copy
	end

	local function registerRuntimeItem(item)
		assert(type(item) == 'table' and item.name, 'registerRuntimeItem expects item table with name')

		newItem(item)

		GlobalState['ox_inv_item_' .. item.name] = stripFunctions(item)
	end

	exports('registerRuntimeItem', registerRuntimeItem)
end

return ItemList
