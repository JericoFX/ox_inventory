if not lib then return end

local Inventory = require 'modules.inventory.server'
local Items = require 'modules.items.server'

local Trades = {}
local PlayerTrades = {}
local tradeTimeout = GetConvarInt('inventory:trade_timeout', 30)

local function getPlayerPedCoords(playerId)
    local ped = GetPlayerPed(playerId)
    if not ped or ped == 0 then return end
    return ped, GetEntityCoords(ped)
end

local function isTradeParticipant(trade, playerId)
    return trade.players[1] == playerId or trade.players[2] == playerId
end

local function getPartnerId(trade, playerId)
    return trade.players[1] == playerId and trade.players[2] or trade.players[1]
end

local function buildTradePayload(trade, viewerId)
    local partnerId = getPartnerId(trade, viewerId)

    local function offersToArray(offers)
        local list = {}
        for _, offer in pairs(offers or {}) do
            list[#list + 1] = offer
        end
        table.sort(list, function(a, b) return a.slot < b.slot end)
        return list
    end

    return {
        id = trade.id,
        partner = {
            id = partnerId,
            name = GetPlayerName(partnerId) or 'Unknown'
        },
        offers = {
            self = offersToArray(trade.offers[viewerId]),
            partner = offersToArray(trade.offers[partnerId])
        },
        confirmations = {
            self = trade.confirmations[viewerId] or false,
            partner = trade.confirmations[partnerId] or false
        },
        expiresAt = trade.expiresAt * 1000
    }
end

local function resetConfirmations(trade)
    trade.confirmations[trade.players[1]] = false
    trade.confirmations[trade.players[2]] = false
end

local function unlockTradeSlots(trade)
    for _, playerId in ipairs(trade.players) do
        local offers = trade.offers[playerId]
        if offers then
            for _, offer in pairs(offers) do
                Inventory.UnlockSlot(playerId, offer.slot, trade.id)
            end
        end
    end
end

local function clearTrade(tradeId)
    local trade = Trades[tradeId]
    if not trade then return end
    for _, playerId in ipairs(trade.players) do
        if PlayerTrades[playerId] == tradeId then
            PlayerTrades[playerId] = nil
        end
    end
    Trades[tradeId] = nil
end

local function closeTrade(trade, reason)
    unlockTradeSlots(trade)
    for _, playerId in ipairs(trade.players) do
        TriggerClientEvent('ox_inventory:tradeClosed', playerId, { id = trade.id, reason = reason })
    end
    clearTrade(trade.id)
end

local function sendTradeState(trade)
    for _, playerId in ipairs(trade.players) do
        TriggerClientEvent('ox_inventory:tradeState', playerId, buildTradePayload(trade, playerId))
    end
end

local function validatePlayersDistance(source, target)
    local sourcePed, sourceCoords = getPlayerPedCoords(source)
    local targetPed, targetCoords = getPlayerPedCoords(target)
    if not sourcePed or not targetPed then return false end
    return #(sourceCoords - targetCoords) <= 3.0
end

local function getOfferWeight(offer)
    local item = Items(offer.name)
    if not item then return 0 end
    return Inventory.SlotWeight(item, {
        name = offer.name,
        count = offer.count,
        metadata = offer.metadata
    })
end

local function cloneSlot(slot)
    return {
        name = slot.name,
        count = slot.count,
        metadata = slot.metadata or {},
        weight = slot.weight
    }
end

local function countSlots(slots)
    local total = 0
    for _ in pairs(slots) do
        total += 1
    end
    return total
end

local function canReceiveItems(inv, outgoingOffers, incomingOffers)
    local slotMap = {}
    for slotId, slotData in pairs(inv.items) do
        slotMap[slotId] = cloneSlot(slotData)
    end

    for _, offer in pairs(outgoingOffers or {}) do
        local slotData = slotMap[offer.slot]
        if not slotData or slotData.name ~= offer.name or not table.matches(slotData.metadata or {}, offer.metadata or {}) then
            return false
        end
        slotData.count -= offer.count
        if slotData.count <= 0 then
            slotMap[offer.slot] = nil
        end
    end

    local emptySlots = inv.slots - countSlots(slotMap)

    local tempIndex = 0

    for _, offer in ipairs(incomingOffers or {}) do
        local item = Items(offer.name)
        if not item then return false end
        if item.stack then
            local stacked = false
            for _, slotData in pairs(slotMap) do
                if slotData.name == offer.name and table.matches(slotData.metadata or {}, offer.metadata or {}) then
                    slotData.count += offer.count
                    stacked = true
                    break
                end
            end
            if not stacked then
                if emptySlots < 1 then return false end
                emptySlots -= 1
                tempIndex += 1
                slotMap[('temp_%s'):format(tempIndex)] = cloneSlot({
                    name = offer.name,
                    count = offer.count,
                    metadata = offer.metadata,
                    weight = offer.weight
                })
            end
        else
            if offer.count > emptySlots then return false end
            emptySlots -= offer.count
        end
    end

    return true
end

local function canCarryTradeItems(inv, outgoingOffers, incomingOffers)
    local outgoingWeight = 0
    local incomingWeight = 0

    for _, offer in pairs(outgoingOffers or {}) do
        outgoingWeight += getOfferWeight(offer)
    end

    for _, offer in ipairs(incomingOffers or {}) do
        incomingWeight += getOfferWeight(offer)
    end

    local newWeight = inv.weight - outgoingWeight + incomingWeight
    if newWeight > inv.maxWeight then return false end

    return canReceiveItems(inv, outgoingOffers, incomingOffers)
end

local function normalizeOfferList(offers)
    local list = {}
    for _, offer in pairs(offers or {}) do
        list[#list + 1] = offer
    end
    return list
end

local function finalizeTrade(trade)
    local firstId = trade.players[1]
    local secondId = trade.players[2]
    local firstInv = Inventory(firstId)
    local secondInv = Inventory(secondId)

    if not firstInv or not secondInv then
        return closeTrade(trade, 'cancelled')
    end

    if not validatePlayersDistance(firstId, secondId) then
        return closeTrade(trade, 'cancelled')
    end

    local firstOffers = trade.offers[firstId] or {}
    local secondOffers = trade.offers[secondId] or {}
    local firstIncoming = normalizeOfferList(secondOffers)
    local secondIncoming = normalizeOfferList(firstOffers)

    for _, offer in pairs(firstOffers) do
        local slotData = firstInv.items[offer.slot]
        if not slotData or slotData.name ~= offer.name or not table.matches(slotData.metadata or {}, offer.metadata or {}) or slotData.count < offer.count then
            return closeTrade(trade, 'cannot_perform')
        end
    end

    for _, offer in pairs(secondOffers) do
        local slotData = secondInv.items[offer.slot]
        if not slotData or slotData.name ~= offer.name or not table.matches(slotData.metadata or {}, offer.metadata or {}) or slotData.count < offer.count then
            return closeTrade(trade, 'cannot_perform')
        end
    end

    if not canCarryTradeItems(firstInv, firstOffers, firstIncoming) or not canCarryTradeItems(secondInv, secondOffers, secondIncoming) then
        return closeTrade(trade, 'cannot_carry')
    end

    local removed = {
        [firstId] = {},
        [secondId] = {}
    }

    for _, offer in pairs(firstOffers) do
        if Inventory.RemoveItem(firstInv, offer.name, offer.count, offer.metadata, offer.slot, nil, true) then
            removed[firstId][#removed[firstId] + 1] = offer
        else
            closeTrade(trade, 'cannot_perform')
            return
        end
    end

    for _, offer in pairs(secondOffers) do
        if Inventory.RemoveItem(secondInv, offer.name, offer.count, offer.metadata, offer.slot, nil, true) then
            removed[secondId][#removed[secondId] + 1] = offer
        else
            for _, rollback in ipairs(removed[firstId]) do
                Inventory.AddItem(firstInv, rollback.name, rollback.count, rollback.metadata, rollback.slot)
            end
            closeTrade(trade, 'cannot_perform')
            return
        end
    end

    local completed = true

    for _, offer in ipairs(firstIncoming) do
        if not Inventory.AddItem(firstInv, offer.name, offer.count, offer.metadata) then
            completed = false
            break
        end
    end

    if completed then
        for _, offer in ipairs(secondIncoming) do
            if not Inventory.AddItem(secondInv, offer.name, offer.count, offer.metadata) then
                completed = false
                break
            end
        end
    end

    if not completed then
        for _, offer in ipairs(firstIncoming) do
            Inventory.RemoveItem(firstInv, offer.name, offer.count, offer.metadata)
        end
        for _, offer in ipairs(secondIncoming) do
            Inventory.RemoveItem(secondInv, offer.name, offer.count, offer.metadata)
        end
        for _, rollback in ipairs(removed[firstId]) do
            Inventory.AddItem(firstInv, rollback.name, rollback.count, rollback.metadata, rollback.slot)
        end
        for _, rollback in ipairs(removed[secondId]) do
            Inventory.AddItem(secondInv, rollback.name, rollback.count, rollback.metadata, rollback.slot)
        end
        closeTrade(trade, 'cannot_perform')
        return
    end

    if server.loglevel > 0 then
        lib.logger(firstInv.owner, 'trade', ('"%s" traded with "%s"'):format(firstInv.label, secondInv.label))
    end

    closeTrade(trade, 'completed')
end

local function createTrade(source, target)
    if not validatePlayersDistance(source, target) then
        return false, 'nobody_nearby'
    end

    if PlayerTrades[source] or PlayerTrades[target] then
        return false, 'cannot_perform'
    end

    local tradeId = ('trade-%s-%s'):format(os.time(), math.random(1000, 9999))
    local expiresAt = os.time() + tradeTimeout

    Trades[tradeId] = {
        id = tradeId,
        players = { source, target },
        offers = {
            [source] = {},
            [target] = {}
        },
        confirmations = {
            [source] = false,
            [target] = false
        },
        expiresAt = expiresAt,
        state = 'pending'
    }

    PlayerTrades[source] = tradeId
    PlayerTrades[target] = tradeId

    TriggerClientEvent('ox_inventory:tradeInvite', target, {
        id = tradeId,
        from = { id = source, name = GetPlayerName(source) or 'Unknown' },
        expiresAt = expiresAt * 1000
    })

    return true
end

local function respondTrade(source, tradeId, accepted)
    local trade = Trades[tradeId]
    if not trade or not isTradeParticipant(trade, source) then return false end
    if trade.state ~= 'pending' then return false end

    if not accepted then
        closeTrade(trade, 'declined')
        return true
    end

    local partnerId = getPartnerId(trade, source)

    if not validatePlayersDistance(source, partnerId) then
        closeTrade(trade, 'nobody_nearby')
        return false, 'nobody_nearby'
    end

    trade.state = 'active'
    resetConfirmations(trade)
    sendTradeState(trade)
    return true
end

local function updateOffer(source, tradeId, slot, count)
    local trade = Trades[tradeId]
    if not trade or trade.state ~= 'active' or not isTradeParticipant(trade, source) then return false end

    local inv = Inventory(source)
    if not inv then return false end

    local slotData = inv.items[slot]
    if not slotData then return false, 'cannot_perform' end

    if Inventory.IsSlotLocked(inv, slot, tradeId) then
        return false, 'cannot_perform'
    end

    count = tonumber(count) or slotData.count
    if count <= 0 then count = slotData.count end
    if count > slotData.count then count = slotData.count end

    if not Inventory.LockSlot(inv, slot, tradeId) then
        return false, 'cannot_perform'
    end

    trade.offers[source][slot] = {
        slot = slot,
        name = slotData.name,
        count = count,
        metadata = slotData.metadata or {},
        weight = slotData.weight
    }

    resetConfirmations(trade)
    sendTradeState(trade)
    return true
end

local function removeOffer(source, tradeId, slot)
    local trade = Trades[tradeId]
    if not trade or trade.state ~= 'active' or not isTradeParticipant(trade, source) then return false end

    if trade.offers[source][slot] then
        trade.offers[source][slot] = nil
        Inventory.UnlockSlot(source, slot, tradeId)
        resetConfirmations(trade)
        sendTradeState(trade)
    end

    return true
end

local function confirmTrade(source, tradeId)
    local trade = Trades[tradeId]
    if not trade or trade.state ~= 'active' or not isTradeParticipant(trade, source) then return false end

    trade.confirmations[source] = true
    sendTradeState(trade)

    if trade.confirmations[trade.players[1]] and trade.confirmations[trade.players[2]] then
        finalizeTrade(trade)
    end

    return true
end

local function cancelTrade(source, tradeId)
    local trade = Trades[tradeId]
    if not trade or not isTradeParticipant(trade, source) then return false end
    closeTrade(trade, 'cancelled')
    return true
end

lib.callback.register('ox_inventory:tradeRequest', function(source, targetId)
    if type(targetId) ~= 'number' then return false, 'nobody_nearby' end
    if source == targetId then return false, 'cannot_perform' end

    local targetPed = GetPlayerPed(targetId)
    if not targetPed or targetPed == 0 then return false, 'nobody_nearby' end

    return createTrade(source, targetId)
end)

lib.callback.register('ox_inventory:tradeRespond', function(source, tradeId, accepted)
    if type(tradeId) ~= 'string' then return false end
    return respondTrade(source, tradeId, accepted)
end)

lib.callback.register('ox_inventory:tradeOfferItem', function(source, tradeId, slot, count)
    if type(tradeId) ~= 'string' or type(slot) ~= 'number' then return false end
    return updateOffer(source, tradeId, slot, count)
end)

lib.callback.register('ox_inventory:tradeRemoveItem', function(source, tradeId, slot)
    if type(tradeId) ~= 'string' or type(slot) ~= 'number' then return false end
    return removeOffer(source, tradeId, slot)
end)

lib.callback.register('ox_inventory:tradeConfirm', function(source, tradeId)
    if type(tradeId) ~= 'string' then return false end
    return confirmTrade(source, tradeId)
end)

lib.callback.register('ox_inventory:tradeCancel', function(source, tradeId)
    if type(tradeId) ~= 'string' then return false end
    return cancelTrade(source, tradeId)
end)

exports('startTrade', createTrade)
exports('cancelTrade', cancelTrade)

AddEventHandler('playerDropped', function()
    local tradeId = PlayerTrades[source]
    if not tradeId then return end
    local trade = Trades[tradeId]
    if trade then
        closeTrade(trade, 'cancelled')
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        local now = os.time()
        for tradeId, trade in pairs(Trades) do
            if trade.expiresAt <= now then
                closeTrade(trade, 'expired')
            end
        end
    end
end)
