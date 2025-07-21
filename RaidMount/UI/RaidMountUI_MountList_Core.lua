-- Mount List Core module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
-- cachedFontPath is handled by Utils.lua

-- Core data variables
local visibleRows = {}
local rowPool = {}
local maxVisibleRows = 30
local rowHeight = 28
local totalRows = 0
local filteredData = {}

RaidMount.textureCache = RaidMount.textureCache or {}
local textureCache = RaidMount.textureCache
local preloadQueue = {}
local preloadDistance = 10

-- Core availability checking functions
local function IsWorldBossAvailable(data)
    -- For world bosses, check if they're on lockout
    if data.contentType == "World" and data.raidName and RaidMount.GetRaidLockout then
        local lockoutTime = RaidMount.GetRaidLockout(data.raidName)
        local isAvailable = (lockoutTime == "No lockout" or lockoutTime == nil)
        return isAvailable
    end
    return true -- Default to available if we can't check
end

local function IsHolidayEventActive(data)
    -- For holiday events, check if they're on lockout
    if data.contentType == "Holiday" and data.raidName and RaidMount.GetRaidLockout then
        local lockoutTime = RaidMount.GetRaidLockout(data.raidName)
        local isActive = (lockoutTime == "No lockout" or lockoutTime == nil)
        return isActive
    end
    return true -- Default to available
end

-- Difficulty text generation
local function GetDifficultyButtonText(difficultyID, contentType, mountData)
    if not difficultyID then return "?" end

    -- DungeonDifficulty and RaidDifficulty should be defined in MountData.lua
    local DungeonDifficulty = { Normal = 1, Heroic = 2, Mythic = 23 }
    local RaidDifficulty = { Legacy10 = 3, Legacy25 = 4, Legacy10H = 5, Legacy25H = 6, LFR = 17, Normal = 14, Heroic = 15, Mythic = 16 }

    -- Find the difficulty key
    local dKey
    for key, dd in pairs(DungeonDifficulty) do
        if dd == difficultyID then
            dKey = key; break
        end
    end

    if not dKey then
        for key, rd in pairs(RaidDifficulty) do
            if rd == difficultyID then
                dKey = key; break
            end
        end
    end

    -- Special handling for known incorrect mappings
    if mountData then
        -- Mimiron's Head: difficulty "Normal 25" but uses modern Normal instead of Legacy25
        if mountData.mountName == "Mimiron's Head" and difficultyID == RaidDifficulty.Normal then
            return "25N"
        end
        
        -- Vitreous Stone Drake: difficulty "Heroic" but uses Normal instead of Heroic
        if mountData.mountName == "Vitreous Stone Drake" and difficultyID == DungeonDifficulty.Normal then
            return "Heroic"
        end
    end

    -- Return appropriate button text based on difficulty and content type
    if dKey == "LFR" then
        return dKey
    elseif dKey == "Normal" then
        return contentType == "Dungeon" and "Normal" or "N"
    elseif dKey == "Heroic" then
        return contentType == "Dungeon" and "Heroic" or "H"
    elseif dKey == "Mythic" then
        return contentType == "Dungeon" and "Mythic" or "M"
    elseif dKey == "Legacy10" then
        return "10N" -- 10-man Normal
    elseif dKey == "Legacy25" then
        return "25N" -- 25-man Normal
    elseif dKey == "Legacy10H" then
        return "10H" -- 10-man Heroic
    elseif dKey == "Legacy25H" then
        return "25H" -- 25-man Heroic
    end

    return "?"
end

-- Helper function to check lockout status considering shared difficulties
local function GetEffectiveLockoutStatus(raidName, difficultyID, sharedDifficulties)
    if not raidName or not RaidMount.GetDifficultyLockoutStatus then
        return true -- Assume available if we can't check
    end

    -- First check the direct difficulty
    local lockoutTime, isAvailable = RaidMount.GetDifficultyLockoutStatus(raidName, difficultyID)

    -- If this difficulty is locked, check if any shared difficulties are also locked
    if not isAvailable and sharedDifficulties then
        for sharedDiffID, primaryDiffID in pairs(sharedDifficulties) do
            -- If this difficulty shares lockout with the primary, check the primary's status
            if sharedDiffID == difficultyID then
                local primaryLockoutTime, primaryAvailable = RaidMount.GetDifficultyLockoutStatus(raidName, primaryDiffID)
                if not primaryAvailable then
                    return false -- Both are locked
                end
            end
        end
    end

    return isAvailable
end

-- Lockout information gathering
local function GetLockoutInfo(data)
    if not data then
        return false, nil
    end

    -- Check for special content types (World bosses, Holiday events)
    if data.contentType == "World" then
        return true, { "World" }, nil, data.contentType
    elseif data.contentType == "Holiday" then
        return true, { "Holiday" }, nil, data.contentType
    end

    -- Check if we have difficulty information
    local hasDifficultyInfo = data.DifficultyIDs and #data.DifficultyIDs > 0

    -- If we have difficulty info, return it
    if hasDifficultyInfo then
        return true, data.DifficultyIDs, data.SharedDifficulties, data.contentType
    end

    -- For dungeon mounts without DifficultyIDs, use the difficulty field from mount data
    if data.contentType == "Dungeon" then
        local DungeonDifficulty = { Normal = 1, Heroic = 2, Mythic = 23 }
        local difficulties = {}

        -- Add Normal difficulty (most dungeons have this)
        table.insert(difficulties, DungeonDifficulty.Normal)

        -- Add Heroic if the mount difficulty is Heroic or higher
        if data.difficulty == "Heroic" or data.difficulty == "Mythic" then
            table.insert(difficulties, DungeonDifficulty.Heroic)
        end

        -- Add Mythic if the mount difficulty is Mythic
        if data.difficulty == "Mythic" then
            table.insert(difficulties, DungeonDifficulty.Mythic)
        end

        if #difficulties > 0 then
            return true, difficulties, nil, data.contentType
        end
    end

    -- Fall back to the original lockout check
    if data.raidName and RaidMount.GetRaidLockout then
        local lockoutTime = RaidMount.GetRaidLockout(data.raidName)
        if lockoutTime and lockoutTime ~= "No lockout" then
            return true, lockoutTime
        end
    end

    return false, nil
end

-- Texture preloading system
local texturePreloadInProgress = false
local maxCacheSize = 100 -- Limit cache size

local function PreloadTexture(mountID)
    -- Temporarily disable texture preloading to improve performance
    return
end

-- Data management functions
function RaidMount.SetFilteredData(data)
    if not data then return end

    -- Clear existing data
    wipe(filteredData)

    -- Copy new data
    for i, mount in ipairs(data) do
        filteredData[i] = mount
    end

    totalRows = #filteredData
    RaidMount.totalRows = totalRows -- Update the global reference

    -- Update content frame height immediately
    if RaidMount.ContentFrame then
        RaidMount.ContentFrame:SetHeight(totalRows * rowHeight)
    end

    -- Update visible rows immediately
    if RaidMount.UpdateVisibleRowsOptimized then
        RaidMount.UpdateVisibleRowsOptimized()
    end
end

-- Cleanup functions
function RaidMount.ClearTextureCache()
    wipe(textureCache)
    wipe(preloadQueue)
    texturePreloadInProgress = false
end

function RaidMount.ClearRowPool()
    -- Just clear the pool without processing each row individually
    for _, row in pairs(rowPool) do
        if row and row.SetParent then
            row:SetParent(nil)
        end
    end
    wipe(rowPool)
end

function RaidMount.ClearVisibleRows()
    for _, row in pairs(visibleRows) do
        if row then
            row:Hide()
        end
    end
    wipe(visibleRows)
end

function RaidMount.CleanupMountList()
    RaidMount.ClearVisibleRows()
    RaidMount.ClearRowPool()
    RaidMount.ClearTextureCache()
    totalRows = 0
    wipe(filteredData)
end

-- Texture caching functions
local function GetCachedTexture(mountID)
    if textureCache[mountID] then
        if RaidMount.performanceStats then
            RaidMount.performanceStats.textureCache.hits = (RaidMount.performanceStats.textureCache.hits or 0) + 1
        end
        return textureCache[mountID]
    end

    if RaidMount.performanceStats then
        RaidMount.performanceStats.textureCache.misses = (RaidMount.performanceStats.textureCache.misses or 0) + 1
    end

    local name, spellID, iconFile = C_MountJournal.GetMountInfoByID(mountID)
    if iconFile then
        textureCache[mountID] = iconFile
        return iconFile
    end

    return nil
end

local function PreloadUpcomingTextures(startIndex, endIndex)
    for i = startIndex, math.min(endIndex + preloadDistance, totalRows) do
        if filteredData[i] then
            local mountID = filteredData[i].MountID or filteredData[i].spellID
            if mountID then
                PreloadTexture(mountID)
            end
        end
    end
end

-- Export core functions
RaidMount.GetDifficultyButtonText = GetDifficultyButtonText
RaidMount.GetEffectiveLockoutStatus = GetEffectiveLockoutStatus
RaidMount.GetLockoutInfo = GetLockoutInfo
RaidMount.GetCachedTexture = GetCachedTexture
RaidMount.PreloadUpcomingTextures = PreloadUpcomingTextures
RaidMount.IsWorldBossAvailable = IsWorldBossAvailable
RaidMount.IsHolidayEventActive = IsHolidayEventActive

-- Export data variables
RaidMount.visibleRows = visibleRows
RaidMount.rowPool = rowPool
RaidMount.maxVisibleRows = maxVisibleRows
RaidMount.rowHeight = rowHeight
RaidMount.totalRows = totalRows
RaidMount.filteredData = filteredData
RaidMount.textureCache = textureCache

-- Export core functions that other modules need
RaidMount.PreloadTexture = PreloadTexture
RaidMount.GetCachedTexture = GetCachedTexture
RaidMount.PreloadUpcomingTextures = PreloadUpcomingTextures
