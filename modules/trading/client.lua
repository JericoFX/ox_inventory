local Utils = require 'modules.utils.client'

local currentTrade = nil

-- Función para iniciar un trade con otro jugador
local function startTrade(targetId)
    if currentTrade then
        return lib.notify({
            id = 'trade_in_progress',
            type = 'error',
            description = locale('trade_in_progress')
        })
    end
    
    local success, message = lib.callback.await('ox_inventory:initTrade', false, targetId)
    
    if not success then
        return lib.notify({
            id = 'trade_failed',
            type = 'error',
            description = locale(message)
        })
    end
    
    lib.notify({
        id = 'trade_started',
        type = 'success',
        description = locale(message)
    })
end


local function confirmTrade()
    if not currentTrade then
        return lib.notify({
            id = 'no_trade',
            type = 'error',
            description = locale('trade_no_active')
        })
    end
    
    local success, message = lib.callback.await('ox_inventory:confirmTrade', false, currentTrade.targetId)
    
    if not success then
        return lib.notify({
            id = 'confirm_failed',
            type = 'error',
            description = locale(message)
        })
    end
    
    lib.notify({
        id = 'trade_confirmed',
        type = 'success',
        description = locale(message)
    })
end

local function cancelTrade()
    if not currentTrade then
        return lib.notify({
            id = 'no_trade',
            type = 'error',
            description = locale('trade_no_active')
        })
    end
    
    local success, message = lib.callback.await('ox_inventory:cancelTrade', false, currentTrade.targetId)
    
    if not success then
        return lib.notify({
            id = 'cancel_failed',
            type = 'error',
            description = locale(message)
        })
    end
    
    currentTrade = nil
    
    lib.notify({
        id = 'trade_cancelled',
        type = 'info',
        description = locale(message)
    })
end

-- Eventos del servidor
RegisterNetEvent('ox_inventory:initTrade', function(data)
    currentTrade = {
        targetId = data.targetPlayer.id,
        targetName = data.targetPlayer.name,
        active = true
    }
    
    -- Enviar datos al NUI
    SendNUIMessage({
        action = 'initTrade',
        data = data
    })
end)

RegisterNetEvent('ox_inventory:updateTrade', function(data)
    -- Actualizar estado del trade en el NUI
    SendNUIMessage({
        action = 'updateTrade',
        data = data
    })
end)

RegisterNetEvent('ox_inventory:updateTradeItems', function(data)
    -- Actualizar items del trade en el NUI
    SendNUIMessage({
        action = 'updateTradeItems',
        data = data
    })
end)

RegisterNetEvent('ox_inventory:completeTrade', function()
    currentTrade = nil
    
    lib.notify({
        id = 'trade_completed',
        type = 'success',
        description = locale('trade_completed')
    })
    
    SendNUIMessage({
        action = 'completeTrade'
    })
end)

RegisterNetEvent('ox_inventory:cancelTrade', function()
    currentTrade = nil
    
    lib.notify({
        id = 'trade_cancelled',
        type = 'info',
        description = locale('trade_cancelled')
    })
    
    SendNUIMessage({
        action = 'cancelTrade'
    })
end)

-- Callbacks del NUI
RegisterNUICallback('confirmTrade', function(data, cb)
    confirmTrade()
    cb('ok')
end)

RegisterNUICallback('cancelTrade', function(data, cb)
    cancelTrade()
    cb('ok')
end)

RegisterNUICallback('updateTradeItems', function(data, cb)
    if not currentTrade then
        return cb('error')
    end
    
    lib.callback.await('ox_inventory:updateTradeItems', false, {
        targetPlayerId = currentTrade.targetId,
        playerItems = data.playerItems,
        targetItems = data.targetItems
    })
    
    cb('ok')
end)

-- Función para obtener el jugador más cercano
local function getClosestPlayer()
    local players = GetActivePlayers()
    local closestDistance = -1
    local closestPlayer = -1
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if closestDistance == -1 or closestDistance > distance then
                closestDistance = distance
                closestPlayer = player
            end
        end
    end
    
    return closestPlayer, closestDistance
end

-- Comando para iniciar trade (temporal, se reemplazará con ox_target)
RegisterCommand('trade', function()
    local closestPlayer, distance = getClosestPlayer()
    
    if closestPlayer == -1 or distance > 3.0 then
        return lib.notify({
            id = 'no_player_nearby',
            type = 'error',
            description = locale('trade_no_player')
        })
    end
    
    local targetId = GetPlayerServerId(closestPlayer)
    startTrade(targetId)
end)

-- Exportar funciones para uso con ox_target
exports('startTrade', function(data)
    if data.entity then
        local playerId = NetworkGetPlayerIndexFromPed(data.entity)
        if playerId ~= -1 then
            local targetId = GetPlayerServerId(playerId)
            startTrade(targetId)
        end
    end
end)

return {
    startTrade = startTrade,
    confirmTrade = confirmTrade,
    cancelTrade = cancelTrade
}
