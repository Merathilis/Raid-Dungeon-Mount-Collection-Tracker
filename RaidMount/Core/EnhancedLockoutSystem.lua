local addonName, RaidMount = ...

RaidMount = RaidMount or {}

-- Enhanced Lockout System inspired by SavedInstances
-- This provides comprehensive lockout tracking with cross-character support

local EnhancedLockout = {}
RaidMount.EnhancedLockout = EnhancedLockout

-- Performance optimization: Use local variables for frequently accessed functions
local time = time
local UnitName = UnitName
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local GetSavedInstanceChatLink = GetSavedInstanceChatLink
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local wipe = wipe
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local string_format = string.format
local string_gsub = string.gsub
local string_upper = string.upper
local math_floor = math.floor
local math_deg = math.deg
local math_atan2 = math.atan2

-- Constants
local FONTEND = FONT_COLOR_CODE_CLOSE
local GOLDFONT = NORMAL_FONT_COLOR_CODE
local YELLOWFONT = LIGHTYELLOW_FONT_COLOR_CODE
local REDFONT = RED_FONT_COLOR_CODE
local GREENFONT = GREEN_FONT_COLOR_CODE
local WHITEFONT = HIGHLIGHT_FONT_COLOR_CODE
local GRAYFONT = GRAY_FONT_COLOR_CODE

-- Legacy raid detection - raids up through Mists of Pandaria have shared lockouts
local LEGACY_EXPANSIONS = {
    ["Classic"] = true,
    ["The Burning Crusade"] = true,
    ["Wrath of the Lich King"] = true,
    ["Cataclysm"] = true,
    ["Mists of Pandaria"] = true
}

-- Function to determine if a raid is legacy (has shared lockouts)
function EnhancedLockout:IsLegacyRaid(expansion)
    return LEGACY_EXPANSIONS[expansion] == true
end

-- Function to get legacy lockout status for an instance
function EnhancedLockout:GetLegacyLockoutStatus(instanceName, charKey)
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        return nil
    end
    
    local charData = RaidMountSaved.enhancedLockouts.characters[charKey]
    if not charData or not charData.lockouts then
        return nil
    end
    
    -- Check if any difficulty of this instance is locked out
    for _, lockout in pairs(charData.lockouts) do
        if lockout.normalizedName == self:NormalizeInstanceName(instanceName) then
            return lockout
        end
    end
    
    return nil
end

-- Instance name translation table for localization issues
local instanceTranslation = {
    -- Add translations as needed for different locales
    -- [lockoutID] = correctName
}

-- Difficulty mapping
local difficultyNames = {
    [1] = "Normal",
    [2] = "Heroic", 
    [3] = "10 Player",
    [4] = "25 Player",
    [5] = "10 Player (Heroic)",
    [6] = "25 Player (Heroic)",
    [7] = "LFR",
    [14] = "Normal",
    [15] = "Heroic",
    [16] = "Mythic",
    [17] = "LFR",
    [23] = "Mythic",
    [33] = "Timewalking"
}

-- Color coding for different lockout states
local lockoutColors = {
    available = "|cFF00FF00",     -- Green
    locked = "|cFFFF0000",        -- Red
    extended = "|cFFFFFF00",      -- Yellow
    partial = "|cFFFF8000",       -- Orange
    expired = "|cFF808080"        -- Gray
}

-- Initialize the enhanced lockout system
function EnhancedLockout:Initialize()
    if not RaidMountSaved then
        RaidMountSaved = {}
    end
    
    if not RaidMountSaved.enhancedLockouts then
        RaidMountSaved.enhancedLockouts = {
            characters = {},
            instances = {},
            lastUpdate = 0
        }
    end
    
    -- Migrate old data structures to new format
    self:MigrateOldDataStructures()
    
    -- Register events for lockout updates (only create once)
    if not EnhancedLockout.eventFrame then
        EnhancedLockout.eventFrame = CreateFrame("Frame")
        EnhancedLockout.eventFrame:RegisterEvent("UPDATE_INSTANCE_INFO")
        EnhancedLockout.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
        EnhancedLockout.eventFrame:RegisterEvent("ADDON_LOADED")
        
        EnhancedLockout.eventFrame:SetScript("OnEvent", function(self, event, ...)
            if event == "ADDON_LOADED" and select(1, ...) == addonName then
                -- Immediate refresh on addon load
                EnhancedLockout:RefreshLockouts()
                -- Also do a delayed refresh to catch any late data
                C_Timer.After(1, function()
                    EnhancedLockout:RefreshLockouts()
                end)
            elseif event == "UPDATE_INSTANCE_INFO" or event == "PLAYER_ENTERING_WORLD" then
                -- Immediate refresh for instance changes
                EnhancedLockout:RefreshLockouts()
                -- Also do a delayed refresh to ensure all data is captured
                C_Timer.After(0.5, function()
                    EnhancedLockout:RefreshLockouts()
                end)
            end
        end)
    end
end

-- Migrate old data structures to new format
function EnhancedLockout:MigrateOldDataStructures()
    if not RaidMountSaved.enhancedLockouts then return end
    
    for charKey, charData in pairs(RaidMountSaved.enhancedLockouts.characters) do
        -- Check if character has old structure (direct lockout data)
        if charData and type(charData) == "table" then
            local hasOldStructure = false
            local hasNewStructure = false
            
            -- Check for old structure (direct lockout keys)
            for key, value in pairs(charData) do
                if type(value) == "table" and value.instanceName then
                    hasOldStructure = true
                    break
                end
            end
            
            -- Check for new structure (.lockouts table)
            if charData.lockouts and type(charData.lockouts) == "table" then
                hasNewStructure = true
            end
            
            -- Migrate if needed
            if hasOldStructure and not hasNewStructure then
                print("RaidMount: Migrating lockout data for " .. charKey)
                
                -- Create new structure
                charData.lockouts = {}
                
                -- Move old lockout data to new structure
                for key, lockoutData in pairs(charData) do
                    if type(lockoutData) == "table" and lockoutData.instanceName then
                        -- Convert to new format
                        local normalizedName = self:NormalizeInstanceName(lockoutData.instanceName)
                        local lockoutKey = string_format("%s_%d", normalizedName, lockoutData.difficulty or 0)
                        
                        charData.lockouts[lockoutKey] = {
                            instanceName = lockoutData.instanceName,
                            normalizedName = normalizedName,
                            instanceID = lockoutData.instanceID or lockoutData.lockoutID,
                            mapID = lockoutData.mapID,
                            resetTime = lockoutData.resetTime or lockoutData.reset,
                            difficulty = lockoutData.difficulty,
                            difficultyName = lockoutData.difficultyName,
                            locked = lockoutData.locked,
                            extended = lockoutData.extended,
                            isRaid = lockoutData.isRaid,
                            maxPlayers = lockoutData.maxPlayers,
                            bossesKilled = lockoutData.bossesKilled,
                            totalBosses = lockoutData.totalBosses,
                            progress = lockoutData.progress,
                            lastUpdated = lockoutData.lastUpdated or time()
                        }
                        
                        -- Remove old data
                        charData[key] = nil
                    end
                end
            end
        end
    end
end

-- Normalize instance names for consistent matching
function EnhancedLockout:NormalizeInstanceName(name)
    if not name then return "" end
    return name:gsub("%p", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""):upper()
end

-- Get current character key
function EnhancedLockout:GetCharacterKey()
    return UnitName("player") .. "-" .. GetRealmName()
end

-- Format time remaining
function EnhancedLockout:FormatTimeRemaining(seconds)
    if not seconds or seconds <= 0 then
        return "Expired"
    end
    
    local days = math_floor(seconds / 86400)
    local hours = math_floor((seconds % 86400) / 3600)
    local minutes = math_floor((seconds % 3600) / 60)
    
    if days > 0 then
        return string_format("%dd %dh %dm", days, hours, minutes)
    elseif hours > 0 then
        return string_format("%dh %dm", hours, minutes)
    elseif minutes > 0 then
        return string_format("%dm", minutes)
    else
        return "< 1m"
    end
end

-- Get boss kill information from lockout link
function EnhancedLockout:ParseBossKills(link, lfdID)
    if not link then return 0, 0 end
    
    local bits = link:match(":(%d+)\124h")
    bits = bits and tonumber(bits)
    if not bits then return 0, 0 end
    
    local killed = 0
    local tempBits = bits
    
    while tempBits > 0 do
        if bit.band(tempBits, 1) > 0 then
            killed = killed + 1
        end
        tempBits = bit.rshift(tempBits, 1)
    end
    
    -- Get total encounters from LFG system
    local total = 0
    if lfdID then
        total = GetLFGDungeonNumEncounters(lfdID) or 0
    end
    
    return killed, total
end

-- Refresh lockout information with better performance
function EnhancedLockout:RefreshLockouts()
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
    end
    
    local charKey = self:GetCharacterKey()
    local currentTime = time()
    
    -- Initialize character data
    if not RaidMountSaved.enhancedLockouts.characters[charKey] then
        RaidMountSaved.enhancedLockouts.characters[charKey] = {
            class = select(2, UnitClass("player")),
            faction = UnitFactionGroup("player"),
            level = UnitLevel("player"),
            lastSeen = currentTime,
            lockouts = {}
        }
    end
    
    local charData = RaidMountSaved.enhancedLockouts.characters[charKey]
    charData.lastSeen = currentTime
    charData.level = UnitLevel("player")
    
    -- Ensure lockouts table exists and is properly structured
    if not charData.lockouts then
        charData.lockouts = {}
    end
    
    -- Clear old lockouts and rebuild from current data
    wipe(charData.lockouts)
    
    -- Scan current lockouts
    for i = 1, GetNumSavedInstances() do
        local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, instanceMapID = GetSavedInstanceInfo(i)
        
        if name and locked then
            local normalizedName = self:NormalizeInstanceName(name)
            local link = GetSavedInstanceChatLink(i)
            local killed, total = self:ParseBossKills(link, nil)
            
            -- Use encounter progress if available
            if encounterProgress and numEncounters then
                killed = encounterProgress
                total = numEncounters
            end
            
            local lockoutData = {
                instanceName = name,
                normalizedName = normalizedName,
                instanceID = id,
                mapID = instanceMapID, -- Add MapID for mount matching
                resetTime = currentTime + reset,
                difficulty = difficulty,
                difficultyName = difficultyName or difficultyNames[difficulty] or "Unknown",
                locked = locked,
                extended = extended,
                isRaid = isRaid,
                maxPlayers = maxPlayers,
                bossesKilled = killed,
                totalBosses = total,
                progress = string_format("%d/%d", killed or 0, total or 0),
                link = link,
                lastUpdated = currentTime
            }
            
            -- Store by instance ID and difficulty for uniqueness
            local lockoutKey = string_format("%s_%d", normalizedName, difficulty)
            charData.lockouts[lockoutKey] = lockoutData
            
            -- Also store in global instances table for cross-character lookup
            if not RaidMountSaved.enhancedLockouts.instances[normalizedName] then
                RaidMountSaved.enhancedLockouts.instances[normalizedName] = {}
            end
            
            if not RaidMountSaved.enhancedLockouts.instances[normalizedName][charKey] then
                RaidMountSaved.enhancedLockouts.instances[normalizedName][charKey] = {}
            end
            
            RaidMountSaved.enhancedLockouts.instances[normalizedName][charKey][difficulty] = lockoutData
        end
    end
    
    RaidMountSaved.enhancedLockouts.lastUpdate = currentTime
    
    -- Clear tooltip cache when lockout data changes
    if RaidMount.ClearTooltipCache then
        RaidMount.ClearTooltipCache()
    end
    
    -- Clean up expired lockouts
    self:CleanupExpiredLockouts()
end

-- Clean up expired lockouts with better performance
function EnhancedLockout:CleanupExpiredLockouts()
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
        return
    end
    
    local currentTime = time()
    local cleanedCount = 0
    
    for charKey, charData in pairs(RaidMountSaved.enhancedLockouts.characters) do
        if charData.lockouts then
            for lockoutKey, lockoutData in pairs(charData.lockouts) do
                if lockoutData.resetTime and lockoutData.resetTime <= currentTime then
                    charData.lockouts[lockoutKey] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
        end
    end
    
    -- Clean up global instances table
    for instanceName, instanceData in pairs(RaidMountSaved.enhancedLockouts.instances) do
        for charKey, charLockouts in pairs(instanceData) do
            for difficulty, lockoutData in pairs(charLockouts) do
                if lockoutData.resetTime and lockoutData.resetTime <= currentTime then
                    charLockouts[difficulty] = nil
                    cleanedCount = cleanedCount + 1
                end
            end
            
            -- Remove empty character entries
            if not next(charLockouts) then
                instanceData[charKey] = nil
            end
        end
        
        -- Remove empty instance entries
        if not next(instanceData) then
            RaidMountSaved.enhancedLockouts.instances[instanceName] = nil
        end
    end
    
    if cleanedCount > 0 then
        print("RaidMount: Cleaned up " .. cleanedCount .. " expired lockouts")
        -- Clear tooltip cache when lockout data changes
        if RaidMount.ClearTooltipCache then
            RaidMount.ClearTooltipCache()
        end
    end
end

-- Get lockout status for a specific instance and difficulty
function EnhancedLockout:GetLockoutStatus(instanceName, difficulty, expansion)
    if not instanceName then
        return "No lockout", true, nil
    end
    
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
    end
    
    local normalizedName = self:NormalizeInstanceName(instanceName)
    local charKey = self:GetCharacterKey()
    
    -- Check if this is a legacy raid (shared lockouts)
    local isLegacy = self:IsLegacyRaid(expansion)
    
    -- Check current character's lockouts
    local charData = RaidMountSaved.enhancedLockouts.characters[charKey]
    if charData and charData.lockouts then
        -- For legacy raids, check if ANY difficulty is locked out
        if isLegacy then
            for lockoutKey, lockoutData in pairs(charData.lockouts) do
                if lockoutData.normalizedName == normalizedName then
                    local timeRemaining = lockoutData.resetTime - time()
                    if timeRemaining > 0 then
                        return self:FormatTimeRemaining(timeRemaining), false, lockoutData
                    end
                end
            end
        else
            -- For modern raids, check specific difficulty first
            local lockoutKey = string_format("%s_%d", normalizedName, difficulty or 0)
            local lockoutData = charData.lockouts[lockoutKey]
            
            if lockoutData then
                local timeRemaining = lockoutData.resetTime - time()
                if timeRemaining > 0 then
                    return self:FormatTimeRemaining(timeRemaining), false, lockoutData
                end
            end
            
            -- Check for shared difficulties (modern system)
            if difficulty then
                -- Get mount data to check for shared difficulties
                local mountData = self:GetMountDataByInstance(instanceName)
                if mountData and mountData.SharedDifficulties then
                    -- Check if this difficulty shares with another difficulty
                    local sharedWith = mountData.SharedDifficulties[difficulty]
                    if sharedWith then
                        -- Check if the shared difficulty has a lockout
                        local sharedLockoutKey = string_format("%s_%d", normalizedName, sharedWith)
                        local sharedLockoutData = charData.lockouts[sharedLockoutKey]
                        
                        if sharedLockoutData then
                            local timeRemaining = sharedLockoutData.resetTime - time()
                            if timeRemaining > 0 then
                                return self:FormatTimeRemaining(timeRemaining), false, sharedLockoutData
                            end
                        end
                    end
                    
                    -- Check if any difficulty shares with this difficulty
                    for sharedDiff, primaryDiff in pairs(mountData.SharedDifficulties) do
                        if primaryDiff == difficulty then
                            local sharedLockoutKey = string_format("%s_%d", normalizedName, sharedDiff)
                            local sharedLockoutData = charData.lockouts[sharedLockoutKey]
                            
                            if sharedLockoutData then
                                local timeRemaining = sharedLockoutData.resetTime - time()
                                if timeRemaining > 0 then
                                    return self:FormatTimeRemaining(timeRemaining), false, sharedLockoutData
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    return "No lockout", true, nil
end

-- Get lockout color based on status
function EnhancedLockout:GetLockoutColor(instanceName, difficulty, isRaid)
    if not isRaid then
        return lockoutColors.available, "", false
    end
    
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
    end
    
    local status, available, lockoutData = self:GetLockoutStatus(instanceName, difficulty, nil)
    
    if not available and lockoutData then
        local color = lockoutColors.locked
        if lockoutData.extended then
            color = lockoutColors.extended
        elseif lockoutData.bossesKilled and lockoutData.totalBosses and 
               lockoutData.bossesKilled > 0 and lockoutData.bossesKilled < lockoutData.totalBosses then
            color = lockoutColors.partial
        end
        
        return color, status, true
    end
    
    return lockoutColors.available, "", false
end

-- Get detailed lockout information for tooltips
function EnhancedLockout:GetDetailedLockoutInfo(instanceName)
    if not instanceName then return {} end
    
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
    end
    
    local normalizedName = self:NormalizeInstanceName(instanceName)
    local lockouts = {}
    
    -- Get current character's lockouts
    local charKey = self:GetCharacterKey()
    local charData = RaidMountSaved.enhancedLockouts.characters[charKey]
    
    if charData and charData.lockouts then
        for lockoutKey, lockoutData in pairs(charData.lockouts) do
            if lockoutData.normalizedName == normalizedName then
                local timeRemaining = lockoutData.resetTime - time()
                if timeRemaining > 0 then
                    table.insert(lockouts, {
                        difficulty = lockoutData.difficultyName,
                        timeRemaining = timeRemaining,
                        progress = lockoutData.progress,
                        extended = lockoutData.extended,
                        bossesKilled = lockoutData.bossesKilled,
                        totalBosses = lockoutData.totalBosses
                    })
                end
            end
        end
    end
    
    return lockouts
end

-- Get cross-character lockout information
function EnhancedLockout:GetCrossCharacterLockouts(instanceName)
    if not instanceName then return {} end
    
    -- Ensure initialization
    if not RaidMountSaved or not RaidMountSaved.enhancedLockouts then
        self:Initialize()
    end
    
    local normalizedName = self:NormalizeInstanceName(instanceName)
    local crossCharLockouts = {}
    
    -- Read directly from character lockouts instead of the instances table
    for charKey, charData in pairs(RaidMountSaved.enhancedLockouts.characters) do
        if charData.lockouts then
            for lockoutKey, lockoutData in pairs(charData.lockouts) do
                if lockoutData.normalizedName == normalizedName then
                    local timeRemaining = lockoutData.resetTime - time()
                    if timeRemaining > 0 then
                        table.insert(crossCharLockouts, {
                            character = charKey,
                            class = charData.class,
                            difficulty = lockoutData.difficultyName,
                            timeRemaining = timeRemaining,
                            progress = lockoutData.progress,
                            extended = lockoutData.extended
                        })
                    end
                end
            end
        end
    end
    
    return crossCharLockouts
end

-- Check if player can enter instance
function EnhancedLockout:CanEnterInstance(instanceName, difficulty)
    local status, available, lockoutData = self:GetLockoutStatus(instanceName, difficulty, nil)
    return available
end

-- Get formatted lockout string for UI display
function EnhancedLockout:GetFormattedLockout(instanceName, difficulty, isRaid)
    local color, timeString, isLocked = self:GetLockoutColor(instanceName, difficulty, isRaid)
    
    if isLocked and timeString ~= "" then
        return color .. timeString .. FONTEND
    elseif isRaid then
        return lockoutColors.available .. "Available" .. FONTEND
    else
        return lockoutColors.available .. "Available" .. FONTEND
    end
end

-- Backward compatibility functions for existing RaidMount code
function RaidMount.GetRaidLockout(instanceName)
    return RaidMount.EnhancedLockout:GetLockoutStatus(instanceName, nil, nil)
end

function RaidMount.GetLockoutColor(instanceName, isRaid)
    return RaidMount.EnhancedLockout:GetLockoutColor(instanceName, nil, isRaid)
end

function RaidMount.GetDetailedLockoutInfo(instanceName)
    return RaidMount.EnhancedLockout:GetDetailedLockoutInfo(instanceName)
end

function RaidMount.CanEnterInstance(instanceName, difficulty)
    return RaidMount.EnhancedLockout:CanEnterInstance(instanceName, difficulty)
end

function RaidMount.GetDifficultyLockoutStatus(instanceName, difficultyID, expansion)
    return RaidMount.EnhancedLockout:GetLockoutStatus(instanceName, difficultyID, expansion)
end

function RaidMount.DebugLockouts()
    RaidMount.EnhancedLockout:DebugLockouts()
end

-- Cross-character lockout functions
function RaidMount.GetCrossCharacterLockouts(instanceName)
    local lockouts = RaidMount.EnhancedLockout:GetCrossCharacterLockouts(instanceName)
    return lockouts
end

function RaidMount.GetCrossCharacterLockoutSummary(mount)
    if not mount or not mount.raidName then
        return {
            totalLocked = 0,
            lockedChars = {}
        }
    end
    
    local lockouts = RaidMount.GetCrossCharacterLockouts(mount.raidName)
    local summary = {
        totalLocked = 0,
        lockedChars = {}
    }
    
    -- Only include characters that have actual lockouts for this raid
    for _, lockout in ipairs(lockouts) do
        table.insert(summary.lockedChars, {
            character = lockout.character,
            class = lockout.class,
            difficulty = lockout.difficulty,
            timeRemaining = lockout.timeRemaining
        })
    end
    
    summary.totalLocked = #summary.lockedChars
    
    return summary
end

-- Force refresh lockouts immediately (for UI opening)
function RaidMount.ForceRefreshLockouts()
    if RaidMount.EnhancedLockout then
        RaidMount.EnhancedLockout:RefreshLockouts()
        -- Clear tooltip cache to ensure fresh data
        if RaidMount.ClearTooltipCache then
            RaidMount.ClearTooltipCache()
        end
    end
end

-- Get mount data by instance name
function EnhancedLockout:GetMountDataByInstance(instanceName)
    if not instanceName then return nil end
    
    -- Get mount data from the combined data function
    local allMounts = RaidMount.GetCombinedMountData and RaidMount.GetCombinedMountData()
    if allMounts then
        for _, mountData in pairs(allMounts) do
            if mountData.raidName == instanceName then
                return mountData
            end
        end
    end
    
    return nil
end

-- Initialize the system
EnhancedLockout:Initialize()

-- Cleanup function for Enhanced Lockout System
function RaidMount.CleanupEnhancedLockout()
    if EnhancedLockout.eventFrame then
        EnhancedLockout.eventFrame:UnregisterAllEvents()
        EnhancedLockout.eventFrame:SetScript("OnEvent", nil)
        EnhancedLockout.eventFrame = nil
    end
end