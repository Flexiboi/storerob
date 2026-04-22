local registers, stolenRegisters, stolenShelfs = {}, {}, {}
local TargetZones = {}

---@return If array contains val
---@param arr Array
---@param val Value inside array
local function contains(arr, val)
    for i = 1, #arr do
        if arr[i] == val then
            return true
        end
    end
    return false
end

--- Get rounded coordinates for consistent checking
---@param coords vector3
---@return vector3
local function getRoundedCoords(coords)
    return vector3(math.floor(coords.x), math.floor(coords.y), math.floor(coords.z))
end

--- Sync all arrays from server side
local function loadRegisters()
    if #TargetZones > 0 then return end
    lib.callback("flex_storerob:server:GetArrays", 1000, function(reg, stolenReg, shelfs, safesConf)
        if safesConf then
            Config.Safes = safesConf
            for i = 1, #safesConf do
                local safe = safesConf[i]
                TargetZones[i] = exports.ox_target:addBoxZone({
                    name = "store_safe_"..i,
                    coords = vec3(safe.coords.x, safe.coords.y, safe.coords.z),
                    size = vec3(1.0, 1.0, 1.0),
                    debug = Config.Debug,
                    options = {
                        {
                            name = "store_safe_steal_"..i,
                            icon = "fa-solid fa-vault",
                            label = locale('target.open_safe'),
                            distance = 2.0,
                            canInteract = function()
                                return not Config.Safes[i].robbed
                            end,
                            onSelect = function(args)
                                lib.callback("flex_storerob:server:CheckItemAndDutyCount", 1000, function(hasItem)
                                    if hasItem then
                                        TriggerServerEvent("flex_storerob:server:RobSafe", i)
                                    else
                                        -- Config.Notify.client(locale('error.missing_item'), "error", 3000)
                                    end
                                end, 'safe')
                            end,
                        }
                    }
                })
            end
        end
        if reg then
            registers = {}
            for i = 1, #reg do
                registers[i] = reg[i].coords
            end
        end
        if stolenReg then
            stolenRegisters = {}
            for i = 1, #stolenReg do
                stolenRegisters[i] = stolenReg[i].coords
                if stolenReg[i].coords then
                    local coords = stolenReg[i].coords
                    for k, v in pairs(Config.RegisterProps) do
                        CreateModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), true)
                    end
                end
            end
        end
        if shelfs then
            stolenShelfs = {}
            for i = 1, #shelfs do
                stolenShelfs[i] = shelfs[i].coords
            end
        end
    end)
end

---@return normal heading
---@param heading heading
local function normalizeHeading(heading)
    heading = heading % 360
    if heading < 0 then
        heading = heading + 360
    end
    return heading
end

---@return if player can rob or not
---@param entityCoords vector3
---@param table array
local function canRob(entityCoords, table)
    if contains(Config.DisabledRobJobs, QBX.PlayerData.job.type) or contains(Config.DisabledRobJobs, QBX.PlayerData.job.name) then return end
    if IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then return false end
    
    local pedCoords = GetEntityCoords(cache.ped)
    if #(pedCoords - entityCoords) > 2.0 then return false end
    
    local pedHeading = normalizeHeading(GetEntityHeading(cache.ped))
    local entityHeading = normalizeHeading(GetEntityHeading(entityCoords))

    local diff = math.abs(pedHeading - entityHeading)
    if diff > 180 then
        diff = 360 - diff
    end

    if diff <= 100.0 then
        return not contains(table, entityCoords)
    else
        return false
    end
end

-- Player load event
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    loadRegisters()
end)

-- Player unload event
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    exports.ox_target:removeModel(Config.RegisterProps, "steal_register")
    exports.ox_target:removeModel(Config.RegisterProps, "rob_register")
    exports.ox_target:removeModel(Config.StealProps, "rob_shelf")
    
    for k, v in pairs(TargetZones) do
        exports.ox_target:removeZone(v)
    end
    
    for i = 1, #stolenRegisters do
        if stolenRegisters[i] then
            local coords = stolenRegisters[i]
            for k, v in pairs(Config.RegisterProps) do
                RemoveModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), false)
            end
        end
    end
end)

-- Resource stop event
AddEventHandler("onResourceStop", function(resource)
    if resource == GetCurrentResourceName() then
        exports.ox_target:removeModel(Config.RegisterProps, "steal_register")
        exports.ox_target:removeModel(Config.RegisterProps, "rob_register")
        exports.ox_target:removeModel(Config.StealProps, "rob_shelf")
        
        for k, v in pairs(TargetZones) do
            exports.ox_target:removeZone(v)
        end
        
        for i = 1, #stolenRegisters do
            if stolenRegisters[i] then
                local coords = stolenRegisters[i]
                for k, v in pairs(Config.RegisterProps) do
                    RemoveModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), false)
                end
            end
        end
    end
end)

-- Resource load event
CreateThread(function()
    Wait(1000)
    loadRegisters() -- Load registers
    
    -- Link registers to target
    exports.ox_target:addModel(Config.RegisterProps, {
        {
            name = 'rob_register',
            icon = "fa-solid fa-lock",
            label = locale('target.rob_register'),
            distance = 1.5,
            onSelect = function(data)
                lib.callback("flex_storerob:server:CheckItemAndDutyCount", 1000, function(hasItem)
                    if hasItem then
                        local entityCoords = getRoundedCoords(GetEntityCoords(data.entity))
                        if not contains(registers, entityCoords) and not contains(stolenRegisters, entityCoords) then
                            TriggerServerEvent("flex_storerob:server:SetRegisterState", entityCoords)
                        end
                    else
                        -- Config.Notify.client(locale('error.missing_item'), "error", 3000)
                    end
                end, 'rob')
            end,
            canInteract = function(entity, distance, coords)
                if distance > 1.5 then return false end
                local entityCoords = getRoundedCoords(GetEntityCoords(entity))
                return canRob(entityCoords, registers)
            end
        },
        {
            name = 'steal_register',
            icon = "fa-solid fa-burst",
            label = locale('target.steal_register'),
            distance = 1.5,
            onSelect = function(data)
                lib.callback("flex_storerob:server:CheckItemAndDutyCount", 1000, function(hasItem)
                    if hasItem then
                        local entityCoords = getRoundedCoords(GetEntityCoords(data.entity))
                        if not contains(stolenRegisters, entityCoords) then
                            TriggerServerEvent("flex_storerob:server:SetStolenRegisterState", entityCoords)
                        end
                    else
                        -- Config.Notify.client(locale('error.missing_item'), "error", 3000)
                    end
                end, 'steal')
            end,
            canInteract = function(entity, distance, coords)
                if distance > 1.5 then return false end
                local entityCoords = getRoundedCoords(GetEntityCoords(entity))
                return canRob(entityCoords, stolenRegisters)
            end
        },
    })

    -- Link shelfs to target
    exports.ox_target:addModel(Config.StealProps, {
        {
            name = 'rob_shelf',
            icon = "fa-solid fa-hand",
            label = locale('target.rob_shelf'),
            distance = 1.5,
            onSelect = function(data)
                local entityCoords = getRoundedCoords(GetEntityCoords(data.entity))
                if not contains(stolenShelfs, entityCoords) then
                    TriggerServerEvent("flex_storerob:server:SetShelfState", entityCoords)
                end
            end,
            canInteract = function(entity, distance, coords)
                if distance > 1.5 then return false end
                if IsEntityPlayingAnim(cache.ped, 'anim@heists@box_carry@', 'idle', 3) then return false end
                if not entity or entity == 0 or not DoesEntityExist(entity) then
                    return false
                end
                local entityCoords = getRoundedCoords(GetEntityCoords(entity))
                return not contains(stolenShelfs, entityCoords)
            end
        },
    })
end)

-- Sync arrays from server
---@param reg Registers
---@param stolenReg Stolen registers
---@param shelfs Shelfs
RegisterNetEvent("flex_storerob:client:Sync", function(reg, stolenReg, shelfs)
    if reg then
        registers = {}
        for k, v in pairs(reg) do
            table.insert(registers, v.coords)
        end
    end
    
    if stolenReg then
        stolenRegisters = {}
        for i = 1, #stolenReg do
            stolenRegisters[i] = stolenReg[i].coords
            if stolenReg[i].coords then
                local coords = stolenReg[i].coords
                for k, v in pairs(Config.RegisterProps) do
                    CreateModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), true)
                end
            end
        end
    end
    
    if shelfs then
        stolenShelfs = {}
        for k, v in pairs(shelfs) do
            table.insert(stolenShelfs, v.coords)
        end
    end
end)

-- Play anim, progress bar and minigame for robbing register
---@param coords Register coordinates
RegisterNetEvent("flex_storerob:client:OpenRegister", function(coords)
    if not coords then return end
    local pedCoords = GetEntityCoords(cache.ped)
    if #(coords - pedCoords) < 10.0 then
        local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.0, GetHashKey(Config.RegisterProps[1]), false, false, false)
        if entity ~= 0 then
            SetEntityHeading(cache.ped, GetEntityHeading(entity))
        end
        
        Wait(250)

        local animDict = lib.requestAnimDict('veh@break_in@0h@p_m_one@')
        TaskPlayAnim(cache.ped, 'veh@break_in@0h@p_m_one@', 'low_force_entry_ds', 3.0, 1.0, -1, 49, 0, true, true, true)
        if math.random(1, 100) <= Config.PoliceNotify.chance.early then
            Config.PoliceNotify.event()
        end
        Wait(250)
        local succes = Config.Minigame.register()
        if succes then
            ClearPedTasks(cache.ped)
            if lib.progressBar({
                duration = 1000 * Config.RobTime.register,
                label = locale('progress.rob_register'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
                anim = {
                    dict = 'oddjobs@shop_robbery@rob_till',
                    clip = 'loop',
                    flag = 49,
                    duration = -1
                },
            }) then
                if math.random(1, 100) <= Config.PoliceNotify.chance.success then
                    Config.PoliceNotify.event()
                end
                ClearPedTasks(cache.ped)
                TriggerServerEvent("flex_storerob:server:OpenRegister", coords)
                if math.random(1, 100) <= Config.FingerPrintChance then
                    fingerPrints(GetEntityCoords(cache.ped))
                end
            else
                ClearPedTasks(cache.ped)
                if contains(registers, coords) then
                    TriggerServerEvent("flex_storerob:server:SetRegisterState", coords)
                end
                Config.Stress.func(Config.Stress.reg)
            end
        else
            if math.random(1, 100) <= Config.PoliceNotify.chance.fail then
                Config.PoliceNotify.event()
            end
            ClearPedTasks(cache.ped)
            if contains(registers, coords) then
                TriggerServerEvent("flex_storerob:server:SetRegisterState", coords)
            end
            Config.Stress.func(Config.Stress.reg)
            TriggerServerEvent('flex_storerob:server:RemoveLockPick', coords, 'rob')
        end
    end
end)

-- Play anim, progress bar for stealing from shelfs
---@param coords Shelf coordinates
RegisterNetEvent("flex_storerob:client:StealShelf", function(coords)
    if not coords then return end
    local pedCoords = GetEntityCoords(cache.ped)
    if #(coords - pedCoords) < 10.0 then
        TaskTurnPedToFaceCoord(cache.ped, coords.x, coords.y, coords.z, 2000)
        Wait(500)
        if math.random(1, 100) <= Config.PoliceNotify.chance.fail then
            Config.PoliceNotify.event()
        end
        if lib.progressBar({
            duration = 1000 * Config.RobTime.shelfs,
            label = locale('progress.rob_shelf'),
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true,
            },
            anim = {
                dict = 'oddjobs@shop_robbery@rob_till',
                clip = 'loop',
                flag = 49,
                duration = -1
            },
        }) then
            ClearPedTasks(cache.ped)
            TriggerServerEvent("flex_storerob:server:StealShelfItem", coords)
            if Config.FingerPrintChance <= math.random(100) then
                fingerPrints()
            end
        else
            ClearPedTasks(cache.ped)
            if contains(stolenShelfs, coords) then
                TriggerServerEvent("flex_storerob:server:SetShelfState", coords)
            end
        end
        Config.Stress.func(Config.Stress.shelf)
    end
end)

-- Play anim, progress bar and minigame for stealing register
---@param coords Register coordinates
RegisterNetEvent("flex_storerob:client:StealRegister", function(coords)
    if not coords then return end
    local pedCoords = GetEntityCoords(cache.ped)
    if #(coords - pedCoords) < 10.0 then
        local entity = GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.0, GetHashKey(Config.RegisterProps[1]), false, false, false)
        if entity ~= 0 then
            SetEntityHeading(cache.ped, GetEntityHeading(entity))
        end
        
        Wait(250)
        local succes = Config.Minigame.stealRegister()
        if succes then
            ClearPedTasks(cache.ped)
            if math.random(1, 100) <= Config.PoliceNotify.chance.fail then
                Config.PoliceNotify.event()
            end
            if lib.progressBar({
                duration = 1000 * Config.RobTime.steal,
                label = locale('progress.steal_register'),
                useWhileDead = false,
                canCancel = true,
                disable = {
                    car = true,
                    move = true,
                    combat = true,
                },
                anim = {
                    dict = 'random@mugging4',
                    clip = 'struggle_loop_b_thief',
                    flag = 49,
                    duration = -1
                },
            }) then
                ClearPedTasks(cache.ped)
                if Config.FingerPrintChance <= math.random(100) then
                    fingerPrints()
                end
                Wait(500)
                TriggerServerEvent("flex_storerob:server:GiveRegister", coords)
                TriggerServerEvent("flex_storerob:server:AddRegisterToStolenList", coords)
            else
                ClearPedTasks(cache.ped)
            end
        else
            if math.random(1, 100) <= Config.PoliceNotify.chance.fail then
                Config.PoliceNotify.event()
            end
            ClearPedTasks(cache.ped)
            TriggerServerEvent('flex_storerob:server:RemoveLockPick', coords, 'steal')
        end
        Config.Stress.func(Config.Stress.steal)
    end
end)

-- Play anim, progress bar and minigame for robbing safe
---@param id Safe ID
---@param code Safe code
---@param locksAmount Number of locks
RegisterNetEvent("flex_storerob:client:RobSafe", function(id, code, locksAmount)
    if not id then return end
    local pedCoords = GetEntityCoords(cache.ped)
    local safe = Config.Safes[id]
    if not safe then return end
    if #(safe.coords.xyz - pedCoords) < 5.0 then
        if math.random(1, 100) <= Config.PoliceNotify.chance.fail then
            Config.PoliceNotify.event()
        end
        TriggerServerEvent("flex_storerob:server:SafeState", id, true)
        TaskTurnPedToFaceCoord(cache.ped, safe.coords.x, safe.coords.y, safe.coords.z, 2000)
        Wait(500)
        if code then
            local animDict = lib.requestAnimDict("anim@amb@clubhouse@tutorial@bkr_tut_ig3@")
            TaskPlayAnim(cache.ped, "anim@amb@clubhouse@tutorial@bkr_tut_ig3@", "machinic_loop_mechandplayer", 3.0, 1.0, -1, 49, 0, true, true, true)
            if Config.Minigame.keypad(code) then
                ClearPedTasks(cache.ped)
                TriggerServerEvent("flex_storerob:server:SafeReward", id)
            else
                ClearPedTasks(cache.ped)
                TriggerServerEvent("flex_storerob:server:SafeState", id, false)
                Config.Stress.func(Config.Stress.safe)
                TriggerServerEvent('flex_storerob:server:RemoveLockPick', coords, 'safe')
            end
        elseif locksAmount then
            local locks = {}
            for i = 1, locksAmount do
                locks[i] = math.random(0,99)
            end

            local animDict = lib.requestAnimDict("anim@scripted@heist@ig15_safe_crack@male@")
            TaskPlayAnim(cache.ped, "anim@scripted@heist@ig15_safe_crack@male@", "idle_player", 3.0, 1.0, -1, 49, 0, true, true, true)

            if Config.Minigame.safe(locks) then
                ClearPedTasks(cache.ped)
                local animDict = lib.requestAnimDict("anim@scripted@heist@ig15_safe_crack@male@")
                TaskPlayAnim(cache.ped, "anim@scripted@heist@ig15_safe_crack@male@", "door_open_player", 3.0, 1.0, -1, 49, 0, true, true, true)
                Wait(GetAnimDuration("anim@scripted@heist@ig15_safe_crack@male@", "door_open_player")*750)

                local animDict = lib.requestAnimDict("anim@scripted@heist@ig15_safe_crack@male@")
                TaskPlayAnim(cache.ped, "anim@scripted@heist@ig15_safe_crack@male@", "exit_player", 3.0, 1.0, -1, 49, 0, true, true, true)
                Wait(GetAnimDuration("anim@scripted@heist@ig15_safe_crack@male@", "exit_player")*750)

                ClearPedTasks(cache.ped)
                TriggerServerEvent("flex_storerob:server:SafeReward", id)
            else
                ClearPedTasks(cache.ped)
                TriggerServerEvent("flex_storerob:server:SafeState", id, false)
                Config.Stress.func(Config.Stress.safe)
                TriggerServerEvent('flex_storerob:server:RemoveLockPick', coords, 'safe')
            end
        end
    end
end)

---@param safe Sync the array from the safes to client side
RegisterNetEvent("flex_storerob:client:SafeState", function(safes)
    Config.Safes = safes
end)

-- Sync stolen register visibility
---@param coords Register coordinates
---@param state True or False for visibility
RegisterNetEvent("flex_storerob:client:SyncStolenRegister", function(coords, state)
    if not coords then return end
    if not state then
        for k, v in pairs(Config.RegisterProps) do
            CreateModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), true)
        end
    else
        for k, v in pairs(Config.RegisterProps) do
            RemoveModelHide(coords.x, coords.y, coords.z, 1.0, GetHashKey(v), false)
        end
    end
end)

if GetResourceState('ox_inventory') == 'started' then
    exports.ox_inventory:displayMetadata({
        safeCode = 'CODE: ',
    })
end