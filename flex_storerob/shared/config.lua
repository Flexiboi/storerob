Config = {}

Config.Debug = false
Config.CoreName = {
    qb = 'qb-core',
    esx = 'es_extended',
    ox = 'ox_core',
    ox_inv = 'ox_inventory',
    qbx = 'qbx_core',
}

Config.Notify = {
    client = function(msg, type, time)
        lib.notify({
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
    server = function(src, msg, type, time)
        lib.notify(src, {
            title = msg,
            type = type,
            time = time or 5000,
        })
    end,
}

Config.DisabledRobJobs = {'leo', 'ems'}
Config.DutyCount = {count = 0, jobs = {'leo', 'police'}}
Config.PoliceNotify = {
    chance = {early = 100, fail = 0, success = 0}, -- chance out of 100
    event = function()
        exports['l2s-dispatch']:StoreRobbery()
    end,
}

Config.Stress = {
    func = function(amount)
        TriggerServerEvent('hud:server:GainStress', amount)
    end,
    reg = math.random(1,2),
    shelf = math.random(1,2),
    steal = math.random(3,5),
    safe = 1,
}

Config.Minigame = {
    register = function()
        -- return true
        local p = promise:new()
        local success = exports.Burevestnik_lockpick_minigame:Burevestnik_lockpick_minigame_start()
        p:resolve(success)
        return Citizen.Await(p)
    end,
    stealRegister = function()
        -- return true
        local p = promise:new()
        local success = exports.Burevestnik_lockpick_minigame:Burevestnik_lockpick_minigame_start()
        p:resolve(success)
        return Citizen.Await(p)
    end,
    keypad = function(code)
        local p = promise:new()
        exports['Boost-Numpad']:openNumpad(code,false,function(success)
            p:resolve(success)
        end)
        return Citizen.Await(p)
    end,
    safe = function(code)
        local p = promise:new()
        local success = exports["pd-safe"]:createSafe(code)
        p:resolve(success)
        return Citizen.Await(p)
    end,
}

Config.FingerPrintChance = 50 -- chance out of 100
Config.ResetTime = {
    breakin = 15, -- Time in minutes before it resets
    steal = 15, -- Time in minutes before it resets
    shelfs = 10, -- Time in minutes before it resets
    safes = 15, -- Time in minutes before it resets
}
Config.RobTime = {
    register = 10, -- Time in seconds
    steal = 30, -- Time in seconds
    safe = 10, -- Time in seconds
    shelfs = 10, -- Time in seconds
}

Config.RegisterProps = {
    'prop_till_01',
}

Config.StealProps = {
    -54719154,
    1437777724,
    -532065181,
    1421582485,
    -220235377,
}

Config.Safes = {}