if not lib then return end

local CraftingBenches = {}
local Items = require 'modules.items.server'
local Inventory = require 'modules.inventory.server'
local UnlockItem = 'crafting_unlocks'

---@param benchId number|string
---@param recipe table
---@return string
local function getRecipeId(benchId, recipe)
	local unlock = recipe.unlock
	if type(unlock) == 'table' then unlock = unlock.id end
	return recipe.id or unlock or ('%s:%s'):format(benchId, recipe.name)
end

---@param inv OxInventory
---@return table, SlotWithItem|nil
local function getCraftingUnlocks(inv)
	local slot = Inventory.GetSlotWithItem(inv, UnlockItem)
	local unlocks = slot?.metadata?.crafting

	if type(unlocks) ~= 'table' then
		unlocks = {}
	end

	return unlocks, slot
end

---@param licenses string|string[]|nil
---@param inv OxInventory
---@return boolean
local function hasRequiredLicenses(inv, licenses)
	if not licenses then return true end
	if not server.hasLicense then return false end

	if type(licenses) == 'string' then
		return server.hasLicense(inv, licenses)
	end

	for i = 1, #licenses do
		if not server.hasLicense(inv, licenses[i]) then
			return false
		end
	end

	return true
end

---@param bench table
---@param stations string|string[]|nil
---@return boolean
local function matchesCraftingStation(bench, stations)
	if not stations then return true end
	local benchStation = bench.station or bench.name or bench.id

	if type(stations) == 'string' then
		return stations == benchStation
	end

	for i = 1, #stations do
		if stations[i] == benchStation then
			return true
		end
	end

	return false
end

---@param recipe table
---@return string|nil, any, any, any, boolean
local function getRecipeRequirements(recipe)
	local unlock = recipe.unlock
	local requirements = type(unlock) == 'table' and unlock or nil

	return type(unlock) == 'string' and unlock or requirements?.id,
		requirements?.groups or recipe.groups,
		requirements?.licenses or recipe.licenses,
		requirements?.stations or recipe.stations,
		requirements?.default == true
end

---@param inv OxInventory
---@param bench table
---@param recipe table
---@param unlocks table
---@return boolean
local function canUseRecipe(inv, bench, recipe, unlocks)
	local unlockId, groups, licenses, stations, defaultUnlock = getRecipeRequirements(recipe)

	if groups and not server.hasGroup(inv, groups) then return false end
	if not hasRequiredLicenses(inv, licenses) then return false end
	if not matchesCraftingStation(bench, stations) then return false end

	if unlockId and not defaultUnlock and not unlocks[unlockId] then
		return false
	end

	return true
end

---@param id number
---@param data table
local function createCraftingBench(id, data)
	CraftingBenches[id] = {}
	local recipes = data.items

	if recipes then
		data.station = data.station or data.name or id

		for i = 1, #recipes do
			local recipe = recipes[i]
			recipe.id = getRecipeId(id, recipe)
			local item = Items(recipe.name)

			if item then
				recipe.weight = item.weight
				recipe.slot = i
			else
				warn(('failed to setup crafting recipe (bench: %s, slot: %s) - item "%s" does not exist'):format(id, i, recipe.name))
			end

			for ingredient, needs in pairs(recipe.ingredients) do
				if needs < 1 then
					item = Items(ingredient)

					if item and not item.durability then
						item.durability = true
					end
				end
			end
		end

		if shared.target then
			data.points = nil
		else
			data.zones = nil
		end

		CraftingBenches[id] = data
	end
end

for id, data in pairs(lib.load('data.crafting') or {}) do createCraftingBench(data.name or id, data) end

---falls back to player coords if zones and points are both nil
---@param source number
---@param bench table
---@param index number
---@return vector3
local function getCraftingCoords(source, bench, index)
	if not bench.zones and not bench.points then
		return GetEntityCoords(GetPlayerPed(source))
	else
		return shared.target and bench.zones[index].coords or bench.points[index]
	end
end

lib.callback.register('ox_inventory:openCraftingBench', function(source, id, index)
	local left, bench = Inventory(source), CraftingBenches[id]

	if not left then return end

	if bench then
		local groups = bench.groups
		local coords = getCraftingCoords(source, bench, index)

		if not coords then return end

		if groups and not server.hasGroup(left, groups) then return end
		if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then return end

		if left.open and left.open ~= source then
			local inv = Inventory(left.open) --[[@as OxInventory]]

			-- Why would the player inventory open with an invalid target? Can't repro but whatever.
			if inv?.player then
				inv:closeInventory()
			end
		end

		left:openInventory(left)

		local unlocks = getCraftingUnlocks(left)
		local availability = {}

		for i = 1, #bench.items do
			local recipe = bench.items[i]
			availability[recipe.id] = canUseRecipe(left, bench, recipe, unlocks)
		end

		left.craftingAvailability = availability
	end

	return { label = left.label, type = left.type, slots = left.slots, weight = left.weight, maxWeight = left.maxWeight, craftingAvailability = left.craftingAvailability }
end)

local TriggerEventHooks = require 'modules.hooks.server'

lib.callback.register('ox_inventory:craftItem', function(source, id, index, recipeId, toSlot)
	local left, bench = Inventory(source), CraftingBenches[id]

	if not left then return end

	if bench then
		local groups = bench.groups
		local coords = getCraftingCoords(source, bench, index)

		if groups and not server.hasGroup(left, groups) then return end
		if #(GetEntityCoords(GetPlayerPed(source)) - coords) > 10 then return end

		local recipe = bench.items[recipeId]

		if recipe then
			local unlocks = getCraftingUnlocks(left)

			if not canUseRecipe(left, bench, recipe, unlocks) then
				return false, 'cannot_perform'
			end

			local tbl, num = {}, 0

			for name in pairs(recipe.ingredients) do
				num += 1
				tbl[num] = name
			end

			local craftedItem = Items(recipe.name)
			local craftCount = (type(recipe.count) == 'number' and recipe.count) or (table.type(recipe.count) == 'array' and math.random(recipe.count[1], recipe.count[2])) or 1

			-- Modified weight calculation
			local newWeight = left.weight
			local items = Inventory.Search(left, 'slots', tbl) or {}
			---@todo new iterator or something to accept a map
			-- First subtract weight of ingredients that will be removed
			for name, needs in pairs(recipe.ingredients) do
				if needs > 0 then
					local item = Items(name)
					if item then
						newWeight -= (item.weight * needs)
					end
				end
			end

			-- Add weight of crafted item
			newWeight += (craftedItem.weight + (recipe.metadata?.weight or 0)) * craftCount

			if newWeight > left.maxWeight then return false, 'cannot_carry' end

			local items = Inventory.Search(left, 'slots', tbl) or {}
			table.wipe(tbl)

			for name, needs in pairs(recipe.ingredients) do
				if needs == 0 then break end

				local slots = items[name] or items

                if #slots == 0 then return end

				for i = 1, #slots do
					local slot = slots[i]

					if needs == 0 then
						if not slot.metadata.durability or slot.metadata.durability > 0 then
							break
						end
					elseif needs < 1 then
						local item = Items(name)
						local durability = slot.metadata.durability

						if durability and durability >= needs * 100 then
							if durability > 100 then
								local degrade = (slot.metadata.degrade or item.degrade) * 60
								local percentage = ((durability - os.time()) * 100) / degrade

								if percentage >= needs * 100 then
									tbl[slot.slot] = needs
									break
								end
							else
								tbl[slot.slot] = needs
								break
							end
						end
					elseif needs <= slot.count then
						tbl[slot.slot] = needs
						break
					else
						tbl[slot.slot] = slot.count
						needs -= slot.count
					end

					if needs == 0 then break end
					-- Player does not have enough items (ui should prevent crafting if lacking items, so this shouldn't trigger)
					if needs > 0 and i == #slots then return end
				end
			end

			if not TriggerEventHooks('craftItem', {
				source = source,
				benchId = id,
				benchIndex = index,
				recipe = recipe,
				toInventory = left.id,
				toSlot = toSlot,
			}) then return false end

			local duration = recipe.duration or 3000
			local startTime = GetGameTimer()
			local success = lib.callback.await('ox_inventory:startCrafting', source, id, recipeId)

			if success then
				local elapsed = GetGameTimer() - startTime
				if elapsed < duration then
					Wait(duration - elapsed)
				end

				for name, needs in pairs(recipe.ingredients) do
					if Inventory.GetItemCount(left, name) < needs then return end
				end

				for slot, count in pairs(tbl) do
					local invSlot = left.items[slot]

					if not invSlot then return end

					if count < 1 then
						local item = Items(invSlot.name)
						local durability = invSlot.metadata.durability or 100

						if durability > 100 then
							local degrade = (invSlot.metadata.degrade or item.degrade) * 60
							durability -= degrade * count
						else
							durability -= count * 100
						end

						if invSlot.count > 1 then
							local emptySlot = Inventory.GetEmptySlot(left)

							if emptySlot then
								local newItem = Inventory.SetSlot(left, item, 1, table.deepclone(invSlot.metadata), emptySlot)

								if newItem then
                                    Items.UpdateDurability(left, newItem, item, durability < 0 and 0 or durability)
								end
							end

							invSlot.count -= 1
                            invSlot.weight = Inventory.SlotWeight(item, invSlot)

							left:syncSlotsWithClients({
								{
									item = invSlot,
									inventory = left.id
								}
							}, true)
						else
                            Items.UpdateDurability(left, invSlot, item, durability < 0 and 0 or durability)
						end
					else
						local removed = invSlot and Inventory.RemoveItem(left, invSlot.name, count, nil, slot)
						-- Failed to remove item (inventory state unexpectedly changed?)
						if not removed then return end
					end
				end

				Inventory.AddItem(left, craftedItem, craftCount, recipe.metadata or {}, craftedItem.stack and toSlot or nil)
			end

			return success
		end
	end
end)

---@param inv OxInventory
---@param updates table
---@return boolean
local function updateCraftingUnlocks(inv, updates)
	local unlocks, slot = getCraftingUnlocks(inv)

	for id, state in pairs(updates) do
		if state then
			unlocks[id] = true
		else
			unlocks[id] = nil
		end
	end

	local metadata = slot and table.clone(slot.metadata or {}) or {}
	metadata.crafting = unlocks

	if slot then
		Inventory.SetMetadata(inv, slot.slot, metadata)
		return true
	end

	local added = Inventory.AddItem(inv, UnlockItem, 1, metadata)
	return added and true or false
end

---@param inv OxInventory
---@param recipeIds string|string[]
---@return boolean
local function addRecipeUnlocks(inv, recipeIds)
	local updates = {}

	if type(recipeIds) == 'table' then
		for i = 1, #recipeIds do
			updates[recipeIds[i]] = true
		end
	else
		updates[recipeIds] = true
	end

	return updateCraftingUnlocks(inv, updates)
end

---@param inv OxInventory
---@param recipeIds string|string[]|nil
---@return boolean
local function removeRecipeUnlocks(inv, recipeIds)
	if not recipeIds then
		local metadata = {}
		local slot = Inventory.GetSlotWithItem(inv, UnlockItem)

		if slot then
			metadata = table.clone(slot.metadata or {})
			metadata.crafting = {}
			Inventory.SetMetadata(inv, slot.slot, metadata)
		end

		return true
	end

	local updates = {}

	if type(recipeIds) == 'table' then
		for i = 1, #recipeIds do
			updates[recipeIds[i]] = false
		end
	else
		updates[recipeIds] = false
	end

	return updateCraftingUnlocks(inv, updates)
end

---@param playerId number
---@param recipeIds string|string[]
---@return boolean
exports('UnlockRecipes', function(playerId, recipeIds)
	local inv = Inventory(playerId)
	if not inv then return false end

	return addRecipeUnlocks(inv, recipeIds)
end)

---@param playerId number
---@param recipeIds string|string[]|nil
---@return boolean
exports('ResetRecipeUnlocks', function(playerId, recipeIds)
	local inv = Inventory(playerId)
	if not inv then return false end

	return removeRecipeUnlocks(inv, recipeIds)
end)
