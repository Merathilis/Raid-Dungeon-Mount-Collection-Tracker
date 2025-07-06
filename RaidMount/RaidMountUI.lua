local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Load UI modules
local UIModules = {
    "UI/RaidMountUI_Utils.lua",
    "UI/RaidMountUI_Main.lua", 
    "UI/RaidMountUI_MountList.lua",
    "UI/RaidMountUI_InfoPanel.lua"
}

-- Load modules (they will be loaded by the TOC file)
-- This is just a reference for module organization

if not RaidMount then
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r |cFFFF0000Error:|r RaidMount table is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
    return
end

-- Initialize global table for attempts
if not RaidMountAttempts then
    RaidMountAttempts = {}
end

-- UI State variables (moved from main module)
local currentFilter = "All"
local currentContentTypeFilter = "All"
local currentSearch = ""
local currentExpansionFilter = "All"
local sortColumn = "mountName"
local sortDescending = false
local isStatsView = false

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Optimization: Create lookup tables for faster mount data access
local mountLookupBySpellID = {}
local mountLookupByName = {}
local expansionMountCounts = {}

-- Build lookup tables on initialization
function RaidMount.BuildMountLookupTables()
    if not RaidMount.mountInstances then return end
    
    -- Clear existing lookups
    mountLookupBySpellID = {}
    mountLookupByName = {}
    expansionMountCounts = {}
    
    for i, mount in ipairs(RaidMount.mountInstances) do
        if mount.spellID then
            mountLookupBySpellID[mount.spellID] = mount  -- Store the mount table, not the index
        end
        if mount.mountName then
            mountLookupByName[mount.mountName:lower()] = mount  -- Store the mount table, not the index
        end
        
        -- Pre-calculate expansion counts
        local expansion = mount.expansion or "Unknown"
        if not expansionMountCounts[expansion] then
            expansionMountCounts[expansion] = 0
        end
        expansionMountCounts[expansion] = expansionMountCounts[expansion] + 1
    end
end

-- Performance caches
-- Static data cache - only rebuild on actual game events
local staticMountDataCache = nil
local staticDataVersion = 0
local filteredDataCache = nil
local sortCache = nil
local lastFilterState = {hash = ""} -- Initialize with hash field
local mountDataCache = nil

-- Cache timers for performance
local mountDataCacheTime = 0
local CACHE_DURATION = 30 -- seconds

-- Function to invalidate all caches
local function InvalidateCache()
    staticMountDataCache = nil
    filteredDataCache = nil
    sortCache = nil
    mountDataCache = nil
    mountDataCacheTime = 0
    lastFilterState = {hash = ""}
end

-- MAIN DATA FUNCTION: Get Combined Mount Data
function RaidMount.GetCombinedMountData()
    -- Check cache first
    local currentTime = GetTime()
    if mountDataCache and mountDataCacheTime > 0 and (currentTime - mountDataCacheTime) < CACHE_DURATION then
        return mountDataCache
    end
    
    -- Build fresh data
    local combinedData = {}
    
    if not RaidMount.mountInstances then
        return combinedData
    end
    
    for _, mount in ipairs(RaidMount.mountInstances) do
        local trackingKey = mount.spellID
        local attempts = RaidMount.GetAttempts and RaidMount.GetAttempts(mount) or 0
        local attemptData = RaidMountAttempts[trackingKey]
        local lastAttempt = "Never"
        local hasMount = false
        
        -- Check collection status from stored data first
        if attemptData and type(attemptData) == "table" then
            hasMount = attemptData.collected or false
            if attemptData.lastAttempt then
                lastAttempt = date("%d/%m/%y", attemptData.lastAttempt) -- UK format
            end
        end
        
        -- Double-check with live mount journal if not marked as collected
        if not hasMount and RaidMount.PlayerHasMount then
            hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
            -- Update stored data if we found it's actually collected
            if hasMount and attemptData then
                attemptData.collected = true
            end
        end
        
        -- Create combined mount data entry
        local lockoutInfo = RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(mount.raidName) or "Unknown"
        table.insert(combinedData, {
            raidName = mount.raidName or "Unknown",
            bossName = mount.bossName or "Unknown", 
            mountName = mount.mountName or "Unknown",
            location = mount.location or mount.raidName or "Unknown",
            dropRate = mount.dropRate or "~1%",
            resetTime = lockoutInfo,
            lockoutStatus = lockoutInfo,
            difficulty = mount.difficulty or "Unknown",
            expansion = mount.expansion or "Unknown",
            collected = hasMount,
            attempts = attempts,
            lastAttempt = lastAttempt,
            mountID = mount.MountID,
            spellID = mount.spellID,
            itemID = mount.itemID,
            contentType = mount.contentType or "Raid",
            type = mount.contentType or "Raid"
        })
    end
    
    -- Cache the result
    mountDataCache = combinedData
    mountDataCacheTime = currentTime
    
    return combinedData
end

-- Clear mount cache
function RaidMount.ClearMountCache()
    InvalidateCache()
end

-- Get account-wide character data for a mount
local function GetAccountWideData(trackingKey)
    if not RaidMountAttempts[trackingKey] then
        RaidMountAttempts[trackingKey] = {
            total = 0,
            characters = {},
            lastAttempt = nil,
            collected = false
        }
    end
    
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local accountData = RaidMountAttempts[trackingKey]
    
    -- Ensure character-specific data exists (using the existing format)
    if not accountData.characters then
        accountData.characters = {}
    end
    
    -- Calculate total attempts and gather character data
    local totalAttempts = accountData.total or 0
    local lastAttemptDate = nil
    local charactersWithAttempts = {}
    local collectedBy = nil
    
    -- Handle existing character data format (character ID -> attempt count)
    for charId, attempts in pairs(accountData.characters) do
        if attempts and attempts > 0 then
            -- Convert character ID back to readable name
            local charName = charId
            if charId == currentPlayer then
                charName = UnitName("player")
            else
                -- Try to extract character name from ID
                charName = charId:match("^([^%-]+)") or charId
            end
            
            table.insert(charactersWithAttempts, {
                name = charName,
                attempts = attempts,
                isCurrent = charId == currentPlayer
            })
        end
    end
    
    -- Sort characters by attempts (descending)
    table.sort(charactersWithAttempts, function(a, b) return a.attempts > b.attempts end)
    
    -- Get last attempt date
    if accountData.lastAttempt then
        lastAttemptDate = date("%d/%m/%y", accountData.lastAttempt) -- UK format
    end
    
    return {
        totalAttempts = totalAttempts,
        charactersWithAttempts = charactersWithAttempts,
        lastAttemptDate = lastAttemptDate,
        collectedBy = collectedBy
    }
end



