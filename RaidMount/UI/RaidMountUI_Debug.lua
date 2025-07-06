-- Debug and utility module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Function to force refresh mount data
function RaidMount.ForceRefreshMountData()
    -- Clear all caches
    if RaidMount.ClearMountCache then
        RaidMount.ClearMountCache()
    end
    
    -- Reset filters using helper function
    if RaidMount.ResetAllFilters then
        RaidMount.ResetAllFilters()
    end
    
    -- Refresh mount collection
    if RaidMount.RefreshMountCollection then
        RaidMount.RefreshMountCollection()
    end
    
    -- Update UI if it's open - preserve current view state
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        if RaidMount.isStatsView then
            RaidMount.ShowDetailedStatsView()
        else
            RaidMount.PopulateUI()
        end
    end
    
    local mountData = RaidMount.GetCombinedMountData()
    PrintAddonMessage("Mount data refreshed! Found " .. #mountData .. " mounts.", false)
end

function RaidMount.Debug()
    local mountData = RaidMount.GetCombinedMountData()
    -- Removed for production
end

-- Legacy function alias for backward compatibility
function RaidMount.DebugUI()
    RaidMount.Debug("ui")
end

-- Force reload UI function
function RaidMount.ReloadUI()
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
        RaidMount.RaidMountFrame = nil
    end
    RaidMount.ContentFrame = nil
    RaidMount.ScrollFrame = nil
    RaidMount.HeaderFrame = nil
    PrintAddonMessage("UI reset. Use /rm to reopen.", false)
end

function RaidMount.HideAllFrames()
    -- Removed for production
end

function RaidMount.DebugAllFrames()
    -- Removed for production
end

-- Nuclear option: Completely destroy all RaidMount frames
function RaidMount.DestroyAllFrames()
    -- Removed for production
end 