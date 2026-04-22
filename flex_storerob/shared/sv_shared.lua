SV_Config = {}

SV_Config.RobItems = {
    rob = 'lockpick',
    steal = 'lockpick',
    safe = false,
    removeonwin = false,
    removeChance = {
        rob = math.random(0,10),
        steal = math.random(0,10),
        safe = math.random(0,10),
    }
}

SV_Config.MonyTypes = {
    'cash',
    'bank',
    'black_money',
}

SV_Config.NotePadItem = 'notepad'
SV_Config.Reward = {
    register = {
        notepad = { chance = math.random(65, 85), amount = 1, info = {}},
        black_money = { chance = 100, amount = math.random(400, 500), info = {}},
    },
    shelf = {
        ecola = { chance = math.random(50, 100), amount = 1, info = {}},
        twerks_candy = { chance = math.random(50, 100), amount = 1, info = {}},
        snikkel_candy = { chance = math.random(50, 100), amount = 1, info = {}},
        sandwich = { chance = math.random(50, 100), amount = 1, info = {}},
        kq_caffeine_powder = { chance = 10, amount = math.random(1,3), info = {}},
    },
    safe = {
        black_money = { chance = 100, amount = math.random(400, 500), info = {}},
        ruby = { chance = 10, amount = 1, info = {}},
        simbolos_chain = { chance = 10, amount = 1, info = {}},
        diamond = { chance = 1, amount = 1, info = {}},
        hack_usb_blueprint = { chance = 5, amount = 1, info = {}},
        -- ironoxide_blueprint = { chance = 5, amount = 1, info = {}},
        cutter_blueprint = { chance = 5, amount = 1, info = {}},
        handcuffs_blueprint = { chance = 5, amount = 1, info = {}},
        key = { chance = 5, amount = 1, info = {}},
        trojan_usb_blueprint = { chance = 5, amount = 1, info = {}},
    }
}

SV_Config.Safes = {
    [1] = {coords = vec3(-710.03424072266, -904.18670654297, 18.640968322754), robbed = false, code = math.random(1000, 9999)},
    [2] = {coords = vec3(28.163164138794, -1338.8779296875, 28.962450027466), robbed = false, code = math.random(1000, 9999)},
    [3] = {coords = vec3(1159.2110595703, -314.11898803711, 68.637420654297), robbed = false, code = math.random(1000, 9999)},
    [4] = {coords = vec3(378.18902587891, 333.69967651367, 102.99572753906), robbed = false, code = math.random(1000, 9999)},
    [5] = {coords = vec3(-1829.4020996094, 798.53179931641, 137.62591552734), robbed = false, code = math.random(1000, 9999)},
    [6] = {coords = vec3(2548.931640625, 384.84262084961, 108.09550476074), robbed = false, code = math.random(1000, 9999)},
    [7] = {coords = vec3(2672.4699707031, 3286.7370605469, 54.706089019775), robbed = false, code = math.random(1000, 9999)},
    [8] = {coords = vec3(1959.0544433594, 3749.1506347656, 31.791324615479), robbed = false, code = math.random(1000, 9999)},
    [9] = {coords = vec3(546.50872802734, 2662.4973144531, 41.623699188232), robbed = false, code = math.random(1000, 9999)},
    [10] = {coords = vec3(1734.9035644531, 6421.1430664062, 34.445495605469), robbed = false, code = math.random(1000, 9999)},
    [11] = {coords = vec3(1708.0445556641, 4920.6982421875, 41.49507522583), robbed = false, code = math.random(1000, 9999)},
    [12] = {coords = vec3(-3250.3488769531, 1004.4138793945, 12.240526199341), robbed = false, code = math.random(1000, 9999)},
    [13] = {coords = vec3(-3048.1279296875, 585.48675537109, 7.3613729476929), robbed = false, code = math.random(1000, 9999)},
    [14] = {coords = vec3(-1220.85, -916.05, 11.329), robbed = false, locks = math.random(2,3)},
    [15] = {coords = vec3(-1478.94, -375.5, 39.16), robbed = false, locks = math.random(2,3)},
    [16] = {coords = vec3(1126.77, -980.1, 45.41), robbed = false, locks = math.random(2,3)},
    [17] = {coords = vec3(1169.31, 2717.79, 37.15), robbed = false, locks = math.random(2,3)},
    [18] = {coords = vec3(-2959.64, 387.08, 14.04), robbed = false, locks = math.random(2,3)},
}