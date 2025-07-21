-- English localization for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Get current locale
local currentLocale = GetLocale()

-- English locale table (default fallback)
local enUSLocale = {
    -- UI Elements
    ["STATS"] = "Stats",
    ["SEARCH"] = "Search",
    ["SEARCH_PLACEHOLDER"] = "Search mounts, raids, or bosses...",
    ["CLEAR_ALL"] = "Clear All",
    ["CLOSE"] = "Close",
    ["SELECT_ALL"] = "Select All",
    ["BACK"] = "Back",
    ["FILTERS"] = "Filters",
    ["ENHANCED_TOOLTIPS"] = "Enhanced Tooltips",
    ["VERSION"] = "Version",
    
    -- Status Messages
    ["COLLECTED"] = "Collected",
    ["NOT_COLLECTED"] = "Not Collected",
    ["LOCKED_OUT"] = "Locked out",
    ["NO_LOCKOUT"] = "No lockout",
    ["AVAILABLE_NOW"] = "Available now",
    ["NEXT_ATTEMPT"] = "Next Attempt",
    ["LOCKOUT"] = "Lockout",
    ["UNKNOWN"] = "Unknown",
    
    -- Column Headers
    ["MOUNT_NAME"] = "Mount Name",
    ["RAID_SOURCE"] = "Raid/Source",
    ["BOSS"] = "Boss",
    ["DROP_RATE"] = "Drop Rate",
    ["EXPANSION"] = "Expansion",
    ["ATTEMPTS"] = "Attempts",
    ["LOCKOUT_STATUS"] = "Lockout",
    ["COORDINATES"] = "Map",
    
    -- Filter Options
    ["ALL"] = "All",
    ["COLLECTED"] = "Collected",
    ["UNCOLLECTED"] = "Uncollected",
    ["RAID"] = "Raid",
    ["DUNGEON"] = "Dungeon",
    ["NORMAL"] = "Normal",
    ["HEROIC"] = "Heroic",
    ["MYTHIC"] = "Mythic",
    
    -- Info Panel
    ["ATTEMPT_TRACKING"] = "ATTEMPT TRACKING",
    ["STATUS_LOCKOUT"] = "STATUS & LOCKOUT",
    ["DESCRIPTION"] = "DESCRIPTION",
    ["TOTAL_ATTEMPTS"] = "Total Attempts",
    ["MORE_CHARACTERS"] = " more characters",
    ["COLLECTORS_BOUNTY"] = "Collector's Bounty:",
    ["COLLECTORS_BOUNTY_BONUS"] = "+5% drop chance",
    ["COLLECTED_ON"] = "Collected:",
    ["NO_DESCRIPTION"] = "No description available.",
    ["RAID"] = "Raid",
    ["BOSS"] = "Boss",
    ["ZONE"] = "Zone",
    
    -- Slash Commands
    ["HELP_TITLE"] = "Available commands:",
    ["HELP_OPEN"] = "/rm - Open/close the main interface",
    ["HELP_HELP"] = "/rm help - Show this help message",
    ["HELP_STATS"] = "/rm stats - Show statistics view",
    ["HELP_RESET"] = "/rm reset - Reset all attempt data (with confirmation)",
    ["HELP_REFRESH"] = "/rm refresh - Refresh mount collection data",
    ["HELP_VERIFY"] = "/rm verify - Verify attempt counts against Blizzard statistics",
    ["UNKNOWN_COMMAND"] = "Unknown command: %s. Use |cFFFFFF00/rm help|r for available commands.",
    ["RESET_CONFIRMATION"] = "Are you sure you want to reset ALL attempt data? This cannot be undone!",
    ["RESET_CONFIRM_AGAIN"] = "Type |cFFFFFF00/rm reset|r again within 10 seconds to confirm.",
    ["RESET_COMPLETE"] = "All attempt data has been reset.",
    ["REFRESH_SCANNING"] = "Scanning your mount collection...",
    ["REFRESH_COMPLETE"] = "Mount collection refreshed.",
    ["VERIFY_COMPLETE"] = "Attempt verification complete.",
    
    -- Statistics
    ["DETAILED_STATS"] = "Detailed Mount Collection Statistics",
    ["OVERALL_STATS"] = "Overall Statistics",
    ["BY_EXPANSION"] = "By Expansion",
    ["MOST_ATTEMPTED"] = "Most Attempted Mounts",
    ["ATTEMPTS_TEXT"] = "attempts",
    
    -- Tooltips
    ["SEARCH_HELP"] = "Search Help",
    ["SEARCH_HELP_LINE1"] = "• Type any word to search mount names, raids, bosses",
    ["SEARCH_HELP_LINE2"] = "• Use quotes for exact phrases: \"Onyxian Drake\"",
    ["SEARCH_HELP_LINE3"] = "• Multiple words search for all terms: ice crown",
    ["SEARCH_HELP_LINE4"] = "• Press Enter to search immediately",
    ["SEARCH_HELP_LINE5"] = "• Press Escape to clear search",
    ["CLEAR_FILTERS_TIP"] = "Clear All Filters",
    ["PROGRESS_TOOLTIP"] = "Mount Collection Progress",
    ["PROGRESS_FORMAT"] = "Collected: |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)",
    
    -- Messages
    ["LOADED_MESSAGE"] = "v%s loaded! Use |cFFFFFF00/rm|r to open the mount tracker.",
    ["SCANNING_FIRST_TIME"] = "Scanning your mount collection for the first time...",
    ["STATS_VIEW_DISPLAYED"] = "Statistics view displayed.",
    ["STATS_VIEW_UNAVAILABLE"] = "Statistics view not available.",
    ["ACTIVE_FILTERS"] = "Active Filters: %s",
    ["NO_FILTERS_ACTIVE"] = "No filters active - showing all mounts",
    ["NO_MOUNTS_FOUND"] = "No mounts found matching your criteria.",
    ["NEW_MOUNT_COLLECTED"] = "New mount collected! Mount ID: %d",
    ["DIFFICULTY_SET"] = "%s is set to %s",
    ["TOMTOM_WAYPOINT_SET"] = "TomTom waypoint set for %s",
    ["COULD_NOT_FIND_MAP_ID"] = "Could not find map ID for zone: %s",
    ["WAYPOINT_SET"] = "Waypoint set for %s at %s (%.1f, %.1f)",
    ["MOUNT_LOCATION"] = "%s location: %s (%s) - %.1f, %.1f",
    ["INSTALL_TOMTOM"] = "Install TomTom addon for better cross-expansion waypoint support",
    ["TRAVEL_GUIDE"] = "RaidMount Travel Guide: %s",
    ["CROSS_EXPANSION_TRAVEL"] = "Cross-expansion travel: %s -> %s (%s)",
    ["TRAVEL_NEEDED"] = "Travel needed: %s -> %s (%s)",
    ["INSTANCE_EXPANSION_INFO"] = "Instance: %s | Expansion: %s",
    
    -- Errors
    ["ERROR_HEADERS_NOT_INIT"] = "RaidMount: Warning - HeaderTexts not initialized",
    ["ERROR_HEADER_DATA_MISSING"] = "RaidMount: Warning - Header data missing for index %d",
    ["ERROR_RAIDMOUNT_NIL"] = "RaidMount: Error - RaidMount table is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.",
}

-- Set English as default fallback, then override with current locale if available
RaidMount.LOCALE = enUSLocale

-- If current locale is English, use English locale
if currentLocale == "enUS" then
    RaidMount.LOCALE = enUSLocale
end 