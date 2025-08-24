local addonName, RaidMount = ...

-- Session tracking
local currentSessionID = 1
local lastSessionTime = 0
local SESSION_TIMEOUT = 3600 -- 1 hour timeout for new session

-- Initialize session tracking
function RaidMount.InitializeSessionTracking()
    if not RaidMountSaved then
        RaidMountSaved = {}
    end
    if not RaidMountSaved.currentSessionID then
        RaidMountSaved.currentSessionID = 1
    end
    if not RaidMountSaved.lastSessionTime then
        RaidMountSaved.lastSessionTime = 0
    end
    currentSessionID = RaidMountSaved.currentSessionID
    lastSessionTime = RaidMountSaved.lastSessionTime
end

-- Check if we need a new session
function RaidMount.CheckNewSession()
    local currentTime = time()
    if currentTime - lastSessionTime > SESSION_TIMEOUT then
        currentSessionID = currentSessionID + 1
        lastSessionTime = currentTime
        RaidMountSaved.currentSessionID = currentSessionID
        RaidMountSaved.lastSessionTime = lastSessionTime
    end
end

-- Get current session ID
function RaidMount.GetCurrentSessionID()
    RaidMount.CheckNewSession()
    return currentSessionID
end

-- Optimized task scheduler with better memory management
local taskScheduler = {
    tasks = {},
    frame = nil
}

function RaidMount.ScheduleDelayedTask(delay, func, taskId)
    -- Use C_Timer instead of custom task scheduler for better performance
    if taskId and taskScheduler.tasks[taskId] then
        taskScheduler.tasks[taskId] = nil
    end

    local timer = C_Timer.NewTimer(delay, function()
        if taskId then
            taskScheduler.tasks[taskId] = nil
        end
        local success, err = pcall(func)
        if not success then
            RaidMount.PrintAddonMessage("Task error (" .. (taskId or "unknown") .. "): " .. tostring(err))
        end
    end)
    
    if taskId then
        taskScheduler.tasks[taskId] = timer
    end
    
    return timer
end

-- Lazy initialization flags
local isInitialized = false
local isDataLoaded = false

-- Centralized function to get current character ID consistently
function RaidMount.GetCurrentCharacterID()
    local characterName = UnitName("player")
    local realmName = GetRealmName()
    
    -- Normalize realm name to prevent inconsistencies
    if not realmName or realmName == "Unknown" or realmName == "" then
        return characterName
    end
    
    return characterName .. "-" .. realmName
end

-- Clean up duplicate character entries in global mount data
function RaidMount.CleanupDuplicateCharacterNames()
    if not RaidMountAttempts then return end
    
    local cleanedCount = 0
    
    -- Iterate through all mount tracking keys
    for trackingKey, attemptData in pairs(RaidMountAttempts) do
        if type(attemptData) == "table" and attemptData.characters then
            local characterMap = {}
            local duplicates = {}
            
            -- Find duplicate character names within this mount
            for charName, charData in pairs(attemptData.characters) do
                local charNameOnly = charName:match("([^%-]+)") or charName
                local realmName = charName:match("^[^%-]+%-([^%-]+)$") or "Unknown"
                local normalizedName = charNameOnly .. "-" .. realmName
                
                if characterMap[normalizedName] then
                    -- Found a duplicate
                    table.insert(duplicates, {
                        original = charName,
                        normalized = normalizedName,
                        existing = characterMap[normalizedName]
                    })
                else
                    characterMap[normalizedName] = charName
                end
            end
            
            -- Merge duplicate entries
            for _, duplicate in ipairs(duplicates) do
                local originalData = attemptData.characters[duplicate.original]
                local existingData = attemptData.characters[duplicate.existing]
                
                if originalData and existingData then
                    local originalCount = 0
                    local existingCount = 0
                    
                    -- Get attempt counts
                    if type(originalData) == "number" then
                        originalCount = originalData
                    elseif type(originalData) == "table" and originalData.count then
                        originalCount = originalData.count
                    end
                    
                    if type(existingData) == "number" then
                        existingCount = existingData
                    elseif type(existingData) == "table" and existingData.count then
                        existingCount = existingData.count
                    end
                    
                    -- Merge counts
                    local totalCount = originalCount + existingCount
                    
                    -- Update existing entry
                    if type(existingData) == "number" then
                        attemptData.characters[duplicate.existing] = totalCount
                    elseif type(existingData) == "table" then
                        existingData.count = totalCount
                        -- Use the most recent date
                        if originalData.lastUpdated and (not existingData.lastUpdated or originalData.lastUpdated > existingData.lastUpdated) then
                            existingData.lastUpdated = originalData.lastUpdated
                        end
                    end
                    
                    -- Remove duplicate entry
                    attemptData.characters[duplicate.original] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            
            -- Also clean up lastAttemptDates if they exist
            if attemptData.lastAttemptDates then
                for charName, _ in pairs(attemptData.lastAttemptDates) do
                    if not attemptData.characters[charName] then
                        -- Remove date entry for character that no longer exists
                        attemptData.lastAttemptDates[charName] = nil
                    end
                end
            end
            
            -- Also clean up classes if they exist
            if attemptData.classes then
                for charName, _ in pairs(attemptData.classes) do
                    if not attemptData.characters[charName] then
                        -- Remove class entry for character that no longer exists
                        attemptData.classes[charName] = nil
                    end
                end
            end
        end
    end
    
    if cleanedCount > 0 then
        RaidMount.PrintAddonMessage("Cleaned up " .. cleanedCount .. " duplicate character name entries")
    end
end

-- Clean up duplicate character entries
function RaidMount.CleanupDuplicateCharacters()
    if not RaidMountAttempts then return end
    
    local characterMap = {}
    local duplicates = {}
    
    -- Find all character entries and map them
    for key, data in pairs(RaidMountAttempts) do
        if type(key) == "string" and type(data) == "table" then
            -- Check if this looks like a character name (contains a dash for realm)
            if key:find("-") then
                local charName, realmName = key:match("([^%-]+)%-([^%-]+)")
                if charName and realmName then
                    local normalizedKey = charName .. "-" .. realmName
                    
                    if characterMap[normalizedKey] then
                        -- Found a duplicate
                        table.insert(duplicates, {
                            original = key,
                            normalized = normalizedKey,
                            existing = characterMap[normalizedKey]
                        })
                    else
                        characterMap[normalizedKey] = key
                    end
                end
            end
        end
    end
    
    -- Merge duplicate entries
    for _, duplicate in ipairs(duplicates) do
        local originalData = RaidMountAttempts[duplicate.original]
        local existingData = RaidMountAttempts[duplicate.existing]
        
        if originalData and existingData then
            -- Merge attempts data
            if originalData.attempts and existingData.attempts then
                for mountKey, attemptData in pairs(originalData.attempts) do
                    if not existingData.attempts[mountKey] then
                        existingData.attempts[mountKey] = attemptData
                    else
                        -- Merge attempt counts
                        existingData.attempts[mountKey].count = 
                            (existingData.attempts[mountKey].count or 0) + (attemptData.count or 0)
                        -- Use the most recent date
                        if attemptData.lastAttempt and (not existingData.attempts[mountKey].lastAttempt or 
                           attemptData.lastAttempt > existingData.attempts[mountKey].lastAttempt) then
                            existingData.attempts[mountKey].lastAttempt = attemptData.lastAttempt
                            existingData.attempts[mountKey].lastAttemptDate = attemptData.lastAttemptDate
                        end
                    end
                end
            end
            
            -- Merge other data
            if originalData.lastSeen and (not existingData.lastSeen or originalData.lastSeen > existingData.lastSeen) then
                existingData.lastSeen = originalData.lastSeen
            end
            
            -- Remove the duplicate entry
            RaidMountAttempts[duplicate.original] = nil
        end
    end
    
    if #duplicates > 0 then
        RaidMount.PrintAddonMessage("Cleaned up " .. #duplicates .. " duplicate character entries")
    end
end

-- Initialize core addon functionality
function RaidMount.InitializeCore()
    if isInitialized then return end

    -- Initialize SavedVariables with proper structure
    RaidMount.InitializeSavedVariables()

    -- Clear tooltip cache on addon load to ensure fresh data
    if RaidMount.ClearTooltipCache then
        RaidMount.ClearTooltipCache()
    end

    -- Clean up any duplicate character entries
    if RaidMount.CleanupDuplicateCharacters then
        RaidMount.CleanupDuplicateCharacters()
    end
    
    -- Clean up duplicate character names in global mount data
    if RaidMount.CleanupDuplicateCharacterNames then
        RaidMount.CleanupDuplicateCharacterNames()
    end

    -- NEW: Proper character-specific tracking
    local currentCharacter = RaidMount.GetCurrentCharacterID() -- Use the new function
    if currentCharacter then
        -- Ensure character data structure exists
        if not RaidMountAttempts[currentCharacter] then
            RaidMountAttempts[currentCharacter] = {
            class = select(2, UnitClass("player")),
                faction = UnitFactionGroup("player"),
                level = UnitLevel("player"),
                lastSeen = date("%Y-%m-%d"),
                attempts = {}, -- Per-mount attempt tracking
                lockouts = {}, -- Current lockout data
                mountCollection = {}, -- Mounts collected by this character
                statistics = {} -- Blizzard statistics for this character
            }
        else
            -- Update existing character data
            RaidMountAttempts[currentCharacter].lastSeen = date("%Y-%m-%d")
            RaidMountAttempts[currentCharacter].class = select(2, UnitClass("player"))
            RaidMountAttempts[currentCharacter].faction = UnitFactionGroup("player")
            RaidMountAttempts[currentCharacter].level = UnitLevel("player")
        end
        
        -- Store current lockout data for this character
        RaidMountAttempts[currentCharacter].lockouts = {}
        for i = 1, GetNumSavedInstances() do
            local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, instanceMapID = GetSavedInstanceInfo(i)
            
            if name and (locked or extended) then
                RaidMountAttempts[currentCharacter].lockouts[name] = {
                    difficulty = difficultyName,
                    difficultyID = difficulty,
                    locked = locked,
                    extended = extended,
                    reset = reset,
                    isRaid = isRaid,
                    instanceID = id,
                    mapID = instanceMapID,
                    progress = string.format("%d/%d", encounterProgress or 0, numEncounters or 0),
                    bossesKilled = encounterProgress or 0,
                    totalBosses = numEncounters or 0,
                    lastUpdated = time()
                }
            end
        end
        
        -- Populate character's mount collection
        RaidMountAttempts[currentCharacter].mountCollection = {}
        for i = 1, C_MountJournal.GetNumMounts() do
            local creatureName, spellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = C_MountJournal.GetMountInfoByID(i)
            if isCollected then
                RaidMountAttempts[currentCharacter].mountCollection[spellID] = {
                    name = creatureName,
                    icon = icon,
                    collectedDate = date("%Y-%m-%d")
                }
            end
        end
        
        -- Populate character's statistics data
        RaidMountAttempts[currentCharacter].statistics = {}
        if RaidMount.mountInstances then
            for _, mount in ipairs(RaidMount.mountInstances) do
                local trackingKey = mount.spellID
                if trackingKey then
                    local statisticsToCheck = mount.statisticIds
                    if mount.statisticIdsByDifficulty then
                        statisticsToCheck = {}
                        for _, diffStats in pairs(mount.statisticIdsByDifficulty) do
                            if type(diffStats) == "table" then
                                for _, statId in ipairs(diffStats) do
                                    table.insert(statisticsToCheck, statId)
                                end
                            end
                        end
                    end
                    
                    if statisticsToCheck and type(statisticsToCheck) == "table" then
                        local maxAttempts = 0
                        local usedStatId = nil
                        
                        for _, statId in ipairs(statisticsToCheck) do
                            local success, statValue = pcall(GetStatisticValue, statId)
                            if success and statValue and statValue > maxAttempts then
                                maxAttempts = statValue
                                usedStatId = statId
                            end
                        end
                        
                        if maxAttempts > 0 then
                            RaidMountAttempts[currentCharacter].statistics[trackingKey] = {
                                mountName = mount.mountName,
                                attempts = maxAttempts,
                                statId = usedStatId,
                                lastUpdated = time()
                            }
                        end
                    end
                end
            end
        end
        
        -- Update RaidMountSaved logged characters
        if not RaidMountSaved.loggedCharacters then
            RaidMountSaved.loggedCharacters = {}
        end
        
        RaidMountSaved.loggedCharacters[currentCharacter] = {
            class = select(2, UnitClass("player")),
            lastLogin = time(),
            realm = GetRealmName(),
            level = UnitLevel("player"),
            faction = UnitFactionGroup("player")
        }
        
        -- Initialize cross-character lockout storage
        if not RaidMountSaved.characterLockouts then
            RaidMountSaved.characterLockouts = {}
        end
        
        -- Store detailed lockout data per-character, per-instance, per-difficulty
        if RaidMount.SaveCharacterLockouts then
            RaidMount.SaveCharacterLockouts()
        end
        
        -- Update cross-character lockout data
        if RaidMount.UpdateCrossCharacterLockouts then
            RaidMount.UpdateCrossCharacterLockouts()
        end
        
        RaidMount.PrintAddonMessage("Character data updated for " .. currentCharacter)
    end

    isInitialized = true
    RaidMount.PrintAddonMessage(RaidMount.L("LOADED_MESSAGE", RaidMount.ADDON_VERSION))
end

-- Optimized data loading with proper dependency checking
function RaidMount.LoadDataAsync()
    if isDataLoaded then return end

    -- Check dependencies with consolidated retry
    local function checkDependencies()
        return RaidMount.mountInstances and
            RaidMount.Coordinates and
            RaidMount.PlayerHasMount and
            RaidMount.GetRaidLockout
    end

    if not checkDependencies() then
        RaidMount.ScheduleDelayedTask(0.5, RaidMount.LoadDataAsync, "load_data_retry")
        return
    end

    -- Initialize performance optimizations
    if RaidMount.InitializePerformanceOptimizations then
        RaidMount.InitializePerformanceOptimizations()
    end

    -- Spread heavy operations with proper scheduling
    RaidMount.ScheduleDelayedTask(0.1, function()
        RaidMount.InitializeFromStatistics()
        -- NEW: Populate character-specific mount data
        RaidMount.PopulateCharacterMountData()
    end, "init_statistics")

    RaidMount.ScheduleDelayedTask(0.3, function()
        RaidMount.RefreshMountCollection()
        isDataLoaded = true
    end, "scan_collection")
end

-- Ensure initialization when needed
function RaidMount.EnsureInitialized()
    if not isInitialized then
        RaidMount.InitializeCore()
    end
    if not isDataLoaded then
        RaidMount.LoadDataAsync()
    end
end

-- Legacy function for compatibility
function RaidMount.InitializeAddon()
    RaidMount.InitializeCore()
    RaidMount.LoadDataAsync()
end

-- Initialize Attempts After Player Login
function RaidMount.ShowVersionMessage()
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r v" .. RaidMount.ADDON_VERSION)
end

-- Optimized event frame with better event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_EXPANSION_LEVEL")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RaidMount" then
        -- Only initialize core on addon load
        RaidMount.InitializeCore()
    elseif event == "PLAYER_LOGIN" then
        RaidMount.ShowVersionMessage()
        -- Delay heavy data loading until after login
        C_Timer.After(2, RaidMount.LoadDataAsync)
        -- Update lockout data after login
        C_Timer.After(3, function()
            if RaidMount.SaveCharacterLockouts then
                RaidMount.SaveCharacterLockouts()
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Save lockout data when entering world (covers login and zone changes)
        C_Timer.After(1, function()
            if RaidMount.SaveCharacterLockouts then
                RaidMount.SaveCharacterLockouts()
            end
        end)
    end
end)

-- Enhanced Boss Kill Tracking with better performance
local bossKillFrame = CreateFrame("Frame")
bossKillFrame:RegisterEvent("BOSS_KILL")
bossKillFrame:RegisterEvent("ENCOUNTER_END")
bossKillFrame:RegisterEvent("NEW_MOUNT_ADDED")
bossKillFrame:RegisterEvent("LOOT_OPENED")
bossKillFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
bossKillFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

bossKillFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "NEW_MOUNT_ADDED" then
        -- Handle new mount collection
        local mountID = ...
        if mountID then
            -- Play sound notification
            PlaySound(8959, "Master")
            
            -- Refresh mount collection data
            if RaidMount.RefreshMountCollection then
                RaidMount.RefreshMountCollection()
            end
            
            -- Update UI if it's open
            if RaidMount.PopulateUI then
                RaidMount.PopulateUI()
            end
            
            -- Print notification
                                        RaidMount.PrintAddonMessage(RaidMount.L("NEW_MOUNT_COLLECTED", mountID))
        end
        return
    elseif event == "LOOT_OPENED" then
        -- Scan loot window for mount items and play sound if found
        local foundMount = false
        for i = 1, GetNumLootItems() do
            local link = GetLootSlotLink(i)
            if link then
                local itemID = select(1, GetItemInfoInstant(link))
                if itemID and C_MountJournal and C_MountJournal.GetMountFromItem and C_MountJournal.GetMountFromItem(itemID) then
                    foundMount = true
                    break
                end
            end
        end
        if foundMount then
            PlaySound(29117, "Master")
        end
        return
    end
    
    -- Update lockout data when instance info changes
    if event == "UPDATE_INSTANCE_INFO" or event == "PLAYER_ENTERING_WORLD" then
        if RaidMount.UpdateCrossCharacterLockouts then
            C_Timer.After(1, RaidMount.UpdateCrossCharacterLockouts)
        end
        if event == "PLAYER_ENTERING_WORLD" then
            return -- Don't process encounter tracking for this event
        end
    end

    local encounterName, success, difficultyID
    if event == "ENCOUNTER_END" then
        local encounterID, encounterName_temp, difficultyID_temp, groupSize, success_temp = ...
        encounterName = encounterName_temp
        difficultyID = difficultyID_temp
        success = success_temp
        if not success then return end
    else
        return -- Ignore BOSS_KILL and any other events for attempt tracking
    end

    local characterID = RaidMount.GetCachedPlayerInfo()
    local currentTime = time()
    local hasFoundMatch = false

    -- Convert difficulty ID to string for comparison
    local difficultyName = "Normal"
    if difficultyID == 17 then
        difficultyName = "LFR"
    elseif difficultyID == 14 then
        difficultyName = "Normal"
    elseif difficultyID == 15 then
        difficultyName = "Heroic"
    elseif difficultyID == 16 then
        difficultyName = "Mythic"
    end

    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local bossToMatch = mount.bossName
        -- Check if this mount has difficulty-specific boss names
        if mount.bossNameByDifficulty and mount.bossNameByDifficulty[difficultyName] then
            bossToMatch = mount.bossNameByDifficulty[difficultyName]
        end

        if bossToMatch and encounterName and encounterName:lower():find(bossToMatch:lower(), 1, true) then
            hasFoundMatch = true
            RaidMount.RecordMountAttempt(mount, currentTime)
            break
        end
    end

    if not hasFoundMatch then
        -- Fallback: check if any mount matches the encounter name
        for _, mount in ipairs(RaidMount.mountInstances or {}) do
            if mount.bossName and encounterName and encounterName:lower():find(mount.bossName:lower(), 1, true) then
                RaidMount.RecordMountAttempt(mount, currentTime)
                break
            end
        end
    end
end)

-- Cleanup function for main addon
function RaidMount.CleanupMain()
    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnEvent", nil)
        eventFrame = nil
    end
    
    if bossKillFrame then
        bossKillFrame:UnregisterAllEvents()
        bossKillFrame:SetScript("OnEvent", nil)
        bossKillFrame = nil
    end
    
    -- Clear task scheduler
    if taskScheduler.tasks then
        for _, timer in pairs(taskScheduler.tasks) do
            if timer.Cancel then
                timer:Cancel()
            end
        end
        wipe(taskScheduler.tasks)
    end
    
    -- Clear cached data
    RaidMount.cachedPlayerInfo = nil
    isInitialized = false
    isDataLoaded = false
end

-- Master cleanup function for addon shutdown
function RaidMount.CleanupAddon()
    print("RaidMount: Starting addon cleanup...")

    -- Clean up UI components
    if RaidMount.CleanupUI then
        RaidMount.CleanupUI()
    end

    -- Clean up mount checking system
    if RaidMount.CleanupMountCheck then
        RaidMount.CleanupMountCheck()
    end

    -- Clean up tooltip system
    if RaidMount.CleanupTooltipSystem then
        RaidMount.CleanupTooltipSystem()
    end

    -- Clean up enhanced lockout system
    if RaidMount.CleanupEnhancedLockout then
        RaidMount.CleanupEnhancedLockout()
    end

    -- Clean up task scheduler
    if taskScheduler then
        if taskScheduler.tasks then
            wipe(taskScheduler.tasks)
        end
        if taskScheduler.frame then
            taskScheduler.frame:SetScript("OnUpdate", nil)
            taskScheduler.frame = nil
        end
    end

    -- Clean up event frames
    if eventFrame then
        eventFrame:UnregisterAllEvents()
        eventFrame:SetScript("OnEvent", nil)
    end

    if bossKillFrame then
        bossKillFrame:UnregisterAllEvents()
        bossKillFrame:SetScript("OnEvent", nil)
    end

    print("RaidMount: Addon cleanup complete")
end

-- Register cleanup on addon unload
local cleanupFrame = CreateFrame("Frame")
cleanupFrame:RegisterEvent("ADDON_LOADED")
cleanupFrame:RegisterEvent("PLAYER_LOGOUT")
cleanupFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == "RaidMount" then
        -- Addon loaded, register for logout
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGOUT" then
        -- Clean up on logout
        RaidMount.CleanupAddon()
    end
end)

 