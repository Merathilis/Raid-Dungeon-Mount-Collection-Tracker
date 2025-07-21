local addonName, RaidMount = ...

-- Data versioning and migration system
local ADDON_DATA_VERSION = 2

local function MigrateData()
    if not RaidMountSaved.version or RaidMountSaved.version < ADDON_DATA_VERSION then
        RaidMount.PrintAddonMessage("Migrating data to version " .. ADDON_DATA_VERSION)

        -- Version 1 to 2 migration
        if not RaidMountSaved.version or RaidMountSaved.version < 2 then
            -- Migrate old attempt data format
            if RaidMountAttempts then
                for trackingKey, attemptData in pairs(RaidMountAttempts) do
                    if type(attemptData) == "table" and attemptData.characters then
                        for charName, charData in pairs(attemptData.characters) do
                            if type(charData) == "number" then
                                -- Migrate old format to new format
                                attemptData.characters[charName] = {
                                    count = charData,
                                    lastUpdated = time(),
                                    source = "migrated_data"
                                }
                            end
                        end
                    end
                end
            end
        end

        RaidMountSaved.version = ADDON_DATA_VERSION
    end
end

-- Enhanced SavedVariables initialization with validation
function RaidMount.InitializeSavedVariables()
    -- Initialize RaidMountSaved with defaults
    if not RaidMountSaved then
        RaidMountSaved = {
            version = ADDON_DATA_VERSION,
            enhancedTooltip = true,
            popupEnabled = true,
            currentSessionID = 1,
            lastSessionTime = 0,
            loggedCharacters = {},
            minimap = { angle = 0 }
        }
    end

    -- Migrate data if needed
    MigrateData()

    -- Validate and set defaults for missing values
    local defaults = {
        enhancedTooltip = true,
        popupEnabled = true,
        currentSessionID = 1,
        lastSessionTime = 0,
        loggedCharacters = {},
        minimap = { angle = 0 }
    }

    for key, defaultValue in pairs(defaults) do
        if RaidMountSaved[key] == nil then
            RaidMountSaved[key] = defaultValue
        end
    end

    -- Initialize settings with validation
    if not RaidMountSettings then
        RaidMountSettings = {
            mountDropSound = true,
            minimap = RaidMountSaved.minimap
        }
    end

    -- Validate settings
    if RaidMountSettings.mountDropSound == nil then
        RaidMountSettings.mountDropSound = true
    end

    -- Initialize attempts with proper structure
    if not RaidMountAttempts then
        RaidMountAttempts = {}
    end

    -- Validate attempts data structure
    for trackingKey, attemptData in pairs(RaidMountAttempts) do
        if type(attemptData) ~= "table" then
            RaidMountAttempts[trackingKey] = {
                total = type(attemptData) == "number" and attemptData or 0,
                characters = {},
                lastAttempt = nil,
                collected = false
            }
        else
            -- Ensure required fields exist
            attemptData.total = attemptData.total or 0
            attemptData.characters = attemptData.characters or {}
            attemptData.collected = attemptData.collected or false
        end
    end

    -- Set global references
    RaidMountTooltipEnabled = RaidMountSaved.enhancedTooltip
    currentSessionID = RaidMountSaved.currentSessionID
    lastSessionTime = RaidMountSaved.lastSessionTime
end

-- Get Attempt Count (HYBRID APPROACH)
function RaidMount.GetAttempts(mount)
    local trackingKey
    if type(mount) == "table" then
        trackingKey = mount.spellID -- Use Spell ID for new system
    else
        trackingKey = mount         -- Legacy: direct ID passed
    end

    -- HYBRID APPROACH: Check character-specific data first, then global data
    local currentCharacter = UnitFullName("player")
    
    -- 1. Check character-specific data (preferred)
    if currentCharacter and RaidMountAttempts[currentCharacter] and RaidMountAttempts[currentCharacter].attempts then
        local charAttempts = RaidMountAttempts[currentCharacter].attempts[trackingKey]
        if charAttempts and charAttempts.count then
            return charAttempts.count
        end
    end
    
    -- 2. Check global character data (legacy compatibility)
    if currentCharacter and RaidMountAttempts[trackingKey] and RaidMountAttempts[trackingKey].characters then
        local globalCharData = RaidMountAttempts[trackingKey].characters[currentCharacter]
        if type(globalCharData) == "number" then
            return globalCharData
        elseif type(globalCharData) == "table" and globalCharData.count then
            return globalCharData.count
        end
    end
    
    -- 3. Fallback to global total
    local attempts = RaidMountAttempts[trackingKey]
    if type(attempts) == "number" then
        return attempts
    elseif type(attempts) == "table" then
        return attempts.total or 0
    end
    return 0
end

-- Get Character-specific attempts (HYBRID APPROACH)
function RaidMount.GetCharacterAttempts(mount, characterID)
    local trackingKey
    if type(mount) == "table" then
        trackingKey = mount.spellID -- Use Spell ID for new system
    else
        trackingKey = mount         -- Legacy: direct ID passed
    end

    -- HYBRID APPROACH: Check character-specific data first, then global data
    -- 1. Check character-specific data (preferred)
    if characterID and RaidMountAttempts[characterID] and RaidMountAttempts[characterID].attempts then
        local charAttempts = RaidMountAttempts[characterID].attempts[trackingKey]
        if charAttempts and charAttempts.count then
            return charAttempts.count
        end
    end
    
    -- 2. Check global character data (legacy compatibility)
    if characterID and RaidMountAttempts[trackingKey] and RaidMountAttempts[trackingKey].characters then
        local globalCharData = RaidMountAttempts[trackingKey].characters[characterID]
        if type(globalCharData) == "number" then
            return globalCharData
        elseif type(globalCharData) == "table" and globalCharData.count then
            return globalCharData.count
        end
    end
    
    return 0
end

-- Reset Attempts
function RaidMount.ResetAttempts(mount)
    if mount then
        local trackingKey
        if type(mount) == "table" then
            trackingKey = mount.spellID -- Use Spell ID for new system
        else
            trackingKey = mount         -- Legacy: direct ID passed
        end

        RaidMountAttempts[trackingKey] = {
            total = 0,
            characters = {},
            lastAttempt = nil,
            collected = false
        }
    else
        -- Reset all attempts
        for id, _ in pairs(RaidMountAttempts) do
            RaidMountAttempts[id] = {
                total = 0,
                characters = {},
                lastAttempt = nil,
                collected = false
            }
        end
    end

    -- Invalidate static cache since attempt data changed
    if RaidMount.InvalidateStaticData then
        RaidMount.InvalidateStaticData()
    end
end

-- Get character lockout information for a specific raid and difficulty
function RaidMount.GetCharacterLockouts(raidName, difficultyID)
    if not raidName or not RaidMount.GetDifficultyLockoutStatus then
        return {}
    end
    
    local characterLockouts = {}
    
    -- For now, only show current character's lockout status
    -- Future enhancement: Add support for checking other characters' lockouts
    local currentCharacter = UnitName("player")
    local timeRemaining, canEnter = RaidMount.GetDifficultyLockoutStatus(raidName, difficultyID)
    
    if not canEnter and timeRemaining and timeRemaining ~= "No lockout" then
        table.insert(characterLockouts, {
            name = currentCharacter,
            isLocked = true,
            lockoutTime = timeRemaining
        })
    end
    
    return characterLockouts
end 