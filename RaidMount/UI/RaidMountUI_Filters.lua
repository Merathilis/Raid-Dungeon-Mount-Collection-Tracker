-- Filters and search module for RaidMount UI
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
RaidMount.currentSearch = RaidMount.currentSearch or ""

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
    
    -- Update filter status display immediately
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

-- CREATE SEARCH AND FILTER COMPONENTS
function RaidMount.CreateSearchAndFilters()
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
    
    searchBox:SetScript("OnTextChanged", OnSearchTextChanged)
    
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
    
    -- Add Escape key support to clear search
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
    
    RaidMount.SearchBox = searchBox
    
    -- Add search label
    local searchLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    searchLabel:SetPoint("BOTTOMLEFT", searchBox, "TOPLEFT", 0, 2)
    searchLabel:SetText(RaidMount.L("SEARCH"))
    searchLabel:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Add search help tooltip
    searchBox:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(RaidMount.L("SEARCH_HELP"), 1, 1, 1)
        GameTooltip:AddLine(RaidMount.L("SEARCH_HELP_LINE1"), 1, 1, 1)
        GameTooltip:AddLine(RaidMount.L("SEARCH_HELP_LINE2"), 1, 1, 1)
        GameTooltip:AddLine(RaidMount.L("SEARCH_HELP_LINE3"), 1, 1, 1)
        GameTooltip:AddLine(RaidMount.L("SEARCH_HELP_LINE4"), 1, 1, 1)
        GameTooltip:AddLine(RaidMount.L("SEARCH_HELP_LINE5"), 1, 1, 1)
        GameTooltip:Show()
    end)
    
    searchBox:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    -- Create filter dropdowns with optimized initialization
    RaidMount.CreateFilterDropdowns()
end

-- String trim function
if not string.trim then
    string.trim = function(s)
        return s:match("^%s*(.-)%s*$")
    end
end

-- Reset search state (called when UI is closed)
function RaidMount.ResetSearchState()
    if searchTimer then
        searchTimer:Cancel()
        searchTimer = nil
    end
    lastSearchTerm = ""
end

-- Clear filter cache (placeholder function)
function RaidMount.ClearFilterCache()
    -- This function can be used to clear any cached filter results
    -- Currently just a placeholder for future optimization
end

-- Test function to verify filtering works
function RaidMount.TestFiltering()
    local mountData = RaidMount.GetCombinedMountData()
    if mountData then
        local filtered = RaidMount.FilterAndSortMountData(mountData)
        print("Filter test complete: " .. #filtered .. " mounts shown")
    else
        print("No mount data available for testing")
    end
end

-- Test function to verify color consistency
function RaidMount.TestMountColors()
    print("=== RaidMount Color System Test ===")
    
    -- Test color constants
    print("Color Constants:")
    for colorName, colorCode in pairs(RaidMount.MOUNT_COLORS) do
        print("  " .. colorName .. ": " .. colorCode .. "Sample Text|r")
    end
    
    -- Test with sample mount data
    local testMounts = {
        {mountName = "Test Collected Mount", collected = true, collectorsBounty = false},
        {mountName = "Test Uncollected Mount", collected = false, collectorsBounty = false},
        {mountName = "Test Bounty Mount (Collected)", collected = true, collectorsBounty = true},
        {mountName = "Test Bounty Mount (Uncollected)", collected = false, collectorsBounty = true},
    }
    
    print("\nColor Test Results:")
    for _, mount in ipairs(testMounts) do
        local qualityColor = RaidMount.GetMountNameColor(mount)
        print("  " .. mount.mountName .. ":")
        print("    Quality Color: " .. qualityColor .. mount.mountName .. "|r")
    end
    
    print("=== Test Complete ===")
end

-- Clear all filters function
function RaidMount.ClearAllFilters()
    -- Reset all filter variables
    RaidMount.currentFilter = "All"
    RaidMount.currentExpansionFilters = {}
    RaidMount.currentContentTypeFilter = "All"
    RaidMount.currentDifficultyFilter = "All"
    RaidMount.currentSearch = ""
    
    -- Also reset the old expansion filter variable for compatibility
    RaidMount.currentExpansionFilter = "All"
    
    -- Reset all dropdowns
    local dropdowns = {
        {RaidMount.CollectedDropdown, "All"},
        {RaidMount.ExpansionDropdown, "All"},
        {RaidMount.ContentTypeDropdown, "All"},
        {RaidMount.DifficultyDropdown, "All"}
    }
    
    for _, dropdown in ipairs(dropdowns) do
        if dropdown[1] then
            UIDropDownMenu_SetSelectedName(dropdown[1], dropdown[2])
            UIDropDownMenu_SetText(dropdown[1], dropdown[2])
        end
    end
    
    -- Reset search box
    if RaidMount.SearchBox then 
        RaidMount.SearchBox:SetText(RaidMount.L("SEARCH_PLACEHOLDER"))
        RaidMount.SearchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    end
    
    -- Clear any cached data to ensure fresh lockout information
    if RaidMount.ClearTooltipCache then
        RaidMount.ClearTooltipCache()
    end
    
    -- Clear filter cache for fresh results
    if RaidMount.ClearFilterCache then
        RaidMount.ClearFilterCache()
    end
    
    -- Update the UI
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
        RaidMount.PopulateUI()
        
        -- Force a refresh of difficulty buttons after clearing filters
        RaidMount.ScheduleDelayedTask(0.1, function()
            if RaidMount.UpdateVisibleRowsOptimized then
                RaidMount.UpdateVisibleRowsOptimized()
            elseif RaidMount.UpdateVisibleRows then
                RaidMount.UpdateVisibleRows()
            end
        end, "clear_filters_refresh")
    end
    
    -- Update filter status display
    RaidMount.UpdateFilterStatusDisplay()
end

-- Update filter status display
function RaidMount.UpdateFilterStatusDisplay()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame.filterStatusText then return end
    
    local activeFilters = {}
    
    -- Check each filter
    if RaidMount.currentFilter ~= "All" then
        table.insert(activeFilters, RaidMount.currentFilter)
    end
    
    if RaidMount.currentExpansionFilters and next(RaidMount.currentExpansionFilters) then
        local expansionList = {}
        for expansion in pairs(RaidMount.currentExpansionFilters) do
            table.insert(expansionList, expansion)
        end
        table.insert(activeFilters, "Expansions: " .. table.concat(expansionList, ", "))
    end
    
    if RaidMount.currentContentTypeFilter ~= "All" then
        table.insert(activeFilters, RaidMount.currentContentTypeFilter)
    end
    
    if RaidMount.currentDifficultyFilter ~= "All" then
        table.insert(activeFilters, RaidMount.currentDifficultyFilter)
    end
    
    if RaidMount.currentSearch ~= "" then
        table.insert(activeFilters, "Search: \"" .. RaidMount.currentSearch .. "\"")
    end
    
    -- Update display
    if #activeFilters > 0 then
        RaidMount.RaidMountFrame.filterStatusText:SetText(RaidMount.L("ACTIVE_FILTERS", table.concat(activeFilters, " + ")))
        RaidMount.RaidMountFrame.filterStatusText:SetTextColor(1, 0.8, 0, 1) -- Gold color
    else
        RaidMount.RaidMountFrame.filterStatusText:SetText(RaidMount.L("NO_FILTERS_ACTIVE"))
        RaidMount.RaidMountFrame.filterStatusText:SetTextColor(0.6, 0.6, 0.6, 1) -- Gray color
    end
end

-- CREATE FILTER DROPDOWNS
function RaidMount.CreateFilterDropdowns()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Create a container frame for all filters (no background)
    local filterContainer = CreateFrame("Frame", nil, frame)
    filterContainer:SetPoint("TOPLEFT", 20, -50)
    filterContainer:SetPoint("TOPRIGHT", -20, -50)
    filterContainer:SetHeight(60)
    
    -- Create filter title
    local filterTitle = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    filterTitle:SetPoint("TOPLEFT", 0, -5)
    filterTitle:SetText(RaidMount.L("FILTERS"))
    filterTitle:SetTextColor(1, 0.8, 0, 1)
    
    -- Row 1: Collection Status and Expansion (most commonly used)
    local row1Y = -30
    
    -- Pre-define options for faster initialization
    local collectionOptions = {"All", "Collected", "Not Collected"}
    local contentTypeOptions = {"All", "Raid", "Dungeon", "World", "Collector's Bounty"}
    local difficultyOptions = {"All", "Normal", "Heroic", "Mythic", "Timewalking"}
    local expansionOptions = {
        "All", "Classic", "The Burning Crusade", "Wrath of the Lich King", 
        "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", 
        "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within", "Holiday Event"
    }
    
    -- Collection Status filter
    local collectedDropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", filterContainer, "UIDropDownMenuTemplate")
    collectedDropdown:SetPoint("TOPLEFT", 0, row1Y)
    
    -- Initialize dropdown with proper function
    UIDropDownMenu_Initialize(collectedDropdown, function(self, level)
        UIDropDownMenu_ClearAll(collectedDropdown)
        for _, option in ipairs(collectionOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(collectedDropdown, option)
                UIDropDownMenu_SetText(collectedDropdown, option)
                RaidMount.currentFilter = option
                
                -- Clear filter cache for fresh results
                if RaidMount.ClearFilterCache then
                    RaidMount.ClearFilterCache()
                end
                
                if not RaidMount.isStatsView and RaidMount.PopulateUI then 
                    RaidMount.PopulateUI() 
                end
                
                if RaidMount.UpdateFilterStatusDisplay then
                    RaidMount.UpdateFilterStatusDisplay()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(collectedDropdown, "All")
    UIDropDownMenu_SetText(collectedDropdown, "All")
    UIDropDownMenu_SetWidth(collectedDropdown, 120)
    RaidMount.CollectedDropdown = collectedDropdown
    
    -- Expansion filter - REPLACED WITH MULTI-SELECT
    local expansionDropdown = CreateFrame("Frame", "RaidMountExpansionDropdown", filterContainer, "UIDropDownMenuTemplate")
    expansionDropdown:SetPoint("TOPLEFT", 140, row1Y)
    
    UIDropDownMenu_Initialize(expansionDropdown, function(self, level)
        UIDropDownMenu_ClearAll(expansionDropdown)
        for _, expansion in ipairs(expansionOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = expansion
            info.func = function()
                -- Toggle expansion in filter list
                RaidMount.currentExpansionFilters = RaidMount.currentExpansionFilters or {}
                
                if expansion == "All" then
                    -- Clear all filters
                    wipe(RaidMount.currentExpansionFilters)
                    UIDropDownMenu_SetText(expansionDropdown, "All")
                else
                    -- Toggle specific expansion
                    if RaidMount.currentExpansionFilters[expansion] then
                        RaidMount.currentExpansionFilters[expansion] = nil
                    else
                        RaidMount.currentExpansionFilters[expansion] = true
                    end
                    
                    -- Update dropdown text
                    local selectedCount = 0
                    for _ in pairs(RaidMount.currentExpansionFilters) do
                        selectedCount = selectedCount + 1
                    end
                    
                    if selectedCount == 0 then
                        UIDropDownMenu_SetText(expansionDropdown, "All")
                    elseif selectedCount == 1 then
                        for exp in pairs(RaidMount.currentExpansionFilters) do
                            UIDropDownMenu_SetText(expansionDropdown, exp)
                            break
                        end
                    else
                        UIDropDownMenu_SetText(expansionDropdown, selectedCount .. " selected")
                    end
                end
                
                if not RaidMount.isStatsView and RaidMount.PopulateUI then 
                    RaidMount.PopulateUI() 
                end
                
                if RaidMount.UpdateFilterStatusDisplay then
                    RaidMount.UpdateFilterStatusDisplay()
                end
            end
            
            -- Show checkmark for selected expansions
            if expansion == "All" then
                if not RaidMount.currentExpansionFilters or next(RaidMount.currentExpansionFilters) == nil then
                    info.checked = true
                end
            else
                if RaidMount.currentExpansionFilters and RaidMount.currentExpansionFilters[expansion] then
                    info.checked = true
                end
            end
            
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(expansionDropdown, "All")
    UIDropDownMenu_SetText(expansionDropdown, "All")
    UIDropDownMenu_SetWidth(expansionDropdown, 140)
    RaidMount.ExpansionDropdown = expansionDropdown
    
    -- Content Type filter
    local contentTypeDropdown = CreateFrame("Frame", "RaidMountContentTypeDropdown", filterContainer, "UIDropDownMenuTemplate")
    contentTypeDropdown:SetPoint("TOPLEFT", 300, row1Y)
    
    UIDropDownMenu_Initialize(contentTypeDropdown, function(self, level)
        UIDropDownMenu_ClearAll(contentTypeDropdown)
        for _, option in ipairs(contentTypeOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(contentTypeDropdown, option)
                UIDropDownMenu_SetText(contentTypeDropdown, option)
                RaidMount.currentContentTypeFilter = option
                
                -- Clear filter cache when changing content type filter
                if RaidMount.ClearFilterCache then
                    RaidMount.ClearFilterCache()
                end
                
                if not RaidMount.isStatsView and RaidMount.PopulateUI then 
                    RaidMount.PopulateUI() 
                end
                
                if RaidMount.UpdateFilterStatusDisplay then
                    RaidMount.UpdateFilterStatusDisplay()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(contentTypeDropdown, "All")
    UIDropDownMenu_SetText(contentTypeDropdown, "All")
    UIDropDownMenu_SetWidth(contentTypeDropdown, 130)
    RaidMount.ContentTypeDropdown = contentTypeDropdown
    
    -- Difficulty filter
    local difficultyDropdown = CreateFrame("Frame", "RaidMountDifficultyDropdown", filterContainer, "UIDropDownMenuTemplate")
    difficultyDropdown:SetPoint("TOPLEFT", 450, row1Y)
    
    UIDropDownMenu_Initialize(difficultyDropdown, function(self, level)
        UIDropDownMenu_ClearAll(difficultyDropdown)
        for _, option in ipairs(difficultyOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(difficultyDropdown, option)
                UIDropDownMenu_SetText(difficultyDropdown, option)
                RaidMount.currentDifficultyFilter = option
                
                if not RaidMount.isStatsView and RaidMount.PopulateUI then 
                    RaidMount.PopulateUI() 
                end
                
                if RaidMount.UpdateFilterStatusDisplay then
                    RaidMount.UpdateFilterStatusDisplay()
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(difficultyDropdown, "All")
    UIDropDownMenu_SetText(difficultyDropdown, "All")
    UIDropDownMenu_SetWidth(difficultyDropdown, 100)
    RaidMount.DifficultyDropdown = difficultyDropdown
    
    -- Clear All Filters button (positioned next to the dropdowns)
    local clearFiltersButton = CreateFrame("Button", nil, filterContainer, "UIPanelButtonTemplate")
    clearFiltersButton:SetSize(80, 22)
    clearFiltersButton:SetPoint("TOPLEFT", 600, row1Y - 1)
    clearFiltersButton:SetText(RaidMount.L("CLEAR_ALL"))
    clearFiltersButton:SetScript("OnClick", function()
        if RaidMount.ClearAllFilters then
            RaidMount.ClearAllFilters()
        end
    end)
    
    -- Add tooltip to clear button
    clearFiltersButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(RaidMount.L("CLEAR_FILTERS_TIP"), 1, 1, 1)
        GameTooltip:AddLine("Reset all filters to 'All' and clear search", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    clearFiltersButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    
    RaidMount.ClearFiltersButton = clearFiltersButton
    
    -- Icon View toggle button (positioned to the right of Clear All)
    local iconViewButton = CreateFrame("Button", nil, filterContainer, "UIPanelButtonTemplate")
    iconViewButton:SetSize(90, 22)
    iconViewButton:SetPoint("LEFT", clearFiltersButton, "RIGHT", 10, 0)
    iconViewButton:SetText("Icon View")
    iconViewButton:SetScript("OnClick", function()
        if RaidMount.isIconView then
            RaidMount.ShowView("list")
            iconViewButton:SetText("Icon View")
        else
            RaidMount.ShowView("icon")
            iconViewButton:SetText("List View")
        end
        -- Hide headers in Icon View, show in List View
        if RaidMount.HeaderTexts then
            for _, headerData in ipairs(RaidMount.HeaderTexts) do
                if headerData.header then
                    headerData.header:SetShown(not RaidMount.isIconView)
                end
            end
        end
    end)
    filterContainer.IconViewButton = iconViewButton
    
    -- Add clean labels above each filter
    local labelY = -15
    local labelColor = {0.7, 0.7, 0.7, 1}
    
    local collectedLabel = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    collectedLabel:SetPoint("TOPLEFT", 50, labelY)
    collectedLabel:SetText("Status")
    collectedLabel:SetTextColor(unpack(labelColor))
    
    local expansionLabel = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    expansionLabel:SetPoint("TOPLEFT", 190, labelY)
    expansionLabel:SetText("Expansion")
    expansionLabel:SetTextColor(unpack(labelColor))
    
    local contentTypeLabel = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    contentTypeLabel:SetPoint("TOPLEFT", 340, labelY)
    contentTypeLabel:SetText("Content")
    contentTypeLabel:SetTextColor(unpack(labelColor))
    
    local difficultyLabel = filterContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    difficultyLabel:SetPoint("TOPLEFT", 490, labelY)
    difficultyLabel:SetText("Difficulty")
    difficultyLabel:SetTextColor(unpack(labelColor))
    
    -- Store the container for easy access
    RaidMount.FilterContainer = filterContainer
    
    -- Ensure dropdowns are immediately ready
    if collectedDropdown and expansionDropdown and contentTypeDropdown and difficultyDropdown then
        -- Force immediate initialization
        UIDropDownMenu_SetSelectedName(collectedDropdown, "All")
        UIDropDownMenu_SetSelectedName(expansionDropdown, "All")
        UIDropDownMenu_SetSelectedName(contentTypeDropdown, "All")
        UIDropDownMenu_SetSelectedName(difficultyDropdown, "All")
    end
end

-- FILTER AND SORT MOUNT DATA
function RaidMount.FilterAndSortMountData(mountData)
    local filtered = {}
    
    -- Pre-process search text once
    local searchText = ""
    local searchWords = {}
    local hasSearch = false
    if RaidMount.currentSearch and RaidMount.currentSearch ~= "" then
        searchText = tostring(RaidMount.currentSearch):lower():gsub("^%s+", ""):gsub("%s+$", "")
        local placeholder = RaidMount.L and RaidMount.L("SEARCH_PLACEHOLDER") or "search mounts, raids, or bosses..."
        if searchText ~= "" and searchText ~= placeholder:lower() then
            hasSearch = true
            -- Pre-split search words for efficiency
            for word in searchText:gmatch("%S+") do
                if word ~= "" then
                    table.insert(searchWords, word)
                end
            end
        end
    end
    
    -- Pre-cache filter values to avoid repeated table lookups
    local currentFilter = RaidMount.currentFilter
    local currentExpansionFilters = RaidMount.currentExpansionFilters
    local currentContentTypeFilter = RaidMount.currentContentTypeFilter
    local currentDifficultyFilter = RaidMount.currentDifficultyFilter
    
    for _, mount in ipairs(mountData) do
        local includeMount = true
        
        -- Filter by collection status (improved logic)
        if currentFilter == "Collected" then
            if not mount.collected then
                includeMount = false
            end
        elseif currentFilter == "Not Collected" then
            if mount.collected then
                includeMount = false
            end
        end
        
        -- Expansion filter (multi-select)
        if currentExpansionFilters and next(currentExpansionFilters) then
            local mountExpansion = (mount.expansion or "Unknown"):lower()
            local isIncluded = false
            
            -- Create expansion name mapping for shortened names
            local expansionMapping = {
                ["wotlk"] = "wrath of the lich king",
                ["wod"] = "warlords of draenor", 
                ["bfa"] = "battle for azeroth",
                ["tbc"] = "the burning crusade",
                ["legion"] = "legion",
                ["shadowlands"] = "shadowlands",
                ["dragonflight"] = "dragonflight",
                ["the war within"] = "the war within",
                ["classic"] = "classic",
                ["the burning crusade"] = "the burning crusade",
                ["cataclysm"] = "cataclysm",
                ["mists of pandaria"] = "mists of pandaria",
                ["holiday event"] = "holiday event"
            }
            
            -- Get the full expansion name for comparison
            local fullExpansionName = expansionMapping[mountExpansion] or mountExpansion
            
            for expansion in pairs(currentExpansionFilters) do
                if fullExpansionName == expansion:lower() then
                    isIncluded = true
                    break
                end
            end
            
            if not isIncluded then
                includeMount = false
            end
        end
        
        -- Content type filter
        if currentContentTypeFilter ~= "All" then
            if currentContentTypeFilter == "Collector's Bounty" then
                -- Use the same logic as elsewhere in the codebase
                if not (mount.collectorsBounty and mount.collectorsBounty ~= false) then
                    includeMount = false
                end
            else
                local mountContentType = (mount.contentType or "Unknown"):lower():gsub("%s+", "")
                local filterContentType = (currentContentTypeFilter or "Unknown"):lower():gsub("%s+", "")
                if not mountContentType:find(filterContentType, 1, true) then
                    includeMount = false
                end
            end
        end
        
        -- Difficulty filter
        if currentDifficultyFilter ~= "All" then
            local mountDifficulty = (mount.difficulty or "Unknown"):lower()
            if mountDifficulty ~= currentDifficultyFilter:lower() then
                includeMount = false
            end
        end
        
        -- Optimized search filtering
        if hasSearch then
            local success, searchResult = pcall(function()
                -- Build searchable text from mount data (cached)
                local mountText = (mount.mountName or ""):lower() .. " " .. 
                                (mount.raidName or ""):lower() .. " " .. 
                                (mount.bossName or ""):lower() .. " " ..
                                (mount.location or ""):lower() .. " " ..
                                (mount.expansion or ""):lower() .. " " ..
                                (mount.difficulty or ""):lower()
                
                -- Add Collector's Bounty to searchable text
                if mount.collectorsBounty and mount.collectorsBounty ~= false then
                    mountText = mountText .. " collector's bounty bounty collector"
                end
                
                -- Handle different search patterns
                if searchText:find('"') then
                    -- Exact phrase search (quoted text)
                    local exactPhrase = searchText:match('"([^"]*)"')
                    if exactPhrase and exactPhrase ~= "" then
                        return mountText:find(exactPhrase, 1, true) ~= nil
                    end
                end
                
                -- Check if search contains spaces (phrase search)
                if #searchWords > 1 then
                    -- Phrase search: all words must be present (AND logic)
                    for _, word in ipairs(searchWords) do
                        if not mountText:find(word, 1, true) then
                            return false
                        end
                    end
                    return true
                else
                    -- Single word search: simple contains check
                    return mountText:find(searchText, 1, true) ~= nil
                end
            end)
            
            if not success then
                -- Search error occurred, include the mount to avoid hiding everything
                includeMount = true
            elseif not searchResult then
                includeMount = false
            end
        end
        
        if includeMount then
            table.insert(filtered, mount)
        end
    end
    
    -- Sort data with error handling and improved sorting logic
    local success, sortError = pcall(function()
        table.sort(filtered, function(a, b)
            local aVal, bVal
            
            -- Handle different sort columns with appropriate data types
            if RaidMount.sortColumn == "attempts" then
                aVal = tonumber(a.attempts) or 0
                bVal = tonumber(b.attempts) or 0
            elseif RaidMount.sortColumn == "collected" then
                aVal = a.collected and 1 or 0
                bVal = b.collected and 1 or 0
            elseif RaidMount.sortColumn == "lockout" then
                -- Sort by lockout status: raids with lockout time should be at the top
                local aLockout = a.raidName and RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(a.raidName) or "No lockout"
                local bLockout = b.raidName and RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(b.raidName) or "No lockout"
                
                -- If both have lockout or both don't have lockout, sort by time remaining
                if aLockout ~= "No lockout" and bLockout ~= "No lockout" then
                    -- Both have lockout, sort by time remaining (shorter time first)
                    aVal = 1
                    bVal = 1
                elseif aLockout ~= "No lockout" then
                    -- Only A has lockout, A should be first
                    aVal = 1
                    bVal = 0
                elseif bLockout ~= "No lockout" then
                    -- Only B has lockout, B should be first
                    aVal = 0
                    bVal = 1
                else
                    -- Neither has lockout, sort alphabetically by raid name
                    aVal = tostring(a.raidName or "")
                    bVal = tostring(b.raidName or "")
                end
            elseif RaidMount.sortColumn == "dropRate" then
                -- Extract numeric value from drop rate strings like "1%" or "~1%"
                local aRate = (a.dropRate or ""):gsub("[^%d.]", "")
                local bRate = (b.dropRate or ""):gsub("[^%d.]", "")
                aVal = tonumber(aRate) or 0
                bVal = tonumber(bRate) or 0
            else
                -- String sorting for mount names, raid names, boss names, expansion
                aVal = tostring(a[RaidMount.sortColumn] or "")
                bVal = tostring(b[RaidMount.sortColumn] or "")
            end
            
            if RaidMount.sortDescending then
                return aVal > bVal
            else
                return aVal < bVal
            end
        end)
    end)
    
    if not success then
        -- Sort failed, but return unsorted data rather than empty
        PrintAddonMessage("Search sort failed: " .. (sortError or "unknown error"), true)
    end
    
    -- Update filter status display
    RaidMount.UpdateFilterStatusDisplay()
    
    return filtered
end

-- UPDATE MOUNT COUNTS
function RaidMount.UpdateMountCounts()
    local totalMounts, collectedMounts = 0, 0
    local combinedData = RaidMount.GetCombinedMountData()

    for _, mount in ipairs(combinedData) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    local percentage = totalMounts > 0 and (collectedMounts / totalMounts) * 100 or 0
    
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.progressBar then
        local bar = RaidMount.RaidMountFrame.progressBar
        bar:SetMinMaxValues(0, totalMounts)
        bar:SetValue(collectedMounts)
        bar.label:SetText(string.format("%d / %d (%.1f%%)", collectedMounts, totalMounts, percentage))
        bar.collected = collectedMounts
        bar.total = totalMounts
    end
end

-- Add missing optimized filter function
function RaidMount.OptimizedFilterAndSort(mountData)
    if not mountData then return {} end
    
    -- Use the existing filter function but with better performance
    return RaidMount.FilterAndSortMountData(mountData)
end

-- Add missing combined mount data function
function RaidMount.GetCombinedMountData()
    -- Ensure the addon is initialized before calling
    if not RaidMount.GetFormattedMountData then
        print("RaidMount: GetFormattedMountData not available yet, addon may not be fully loaded")
        return {}
    end
    
    -- Ensure initialization
    if RaidMount.EnsureInitialized then
        RaidMount.EnsureInitialized()
    end
    
    -- Use the existing formatted mount data function
    return RaidMount.GetFormattedMountData()
end 

-- Test function to verify dropdown functionality
function RaidMount.TestDropdowns()
    print("=== Testing Dropdown Functionality ===")
    
    if RaidMount.CollectedDropdown then
        print("Collection dropdown found")
        UIDropDownMenu_Initialize(RaidMount.CollectedDropdown, function(self, level)
            local options = {"All", "Collected", "Not Collected"}
            for _, option in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option
                info.func = function()
                    print("Collection dropdown clicked: " .. option)
                    UIDropDownMenu_SetSelectedName(RaidMount.CollectedDropdown, option)
                    UIDropDownMenu_SetText(RaidMount.CollectedDropdown, option)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
    else
        print("Collection dropdown NOT found")
    end
    
    if RaidMount.ExpansionDropdown then
        print("Expansion dropdown found")
    else
        print("Expansion dropdown NOT found")
    end
    
    if RaidMount.ContentTypeDropdown then
        print("Content type dropdown found")
    else
        print("Content type dropdown NOT found")
    end
    
    if RaidMount.DifficultyDropdown then
        print("Difficulty dropdown found")
    else
        print("Difficulty dropdown NOT found")
    end
    
    print("=== Dropdown Test Complete ===")
end

-- Export the test function
RaidMount.TestDropdowns = RaidMount.TestDropdowns 