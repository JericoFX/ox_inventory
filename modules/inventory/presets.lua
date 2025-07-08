local InventoryPresets = {}

local playerUsage = {}
local playerCooldowns = {}
local rateLimits = {
    commandCooldown = 5000,
    presetCooldown = 30000,
    maxAttemptsPerMinute = 5
}
local playerAttempts = {}

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

local function validatePlayer(playerId)
    if not playerId or playerId == 0 then return false end
    local player = GetPlayerPed(playerId)
    return player and player ~= 0 and GetPlayerName(playerId) ~= nil
end

local function sanitizeInput(input)
    if type(input) ~= "string" then return nil end
    return input:gsub("[^%w_%-]", ""):sub(1, 50)
end

local function isRateLimited(playerId, action)
    local now = GetGameTimer()
    local playerKey = tostring(playerId)
    
    if not playerCooldowns[playerKey] then
        playerCooldowns[playerKey] = {}
    end
    
    local lastAction = playerCooldowns[playerKey][action]
    local cooldownTime = rateLimits[action] or rateLimits.commandCooldown
    
    if lastAction and (now - lastAction) < cooldownTime then
        return true
    end
    
    playerCooldowns[playerKey][action] = now
    return false
end

local function checkAttemptLimit(playerId)
    local now = GetGameTimer()
    local playerKey = tostring(playerId)
    
    if not playerAttempts[playerKey] then
        playerAttempts[playerKey] = {}
    end
    
    local attempts = playerAttempts[playerKey]
    local cutoff = now - 60000
    
    for i = #attempts, 1, -1 do
        if attempts[i] < cutoff then
            table.remove(attempts, i)
        end
    end
    
    if #attempts >= rateLimits.maxAttemptsPerMinute then
        return false
    end
    
    attempts[#attempts + 1] = now
    return true
end

local function logSecurityEvent(playerId, event, details)
    local playerName = GetPlayerName(playerId) or "Unknown"
    lib.logger(playerId, 'security_event', ('Security: %s - Player: %s (%s) - %s'):format(
        event, playerName, playerId, details or ""
    ))
end

local function getPlayerIdentifier(playerId)
    local player = server.getPlayer(playerId)
    if not player then return nil end
    
    if shared.framework == 'qb' then
        local qbPlayer = exports['qb-core']:GetPlayer(playerId)
        return qbPlayer and qbPlayer.PlayerData.citizenid
    elseif shared.framework == 'esx' then
        return player.identifier
    elseif shared.framework == 'ox' then
        return player.userId and tostring(player.userId)
    elseif shared.framework == 'nd' then
        local NDCore = exports["ND_Core"]
        local ndPlayer = NDCore:getPlayer(playerId)
        return ndPlayer and ndPlayer.getData().id
    end
    
    return nil
end

local function getPlayerUsage(playerId)
    local playerKey = tostring(playerId)
    if not playerUsage[playerKey] then
        playerUsage[playerKey] = {}
        
        local identifier = getPlayerIdentifier(playerId)
        if identifier then
            local result = MySQL.query.await('SELECT preset_name, usage_count FROM ox_preset_usage WHERE player_identifier = ?', {
                identifier
            })
            
            if result then
                for _, row in ipairs(result) do
                    playerUsage[playerKey][row.preset_name] = row.usage_count
                end
            end
        end
    end
    return playerUsage[playerKey]
end

local function hasUsedPreset(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    return usage[presetName] and usage[presetName] > 0
end

local function markPresetUsed(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    usage[presetName] = (usage[presetName] or 0) + 1
    
    local identifier = getPlayerIdentifier(playerId)
    if identifier then
        MySQL.query.await('INSERT INTO ox_preset_usage (player_identifier, preset_name, usage_count) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE usage_count = usage_count + 1', {
            identifier,
            presetName,
            usage[presetName]
        })
    end
end

local function resetPresetUsage(playerId, presetName)
    local usage = getPlayerUsage(playerId)
    if usage[presetName] then
        usage[presetName] = 0
    end
    
    local identifier = getPlayerIdentifier(playerId)
    if identifier then
        MySQL.query.await('DELETE FROM ox_preset_usage WHERE player_identifier = ? AND preset_name = ?', {
            identifier,
            presetName
        })
    end
end

local function validatePresetData(preset)
    if not preset or type(preset) ~= "table" then return false end
    if not preset.items or type(preset.items) ~= "table" then return false end
    
    for _, itemData in pairs(preset.items) do
        if not itemData.item or not itemData.count then return false end
        if type(itemData.count) ~= "number" or itemData.count <= 0 then return false end
        if itemData.count > 1000 then return false end
    end
    
    return true
end

local function isNewPlayer(playerId)
    local player = server.getPlayer(playerId)
    if not player then return false end
    
    local newPlayerThreshold = 3600 -- 1 hour in seconds
    
    -- Framework-specific detection
    if shared.framework == 'qb' then
        -- QBCore: Check total playtime from player data
        local qbPlayer = exports['qb-core']:GetPlayer(playerId)
        if qbPlayer and qbPlayer.PlayerData.metadata then
            local playtime = qbPlayer.PlayerData.metadata.playtime or 0
            return playtime < newPlayerThreshold
        end
        
        -- Fallback: Check character creation date
        local result = MySQL.scalar.await('SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) FROM players WHERE citizenid = ?', {
            qbPlayer and qbPlayer.PlayerData.citizenid
        })
        return result and result < newPlayerThreshold
        
    elseif shared.framework == 'esx' then
        -- ESX: Check playtime from database
        local result = MySQL.scalar.await('SELECT playtime FROM users WHERE identifier = ?', {
            player.identifier
        })
        if result then
            return result < newPlayerThreshold
        end
        
        -- Fallback: Check creation date
        local created = MySQL.scalar.await('SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) FROM users WHERE identifier = ?', {
            player.identifier
        })
        return created and created < newPlayerThreshold
        
    elseif shared.framework == 'ox' then
        -- OX: Check user data
        local userId = player.userId
        if userId then
            local result = MySQL.scalar.await('SELECT TIMESTAMPDIFF(SECOND, created_at, NOW()) FROM users WHERE user_id = ?', {
                userId
            })
            return result and result < newPlayerThreshold
        end
        
    elseif shared.framework == 'nd' then
        -- ND: Check character data
        local NDCore = exports["ND_Core"]
        local ndPlayer = NDCore:getPlayer(playerId)
        if ndPlayer and ndPlayer.getData then
            local characterData = ndPlayer.getData()
            if characterData.createdAt then
                local timeDiff = os.time() - characterData.createdAt
                return timeDiff < newPlayerThreshold
            end
        end
    end
    
    -- Fallback: Consider as new player if we can't determine
    -- This is safer than denying access
    lib.logger(playerId, 'preset_fallback', 'Could not determine player age, defaulting to new player')
    return true
end

function InventoryPresets.ValidatePreset(playerId, presetName, bypassUsageCheck)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    if not server.enablePresetsSystem then return false, "Presets disabled" end
    
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
    local preset = server.presets[presetName]
    if not preset then return false, "Preset not found" end
    
    if not validatePresetData(preset) then return false, "Invalid preset data" end
    
    local inv = getInventory()(playerId)
    if not inv then return false, "Inventory not found" end
    
    if not bypassUsageCheck and preset.max_uses and hasUsedPreset(playerId, presetName) then
        local usage = getPlayerUsage(playerId)
        if usage[presetName] >= preset.max_uses then
            return false, "Already used maximum times"
        end
    end
    
    if preset.new_player_only then
        if not isNewPlayer(playerId) then
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
            else
                return false, "Invalid item in preset: " .. itemData.item
            end
        end
        
        if inv.weight + totalWeight > inv.maxWeight then
            return false, "Not enough weight capacity"
        end
    end
    
    local slotsNeeded = 0
    for _, itemData in pairs(preset.items) do
        local item = getItems()(itemData.item)
        if item then
            if not item.stack then
                slotsNeeded = slotsNeeded + itemData.count
            else
                slotsNeeded = slotsNeeded + 1
            end
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
    if not validatePlayer(playerId) then return false, "Invalid player" end
    
    if not bypassUsageCheck and isRateLimited(playerId, 'presetCooldown') then
        return false, "Please wait before using another preset"
    end
    
    local valid, reason = InventoryPresets.ValidatePreset(playerId, presetName, bypassUsageCheck)
    if not valid then 
        logSecurityEvent(playerId, 'PRESET_VALIDATION_FAILED', reason)
        return false, reason 
    end
    
    local preset = server.presets[presetName]
    local inv = getInventory()(playerId)
    local success_count = 0
    
    for _, itemData in pairs(preset.items) do
        local metadata = itemData.metadata
        if metadata and type(metadata) == "table" then
            for k, v in pairs(metadata) do
                if type(k) ~= "string" or (type(v) ~= "string" and type(v) ~= "number") then
                    metadata[k] = nil
                end
            end
        end
        
        local success = getInventory().AddItem(inv, itemData.item, itemData.count, metadata)
        if success then
            success_count = success_count + 1
        end
    end
    
    if success_count > 0 then
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

function InventoryPresets.CheckLocationActivation(playerId, presetName)
    if not validatePlayer(playerId) then return false end
    
    local preset = server.presets[presetName]
    if not preset.activator_coords then return true end
    
    local playerPed = GetPlayerPed(playerId)
    if not playerPed or playerPed == 0 then return false end
    
    local playerCoords = GetEntityCoords(playerPed)
    local distance = #(playerCoords - preset.activator_coords)
    
    return distance <= (preset.activator_distance or 5.0)
end

function InventoryPresets.UseActivatorItem(playerId, presetName)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
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
    
    getInventory().RemoveItem(inv, preset.activator_item, 1)
    
    return InventoryPresets.ApplyPreset(playerId, presetName)
end

-- Framework-specific death events
if shared.framework == 'qb' then
    AddEventHandler('hospital:server:SetDeathStatus', function(isDead)
        if isDead then
            local playerId = source
            TriggerEvent('ox_inventory:playerDied', playerId)
        end
    end)
    
    AddEventHandler('qb-ambulancejob:server:SetDeathStatus', function(isDead)
        if isDead then
            local playerId = source
            TriggerEvent('ox_inventory:playerDied', playerId)
        end
    end)
    
elseif shared.framework == 'esx' then
    AddEventHandler('esx_ambulancejob:onPlayerDeath', function()
        local playerId = source
        TriggerEvent('ox_inventory:playerDied', playerId)
    end)
    
    AddEventHandler('esx:onPlayerDeath', function(data)
        local playerId = source
        TriggerEvent('ox_inventory:playerDied', playerId)
    end)
    
elseif shared.framework == 'ox' then
    AddEventHandler('ox:playerDeath', function(playerId)
        TriggerEvent('ox_inventory:playerDied', playerId)
    end)
    
elseif shared.framework == 'nd' then
    AddEventHandler('ND:characterDied', function(playerId)
        TriggerEvent('ox_inventory:playerDied', playerId)
    end)
end

-- Generic death detection fallback
AddEventHandler('baseevents:onPlayerDied', function(killerType, coords)
    local playerId = source
    TriggerEvent('ox_inventory:playerDied', playerId)
end)

AddEventHandler('ox_inventory:playerJobChanged', function(playerId, oldJob, newJob)
    if not validatePlayer(playerId) then return end
    
    for presetName, preset in pairs(server.presets) do
        if preset.reset_on_job_change then
            resetPresetUsage(playerId, presetName)
        end
    end
end)

AddEventHandler('ox_inventory:playerDied', function(playerId)
    if not validatePlayer(playerId) then return end
    
    for presetName, preset in pairs(server.presets) do
        if preset.reset_on_death then
            resetPresetUsage(playerId, presetName)
        end
    end
end)

AddEventHandler('playerDropped', function()
    local playerId = source
    local playerKey = tostring(playerId)
    playerUsage[playerKey] = nil
    playerCooldowns[playerKey] = nil
    playerAttempts[playerKey] = nil
end)

function InventoryPresets.GetAvailablePresets(playerId)
    if not validatePlayer(playerId) then return {} end
    if not server.enablePresetsSystem then return {} end
    
    local available = {}
    local player = server.getPlayer(playerId)
    
    for presetName, preset in pairs(server.presets) do
        if not validatePresetData(preset) then goto continue end
        
        local canUse = true
        local reason = ""
        local usageInfo = ""
        
        if preset.jobs and not server.hasGroup(player, preset.jobs) then
            canUse = false
            reason = "Job required"
        end
        
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
        
        if preset.new_player_only and not isNewPlayer(playerId) then
            canUse = false
            reason = "Only for new players"
        end
        
        available[#available + 1] = {
            name = presetName,
            label = preset.label or presetName,
            canUse = canUse,
            reason = reason,
            usageInfo = usageInfo,
            needsLocation = preset.activator_coords ~= nil
        }
        
        ::continue::
    end
    
    return available
end

lib.addCommand('preset', {
    help = 'Apply a preset inventory package',
    params = {
        {
            name = 'preset_name',
            type = 'string',
            help = 'Name of the preset to apply (optional)',
            optional = true
        }
    }
}, function(source, args)
    if not validatePlayer(source) then return end
    if not server.enablePresetsSystem then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Presets system is disabled'
        })
        return
    end
    
    if not checkAttemptLimit(source) then
        logSecurityEvent(source, 'PRESET_RATE_LIMIT', 'Too many attempts')
        return
    end
    
    if isRateLimited(source, 'commandCooldown') then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Please wait before using this command again'
        })
        return
    end
    
    local presetName = args.preset_name and sanitizeInput(args.preset_name)
    if not presetName then
        local available = InventoryPresets.GetAvailablePresets(source)
        local options = {}
        
        for _, preset in ipairs(available) do
            if preset.canUse then
                options[#options + 1] = {
                    title = preset.label,
                    description = preset.usageInfo,
                    args = { preset.name }
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
            options = options
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

lib.addCommand('usepreset', {
    help = 'Use an activator item to apply a preset',
    params = {
        {
            name = 'preset_name',
            type = 'string',
            help = 'Name of the preset to activate (optional)',
            optional = true
        }
    }
}, function(source, args)
    if not validatePlayer(source) then return end
    if not server.enablePresetsSystem then return end
    
    if not checkAttemptLimit(source) then
        logSecurityEvent(source, 'USEPRESET_RATE_LIMIT', 'Too many attempts')
        return
    end
    
    if isRateLimited(source, 'commandCooldown') then
        return
    end
    
    local presetName = args.preset_name and sanitizeInput(args.preset_name)
    if not presetName then
        local available = InventoryPresets.GetAvailablePresets(source)
        local options = {}
        
        for _, preset in ipairs(available) do
            local presetData = server.presets[preset.name]
            if presetData and presetData.activator_item and preset.canUse then
                options[#options + 1] = {
                    title = preset.label,
                    description = "Requires item" .. (preset.needsLocation and " + Location" or ""),
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
            options = options
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

RegisterNetEvent('ox_inventory:selectPreset', function(presetName)
    if not validatePlayer(source) then return end
    
    presetName = sanitizeInput(presetName)
    if not presetName then
        logSecurityEvent(source, 'INVALID_PRESET_NAME', presetName)
        return
    end
    
    local success, message = InventoryPresets.ApplyPreset(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

RegisterNetEvent('ox_inventory:usePresetItem', function(presetName)
    if not validatePlayer(source) then return end
    
    presetName = sanitizeInput(presetName)
    if not presetName then
        logSecurityEvent(source, 'INVALID_PRESET_NAME', presetName)
        return
    end
    
    local success, message = InventoryPresets.UseActivatorItem(source, presetName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = success and 'success' or 'error',
        description = message
    })
end)

lib.addCommand('resetpresetusage', {
    help = 'Reset preset usage for a specific player',
    params = {
        {
            name = 'target_id',
            type = 'playerId',
            help = 'Player ID to reset usage for'
        },
        {
            name = 'preset_name',
            type = 'string',
            help = 'Name of the preset to reset'
        }
    },
    restricted = 'group.admin'
}, function(source, args)
    local targetId = args.target_id
    local presetName = args.preset_name and sanitizeInput(args.preset_name)
    
    if not targetId or not validatePlayer(targetId) then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid target player'
        })
        return
    end
    
    if not presetName then
        TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = 'Invalid preset name'
        })
        return
    end
    
    resetPresetUsage(targetId, presetName)
    lib.logger(source, 'admin_action', ('Reset preset usage: %s for player %s'):format(presetName, targetId))
    
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'success',
        description = 'Reset preset usage for player'
    })
end)

exports('ApplyPreset', function(playerId, presetName, bypassChecks)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
    return InventoryPresets.ApplyPreset(playerId, presetName, bypassChecks)
end)

exports('ValidatePreset', function(playerId, presetName, bypassUsageCheck)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
    return InventoryPresets.ValidatePreset(playerId, presetName, bypassUsageCheck)
end)

exports('UseActivatorItem', function(playerId, presetName)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
    return InventoryPresets.UseActivatorItem(playerId, presetName)
end)

exports('GetAvailablePresets', function(playerId)
    if not validatePlayer(playerId) then return {} end
    return InventoryPresets.GetAvailablePresets(playerId)
end)

exports('CheckLocationActivation', function(playerId, presetName)
    if not validatePlayer(playerId) then return false end
    presetName = sanitizeInput(presetName)
    if not presetName then return false end
    
    return InventoryPresets.CheckLocationActivation(playerId, presetName)
end)

exports('ResetUsage', function(playerId, presetName)
    if not validatePlayer(playerId) then return false end
    presetName = sanitizeInput(presetName)
    if not presetName then return false end
    
    resetPresetUsage(playerId, presetName)
    return true
end)

exports('HasUsedPreset', function(playerId, presetName)
    if not validatePlayer(playerId) then return false end
    presetName = sanitizeInput(presetName)
    if not presetName then return false end
    
    return hasUsedPreset(playerId, presetName)
end)

exports('GetPlayerUsage', function(playerId)
    if not validatePlayer(playerId) then return {} end
    return getPlayerUsage(playerId)
end)

exports('IsSystemEnabled', function() 
    return server.enablePresetsSystem 
end)

exports('GetPresetInfo', function(presetName)
    presetName = sanitizeInput(presetName)
    if not presetName then return nil end
    
    local preset = server.presets[presetName]
    if not preset or not validatePresetData(preset) then return nil end
    
    return {
        label = preset.label,
        jobs = preset.jobs,
        max_uses = preset.max_uses,
        new_player_only = preset.new_player_only,
        weight_check = preset.weight_check,
        hasActivator = preset.activator_item ~= nil,
        hasLocation = preset.activator_coords ~= nil
    }
end)

exports('GivePresetToPlayer', function(playerId, presetName, bypassChecks)
    if not validatePlayer(playerId) then return false, "Invalid player" end
    presetName = sanitizeInput(presetName)
    if not presetName then return false, "Invalid preset name" end
    
    return InventoryPresets.ApplyPreset(playerId, presetName, bypassChecks)
end)

exports('GivePresetToJob', function(job, presetName)
    if type(job) ~= "string" then return 0 end
    presetName = sanitizeInput(presetName)
    if not presetName then return 0 end
    
    local players = GetPlayers()
    local count = 0
    
    for _, playerId in ipairs(players) do
        local numericId = tonumber(playerId)
        if validatePlayer(numericId) then
            local player = server.getPlayer(numericId)
            if player and server.hasGroup(player, { job }) then
                local success = InventoryPresets.ApplyPreset(numericId, presetName, true)
                if success then count = count + 1 end
            end
        end
    end
    
    return count
end)

exports('ResetAllUsage', function(playerId)
    if not validatePlayer(playerId) then return false end
    
    local playerKey = tostring(playerId)
    if playerUsage[playerKey] then
        playerUsage[playerKey] = {}
        
        local identifier = getPlayerIdentifier(playerId)
        if identifier then
            MySQL.query.await('DELETE FROM ox_preset_usage WHERE player_identifier = ?', {
                identifier
            })
        end
        
        return true
    end
    return false
end)

exports('GetDatabaseSchema', function()
    return [[
        CREATE TABLE IF NOT EXISTS `ox_preset_usage` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `player_identifier` varchar(100) NOT NULL,
            `preset_name` varchar(50) NOT NULL,
            `usage_count` int(11) NOT NULL DEFAULT 0,
            `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `player_preset` (`player_identifier`, `preset_name`),
            KEY `idx_player_identifier` (`player_identifier`),
            KEY `idx_preset_name` (`preset_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]]
end)

exports('CreateDatabaseTables', function()
    local schema = exports.ox_inventory:GetDatabaseSchema()
    MySQL.query.await(schema)
    lib.logger(0, 'preset_system', 'Database tables created successfully')
    return true
end)

CreateThread(function()
    if server.enablePresetsSystem then
        local schema = [[
            CREATE TABLE IF NOT EXISTS `ox_preset_usage` (
                `id` int(11) NOT NULL AUTO_INCREMENT,
                `player_identifier` varchar(100) NOT NULL,
                `preset_name` varchar(50) NOT NULL,
                `usage_count` int(11) NOT NULL DEFAULT 0,
                `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                UNIQUE KEY `player_preset` (`player_identifier`, `preset_name`),
                KEY `idx_player_identifier` (`player_identifier`),
                KEY `idx_preset_name` (`preset_name`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]
        
        MySQL.query.await(schema)
        lib.logger(0, 'preset_system', 'Presets system initialized with database persistence')
    end
end)

return InventoryPresets
