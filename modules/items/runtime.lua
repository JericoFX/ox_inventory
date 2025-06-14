-- Pequeño modulo para registrar items al vuelo, sin reiniciar el server, por algo los de ox no lo hicieron primero, parece muy facil, algo mal hay

local ItemList  = require 'modules.items.shared'        -- tabla con todos los items

local Runtime = {
    list   = {},
    owner  = {},
}

local RateLimiter = {
    window = 1000, -- ms
    limit  = 10,
    calls  = {},
}

local function normalise(def)
    if def.weight == nil then def.weight = 0 end
    if def.close  == nil then def.close  = true end
    if def.stack  == nil then def.stack  = true end
    return def
end

local function validate(name, def)
    if type(name) ~= 'string' or name == ''      then return false, 'invalid_name'   end
    if ItemList[name]                            then return false, 'already_exists' end
    if type(def) ~= 'table'                      then return false, 'invalid_def'    end
    if not (def.description or def.client and def.client.image) then return false, 'missing_fields' end
    --Algo mas carajo, siempre me olvido de algo!
    return true
end

-- Esto es para evitar que se registran items al vuelo.
local function allow(resource)
    local now = GetGameTimer()
    local data = RateLimiter.calls[resource]
    if not data then
        data = {}
        RateLimiter.calls[resource] = data
    end

    for i = #data, 1, -1 do
        if now - data[i] > RateLimiter.window then
            table.remove(data, i)
        end
    end

    if #data >= RateLimiter.limit then
        return false
    end

    data[#data + 1] = now
    return true
end

function Runtime.register(name, def)
    local owner = GetInvokingResource() or 'unknown'
    if not allow(owner) then return false, 'rate_limited' end

    local ok, err = validate(name, def)
    if not ok then return false, err end

    def.name = name
    normalise(def) -- esto es para que no se rompa el servidor si no se pone el peso, stack, etc
    ItemList[name]      = def
    Runtime.list[name]  = def
    Runtime.owner[name] = owner

    -- mandamos al instante a todos los que estan dentro y que reviente 
    TriggerClientEvent('ox_inventory:_addRuntimeItem', -1, name, def)
    return true
end

function Runtime.unregister(name)
    local owner = GetInvokingResource()
    if not allow(owner) then return false, 'rate_limited' end

    if Runtime.owner[name] ~= owner then return false, 'not_item_owner' end
    print('Unregistering item: ' .. name)
    if not ItemList[name] then return false, 'item_not_found' end -- < esto es para que no se rompa el servidor si el item no existe
    ItemList[name]      = nil
    Runtime.list[name]  = nil
    Runtime.owner[name] = nil

    TriggerClientEvent('ox_inventory:_removeRuntimeItem', -1, name)
    return true
end

-- Esto tiene pinta de que explota el servidor, no se si es por el numero de items o por el numero de jugadores
AddEventHandler('playerJoining', function(id)
    if next(Runtime.list) then
        lib.triggerClientEvent(id, 'ox_inventory:_bulkRuntimeItems', Runtime.list)
    end
end)

exports('RegisterItem',   Runtime.register)
exports('UnregisterItem', Runtime.unregister)


-- callback para que el cliente pregunte si el item realmente esta registrado
lib.callback.register('ox_inventory:runtimeItemExists', function(_, itemName)
    return Runtime.list[itemName] ~= nil
end)

-- devuelve la lista actual para validar desde el cliente
lib.callback.register('ox_inventory:getRuntimeItems', function()
    return Runtime.list
end)

-- exports.ox_inventory:RegisterItem('apple', { label = 'Manzana', weight = 120 }) -- < falla porque le faltan la mitad de las cosas , imagen, etc
-- exports.ox_inventory:UnregisterItem('apple') -- < falla porque no se puede borrar un item que no existe