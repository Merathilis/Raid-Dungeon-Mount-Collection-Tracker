local addonName, RaidMount = ...

-- Optimized statistics function with better error handling
local function GetStatisticValue(statisticId)
    if not statisticId then return 0 end

    local value = GetStatistic(statisticId)
    if value and value ~= "--" and tonumber(value) then
        return tonumber(value)
    end
    return 0
end

-- NEW: Populate character-specific mount data from statistics
function RaidMount.PopulateCharacterMountData()
    if not RaidMount.mountInstances then return end
    
    local currentCharacter = RaidMount.GetCurrentCharacterID()
    local characterClass = select(2, UnitClass("player"))
    
    -- Ensure character is logged in RaidMountSaved
    if not RaidMountSaved.loggedCharacters then
        RaidMountSaved.loggedCharacters = {}
    end
    
    if not RaidMountSaved.loggedCharacters[currentCharacter] then
        RaidMountSaved.loggedCharacters[currentCharacter] = {
            class = characterClass,
            lastLogin = time(),
            realm = GetRealmName()
        }
    end
    
    -- Update last login time
    RaidMountSaved.loggedCharacters[currentCharacter].lastLogin = time()
    RaidMountSaved.loggedCharacters[currentCharacter].class = characterClass
    
    -- Scan all mounts for statistics data
    for _, mount in ipairs(RaidMount.mountInstances) do
        local trackingKey = mount.spellID
        if trackingKey then
            -- Initialize attempt data if needed
            if not RaidMountAttempts[trackingKey] then
                RaidMountAttempts[trackingKey] = {
                    total = 0,
                    characters = {},
                    lastAttempt = nil,
                    collected = false,
                    statisticsInitialized = false
                }
            end
            
            local attemptData = RaidMountAttempts[trackingKey]
            
            -- Check if this character has any statistics for this mount
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
                
                -- If we found statistics data, populate character data
                if maxAttempts > 0 then
                    -- Initialize character data if needed
                    if not attemptData.characters[currentCharacter] then
                        attemptData.characters[currentCharacter] = {
                            count = 0,
                            lastUpdated = time(),
                            source = "blizzard_statistics"
                        }
                    end
                    
                    -- Update character data with statistics
                    local charData = attemptData.characters[currentCharacter]
                    if type(charData) == "number" then
                        -- Migrate old format
                        charData = {
                            count = charData,
                            lastUpdated = time(),
                            source = "blizzard_statistics"
                        }
                        attemptData.characters[currentCharacter] = charData
                    end
                    
                    -- Update count if statistics show higher value
                    if maxAttempts > charData.count then
                        charData.count = maxAttempts
                        charData.lastUpdated = time()
                        charData.source = "blizzard_statistics"
                    end
                    
                    -- Update total if needed
                    if maxAttempts > (attemptData.total or 0) then
                        attemptData.total = maxAttempts
                    end
                    
                    -- Initialize classes table if needed
                    if not attemptData.classes then
                        attemptData.classes = {}
                    end
                    attemptData.classes[currentCharacter] = characterClass
                    
                    -- Initialize last attempt dates if needed
                    if not attemptData.lastAttemptDates then
                        attemptData.lastAttemptDates = {}
                    end
                    attemptData.lastAttemptDates[currentCharacter] = date("%d/%m/%y")
                end
            end
        end
    end
end

-- Optimized statistics initialization with improved batching and error handling
function RaidMount.InitializeFromStatistics()
    if not RaidMount.mountInstances then return end

    local initializedCount = 0
    local mountsToProcess = {}

    -- Collect mounts that need statistics initialization
    for _, mount in ipairs(RaidMount.mountInstances) do
        local trackingKey = mount.spellID
        if trackingKey then
            local attemptData = RaidMountAttempts[trackingKey]
            if not attemptData then
                attemptData = {
                    total = 0,
                    characters = {},
                    lastAttempt = nil,
                    collected = false,
                    statisticsInitialized = false
                }
                RaidMountAttempts[trackingKey] = attemptData
            end

            if not attemptData.statisticsInitialized then
                table.insert(mountsToProcess, { mount = mount, attemptData = attemptData })
            end
        end
    end

    -- Process in batches to prevent frame drops
    if #mountsToProcess > 0 then
        local function ProcessStatisticsBatch(startIndex, batchSize)
            local endIndex = math.min(startIndex + batchSize - 1, #mountsToProcess)

            for i = startIndex, endIndex do
                local data = mountsToProcess[i]
                local mount = data.mount
                local attemptData = data.attemptData

                -- Safely get statistics to check
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

                    if maxAttempts > (attemptData.total or 0) then
                        attemptData.total = maxAttempts
                        attemptData.statisticsInitialized = true
                        attemptData.statisticsSource = {
                            statId = usedStatId,
                            lastUpdated = time(),
                            source = "blizzard_statistics"
                        }
                        initializedCount = initializedCount + 1
                    else
                        -- Mark as initialized even if no data found to prevent repeated checks
                        attemptData.statisticsInitialized = true
                    end
                end
            end

            -- Continue with next batch using task scheduler
            if endIndex < #mountsToProcess then
                RaidMount.ScheduleDelayedTask(0.05, function() -- Increased delay for better performance
                    ProcessStatisticsBatch(endIndex + 1, batchSize)
                end, "statistics_batch_" .. endIndex)
            else
                -- Finished processing
                if initializedCount > 0 then
                    RaidMount.PrintAddonMessage("Initialized " .. initializedCount .. " mounts from statistics")
                end
            end
        end

        -- Start processing with smaller batch size for better performance
        ProcessStatisticsBatch(1, 10) -- Reduced from 15
    end
end

function RaidMount.VerifyStatistics()
    local verifiedCount = 0
    local correctedCount = 0
    local corrections = {}

    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local attemptData = RaidMountAttempts[mount.spellID]
        local statisticsToCheck = mount.statisticIds

        if mount.statisticIdsByDifficulty then
            statisticsToCheck = {}
            for _, diffStats in pairs(mount.statisticIdsByDifficulty) do
                for _, statId in ipairs(diffStats) do
                    table.insert(statisticsToCheck, statId)
                end
            end
        end

        if attemptData and statisticsToCheck then
            local maxStatValue = 0
            local usedStatId = nil

            for _, statId in ipairs(statisticsToCheck) do
                local statValue = GetStatisticValue(statId)
                if statValue > maxStatValue then
                    maxStatValue = statValue
                    usedStatId = statId
                end
            end

            verifiedCount = verifiedCount + 1

            if maxStatValue > (attemptData.total or 0) then
                local oldTotal = attemptData.total or 0
                attemptData.total = maxStatValue
                attemptData.statisticsSource = {
                    statId = usedStatId,
                    lastUpdated = time(),
                    source = "blizzard_statistics"
                }
                correctedCount = correctedCount + 1

                table.insert(corrections, {
                    mountName = mount.mountName,
                    oldTotal = oldTotal,
                    newTotal = maxStatValue,
                    statId = usedStatId
                })
            end
        end
    end

    return {
        verified = verifiedCount,
        corrected = correctedCount,
        corrections = corrections
    }
end

-- NEW: Record mount attempt for current character (HYBRID APPROACH)
function RaidMount.RecordMountAttempt(mount, currentTime)
    local currentCharacter = RaidMount.GetCurrentCharacterID()
    if not currentCharacter then return end
    
    local trackingKey = mount.spellID
    if not trackingKey then return end
    
    -- HYBRID APPROACH: Update both global and character-specific data
    
    -- 1. Update character-specific data
    if not RaidMountAttempts[currentCharacter] then
        RaidMountAttempts[currentCharacter] = {
            class = select(2, UnitClass("player")),
            faction = UnitFactionGroup("player"),
            level = UnitLevel("player"),
            lastSeen = date("%Y-%m-%d"),
            attempts = {},
            lockouts = {},
            mountCollection = {},
            statistics = {}
        }
    end
    
    -- Initialize attempts table if needed
    if not RaidMountAttempts[currentCharacter].attempts then
        RaidMountAttempts[currentCharacter].attempts = {}
    end
    
    -- Record the attempt for this character
    if not RaidMountAttempts[currentCharacter].attempts[trackingKey] then
        RaidMountAttempts[currentCharacter].attempts[trackingKey] = {
            count = 0,
            mountName = mount.mountName,
            lastAttempt = currentTime,
            lastAttemptDate = date("%Y-%m-%d")
        }
    end
    
    RaidMountAttempts[currentCharacter].attempts[trackingKey].count = 
        RaidMountAttempts[currentCharacter].attempts[trackingKey].count + 1
    RaidMountAttempts[currentCharacter].attempts[trackingKey].lastAttempt = currentTime
    RaidMountAttempts[currentCharacter].attempts[trackingKey].lastAttemptDate = date("%Y-%m-%d")
    
    -- 2. Update global data for legacy compatibility and account-wide tracking
    if not RaidMountAttempts[trackingKey] then
        RaidMountAttempts[trackingKey] = {
            total = 0,
            characters = {},
            lastAttempt = nil,
            collected = false,
            statisticsInitialized = false
        }
    end
    
    -- Update global total
    RaidMountAttempts[trackingKey].total = (RaidMountAttempts[trackingKey].total or 0) + 1
    
    -- Update global character data
    if not RaidMountAttempts[trackingKey].characters then
        RaidMountAttempts[trackingKey].characters = {}
    end
    
    if type(RaidMountAttempts[trackingKey].characters[currentCharacter]) == "number" then
        -- Migrate old format
        RaidMountAttempts[trackingKey].characters[currentCharacter] = {
            count = RaidMountAttempts[trackingKey].characters[currentCharacter] + 1,
            lastUpdated = currentTime,
            source = "addon_tracking"
        }
    elseif type(RaidMountAttempts[trackingKey].characters[currentCharacter]) == "table" then
        -- Update existing
        RaidMountAttempts[trackingKey].characters[currentCharacter].count = 
            (RaidMountAttempts[trackingKey].characters[currentCharacter].count or 0) + 1
        RaidMountAttempts[trackingKey].characters[currentCharacter].lastUpdated = currentTime
        RaidMountAttempts[trackingKey].characters[currentCharacter].source = "addon_tracking"
    else
        -- First time for this character
        RaidMountAttempts[trackingKey].characters[currentCharacter] = {
            count = 1,
            lastUpdated = currentTime,
            source = "addon_tracking"
        }
    end

    -- Update global metadata
    RaidMountAttempts[trackingKey].lastAttempt = currentTime
    
    -- Update global classes data
    if not RaidMountAttempts[trackingKey].classes then
        RaidMountAttempts[trackingKey].classes = {}
    end
    RaidMountAttempts[trackingKey].classes[currentCharacter] = select(2, UnitClass("player"))
    
    -- Update global last attempt dates - ONLY for the current character who actually attempted
    if not RaidMountAttempts[trackingKey].lastAttemptDates then
        RaidMountAttempts[trackingKey].lastAttemptDates = {}
    end
    -- Only set the date for the current character who is actually attempting
    RaidMountAttempts[trackingKey].lastAttemptDates[currentCharacter] = date("%d/%m/%y")
    
    -- Check if mount was collected
    local hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
    if hasMount then
        -- Update character-specific collection
        RaidMountAttempts[currentCharacter].attempts[trackingKey].collected = true
        RaidMountAttempts[currentCharacter].attempts[trackingKey].collectedDate = date("%Y-%m-%d")
        
        -- Update global collection status
        RaidMountAttempts[trackingKey].collected = true
        
        PlaySound(8959, "Master")
    end
    
    -- Update character's last seen
    RaidMountAttempts[currentCharacter].lastSeen = date("%Y-%m-%d")
    
    RaidMount.PrintAddonMessage("Recorded attempt for " .. mount.mountName .. " (Total: " .. 
        RaidMountAttempts[currentCharacter].attempts[trackingKey].count .. ")")
end

-- Record Attempt (Enhanced with session tracking)
function RaidMount.RecordBossAttempt(encounterName, difficultyName)
    -- Get current difficulty if not provided
    if not difficultyName then
        local difficultyID = select(3, GetInstanceInfo())
        difficultyName = "Normal"
        if difficultyID == 17 then
            difficultyName = "LFR"
        elseif difficultyID == 14 then
            difficultyName = "Normal"
        elseif difficultyID == 15 then
            difficultyName = "Heroic"
        elseif difficultyID == 16 then
            difficultyName = "Mythic"
        end
    end
    if not encounterName then return end

    RaidMount.CheckNewSession()

    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local bossToMatch = mount.bossName

        -- Check if this mount has difficulty-specific boss names
        if mount.bossNameByDifficulty and mount.bossNameByDifficulty[difficultyName] then
            bossToMatch = mount.bossNameByDifficulty[difficultyName]
        end

        if bossToMatch and bossToMatch == encounterName then
            -- Use new character-specific attempt recording
            RaidMount.RecordMountAttempt(mount, time())

            if RaidMount.PopulateUI then RaidMount.PopulateUI() end
        end
    end
end 