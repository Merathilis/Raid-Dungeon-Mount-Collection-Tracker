local addonName, RaidMount = ...
RaidMount = RaidMount or {}




if not RaidMount then
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r |cFFFF0000Error:|r " .. RaidMount.L("ERROR_RAIDMOUNT_NIL"))
    return
end

-- Don't wipe RaidMountAttempts - just ensure it exists
if not RaidMountAttempts then
    RaidMountAttempts = {}
end

-- Initialize filter variables
RaidMount.currentFilter = RaidMount.currentFilter or "All"
RaidMount.currentExpansionFilter = RaidMount.currentExpansionFilter or "All"
RaidMount.currentContentTypeFilter = RaidMount.currentContentTypeFilter or "All"
RaidMount.currentDifficultyFilter = RaidMount.currentDifficultyFilter or "All"
RaidMount.currentSearch = RaidMount.currentSearch or ""

-- Initialize sort variables
RaidMount.sortColumn = RaidMount.sortColumn or "mountName"
RaidMount.sortDescending = RaidMount.sortDescending or false
RaidMount.isStatsView = RaidMount.isStatsView or false

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

local mountLookupBySpellID = {}
local mountLookupByName = {}
local expansionMountCounts = {}

function RaidMount.BuildMountLookupTables()
    if not RaidMount.mountInstances then return end
    
    mountLookupBySpellID = {}
    mountLookupByName = {}
    expansionMountCounts = {}
    
    for i, mount in ipairs(RaidMount.mountInstances) do
        if mount.spellID then
            mountLookupBySpellID[mount.spellID] = mount
        end
        if mount.mountName then
            mountLookupByName[mount.mountName:lower()] = mount
        end
        
        local expansion = mount.expansion or "Unknown"
        if not expansionMountCounts[expansion] then
            expansionMountCounts[expansion] = 0
        end
        expansionMountCounts[expansion] = expansionMountCounts[expansion] + 1
    end
    
    -- Build search index for optimized searching
    RaidMount.BuildSearchIndex()
end

local staticMountDataCache = nil
local staticDataVersion = 0
local filteredDataCache = nil
local sortCache = nil
local lastFilterState = {hash = ""}
local mountDataCache = nil

local mountDataCacheTime = 0
local CACHE_DURATION = 30

local function InvalidateCache()
    staticMountDataCache = nil
    filteredDataCache = nil
    sortCache = nil
    mountDataCache = nil
    mountDataCacheTime = 0
    lastFilterState = {hash = ""}
end


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
    
    local currentPlayer = RaidMount.GetCurrentCharacterID()
    local accountData = RaidMountAttempts[trackingKey]
    
    if not accountData.characters then
        accountData.characters = {}
    end
    
    local totalAttempts = accountData.total or 0
    local lastAttemptDate = nil
    local charactersWithAttempts = {}
    local collectedBy = nil
    
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

RaidMount.ShowIconView = RaidMount.ShowIconView or function() end
RaidMount.HideIconView = RaidMount.HideIconView or function() end

-- Optimized search and filtering system
local searchIndex = {}
local filterCache = {}
local lastFilterHash = ""

-- Build search index for fast lookups
function RaidMount.BuildSearchIndex()
    if not RaidMount.mountInstances then 
        return 
    end
    
    searchIndex = {}
    
    for i, mount in ipairs(RaidMount.mountInstances) do
        local searchableText = {}
        
        -- Pre-process and cache searchable text
        if mount.mountName then
            local mountNameLower = mount.mountName:lower()
            table.insert(searchableText, mountNameLower)
            -- Add individual words for partial matching
            for word in mountNameLower:gmatch("%S+") do
                table.insert(searchableText, word)
            end
        end
        
        if mount.raidName then
            local raidNameLower = mount.raidName:lower()
            table.insert(searchableText, raidNameLower)
            for word in raidNameLower:gmatch("%S+") do
                table.insert(searchableText, word)
            end
        end
        
        if mount.bossName then
            local bossNameLower = mount.bossName:lower()
            table.insert(searchableText, bossNameLower)
            for word in bossNameLower:gmatch("%S+") do
                table.insert(searchableText, word)
            end
        end
        
        if mount.expansion then
            table.insert(searchableText, mount.expansion:lower())
        end
        
        if mount.contentType then
            table.insert(searchableText, mount.contentType:lower())
        end
        

        
        -- Create search index for this mount
        searchIndex[i] = {
            mountIndex = i,
            searchableText = searchableText,
            searchableString = table.concat(searchableText, " ")
        }
    end
end

-- Fast search function using pre-built index
function RaidMount.FastSearch(searchTerm, mountData)
    if not searchTerm or searchTerm == "" then
        return mountData -- Return all data if no search term
    end
    
    local searchLower = searchTerm:lower()
    local results = {}
    local resultSet = {}
    
    -- Use pre-built search index for fast lookups
    for _, indexEntry in ipairs(searchIndex) do
        if indexEntry.searchableString:find(searchLower, 1, true) then
            local mount = mountData[indexEntry.mountIndex]
            if mount and not resultSet[mount] then
                table.insert(results, mount)
                resultSet[mount] = true
            end
        end
    end
    
    return results
end

-- Combined optimized filter and sort (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Clear filter cache when needed (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Timer management is handled by Core/RaidMountSession.lua
-- This module delegates to the core implementation





