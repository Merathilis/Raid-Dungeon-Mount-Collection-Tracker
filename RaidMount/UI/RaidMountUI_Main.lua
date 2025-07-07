-- Main UI module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities (will be available after Utils module loads)
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local CreateStandardDropdown = RaidMount.CreateStandardDropdown
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- UI State variables (shared across modules)
RaidMount.currentFilter = RaidMount.currentFilter or "All"
RaidMount.currentContentTypeFilter = RaidMount.currentContentTypeFilter or "All"
RaidMount.currentSearch = RaidMount.currentSearch or ""
RaidMount.currentExpansionFilter = RaidMount.currentExpansionFilter or "All"
RaidMount.sortColumn = RaidMount.sortColumn or "mountName"
RaidMount.sortDescending = RaidMount.sortDescending or false
RaidMount.isStatsView = RaidMount.isStatsView or false

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
    RaidMount.currentFilter, RaidMount.currentExpansionFilter, RaidMount.currentContentTypeFilter, RaidMount.currentSearch = "All", "All", "All", ""
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
    RaidMount.isStatsView = false
    
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
            if RaidMount.sortColumn == sortKey then
                RaidMount.sortDescending = not RaidMount.sortDescending
            else
                RaidMount.sortColumn = sortKey
                RaidMount.sortDescending = false
            end
            
            -- Update header text to show sort direction
            local arrow = RaidMount.sortDescending and " ▼" or " ▲"
            header:SetText(column.text .. arrow)
            
            -- Clear arrows from other headers
            for j, otherCol in ipairs(columns) do
                if j ~= i then
                    local otherHeader = headerFrame:GetChildren()
                    -- Find the correct header and reset its text
                    -- This is a simplified approach - in practice you'd store header references
                end
            end
            
            if not RaidMount.isStatsView then RaidMount.PopulateUI() end
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

-- Filter functionality moved to RaidMountUI_Filters.lua

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
    versionText:SetText("|cFF666666Version: 07.07.25.15|r")
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
    if RaidMount.isStatsView then return end
    
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

-- Data processing functionality moved to RaidMountUI_Filters.lua

-- TOGGLE STATS VIEW
function RaidMount.ToggleStatsView()
    RaidMount.isStatsView = not RaidMount.isStatsView
    if RaidMount.isStatsView then
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

-- Stats functionality moved to RaidMountUI_Stats.lua

-- Debug functionality moved to RaidMountUI_Debug.lua

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

function RaidMount.HideUI()
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
    end
end 