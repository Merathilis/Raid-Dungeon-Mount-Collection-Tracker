local addonName, RaidMount = ...
RaidMount.mountInstances = RaidMount.mountInstances or {}

RaidMount.mountInstances = {
    -- ======================================
    -- RAID BOSS DROPS
    -- ======================================
    
    -- Classic WoW Raids
    { mountName = "Onyxian Drake", itemID = 49636, mountID = 69395, spellID = 69395, raidName = "Onyxia's Lair", expansion = "Classic", bossName = "Onyxia", dropRate = "~1%", difficulty = "Normal", location = "Dustwallow Marsh", statisticIds = { 1098 }, contentType = "Raid" },
    { mountName = "Fiery Warhorse", itemID = 30480, mountID = 36702, spellID = 36702, raidName = "Karazhan", expansion = "The Burning Crusade", bossName = "Attumen the Huntsman", dropRate = "~1%", difficulty = "Normal", location = "Deadwind Pass", statisticIds = { 1088 }, contentType = "Raid" },
    { mountName = "Ashes of Al'ar", itemID = 32458, mountID = 40192, spellID = 40192, raidName = "Tempest Keep", expansion = "The Burning Crusade", bossName = "Kael'thas Sunstrider", dropRate = "~1%", difficulty = "Normal", location = "Netherstorm", contentType = "Raid" },
    
    -- Wrath of the Lich King Raids
    { mountName = "Azure Drake", itemID = 43952, mountID = 59567, spellID = 59567, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", statisticIds = { 1391, 1394 }, contentType = "Raid" },
    { mountName = "Blue Drake", itemID = 43953, mountID = 59568, spellID = 59568, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", statisticIds = { 1391, 1394 }, contentType = "Raid" },
    { mountName = "Bronze Drake", itemID = 43951, mountID = 59569, spellID = 59569, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", statisticIds = { 1391, 1394 }, contentType = "Raid" },
    { mountName = "Black Drake", itemID = 44224, mountID = 59650, spellID = 59650, raidName = "The Obsidian Sanctum", expansion = "Wrath of the Lich King", bossName = "Sartharion", dropRate = "~2%", difficulty = "Normal 10", location = "Dragonblight", contentType = "Raid" },
    { mountName = "Twilight Drake", itemID = 44228, mountID = 59571, spellID = 59571, raidName = "The Obsidian Sanctum", expansion = "Wrath of the Lich King", bossName = "Sartharion", dropRate = "~2%", difficulty = "Normal 25", location = "Dragonblight", contentType = "Raid" },
    { mountName = "Mimiron's Head", itemID = 45693, mountID = 63796, spellID = 63796, raidName = "Ulduar", expansion = "Wrath of the Lich King", bossName = "Yogg-Saron (0 Keepers)", dropRate = "~1%", difficulty = "Normal 25", location = "The Storm Peaks", statisticIds = { 2869, 2883 }, contentType = "Raid" },
    { mountName = "Invincible", itemID = 50818, mountID = 72286, spellID = 72286, raidName = "Icecrown Citadel", expansion = "Wrath of the Lich King", bossName = "The Lich King", dropRate = "~1%", difficulty = "Heroic 25", location = "Icecrown", statisticIds = { 4688 }, contentType = "Raid" },
    { mountName = "Grand Black War Mammoth", itemID = 44083, mountID = 61467, spellID = 61467, raidName = "Vault of Archavon", expansion = "Wrath of the Lich King", bossName = "Any Boss", dropRate = "~1%", difficulty = "Normal", location = "Wintergrasp", statisticIds = { 1753, 1754, 2870, 3236, 4074, 4075, 4657, 4658 }, contentType = "Raid" },
    
    -- Cataclysm Raids
    { mountName = "Drake of the South Wind", itemID = 63128, mountID = 88744, spellID = 88744, raidName = "Throne of the Four Winds", expansion = "Cataclysm", bossName = "Al'Akir", dropRate = "~1%", difficulty = "Normal", location = "Uldum", statisticIds = { 5976, 5977 }, contentType = "Raid" },
    { mountName = "Pureblood Fire Hawk", itemID = 69122, mountID = 97493, spellID = 97493, raidName = "Firelands", expansion = "Cataclysm", bossName = "Ragnaros", dropRate = "~1%", difficulty = "Normal", location = "Mount Hyjal", statisticIds = { 5970, 5971 }, contentType = "Raid" },
    { mountName = "Flametalon of Alysrazor", itemID = 69823, mountID = 101542, spellID = 101542, raidName = "Firelands", expansion = "Cataclysm", bossName = "Alysrazor", dropRate = "~1%", difficulty = "Normal", location = "Mount Hyjal", statisticIds = { 6161, 6162 }, contentType = "Raid" },
    { mountName = "Experiment 12-B", itemID = 78919, mountID = 110039, spellID = 110039, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Ultraxion", dropRate = "~1%", difficulty = "Normal", location = "Caverns of Time", statisticIds = { 6168 }, contentType = "Raid" },
    { mountName = "Blazing Drake", itemID = 77067, mountID = 107842, spellID = 107842, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Deathwing", dropRate = "~1%", difficulty = "Normal", location = "Caverns of Time", statisticIds = { 5576, 5577 }, contentType = "Raid" },
    { mountName = "Life-Binder's Handmaiden", itemID = 77069, mountID = 107845, spellID = 107845, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Deathwing", dropRate = "~1%", difficulty = "Heroic", location = "Caverns of Time", statisticIds = { 6167, 6168 }, contentType = "Raid" },
    
    -- Mists of Pandaria Raids
    { mountName = "Astral Cloud Serpent", itemID = 87777, mountID = 127170, spellID = 127170, raidName = "Mogu'shan Vaults", expansion = "Mists of Pandaria", bossName = "Elegon", dropRate = "~1%", difficulty = "Normal", location = "Kun-Lai Summit", statisticIds = { 6797, 6798, 7924, 7923 }, contentType = "Raid" },
    { mountName = "Clutch of Ji-Kun", itemID = 95059, mountID = 139448, spellID = 139448, raidName = "Throne of Thunder", expansion = "Mists of Pandaria", bossName = "Ji-Kun", dropRate = "~1%", difficulty = "Normal", location = "Isle of Thunder", statisticIds = { 8171, 8169, 8172, 8170 }, contentType = "Raid" },
    { mountName = "Spawn of Horridon", itemID = 93666, mountID = 136471, spellID = 136471, raidName = "Throne of Thunder", expansion = "Mists of Pandaria", bossName = "Horridon", dropRate = "~1%", difficulty = "Normal", location = "Isle of Thunder", contentType = "Raid" },
    { mountName = "Kor'kron Juggernaut", itemID = 104253, mountID = 148417, spellID = 148417, raidName = "Siege of Orgrimmar", expansion = "Mists of Pandaria", bossName = "Garrosh Hellscream", dropRate = "~1%", difficulty = "Mythic", location = "Vale of Eternal Blossoms", statisticIds = { 8638, 8637 }, contentType = "Raid" },
    
    -- Warlords of Draenor Raids
    { mountName = "Ironhoof Destroyer", itemID = 116660, mountID = 171621, spellID = 171621, raidName = "Blackrock Foundry", expansion = "Warlords of Draenor", bossName = "Blackhand", dropRate = "~1%", difficulty = "Mythic", location = "Gorgrond", statisticIds = { 9365 }, contentType = "Raid" },
    { mountName = "Felsteel Annihilator", itemID = 123890, mountID = 182912, spellID = 182912, raidName = "Hellfire Citadel", expansion = "Warlords of Draenor", bossName = "Archimonde", dropRate = "~1%", difficulty = "Mythic", location = "Tanaan Jungle", statisticIds = { 10252 }, contentType = "Raid" },
    
    -- Legion Raids
    { mountName = "Midnight's Eternal Reins", itemID = 137574, mountID = 213134, spellID = 213134, raidName = "The Emerald Nightmare", expansion = "Legion", bossName = "Xavius", dropRate = "~1%", difficulty = "Mythic", location = "Val'sharah", contentType = "Raid" },
    { mountName = "Felblaze Infernal", itemID = 137574, mountID = 791, spellID = 213134, raidName = "The Nighthold", expansion = "Legion", bossName = "Gul'dan", dropRate = "~1%", difficulty = "Normal", location = "Suramar", contentType = "Raid" },
    { mountName = "Hellfire Infernal", itemID = 137575, mountID = 633, spellID = 171827, raidName = "The Nighthold", expansion = "Legion", bossName = "Gul'dan", dropRate = "~1%", difficulty = "Mythic", location = "Suramar", contentType = "Raid" },
    { mountName = "Living Infernal Core", itemID = 147821, mountID = 238452, spellID = 238452, raidName = "Tomb of Sargeras", expansion = "Legion", bossName = "Mistress Sassz'ine", dropRate = "~1%", difficulty = "Mythic", location = "Broken Shore", contentType = "Raid" },
    { mountName = "Abyss Worm", itemID = 143643, mountID = 899, spellID = 232519, raidName = "Tomb of Sargeras", expansion = "Legion", bossName = "Mistress Sassz'ine", dropRate = "~1%", difficulty = "Mythic", location = "Broken Shore", contentType = "Raid" },
    { mountName = "Antoran Charhound", itemID = 152816, mountID = 971, spellID = 253088, raidName = "Antorus, the Burning Throne", expansion = "Legion", bossName = "Felhounds of Sargeras", dropRate = "~1%", difficulty = "Mythic", location = "Antoran Wastes", contentType = "Raid" },
    { mountName = "Shackled Ur'zul", itemID = 152789, mountID = 954, spellID = 243651, raidName = "Antorus, the Burning Throne", expansion = "Legion", bossName = "Argus the Unmaker", dropRate = "~1%", difficulty = "Mythic", location = "Antoran Wastes", contentType = "Raid" },
    
    -- Battle for Azeroth Raids
    { mountName = "G.M.O.D.", itemID = 166518, mountID = 1217, spellID = 289083, raidName = "Battle of Dazar'alor", expansion = "Battle for Azeroth", bossName = "High Tinker Mekkatorque", dropRate = "~1%", difficulty = "Mythic", location = "Zuldazar", statisticIds = { 13382 }, contentType = "Raid" },
    { mountName = "Glacial Tidestorm", itemID = 166705, mountID = 1219, spellID = 289555, raidName = "Battle of Dazar'alor", expansion = "Battle for Azeroth", bossName = "Lady Jaina Proudmoore", dropRate = "~1%", difficulty = "Mythic", location = "Zuldazar", statisticIds = { 12745 }, contentType = "Raid" },
    { mountName = "Surf Jelly", itemID = 169201, mountID = 1169, spellID = 278979, raidName = "The Eternal Palace", expansion = "Battle for Azeroth", bossName = "Lady Ashvane", dropRate = "~1%", difficulty = "Mythic", location = "Nazjatar", contentType = "Raid" },
    { mountName = "Silent Glider", itemID = 174754, mountID = 316275, spellID = 316275, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "Il'gynoth", dropRate = "~1%", difficulty = "Mythic", location = "Uldum/Vale of Eternal Blossoms", contentType = "Raid" },
    { mountName = "Loyal Gorger", itemID = 174842, mountID = 316339, spellID = 316339, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "Vexiona", dropRate = "~1%", difficulty = "Mythic", location = "Uldum/Vale of Eternal Blossoms", contentType = "Raid" },
    { mountName = "Ny'alotha Allseer", itemID = 174872, mountID = 1293, spellID = 308814, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "N'Zoth the Corruptor", dropRate = "~1%", difficulty = "Mythic", location = "Uldum/Vale of Eternal Blossoms", statisticIds = { 13372, 13373, 13374, 13379 }, contentType = "Raid" },
    
    -- Shadowlands Raids
    { mountName = "Sanctum Gloomcharger", itemID = 186656, mountID = 1500, spellID = 354351, raidName = "Castle Nathria", expansion = "Shadowlands", bossName = "Sire Denathrius", dropRate = "~1%", difficulty = "Normal", location = "Revendreth", statisticIds = { 15145, 15144, 15147, 15146 }, contentType = "Raid" },
    { mountName = "Vengeance", itemID = 186642, mountID = 351195, spellID = 351195, raidName = "Sanctum of Domination", expansion = "Shadowlands", bossName = "Sylvanas Windrunner", dropRate = "~1%", difficulty = "Mythic", location = "The Maw", statisticIds = { 15176 }, contentType = "Raid" },
    { mountName = "Zereth Overseer", itemID = 190768, mountID = 1587, spellID = 368158, raidName = "Sepulcher of the First Ones", expansion = "Shadowlands", bossName = "The Jailer", dropRate = "~1%", difficulty = "Mythic", location = "Zereth Mortis", statisticIds = { 15467 }, contentType = "Raid" },
    
    -- Dragonflight Raids
    { mountName = "Anu'relos, Flame's Guidance", itemID = 208153, mountID = 1818, spellID = 424484, raidName = "Amirdrassil, the Dream's Hope", expansion = "Dragonflight", bossName = "Fyrakk", dropRate = "~1%", difficulty = "Mythic", location = "Emerald Dream", contentType = "Raid" },
    
    -- The War Within Raids
    { mountName = "Sureki Skyrazor", itemID = 223274, mountID = 2219, spellID = 451486, raidName = "Nerub-ar Palace", expansion = "The War Within", bossName = "Queen Ansurek", dropRate = "~1%", difficulty = "Normal", location = "Azj-Kahet", statisticIds = { 40295, 40296, 40297, 40298 }, contentType = "Raid" },
    { mountName = "Prototype A.S.M.R.", itemID = 223505, mountID = 2507, spellID = 1221155, raidName = "Liberation of Undermine", expansion = "The War Within", bossName = "Chrome King Gallywix", dropRate = "~1%", difficulty = "Mythic", location = "Undermine", contentType = "Raid" },
    { mountName = "Remembered Golden Gryphon", itemID = 223315, mountID = 441324, spellID = 441324, raidName = "Liberation of Undermine", expansion = "The War Within", bossName = "Chrome King Gallywix", dropRate = "100%", difficulty = "Mythic", location = "Undermine", contentType = "Raid" },
    
    -- ======================================
    -- DUNGEON BOSS DROPS
    -- ======================================
    
    -- Classic Dungeons
    { mountName = "Rivendare's Deathcharger", itemID = 13335, mountID = 17481, spellID = 17481, raidName = "Stratholme", expansion = "Classic", bossName = "Baron Rivendare", dropRate = "~1%", difficulty = "Normal", location = "Eastern Plaguelands", contentType = "Dungeon" },
    
    -- The Burning Crusade Dungeons
    { mountName = "Raven Lord", itemID = 32768, mountID = 41252, spellID = 41252, raidName = "Sethekk Halls", expansion = "The Burning Crusade", bossName = "Anzu", dropRate = "~1%", difficulty = "Heroic", location = "Terokkar Forest", contentType = "Dungeon" },
    { mountName = "Swift White Hawkstrider", itemID = 35513, mountID = 46628, spellID = 46628, raidName = "Magister's Terrace", expansion = "The Burning Crusade", bossName = "Kael'thas Sunstrider", dropRate = "~1%", difficulty = "Heroic", location = "Isle of Quel'Danas", contentType = "Dungeon" },
    
    -- Wrath of the Lich King Dungeons
    { mountName = "Blue Proto-Drake", itemID = 44151, mountID = 59996, spellID = 59996, raidName = "Utgarde Pinnacle", expansion = "Wrath of the Lich King", bossName = "Skadi the Ruthless", dropRate = "~1%", difficulty = "Heroic", location = "Howling Fjord", contentType = "Dungeon" },
    
    -- Cataclysm Dungeons
    { mountName = "Vitreous Stone Drake", itemID = 63043, mountID = 88746, spellID = 88746, raidName = "The Stonecore", expansion = "Cataclysm", bossName = "Slabhide", dropRate = "~1%", difficulty = "Heroic", location = "Deepholm", contentType = "Dungeon" },
    { mountName = "Drake of the North Wind", itemID = 63040, mountID = 88742, spellID = 88742, raidName = "The Vortex Pinnacle", expansion = "Cataclysm", bossName = "Altairus", dropRate = "~1%", difficulty = "Heroic", location = "Uldum", contentType = "Dungeon" },
    { mountName = "Armored Razzashi Raptor", itemID = 68823, mountID = 96491, spellID = 96491, raidName = "Zul'Gurub", expansion = "Cataclysm", bossName = "Bloodlord Mandokir", dropRate = "~1%", difficulty = "Heroic", location = "Northern Stranglethorn", contentType = "Dungeon" },
    { mountName = "Swift Zulian Panther", itemID = 68824, mountID = 96499, spellID = 96499, raidName = "Zul'Gurub", expansion = "Cataclysm", bossName = "High Priestess Kilnara", dropRate = "~1%", difficulty = "Heroic", location = "Northern Stranglethorn", contentType = "Dungeon" },
    { mountName = "Amani Battle Bear", itemID = 69747, mountID = 98204, spellID = 98204, raidName = "Zul'Aman", expansion = "Cataclysm", bossName = "Timed Run Reward", dropRate = "100%", difficulty = "Heroic", location = "Ghostlands", contentType = "Dungeon" },
    
    -- Legion Dungeons
    { mountName = "Midnight", itemID = 142236, mountID = 229499, spellID = 229499, raidName = "Return to Karazhan", expansion = "Legion", bossName = "Attumen the Huntsman", dropRate = "~1%", difficulty = "Mythic", location = "Karazhan", statisticIds = { 12745 }, contentType = "Dungeon" },
    { mountName = "Smoldering Ember Wyrm", itemID = 142552, mountID = 231428, spellID = 231428, raidName = "Return to Karazhan", expansion = "Legion", bossName = "Nightbane", dropRate = "~1%", difficulty = "Mythic", location = "Karazhan", contentType = "Dungeon" },
    
    -- Battle for Azeroth Dungeons
    { mountName = "Aerial Unit R-21/X", itemID = 168830, mountID = 1227, spellID = 290718, raidName = "Operation: Mechagon", expansion = "Battle for Azeroth", bossName = "King Mechagon", dropRate = "~1%", difficulty = "Mythic", location = "Mechagon Island", statisticIds = { 13382 }, contentType = "Dungeon" },
    { mountName = "Mechagon Peacekeeper", itemID = 168826, mountID = 1252, spellID = 299158, raidName = "Operation: Mechagon", expansion = "Battle for Azeroth", bossName = "HK-8 Aerial Oppression Unit", dropRate = "~1%", difficulty = "Mythic", location = "Mechagon Island", contentType = "Dungeon" },
    { mountName = "Sharkbait", itemID = 166461, mountID = 995, spellID = 254813, raidName = "Freehold", expansion = "Battle for Azeroth", bossName = "Harlan Sweete", dropRate = "~1%", difficulty = "Mythic", location = "Tiragarde Sound", contentType = "Dungeon" },
    { mountName = "Underrot Crawg Harness", itemID = 160829, mountID = 1053, spellID = 273541, raidName = "The Underrot", expansion = "Battle for Azeroth", bossName = "Unbound Abomination", dropRate = "~1%", difficulty = "Mythic", location = "Nazmir", contentType = "Dungeon" },
    { mountName = "Mummified Raptor Skull", itemID = 159921, mountID = 1040, spellID = 266058, raidName = "Kings' Rest", expansion = "Battle for Azeroth", bossName = "King Dazar", dropRate = "~1%", difficulty = "Mythic", location = "Zuldazar", contentType = "Dungeon" },
    
    -- Shadowlands Dungeons
    { mountName = "Marrowfang", itemID = 181819, mountID = 1406, spellID = 336036, raidName = "The Necrotic Wake", expansion = "Shadowlands", bossName = "Nalthor the Rimebinder", dropRate = "~1%", difficulty = "Mythic", location = "Bastion", contentType = "Dungeon" },
    { mountName = "Cartel Master's Gearglider", itemID = 186638, mountID = 1481, spellID = 353263, raidName = "Tazavesh, the Veiled Market", expansion = "Shadowlands", bossName = "So'leah", dropRate = "~1%", difficulty = "Mythic", location = "The Veiled Market", contentType = "Dungeon" },
    { mountName = "Slime Serpent", itemID = 183608, mountID = 1445, spellID = 346141, raidName = "Plaguefall", expansion = "Shadowlands", bossName = "Margrave Stradama", dropRate = "~1%", difficulty = "Mythic", location = "Maldraxxus", contentType = "Dungeon" },
    
    -- Dragonflight Dungeons
    { mountName = "Reins of the Volcanic Stone Drake", itemID = 198825, mountID = 395387, spellID = 395387, raidName = "Neltharus", expansion = "Dragonflight", bossName = "Magmatusk", dropRate = "~1%", difficulty = "Mythic", location = "The Waking Shores", contentType = "Dungeon" },
    { mountName = "Reins of the Liberated Slyvern", itemID = 192799, mountID = 1553, spellID = 359622, raidName = "The Nokhud Offensive", expansion = "Dragonflight", bossName = "Teera and Maruuk", dropRate = "~1%", difficulty = "Mythic", location = "Ohn'ahran Plains", contentType = "Dungeon" },
    { mountName = "Subdued Seahawk", itemID = 192761, mountID = 374203, spellID = 374203, raidName = "Ruby Life Pools", expansion = "Dragonflight", bossName = "Kokia Blazehoof", dropRate = "~1%", difficulty = "Mythic", location = "The Waking Shores", contentType = "Dungeon" },
    { mountName = "Wick", itemID = 223315, mountID = 2204, spellID = 449264, raidName = "Darkflame Cleft", expansion = "Dragonflight", bossName = "The Darkness", dropRate = "~1%", difficulty = "Mythic", location = "Zaralek Cavern", contentType = "Dungeon" },
    
    -- ======================================
    -- WORLD BOSS DROPS
    -- ======================================
    
    -- Wrath of the Lich King World Drops
    { mountName = "White Polar Bear", itemID = 43962, mountID = 54753, spellID = 54753, raidName = "Daily Dungeon", expansion = "Wrath of the Lich King", bossName = "Daily Dungeon Reward", dropRate = "~1%", difficulty = "Normal", location = "Various", contentType = "World" },
    { mountName = "Reins of the Time-Lost Proto-Drake", itemID = 44168, mountID = 60002, spellID = 60002, raidName = "World Spawn", expansion = "Wrath of the Lich King", bossName = "Time-Lost Proto-Drake", dropRate = "100%", difficulty = "World", location = "The Storm Peaks", contentType = "World" },
    
    -- Cataclysm World Bosses
    { mountName = "Reins of the Phosphorescent Stone Drake", itemID = 63041, mountID = 88718, spellID = 88718, raidName = "Deepholm", expansion = "Cataclysm", bossName = "Aeonaxx", dropRate = "100%", difficulty = "World", location = "Deepholm", contentType = "World" },
    
    -- Mists of Pandaria World Bosses
    { mountName = "Reins of the Cobalt Primordial Direhorn", itemID = 94228, mountID = 138423, spellID = 138423, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Oondasta", dropRate = "~1%", difficulty = "World", location = "Isle of Giants", contentType = "World" },
    { mountName = "Reins of the Amber Primordial Direhorn", itemID = 94230, mountID = 138424, spellID = 138424, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Oondasta", dropRate = "~1%", difficulty = "World", location = "Isle of Giants", contentType = "World" },
    { mountName = "Reins of the Heavenly Onyx Cloud Serpent", itemID = 87771, mountID = 127158, spellID = 127158, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Sha of Anger", dropRate = "~1%", difficulty = "World", location = "Kun-Lai Summit", contentType = "World" },
    { mountName = "Reins of the Thundering Cobalt Cloud Serpent", itemID = 95057, mountID = 139442, spellID = 139442, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Nalak", dropRate = "~1%", difficulty = "World", location = "Isle of Thunder", contentType = "World" },
    { mountName = "Son of Galleon's Saddle", itemID = 89783, mountID = 130965, spellID = 130965, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Galleon", dropRate = "~1%", difficulty = "World", location = "Valley of the Four Winds", contentType = "World" },
    
    -- Warlords of Draenor World Bosses
    { mountName = "Solar Spirehawk", itemID = 116771, mountID = 171827, spellID = 171827, raidName = "Rukhmar", expansion = "Warlords of Draenor", bossName = "Rukhmar", dropRate = "~1%", difficulty = "World", location = "Spires of Arak", contentType = "World" },
    
    -- Special/Other
    { mountName = "Infinite Timereaver", itemID = 133543, mountID = 201098, spellID = 201098, raidName = "Timewalking Dungeons", expansion = "Warlords of Draenor", bossName = "Any Timewalking Boss", dropRate = "~0.01%", difficulty = "Timewalking", location = "Various", contentType = "Special" },
    
    -- ======================================
    -- HOLIDAY/EVENT BOSS DROPS
    -- ======================================
    
    -- Hallow's End Event
    { mountName = "Headless Horseman's Mount", itemID = 37012, mountID = 48025, spellID = 48025, raidName = "Hallow's End", expansion = "Holiday Event", bossName = "Headless Horseman", dropRate = "~0.5%", difficulty = "Holiday", location = "Scarlet Monastery", contentType = "Holiday" },
    
    -- Brewfest Event
    { mountName = "Swift Brewfest Ram", itemID = 33977, mountID = 43899, spellID = 43899, raidName = "Brewfest", expansion = "Holiday Event", bossName = "Coren Direbrew", dropRate = "~3%", difficulty = "Holiday", location = "Blackrock Depths", contentType = "Holiday" },
    { mountName = "Great Brewfest Kodo", itemID = 33976, mountID = 43900, spellID = 43900, raidName = "Brewfest", expansion = "Holiday Event", bossName = "Coren Direbrew", dropRate = "~3%", difficulty = "Holiday", location = "Blackrock Depths", contentType = "Holiday" },
    
    -- Love is in the Air Event
    { mountName = "Big Love Rocket", itemID = 50250, mountID = 71342, spellID = 71342, raidName = "Love is in the Air", expansion = "Holiday Event", bossName = "Apothecary Hummel", dropRate = "~0.03%", difficulty = "Holiday", location = "Shadowfang Keep", contentType = "Holiday" }
}

-- Count mounts by category
local raidMounts = 0
local dungeonMounts = 0
local worldMounts = 0
local holidayMounts = 0
local specialMounts = 0

for _, mount in ipairs(RaidMount.mountInstances) do
    if mount.contentType == "Raid" then
        raidMounts = raidMounts + 1
    elseif mount.contentType == "Dungeon" then
        dungeonMounts = dungeonMounts + 1
    elseif mount.contentType == "World" then
        worldMounts = worldMounts + 1
    elseif mount.contentType == "Holiday" then
        holidayMounts = holidayMounts + 1
    elseif mount.contentType == "Special" then
        specialMounts = specialMounts + 1
    end
end

print("RaidMount: Loaded " .. #RaidMount.mountInstances .. " boss drop mounts:")
print("  - " .. raidMounts .. " Raid mounts")
print("  - " .. dungeonMounts .. " Dungeon mounts") 
print("  - " .. worldMounts .. " World Boss mounts")
print("  - " .. specialMounts .. " Special mounts")
print("  - " .. holidayMounts .. " Holiday Event mounts")

return RaidMount

