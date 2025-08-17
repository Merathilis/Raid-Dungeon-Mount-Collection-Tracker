local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local ADDON_VERSION = "29.07.25.45"
local RAIDMOUNT_PREFIX = "|cFF33CCFFRaid|r|cFFFF0000Mount|r"

-- Performance optimization: Use local variables for frequently accessed functions
local print = print
local time = time
local date = date
local UnitName = UnitName
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local GetNumSavedInstances = GetNumSavedInstances
local GetSavedInstanceInfo = GetSavedInstanceInfo
local C_Timer = C_Timer
local CreateFrame = CreateFrame

-- Set global version for other modules
RaidMount.ADDON_VERSION = ADDON_VERSION

local function PrintAddonMessage(message, isError)
    if message then
        print(RAIDMOUNT_PREFIX .. ": " .. message)
    end
end

-- Set global print function for other modules
RaidMount.PrintAddonMessage = PrintAddonMessage

-- Initialize SavedVariables with proper structure
RaidMountAttempts = RaidMountAttempts or {}

-- Performance optimization: Cache player info
local cachedPlayerInfo = nil
local function GetCachedPlayerInfo()
    if not cachedPlayerInfo then
        local characterName = UnitName("player")
        local realmName = GetRealmName()
        
        -- Normalize to prevent duplicates when realm info is inconsistent
        if not realmName or realmName == "Unknown" or realmName == "" then
            cachedPlayerInfo = characterName
        else
            cachedPlayerInfo = characterName .. "-" .. realmName
        end
    end
    return cachedPlayerInfo
end

-- NEW: Normalize character ID to prevent duplicates
local function NormalizeCharacterID(characterName, realmName)
    if not characterName then return nil end
    
    -- If realm is nil, unknown, or empty, just use character name
    if not realmName or realmName == "Unknown" or realmName == "" then
        return characterName
    end
    
    return characterName .. "-" .. realmName
end

-- Set global function for other modules
RaidMount.GetCachedPlayerInfo = GetCachedPlayerInfo
RaidMount.NormalizeCharacterID = NormalizeCharacterID

-- Unified Mount Color System - Quality-based without API calls
RaidMount.MOUNT_COLORS = {
    -- Quality-based colors (same for all mounts regardless of collection status)
    COMMON = "|cFFFFFFFF",      -- White for common quality
    UNCOMMON = "|cFF1EFF00",    -- Green for uncommon quality
    RARE = "|cFF0070DD",        -- Blue for rare quality
    EPIC = "|cFFA335EE",        -- Purple for epic quality
    LEGENDARY = "|cFFFF8000",   -- Orange for legendary quality
    
    -- Default fallback
    DEFAULT = "|cFFA335EE",     -- Default to epic purple
}

-- Unified function to get mount collection status
function RaidMount.GetMountCollectionStatus(mountData)
    -- Use cached data first for performance
    if mountData.collected ~= nil then
        return mountData.collected
    end
    
    -- Fallback to live check if cache is missing
    if (mountData.mountID or mountData.spellID) and RaidMount.PlayerHasMount then
        local hasMount = RaidMount.PlayerHasMount(mountData.mountID, mountData.itemID, mountData.spellID)
        -- Cache the result to avoid repeated API calls
        mountData.collected = hasMount
        return hasMount
    end
    
    return false
end

-- Determine mount quality based on mount data (no API calls)
function RaidMount.GetMountQuality(mountData)
    -- Legendary mounts (very rare, special sources)
    local legendaryMounts = {
        -- Mythic-only mounts
        "Invincible", "Ashes of Al'ar", "Mimiron's Head", "Life-Binder's Handmaiden",
        "Kor'kron Juggernaut", "Ironhoof Destroyer", "Felsteel Annihilator", 
        "Hellfire Infernal", "Shackled Ur'zul", "Glacial Tidestorm", "Ny'alotha Allseer",
        "Vengeance", "Zereth Overseer", "Anu'relos, Flame's Guidance", "Ascendant Skyrazor",
        -- TCG and Promotional
        "Swift Spectral Tiger", "Magic Rooster Egg", "Tyrael's Charger"
    }
    
    -- Rare mounts (dungeon drops, some raid mounts)
    local rareMounts = {
        "Rivendare's Deathcharger", "Raven Lord", "Blue Proto-Drake", "Green Proto-Drake",
        "Vitreous Stone Drake", "Drake of the North Wind", "Swift White Hawkstrider"
    }
    
    -- Check mount name for quality
    local mountName = mountData.mountName or ""
    
    for _, legendary in ipairs(legendaryMounts) do
        if mountName:find(legendary) then
            return "legendary"
        end
    end
    
    for _, rare in ipairs(rareMounts) do
        if mountName:find(rare) then
            return "rare"
        end
    end
    
    -- Check by content type and difficulty
    if mountData.difficulty then
        local diff = mountData.difficulty:lower()
        if diff:find("mythic") then
            return "legendary"
        elseif diff:find("heroic") then
            return "epic"
        elseif diff:find("normal") then
            return "rare"
        end
    end
    
    -- Check by content type
    if mountData.contentType then
        local content = mountData.contentType:lower()
        if content:find("raid") then
            return "epic" -- Most raid mounts are epic
        elseif content:find("dungeon") then
            return "rare" -- Most dungeon mounts are rare
        elseif content:find("world") then
            return "rare" -- World boss mounts are rare
        end
    end
    
    -- Default to epic for raid mounts
    return "epic"
end

-- Unified function to get mount name color
function RaidMount.GetMountNameColor(mountData, useSimpleColors)
    -- Quality-based coloring only (collection status shown by green tick icon)
    local quality = RaidMount.GetMountQuality(mountData)
    
    if quality == "legendary" then
        return RaidMount.MOUNT_COLORS.LEGENDARY
    elseif quality == "epic" then
        return RaidMount.MOUNT_COLORS.EPIC
    elseif quality == "rare" then
        return RaidMount.MOUNT_COLORS.RARE
    elseif quality == "uncommon" then
        return RaidMount.MOUNT_COLORS.UNCOMMON
    elseif quality == "common" then
        return RaidMount.MOUNT_COLORS.COMMON
    else
        return RaidMount.MOUNT_COLORS.DEFAULT
    end
end

-- Get Difficulty Color
function RaidMount.GetDifficultyColor(difficulty)
    local colors = {
        ["Mythic"] = "|cFFFF8000",
        ["Heroic"] = "|cFF0070DD",
        ["Normal"] = "|cFFFFFFFF",
        ["LFR"] = "|cFF1EFF00"
    }
    return colors[difficulty] or "|cFFFFFFFF"
end

-- Get Lockout Color
function RaidMount.GetLockoutColor(raidName)
    local resetTime = RaidMount.GetRaidLockout(raidName)
    return (resetTime == "No lockout") and "|cFF00FF00" or "|cFFFF0000"
end

-- Check if player has a mount (missing function that was being referenced)
function RaidMount.PlayerHasMount(mountID, itemID, spellID)
    -- This function might be causing performance issues - let's optimize it
    
    -- Try direct Mount ID lookup first (most efficient)
    if mountID and C_MountJournal then
        local success, name, mountSpellID, icon, active, isUsable, sourceType, isFavorite, isFactionSpecific, faction, hideOnChar, isCollected = pcall(C_MountJournal.GetMountInfoByID, mountID)
        if success and name then
            return isCollected == true
        end
    end
    
    -- Fallback: check if spell is known (for older mounts)
    if spellID and IsSpellKnown then
        return IsSpellKnown(spellID)
    end
    
    return false
end

-- Refresh mount collection data (missing function that was being referenced)
function RaidMount.RefreshMountCollection()
    if not RaidMount.mountInstances then
        return
    end
    
    -- Update collection status for all mounts
    for _, mount in ipairs(RaidMount.mountInstances) do
        if mount.MountID or mount.spellID then
            local hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
            
            -- Update the mount data with current collection status
            mount.collected = hasMount
            
            -- Update saved data
            local trackingKey = mount.spellID
            if trackingKey then
                if not RaidMountAttempts[trackingKey] then
                    RaidMountAttempts[trackingKey] = {
                        total = 0,
                        characters = {},
                        lastAttempt = nil,
                        collected = false
                    }
                end
                RaidMountAttempts[trackingKey].collected = hasMount
            end
        end
    end
end

-- Enhanced Format Mount Data for UI
function RaidMount.GetFormattedMountData()
    -- Ensure addon is initialized
    if not RaidMount.mountInstances then
        print("RaidMount: Mount data not loaded yet")
        return {}
    end
    
    if #RaidMount.mountInstances == 0 then
        return {}
    end
    
    local formattedData = {}
    for _, mount in ipairs(RaidMount.mountInstances) do
        local attempts = RaidMount.GetAttempts(mount)
        local trackingKey = mount.spellID -- Use Spell ID as primary key
        local attemptData = RaidMountAttempts[trackingKey]
        local lastAttempt = nil
        local hasMount = false

        -- Check collection status from stored data first, then live check
        if attemptData and type(attemptData) == "table" then
            hasMount = attemptData.collected or false
            if attemptData.lastAttempt then
                lastAttempt = date("%d/%m/%y", attemptData.lastAttempt)
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

        local lockoutInfo = RaidMount.GetRaidLockout(mount.raidName)
        -- For legacy raids, we need to pass expansion information for proper lockout handling
        if mount.expansion and RaidMount.EnhancedLockout and RaidMount.EnhancedLockout:IsLegacyRaid(mount.expansion) then
            local status, available, lockoutData = RaidMount.EnhancedLockout:GetLockoutStatus(mount.raidName, nil, mount.expansion)
            lockoutInfo = status
        end
        table.insert(formattedData, {
            raidName = mount.raidName or RaidMount.L("UNKNOWN"),
            bossName = mount.bossName or RaidMount.L("UNKNOWN"),
            mountName = mount.mountName or RaidMount.L("UNKNOWN"),
            location = mount.location or RaidMount.L("UNKNOWN"),
            dropRate = mount.dropRate or "~1%",
            resetTime = lockoutInfo,
            lockoutStatus = lockoutInfo,
            difficulty = mount.difficulty or RaidMount.L("UNKNOWN"),
            expansion = mount.expansion or RaidMount.L("UNKNOWN"),
            collected = hasMount,
            attempts = attempts,
            lastAttempt = lastAttempt,
            mountID = mount.MountID, -- Note: MountData uses MountID (capital)
            spellID = mount.spellID,
            itemID = mount.itemID,
            type = "Raid",
            -- Add difficulty information for the new UI feature
            DifficultyIDs = mount.DifficultyIDs,
            SharedDifficulties = mount.SharedDifficulties,
            contentType = mount.contentType,

            -- Add MapID and InstanceID for lockout matching
            MapID = mount.MapID,
            mapID = mount.MapID, -- Also add lowercase version for compatibility
            InstanceID = mount.InstanceID,
            instanceID = mount.InstanceID -- Also add lowercase version for compatibility
        })
    end
    return formattedData
end










