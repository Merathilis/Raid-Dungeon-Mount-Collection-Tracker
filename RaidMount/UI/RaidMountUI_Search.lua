-- Search module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Optimized search with event-driven debouncing
local searchTimer = nil
local lastSearchTerm = ""
local isInitializing = true
local searchInProgress = false

local function PerformSearch(searchTerm)
    -- Don't search if it's the placeholder text or empty
    local placeholder = RaidMount.L and RaidMount.L("SEARCH_PLACEHOLDER") or "Search mounts, raids, or bosses..."
    if searchTerm == placeholder or searchTerm == "" or not searchTerm then
        searchTerm = ""
    end
    
    if searchTerm == lastSearchTerm then return end
    
    lastSearchTerm = searchTerm
    RaidMount.currentSearch = searchTerm
    
    -- Clear filter cache for fresh results
    if RaidMount.ClearFilterCache then
        RaidMount.ClearFilterCache()
    end
    
    if not RaidMount.isStatsView then
        if RaidMount.PopulateUI then
            RaidMount.PopulateUI()
        end
    end
    
    if RaidMount.UpdateFilterStatusDisplay then
        RaidMount.UpdateFilterStatusDisplay()
    end
end

local function OnSearchTextChanged(self)
    if isInitializing then 
        return 
    end
    
    local searchTerm = self:GetText()
    
    -- Cancel previous timer
    if searchTimer then
        searchTimer:Cancel()
        searchTimer = nil
    end
    
    -- Immediate visual feedback - update search state instantly
    RaidMount.currentSearch = searchTerm
    
    -- Show clear button immediately if there's text
    if self.clearButton then
        if searchTerm ~= "" and searchTerm ~= (RaidMount.L and RaidMount.L("SEARCH_PLACEHOLDER") or "Search mounts, raids, or bosses...") then
            self.clearButton:Show()
        else
            self.clearButton:Hide()
        end
    end
    
    -- Update filter status display immediately for instant feedback
    if RaidMount.UpdateFilterStatusDisplay then
        RaidMount.UpdateFilterStatusDisplay()
    end
    
    -- Only update UI if not already in progress to prevent spam
    if not searchInProgress and not RaidMount.isStatsView and RaidMount.PopulateUI then
        searchInProgress = true
        -- Immediate UI update for instant feedback
        RaidMount.PopulateUI()
        searchInProgress = false
    end
    
    -- Schedule final search with minimal debouncing for final processing
    if RaidMount.ScheduleDelayedTask then
        searchTimer = RaidMount.ScheduleDelayedTask(0.02, function() -- Reduced to 0.02s for near-instant
            PerformSearch(searchTerm)
        end, "search_debounce")
    else
        -- Fallback if scheduler not available
        C_Timer.After(0.02, function()
            PerformSearch(searchTerm)
        end)
    end
end

-- Create search box
function RaidMount.CreateSearchBox()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Search box (positioned above filters)
    local searchBox = CreateFrame("EditBox", "RaidMountSearchBox", frame)
    searchBox:SetSize(280, 28)
    searchBox:SetPoint("TOPLEFT", 20, -15)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("ChatFontNormal")
    searchBox:SetTextInsets(10, 10, 0, 0)
    
    local editBg = searchBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.05, 0.05, 0.1, 0.9)
    
    local placeholder = RaidMount.L and RaidMount.L("SEARCH_PLACEHOLDER") or "Search mounts, raids, or bosses..."
    searchBox:SetText(placeholder)
    searchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Initialize search state to prevent initial search
    RaidMount.currentSearch = ""
    lastSearchTerm = ""
    
    -- End initialization phase faster
    C_Timer.After(0.1, function() -- Reduced from 0.5s to 0.1s
        isInitializing = false
    end)
    
    -- Clear button for search box
    local clearButton = CreateFrame("Button", nil, searchBox)
    clearButton:SetSize(16, 16)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -5, 0)
    clearButton:SetText("×")
    clearButton:SetNormalFontObject("GameFontNormalSmall")
    clearButton:SetHighlightFontObject("GameFontHighlightSmall")
    clearButton:Hide()
    
    -- Store reference to clear button for immediate access
    searchBox.clearButton = clearButton
    
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        RaidMount.currentSearch = ""
        clearButton:Hide()
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
            RaidMount.PopulateUI()
        end
    end)
    
    -- Set up search box events
    searchBox:SetScript("OnTextChanged", OnSearchTextChanged)
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == placeholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
        if self:GetText() ~= "" then
            clearButton:Show()
        end
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(placeholder)
            self:SetTextColor(0.6, 0.6, 0.6, 1)
            clearButton:Hide()
        end
    end)
    
    searchBox:SetScript("OnEscapePressed", function(self)
        if self:GetText() ~= "" and self:GetText() ~= placeholder then
            self:SetText("")
            RaidMount.currentSearch = ""
            clearButton:Hide()
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
                RaidMount.PopulateUI()
            end
        end
        self:ClearFocus()
    end)
    
    -- Add Enter key support for immediate search
    searchBox:SetScript("OnEnterPressed", function(self)
        if searchTimer then
            searchTimer:Cancel()
            searchTimer = nil
        end
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
            RaidMount.PopulateUI()
        end
        self:ClearFocus()
    end)
    
    -- Store reference
    RaidMount.SearchBox = searchBox
    
    return searchBox
end

-- Reset search state (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Clear filter cache (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Test filtering functionality
function RaidMount.TestFiltering()
    PrintAddonMessage("Testing filtering functionality...")
    
    -- Test search functionality
    if RaidMount.SearchBox then
        PrintAddonMessage("Search box found and functional")
    else
        PrintAddonMessage("Search box not found", true)
    end
    
    -- Test current search state
    PrintAddonMessage("Current search: " .. (RaidMount.currentSearch or "none"))
    
    -- Test filter state
    PrintAddonMessage("Current filters:")
    PrintAddonMessage("  Collection: " .. (RaidMount.currentFilter or "none"))
    PrintAddonMessage("  Expansion: " .. (RaidMount.currentExpansionFilter or "none"))
    PrintAddonMessage("  Content Type: " .. (RaidMount.currentContentTypeFilter or "none"))
    PrintAddonMessage("  Difficulty: " .. (RaidMount.currentDifficultyFilter or "none"))
end

-- Test mount colors
function RaidMount.TestMountColors()
    PrintAddonMessage("Testing mount color functionality...")
    
    -- Test color functions
    if RaidMount.GetMountNameColor then
        PrintAddonMessage("Mount color function available")
    else
        PrintAddonMessage("Mount color function not available", true)
    end
    
    if RaidMount.GetDifficultyColor then
        PrintAddonMessage("Difficulty color function available")
    else
        PrintAddonMessage("Difficulty color function not available", true)
    end
    
    if RaidMount.GetLockoutColor then
        PrintAddonMessage("Lockout color function available")
    else
        PrintAddonMessage("Lockout color function not available", true)
    end
end

-- Export functions for other modules
RaidMount.CreateSearchBox = RaidMount.CreateSearchBox
RaidMount.ResetSearchState = RaidMount.ResetSearchState
RaidMount.ClearFilterCache = RaidMount.ClearFilterCache
RaidMount.TestFiltering = RaidMount.TestFiltering
RaidMount.TestMountColors = RaidMount.TestMountColors 