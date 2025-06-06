# 📦 Preset System Exports

## Basic Usage

### Enable/Configure System

```lua
-- In config_server.lua
enablePresetsSystem = true
presets = {
    custom_preset = {
        label = "Custom Kit",
        items = {
            {item = "item_name", count = 3},
            {item = "another_item", count = 1}
        },
        max_uses = 1,
        jobs = {"police"},
        weight_check = true
    }
}
```

## 🎮 Commands with ox_lib Menus

### `/preset` - Interactive Menu

- Shows available presets with status
- ✅ Available presets
- ❌ Disabled presets with reason
- Usage counter display

### `/usepreset` - Activator Item Menu

- Shows presets that require activator items
- Item + location requirements
- Consumes activator item on use

## 🔧 Exports for Other Resources

### Basic Operations

```lua
-- Apply preset to player
local success, message = exports.ox_inventory:ApplyPreset(playerId, "police_basic")

-- Validate before applying
local valid, reason = exports.ox_inventory:ValidatePreset(playerId, "police_basic")

-- Use activator item system
local success, message = exports.ox_inventory:UseActivatorItem(playerId, "police_basic")

-- Get available presets for player
local presets = exports.ox_inventory:GetAvailablePresets(playerId)
```

### Information Exports

```lua
-- Check if system is enabled
local enabled = exports.ox_inventory:IsSystemEnabled()

-- Get all preset configurations
local allPresets = exports.ox_inventory:GetAllPresets()

-- Get specific preset info
local presetInfo = exports.ox_inventory:GetPresetInfo("police_basic")

-- Check player usage
local hasUsed = exports.ox_inventory:HasUsedPreset(playerId, "police_basic")
local usage = exports.ox_inventory:GetPlayerUsage(playerId)
```

### Advanced Operations

```lua
-- Give preset bypassing all checks
local success = exports.ox_inventory:GivePresetToPlayer(playerId, "police_basic", true)

-- Give preset to all players with specific job
local count = exports.ox_inventory:GivePresetToJob("police", "police_basic")
-- Returns: number of players who received the preset

-- Reset all usage for player
local success = exports.ox_inventory:ResetAllUsage(playerId)

-- Reset specific preset usage
exports.ox_inventory:ResetUsage(playerId, "police_basic")

-- Mark preset as used (for custom logic)
exports.ox_inventory:MarkPresetUsed(playerId, "police_basic")
```

## 🎯 Integration Examples

### Job System Integration

```lua
-- When player gets hired as police
AddEventHandler('esx:setJob', function(source, job, lastJob)
    if job.name == 'police' then
        -- Give police preset automatically
        exports.ox_inventory:GivePresetToPlayer(source, "police_basic")
    end
end)
```

### Custom NPC Interaction

```lua
-- Create NPC that gives presets
RegisterNetEvent('myresource:talkToQuartermaster', function()
    local playerId = source
    local available = exports.ox_inventory:GetAvailablePresets(playerId)

    -- Filter for job-specific presets
    local jobPresets = {}
    for _, preset in ipairs(available) do
        if preset.canUse and preset.name:find("police") then
            table.insert(jobPresets, preset)
        end
    end

    -- Show custom menu or apply directly
    if #jobPresets > 0 then
        exports.ox_inventory:ApplyPreset(playerId, jobPresets[1].name)
    end
end)
```

### Location-Based Preset Access

```lua
-- Check if player can use preset at location
local canUse = exports.ox_inventory:CheckLocationActivation(playerId, "police_basic")

if canUse then
    exports.ox_inventory:UseActivatorItem(playerId, "police_basic")
else
    -- Player needs to move to correct location
end
```

### Usage Tracking & Analytics

```lua
-- Get detailed usage stats
local usage = exports.ox_inventory:GetPlayerUsage(playerId)
-- Returns: {preset_name = usage_count, ...}

-- Check if player has reached limit
local hasUsed = exports.ox_inventory:HasUsedPreset(playerId, "newbie_kit")

-- Custom reset logic
RegisterNetEvent('myresource:resetWeekly', function()
    for _, playerId in ipairs(GetPlayers()) do
        exports.ox_inventory:ResetAllUsage(tonumber(playerId))
    end
end)
```

## 🎛️ Preset Configuration Options

```lua
preset_name = {
    label = "Display Name",
    items = {
        {item = "item_name", count = 1, metadata = {durability = 100}}
    },

    -- Restrictions
    jobs = {"police", "ambulance"},     -- Required jobs
    max_uses = 1,                       -- Usage limit
    new_player_only = true,             -- Only for new players
    weight_check = true,                -- Validate weight capacity

    -- Reset conditions
    reset_on_death = false,             -- Reset usage on death
    reset_on_job_change = true,         -- Reset when changing jobs

    -- Activator system
    activator_item = "police_card",     -- Required item (consumed)
    activator_coords = vec3(x, y, z),   -- Required location
    activator_distance = 5.0            -- Max distance from coords
}
```

## 🔨 Admin Commands

```bash
/resetpresetusage [playerid] [preset]  # Reset specific usage
```

## 📊 Return Values

### ApplyPreset / GivePresetToPlayer

- `success` (boolean): Operation success
- `message` (string): Result description with usage info

### ValidatePreset

- `valid` (boolean): Can apply preset
- `reason` (string): Failure reason if invalid

### GetAvailablePresets

Returns array of:

```lua
{
    name = "preset_name",
    label = "Display Name",
    canUse = true/false,
    reason = "failure_reason",
    usageInfo = "(1/3 uses)",
    activatorItem = "item_name",
    needsLocation = true/false
}
```

## ⚡ Performance Notes

- Usage tracking is stored in memory (cleared on disconnect)
- Validation is lightweight and cached
- Bulk operations are optimized for multiple players
- Location checks use native distance calculations
