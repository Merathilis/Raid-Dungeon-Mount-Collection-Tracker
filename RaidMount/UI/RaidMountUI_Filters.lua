-- Filters and search module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Search state management
local searchTimer = nil
local lastSearchText = ""

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
    
    local placeholder = RaidMount.L("SEARCH_PLACEHOLDER")
    searchBox:SetText(placeholder)
    searchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Clear button for search box
    local clearButton = CreateFrame("Button", nil, searchBox)
    clearButton:SetSize(16, 16)
    clearButton:SetPoint("RIGHT", searchBox, "RIGHT", -5, 0)
    clearButton:SetText("×")
    clearButton:SetNormalFontObject("GameFontNormalSmall")
    clearButton:SetHighlightFontObject("GameFontHighlightSmall")
    clearButton:Hide()
    
    clearButton:SetScript("OnClick", function()
        searchBox:SetText("")
        searchBox:ClearFocus()
        RaidMount.currentSearch = ""
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
            RaidMount.PopulateUI()
        end
    end)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == placeholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
        clearButton:Show()
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(placeholder)
            self:SetTextColor(0.6, 0.6, 0.6, 1)
            clearButton:Hide()
        end
    end)
    
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local currentText = self:GetText()
            
            -- Show/hide clear button based on text content
            if currentText ~= "" and currentText ~= placeholder then
                clearButton:Show()
            else
                clearButton:Hide()
            end
            
            -- Cancel previous timer to prevent conflicts
            if searchTimer then
                searchTimer:Cancel()
                searchTimer = nil
            end
            
            -- Only process if text actually changed
            if currentText ~= lastSearchText then
                lastSearchText = currentText
                
                if currentText ~= placeholder then
                    RaidMount.currentSearch = currentText:lower():trim()
                    
                    -- Debounce search with timer
                    searchTimer = C_Timer.After(0.1, function()
                        searchTimer = nil
                        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
                            RaidMount.PopulateUI()
                        end
                        RaidMount.UpdateFilterStatusDisplay()
                    end)
                elseif currentText == "" or currentText == placeholder then
                    RaidMount.currentSearch = ""
                    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
                        RaidMount.PopulateUI()
                    end
                    RaidMount.UpdateFilterStatusDisplay()
                end
            end
        end
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
    
    -- Add Escape key support to clear search
    searchBox:SetScript("OnEscapePressed", function(self)
        if self:GetText() ~= "" and self:GetText() ~= placeholder then
            self:SetText("")
            RaidMount.currentSearch = ""
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
    
    -- Create filter dropdowns
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
    lastSearchText = ""
end

-- Clear all filters function
function RaidMount.ClearAllFilters()
    -- Reset all filter variables
    RaidMount.currentFilter = "All"
    RaidMount.currentExpansionFilters = {}
    RaidMount.currentContentTypeFilter = "All"
    RaidMount.currentDifficultyFilter = "All"
    RaidMount.currentSearch = ""
    
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
    
    -- Update the UI
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
        RaidMount.PopulateUI()
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
    
    -- Collection Status filter
    local collectedDropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", filterContainer, "UIDropDownMenuTemplate")
    collectedDropdown:SetPoint("TOPLEFT", 0, row1Y)
    UIDropDownMenu_Initialize(collectedDropdown, function()
        local options = {"All", "Collected", "Uncollected"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(collectedDropdown, option)
                UIDropDownMenu_SetText(collectedDropdown, option)
                RaidMount.currentFilter = option
                if not RaidMount.isStatsView then 
                    RaidMount.PopulateUI() 
                end
                RaidMount.UpdateFilterStatusDisplay()
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
    UIDropDownMenu_Initialize(expansionDropdown, function()
        local expansions = {
            "All", "Classic", "The Burning Crusade", "Wrath of the Lich King", 
            "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", 
            "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within", "Holiday Event"
        }
        
        for _, expansion in ipairs(expansions) do
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
                
                if not RaidMount.isStatsView then 
                    RaidMount.PopulateUI() 
                end
                RaidMount.UpdateFilterStatusDisplay()
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
    UIDropDownMenu_Initialize(contentTypeDropdown, function()
        local options = {"All", "Raid", "Dungeon", "World", "Collector's Bounty"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(contentTypeDropdown, option)
                UIDropDownMenu_SetText(contentTypeDropdown, option)
                RaidMount.currentContentTypeFilter = option
                if not RaidMount.isStatsView then 
                    RaidMount.PopulateUI() 
                end
                RaidMount.UpdateFilterStatusDisplay()
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
    UIDropDownMenu_Initialize(difficultyDropdown, function()
        local options = {"All", "Normal", "Heroic", "Mythic", "LFR", "Timewalking"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(difficultyDropdown, option)
                UIDropDownMenu_SetText(difficultyDropdown, option)
                RaidMount.currentDifficultyFilter = option
                if not RaidMount.isStatsView then 
                    RaidMount.PopulateUI() 
                end
                RaidMount.UpdateFilterStatusDisplay()
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
        RaidMount.ClearAllFilters()
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
        if searchText ~= "" and searchText ~= RaidMount.L("SEARCH_PLACEHOLDER"):lower() then
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
    local currentExpansionFilter = RaidMount.currentExpansionFilter
    local currentContentTypeFilter = RaidMount.currentContentTypeFilter
    local currentDifficultyFilter = RaidMount.currentDifficultyFilter
    
    for _, mount in ipairs(mountData) do
        local includeMount = true
        
        -- Filter by collection status (improved logic)
        if currentFilter == "Collected" then
            if not mount.collected then
                includeMount = false
            end
        elseif currentFilter == "Uncollected" then
            if mount.collected then
                includeMount = false
            end
        end
        
        -- Expansion filter (multi-select)
        if RaidMount.currentExpansionFilters and next(RaidMount.currentExpansionFilters) then
            local mountExpansion = (mount.expansion or "Unknown"):lower()
            local isIncluded = false
            
            for expansion in pairs(RaidMount.currentExpansionFilters) do
                if mountExpansion == expansion:lower() then
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
                if not mount.collectorsBounty then
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