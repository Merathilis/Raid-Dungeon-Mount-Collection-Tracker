-- Debug and utility module for RaidMount UI
local addonName, RaidMount = ...

local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Function to force refresh mount data
function RaidMount.ForceRefreshMountData()
    if RaidMount.ClearMountCache then
        RaidMount.ClearMountCache()
    end
    
    if RaidMount.ResetAllFilters then
        RaidMount.ResetAllFilters()
    end
    
    if RaidMount.RefreshMountCollection then
        RaidMount.RefreshMountCollection()
    end
    
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
end

function RaidMount.DebugAllFrames()
end

function RaidMount.DestroyAllFrames()
end