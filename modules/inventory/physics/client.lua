local currentEffects = {
    movement_speed = 1.0,
    stamina_drain = 1.0,
    weapon_sway = 1.0
}

local function applyMovementEffect(speed)
    if not speed or speed >= 1.0 then
        SetPedMoveRateOverride(cache.ped, 1.0)
        return
    end
    
    SetPedMoveRateOverride(cache.ped, speed)
    currentEffects.movement_speed = speed
end

local function applyStaminaEffect(drain)
    if not drain then drain = 1.0 end
    currentEffects.stamina_drain = drain
end

local function applyWeaponEffect(sway)
    if not sway then sway = 1.0 end
    currentEffects.weapon_sway = sway
end

CreateThread(function()
    while true do
        Wait(100)
        
        if currentEffects.stamina_drain > 1.0 then
            local stamina = GetPlayerStamina(cache.playerId)
            local newStamina = stamina - (currentEffects.stamina_drain - 1.0)
            
            if newStamina < stamina then
                SetPlayerStamina(cache.playerId, math.max(0, newStamina))
            end
        end
        
        if currentEffects.weapon_sway > 1.0 then
            local weapon = GetSelectedPedWeapon(cache.ped)
            if weapon and weapon ~= `WEAPON_UNARMED` then
                SetPlayerWeaponDamageModifier(cache.playerId, 1.0 / currentEffects.weapon_sway)
            end
        end
    end
end)

RegisterNetEvent('ox_inventory:applyMovementEffect', applyMovementEffect)
RegisterNetEvent('ox_inventory:applyStaminaEffect', applyStaminaEffect)
RegisterNetEvent('ox_inventory:applyWeaponEffect', applyWeaponEffect)

exports('getCurrentEffects', function()
    return currentEffects
end) 