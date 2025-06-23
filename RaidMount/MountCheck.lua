local addonName, RaidMount = ...
RaidMount = RaidMount or {}

--  Cache to avoid duplicate checks
RaidMount.MountCache = {}

-- Mount detection: Scan journal and match by Spell ID
function RaidMount.RefreshMountCollection()
    -- Clear cache first
    RaidMount.ClearMountCache()
    
    local collectedCount = 0
    local totalChecked = 0
    
    -- Get all collected mounts from journal
    local collectedSpellIDs = {}
    local mountIDs = C_MountJournal.GetMountIDs()
    
    if mountIDs then
        for _, mountID in ipairs(mountIDs) do
            local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
            
            if isCollected and spellID then
                collectedSpellIDs[spellID] = true
            end
        end
    end
    
    -- Check all mounts by matching Spell IDs
    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        if mount.spellID then
            totalChecked = totalChecked + 1
            local hasMount = collectedSpellIDs[mount.spellID] == true
            
            -- Use Spell ID as the primary key for all tracking (not Mount ID)
            local trackingKey = mount.spellID
            
            -- Initialize attempt data if it doesn't exist
            if not RaidMountAttempts[trackingKey] then
                RaidMountAttempts[trackingKey] = {
                    total = 0,
                    characters = {},
                    lastAttempt = nil,
                    collected = false
                }
            end
            
            -- Update collection status
            RaidMountAttempts[trackingKey].collected = hasMount
            mount.collected = hasMount
            
            if hasMount then
                collectedCount = collectedCount + 1
            end
        end
    end
    

    
    -- Update UI if it's open
    if RaidMount.PopulateUI then
        RaidMount.PopulateUI()
    end
end

-- Cache for mount detection to avoid repeated API calls
local mountCache = {}
local cacheExpiry = {}
local CACHE_DURATION = 300 -- 5 minutes

-- Primary mount detection function with multiple fallback methods
function RaidMount.PlayerHasMount(mountID, itemID, spellID)
    if not mountID then
        return false
    end
    
    -- Check cache first
    local cacheKey = tostring(mountID)
    if mountCache[cacheKey] and cacheExpiry[cacheKey] and GetTime() < cacheExpiry[cacheKey] then
        return mountCache[cacheKey]
    end
    
    local hasMount = false
    
    -- Method 1: Check if mount spell is known
    if mountID and IsSpellKnown(mountID) then
        hasMount = true
    end
    
    -- Method 2: Check mount journal if available
    if not hasMount and C_MountJournal then
        local mountIDs = C_MountJournal.GetMountIDs()
        if mountIDs then
            for _, jMountID in ipairs(mountIDs) do
                local name, jSpellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(jMountID)
                
                -- Match by mountID or spellID
                if jMountID == mountID or (spellID and jSpellID == spellID) then
                    hasMount = isCollected == true
                    break
                end
            end
        end
    end
    
    -- Method 3: Check if item exists in bags/bank (for item-based mounts)
    if not hasMount and itemID and itemID > 0 then
        if C_Item and C_Item.DoesItemExistByID then
            if C_Item.DoesItemExistByID(itemID) then
                local itemCount = C_Item.GetItemCount(itemID, true, false, true) -- include bank and reagent bank
                if itemCount > 0 then
                    hasMount = true
                end
            end
        end
    end
    
    -- Cache the result
    mountCache[cacheKey] = hasMount
    cacheExpiry[cacheKey] = GetTime() + CACHE_DURATION
    
    return hasMount
end

-- Clear mount cache (useful when mounts are obtained)
function RaidMount.ClearMountCache()
    mountCache = {}
    cacheExpiry = {}
end
