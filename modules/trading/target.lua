if not lib.checkDependency('ox_target', '1.0.0') then
    return warn('ox_target is required for the trading system')
end

local Trading = require 'modules.trading.client'

-- Añadir opción de trading a jugadores
exports.ox_target:addGlobalPlayer({
    {
        name = 'ox_inventory:trade',
        icon = 'fas fa-exchange-alt',
        label = 'Intercambiar Items',
        canInteract = function(entity, distance, coords, name)
            -- Verificar que sea un jugador válido y esté cerca
            if distance > 3.0 then return false end
            
            local playerId = NetworkGetPlayerIndexFromPed(entity)
            if playerId == -1 then return false end
            
            local targetId = GetPlayerServerId(playerId)
            if targetId == GetPlayerServerId(PlayerId()) then return false end
            
            return true
        end,
        onSelect = function(data)
            if data.entity then
                local playerId = NetworkGetPlayerIndexFromPed(data.entity)
                if playerId ~= -1 then
                    local targetId = GetPlayerServerId(playerId)
                    
                    -- Verificar que el jugador objetivo esté cerca
                    local playerCoords = GetEntityCoords(PlayerPedId())
                    local targetCoords = GetEntityCoords(data.entity)
                    
                    if #(playerCoords - targetCoords) <= 3.0 then
                        Trading.startTrade(targetId)
                    else
                        lib.notify({
                            id = 'player_too_far',
                            type = 'error',
                            description = 'El jugador está muy lejos'
                        })
                    end
                end
            end
        end
    }
})

-- Función para crear un menú contextual de trading (opcional)
local function createTradeMenu(targetId, targetName)
    local options = {
        {
            title = 'Intercambiar con ' .. targetName,
            description = 'Iniciar intercambio de items',
            icon = 'exchange-alt',
            onSelect = function()
                Trading.startTrade(targetId)
            end
        },
        {
            title = 'Cancelar',
            description = 'Cerrar menú',
            icon = 'times'
        }
    }
    
    lib.registerContext({
        id = 'trade_menu',
        title = 'Opciones de Intercambio',
        options = options
    })
    
    lib.showContext('trade_menu')
end

-- Comando alternativo para testing
RegisterCommand('trademenu', function()
    local players = GetActivePlayers()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    local nearbyPlayers = {}
    
    for _, player in ipairs(players) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(playerCoords - targetCoords)
            
            if distance <= 5.0 then
                table.insert(nearbyPlayers, {
                    id = GetPlayerServerId(player),
                    name = GetPlayerName(player),
                    distance = distance
                })
            end
        end
    end
    
    if #nearbyPlayers == 0 then
        return lib.notify({
            id = 'no_players_nearby',
            type = 'error',
            description = 'No hay jugadores cerca'
        })
    end
    
    local options = {}
    
    for _, player in ipairs(nearbyPlayers) do
        table.insert(options, {
            title = player.name,
            description = ('Distancia: %.1fm'):format(player.distance),
            icon = 'user',
            onSelect = function()
                Trading.startTrade(player.id)
            end
        })
    end
    
    table.insert(options, {
        title = 'Cancelar',
        description = 'Cerrar menú',
        icon = 'times'
    })
    
    lib.registerContext({
        id = 'nearby_players_menu',
        title = 'Jugadores Cercanos',
        options = options
    })
    
    lib.showContext('nearby_players_menu')
end)

return {
    createTradeMenu = createTradeMenu
}
