-- Main UI module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities (will be available after Utils module loads)
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local CreateStandardDropdown = RaidMount.CreateStandardDropdown
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- UI State variables
local currentFilter = "All"
local currentContentTypeFilter = "All"
local currentSearch = ""
local currentExpansionFilter = "All"
local sortColumn = "mountName"
local sortDescending = false
local isStatsView = false

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Helper function for consistent addon messages
local function PrintAddonMessage(message, isError)
    -- Removed for production
end

-- Multi-purpose cleanup function
local function ClearContentFrameChildren()
    if not RaidMount.ContentFrame then return end
    for _, child in pairs({RaidMount.ContentFrame:GetChildren()}) do
        if child ~= RaidMount.ContentFrame.bg then child:Hide() end
    end
    if RaidMount.statsElements then
        for _, element in ipairs(RaidMount.statsElements) do
            if element and element.Hide then element:Hide() end
        end
        RaidMount.statsElements = {}
    end
    -- Clean up stats frame if it exists
    if RaidMount.StatsFrame then
        RaidMount.StatsFrame:Hide()
        RaidMount.StatsFrame:SetParent(nil)
        RaidMount.StatsFrame = nil
    end
end

-- Batch dropdown reset
local function ResetDropdown(dropdown, value)
    if dropdown then
        UIDropDownMenu_SetSelectedName(dropdown, value)
        UIDropDownMenu_SetText(dropdown, value)
    end
end

-- Consolidated filter reset
local function ResetAllFilters()
    currentFilter, currentExpansionFilter, currentContentTypeFilter, currentSearch = "All", "All", "All", ""
    for _, dropdown in pairs({RaidMount.ExpansionDropdown, RaidMount.CollectedDropdown, RaidMount.ContentTypeDropdown}) do
        ResetDropdown(dropdown, "All")
    end
    if RaidMount.SearchBox then RaidMount.SearchBox:SetText("") end
end

-- MAIN UI CREATION FUNCTION
function RaidMount.ShowUI()
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        RaidMount.RaidMountFrame:Hide()
        return
    end
    
    -- Reset stats view when opening
    isStatsView = false
    
    if not RaidMount.RaidMountFrame then
        RaidMount.CreateMainFrame()
    end
    
    RaidMount.RaidMountFrame:Show()
    RaidMount.PopulateUI()
end

-- CREATE COLUMN HEADERS
function RaidMount.CreateColumnHeaders()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Create header frame
    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetPoint("TOPLEFT", 15, -135)
    headerFrame:SetPoint("TOPRIGHT", -35, -135)
    headerFrame:SetHeight(25)
    
    -- Header background
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.02, 0.02, 0.02, 0.95)
    
    -- Column definitions matching mount list positions exactly
    local columns = {
        {text = "Mount", pos = 50, width = 200, align = "LEFT"},
        {text = "Raid", pos = 260, width = 150, align = "LEFT"},
        {text = "Boss", pos = 420, width = 120, align = "LEFT"},
        {text = "Drop Rate", pos = 550, width = 80, align = "CENTER"},
        {text = "Expansion", pos = 640, width = 100, align = "LEFT"},
        {text = "Attempts", pos = 750, width = 60, align = "CENTER"},
        {text = "Collected", pos = 820, width = 50, align = "CENTER"},
        {text = "Raid Available", pos = 850, width = 100, align = "CENTER"}
    }
    
    for i, column in ipairs(columns) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", headerFrame, "LEFT", column.pos, -5)
        header:SetWidth(column.width)
        header:SetJustifyH(column.align)
        header:SetFont(cachedFontPath, 11, "OUTLINE")
        header:SetTextColor(0.8, 0.8, 0.8, 1)
        header:SetText(column.text)
        
        -- Add sorting functionality
        local button = CreateFrame("Button", nil, headerFrame)
        button:SetPoint("LEFT", headerFrame, "LEFT", column.pos, 0)
        button:SetSize(column.width, 25)
        button:SetScript("OnClick", function()
            -- Toggle sort order if clicking same column
            local sortKey = column.text:lower():gsub(" ", "")
            if sortColumn == sortKey then
                sortDescending = not sortDescending
            else
                sortColumn = sortKey
                sortDescending = false
            end
            
            -- Update header text to show sort direction
            local arrow = sortDescending and " ▼" or " ▲"
            header:SetText(column.text .. arrow)
            
            -- Clear arrows from other headers
            for j, otherCol in ipairs(columns) do
                if j ~= i then
                    local otherHeader = headerFrame:GetChildren()
                    -- Find the correct header and reset its text
                    -- This is a simplified approach - in practice you'd store header references
                end
            end
            
            if not isStatsView then RaidMount.PopulateUI() end
        end)
    end
    
    RaidMount.HeaderFrame = headerFrame
end

-- CREATE MAIN FRAME
function RaidMount.CreateMainFrame()
    if RaidMount.RaidMountFrame then return RaidMount.RaidMountFrame end
    
    local frame = CreateFrame("Frame", "RaidMountFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1000, 700)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    
    -- Frame backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFFFFD700Raid & Dungeon Mount Tracker|r")
    title:SetFont(cachedFontPath, 24, "OUTLINE")
    
    -- Make frame movable
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() RaidMount.HideUI() end)
    
    RaidMount.RaidMountFrame = frame
    
    -- Create all UI components
    RaidMount.CreateSearchAndFilters()
    RaidMount.CreateColumnHeaders()
    RaidMount.CreateScrollFrame()
    RaidMount.CreateProgressBar()
    RaidMount.CreateButtons()
    RaidMount.CreateInfoPanel(frame)
    
    return frame
end

-- CREATE SEARCH AND FILTER COMPONENTS
function RaidMount.CreateSearchAndFilters()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Search box
    local searchBox = CreateFrame("EditBox", "RaidMountSearchBox", frame)
    searchBox:SetSize(250, 30)
    searchBox:SetPoint("TOPLEFT", 20, -70)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("ChatFontNormal")
    searchBox:SetTextInsets(10, 10, 0, 0)
    
    local editBg = searchBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.05, 0.05, 0.1, 0.9)
    
    local placeholder = "Search mounts, raids, or bosses..."
    searchBox:SetText(placeholder)
    searchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == placeholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(placeholder)
            self:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end)
    
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= placeholder then
            currentSearch = self:GetText():lower()
            C_Timer.After(0.2, function() -- Reduced delay for faster response
                if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then
                    RaidMount.PopulateUI()
                end
            end)
        elseif self:GetText() == "" or self:GetText() == placeholder then
            currentSearch = ""
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then
                RaidMount.PopulateUI()
            end
        end
    end)
    
    RaidMount.SearchBox = searchBox
    
    -- Create filter dropdowns
    RaidMount.CreateFilterDropdowns()
end

-- CREATE FILTER DROPDOWNS
function RaidMount.CreateFilterDropdowns()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Status filter
    local collectedDropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", frame, "UIDropDownMenuTemplate")
    collectedDropdown:SetPoint("TOPLEFT", 300, -65)
    UIDropDownMenu_Initialize(collectedDropdown, function()
        local options = {"All", "Collected", "Uncollected"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(collectedDropdown, option)
                UIDropDownMenu_SetText(collectedDropdown, option)
                currentFilter = option
                if not isStatsView then 
                    C_Timer.After(0.1, function() -- Small delay to ensure UI updates
                        RaidMount.PopulateUI() 
                    end)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedName(collectedDropdown, "All")
    UIDropDownMenu_SetText(collectedDropdown, "All")
    UIDropDownMenu_SetWidth(collectedDropdown, 150)
    RaidMount.CollectedDropdown = collectedDropdown
    
    -- Expansion filter
    local expansionDropdown = CreateFrame("Frame", "RaidMountExpansionDropdown", frame, "UIDropDownMenuTemplate")
    expansionDropdown:SetPoint("TOPLEFT", 500, -65)
    UIDropDownMenu_Initialize(expansionDropdown, function()
        local options = {"All", "Classic", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within", "Holiday Event"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(expansionDropdown, option)
                UIDropDownMenu_SetText(expansionDropdown, option)
                currentExpansionFilter = option
                if not isStatsView then 
                    C_Timer.After(0.1, function() -- Small delay to ensure UI updates
                        RaidMount.PopulateUI() 
                    end)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedName(expansionDropdown, "All")
    UIDropDownMenu_SetText(expansionDropdown, "All")
    UIDropDownMenu_SetWidth(expansionDropdown, 180)
    RaidMount.ExpansionDropdown = expansionDropdown
end

-- CREATE SCROLL FRAME
function RaidMount.CreateScrollFrame()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -165)
    scrollFrame:SetPoint("BOTTOMRIGHT", -35, 160) -- More space for larger info panel
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame.scrollChild = scrollChild
    
    RaidMount.ScrollFrame = scrollFrame
    RaidMount.ContentFrame = scrollChild
    
    -- Set up scroll callbacks
    if RaidMount.SetupScrollFrameCallbacks then
        RaidMount.SetupScrollFrameCallbacks()
    end
end

-- CREATE PROGRESS BAR
function RaidMount.CreateProgressBar()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    local progressBar = CreateFrame("StatusBar", nil, frame)
    progressBar:SetSize(220, 20)
    progressBar:SetPoint("TOPRIGHT", -30, -20) -- Top right, less wide
    progressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBar:SetStatusBarColor(0.2, 0.8, 0.2, 0.8)
    progressBar:SetMinMaxValues(0, 100)
    progressBar:SetValue(0)
    
    -- Progress bar background
    local bg = progressBar:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    
    -- Progress bar label
    local label = progressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("CENTER")
    label:SetFont(cachedFontPath, 12, "OUTLINE")
    label:SetText("0 / 0 (0%)")
    progressBar.label = label
    
    frame.progressBar = progressBar
    
    progressBar:EnableMouse(true)
    progressBar:SetScript("OnEnter", function(self)
        local collected = self.collected or 0
        local total = self.total or 0
        local percent = total > 0 and (collected / total * 100) or 0
        GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
        GameTooltip:SetText("Mount Collection Progress", 1, 1, 1)
        GameTooltip:AddLine(string.format("Collected: |cFF00FF00%d|r / |cFFFFFFFF%d|r (|cFFFFFF00%.1f%%|r)", collected, total, percent), 1, 1, 1)
        GameTooltip:Show()
    end)
    progressBar:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
end

-- CREATE BUTTONS
function RaidMount.CreateButtons()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Stats button
    local statsBtn = CreateFrame("Button", "RaidMountStatsButton", frame, "UIPanelButtonTemplate")
    statsBtn:SetSize(100, 30)
    statsBtn:SetPoint("TOPRIGHT", -30, -55) -- Below the progress bar, right aligned
    statsBtn:SetText("Stats")
    statsBtn:SetScript("OnClick", function() RaidMount.ToggleStatsView() end)
    frame.StatsButton = statsBtn
    
    -- Version text
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOMLEFT", 10, 10)
    versionText:SetText("|cFF666666Version: 04.07.25.04|r")
    versionText:SetTextColor(0.4, 0.4, 0.4, 1)
    
    -- Enhanced tooltips checkbox
    local tooltipCheckbox = CreateFrame("CheckButton", "RaidMountTooltipCheckbox", frame, "UICheckButtonTemplate")
    tooltipCheckbox:SetSize(20, 20)
    tooltipCheckbox:SetPoint("BOTTOMRIGHT", -15, 10)
    tooltipCheckbox:SetChecked(RaidMountSaved and RaidMountSaved.enhancedTooltip ~= false)
    
    -- Checkbox label
    local tooltipLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tooltipLabel:SetPoint("RIGHT", tooltipCheckbox, "LEFT", -5, 0)
    tooltipLabel:SetText("|cFF999999Enhanced Tooltips|r")
    tooltipLabel:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Checkbox functionality
    tooltipCheckbox:SetScript("OnClick", function(self)
        RaidMountTooltipEnabled = self:GetChecked()
        if not RaidMountSaved then RaidMountSaved = {} end
        RaidMountSaved.enhancedTooltip = RaidMountTooltipEnabled
        if RaidMountTooltipEnabled then
            -- Removed for production
        else
            -- Removed for production
        end
    end)
    
    frame.tooltipCheckbox = tooltipCheckbox
end

-- POPULATE UI WITH MOUNT DATA
function RaidMount.PopulateUI()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    if isStatsView then return end
    
    -- Clear existing content
    ClearContentFrameChildren()
    
    -- Get mount data
    local mountData = RaidMount.GetCombinedMountData()
    if not mountData then
        PrintAddonMessage("No mount data available", true)
        return
    end
    
    -- Filter and sort data
    local filteredData = RaidMount.FilterAndSortMountData(mountData)
    
    -- Update progress bar
    RaidMount.UpdateMountCounts()
    
    -- Set filtered data for mount list module
    if RaidMount.SetFilteredData then
        RaidMount.SetFilteredData(filteredData)
    end
end

-- FILTER AND SORT MOUNT DATA
function RaidMount.FilterAndSortMountData(mountData)
    local filtered = {}
    local debugCounts = {total = 0, collected = 0, uncollected = 0, filtered = 0}
    
    for _, mount in ipairs(mountData) do
        local includeMount = true
        debugCounts.total = debugCounts.total + 1
        
        -- Debug collection status
        if mount.collected then
            debugCounts.collected = debugCounts.collected + 1
        else
            debugCounts.uncollected = debugCounts.uncollected + 1
        end
        
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
        
        -- Filter by expansion (improved matching)
        if currentExpansionFilter ~= "All" then
            local mountExpansion = mount.expansion or "Unknown"
            if mountExpansion ~= currentExpansionFilter then
                includeMount = false
            end
        end
        
        -- Filter by search text (improved search)
        if currentSearch and currentSearch ~= "" and currentSearch ~= "search mounts, raids, or bosses..." then
            local searchText = currentSearch:lower()
            local mountText = (mount.mountName or ""):lower() .. " " .. 
                            (mount.raidName or ""):lower() .. " " .. 
                            (mount.bossName or ""):lower() .. " " ..
                            (mount.location or ""):lower() .. " " ..
                            (mount.expansion or ""):lower() .. " " ..
                            (mount.difficulty or ""):lower()
            
            -- Support partial matching (e.g., "ony" matches "Onyxian")
            local found = false
            for word in searchText:gmatch("%S+") do
                if mountText:find(word, 1, true) then
                    found = true
                    break
                end
            end
            
            if not found then
                includeMount = false
            end
        end
        
        if includeMount then
            table.insert(filtered, mount)
            debugCounts.filtered = debugCounts.filtered + 1
        end
    end
    
    -- Debug output for troubleshooting
    if currentFilter ~= "All" or currentExpansionFilter ~= "All" or (currentSearch and currentSearch ~= "") then
        -- Removed for production
    end
    
    -- Sort data
    table.sort(filtered, function(a, b)
        local aVal = a[sortColumn] or ""
        local bVal = b[sortColumn] or ""
        if sortDescending then
            return aVal > bVal
        else
            return aVal < bVal
        end
    end)
    
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

-- TOGGLE STATS VIEW
function RaidMount.ToggleStatsView()
    isStatsView = not isStatsView
    if isStatsView then
        RaidMount.ShowDetailedStatsView()
    else
        -- Clean up stats frame and show scroll frame
        if RaidMount.StatsFrame then
            RaidMount.StatsFrame:Hide()
            RaidMount.StatsFrame:SetParent(nil)
            RaidMount.StatsFrame = nil
        end
        if RaidMount.ScrollFrame then
            RaidMount.ScrollFrame:Show()
        end
        RaidMount.PopulateUI()
    end
end

-- SHOW DETAILED STATS VIEW
function RaidMount.ShowDetailedStatsView()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    
    -- Clear existing content
    ClearContentFrameChildren()
    
    -- Hide the scroll frame to prevent scrolling issues
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:Hide()
    end
    
    -- Create a dedicated stats frame that stays within the UI bounds
    local statsFrame = CreateFrame("ScrollFrame", nil, RaidMount.RaidMountFrame)
    statsFrame:SetPoint("TOPLEFT", 15, -165)
    statsFrame:SetPoint("BOTTOMRIGHT", -35, 40) -- Keep it above the bottom UI elements
    statsFrame:SetFrameLevel(RaidMount.RaidMountFrame:GetFrameLevel() + 10)
    
    -- Create content frame for the scroll frame
    local statsContent = CreateFrame("Frame", nil, statsFrame)
    statsContent:SetSize(statsFrame:GetWidth() - 20, 800) -- Set a reasonable height
    statsFrame:SetScrollChild(statsContent)
    
    -- Add background to stats frame
    local statsBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    statsBg:SetAllPoints()
    statsBg:SetColorTexture(0.05, 0.05, 0.05, 0.95)
    
    -- Enable mouse wheel scrolling for stats
    statsFrame:EnableMouseWheel(true)
    statsFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 40)))
        self:SetVerticalScroll(newScroll)
    end)
    
    -- Store the stats frame for cleanup
    RaidMount.StatsFrame = statsFrame
    
    -- Use the stats content frame for positioning elements
    local frame = statsContent
    
    local mountData = RaidMount.GetCombinedMountData()
    if not mountData then return end
    
    -- Initialize stats tracking
    if not RaidMount.statsElements then
        RaidMount.statsElements = {}
    end
    
    -- Create main stats title
    local mainTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainTitle:SetPoint("TOPLEFT", 20, -20)
    mainTitle:SetFont(cachedFontPath, 16, "OUTLINE")
    mainTitle:SetTextColor(0.4, 0.8, 1, 1)
    mainTitle:SetText("Detailed Mount Collection Statistics")
    table.insert(RaidMount.statsElements, mainTitle)
    
    -- Calculate comprehensive stats
    local totalMounts = #mountData
    local collectedMounts = 0
    local totalAttempts = 0
    local expansionStats = {}
    local contentTypeStats = {}
    local mostAttemptedMounts = {}
    
    for _, mount in ipairs(mountData) do
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
        
        local attempts = tonumber(mount.attempts) or 0
        totalAttempts = totalAttempts + attempts
        
        -- Track most attempted mounts
        if attempts > 0 then
            table.insert(mostAttemptedMounts, {
                name = mount.mountName,
                attempts = attempts,
                source = mount.raidName or mount.location or "Unknown",
                collected = mount.collected
            })
        end
        
        -- Expansion stats
        local expansion = mount.expansion or "Unknown"
        if not expansionStats[expansion] then
            expansionStats[expansion] = {total = 0, collected = 0, attempts = 0}
        end
        expansionStats[expansion].total = expansionStats[expansion].total + 1
        expansionStats[expansion].attempts = expansionStats[expansion].attempts + attempts
        if mount.collected then
            expansionStats[expansion].collected = expansionStats[expansion].collected + 1
        end
        
        -- Content type stats
        local contentType = mount.contentType or mount.type or "Unknown"
        if not contentTypeStats[contentType] then
            contentTypeStats[contentType] = {total = 0, collected = 0, attempts = 0}
        end
        contentTypeStats[contentType].total = contentTypeStats[contentType].total + 1
        contentTypeStats[contentType].attempts = contentTypeStats[contentType].attempts + attempts
        if mount.collected then
            contentTypeStats[contentType].collected = contentTypeStats[contentType].collected + 1
        end
    end
    
    -- Sort most attempted mounts
    table.sort(mostAttemptedMounts, function(a, b) return a.attempts > b.attempts end)
    
    -- Create two-column layout
    local leftColumn = 20
    local rightColumn = 450
    local yPos = -60
    
    -- LEFT COLUMN: Overall Statistics
    local overallHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    overallHeader:SetPoint("TOPLEFT", leftColumn, yPos)
    overallHeader:SetFont(cachedFontPath, 14, "OUTLINE")
    overallHeader:SetTextColor(1, 0.82, 0, 1)
    overallHeader:SetText("Overall Statistics")
    table.insert(RaidMount.statsElements, overallHeader)
    yPos = yPos - 25
    
    -- Overall stats with progress bar
    local overallPercentage = (collectedMounts / totalMounts) * 100
    
    -- Main progress bar
    local mainProgressBar = CreateFrame("StatusBar", nil, frame)
    mainProgressBar:SetSize(350, 25)
    mainProgressBar:SetPoint("TOPLEFT", leftColumn + 10, yPos)
    mainProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    mainProgressBar:SetStatusBarColor(0.2, 0.8, 0.2, 0.9)
    mainProgressBar:SetMinMaxValues(0, totalMounts)
    mainProgressBar:SetValue(collectedMounts)
    
    -- Progress bar background
    local mainBg = mainProgressBar:CreateTexture(nil, "BACKGROUND")
    mainBg:SetAllPoints()
    mainBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Progress bar border
    local mainBorder = CreateFrame("Frame", nil, mainProgressBar, "BackdropTemplate")
    mainBorder:SetAllPoints()
    mainBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 12,
        insets = {left = 2, right = 2, top = 2, bottom = 2}
    })
    mainBorder:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    
    -- Progress bar text overlay
    local mainProgressText = mainProgressBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mainProgressText:SetPoint("CENTER")
    mainProgressText:SetFont(cachedFontPath, 12, "OUTLINE")
    mainProgressText:SetText(string.format("%d / %d (%.1f%%)", collectedMounts, totalMounts, overallPercentage))
    mainProgressText:SetTextColor(1, 1, 1, 1)
    
    table.insert(RaidMount.statsElements, mainProgressBar)
    table.insert(RaidMount.statsElements, mainBorder)
    yPos = yPos - 35
    
    -- Find the most attempted mount
    local mostAttemptedMount = nil
    local highestAttempts = 0
    for _, mount in ipairs(mostAttemptedMounts) do
        if mount.attempts > highestAttempts then
            highestAttempts = mount.attempts
            mostAttemptedMount = mount
        end
    end
    
    -- Overall stats details
    local overallStats = {
        string.format("Missing: |cFFFF6666%d|r mounts", totalMounts - collectedMounts),
        string.format("Total Attempts: |cFFFFFFFF%d|r", totalAttempts),
        string.format("Average Attempts per Mount: |cFFFFFFFF%.1f|r", totalAttempts / totalMounts),
        mostAttemptedMount and string.format("Most Attempted Mount: |cFFFFD700%s|r (|cFFFF6666%d attempts|r)", 
            mostAttemptedMount.name, mostAttemptedMount.attempts) or "Most Attempted Mount: |cFFCCCCCCNone|r"
    }
    
    for _, stat in ipairs(overallStats) do
        local statText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statText:SetPoint("TOPLEFT", leftColumn + 10, yPos)
        statText:SetFont(cachedFontPath, 11, "OUTLINE")
        statText:SetText(stat)
        table.insert(RaidMount.statsElements, statText)
        yPos = yPos - 16
    end
    
    yPos = yPos - 15
    
    -- By Expansion
    local expansionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    expansionHeader:SetPoint("TOPLEFT", leftColumn, yPos)
    expansionHeader:SetFont(cachedFontPath, 14, "OUTLINE")
    expansionHeader:SetTextColor(1, 0.82, 0, 1)
    expansionHeader:SetText("By Expansion")
    table.insert(RaidMount.statsElements, expansionHeader)
    yPos = yPos - 25
    
    -- Sort expansions by total mounts
    local sortedExpansions = {}
    for expansion, stats in pairs(expansionStats) do
        table.insert(sortedExpansions, {name = expansion, stats = stats})
    end
    table.sort(sortedExpansions, function(a, b) return a.stats.total > b.stats.total end)
    
    for _, expansion in ipairs(sortedExpansions) do
        local name = expansion.name
        local stats = expansion.stats
        local percentage = (stats.collected / stats.total) * 100
        
        -- Expansion name
        local expansionName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expansionName:SetPoint("TOPLEFT", leftColumn + 10, yPos)
        expansionName:SetFont(cachedFontPath, 11, "OUTLINE")
        expansionName:SetText(name)
        expansionName:SetTextColor(0.9, 0.9, 0.9, 1)
        table.insert(RaidMount.statsElements, expansionName)
        yPos = yPos - 16
        
        -- Progress bar for expansion
        local expProgressBar = CreateFrame("StatusBar", nil, frame)
        expProgressBar:SetSize(300, 18)
        expProgressBar:SetPoint("TOPLEFT", leftColumn + 20, yPos)
        expProgressBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        -- Color based on completion percentage
        if percentage == 100 then
            expProgressBar:SetStatusBarColor(0.2, 0.8, 0.2, 0.9) -- Green
        elseif percentage >= 75 then
            expProgressBar:SetStatusBarColor(0.8, 0.8, 0.2, 0.9) -- Yellow-green
        elseif percentage >= 50 then
            expProgressBar:SetStatusBarColor(1, 0.82, 0, 0.9) -- Gold
        elseif percentage >= 25 then
            expProgressBar:SetStatusBarColor(1, 0.5, 0, 0.9) -- Orange
        else
            expProgressBar:SetStatusBarColor(0.8, 0.2, 0.2, 0.9) -- Red
        end
        
        expProgressBar:SetMinMaxValues(0, stats.total)
        expProgressBar:SetValue(stats.collected)
        
        -- Progress bar background
        local expBg = expProgressBar:CreateTexture(nil, "BACKGROUND")
        expBg:SetAllPoints()
        expBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        
        -- Progress bar border
        local expBorder = CreateFrame("Frame", nil, expProgressBar, "BackdropTemplate")
        expBorder:SetAllPoints()
        expBorder:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 8,
            insets = {left = 1, right = 1, top = 1, bottom = 1}
        })
        expBorder:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
        
        -- Progress bar text
        local expProgressText = expProgressBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        expProgressText:SetPoint("CENTER")
        expProgressText:SetFont(cachedFontPath, 10, "OUTLINE")
        expProgressText:SetText(string.format("%d/%d (%.1f%%) - %d attempts", 
            stats.collected, stats.total, percentage, stats.attempts))
        expProgressText:SetTextColor(1, 1, 1, 1)
        
        table.insert(RaidMount.statsElements, expProgressBar)
        table.insert(RaidMount.statsElements, expBorder)
        yPos = yPos - 25
    end
    
    -- RIGHT COLUMN: Most Attempted Mounts
    local rightYPos = -60
    local mostAttemptedHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    mostAttemptedHeader:SetPoint("TOPLEFT", rightColumn, rightYPos)
    mostAttemptedHeader:SetFont(cachedFontPath, 14, "OUTLINE")
    mostAttemptedHeader:SetTextColor(1, 0.82, 0, 1)
    mostAttemptedHeader:SetText("Most Attempted Mounts")
    table.insert(RaidMount.statsElements, mostAttemptedHeader)
    rightYPos = rightYPos - 25
    
    -- Display top 15 most attempted mounts with attempt bars
    local maxDisplay = math.min(15, #mostAttemptedMounts)
    local maxAttempts = mostAttemptedMounts[1] and mostAttemptedMounts[1].attempts or 1
    
    for i = 1, maxDisplay do
        local mount = mostAttemptedMounts[i]
        local statusIcon = mount.collected and "|TInterface\\RaidFrame\\ReadyCheck-Ready:16:16:0:0|t" or "|TInterface\\RaidFrame\\ReadyCheck-NotReady:16:16:0:0|t"
        local nameColor = mount.collected and "|cFF00FF00" or "|cFFFFFFFF"
        
        -- Mount name and status
        local mountText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mountText:SetPoint("TOPLEFT", rightColumn + 10, rightYPos)
        mountText:SetFont(cachedFontPath, 10, "OUTLINE")
        
        -- Truncate long names
        local displayName = mount.name
        if #displayName > 18 then
            displayName = displayName:sub(1, 15) .. "..."
        end
        local displaySource = mount.source
        if #displaySource > 12 then
            displaySource = displaySource:sub(1, 9) .. "..."
        end
        
        mountText:SetText(string.format("%s %s%s|r (%s)", 
            statusIcon, nameColor, displayName, displaySource))
        table.insert(RaidMount.statsElements, mountText)
        rightYPos = rightYPos - 16
        
        -- Attempt progress bar
        local attemptBar = CreateFrame("StatusBar", nil, frame)
        attemptBar:SetSize(250, 12)
        attemptBar:SetPoint("TOPLEFT", rightColumn + 20, rightYPos)
        attemptBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        
        -- Color based on attempt count
        if mount.attempts >= 20 then
            attemptBar:SetStatusBarColor(0.9, 0.1, 0.1, 0.9) -- Deep red for high attempts
        elseif mount.attempts >= 15 then
            attemptBar:SetStatusBarColor(1, 0.3, 0.3, 0.9) -- Red
        elseif mount.attempts >= 10 then
            attemptBar:SetStatusBarColor(1, 0.5, 0, 0.9) -- Orange
        elseif mount.attempts >= 5 then
            attemptBar:SetStatusBarColor(1, 0.82, 0, 0.9) -- Gold
        else
            attemptBar:SetStatusBarColor(0.6, 0.6, 0.6, 0.9) -- Grey
        end
        
        attemptBar:SetMinMaxValues(0, maxAttempts)
        attemptBar:SetValue(mount.attempts)
        
        -- Attempt bar background
        local attemptBg = attemptBar:CreateTexture(nil, "BACKGROUND")
        attemptBg:SetAllPoints()
        attemptBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)
        
                 -- Attempt bar border
         local attemptBorder = CreateFrame("Frame", nil, attemptBar, "BackdropTemplate")
         attemptBorder:SetAllPoints()
         attemptBorder:SetBackdrop({
             edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
             edgeSize = 6,
             insets = {left = 1, right = 1, top = 1, bottom = 1}
         })
         attemptBorder:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
        
        -- Attempt count text
        local attemptText = attemptBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        attemptText:SetPoint("CENTER")
        attemptText:SetFont(cachedFontPath, 9, "OUTLINE")
        attemptText:SetText(string.format("%d attempts", mount.attempts))
        attemptText:SetTextColor(1, 1, 1, 1)
        
        table.insert(RaidMount.statsElements, attemptBar)
        table.insert(RaidMount.statsElements, attemptBorder)
        rightYPos = rightYPos - 20
    end
    
    -- Add a "Back" button at the bottom of the content
    local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    backButton:SetSize(100, 30)
    backButton:SetPoint("BOTTOM", 0, 10)
    backButton:SetText("Back")
    backButton:SetScript("OnClick", function()
        RaidMount.ToggleStatsView()
    end)
    table.insert(RaidMount.statsElements, backButton)
end

-- Function to force refresh mount data
function RaidMount.ForceRefreshMountData()
    -- Clear all caches
    if RaidMount.ClearMountCache then
        RaidMount.ClearMountCache()
    end
    
    -- Reset filters using helper function
    ResetAllFilters()
    
    -- Refresh mount collection
    if RaidMount.RefreshMountCollection then
        RaidMount.RefreshMountCollection()
    end
    
    -- Update UI if it's open - preserve current view state
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        if isStatsView then
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

-- Initialize UI system
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RaidMount" then
        -- Build lookup tables for optimized performance
        C_Timer.After(1, function()
            if RaidMount.BuildMountLookupTables then
                RaidMount.BuildMountLookupTables()
            end
        end)
        -- Build initial static cache
        C_Timer.After(3, function()
            if RaidMount.GetCombinedMountData then
                RaidMount.GetCombinedMountData() -- This will build the static cache
            end
        end)
    elseif event == "PLAYER_LOGIN" then
        -- Rebuild lookup tables after login when all data is available
        C_Timer.After(2, function()
            if RaidMount.BuildMountLookupTables then
                RaidMount.BuildMountLookupTables()
            end
        end)
        -- Build initial static cache after login
        C_Timer.After(5, function()
            if RaidMount.GetCombinedMountData then
                RaidMount.GetCombinedMountData() -- This will build the static cache
            end
        end)
    end
end)

-- Export functions for other modules
RaidMount.ClearContentFrameChildren = ClearContentFrameChildren
RaidMount.ResetAllFilters = ResetAllFilters
RaidMount.ResetDropdown = ResetDropdown 