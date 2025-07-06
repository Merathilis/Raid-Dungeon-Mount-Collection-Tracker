local addonName, RaidMount = ...
RaidMount.mountInstances = RaidMount.mountInstances or {}

RaidMount.mountInstances = {
    -- ======================================
    -- RAID BOSS DROPS
    -- ======================================
    
    -- Classic WoW Raids
    { mountName = "Red Qiraji Resonating Crystal", MountID = 26, spellID = 26054, raidName = "Temple of Ahn'Qiraj", expansion = "Classic", bossName = "Trash Mobs", dropRate = "~1%", difficulty = "Normal", location = "Silithus", description = "A rare crystalline formation that resonates with the ancient magic of the Qiraji empire.", contentType = "Raid", collectorsBounty = true },
    { mountName = "Onyxian Drake", MountID = 349, spellID = 69395, raidName = "Onyxia's Lair", expansion = "Classic", bossName = "Onyxia", dropRate = "~1%", difficulty = "Normal", location = "Dustwallow Marsh", statisticIds = { 1098 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Fiery Warhorse", MountID = 168, spellID = 36702, raidName = "Karazhan", expansion = "The Burning Crusade", bossName = "Attumen the Huntsman", dropRate = "~1%", difficulty = "Normal", location = "Deadwind Pass", description = "Was one of the most vicious steeds stabled in Karazhan.", statisticIds = { 1088 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Ashes of Al'ar", MountID = 183, spellID = 40192, raidName = "Tempest Keep", expansion = "The Burning Crusade", bossName = "Kael'thas Sunstrider", dropRate = "~1%", difficulty = "Normal", location = "Netherstorm", description = "Al'ar was the beloved pet of Kael'thas Sunstrider, who often boasted that death would never claim it. Perhaps he was right.", statisticIds = { 1088 }, contentType = "Raid", collectorsBounty = true },
    
    -- Wrath of the Lich King Raids
    { mountName = "Azure Drake", MountID = 246, spellID = 59567, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", description = "Believed to be the most beautiful of all dragonkind, the blues have suffered greatly at the hands of Malygos's madness.", statisticIds = { 1391, 1394 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Blue Drake", MountID = 247, spellID = 59568, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", description = "Believed to be the most beautiful of all dragonkind, the blues have suffered greatly at the hands of Malygos's madness.", statisticIds = { 1391, 1394 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Bronze Drake", MountID = 248, spellID = 59569, raidName = "Eye of Eternity", expansion = "Wrath of the Lich King", bossName = "Malygos", dropRate = "~1%", difficulty = "Normal", location = "Borean Tundra", description = "The bronze dragonflight has sacrificed much in their role as the shepherds of time.", statisticIds = { 1391, 1394 }, contentType = "Raid" },
    { mountName = "Black Drake", MountID = 253, spellID = 59650, raidName = "The Obsidian Sanctum", expansion = "Wrath of the Lich King", bossName = "Sartharion", dropRate = "~2%", difficulty = "Normal 10", location = "Dragonblight", description = "Sartharion's legacy lives on in the drakes he leaves behind.", statisticIds = { 1392, 1393 }, contentType = "Raid" },
    { mountName = "Twilight Drake", MountID = 250, spellID = 59571, raidName = "The Obsidian Sanctum", expansion = "Wrath of the Lich King", bossName = "Sartharion", dropRate = "~2%", difficulty = "Normal 25", location = "Dragonblight", description = "The twilight dragonflight stands as perhaps the most mysterious of all dragons.", statisticIds = { 1392, 1393 }, contentType = "Raid" },
    { mountName = "Mimiron's Head", MountID = 304, spellID = 63796, raidName = "Ulduar", expansion = "Wrath of the Lich King", bossName = "Yogg-Saron (0 Keepers)", dropRate = "~1%", difficulty = "Normal 25", location = "The Storm Peaks", description = "A token of titan craftsmanship hoarded by the Old God, Yogg-Saron. Currently the single largest mechanical gnome head in Azeroth.", statisticIds = { 2869, 2883 }, contentType = "Raid", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Invincible", MountID = 363, spellID = 72286, raidName = "Icecrown Citadel", expansion = "Wrath of the Lich King", bossName = "The Lich King", dropRate = "~1%", difficulty = "Heroic 25", location = "Icecrown", description = "The famous steed of Arthas Menethil, who serves its master in life and in death.  Riding him is truly a feat of strength.", statisticIds = { 4688 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Grand Black War Mammoth", MountID = 287, spellID = 61467, raidName = "Vault of Archavon", expansion = "Wrath of the Lich King", bossName = "Any Boss", dropRate = "~1%", difficulty = "Normal", location = "Wintergrasp", statisticIds = { 1753, 1754, 2870, 3236, 4074, 4075, 4657, 4658 }, contentType = "Raid", collectorsBounty = true },
    
    -- Cataclysm Raids
    { mountName = "Drake of the South Wind", MountID = 396, spellID = 88744, raidName = "Throne of the Four Winds", expansion = "Cataclysm", bossName = "Al'Akir", dropRate = "~1%", difficulty = "Normal", location = "Uldum", description = "The South Wind was known in ancient times to bring distress and misfortune to mortals.", statisticIds = { 5976, 5977 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Pureblood Fire Hawk", MountID = 415, spellID = 97493, raidName = "Firelands", expansion = "Cataclysm", bossName = "Ragnaros", dropRate = "~1%", difficulty = "Normal", location = "Mount Hyjal", description = "Ragnaros the Firelord was among the most ancient and powerful of his kind; a creature of fire and hatred whose very presence scorched the air.", statisticIds = { 5970, 5971 }, contentType = "Raid", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Flametalon of Alysrazor", MountID = 425, spellID = 101542, raidName = "Firelands", expansion = "Cataclysm", bossName = "Alysrazor", dropRate = "~1%", difficulty = "Normal", location = "Mount Hyjal", description = "The giant roc Alysrazor soars on wings of flame through skies of fire, raining death on all below.", statisticIds = { 6161, 6162 }, contentType = "Raid", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Experiment 12-B", MountID = 445, spellID = 110039, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Ultraxion", dropRate = "~1%", difficulty = "Normal", location = "Caverns of Time", description = "An experiment commissioned by Deathwing, this drake was infused with pure twilight energy.", statisticIds = { 6168 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Blazing Drake", MountID = 442, spellID = 107842, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Deathwing", dropRate = "~1%", difficulty = "Normal", location = "Caverns of Time", description = "Deathwing's violent upheaval of Deepholm and other elemental realms created unique magical conditions that have given rise to drakes like none seen before.", statisticIds = { 5576, 5577 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Life-Binder's Handmaiden", MountID = 444, spellID = 107845, raidName = "Dragon Soul", expansion = "Cataclysm", bossName = "Deathwing", dropRate = "~1%", difficulty = "Heroic", location = "Caverns of Time", description = "Alexstrasza's Handmaidens are known for bringing hope to dark places and healing grievous wounds.", statisticIds = { 6167, 6168 }, contentType = "Raid", collectorsBounty = true },
    
    -- Mists of Pandaria Raids
    { mountName = "Astral Cloud Serpent", MountID = 478, spellID = 127170, raidName = "Mogu'shan Vaults", expansion = "Mists of Pandaria", bossName = "Elegon", dropRate = "~1%", difficulty = "Normal", location = "Kun-Lai Summit", description = "Legends say that when the mogu's dominion over Pandaria was crumbling, the star-touched Elegon was the last of the great mogu spirits to fall.", statisticIds = { 6797, 6798, 7924, 7923 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Clutch of Ji-Kun", MountID = 543, spellID = 139448, raidName = "Throne of Thunder", expansion = "Mists of Pandaria", bossName = "Ji-Kun", dropRate = "~1%", difficulty = "Normal", location = "Isle of Thunder", description = "A matriarch of the Pandaren crane, Ji-Kun watched over the clutch and cared for her young.", statisticIds = { 8171, 8169, 8172, 8170 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Spawn of Horridon", MountID = 531, spellID = 136471, raidName = "Throne of Thunder", expansion = "Mists of Pandaria", bossName = "Horridon", dropRate = "~1%", difficulty = "Normal", location = "Isle of Thunder", description = "The Zandalari bred Horridon to be the perfect weapon. His spawn carry the same ruthless drive for destruction.", statisticIds = { 8148, 8149, 8150, 8151, 8152 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Kor'kron Juggernaut", MountID = 559, spellID = 148417, raidName = "Siege of Orgrimmar", expansion = "Mists of Pandaria", bossName = "Garrosh Hellscream", dropRate = "~1%", difficulty = "Mythic", location = "Vale of Eternal Blossoms", description = "The pinnacle of goblin engineering, this war machine was commissioned by Garrosh Hellscream for the siege of Orgrimmar.", statisticIds = { 8638, 8637 }, contentType = "Raid", collectorsBounty = true },
    
    -- Warlords of Draenor Raids
    { mountName = "Ironhoof Destroyer", MountID = 613, spellID = 171621, raidName = "Blackrock Foundry", expansion = "Warlords of Draenor", bossName = "Blackhand", dropRate = "~1%", difficulty = "Mythic", location = "Gorgrond", description = "A trophy taken from the defeated Warlord Blackhand. This massive gronn was bred for war.", statisticIds = { 9365 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Felsteel Annihilator", MountID = 751, spellID = 182912, raidName = "Hellfire Citadel", expansion = "Warlords of Draenor", bossName = "Archimonde", dropRate = "~1%", difficulty = "Mythic", location = "Tanaan Jungle", description = "Even the Burning Legion considers this war machine to be the pinnacle of fel technology.", statisticIds = { 10252 }, contentType = "Raid", collectorsBounty = true },
    
    -- Legion Raids
    { mountName = "Felblaze Infernal", MountID = 791, spellID = 213134, raidName = "The Nighthold", expansion = "Legion", bossName = "Gul'dan", dropRate = "~1%", difficulty = "Normal", location = "Suramar", description = "The Illidari were able to break one of these fiery beasts for use as an unstoppable, fearless mount against the Legion.", statisticIds = { 10977, 10978, 10979, 10980 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Hellfire Infernal", MountID = 633, spellID = 171827, raidName = "The Nighthold", expansion = "Legion", bossName = "Gul'dan", dropRate = "~1%", difficulty = "Mythic", location = "Suramar", description = "From the bowels of the nether is summoned a creature of pure hatred, bent on burning down any life in its way.", statisticIds = { 10977, 10978, 10979, 10980 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Abyss Worm", MountID = 899, spellID = 232519, raidName = "Tomb of Sargeras", expansion = "Legion", bossName = "Mistress Sassz'ine", dropRate = "~1%", difficulty = "Mythic", location = "Broken Shore", description = "The shadows that trail off of its scales are otherworldly, is this creature from the depths of Azeroth's oceans?", statisticIds = { 11893, 11894, 11895, 11896 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Antoran Charhound", MountID = 971, spellID = 253088, raidName = "Antorus, the Burning Throne", expansion = "Legion", bossName = "Felhounds of Sargeras", dropRate = "~1%", difficulty = "Mythic", location = "Antoran Wastes", description = "Sargeras' own hound was maybe once a felstalker, but over the years the Dark Titan reforged and reshaped his companion into something much more powerful. When, at last, he was pleased with his creation, he set about creating more of the hounds, and imbuing them with shadow and flame.", contentType = "Raid", collectorsBounty = true },
    { mountName = "Shackled Ur'zul", MountID = 954, spellID = 243651, raidName = "Antorus, the Burning Throne", expansion = "Legion", bossName = "Argus the Unmaker", dropRate = "~1%", difficulty = "Mythic", location = "Antoran Wastes", description = "Formed from the tormented bodies and souls of fallen members of the Army of the Light, the Ur'zul is both fascinating and horrifying.", contentType = "Raid", collectorsBounty = true },
    
    -- Battle for Azeroth Raids
    { mountName = "G.M.O.D.", MountID = 1217, spellID = 289083, raidName = "Battle of Dazar'alor", expansion = "Battle for Azeroth", bossName = "High Tinker Mekkatorque", dropRate = "~1%", difficulty = "Normal", location = "Dazar'alor", description = "The Gallywix Mecha of Death is a marvel of goblin engineering, and a testament to the power of greed.", statisticIds = { 13317, 13318 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Glacial Tidestorm", MountID = 1219, spellID = 289555, raidName = "Battle of Dazar'alor", expansion = "Battle for Azeroth", bossName = "Lady Jaina Proudmoore", dropRate = "~1%", difficulty = "Mythic", location = "Dazar'alor", description = "A manifestation of Jaina's mastery over frost magic, this elemental mount is as beautiful as it is deadly.", statisticIds = { 13317, 13318 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Surf Jelly", MountID = 1169, spellID = 278979, raidName = "The Eternal Palace", expansion = "Battle for Azeroth", bossName = "Lady Ashvane", dropRate = "~1%", difficulty = "Mythic", location = "Nazjatar", description = "The time between being stung and being enveloped and devoured is short enough to consider not swimming in the Great Sea.", statisticIds = { 13600, 13601, 13602, 13603 }, contentType = "Raid" },
    { mountName = "Silent Glider", MountID = 1257, spellID = 300149, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "Il'gynoth", dropRate = "~1%", difficulty = "Mythic", location = "Uldum/Vale of Eternal Blossoms", description = "A rare sight. Most disappeared once Baron Rivendare ruled in Stratholme.", contentType = "Raid" },
    { mountName = "Loyal Gorger", MountID = 1391, spellID = 333027, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "Vexiona", dropRate = "~1%", difficulty = "Mythic", location = "Uldum/Vale of Eternal Blossoms", description = "A remnant of the Black Empire's past, these precursors of the abyss worms are once again resurging with the rise of Ny'alotha.", statisticIds = { 14123, 14124, 14125, 14126 }, contentType = "Raid" },
    { mountName = "Ny'alotha Allseer", MountID = 1293, spellID = 308814, raidName = "Ny'alotha, the Waking City", expansion = "Battle for Azeroth", bossName = "N'Zoth the Corruptor", dropRate = "~1%", difficulty = "Mythic", location = "Vale of Eternal Blossoms", description = "A manifestation of N'Zoth's all-seeing corruption, this mount serves as a reminder of the Old God's influence.", statisticIds = { 14082, 14083 }, contentType = "Raid", collectorsBounty = true },
    
    -- Shadowlands Raids
    { mountName = "Sanctum Gloomcharger", MountID = 1500, spellID = 354351, raidName = "Castle Nathria", expansion = "Shadowlands", bossName = "Sire Denathrius", dropRate = "~1%", difficulty = "Normal", location = "Revendreth", description = "The denizens of Revendreth are well accustomed to the finer things in afterlife.", statisticIds = { 14455, 14456, 14457, 14458 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Vengeance", MountID = 1471, spellID = 351195, raidName = "Sanctum of Domination", expansion = "Shadowlands", bossName = "Sylvanas Windrunner", dropRate = "~1%", difficulty = "Mythic", location = "The Maw", description = "It is only fitting that the Banshee Queen's personal mount shows her new dark powers, as terrifying as its master's scream.", statisticIds = { 15173, 15174, 15175, 15176 }, contentType = "Raid", collectorsBounty = true },
    { mountName = "Zereth Overseer", MountID = 1587, spellID = 368158, raidName = "Sepulcher of the First Ones", expansion = "Shadowlands", bossName = "The Jailer", dropRate = "~1%", difficulty = "Mythic", location = "Zereth Mortis", description = "An automa created in Zereth Mortis by the First Ones to oversee the realms of Death.", statisticIds = { 15467 }, contentType = "Raid", collectorsBounty = true },
    
    -- Dragonflight Raids
    { mountName = "Anu'relos, Flame's Guidance", MountID = 1818, spellID = 424484, raidName = "Amirdrassil, the Dream's Hope", expansion = "Dragonflight", bossName = "Fyrakk", dropRate = "~1%", difficulty = "Mythic", location = "Emerald Dream", description = "A mount born from the flames of Fyrakk's corruption, yet somehow still burning with hope for redemption.", contentType = "Raid" },
    
    -- The War Within Raids
    { mountName = "Sureki Skyrazor", MountID = 2219, spellID = 451486, raidName = "Nerub-ar Palace", expansion = "The War Within", bossName = "Queen Ansurek", dropRate = "~1%", difficulty = "Normal", location = "Azj-Kahet", description = "A terrifying nerubian mount that patrols the darkest depths of Azj-Kahet.", statisticIds = { 40295, 40296, 40297, 40298 }, contentType = "Raid" },
    { mountName = "Prototype A.S.M.R.", MountID = 2507, spellID = 1221155, raidName = "Liberation of Undermine", expansion = "The War Within", bossName = "Chrome King Gallywix", dropRate = "~1%", difficulty = "Mythic", location = "Undermine", description = "An experimental goblin engineering marvel that defies both logic and safety regulations.", contentType = "Raid" },
    { mountName = "The Big G", MountID = 2487, spellID = 1217760, raidName = "Liberation of Undermine", expansion = "The War Within", bossName = "Chrome King Gallywix", dropRate = "~1%", difficulty = "Mythic", location = "Undermine", description = "Doesn't actually seem like anything too special under the hood, but just wait until those goblins next door see you pull up for the next pool party.", contentType = "Raid" },

    
    -- ======================================
    -- DUNGEON BOSS DROPS
    -- ======================================
    
    -- Classic Dungeons
    { mountName = "Rivendare's Deathcharger", MountID = 69, spellID = 17481, raidName = "Stratholme", expansion = "Classic", bossName = "Baron Rivendare", dropRate = "~1%", difficulty = "Normal", location = "Eastern Plaguelands", description = "When Baron Rivendare became a champion of the Scourge, he condemned his favorite horse to join him in undeath.", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Swift Razzashi Raptor", MountID = 110, spellID = 24242, raidName = "Zul'Gurub", expansion = "Classic", bossName = "Bloodlord Mandokir", dropRate = "~1%", difficulty = "Normal", location = "Stranglethorn Vale", description = "The only known Razzashi Raptors were said to have been in the custody of Bloodlord Mandokir in Zul'Gurub. This species of raptor has not been seen in many years.", contentType = "Dungeon" },
    
    -- The Burning Crusade Dungeons
    { mountName = "Raven Lord", MountID = 185, spellID = 41252, raidName = "Sethekk Halls", expansion = "The Burning Crusade", bossName = "Anzu", dropRate = "~1%", difficulty = "Heroic", location = "Terokkar Forest", description = "The rest be forgotten to walk upon the ground, clipped wings and shame. -Word of the Raven", contentType = "Dungeon", collectorsBounty = true },
    { mountName = "Swift White Hawkstrider", MountID = 213, spellID = 46628, raidName = "Magister's Terrace", expansion = "The Burning Crusade", bossName = "Kael'thas Sunstrider", dropRate = "~1%", difficulty = "Heroic", location = "Isle of Quel'Danas", description = "I may question Prince Kael'thas's loyalties, but never his style. -Elrodan", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    
    -- Wrath of the Lich King Dungeons
    { mountName = "Blue Proto-Drake", MountID = 264, spellID = 59996, raidName = "Utgarde Pinnacle", expansion = "Wrath of the Lich King", bossName = "Skadi the Ruthless", dropRate = "~1%", difficulty = "Heroic", location = "Howling Fjord", description = "The Storm Peaks! There we will find the beast strong enough to bear me into battle. -Skadi the Ruthless", contentType = "Dungeon", collectorsBounty = true },
    { mountName = "Green Proto-Drake", MountID = 278, spellID = 61294, raidName = "Utgarde Pinnacle", expansion = "Wrath of the Lich King", bossName = "Cracked Egg", dropRate = "~1%", difficulty = "Heroic", location = "Howling Fjord", description = "The vrykul were the first to recognize their potential. Or maybe the second, depending on how you look at it.", contentType = "Dungeon" },
    
    -- Cataclysm Dungeons
    { mountName = "Vitreous Stone Drake", MountID = 397, spellID = 88746, raidName = "The Stonecore", expansion = "Cataclysm", bossName = "Slabhide", dropRate = "~1%", difficulty = "Heroic", location = "Deepholm", description = "Those would be perfect in a pendant, and that would make a fantastic ring. Let me know if this thing sheds or molts or whatever. -Kalinda", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Drake of the North Wind", MountID = 395, spellID = 88742, raidName = "The Vortex Pinnacle", expansion = "Cataclysm", bossName = "Altairus", dropRate = "~1%", difficulty = "Heroic", location = "Uldum", description = "They sicken of the calm who know the storm.", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Grey Riding Camel", MountID = 400, spellID = 88750, raidName = "Feralas", expansion = "Cataclysm", bossName = "Dormus the Camel-Hoarder", dropRate = "~1%", difficulty = "World", location = "Feralas", description = "Fennimore Quigley is credited with milking the first camel and breaking the record for \"longest unintentional flight,\" all in the same afternoon.", contentType = "Dungeon" },
    { mountName = "Armored Razzashi Raptor", MountID = 410, spellID = 96491, raidName = "Zul'Gurub", expansion = "Cataclysm", bossName = "Bloodlord Mandokir", dropRate = "~1%", difficulty = "Heroic", location = "Stranglethorn Vale", description = "The purebred royal raptors of Zul'Gurub, these mounts have become a rare sight in Stranglethorn Vale.", contentType = "Dungeon", collectorsBounty = true },
    { mountName = "Swift Zulian Panther", MountID = 411, spellID = 96499, raidName = "Zul'Gurub", expansion = "Cataclysm", bossName = "High Priestess Kilnara", dropRate = "~1%", difficulty = "Heroic", location = "Stranglethorn Vale", description = "The jungle trolls have long coveted panther fangs, using them for rituals or as ingredients in mojos.", contentType = "Dungeon", collectorsBounty = true },
    { mountName = "Amani Battle Bear", MountID = 419, spellID = 98204, raidName = "Zul'Aman", expansion = "Cataclysm", bossName = "Timed Run Reward", dropRate = "100%", difficulty = "Heroic", location = "Ghostlands", description = "The Amani trolls decorate these ferocious mounts in magic amulets and ceremonial masks as a way to venerate the bear god Nalorakk.", contentType = "Dungeon" },
    
    -- Legion Dungeons
    { mountName = "Midnight", MountID = 875, spellID = 229499, raidName = "Return to Karazhan", expansion = "Legion", bossName = "Attumen the Huntsman", dropRate = "~1%", difficulty = "Mythic", location = "Deadwind Pass", description = "Still one of the most vicious steeds stabled in Karazhan.", contentType = "Dungeon", collectorsBounty = true },
    { mountName = "Smoldering Ember Wyrm", MountID = 883, spellID = 231428, raidName = "Return to Karazhan", expansion = "Legion", bossName = "Nightbane", dropRate = "~1%", difficulty = "Mythic", location = "Deadwind Pass", description = "A dragon of pure ember and ash, born from the depths of Karazhan's darkest corners.", contentType = "Dungeon" },
    { mountName = "Grove Warden", MountID = 764, spellID = 189999, raidName = "Legion Pre-Patch", expansion = "Legion", bossName = "Quest: Dark Waters", dropRate = "100%", difficulty = "Quest", location = "Moonglade", description = "These magical companions are the wardens of peaceful, primordial groves within the Emerald Dream.", contentType = "Special" },
    { mountName = "Vile Fiend", MountID = 955, spellID = 243652, raidName = "Antorus, the Burning Throne", expansion = "Legion", bossName = "Houndmaster Kerrax", dropRate = "~1%", difficulty = "Mythic", location = "Antoran Wastes", description = "Infused with acidic blood through a terrifying ritual, you can feel your control over this beast is tenuous at best.", statisticIds = { 11960, 11961, 11962, 12119 }, contentType = "Raid" },
    
    -- Battle for Azeroth Dungeons
    { mountName = "Aerial Unit R-21/X", MountID = 1227, spellID = 290718, raidName = "Operation: Mechagon", expansion = "Battle for Azeroth", bossName = "King Mechagon", dropRate = "~1%", difficulty = "Mythic", location = "Mechagon", description = "A flying machine of goblin engineering, designed for aerial combat and transportation.", contentType = "Dungeon" },
    { mountName = "Mechagon Peacekeeper", MountID = 1252, spellID = 299158, raidName = "Operation: Mechagon", expansion = "Battle for Azeroth", bossName = "HK-8 Aerial Oppression Unit", dropRate = "~1%", difficulty = "Mythic", location = "Mechagon", description = "A mechanical guardian of peace, though its methods are anything but peaceful.", contentType = "Dungeon" },
    { mountName = "Sharkbait", MountID = 1166, spellID = 266058, raidName = "Freehold", expansion = "Battle for Azeroth", bossName = "Harlan Sweete", dropRate = "~1%", difficulty = "Mythic", location = "Tiragarde Sound", description = "A prized parrot of the infamous pirate Harlan Sweete.", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Tomb Stalker", MountID = 1167, spellID = 266058, raidName = "Kings' Rest", expansion = "Battle for Azeroth", bossName = "King Dazar", dropRate = "~1%", difficulty = "Mythic", location = "Zuldazar", description = "An ancient construct that once guarded the tombs of Zandalar's greatest kings.", contentType = "Dungeon", collectorsBounty = "Drop rate not increased in Timewalking" },
    { mountName = "Underrot Crawg", MountID = 1169, spellID = 273541, raidName = "The Underrot", expansion = "Battle for Azeroth", bossName = "Unbound Abomination", dropRate = "~1%", difficulty = "Mythic", location = "Nazmir", description = "A vicious creature born from the corruption that plagues Nazmir.", contentType = "Dungeon", collectorsBounty = true },
    
    -- Shadowlands Dungeons
    { mountName = "Marrowfang", MountID = 1406, spellID = 336036, raidName = "The Necrotic Wake", expansion = "Shadowlands", bossName = "Nalthor the Rimebinder", dropRate = "~1%", difficulty = "Mythic", location = "Bastion", description = "A skeletal mount forged from the bones of the dead, bound by necromantic magic.", contentType = "Dungeon" },
    { mountName = "Cartel Master's Gearglider", MountID = 1481, spellID = 353263, raidName = "Tazavesh, the Veiled Market", expansion = "Shadowlands", bossName = "So'leah", dropRate = "~1%", difficulty = "Mythic", location = "Oribos", description = "A mechanical flying machine used by the cartel masters to navigate the Veiled Market.", contentType = "Dungeon" },
    { mountName = "Slime Serpent", MountID = 1445, spellID = 346141, raidName = "Plaguefall", expansion = "Shadowlands", bossName = "Margrave Stradama", dropRate = "~1%", difficulty = "Mythic", location = "Maldraxxus", description = "A serpentine mount composed entirely of living slime, constantly shifting and reforming.", contentType = "Dungeon" },
    
    -- Dragonflight Dungeons
    { mountName = "Volcanic Stone Drake", MountID = 198825, spellID = 88331, raidName = "Neltharus", expansion = "Dragonflight", bossName = "Magmatusk", dropRate = "~1%", difficulty = "Mythic", location = "Thaldraszus", description = "A drake forged from volcanic stone, its scales glow with the heat of molten lava.", contentType = "Dungeon" },
    { mountName = "Liberated Slyvern", MountID = 192799, spellID = 359622, raidName = "The Nokhud Offensive", expansion = "Dragonflight", bossName = "Teera and Maruuk", dropRate = "~1%", difficulty = "Mythic", location = "Ohn'ahran Plains", description = "A slyvern freed from the control of the Nokhud clan, now serving as a loyal mount.", contentType = "Dungeon" },
    { mountName = "Wick", MountID = 2204, spellID = 449264, raidName = "Darkflame Cleft", expansion = "Dragonflight", bossName = "The Darkness", dropRate = "~1%", difficulty = "Mythic", location = "Zaralek Cavern", description = "A mount born from the darkness itself, its form shifting between shadow and flame.", contentType = "Dungeon" },
    
    -- The War Within Dungeons
    { mountName = "Stonevault Mechsuit", MountID = 2119, spellID = 442358, raidName = "The Stonevault", expansion = "The War Within", bossName = "Quest: Repurposed, Restored", dropRate = "100%", difficulty = "Quest", location = "The Ringing Deeps", description = "Metal once ruined, restored to life by scrap and song.", contentType = "Special" },
    
    -- ======================================
    -- WORLD BOSS DROPS
    -- ======================================
    
    -- Wrath of the Lich King World Drops
    { mountName = "White Polar Bear", MountID = 237, spellID = 54753, raidName = "Daily Dungeon", expansion = "Wrath of the Lich King", bossName = "Daily Dungeon Reward", dropRate = "~1%", difficulty = "Normal", location = "Various", contentType = "World" },
    { mountName = "Time-Lost Proto-Drake", MountID = 44168, spellID = 60002, raidName = "World Spawn", expansion = "Wrath of the Lich King", bossName = "Time-Lost Proto-Drake", dropRate = "100%", difficulty = "World", location = "The Storm Peaks", contentType = "World" },
    
    -- Cataclysm World Bosses
    { mountName = "Phosphorescent Stone Drake", MountID = 63041, spellID = 88718, raidName = "Deepholm", expansion = "Cataclysm", bossName = "Aeonaxx", dropRate = "100%", difficulty = "World", location = "Deepholm", contentType = "World" },
    
    -- Mists of Pandaria World Bosses
    { mountName = "Cobalt Primordial Direhorn", MountID = 94228, spellID = 138423, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Oondasta", dropRate = "~1%", difficulty = "World", location = "Isle of Giants", statisticIds = { 8147 }, contentType = "World" },
    { mountName = "Amber Primordial Direhorn", MountID = 94230, spellID = 138424, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Oondasta", dropRate = "~1%", difficulty = "World", location = "Isle of Giants", statisticIds = { 8147 }, contentType = "World" },
    { mountName = "Heavenly Onyx Cloud Serpent", MountID = 87771, spellID = 127158, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Sha of Anger", dropRate = "~1%", difficulty = "World", location = "Kun-Lai Summit", statisticIds = { 6989 }, contentType = "World" },
    { mountName = "Thundering Cobalt Cloud Serpent", MountID = 95057, spellID = 139442, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Nalak", dropRate = "~1%", difficulty = "World", location = "Isle of Thunder", statisticIds = { 8146 }, contentType = "World" },
    { mountName = "Son of Galleon", MountID = 89783, spellID = 130965, raidName = "World Boss", expansion = "Mists of Pandaria", bossName = "Galleon", dropRate = "~1%", difficulty = "World", location = "Valley of the Four Winds", contentType = "World" },
    
    -- Warlords of Draenor World Bosses
    { mountName = "Solar Spirehawk", MountID = 634, spellID = 171828, raidName = "Rukhmar", expansion = "Warlords of Draenor", bossName = "Rukhmar", dropRate = "~1%", difficulty = "World", location = "Spires of Arak", statisticIds = { 9279 }, contentType = "World" },
    { mountName = "Warsong Direfang", MountID = 643, spellID = 171837, raidName = "Tanaan Jungle", expansion = "Warlords of Draenor", bossName = "Vengeance, Deathtalon, Terrorfist, Doomroller", dropRate = "~1%", difficulty = "World", location = "Tanaan Jungle", description = "Has a will of iron but is a sweetheart if you give it a clefthoof bone to chew on.", contentType = "World" },
    { mountName = "Infernal Direwolf", MountID = 758, spellID = 186305, raidName = "Hellfire Citadel", expansion = "Warlords of Draenor", bossName = "Achievement: Glory of the Hellfire Raider", dropRate = "100%", difficulty = "Mythic", location = "Tanaan Jungle", description = "A mighty wolf of Draenor, touched by the fel energies unleashed by Gul'dan in Tanaan Jungle. It has not gone completely mad... yet.", statisticIds = { 10202, 10203, 10204, 10206, 10207, 10208, 10210, 10211, 10212 }, contentType = "Raid" },
    
    -- Cataclysm World Bosses (Additional)
    { mountName = "Azure Worldchiller", MountID = 1798, spellID = 420097, raidName = "Tanaris", expansion = "Cataclysm", bossName = "Doomwalker", dropRate = "~1%", difficulty = "World", location = "Tanaris", description = "In the corners of Azeroth, stories are told of a dreaded dragon who swept a pall of torment over the land. In some versions of this story, his fiery presence brought cataclysmic death and destruction worldwide. In other versions, he is blue.", contentType = "World" },
    { mountName = "Illidari Doomhawk", MountID = 293, spellID = 62048, raidName = "Tanaris", expansion = "Cataclysm", bossName = "Doomwalker", dropRate = "~1%", difficulty = "World", location = "Tanaris", description = "Once a year, a rift in time appears, and strange things occur. The Illidari scouts and Doomwalker were quite surprised to find themselves in Tanaris.", contentType = "World" },
    
    -- Special/Other
    { mountName = "Infinite Timereaver", MountID = 781, spellID = 201098, raidName = "Timewalking Dungeons", expansion = "Warlords of Draenor", bossName = "Any Timewalking Boss", dropRate = "~0.01%", difficulty = "Timewalking", location = "Various", contentType = "Special" },
    
    -- ======================================
    -- HOLIDAY/EVENT BOSS DROPS
    -- ======================================
    
    -- Hallow's End Event
    { mountName = "Headless Horseman's Mount", MountID = 219, spellID = 48025, raidName = "Hallow's End", expansion = "Holiday Event", bossName = "Headless Horseman", dropRate = "~0.5%", difficulty = "Holiday", location = "Scarlet Monastery", description = "Be it into the flood, or into the fire, this one will go where you require.", contentType = "Holiday" },
    
    -- Brewfest Event
    { mountName = "Swift Brewfest Ram", MountID = 202, spellID = 43900, raidName = "Brewfest", expansion = "Holiday Event", bossName = "Coren Direbrew", dropRate = "~3%", difficulty = "Holiday", location = "Blackrock Depths", description = "Dwarves attribute this breed's even temperament to rigorous training, but other races argue that a daily diet of strong ale has something to do with it.", contentType = "Holiday" },
    { mountName = "Great Brewfest Kodo", MountID = 226, spellID = 49379, raidName = "Brewfest", expansion = "Holiday Event", bossName = "Coren Direbrew", dropRate = "~3%", difficulty = "Holiday", location = "Blackrock Depths", description = "Coren Direbrew won this prize after drinking a Tauren druid under the table - and the druid was in bear form.", contentType = "Holiday" },
    
    -- Love is in the Air Event
     
    { mountName = "X-45 Heartbreaker", MountID = 352, spellID = 71342, raidName = "Love is in the Air", expansion = "Holiday Event", bossName = "Apothecary Hummel", dropRate = "~0.03%", difficulty = "Holiday", location = "Shadowfang Keep", description = "Apothecary Hummel painted this masterpiece bright pink for an unrequited love.", contentType = "Holiday" },
    { mountName = "Love Witch's Sweeper", MountID = 2328, spellID = 472479, raidName = "Love is in the Air", expansion = "Holiday Event", bossName = "Apothecary Hummel", dropRate = "~1%", difficulty = "Holiday", location = "Shadowfang Keep", description = "A magical broomstick that carries the essence of love and romance through the air.", contentType = "Holiday" },
    
    -- Dragonflight World/Achievement Mounts
    { mountName = "Winter Night Dreamsaber", MountID = 1815, spellID = 424476, raidName = "Dreamseed Cache", expansion = "Dragonflight", bossName = "Dreamseed Cache", dropRate = "~1%", difficulty = "World", location = "Emerald Dream", description = "These nocturnal dreamsabers carry the chill of winter with them and will often hibernate for days on end if not otherwise awoken.", contentType = "World" }
}

-- Performance optimization: Create lookup tables for faster access
local mountLookupByID = {}
local mountLookupBySpellID = {}
local mountLookupByName = {}
local mountLookupByRaid = {}
local mountLookupByType = {
    Raid = {},
    Dungeon = {},
    World = {},
    Holiday = {},
    Special = {}
}

-- Build lookup tables
for i, mount in ipairs(RaidMount.mountInstances) do
    -- Index by MountID
    if mount.MountID then
        mountLookupByID[mount.MountID] = mount
    end
    
    -- Index by SpellID
    if mount.spellID then
        mountLookupBySpellID[mount.spellID] = mount
    end
    
    -- Index by name (case-insensitive)
    if mount.mountName then
        mountLookupByName[mount.mountName:lower()] = mount
    end
    
    -- Index by raid/dungeon name
    if mount.raidName then
        if not mountLookupByRaid[mount.raidName] then
            mountLookupByRaid[mount.raidName] = {}
        end
        table.insert(mountLookupByRaid[mount.raidName], mount)
    end
    
    -- Index by content type
    if mount.contentType and mountLookupByType[mount.contentType] then
        table.insert(mountLookupByType[mount.contentType], mount)
    end
end

-- Fast lookup functions
function RaidMount.GetMountByID(mountID)
    return mountLookupByID[mountID]
end

function RaidMount.GetMountBySpellID(spellID)
    return mountLookupBySpellID[spellID]
end

function RaidMount.GetMountByName(name)
    return mountLookupByName[name and name:lower()]
end

function RaidMount.GetMountsByRaid(raidName)
    return mountLookupByRaid[raidName] or {}
end

function RaidMount.GetMountsByType(contentType)
    return mountLookupByType[contentType] or {}
end

-- Cache mount collection status for faster lookups
local collectionCache = {}
local collectionCacheDirty = true

function RaidMount.UpdateCollectionCache()
    if not collectionCacheDirty then return end
    
    collectionCache = {}
    for _, mount in ipairs(RaidMount.mountInstances) do
        local key = mount.MountID or mount.spellID
        if key then
            collectionCache[key] = C_MountJournal.GetMountInfoByID(key) ~= nil
        end
    end
    collectionCacheDirty = false
end

function RaidMount.GetMountCollectionStatus(mountID)
    if collectionCacheDirty then
        RaidMount.UpdateCollectionCache()
    end
    return collectionCache[mountID] or false
end

function RaidMount.InvalidateCollectionCache()
    collectionCacheDirty = true
end

-- Statistics
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

return RaidMount

