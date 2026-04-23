local registers, stolenRegisters, stolenShelfs, safes = {}, {}, {}, {}
local WEBHOOK_URL = {
    ['DEFAULT'] = '',
    ['SHELF'] = '',
    ['STEAL'] = '',
    ['REGISTER'] = '',
    ['SAFE'] = '',
}

local function SendWebhook(title, description)
    if WEBHOOK_URL == "" or WEBHOOK_URL == nil then return end
    if WEBHOOK_URL[title:upper()] then
        if WEBHOOK_URL[title:upper()] == "" or WEBHOOK_URL[title:upper()] == nil then return end
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = description,
            ["type"] = "rich",
            ["color"] = 3066993,
            ["footer"] = {
                ["text"] = "VOS",
            },
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }
    }

    PerformHttpRequest(WEBHOOK_URL[title:upper()] or WEBHOOK_URL['DEFAULT'], function(err, text, headers) end, 'POST', json.encode({
        username = "VOS",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

-- @return True or False if array contains coordinates
---@param arr Array to check
---@param coords Coordinates to check
function containsCoords(arr, coords)
    for i = 1, #arr do
        if arr[i] and arr[i].coords then
            local stored = arr[i].coords
            local distance = #(vector3(stored.x, stored.y, stored.z) - vector3(coords.x, coords.y, coords.z))
            if distance < 0.1 then -- Small tolerance for floating point errors
                return true
            end
        end
    end
    return false
end

-- @return if player has correct item
---@param stage What item it needs to check for
lib.callback.register("flex_storerob:server:CheckItemAndDutyCount", function(source, stage)
    local jobcount = 0
    for _, job in pairs(Config.DutyCount.jobs) do
        local count = exports.qbx_core:GetDutyCountJob(job)
        jobcount += count
    end
    if jobcount < Config.DutyCount.count then
        Config.Notify.server(source, locale('error.nopolice'), 'info', 3000)
        return false
    end
    if SV_Config.RobItems[stage] then
        if HasInvGotItem(source, 'count', SV_Config.RobItems[stage], nil, 1) then
            return true
        else
            Config.Notify.server(source, locale('error.missing_item'), 'error', 3000)
            return false
        end
    else
        return true
    end
end)

-- @return all arrays to client
lib.callback.register("flex_storerob:server:GetArrays", function(source)
    return registers, stolenRegisters, stolenShelfs, SV_Config.Safes
end)

-- Register rob state
---@param coords Coordinates of the register
RegisterNetEvent("flex_storerob:server:SetRegisterState", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    if not containsCoords(registers, coords) then
        table.insert(registers, {coords = coords, expiresAt = os.time() + (Config.ResetTime.breakin * 60)})
        TriggerClientEvent("flex_storerob:client:OpenRegister", src, coords)
        TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
    else
        for i = 1, #registers do
            if registers[i] and registers[i].coords then
                local stored = registers[i].coords
                local distance = #(vector3(stored.x, stored.y, stored.z) - vector3(coords.x, coords.y, coords.z))
                if distance < 0.1 then
                    table.remove(registers, i)
                    TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
                    return
                end
            end
        end
    end
end)

-- Register stolen state
---@param coords Coordinates of the register
RegisterNetEvent("flex_storerob:server:SetStolenRegisterState", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    if not containsCoords(stolenRegisters, coords) then
        TriggerClientEvent("flex_storerob:client:StealRegister", src, coords)
    else
        for i = 1, #stolenRegisters do
            if stolenRegisters[i] and stolenRegisters[i].coords then
                local stored = stolenRegisters[i].coords
                local distance = #(vector3(stored.x, stored.y, stored.z) - vector3(coords.x, coords.y, coords.z))
                if distance < 0.1 then
                    TriggerClientEvent("flex_storerob:client:SyncStolenRegister", -1, coords, true)
                    table.remove(stolenRegisters, i)
                    TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
                    return
                end
            end
        end
    end
end)

RegisterNetEvent("flex_storerob:server:AddRegisterToStolenList", function(coords)
    table.insert(stolenRegisters, {coords = coords, expiresAt = os.time() + (Config.ResetTime.steal * 60)})
end)

-- Shelf steal state
---@param coords Coordinates of the shelf
RegisterNetEvent("flex_storerob:server:SetShelfState", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    if not containsCoords(stolenShelfs, coords) then
        table.insert(stolenShelfs, {coords = coords, expiresAt = os.time() + (Config.ResetTime.shelfs * 60)})
        TriggerClientEvent("flex_storerob:client:StealShelf", src, coords)
        TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
        SendWebhook('SHELF', locale('discord.started_shelf_stealing', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')'))
    else
        for i = 1, #stolenShelfs do
            if stolenShelfs[i] and stolenShelfs[i].coords then
                local stored = stolenShelfs[i].coords
                local distance = #(vector3(stored.x, stored.y, stored.z) - vector3(coords.x, coords.y, coords.z))
                if distance < 0.1 then
                    table.remove(stolenShelfs, i)
                    TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
                    return
                end
            end
        end
    end
end)

-- Shelf give reward
---@param coords Coordinates of the shelf
RegisterNetEvent("flex_storerob:server:StealShelfItem", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    for k, v in pairs(SV_Config.Reward.shelf) do
        if v.chance >= math.random(1, 100) then
            SendWebhook('SHELF', locale('discord.finished_shelf_stealing', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')', k, v.amount))
            if SV_Config.MonyTypes[k] then
                AddMoney(src, k, v.amount, nil)
            else
                AddItem(src, k, v.amount, v.info, nil)
            end
        end
    end
end)

-- Sync all arrays
RegisterNetEvent("flex_storerob:server:SyncStolenRegister", function()
    TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
end)

-- Give register item
---@param coords Coordinates of the register
RegisterNetEvent("flex_storerob:server:GiveRegister", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    Wait(150)
    TriggerClientEvent("flex_storerob:client:SyncStolenRegister", -1, coords, false)
    SendWebhook('STEAL', locale('discord.finished_steal_stealing', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')'))
    Wait(math.random(600,750))
    AddItem(src, 'register', 1, nil, nil)
    if SV_Config.RobItems.removeChance.steal ~= 0 and SV_Config.RobItems.removeonwin and math.random(1, 100) <= SV_Config.RobItems.removeChance.steal then
        RemoveItem(src, SV_Config.RobItems.steal, 1, nil, nil)
    end
end)

-- Give register rob rewards
---@param coords Coordinates of the register
RegisterNetEvent("flex_storerob:server:OpenRegister", function(coords)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    
    for k, v in pairs(SV_Config.Reward.register) do
        if v.chance >= math.random(1, 100) then
            SendWebhook('REGISTER', locale('discord.finished_open_register', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')', k, v.amount))
            if SV_Config.MonyTypes[k] then
                AddMoney(src, k, v.amount, nil)
            else
                if k == SV_Config.NotePadItem then
                    for i = 1, #SV_Config.Safes do
                        if SV_Config.Safes[i].code and not SV_Config.Safes[i].robbed then
                            if #(pedCoords.xyz - SV_Config.Safes[i].coords.xyz) < 25.0 then
                                AddItem(src, SV_Config.NotePadItem, v.amount, {safeCode = SV_Config.Safes[i].code}, nil)
                            end
                        end
                    end
                else
                    AddItem(src, k, v.amount, v.info, nil)
                end
            end
        end
    end
    if SV_Config.RobItems.removeChance.rob ~= 0 and SV_Config.RobItems.removeonwin and math.random(1, 100) <= SV_Config.RobItems.removeChance.rob then
        RemoveItem(src, SV_Config.RobItems.rob, 1, nil, nil)
    end
end)

-- Open Safe
---@param id ID of the safes array
RegisterNetEvent("flex_storerob:server:RobSafe", function(id)
    local src = source
    local safe = SV_Config.Safes[id]
    if not safe then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(safe.coords.xyz - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    local player = GetPlayer(src)
    if not player then return end
    SendWebhook('SAFE', locale('discord.started_saferob', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')'))
    TriggerClientEvent("flex_storerob:client:RobSafe", src, id, safe.code or nil, safe.locks or nil)
end)

-- Give Safe Reward
---@param id ID of the safes array
RegisterNetEvent("flex_storerob:server:SafeReward", function(id)
    local src = source
    local safe = SV_Config.Safes[id]
    if not safe then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(safe.coords.xyz - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    if safe.code then
        safe.code = math.random(1000, 9999)
        SendWebhook('SAFE', locale('discord.newsafecode', safe.code))
    end
    for k, v in pairs(SV_Config.Reward.safe) do
        if v.chance >= math.random(1, 100) then
            SendWebhook('SAFE', locale('discord.finished_saferob', player?.PlayerData?.charinfo?.firstname..' '..player?.PlayerData?.charinfo?.lastname..' ('..player?.PlayerData?.citizenid..')', k, v.amount))
            if SV_Config.MonyTypes[k] then
                AddMoney(src, k, v.amount, nil)
            else
                AddItem(src, k, v.amount, v.info, nil)
            end
        end
    end
    if SV_Config.RobItems.removeChance.safe ~= 0 and SV_Config.RobItems.removeonwin and math.random(1, 100) <= SV_Config.RobItems.removeChance.safe then
        RemoveItem(src, SV_Config.RobItems.safe, 1, nil, nil)
    end
end)

-- Set Safe State
---@param id ID of the safes array
---@param state Bool to set safe state
RegisterNetEvent("flex_storerob:server:SafeState", function(id, state)
    local src = source
    local safe = SV_Config.Safes[id]
    if not safe then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local pedCoords = GetEntityCoords(ped)
    if #(safe.coords.xyz - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    safe.robbed = state
    if state then
        table.insert(safes, {id = id, expiresAt = os.time() + (Config.ResetTime.safes * 60)})
    else
        for i = #safes, 1, -1 do
            local s = safes[i]
            if s and s.id == id then
                table.remove(safes, i)
            end
        end
    end
    TriggerClientEvent("flex_storerob:client:SafeState", -1, SV_Config.Safes)
end)

-- Remove lockpick chance
RegisterNetEvent("flex_storerob:server:RemoveLockPick", function(coords, robType)
    local src = source
    if not coords then return end
    local ped = GetPlayerPed(src)
    if ped == nil or ped == 0 then return end
    local player = GetPlayer(src)
    if not player then return end
    local pedCoords = GetEntityCoords(ped)
    if #(vector3(coords.x, coords.y, coords.z) - pedCoords.xyz) > 20.0 then 
        return DropPlayer(src, locale('error.exploit_kick')) 
    end
    if not SV_Config.RobItems[robType] or not SV_Config.RobItems.removeChance[robType] then return end
    if SV_Config.RobItems.removeChance[robType] ~= 0 or math.random(1, 100) <= SV_Config.RobItems.removeChance[robType] then
        RemoveItem(src, SV_Config.RobItems[robType], 1, nil, nil)
    end
end)

-- Thread that runs each minute to check if the state needs to be reset
CreateThread(function()
    while true do
        Wait(1000 * 60) -- check every 1 minute
        local currentTime = os.time()
        
        for i = #registers, 1, -1 do
            local reg = registers[i]
            if reg and reg.expiresAt and currentTime >= reg.expiresAt then
                table.remove(registers, i)
                TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
            end
        end
        
        for i = #stolenRegisters, 1, -1 do
            local reg = stolenRegisters[i]
            if reg and reg.expiresAt and currentTime >= reg.expiresAt then
                TriggerClientEvent("flex_storerob:client:SyncStolenRegister", -1, reg.coords, true)
                table.remove(stolenRegisters, i)
                TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
            end
        end
        
        for i = #stolenShelfs, 1, -1 do
            local shelf = stolenShelfs[i]
            if shelf and shelf.expiresAt and currentTime >= shelf.expiresAt then
                table.remove(stolenShelfs, i)
                TriggerClientEvent("flex_storerob:client:Sync", -1, registers, stolenRegisters, stolenShelfs)
            end
        end
        
        for i = #safes, 1, -1 do
            local safe = safes[i]
            if safe and safe.expiresAt and currentTime >= safe.expiresAt then
                SV_Config.Safes[safe.id].robbed = false
                table.remove(safes, i)
                TriggerClientEvent("flex_storerob:client:SafeState", -1, SV_Config.Safes)
            end
        end
    end
end)
