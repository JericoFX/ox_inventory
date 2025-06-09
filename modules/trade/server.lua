if not lib then return end

local Trade = {}
local ActiveTrades = {}
local TradeInvitations = {}

local TRADE_STATE = {
    PENDING = 'pending',
    ACCEPTED = 'accepted',
    CONFIRMED = 'confirmed',
    CANCELLED = 'cancelled',
    COMPLETED = 'completed'
}

local TRADE_TIMEOUT = 300000

---@class TradeSession
---@field id string
---@field player1 number
---@field player2 number
---@field state string
---@field player1_items table<number, SlotWithItem>
---@field player2_items table<number, SlotWithItem>
---@field player1_confirmed boolean
---@field player2_confirmed boolean
---@field created_at number
---@field last_activity number

local function generateTradeId()
    return ('trade_%s_%s'):format(os.time(), math.random(1000, 9999))
end

local function getPlayerDistance(source1, source2)
    local ped1 = GetPlayerPed(source1)
    local ped2 = GetPlayerPed(source2)
    local coords1 = GetEntityCoords(ped1)
    local coords2 = GetEntityCoords(ped2)
    return #(coords1 - coords2)
end

local function validateTradePlayer(source)
    local player = Player(source)
    if not player then return false, 'player_not_found' end

    local ped = GetPlayerPed(source)
    if not ped then return false, 'invalid_ped' end

    if IsEntityDead(ped) then return false, 'player_dead' end

    local playerState = player.state
    if playerState.invBusy then return false, 'player_busy' end
    if playerState.cuffed then return false, 'player_cuffed' end

    return true
end

local function cleanupTrade(tradeId, reason)
    local trade = ActiveTrades[tradeId]
    if not trade then return end

    TriggerClientEvent('ox_inventory:tradeCancelled', trade.player1, reason or 'trade_cancelled')
    TriggerClientEvent('ox_inventory:tradeCancelled', trade.player2, reason or 'trade_cancelled')

    ActiveTrades[tradeId] = nil

    lib.logger(trade.player1, 'tradeCancelled', {
        tradeId = tradeId,
        player2 = trade.player2,
        reason = reason
    })
end

local function validateTradeItems(tradeSession)
    local inv1 = Inventory(tradeSession.player1)
    local inv2 = Inventory(tradeSession.player2)

    if not inv1 or not inv2 then return false end

    for slot, item in pairs(tradeSession.player1_items) do
        local currentItem = inv1.items[slot]
        if not currentItem or currentItem.count < item.count or currentItem.name ~= item.name then
            return false
        end
    end

    for slot, item in pairs(tradeSession.player2_items) do
        local currentItem = inv2.items[slot]
        if not currentItem or currentItem.count < item.count or currentItem.name ~= item.name then
            return false
        end
    end

    return true
end

local function executeTradeTransaction(tradeSession)
    local inv1 = Inventory(tradeSession.player1)
    local inv2 = Inventory(tradeSession.player2)

    if not inv1 or not inv2 then return false end

    local player1Items = {}
    local player2Items = {}

    for slot, item in pairs(tradeSession.player1_items) do
        local success, removedItem = Inventory.RemoveItem(inv1, item.name, item.count, item.metadata, slot)
        if not success then return false end
        table.insert(player1Items, removedItem)
    end

    for slot, item in pairs(tradeSession.player2_items) do
        local success, removedItem = Inventory.RemoveItem(inv2, item.name, item.count, item.metadata, slot)
        if not success then
            for _, restoredItem in pairs(player1Items) do
                Inventory.AddItem(inv1, restoredItem.name, restoredItem.count, restoredItem.metadata)
            end
            return false
        end
        table.insert(player2Items, removedItem)
    end

    for _, item in pairs(player1Items) do
        local success = Inventory.AddItem(inv2, item.name, item.count, item.metadata)
        if not success then
            Inventory.AddItem(inv1, item.name, item.count, item.metadata)
        end
    end

    for _, item in pairs(player2Items) do
        local success = Inventory.AddItem(inv1, item.name, item.count, item.metadata)
        if not success then
            Inventory.AddItem(inv2, item.name, item.count, item.metadata)
        end
    end

    return true
end

function Trade.SendInvitation(source, targetId)
    local valid, error = validateTradePlayer(source)
    if not valid then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_error_' .. error)
        })
    end

    local targetValid, targetError = validateTradePlayer(targetId)
    if not targetValid then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_target_error_' .. targetError)
        })
    end

    local distance = getPlayerDistance(source, targetId)
    if distance > 3.0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_too_far')
        })
    end

    if TradeInvitations[targetId] then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_player_busy')
        })
    end

    TradeInvitations[targetId] = {
        from = source,
        timestamp = os.time()
    }

    local sourceName = GetPlayerName(source)
    TriggerClientEvent('ox_inventory:tradeInvitation', targetId, source, sourceName)
    TriggerClientEvent('ox_lib:notify', source, {
        type = 'inform',
        description = locale('trade_invitation_sent')
    })

    SetTimeout(30000, function()
        if TradeInvitations[targetId] and TradeInvitations[targetId].from == source then
            TradeInvitations[targetId] = nil
            TriggerClientEvent('ox_lib:notify', source, {
                type = 'error',
                description = locale('trade_invitation_expired')
            })
        end
    end)
end

function Trade.AcceptInvitation(source)
    local invitation = TradeInvitations[source]
    if not invitation then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_no_invitation')
        })
    end

    local fromPlayer = invitation.from
    TradeInvitations[source] = nil

    local valid1, error1 = validateTradePlayer(source)
    local valid2, error2 = validateTradePlayer(fromPlayer)

    if not valid1 or not valid2 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_validation_failed')
        })
    end

    local distance = getPlayerDistance(source, fromPlayer)
    if distance > 3.0 then
        return TriggerClientEvent('ox_lib:notify', source, {
            type = 'error',
            description = locale('trade_too_far')
        })
    end

    local tradeId = generateTradeId()
    local tradeSession = {
        id = tradeId,
        player1 = fromPlayer,
        player2 = source,
        state = TRADE_STATE.ACCEPTED,
        player1_items = {},
        player2_items = {},
        player1_confirmed = false,
        player2_confirmed = false,
        created_at = os.time(),
        last_activity = os.time()
    }

    ActiveTrades[tradeId] = tradeSession

    TriggerClientEvent('ox_inventory:tradeStarted', fromPlayer, tradeId, source)
    TriggerClientEvent('ox_inventory:tradeStarted', source, tradeId, fromPlayer)

    lib.logger(fromPlayer, 'tradeStarted', {
        tradeId = tradeId,
        player2 = source
    })

    SetTimeout(TRADE_TIMEOUT, function()
        if ActiveTrades[tradeId] then
            cleanupTrade(tradeId, 'trade_timeout')
        end
    end)
end

function Trade.DeclineInvitation(source)
    local invitation = TradeInvitations[source]
    if not invitation then return end

    TradeInvitations[source] = nil
    TriggerClientEvent('ox_lib:notify', invitation.from, {
        type = 'error',
        description = locale('trade_invitation_declined')
    })
end

function Trade.AddItem(source, tradeId, slot, count)
    local trade = ActiveTrades[tradeId]
    if not trade then return false end

    if trade.state ~= TRADE_STATE.ACCEPTED then return false end

    local playerItems = source == trade.player1 and trade.player1_items or trade.player2_items
    local inventory = Inventory(source)
    local item = inventory.items[slot]

    if not item or item.count < count then return false end

    playerItems[slot] = {
        name = item.name,
        count = count,
        metadata = item.metadata,
        slot = slot
    }

    trade.last_activity = os.time()
    trade.player1_confirmed = false
    trade.player2_confirmed = false

    TriggerClientEvent('ox_inventory:tradeItemAdded', trade.player1, source, slot, count)
    TriggerClientEvent('ox_inventory:tradeItemAdded', trade.player2, source, slot, count)

    return true
end

function Trade.RemoveItem(source, tradeId, slot)
    local trade = ActiveTrades[tradeId]
    if not trade then return false end

    if trade.state ~= TRADE_STATE.ACCEPTED then return false end

    local playerItems = source == trade.player1 and trade.player1_items or trade.player2_items
    playerItems[slot] = nil

    trade.last_activity = os.time()
    trade.player1_confirmed = false
    trade.player2_confirmed = false

    TriggerClientEvent('ox_inventory:tradeItemRemoved', trade.player1, source, slot)
    TriggerClientEvent('ox_inventory:tradeItemRemoved', trade.player2, source, slot)

    return true
end

function Trade.ConfirmTrade(source, tradeId)
    local trade = ActiveTrades[tradeId]
    if not trade then return false end

    if trade.state ~= TRADE_STATE.ACCEPTED then return false end

    if source == trade.player1 then
        trade.player1_confirmed = true
    elseif source == trade.player2 then
        trade.player2_confirmed = true
    else
        return false
    end

    trade.last_activity = os.time()

    TriggerClientEvent('ox_inventory:tradeConfirmation', trade.player1, source, true)
    TriggerClientEvent('ox_inventory:tradeConfirmation', trade.player2, source, true)

    if trade.player1_confirmed and trade.player2_confirmed then
        if validateTradeItems(trade) then
            local success = executeTradeTransaction(trade)
            if success then
                trade.state = TRADE_STATE.COMPLETED
                TriggerClientEvent('ox_inventory:tradeCompleted', trade.player1)
                TriggerClientEvent('ox_inventory:tradeCompleted', trade.player2)

                lib.logger(trade.player1, 'tradeCompleted', {
                    tradeId = tradeId,
                    player2 = trade.player2,
                    player1_items = trade.player1_items,
                    player2_items = trade.player2_items
                })

                ActiveTrades[tradeId] = nil
            else
                cleanupTrade(tradeId, 'trade_execution_failed')
            end
        else
            cleanupTrade(tradeId, 'trade_validation_failed')
        end
    end

    return true
end

function Trade.CancelTrade(source, tradeId)
    local trade = ActiveTrades[tradeId]
    if not trade then return false end

    if source ~= trade.player1 and source ~= trade.player2 then return false end

    cleanupTrade(tradeId, 'trade_cancelled_by_player')
    return true
end

lib.callback.register('ox_inventory:sendTradeInvitation', function(source, targetId)
    return Trade.SendInvitation(source, targetId)
end)

lib.callback.register('ox_inventory:acceptTradeInvitation', function(source)
    return Trade.AcceptInvitation(source)
end)

lib.callback.register('ox_inventory:declineTradeInvitation', function(source)
    return Trade.DeclineInvitation(source)
end)

lib.callback.register('ox_inventory:addTradeItem', function(source, tradeId, slot, count)
    return Trade.AddItem(source, tradeId, slot, count)
end)

lib.callback.register('ox_inventory:removeTradeItem', function(source, tradeId, slot)
    return Trade.RemoveItem(source, tradeId, slot)
end)

lib.callback.register('ox_inventory:confirmTrade', function(source, tradeId)
    return Trade.ConfirmTrade(source, tradeId)
end)

lib.callback.register('ox_inventory:cancelTrade', function(source, tradeId)
    return Trade.CancelTrade(source, tradeId)
end)

CreateThread(function()
    while true do
        Wait(60000)
        local currentTime = os.time()

        for tradeId, trade in pairs(ActiveTrades) do
            if currentTime - trade.last_activity > 300 then
                cleanupTrade(tradeId, 'trade_timeout')
            end
        end

        for playerId, invitation in pairs(TradeInvitations) do
            if currentTime - invitation.timestamp > 30 then
                TradeInvitations[playerId] = nil
            end
        end
    end
end)

return Trade
