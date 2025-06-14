# 🎒 ox_inventory

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
> For issues, questions, or contributions, please use **this repository only**.

---

## 📋 Overview

A complete inventory system for FiveM, implementing items, weapons, shops, and more without any strict framework dependency. Built with modern UI/UX principles and server-side security at its core.

![](https://img.shields.io/github/downloads/communityox/ox_inventory/total?logo=github&style=flat-square)
![](https://img.shields.io/github/downloads/communityox/ox_inventory/latest/total?logo=github&style=flat-square)
![](https://img.shields.io/github/contributors/communityox/ox_inventory?logo=github&style=flat-square)
![](https://img.shields.io/github/v/release/communityox/ox_inventory?logo=github&style=flat-square)
![](https://img.shields.io/github/license/communityox/ox_inventory?style=flat-square)

---

## 📚 Documentation

**Official Documentation:** https://coxdocs.dev/ox_inventory

---

## 💾 Installation

**Latest Release:** https://github.com/communityox/ox_inventory/releases/latest/download/ox_inventory.zip

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

### **Runtime Item Registration**

- **RegisterItem / UnregisterItem** exports let any resource create or remove items at runtime without server restart.
- Calls are **rate-limited (10 per second, per resource)** to avoid network spam.

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

### **Registration System**

- **Runtime stash creation** from any resource
- **Custom storage locations** with coordinate-based access
- **Persistent storage** with database integration

---

## 🎨 User Interface

### **Modern Design**

- **Responsive layout** adapting to different screen sizes
- **Drag & drop** functionality for intuitive item management
- **Visual feedback** for all user interactions
- **Accessibility features** for better user experience

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

**Original Copyright © 2024 Overextended** - https://github.com/overextended  
**Fork modifications © 2025 JericoFX** - Respecting GPL-3.0 license terms

---

## 🔗 Related Projects

- [ox_lib](https://github.com/overextended/ox_lib) - Essential utility library
- [ox_core](https://github.com/communityox/ox_core) - Modern framework
- [ox_target](https://github.com/overextended/ox_target) - Interaction system

---

<div align="center">

**Made with ❤️ for the FiveM Community**

</div>
