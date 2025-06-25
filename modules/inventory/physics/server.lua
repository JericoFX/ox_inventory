-- modules/inventory/physics.lua
local InventoryPhysics = {}
local TriggerEventHooks = require 'modules.hooks.server'

local function getItems()
    if not Items then
        local success, module = pcall(require, 'modules.items.server')
        Items = success and module or nil
    end
    return Items
end

local function getInventory()
    if not Inventory then
        Inventory = require 'modules.inventory.server'
    end
    return Inventory
end

function InventoryPhysics.CalculateEffects(playerId)
    if not server.enablePhysicsSystem then return nil end

    local inv = getInventory()(playerId)
    if not inv then return nil end

    local config = server.physicsConfig
    local weightRatio = inv.weight / inv.maxWeight
    local effects = {
        movement_speed = 1.0,
        stamina_drain = 1.0,
        weapon_sway = 1.0
    }

    if weightRatio > config.weightThresholds.heavy then
        effects.movement_speed = math.max(0.6, 1.0 - config.movementPenalty)
        effects.stamina_drain = 1.0 + config.staminaPenalty
    elseif weightRatio > config.weightThresholds.medium then
        effects.movement_speed = math.max(0.8, 1.0 - (config.movementPenalty * 0.6))
        effects.stamina_drain = 1.0 + (config.staminaPenalty * 0.6)
    elseif weightRatio > config.weightThresholds.light then
        effects.stamina_drain = 1.0 + (config.staminaPenalty * 0.3)
    end

    local ItemsModule = getItems()
    if ItemsModule then
        local weaponWeight = 0
        for _, item in pairs(inv.items) do
            if item.name:find('WEAPON_') then
                local itemData = ItemsModule(item.name)
                if itemData and itemData.weight > 2000 then
                    weaponWeight = weaponWeight + itemData.weight
                end
            end
        end

        if weaponWeight > 0 then
            effects.weapon_sway = 1.0 + (weaponWeight / 10000 * config.weaponPenalty)
        end
    end

    return effects
end

function InventoryPhysics.ApplyEffects(playerId, effects)
    if not effects then return end

    local player = Player(playerId)
    if not player or not player.state then return end

    -- Movement speed
    if effects.movement_speed and effects.movement_speed < 1.0 then
        player.state:set('inv_movement_speed', effects.movement_speed, true)
    else
        player.state.inv_movement_speed = nil
    end

    -- Stamina drain
    if effects.stamina_drain and effects.stamina_drain > 1.0 then
        player.state:set('inv_stamina_drain', effects.stamina_drain, true)
    else
        player.state.inv_stamina_drain = nil
    end

    -- Weapon sway
    if effects.weapon_sway and effects.weapon_sway > 1.0 then
        player.state:set('inv_weapon_sway', effects.weapon_sway, true)
    else
        player.state.inv_weapon_sway = nil
    end
end

local function onWeightChange(payload)
    if not server.enablePhysicsSystem then return end

    local playerId = payload.source
    if not playerId then return end

    local fromInventory = payload.fromInventory
    local toInventory = payload.toInventory

    if fromInventory and fromInventory == playerId then
        local effects = InventoryPhysics.CalculateEffects(playerId)
        if effects then
            InventoryPhysics.ApplyEffects(playerId, effects)
        end
    end

    if toInventory and toInventory == playerId and toInventory ~= fromInventory then
        local effects = InventoryPhysics.CalculateEffects(playerId)
        if effects then
            InventoryPhysics.ApplyEffects(playerId, effects)
        end
    end
end

exports.ox_inventory:registerHook('swapItems', onWeightChange)

exports('CalculateEffects', InventoryPhysics.CalculateEffects)
exports('ApplyEffects', InventoryPhysics.ApplyEffects)

return InventoryPhysics
