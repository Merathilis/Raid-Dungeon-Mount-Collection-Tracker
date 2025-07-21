-- Dropdowns module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Initialize filter variables if not already set
RaidMount.currentFilter = RaidMount.currentFilter or "All"
RaidMount.currentExpansionFilters = RaidMount.currentExpansionFilters or {}
RaidMount.currentExpansionFilter = RaidMount.currentExpansionFilter or "All" -- For compatibility
RaidMount.currentContentTypeFilter = RaidMount.currentContentTypeFilter or "All"
RaidMount.currentDifficultyFilter = RaidMount.currentDifficultyFilter or "All"

-- Clear all filters (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Update filter status display (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Create filter dropdowns (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Export functions for other modules
RaidMount.ClearAllFilters = RaidMount.ClearAllFilters
RaidMount.UpdateFilterStatusDisplay = RaidMount.UpdateFilterStatusDisplay
RaidMount.CreateFilterDropdowns = RaidMount.CreateFilterDropdowns 