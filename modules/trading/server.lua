local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local tradingData = {}

local function validateTradeItems(playerId, playerItems, targetItems)
    local playerInventory = Inventory(playerId)

    if not playerInventory then
        return false, 'inventory_lost_access'
    end

    for _, tradeItem in ipairs(playerItems) do
        local itemData = Inventory.GetSlot(playerInventory, tradeItem.slot)

        if not itemData or itemData.name ~= tradeItem.name then
            return false, 'item_not_found'
        end

        if itemData.count < (tradeItem.count or 1) then
            return false, 'item_not_enough'
        end
    end

    for _, tradeItem in ipairs(targetItems) do
        local itemName = tradeItem.name
        local itemCount = tradeItem.count or 1
        local itemMetadata = tradeItem.metadata

        if not Inventory.CanCarryItem(playerInventory, itemName, itemCount, itemMetadata) then
            return false, 'cannot_carry'
        end
    end

    local playerItemsWeight = 0
    for _, tradeItem in ipairs(playerItems) do
        local itemData = Inventory.GetSlot(playerInventory, tradeItem.slot)
        if itemData then
            playerItemsWeight = playerItemsWeight + (itemData.weight * (tradeItem.count or 1))
        end
    end

    local targetItemsWeight = 0
    for _, tradeItem in ipairs(targetItems) do
        local item = Items(tradeItem.name)
        if item then
            local weight = tradeItem.metadata and tradeItem.metadata.weight or item.weight
            targetItemsWeight = targetItemsWeight + (weight * (tradeItem.count or 1))
        end
    end

    local weightDifference = targetItemsWeight - playerItemsWeight

    if not Inventory.CanCarryWeight(playerInventory, weightDifference) then
        return false, 'cannot_carry'
    end

    return true, 'items_valid'
end
local function executeTrade(trade)
    local player1Inventory = Inventory(trade.player1.id)
    local player2Inventory = Inventory(trade.player2.id)

    if not player1Inventory or not player2Inventory then
        return false, 'inventory_lost_access'
    end

    local valid1, error1 = validateTradeItems(trade.player1.id, trade.player1.items, trade.player2.items)
    local valid2, error2 = validateTradeItems(trade.player2.id, trade.player2.items, trade.player1.items)

    if not valid1 then
        TriggerClientEvent('ox_inventory:cancelTrade', trade.player1.id)
        TriggerClientEvent('ox_inventory:cancelTrade', trade.player2.id)
        return false, error1
    end

    if not valid2 then
        TriggerClientEvent('ox_inventory:cancelTrade', trade.player1.id)
        TriggerClientEvent('ox_inventory:cancelTrade', trade.player2.id)
        return false, error2
    end

    for _, tradeItem in ipairs(trade.player1.items) do
        Inventory.RemoveItem(trade.player1.id, tradeItem.name, tradeItem.count or 1, tradeItem.metadata, tradeItem.slot)
    end

    for _, tradeItem in ipairs(trade.player2.items) do
        Inventory.RemoveItem(trade.player2.id, tradeItem.name, tradeItem.count or 1, tradeItem.metadata, tradeItem.slot)
    end

    for _, tradeItem in ipairs(trade.player2.items) do
        Inventory.AddItem(trade.player1.id, tradeItem.name, tradeItem.count or 1, tradeItem.metadata)
    end

    for _, tradeItem in ipairs(trade.player1.items) do
        Inventory.AddItem(trade.player2.id, tradeItem.name, tradeItem.count or 1, tradeItem.metadata)
    end

    local tradeId = ('%s-%s'):format(trade.player1.id, trade.player2.id)
    local altTradeId = ('%s-%s'):format(trade.player2.id, trade.player1.id)

    tradingData[tradeId] = nil
    tradingData[altTradeId] = nil

    TriggerClientEvent('ox_inventory:completeTrade', trade.player1.id)
    TriggerClientEvent('ox_inventory:completeTrade', trade.player2.id)

    return true, 'trade_completed'
end
local function initTrade(source, targetId)
    local playerInventory = Inventory(source)
    local targetInventory = Inventory(targetId)

    if not playerInventory or not targetInventory then
        return false, 'invalid_inventory'
    end

    local playerPed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(targetId)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)

    if #(playerCoords - targetCoords) > 3.0 then
        return false, 'trade_player_too_far'
    end

    local tradeId = ('%s-%s'):format(source, targetId)
    tradingData[tradeId] = {
        player1 = {
            id = source,
            name = GetPlayerName(source),
            items = {},
            confirmed = false
        },
        player2 = {
            id = targetId,
            name = GetPlayerName(targetId),
            items = {},
            confirmed = false
        },
        active = true
    }

    TriggerClientEvent('ox_inventory:initTrade', source, {
        targetPlayer = { id = targetId, name = GetPlayerName(targetId) },
        playerItems = {},
        targetItems = {}
    })

    TriggerClientEvent('ox_inventory:initTrade', targetId, {
        targetPlayer = { id = source, name = GetPlayerName(source) },
        playerItems = {},
        targetItems = {}
    })

    return true, 'trade_started'
end

local function confirmTrade(source, targetId)
    local tradeId = ('%s-%s'):format(source, targetId)
    local altTradeId = ('%s-%s'):format(targetId, source)

    local trade = tradingData[tradeId] or tradingData[altTradeId]

    if not trade or not trade.active then
        return false, 'trade_no_active'
    end

    if trade.player1.id == source then
        trade.player1.confirmed = true
    elseif trade.player2.id == source then
        trade.player2.confirmed = true
    end

    TriggerClientEvent('ox_inventory:updateTrade', trade.player1.id, {
        playerConfirmed = trade.player1.confirmed,
        targetConfirmed = trade.player2.confirmed
    })

    TriggerClientEvent('ox_inventory:updateTrade', trade.player2.id, {
        playerConfirmed = trade.player2.confirmed,
        targetConfirmed = trade.player1.confirmed
    })

    if trade.player1.confirmed and trade.player2.confirmed then
        return executeTrade(trade)
    end

    return true, 'trade_confirmed'
end




local function cancelTrade(source, targetId)
    local tradeId = ('%s-%s'):format(source, targetId)
    local altTradeId = ('%s-%s'):format(targetId, source)

    local trade = tradingData[tradeId] or tradingData[altTradeId]

    if not trade then
        return false, 'trade_no_active'
    end

    tradingData[tradeId] = nil
    tradingData[altTradeId] = nil

    TriggerClientEvent('ox_inventory:cancelTrade', trade.player1.id)
    TriggerClientEvent('ox_inventory:cancelTrade', trade.player2.id)

    return true, 'trade_cancelled'
end

local function updateTradeItems(source, targetId, playerItems, targetItems)
    local tradeId = ('%s-%s'):format(source, targetId)
    local altTradeId = ('%s-%s'):format(targetId, source)

    local trade = tradingData[tradeId] or tradingData[altTradeId]

    if not trade or not trade.active then
        return false, 'trade_no_active'
    end

    if trade.player1.id == source then
        trade.player1.items = playerItems or {}
        trade.player1.confirmed = false
    elseif trade.player2.id == source then
        trade.player2.items = playerItems or {}
        trade.player2.confirmed = false
    end

    if trade.player1.id == targetId then
        trade.player1.confirmed = false
    elseif trade.player2.id == targetId then
        trade.player2.confirmed = false
    end

    TriggerClientEvent('ox_inventory:updateTradeItems', trade.player1.id, {
        playerItems = trade.player1.items,
        targetItems = trade.player2.items
    })

    TriggerClientEvent('ox_inventory:updateTradeItems', trade.player2.id, {
        playerItems = trade.player2.items,
        targetItems = trade.player1.items
    })

    return true, 'trade_items_updated'
end

-- Callbacks para las acciones de trading
lib.callback.register('ox_inventory:initTrade', function(source, targetId)
    return initTrade(source, targetId)
end)

lib.callback.register('ox_inventory:confirmTrade', function(source, data)
    return confirmTrade(source, data.targetPlayerId)
end)

lib.callback.register('ox_inventory:cancelTrade', function(source, data)
    return cancelTrade(source, data.targetPlayerId)
end)

lib.callback.register('ox_inventory:updateTradeItems', function(source, data)
    return updateTradeItems(source, data.targetPlayerId, data.playerItems, data.targetItems)
end)

-- Limpiar datos cuando un jugador se desconecta
AddEventHandler('playerDropped', function(reason)
    local source = source

    for tradeId, trade in pairs(tradingData) do
        if trade.player1.id == source or trade.player2.id == source then
            local otherId = trade.player1.id == source and trade.player2.id or trade.player1.id
            cancelTrade(source, otherId)
            break
        end
    end
end)

return {
    initTrade = initTrade,
    confirmTrade = confirmTrade,
    cancelTrade = cancelTrade
}
