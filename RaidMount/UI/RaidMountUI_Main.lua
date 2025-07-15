-- Main UI module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities (will be available after Utils module loads)
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local CreateStandardDropdown = RaidMount.CreateStandardDropdown
local PrintAddonMessage = RaidMount.PrintAddonMessage

RaidMount.currentFilter = RaidMount.currentFilter or "All"
RaidMount.currentContentTypeFilter = RaidMount.currentContentTypeFilter or "All"
RaidMount.currentDifficultyFilter = RaidMount.currentDifficultyFilter or "All"
RaidMount.currentSearch = RaidMount.currentSearch or ""
RaidMount.currentExpansionFilter = RaidMount.currentExpansionFilter or "All"
RaidMount.sortColumn = RaidMount.sortColumn or "mountName"
RaidMount.sortDescending = RaidMount.sortDescending or false
RaidMount.isStatsView = RaidMount.isStatsView or false

-- Track last non-stats view
RaidMount.lastViewType = RaidMount.lastViewType or "list"

local cachedFontPath = "Fonts\\FRIZQT__.TTF"

local function PrintAddonMessage(message, isError)
end

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
    if RaidMount.StatsFrame then
        RaidMount.StatsFrame:Hide()
        RaidMount.StatsFrame:SetParent(nil)
        RaidMount.StatsFrame = nil
    end
end

local function ResetDropdown(dropdown, value)
    if dropdown then
        UIDropDownMenu_SetSelectedName(dropdown, value)
        UIDropDownMenu_SetText(dropdown, value)
    end
end

local function ResetAllFilters()
    RaidMount.currentFilter, RaidMount.currentExpansionFilter, RaidMount.currentContentTypeFilter, RaidMount.currentDifficultyFilter, RaidMount.currentSearch = "All", "All", "All", "All", ""
    for _, dropdown in pairs({RaidMount.ExpansionDropdown, RaidMount.CollectedDropdown, RaidMount.ContentTypeDropdown, RaidMount.DifficultyDropdown}) do
        ResetDropdown(dropdown, "All")
    end
    if RaidMount.SearchBox then 
        RaidMount.SearchBox:SetText("Search mounts, raids, or bosses...")
        RaidMount.SearchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    end
end

function RaidMount.ShowUI()
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        RaidMount.RaidMountFrame:Hide()
        return
    end
    
    RaidMount.isStatsView = false
    
    if not RaidMount.RaidMountFrame then
        RaidMount.CreateMainFrame()
    end
    
    RaidMount.RaidMountFrame:Show()
    RaidMount.PopulateUI()
end

function RaidMount.CreateColumnHeaders()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    local headerFrame = CreateFrame("Frame", nil, frame)
    headerFrame:SetPoint("TOPLEFT", 15, -150)
    headerFrame:SetPoint("TOPRIGHT", -35, -150)
    headerFrame:SetHeight(25)
    
    local headerBg = headerFrame:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(0.02, 0.02, 0.02, 0.95)
    
    local columns = {
        {text = "Mount", pos = 50, width = 180, align = "LEFT", sortKey = "mountName"},
        {text = "Raid", pos = 240, width = 130, align = "LEFT", sortKey = "raidName"},
        {text = "Boss", pos = 380, width = 100, align = "LEFT", sortKey = "bossName"},
        {text = "Drop Rate", pos = 490, width = 70, align = "CENTER", sortKey = "dropRate"},
        {text = "Expansion", pos = 570, width = 90, align = "LEFT", sortKey = "expansion"},
        {text = "Attempts", pos = 670, width = 50, align = "CENTER", sortKey = "attempts"},
        {text = "Collected", pos = 730, width = 50, align = "CENTER", sortKey = "collected"},
        {text = "Lockout", pos = 790, width = 120, align = "CENTER", sortKey = "lockout"},
        {text = RaidMount.L("COORDINATES"), pos = 920, width = 80, align = "CENTER", sortKey = "coordinates"}
    }
    
    local headerTexts = {}
    
    for i, column in ipairs(columns) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", headerFrame, "LEFT", column.pos, -5)
        header:SetWidth(column.width)
        header:SetJustifyH(column.align)
        header:SetFont(cachedFontPath, 11, "OUTLINE")
        header:SetTextColor(0.8, 0.8, 0.8, 1)
        header:SetText(column.text)
        
        headerTexts[i] = {header = header, originalText = column.text, sortKey = column.sortKey}
        
        if not header then
            print("RaidMount: Error - Failed to create header for column " .. column.text)
        end
        
        local button = CreateFrame("Button", nil, headerFrame)
        button:SetPoint("LEFT", headerFrame, "LEFT", column.pos, 0)
        button:SetSize(column.width, 25)
        
        button:SetScript("OnEnter", function(self)
            header:SetTextColor(1, 1, 0, 1)
        end)
        
        button:SetScript("OnLeave", function(self)
            header:SetTextColor(0.8, 0.8, 0.8, 1)
        end)
        
        button:SetScript("OnClick", function()
            if RaidMount.sortColumn == column.sortKey then
                RaidMount.sortDescending = not RaidMount.sortDescending
            else
                RaidMount.sortColumn = column.sortKey
                RaidMount.sortDescending = false
            end
            
            for j, headerData in ipairs(headerTexts) do
                if headerData.sortKey == RaidMount.sortColumn then
                    local arrowChar = RaidMount.sortDescending and " |TInterface\\Buttons\\Arrow-Down-Up:12:12|t" or " |TInterface\\Buttons\\Arrow-Up-Up:12:12|t"
                    headerData.header:SetText(headerData.originalText .. arrowChar)
                    headerData.header:SetTextColor(1, 0.8, 0, 1)
                else
                    headerData.header:SetText(headerData.originalText)
                    headerData.header:SetTextColor(0.8, 0.8, 0.8, 1)
                end
            end
            
            if not RaidMount.isStatsView then RaidMount.PopulateUI() end
        end)
    end
    
    RaidMount.HeaderFrame = headerFrame
    RaidMount.HeaderTexts = headerTexts
end

function RaidMount.CreateMainFrame()
    if RaidMount.RaidMountFrame then return RaidMount.RaidMountFrame end
    
    local frame = CreateFrame("Frame", "RaidMountFrame", UIParent, "BackdropTemplate")
    frame:SetSize(1050, 700)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("HIGH")
    
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
    title:SetText("|cFF33CCFFRaid|r and |cFF33CCFFDungeon|r |cFFFF0000Mount|r |cFFFFD700Tracker|r")
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
    RaidMount.CreateFilterStatusDisplay(frame)
    
    return frame
end

-- Filter functionality moved to RaidMountUI_Filters.lua

-- CREATE SCROLL FRAME
function RaidMount.CreateScrollFrame()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 15, -180)
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
        GameTooltip:SetText(RaidMount.L("PROGRESS_TOOLTIP"), 1, 1, 1)
        GameTooltip:AddLine(string.format(RaidMount.L("PROGRESS_FORMAT"), collected, total, percent), 1, 1, 1)
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
    statsBtn:SetText(RaidMount.L("STATS"))
    statsBtn:SetScript("OnClick", function() RaidMount.ToggleStatsView() end)
    frame.StatsButton = statsBtn
    
    -- Version text
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOMLEFT", 10, 10)
            versionText:SetText("|cFF666666Version: 15.07.25.30|r")
    versionText:SetTextColor(0.4, 0.4, 0.4, 1)
    
    -- Enhanced tooltips checkbox
    local tooltipCheckbox = CreateFrame("CheckButton", "RaidMountTooltipCheckbox", frame, "UICheckButtonTemplate")
    tooltipCheckbox:SetSize(20, 20)
    tooltipCheckbox:SetPoint("BOTTOMRIGHT", -150, 10)
    tooltipCheckbox:SetChecked(RaidMountSaved and RaidMountSaved.enhancedTooltip ~= false)

    -- Mount drop sound checkbox
    local soundCheckbox = CreateFrame("CheckButton", "RaidMountSoundCheckbox", frame, "UICheckButtonTemplate")
    soundCheckbox:SetSize(20, 20)
    soundCheckbox:SetPoint("RIGHT", tooltipCheckbox, "LEFT", -90, 0)
    soundCheckbox:SetChecked(RaidMountSettings and RaidMountSettings.mountDropSound ~= false)

    -- Popup enabled checkbox
    local popupCheckbox = CreateFrame("CheckButton", "RaidMountPopupCheckbox", frame, "UICheckButtonTemplate")
    popupCheckbox:SetSize(20, 20)
    popupCheckbox:SetPoint("RIGHT", soundCheckbox, "LEFT", -90, 0)
    popupCheckbox:SetChecked(RaidMountSaved and RaidMountSaved.popupEnabled ~= false)

    -- Popup label
    local popupLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    popupLabel:SetPoint("RIGHT", popupCheckbox, "LEFT", -8, 0)
    popupLabel:SetText("|cFF999999World Boss Alert|r")
    popupLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Character Checker button (moved to bottom right)
    local charCheckerButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    charCheckerButton:SetSize(120, 25)
    charCheckerButton:SetPoint("BOTTOMRIGHT", -15, 10)
    charCheckerButton:SetText("Alt Data")
    charCheckerButton:SetScript("OnClick", function()
        if RaidMount.UpdateCharacterChecker then
            -- Check if character checker frame exists and is shown
            local charFrame = _G["RaidMountCharacterChecker"]
            if charFrame and charFrame:IsShown() then
                charFrame:Hide()
            else
                RaidMount.UpdateCharacterChecker()
            end
        else
            print("Character checker not available. Try /rm characters instead.")
        end
    end)

    -- Sound label
    local soundLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    soundLabel:SetPoint("RIGHT", soundCheckbox, "LEFT", -5, 0)
    soundLabel:SetText("|cFF999999Mount Drop Sound|r")
    soundLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Checkbox label
    local tooltipLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tooltipLabel:SetPoint("RIGHT", tooltipCheckbox, "LEFT", -5, 0)
    tooltipLabel:SetText("|cFF999999" .. RaidMount.L("ENHANCED_TOOLTIPS") .. "|r")
    tooltipLabel:SetTextColor(0.6, 0.6, 0.6, 1)

    -- Checkbox functionality
    tooltipCheckbox:SetScript("OnClick", function(self)
        RaidMountTooltipEnabled = self:GetChecked()
        if not RaidMountSaved then RaidMountSaved = {} end
        RaidMountSaved.enhancedTooltip = RaidMountTooltipEnabled
    end)
    soundCheckbox:SetScript("OnClick", function(self)
        if not RaidMountSettings then RaidMountSettings = {} end
        RaidMountSettings.mountDropSound = self:GetChecked()
    end)
    popupCheckbox:SetScript("OnClick", function(self)
        if not RaidMountSaved then RaidMountSaved = {} end
        RaidMountSaved.popupEnabled = self:GetChecked()
    end)

    frame.tooltipCheckbox = tooltipCheckbox
    frame.soundCheckbox = soundCheckbox
    frame.popupCheckbox = popupCheckbox
end

-- UPDATE HEADER DISPLAY
function RaidMount.UpdateHeaderDisplay()
    if not RaidMount.HeaderTexts then 
        print(RaidMount.L("ERROR_HEADERS_NOT_INIT"))
        return 
    end
    
    -- Update all headers to show current sort state
    for i, headerData in ipairs(RaidMount.HeaderTexts) do
        -- Safety check to ensure header exists
        if not headerData or not headerData.header then
            print(RaidMount.L("ERROR_HEADER_DATA_MISSING", i))
            return
        end
        

        
        if headerData.sortKey == RaidMount.sortColumn then
            -- Use Blizzard arrow symbols
            local arrowChar = RaidMount.sortDescending and " |TInterface\\Buttons\\Arrow-Down-Up:12:12|t" or " |TInterface\\Buttons\\Arrow-Up-Up:12:12|t"
            headerData.header:SetText(headerData.originalText .. arrowChar)
            headerData.header:SetTextColor(1, 0.8, 0, 1) -- Gold for active sort
        else
            headerData.header:SetText(headerData.originalText)
            headerData.header:SetTextColor(0.8, 0.8, 0.8, 1) -- Normal color
        end
    end
end

-- POPULATE UI
function RaidMount.PopulateUI()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    
    local mountData = RaidMount.GetCombinedMountData()
    if not mountData then return end
    
    -- Filter and sort the data
    local filteredData = RaidMount.FilterAndSortMountData(mountData)
    
    -- Update header display to show current sort
    RaidMount.UpdateHeaderDisplay()
    
    -- Update the mount list display
    if RaidMount.SetFilteredData then
        RaidMount.SetFilteredData(filteredData)
    end
    
    -- Update icon view if it's active
    if RaidMount.isIconView and RaidMount.RefreshIconView then
        RaidMount.RefreshIconView()
    end
    
    -- Update mount counts
    RaidMount.UpdateMountCounts()
end

-- Centralized view management
function RaidMount.ShowView(viewType)
    -- Aggressively hide all possible views first
    if RaidMount.StatsFrame then
        RaidMount.StatsFrame:Hide()
        RaidMount.StatsFrame:SetParent(nil)
        RaidMount.StatsFrame = nil
    end
    if RaidMount.HideIconView then RaidMount.HideIconView() end
    if RaidMount.ScrollFrame then RaidMount.ScrollFrame:Hide() end

    -- Show the requested view
    if viewType == "stats" then
        RaidMount.isStatsView = true
        RaidMount.ShowDetailedStatsView()
    elseif viewType == "icon" then
        RaidMount.isStatsView = false
        RaidMount.isIconView = true
        RaidMount.lastViewType = "icon"
        RaidMount.ShowIconView()
    elseif viewType == "list" then
        RaidMount.isStatsView = false
        RaidMount.isIconView = false
        RaidMount.lastViewType = "list"
        if RaidMount.ScrollFrame then
            RaidMount.ScrollFrame:Show()
            RaidMount.ScrollFrame:SetVerticalScroll(0)
            if RaidMount.ClearVisibleRows then RaidMount.ClearVisibleRows() end
            if RaidMount.PopulateUI then RaidMount.PopulateUI() end
            -- Force a full list rebuild
            if RaidMount.GetCombinedMountData and RaidMount.FilterAndSortMountData and RaidMount.SetFilteredData then
                local mountData = RaidMount.GetCombinedMountData()
                local filteredData = RaidMount.FilterAndSortMountData(mountData)
                RaidMount.SetFilteredData(filteredData)
            end
            C_Timer.After(0, function()
                if RaidMount.UpdateVisibleRowsOptimized then
                    RaidMount.UpdateVisibleRowsOptimized()
                elseif RaidMount.UpdateVisibleRows then
                    RaidMount.UpdateVisibleRows()
                end
            end)
        end
    end
end

-- Refactor stats toggle to use ShowView
function RaidMount.ToggleStatsView()
    RaidMount.isStatsView = not RaidMount.isStatsView
    if RaidMount.isStatsView then
        RaidMount.ShowView("stats")
    else
        RaidMount.ShowView(RaidMount.lastViewType or "list")
    end
end

-- On UI load or /reload, show only the correct view
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "PLAYER_LOGIN" or (event == "ADDON_LOADED" and addonName == "RaidMount") then
        if RaidMount.isStatsView then
            RaidMount.ShowView("stats")
        else
            RaidMount.ShowView(RaidMount.lastViewType or "list")
        end
    end
end)

-- CREATE FILTER STATUS DISPLAY
function RaidMount.CreateFilterStatusDisplay(frame)
    if not frame then return end
    
    -- Create filter status text (positioned below the new filter container)
    local filterStatusText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    filterStatusText:SetPoint("TOPLEFT", 20, -120)
            filterStatusText:SetText(RaidMount.L("NO_FILTERS_ACTIVE"))
    filterStatusText:SetTextColor(0.6, 0.6, 0.6, 1)
    
    frame.filterStatusText = filterStatusText
end

-- Export functions for other modules
RaidMount.ClearContentFrameChildren = ClearContentFrameChildren
RaidMount.ResetAllFilters = ResetAllFilters
RaidMount.ResetDropdown = ResetDropdown

function RaidMount.HideUI()
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
    end
    
    -- Reset search state to prevent timer conflicts
    if RaidMount.ResetSearchState then
        RaidMount.ResetSearchState()
    end
end 