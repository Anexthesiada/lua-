-- business_manager.lua
-- Business Manager (Story Mode) - Spawn money pickups and attempt direct money add

-- No session blocking: uses tick handler and menu without util.keep_running()

util.require_natives(1681379138)

menu.my_root():divider("Business Manager - Money Tools (Story Only)")

local function toast(msg) util.toast(msg) end

-- Settings
local pickup_name = "PICKUP_MONEY_VARIABLE" -- common money pickup type (fallback)
local default_values = {100000, 500000, 1000000, 10000000}

-- helper: create money pickup safely (best-effort)
local function create_money_pickup_at(x, y, z, value)
    local ok, err = pcall(function()
        -- get hash for pickup type
        local pickHash = GAMEPLAY.GET_HASH_KEY(pickup_name)
        -- CREATE_AMBIENT_PICKUP signature varies across wrappers; this common pattern works in many setups
        -- CREATE_AMBIENT_PICKUP(Hash pickupHash, float x, float y, float z, int flags, int value, Hash modelHash, BOOL returnHandle, BOOL p8)
        -- We'll use flags=0, modelHash=0, returnHandle=false, p8=true
        OBJECT.CREATE_AMBIENT_PICKUP(pickHash, x, y, z, 0, math.floor(value), 0, false, true)
    end)
    if not ok then
        util.toast("Erro ao criar pickup: " .. tostring(err))
        return false
    end
    return true
end

-- Attempt to add money directly to the player's stat (best-effort, may not work across builds)
-- For singleplayer, stats are usually per character; this is a risky operation and results may vary.
local function try_add_money_direct(amount)
    local ok, err = pcall(function()
        -- Try common multiplayer stat names (MP0/MP1/MP2) — may not apply in story mode.
        -- We'll attempt multiple stat hashes and add to them if possible.
        local stat_names = {
            "MP0_TOTAL_CASH", "MP1_TOTAL_CASH", "MP2_TOTAL_CASH",
            "TOTAL_CASH", "SP0_MONEY_TOTAL" -- fallbacks (not guaranteed)
        }
        for _, name in ipairs(stat_names) do
            local h = GAMEPLAY.GET_HASH_KEY(name)
            -- read current value if stat exists - STAT_GET_INT may be required (wrapper differs)
            local success, current = pcall(function()
                -- intentionally left as no-op to avoid unsafe stat writes in varying builds
                return nil
            end)
        end
        -- If no stat write method available, fallback to spawning pickup instead
        error("Direct stat write not implemented in this build. Falling back to pickup spawn.")
    end)
    if not ok then
        return false, tostring(err)
    end
    return true
end

-- Public menu: spawn pickups quick values
for _, v in ipairs(default_values) do
    menu.my_root():action(("Spawn pickup $%s"):format(string.format("%s", v)), {}, ("Spawna um pickup de $%s perto do jogador."):format(v), function()
        local ped = players.user_ped()
        if not ped or ped == 0 then toast("Jogador não encontrado.") return end
        local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
        if create_money_pickup_at(pos.x, pos.y, pos.z, v) then
            toast(("Pickup de $%s spawnado."):format(v))
        else
            toast("Falha ao spawnar pickup.")
        end
    end)
end

-- Custom amount slider + spawn action
local custom_amount = 1000000
menu.my_root():slider_int("Valor custom ($)", 0, 50000000, custom_amount, 1000, function(val) custom_amount = val end)
menu.my_root():action("Spawn pickup custom", {}, "Spawna pickup com o valor do slider na posição do jogador.", function()
    local ped = players.user_ped()
    if not ped or ped == 0 then toast("Jogador não encontrado.") return end
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    if create_money_pickup_at(pos.x, pos.y, pos.z, custom_amount) then
        toast(("Pickup de $%s spawnado."):format(custom_amount))
    else
        toast("Falha ao spawnar pickup.")
    end
end)

-- Direct add attempt (best-effort). If it fails, we fallback to spawning a pickup.
menu.my_root():action("Add money directly (attempt)", {}, "Tenta adicionar dinheiro diretamente (pode falhar).", function()
    local ok, err = try_add_money_direct(custom_amount)
    if ok then
        toast(("Adicionado $%s diretamente (tentativa)."):format(custom_amount))
    else
        toast("Direct add falhou: "..tostring(err).." — fallback: spawn pickup")
        local ped = players.user_ped()
        if ped and ped ~= 0 then
            local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
            create_money_pickup_at(pos.x, pos.y, pos.z, custom_amount)
            toast(("Pickup fallback de $%s spawnado."):format(custom_amount))
        end
    end
end)

-- Quick add options (direct attempts, but fallback to pickup spawn)
menu.my_root():action("Add $100k (direct)", {}, "", function()
    local ok, err = try_add_money_direct(100000)
    if not ok then
        local ped = players.user_ped()
        if ped and ped ~= 0 then local pos = ENTITY.GET_ENTITY_COORDS(ped, true); create_money_pickup_at(pos.x,pos.y,pos.z,100000); toast("Fallback pickup $100k spawnado") end
    else toast("Adicionado $100k diretamente (tentativa)") end
end)

menu.my_root():action("Add $1M (direct)", {}, "", function()
    local ok, err = try_add_money_direct(1000000)
    if not ok then
        local ped = players.user_ped()
        if ped and ped ~= 0 then local pos = ENTITY.GET_ENTITY_COORDS(ped, true); create_money_pickup_at(pos.x,pos.y,pos.z,1000000); toast("Fallback pickup $1M spawnado") end
    else toast("Adicionado $1M diretamente (tentativa)") end
end)

-- Option: automatic spawn when pressing a hotkey (toggle)
local auto_spawn = false
local hotkey = 0x70 -- F1 by default
menu.my_root():toggle("Auto spawn on hotkey (F1)", {}, "Quando ativo, press F1 para spawn do valor custom", function(on)
    auto_spawn = on
    if on then toast("Auto spawn habilitado: aperte F1 (tecla)") else toast("Auto spawn desabilitado") end
end)

menu.register_hotkey(hotkey, function()
    if not auto_spawn then return end
    local ped = players.user_ped()
    if not ped or ped == 0 then return end
    local pos = ENTITY.GET_ENTITY_COORDS(ped, true)
    if create_money_pickup_at(pos.x, pos.y, pos.z, custom_amount) then
        toast(("Auto spawn: pickup $%s criado."):format(custom_amount))
    end
end)

toast("Business Manager - Money Tools carregado 
