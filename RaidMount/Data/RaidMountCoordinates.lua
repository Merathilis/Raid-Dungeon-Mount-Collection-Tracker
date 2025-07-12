local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local RaidMountCoordinates = {
    -- Classic Raids
    [26] = {x = 46.6, y = 7.5, zone = "Silithus", instance = "Temple of Ahn'Qiraj"},  -- Red Qiraji Resonating Crystal
    [349] = {x = 52.0, y = 76.0, zone = "Dustwallow Marsh", instance = "Onyxia's Lair"},
    [168] = {x = 46.9, y = 74.6, zone = "Deadwind Pass", instance = "Karazhan"},
    [183] = {x = 76.5, y = 65.1, zone = "Netherstorm", instance = "Tempest Keep"},

    -- WotLK Raids
    [246] = {x = 27.5, y = 26.0, zone = "Borean Tundra", instance = "The Eye of Eternity"},
    [247] = {x = 27.5, y = 26.0, zone = "Borean Tundra", instance = "The Eye of Eternity"},
    [248] = {x = 27.5, y = 26.0, zone = "Borean Tundra", instance = "The Eye of Eternity"},
    [253] = {x = 57.2, y = 42.1, zone = "Dragonblight", instance = "The Obsidian Sanctum"},
    [250] = {x = 57.2, y = 42.1, zone = "Dragonblight", instance = "The Obsidian Sanctum"},
    [304] = {x = 41.6, y = 17.8, zone = "The Storm Peaks", instance = "Ulduar"},
    [363] = {x = 53.9, y = 87.1, zone = "Icecrown", instance = "Icecrown Citadel"},
    [287] = {x = 47.3, y = 78.3, zone = "Wintergrasp", instance = "Vault of Archavon"},

    -- Cataclysm Raids
    [396] = {x = 38.3, y = 80.5, zone = "Uldum", instance = "Throne of the Four Winds"},
    [415] = {x = 47.3, y = 78.1, zone = "Mount Hyjal", instance = "Firelands"},
    [425] = {x = 47.3, y = 78.1, zone = "Mount Hyjal", instance = "Firelands"},
    [445] = {x = 64.3, y = 50.2, zone = "Tanaris", instance = "Dragon Soul"},
    [442] = {x = 64.3, y = 50.2, zone = "Tanaris", instance = "Dragon Soul"},
    [444] = {x = 64.3, y = 50.2, zone = "Tanaris", instance = "Dragon Soul"},

    -- Mists of Pandaria Raids
    [478] = {x = 60.0, y = 39.0, zone = "Kun-Lai Summit", instance = "Mogu'shan Vaults"},
    [543] = {x = 63.0, y = 32.0, zone = "Isle of Thunder", instance = "Throne of Thunder"},
    [531] = {x = 63.0, y = 32.0, zone = "Isle of Thunder", instance = "Throne of Thunder"},
    [559] = {x = 74.0, y = 42.0, zone = "Vale of Eternal Blossoms", instance = "Siege of Orgrimmar"},

    -- Warlords of Draenor Raids
    [613] = {x = 44.3, y = 60.0, zone = "Gorgrond", instance = "Blackrock Foundry"},
    [751] = {x = 29.5, y = 40.2, zone = "Tanaan Jungle", instance = "Hellfire Citadel"},

    -- Legion Raids
    [791] = {x = 55.8, y = 64.5, zone = "Suramar", instance = "The Nighthold"},
    [633] = {x = 55.8, y = 64.5, zone = "Suramar", instance = "The Nighthold"},
    [899] = {x = 29.5, y = 40.2, zone = "Broken Shore", instance = "Tomb of Sargeras"},
    [971] = {x = 55.8, y = 64.5, zone = "Antoran Wastes", instance = "Antorus, the Burning Throne"},
    [954] = {x = 55.8, y = 64.5, zone = "Antoran Wastes", instance = "Antorus, the Burning Throne"},

    -- Battle for Azeroth Raids
    [1217] = {x = 39.0, y = 2.0, zone = "Dazar'alor", instance = "Battle of Dazar'alor"},
    [1219] = {x = 70.0, y = 35.0, zone = "Boralus", instance = "Battle of Dazar'alor"},
    [1169] = {x = 50.0, y = 12.0, zone = "Nazjatar", instance = "The Eternal Palace"},
    [1257] = {x = 38.0, y = 44.0, zone = "Uldum", instance = "Ny'alotha, the Waking City"},
    [1391] = {x = 57.0, y = 48.0, zone = "Vale of Eternal Blossoms", instance = "Ny'alotha, the Waking City"},
    [1293] = {x = 57.0, y = 48.0, zone = "Vale of Eternal Blossoms", instance = "Ny'alotha, the Waking City"},

    -- Shadowlands Raids
    [1500] = {x = 69.0, y = 31.0, zone = "The Maw", instance = "Sanctum of Domination"},
    [1471] = {x = 69.0, y = 31.0, zone = "The Maw", instance = "Sanctum of Domination"},
    [1587] = {x = 81.0, y = 53.0, zone = "Zereth Mortis", instance = "Sepulcher of the First Ones"},

    -- Dragonflight Raids
    [1818] = {x = 28.0, y = 31.0, zone = "Emerald Dream", instance = "Amirdrassil, the Dream's Hope"},

    -- The War Within Raids
    [2219] = {x = 35.0, y = 72.0, zone = "City of Threads, Azj-Kahet", instance = "Nerub-ar Palace"},
    [2223] = {x = 35.0, y = 72.0, zone = "City of Threads, Azj-Kahet", instance = "Nerub-ar Palace"},
    [2507] = {x = 41.8, y = 49.0, zone = "Undermine", instance = "Liberation of Undermine"},
    [2487] = {x = 41.8, y = 49.0, zone = "Undermine", instance = "Liberation of Undermine"},

    -- Classic Dungeons
    [69] = {x = 26.0, y = 14.0, zone = "Eastern Plaguelands", instance = "Stratholme"},

    -- Burning Crusade Dungeons
    [185] = {x = 42.0, y = 65.0, zone = "Auchindoun, Terokkar Forest", instance = "Sethekk Halls"},
    [213] = {x = 61.0, y = 31.0, zone = "Isle of Quel'Danas", instance = "Magisters' Terrace"},

    -- Wrath of the Lich King Dungeons
    [264] = {x = 57.0, y = 48.0, zone = "Howling Fjord", instance = "Utgarde Pinnacle"},
    [278] = {x = 57.0, y = 48.0, zone = "Howling Fjord", instance = "Utgarde Pinnacle"},

    -- Cataclysm Dungeons
    [397] = {x = 47.0, y = 52.0, zone = "Deepholm", instance = "The Stonecore"},
    [395] = {x = 76.0, y = 83.0, zone = "Uldum", instance = "The Vortex Pinnacle"},
    [400] = {x = 50.0, y = 50.0, zone = "Feralas", instance = "Feralas"},
    [410] = {x = 67.0, y = 32.0, zone = "Northern Stranglethorn", instance = "Zul'Gurub"},
    [411] = {x = 67.0, y = 32.0, zone = "Northern Stranglethorn", instance = "Zul'Gurub"},
    [419] = {x = 82.0, y = 64.0, zone = "Ghostlands", instance = "Zul'Aman"},

    -- Legion Dungeons
    [875] = {x = 46.9, y = 74.6, zone = "Deadwind Pass", instance = "Return to Karazhan"},
    [883] = {x = 46.9, y = 74.6, zone = "Deadwind Pass", instance = "Return to Karazhan"},
    [955] = {x = 55.8, y = 64.5, zone = "Antoran Wastes", instance = "Antorus, the Burning Throne"},

    -- Battle for Azeroth Dungeons
    [995] = {x = 85.0, y = 78.0, zone = "Tiragarde Sound", instance = "Freehold"},
    [1040] = {x = 38.0, y = 13.4, zone = "Zuldazar", instance = "Kings' Rest"},
    [1053] = {x = 26.0, y = 46.8, zone = "Nazmir", instance = "The Underrot"},
    [1227] = {x = 69.8, y = 62.6, zone = "Mechagon", instance = "Operation: Mechagon"},
    [1252] = {x = 69.8, y = 62.6, zone = "Mechagon", instance = "Operation: Mechagon"},

    -- Shadowlands Dungeons
    [1406] = {x = 40.4, y = 55.0, zone = "Bastion", instance = "The Necrotic Wake"},
    [1481] = {x = 86.0, y = 48.0, zone = "Tazavesh, the Veiled Market", instance = "Tazavesh, the Veiled Market"},
    [1445] = {x = 59.0, y = 65.0, zone = "Maldraxxus", instance = "Plaguefall"},

    -- Dragonflight Dungeons
    [198825] = {x = 60.0, y = 40.0, zone = "Thaldraszus", instance = "Neltharus"},
    [192799] = {x = 85.0, y = 50.0, zone = "Ohn'ahran Plains", instance = "The Nokhud Offensive"},
    [2569] = {x = 50.0, y = 50.0, zone = "K'aresh", instance = "Manaforge Omega"},  -- Unbound Star-Eater

    -- The War Within Dungeons
    [2204] = {x = 59.0, y = 21.0, zone = "The Ringing Deeps", instance = "Darkflame Cleft"},
    [2119] = {x = 47.0, y = 9.0, zone = "The Ringing Deeps", instance = "The Stonevault"},

    -- World Bosses
    [44168] = {x = 50.0, y = 50.0, zone = "The Storm Peaks", instance = "Frozen Lake/Ulduar/Waterfall"},  -- Time-Lost Proto-Drake
    [63041] = {x = 49.1, y = 55.6, zone = "Deepholm", instance = "Aeonaxx"},
    [94228] = {x = 50.0, y = 54.5, zone = "Isle of Giants", instance = "World Boss"},  -- Cobalt Primordial Direhorn (Oondasta)
    [94230] = {x = 50.0, y = 54.5, zone = "Isle of Giants", instance = "World Boss"},  -- Amber Primordial Direhorn (Oondasta)
    [87771] = {x = 54.0, y = 63.0, zone = "Kun-Lai Summit", instance = "World Boss"},  -- Heavenly Onyx Cloud Serpent (Sha of Anger)
    [95057] = {x = 49.0, y = 68.0, zone = "Isle of Thunder", instance = "World Boss"},  -- Thundering Cobalt Cloud Serpent (Nalak)
    [89783] = {x = 70.0, y = 64.0, zone = "Valley of the Four Winds", instance = "World Boss"},  -- Son of Galleon (Galleon)
    [634] = {x = 36.6, y = 39.0, zone = "Spires of Arak", instance = "World Boss"},  -- Solar Spirehawk (Rukhmar)
    [643] = {x = -1, y = -1, zone = "Tanaan Jungle", instance = "World Mob Cage"},  -- Warsong Direfang (via Rattling Iron Cage)
    
    -- Tanaan Jungle rares that drop Warsong Direfang cage
    [90122] = {x = 47.0, y = 52.6, zone = "Tanaan Jungle", instance = "Doomroller"},
    [95044] = {x = 32.6, y = 74.0, zone = "Tanaan Jungle", instance = "Vengeance"},
    [90139] = {x = 14.6, y = 62.8, zone = "Tanaan Jungle", instance = "Terrorfist"},
    [95053] = {x = 23.0, y = 40.2, zone = "Tanaan Jungle", instance = "Deathtalon"},
    [758] = {x = 45.2, y = 53.6, zone = "Tanaan Jungle", instance = "Hellfire Citadel"},  -- Infernal Direwolf (Glory of the Hellfire Raider)
    [1798] = {x = 62.5, y = 50.0, zone = "Tanaris", instance = "World Event"},  -- Azure Worldchiller (Doomwalker TW)
    [293] = {x = 62.5, y = 50.0, zone = "Tanaris", instance = "World Event"},  -- Illidari Doomhawk (Doomwalker TW)

    -- Special/Holiday Mounts
    [781] = {x = 0.0, y = 0.0, zone = "Various", instance = "Timewalking Dungeons"},
    [219] = {x = 0.0, y = 0.0, zone = "Scarlet Monastery", instance = "Hallow's End"},
    [202] = {x = 0.0, y = 0.0, zone = "Blackrock Depths", instance = "Brewfest"},
    [226] = {x = 0.0, y = 0.0, zone = "Blackrock Depths", instance = "Brewfest"},
    [352] = {x = 0.0, y = 0.0, zone = "Shadowfang Keep", instance = "Love is in the Air"},
    [2328] = {x = 0.0, y = 0.0, zone = "Shadowfang Keep", instance = "Love is in the Air"},

    -- Dragonflight World Mounts
    [1815] = {x = 50.0, y = 50.0, zone = "Emerald Dream", instance = "Dreamseed Cache"},
}

RaidMount.Coordinates = RaidMountCoordinates
