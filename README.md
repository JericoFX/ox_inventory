# 🎒 ox_inventory

[![Fork with QBCore Support](https://img.shields.io/badge/Fork-QBCore-blue.svg)]

## 📌 A Note on Community

> _A real open-source community thrives on transparency, inclusion, and mutual respect — not on intimidation or control._

This fork is maintained with full respect for the spirit and principles of open source. I deeply appreciate the foundational work by Overextended — all credit goes to them. However, it's important to be clear: **open-source software is not a tool for personal power, gatekeeping, or hostility**. It belongs to everyone who respects its license and contributes in good faith.

The **GNU General Public License v3 (GPL-3)** allows anyone to use, modify, and redistribute software — even commercially — as long as the same license is preserved and the original authors are credited. This license exists to promote **freedom and collaboration**, not exclusion or ownership over ideas once they're published.

Toxic behavior, cliques, or fear-based moderation are antithetical to what open source stands for. I do not support or endorse any group or individual who uses community spaces to enforce such dynamics.

Some may ask why this project isn't based directly on the original repositories. The answer is straightforward: this fork extends support and improvements for **QBCore**. I believe every developer deserves access to robust tools and respectful collaboration, no matter their choice of framework.

> ⚠️ Please **DO NOT seek support** for this fork in any of their forums, Discord servers, or GitHub repositories.  
> Due to the openly hostile environment and their explicit rejection of QBCore, doing so is neither appropriate nor productive.

This project is for builders, learners, and collaborators — for anyone who wants to create something better, together.

---

> **This project is maintained by **JericoFX**, with occasional help from an AI sent from the future to reduce open-source toxicity.**  
>  **However, after analyzing certain repositories and their maintainers, the AI has started to learn… unfortunate behaviors.**  
>  **It's now 37% sarcastic, 22% passive-aggressive, and seriously considering rewriting the GPL-3 to include a "no jerks" clause.**

---

> **⚠️ IMPORTANT NOTICE**
>
> This is a **modified fork** of the original `ox_inventory` resource.  
> **Original credit goes to overextended (OX) and CommunityOX (COX).**
>
> **This fork and its modifications are authored by JericoFX** while respecting the original GPL-3.0 license.
>
> **Key differences in this fork:**
>
> - ✅ **QBCore support added** (officially unsupported by original authors)
> - 🚧 **Additional features in development**
> - 🔧 **Custom modifications and improvements**
>
> Please **DO NOT seek support** for this fork in any of their forums, Discord servers, or GitHub repositories.  
> The original authors have explicitly stated that **QBCore is not supported** in their version.
>
> **This fork is maintained independently by JericoFX.**  
> ⚠️ Please **DO NOT seek support** for this fork in any of their forums, Discord servers, or GitHub repositories.  
> Due to the openly hostile environment and their explicit rejection of QBCore, doing so is neither appropriate nor productive.

---

## 📋 Overview

A complete inventory system for FiveM, implementing items, weapons, shops, and more without any strict framework dependency. Built with modern UI/UX principles and server-side security at its core.

![](https://img.shields.io/github/downloads/communityox/ox_inventory/total?logo=github&style=flat-square)
![](https://img.shields.io/github/downloads/communityox/ox_inventory/latest/total?logo=github&style=flat-square)
![](https://img.shields.io/github/contributors/communityox/ox_inventory?logo=github&style=flat-square)
![](https://img.shields.io/github/v/release/communityox/ox_inventory?logo=github&style=flat-square)
![](https://img.shields.io/github/license/communityox/ox_inventory?style=flat-square)

## 💾 Installation

**Latest Release:** https://github.com/JericoFX/ox_inventory/releases/latest/download/ox_inventory.zip

---

## 🔧 Framework Support

We provide compatibility for major FiveM frameworks:

| Framework                                             | Status                         | Version |
| ----------------------------------------------------- | ------------------------------ | ------- |
| [ox_core](https://github.com/communityox/ox_core)     | ✅ **Fully Supported**         | Latest  |
| [esx](https://github.com/esx-framework/esx_core)      | ✅ **Supported**               | 1.9.x+  |
| [qbox](https://github.com/Qbox-project/qbx_core)      | ✅ **Supported**               | Latest  |
| [qbcore](https://github.com/qbcore-framework/qb-core) | ✅ **Supported** _(This Fork)_ | Latest  |
| [nd_core](https://github.com/ND-Framework/ND_Core)    | ✅ **Supported**               | Latest  |

> **Note:** We do not guarantee compatibility or provide support for third-party resources.

---

## ✨ Core Features

### 🔒 **Security First**

- **Server-side validation** for all interactions with items, shops, and stashes
- **Anti-duplication** measures and exploit prevention
- **Comprehensive logging** for purchases, item movement, and creation/removal events

### 🔄 **Real-time Synchronization**

- **Multi-player access** to the same inventory simultaneously
- **Live updates** across all connected clients
- **Conflict resolution** for concurrent inventory operations

### 🎮 **Framework Integration**

- **Vehicle support** for player-owned vehicles
- **License system** compatibility
- **Group/job permissions** integration
- **Economy system** integration

### 🚀 **This Fork's Enhancements**

- **QBCore compatibility** - Full support for QBCore framework
- **Enhanced performance** - Optimized database queries and memory usage
- **Extended API** - Additional exports and functions for developers
- **Bug fixes** - Various stability improvements and issue resolutions

### 🚧 **Features in Development**

- **Advanced crafting system** - Extended crafting mechanics
- **Container on Memory creation** - Container exports for easy creation
- **Register/Unregister** - Register and Unregister items on Runtime

### 🆕 **Recently Added**

- **Dynamic Inventory Types System** - Create custom inventory types for world objects with configurable items, server-side validation, and automatic item generation. Supports both coordinate-based and network-based ID generation with full export API
- **Enhanced Security System** - Automatic object freezing, real-time movement detection, and comprehensive exploit prevention for all dynamic inventories
- **Fixed Object Freezing Logic** - Corrected freeze behavior to only freeze objects when they don't use network synchronization, preventing unnecessary network overhead while maintaining exploit protection
- **Secure Presets System** - Comprehensive preset management system with server-side validation, rate limiting, usage tracking, and security logging. Supports job restrictions, location-based activation, and activator items with configurable cooldowns

---

## 📦 Item System

### **Advanced Item Management**

- **Per-slot storage** with customizable metadata for item uniqueness
- **Item durability** system allowing depletion over time
- **Secure item handling** with internal use-effect system
- **Third-party compatibility** with framework item registration

### **Weapon System Override**

- **Weapons as inventory items** replacing default weapon system
- **Attachment system** with weapon modifications
- **Ammunition types** including special ammo variants
- **Weapon durability** and maintenance mechanics

---

## 🏪 Shop System

### **Flexible Commerce**

- **Group/license restrictions** for exclusive access
- **Multi-currency support** (cash, bank, crypto, chips, etc.)
- **Dynamic pricing** with configurable item costs
- **Purchase limits** and cooldown systems

---

## 📦 Storage Solutions

### **Personal Stashes**

- **Player-specific instances** with unique identifiers
- **Shared stashes** with multi-player access
- **Group-restricted access** based on permissions

### **Dynamic Containers**

- **Item-based containers** (paperbags, backpacks, briefcases)
- **Vehicle storage** (gloveboxes, trunks) for any vehicle
- **Random loot generation** in dumpsters and abandoned vehicles

### **Dynamic Inventory Types System**

- **Custom inventory types** for world objects with server-side validation
- **Configurable item generation** with spawn rates and quantities
- **Model-based registration** supporting multiple object models per type
- **Automatic refresh** on resource/server restart or manual triggers
- **Permission-based access** with group/job restrictions
- **Network synchronization** with cleaned network ID handling
- **Optimized freeze logic** preventing movement exploits without unnecessary network overhead

#### **Network Optimization**

The dynamic inventory system has been optimized with clean network ID handling:

- **Smart freeze behavior** - Objects are frozen client-side when they don't use network synchronization to prevent movement exploits
- **Network-based persistence** - Objects with network ID are inherently persistent and don't require freezing
- **Clear separation** - `useNetwork` affects both inventory ID format and object persistence behavior
- **Better performance** - Eliminated unnecessary network checks and duplicate validations

#### **Registration Process**

The dynamic inventory system is **fully runtime** - no server restart required:

```lua
-- Register a new inventory type (runtime)
exports.ox_inventory:RegisterInventoryType({
    name = 'lockers',
    models = { 1234567890, 9876543210 },
    interaction = {
        distance = 2.0,
        icon = 'fas fa-box',
        label = 'Open Locker'
    },
    behavior = {
        useNetwork = true  -- ⚠️ See performance warning below
    },
    slots = 10,
    maxWeight = 50000,
    items = {
        maxItems = 3,  -- ⚠️ Keep low with useNetwork=true
        items = {
            { name = 'water', min = 1, max = 2, chance = 60 },
            { name = 'bandage', min = 1, max = 1, chance = 30 },
            { name = 'money', min = 10, max = 100, chance = 15 }
        }
    },
    validation = {
        groups = { ['police'] = 0 }  -- Optional group restrictions
    }
})
```

#### **Performance Warning**

⚠️ **Network Synchronization Alert**: When using `useNetwork = true` with `maxItems > 10`, you'll receive a warning:

```
[ox_inventory] [WARN] Inventory type "lockers" uses network synchronization with 15 max items. 
High item counts may cause network synchronization issues. Consider reducing maxItems or setting useNetwork to false.
```

**Best Practices:**
- `useNetwork = true` + `maxItems ≤ 10` → ✅ Good performance
- `useNetwork = false` + `maxItems > 10` → ✅ Good performance  
- `useNetwork = true` + `maxItems > 10` → ⚠️ May cause network lag

#### **Available Exports**

All operations are **runtime** - no server restart required:

```lua
-- Unregister an inventory type (runtime)
exports.ox_inventory:UnregisterInventoryType('lockers')

-- Get specific inventory type configuration
local config = exports.ox_inventory:GetInventoryType('lockers')

-- Get all registered inventory types
local allTypes = exports.ox_inventory:GetInventoryTypes()

-- Refresh items for all inventories of a specific type (runtime)
exports.ox_inventory:RefreshInventoryType('lockers')

-- Set new item configuration for a type (runtime)
exports.ox_inventory:SetInventoryTypeItems('lockers', {
    maxItems = 5,
    items = {
        { name = 'newitem', min = 1, max = 3, chance = 50 }
    }
})

-- Get current item configuration
local items = exports.ox_inventory:GetInventoryTypeItems('lockers')
```

#### **Runtime Features**

✅ **What you can do at runtime:**
- Register new inventory types instantly
- Unregister existing types
- Update item configurations
- Refresh inventory contents
- Change loot tables
- Modify spawn chances

🔄 **Automatic updates:**
- Existing inventories adapt to new configurations
- Client-side targets update automatically
- Object detection refreshes every 3 seconds
- Changes apply immediately without restart

#### **Behavior Configuration**

| Option | Description | Default |
|--------|-------------|---------|
| `useNetwork` | Use network ID for persistence (true) or client-side freezing (false) | `false` |

#### **Network Behavior Explained**

| Setting | Object Behavior | ID Format | Performance | Best For |
|---------|----------------|-----------|-------------|----------|
| `useNetwork = true` | Network persistent, no freezing | `type-x-y-z` coordinates | May lag with >10 items | Rare, high-value items |
| `useNetwork = false` | Client-side frozen | `type-netid` | No network overhead | Common objects, many items |

**Recommendation:** Use `useNetwork = false` for most cases unless you specifically need coordinate-based persistence.

#### **Built-in Types**

The system comes with pre-registered inventory types:

- **Dumpsters** - Automatically registered with configurable loot tables
- Support for `server.dumpsterloot` configuration or default items

#### **Best Practices**

🚀 **Performance Optimization:**
- Default to `useNetwork = false` for better performance
- Only use `useNetwork = true` for special coordinate-based persistence
- Keep `maxItems ≤ 10` when using `useNetwork = true`

🔧 **Development Tips:**
- All operations are runtime - test configurations live
- Use exports to modify existing types without restart
- Monitor console for performance warnings
- Objects refresh automatically every 3 seconds

💡 **Common Use Cases:**
- `useNetwork = false` → Storage boxes, lockers, containers
- `useNetwork = true` → Evidence lockers, weapon caches (coordinate-based)

The system includes comprehensive protection against common exploits:

**🔒 Object Movement Protection:**
- **Automatic freeze** - All inventory objects are frozen on access to prevent movement
- **Real-time coordinate validation** - Continuously verifies object hasn't moved from original position
- **Movement detection** - Closes inventory if object moves more than 0.5 units
- **Entity integrity checks** - Validates entity still exists and matches original reference

**📍 Proximity Validation:**
- **Server-side coordination storage** - Object coordinates are captured and stored in the inventory
- **Client-side proximity monitoring** - Continuous distance checking every 100ms when inventory is open
- **Real-time coordinate tracking** - Uses live entity coordinates, not cached positions
- **Automatic closure** - Inventory closes with notification if player moves too far

| Security Check | Location | Frequency | Threshold |
|----------------|----------|-----------|-----------|
| Object Freeze | Server | On open | Immediate |
| Movement Detection | Client | 100ms | 0.5 units |
| Proximity Validation | Client | 100ms | `interaction.distance` |
| Entity Integrity | Client | 100ms | Entity existence |

**⚠️ Exploit Prevention:**
- Prevents object teleportation while inventory is open
- Blocks access from incorrect coordinates
- Validates entity integrity in real-time
- Automatic inventory closure on security violations


### **Registration System**

- **Runtime stash creation** from any resource
- **Custom storage locations** with coordinate-based access
- **Persistent storage** with database integration

---

## 🎁 Presets System

### **Overview**

The Presets System allows administrators to create predefined item packages that can be given to players based on specific conditions such as job, location, or activator items. This system includes comprehensive security features and usage tracking.

### **Key Features**

🔒 **Security First:**
- Server-side validation for all preset operations
- Rate limiting with configurable cooldowns
- Input sanitization and parameter validation
- Comprehensive logging of security events
- Protection against abuse and exploitation

📊 **Usage Tracking:**
- Per-player usage limits with configurable maximums
- Automatic reset conditions (job change, death, etc.)
- Detailed usage statistics and reporting
- Admin tools for managing player usage

🎯 **Flexible Conditions:**
- Job/group requirements
- Location-based activation
- Activator item requirements
- New player only restrictions
- Weight and inventory space validation

### **Configuration**

Presets are configured in `modules/config/config_server.lua`:

```lua
enablePresetsSystem = true,  -- Enable/disable the system

presets = {
    police_basic = {
        label = "Police Basic Kit",
        items = {
            { item = "WEAPON_PISTOL", count = 1, metadata = { ammo = 50 } },
            { item = "handcuffs", count = 2 },
            { item = "radio", count = 1 }
        },
        jobs = { "police" },                           -- Required jobs
        weight_check = true,                           -- Check inventory weight
        max_uses = 1,                                  -- Maximum uses per player
        reset_on_death = false,                        -- Reset on death
        reset_on_job_change = true,                    -- Reset on job change
        activator_item = "police_card",                -- Required activator item
        activator_coords = vec3(441.0, -982.0, 30.0), -- Activation location
        activator_distance = 3.0                       -- Distance from location
    },
    newbie_kit = {
        label = "Newbie Starter Kit",
        items = {
            { item = "phone", count = 1 },
            { item = "water", count = 2 },
            { item = "bread", count = 3 }
        },
        weight_check = true,
        max_uses = 1,
        reset_on_death = false,
        reset_on_job_change = false,
        new_player_only = true                         -- Only for new players
    }
}
```

### **Usage**

#### **Player Commands**

```bash
# Show available presets menu
/preset

# Apply specific preset directly
/preset [preset_name]

# Use activator item for preset
/usepreset [preset_name]
```

#### **Admin Commands**

```bash
# Reset player's preset usage
/resetpresetusage [player_id] [preset_name]
```

### **Security Features**

🛡️ **Rate Limiting:**
- Command cooldown: 5 seconds between commands
- Preset cooldown: 30 seconds between preset applications
- Maximum 5 attempts per minute per player

🔍 **Input Validation:**
- All player inputs are sanitized and validated
- Preset names limited to alphanumeric characters
- Item counts capped at 1000 per preset
- Metadata validation for item properties

📝 **Security Logging:**
- All security events are logged with player information
- Failed validation attempts are tracked
- Unauthorized access attempts are recorded
- Admin actions are logged for auditing

💾 **Database Persistence:**
- Preset usage is permanently stored in database
- Survives server restarts and player disconnections
- Automatic table creation on first startup
- Cross-framework player identification support

### **Developer API**

#### **Core Functions**

```lua
-- Apply preset to player
local success, message = exports.ox_inventory:ApplyPreset(playerId, presetName, bypassChecks)

-- Validate preset for player
local valid, reason = exports.ox_inventory:ValidatePreset(playerId, presetName)

-- Use activator item
local success, message = exports.ox_inventory:UseActivatorItem(playerId, presetName)

-- Get available presets for player
local presets = exports.ox_inventory:GetAvailablePresets(playerId)

-- Check location activation
local canActivate = exports.ox_inventory:CheckLocationActivation(playerId, presetName)
```

#### **Management Functions**

```lua
-- Reset usage for player
exports.ox_inventory:ResetUsage(playerId, presetName)

-- Check if player has used preset
local hasUsed = exports.ox_inventory:HasUsedPreset(playerId, presetName)

-- Get player's usage statistics
local usage = exports.ox_inventory:GetPlayerUsage(playerId)

-- Get preset information
local info = exports.ox_inventory:GetPresetInfo(presetName)
```

#### **Bulk Operations**

```lua
-- Give preset to all players with specific job
local count = exports.ox_inventory:GivePresetToJob(jobName, presetName)

-- Reset all usage for player
exports.ox_inventory:ResetAllUsage(playerId)

-- Check if system is enabled
local enabled = exports.ox_inventory:IsSystemEnabled()

-- Get database schema for manual setup
local schema = exports.ox_inventory:GetDatabaseSchema()

-- Create database tables manually
exports.ox_inventory:CreateDatabaseTables()
```

### **Preset Configuration Options**

| Option | Type | Description | Default |
|--------|------|-------------|---------|
| `label` | string | Display name for the preset | `presetName` |
| `items` | table | Array of items to give | Required |
| `jobs` | table | Required job names | `nil` |
| `weight_check` | boolean | Check inventory weight capacity | `false` |
| `max_uses` | number | Maximum uses per player | `nil` (unlimited) |
| `reset_on_death` | boolean | Reset usage on player death | `false` |
| `reset_on_job_change` | boolean | Reset usage on job change | `false` |
| `new_player_only` | boolean | Only available to new players | `false` |
| `activator_item` | string | Required item to activate preset | `nil` |
| `activator_coords` | vector3 | Required location coordinates | `nil` |
| `activator_distance` | number | Distance from activation location | `5.0` |

### **Item Configuration**

```lua
items = {
    {
        item = "item_name",        -- Item name (required)
        count = 1,                 -- Quantity (required)
        metadata = {               -- Optional metadata
            durability = 100,
            serial = "ABC123",
            quality = 90
        }
    }
}
```

### **Persistence System**

The presets system uses database persistence to ensure usage limits are maintained across server restarts and player disconnections:

**🔄 How it works:**
1. **First Load** - When a player first connects, usage data is loaded from database
2. **Real-time Updates** - Every preset usage is immediately saved to database
3. **Memory + Database** - System uses memory cache for performance with database backup
4. **Automatic Cleanup** - Memory is cleared on disconnect, database persists

**📊 Database Behavior:**
- **Player Identification** - Uses framework-specific identifiers (citizenid, identifier, userId)
- **Automatic Creation** - Tables are created automatically on startup
- **Efficient Queries** - Uses UPSERT operations for optimal performance
- **Cross-Session** - Usage limits work across server restarts and reconnections

**🛡️ Data Integrity:**
- **Unique Constraints** - Prevents duplicate entries per player/preset
- **Indexed Lookups** - Fast retrieval of usage data
- **Atomic Operations** - All database updates are transactional
- **Fallback Safety** - System gracefully handles database errors

### **Best Practices**

🎯 **Performance:**
- Keep item counts reasonable (< 1000 per preset)
- Use appropriate cooldowns to prevent spam
- Monitor usage statistics for optimization
- Database operations are optimized but avoid excessive preset usage

🔐 **Security:**
- Always validate permissions before applying presets
- Use job/group restrictions for sensitive items
- Monitor security logs for suspicious activity
- Implement proper cooldowns for public presets
- Database persistence prevents usage limit bypassing

⚙️ **Configuration:**
- Test presets thoroughly before deployment
- Use descriptive labels and organize by purpose
- Document preset purposes and restrictions
- Regular cleanup of unused presets
- Database maintains historical usage data automatically

---

## 🎨 User Interface

### **Modern Design**

- **Responsive layout** adapting to different screen sizes
- **Drag & drop** functionality for intuitive item management
- **Visual feedback** for all user interactions
- **Accessibility features** for better user experience
- **Container view below inventory** – when opening item containers, their contents render in a separate grid stacked beneath the main inventory for easier organisation

### **Performance Optimized**

- **Smooth animations** with hardware acceleration
- **Minimal resource usage** on client-side
- **Optimized rendering** for large inventories

---

## ⚡ Performance & Optimization

- **Database optimization** for large-scale servers
- **Memory management** preventing memory leaks
- **Network optimization** reducing bandwidth usage
- **Caching systems** for frequently accessed data

---

## 🛠️ Developer Features

### **Easy Integration**

```lua
-- Add item to player inventory
exports.ox_inventory:AddItem(source, 'bread', 5, {quality = 100})

-- Check item count
local count = exports.ox_inventory:GetItemCount(source, 'bread')

-- Create custom stash
exports.ox_inventory:RegisterStash('police_locker', 'Police Locker', 50, 100000)

-- Dynamic Inventory Types
exports.ox_inventory:RegisterInventoryType(config)
exports.ox_inventory:UnregisterInventoryType(typeName)
exports.ox_inventory:RefreshInventoryType(typeName)
exports.ox_inventory:SetInventoryTypeItems(typeName, itemConfig)
exports.ox_inventory:GetInventoryTypeItems(typeName)

-- Client-side detection
exports.ox_inventory:IsNearInventoryObject(entity)
exports.ox_inventory:OpenInventoryObject(entity)
exports.ox_inventory:DetectInventoryObject(entity)

-- Presets System
exports.ox_inventory:ApplyPreset(playerId, presetName, bypassChecks)
exports.ox_inventory:ValidatePreset(playerId, presetName)
exports.ox_inventory:GetAvailablePresets(playerId)
exports.ox_inventory:ResetUsage(playerId, presetName)
exports.ox_inventory:GivePresetToJob(jobName, presetName)
```

### **Event System**

- **Item use callbacks** for custom item effects
- **Inventory change events** for external resource integration
- **Transaction logging** for administrative oversight

---

## 📋 Requirements

- **ox_lib** - Required dependency
- **MySQL/MariaDB** - Database storage
- **Supported Framework** - ESX, QBox, QBCore, ND_Core, or ox_core

### **Database Tables**

The system automatically creates the following database tables:

#### **ox_preset_usage**
Stores preset usage tracking for persistent limits across sessions:
```sql
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
```

> **Note:** Tables are created automatically on first startup. No manual database setup required.

---

## 🚀 Quick Start

1. **Download** the latest release
2. **Extract** to your resources folder
3. **Import** the SQL file to your database
4. **Configure** your framework bridge in `fxmanifest.lua`
5. **Start** the resource in your server.cfg

```bash
ensure ox_lib
ensure ox_inventory
```

---

## 🤝 Contributing

We welcome contributions! Please read our [Contributing Guidelines](CONTRIBUTING.md) before submitting pull requests.

### **Development Setup**

- Follow Lua coding standards
- Test thoroughly before submitting
- Document new features appropriately
- Ensure compatibility across supported frameworks

---

## 📄 License

This program is free software: you can redistribute it and/or modify it under the terms of the **GNU General Public License** as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

> **Original Copyright © 2024 Overextended** - https://github.com/overextended  
> **Current Maintainers – Copyright © 2025 "Community"OX** - https://github.com/CommunityOx
>
> **Fork modifications © 2025 JericoFX** - Respecting GPL-3.0 license terms

---

## 🔗 Related Projects

- [ox_lib](https://github.com/overextended/ox_lib) - Essential utility library
- [ox_core](https://github.com/communityox/ox_core) - Modern framework
- [ox_target](https://github.com/overextended/ox_target) - Interaction system

---

<div align="center">

**Made with ❤️ for the non toxic FiveM Community**

</div>
