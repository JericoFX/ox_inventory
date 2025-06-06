local InventoryPresets = {}

local playerUsage = {} -- Track usage per player

local function getItems()
    if not Items then
        Items = require 'modules.items.server'
    end
    return Items
end

local function getInventory()
    if not Inventory then
        Inventory = require 'modules.inventory.server'
    end
    return Inventory
end

local function getPlayerUsage(playerId)
    if not playerUsage[playerId] then
        playerUsage[playerId] = {}
    end
    return playerUsage[playerId]
end

local function hasUsedPreset(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    return usage[presetName] and usage[presetName] > 0
end

local function markPresetUsed(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    usage[presetName] = (usage[presetName] or 0) + 1
end

local function resetPresetUsage(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    usage[presetName] = 0
end

function InventoryPresets.ValidatePreset(playerId, presetName, bypassUsageCheck)
    if not server.enablePresetsSystem then return false, "Presets disabled" end

    local preset = server.presets[presetName]
    if not preset then return false, "Preset not found" end

    local inv = getInventory()(playerId)
    if not inv then return false, "Inventory not found" end

    -- Check usage limit
    if not bypassUsageCheck and preset.max_uses and hasUsedPreset(playerId, presetName) then
        local usage = getPlayerUsage(playerId)
        if usage[presetName] >= preset.max_uses then
            return false, "Already used maximum times"
        end
    end

    -- Check if new player only
    if preset.new_player_only then
        local player = server.getPlayer(playerId)
        if not player or (player.playtime and player.playtime > 3600) then -- 1 hour playtime
            return false, "Only for new players"
        end
    end

    if preset.jobs then
        local player = server.getPlayer(playerId)
        if not player or not server.hasGroup(player, preset.jobs) then
            return false, "Job required"
        end
    end

    if preset.weight_check then
        local totalWeight = 0
        local ItemsModule = getItems()

        for _, itemData in pairs(preset.items) do
            local item = ItemsModule(itemData.item)
            if item then
                totalWeight = totalWeight + (item.weight * itemData.count)
            end
        end

        if inv.weight + totalWeight > inv.maxWeight then
            return false, "Not enough weight capacity"
        end
    end

    local slotsNeeded = 0
    for _, itemData in pairs(preset.items) do
        local item = getItems()(itemData.item)
        if item and not item.stack then
            slotsNeeded = slotsNeeded + itemData.count
        else
            slotsNeeded = slotsNeeded + 1
        end
    end

    local freeSlots = 0
    for i = 1, inv.slots do
        if not inv.items[i] then
            freeSlots = freeSlots + 1
        end
    end

    if freeSlots < slotsNeeded then
        return false, "Not enough free slots"
    end

    return true
end

function InventoryPresets.ApplyPreset(playerId, presetName, bypassUsageCheck)
    local valid, reason = InventoryPresets.ValidatePreset(playerId, presetName, bypassUsageCheck)
    if not valid then return false, reason end

    local preset = server.presets[presetName]
    local inv = getInventory()(playerId)
    local success_count = 0

    for _, itemData in pairs(preset.items) do
        local success = getInventory().AddItem(inv, itemData.item, itemData.count, itemData.metadata)
        if success then
            success_count = success_count + 1
        end
    end

    if success_count > 0 then
        -- Mark as used
        if not bypassUsageCheck then
            markPresetUsed(playerId, presetName)
        end

        lib.logger(playerId, 'preset_applied', ('Applied preset: %s (uses: %d/%d)'):format(
            presetName,
            getPlayerUsage(playerId)[presetName] or 0,
            preset.max_uses or 999
        ))

        local usageText = preset.max_uses and
            string.format(' (%d/%d uses)', getPlayerUsage(playerId)[presetName] or 0, preset.max_uses) or ''

        return true, ('Applied %d items%s'):format(success_count, usageText)
    end

    return false, "Failed to apply items"
end

-- Alternative activation methods
function InventoryPresets.CheckLocationActivation(playerId, presetName)
    local preset = server.presets[presetName]
    if not preset.activator_coords then return true end

    local playerCoords = GetEntityCoords(GetPlayerPed(playerId))
    local distance = #(playerCoords - preset.activator_coords)

    return distance <= (preset.activator_distance or 5.0)
end

function InventoryPresets.UseActivatorItem(playerId, presetName)
    local preset = server.presets[presetName]
    if not preset.activator_item then return false, "No activator item" end

    local inv = getInventory()(playerId)
    local hasItem = getInventory().GetItem(inv, preset.activator_item, nil, true)

    if hasItem < 1 then
        return false, "Missing activator item: " .. preset.activator_item
    end

    if not InventoryPresets.CheckLocationActivation(playerId, presetName) then
        return false, "Must be near activation location"
    end

    -- Consume the activator item
    getInventory().RemoveItem(inv, preset.activator_item, 1)

    return InventoryPresets.ApplyPreset(playerId, presetName)
end

-- Event handlers for job changes and death
AddEventHandler('ox_inventory:playerJobChanged', function(playerId, oldJob, newJob)
    for presetName, preset in pairs(server.presets) do
        if preset.reset_on_job_change then
            resetPresetUsage(playerId, presetName)
        end
    end
end)

AddEventHandler('ox_inventory:playerDied', function(playerId)
    for presetName, preset in pairs(server.presets) do
        if preset.reset_on_death then
            resetPresetUsage(playerId, presetName)
        end
    end
end)

AddEventHandler('playerDropped', function()
    playerUsage[source] = nil
end)

-- Get available presets for player
function InventoryPresets.GetAvailablePresets(playerId)
    if not server.enablePresetsSystem then return {} end

    local available = {}
    local player = server.getPlayer(playerId)

    for presetName, preset in pairs(server.presets) do
        local canUse = true
        local reason = ""
        local usageInfo = ""

        -- Check job requirement
        if preset.jobs and not server.hasGroup(player, preset.jobs) then
            canUse = false
            reason = "Job required: " .. table.concat(preset.jobs, ", ")
        end

        -- Check usage limit
        if preset.max_uses and hasUsedPreset(playerId, presetName) then
            local usage = getPlayerUsage(playerId)
            if usage[presetName] >= preset.max_uses then
                canUse = false
                reason = "Maximum uses reached"
            else
                usageInfo = string.format("(%d/%d uses)", usage[presetName], preset.max_uses)
            end
        elseif preset.max_uses then
            usageInfo = string.format("(0/%d uses)", preset.max_uses)
        end

        -- Check new player only
        if preset.new_player_only and player.playtime and player.playtime > 3600 then
            canUse = false
            reason = "Only for new players"
        end

        available[#available + 1] = {
            name = presetName,
            label = preset.label,
            canUse = canUse,
            reason = reason,
            usageInfo = usageInfo,
            activatorItem = preset.activator_item,
            needsLocation = preset.activator_coords ~= nil
        }
    end

    return available
end

-- Commands with ox_lib
RegisterCommand('preset', function(source, args)
    if not server.enablePresetsSystem then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Presets system is disabled'
        })
        return
    end

    local presetName = args[1]
    if not presetName then
        -- Show preset selection menu
        local available = InventoryPresets.GetAvailablePresets(source)
        local options = {}

        for _, preset in ipairs(available) do
            if preset.canUse then
                options[#options + 1] = {
                    title = preset.label,
                    description = preset.usageInfo,
                    args = { preset.name }
                }
            else
                options[#options + 1] = {
                    title = preset.label .. " ❌",
                    description = preset.reason,
                    disabled = true
                }
            end
        end

        if #options == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'inform',
                description = 'No presets available'
            })
            return
        end

        TriggerClientEvent('ox_lib:registerContext', source, {
            id = 'preset_menu',
            title = 'Available Presets',
            options = options,
            onSelect = function(selected)
                TriggerServerEvent('ox_inventory:selectPreset', selected.args[1])
            end
        })

        TriggerClientEvent('ox_lib:showContext', source, 'preset_menu')
        return
    end

    local success, message = InventoryPresets.ApplyPreset(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

RegisterCommand('usepreset', function(source, args)
    if not server.enablePresetsSystem then return end

    local presetName = args[1]
    if not presetName then
        -- Show activator item menu
        local available = InventoryPresets.GetAvailablePresets(source)
        local options = {}

        for _, preset in ipairs(available) do
            if preset.activatorItem and preset.canUse then
                options[#options + 1] = {
                    title = preset.label,
                    description = "Requires: " .. preset.activatorItem ..
                        (preset.needsLocation and " + Location" or ""),
                    args = { preset.name }
                }
            end
        end

        if #options == 0 then
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'inform',
                description = 'No activator presets available'
            })
            return
        end

        TriggerClientEvent('ox_lib:registerContext', source, {
            id = 'usepreset_menu',
            title = 'Use Activator Item',
            options = options,
            onSelect = function(selected)
                TriggerServerEvent('ox_inventory:usePresetItem', selected.args[1])
            end
        })

        TriggerClientEvent('ox_lib:showContext', source, 'usepreset_menu')
        return
    end

    local success, message = InventoryPresets.UseActivatorItem(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

-- Server events for menu selections
RegisterNetEvent('ox_inventory:selectPreset', function(presetName)
    local success, message = InventoryPresets.ApplyPreset(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

RegisterNetEvent('ox_inventory:usePresetItem', function(presetName)
    local success, message = InventoryPresets.UseActivatorItem(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

-- Admin command to reset usage
RegisterCommand('resetpresetusage', function(source, args)
    if not IsPlayerAceAllowed(source, 'ox_inventory.admin') then return end

    local targetId = tonumber(args[1])
    local presetName = args[2]

    if targetId and presetName then
        resetPresetUsage(targetId, presetName)
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'success',
            description = 'Reset preset usage for player'
        })
    end
end)

-- More useful exports for other resources
exports('ApplyPreset', InventoryPresets.ApplyPreset)
exports('ValidatePreset', InventoryPresets.ValidatePreset)
exports('UseActivatorItem', InventoryPresets.UseActivatorItem)
exports('GetAvailablePresets', InventoryPresets.GetAvailablePresets)
exports('CheckLocationActivation', InventoryPresets.CheckLocationActivation)
exports('ResetUsage', resetPresetUsage)
exports('HasUsedPreset', hasUsedPreset)
exports('GetPlayerUsage', getPlayerUsage)
exports('MarkPresetUsed', markPresetUsed)

-- Useful exports for integration
exports('IsSystemEnabled', function() return server.enablePresetsSystem end)
exports('GetAllPresets', function() return server.presets end)
exports('GetPresetInfo', function(presetName) return server.presets[presetName] end)

-- Quick preset application for other resources
exports('GivePresetToPlayer', function(playerId, presetName, bypassChecks)
    if bypassChecks then
        return InventoryPresets.ApplyPreset(playerId, presetName, true)
    else
        return InventoryPresets.ApplyPreset(playerId, presetName)
    end
end)

-- Bulk operations
exports('GivePresetToJob', function(job, presetName)
    local players = GetPlayers()
    local count = 0

    for _, playerId in ipairs(players) do
        local player = server.getPlayer(tonumber(playerId))
        if player and server.hasGroup(player, { job }) then
            local success = InventoryPresets.ApplyPreset(tonumber(playerId), presetName, true)
            if success then count = count + 1 end
        end
    end

    return count
end)

exports('ResetAllUsage', function(playerId)
    if playerUsage[playerId] then
        playerUsage[playerId] = {}
        return true
    end
    return false
end)

return InventoryPresets
