-- Main UI module for RaidMount
local addonName, RaidMount = ...

RaidMount = RaidMount or {}

-- Performance optimization: Use local variables for frequently accessed functions
local UnitName = UnitName
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local CreateFrame = CreateFrame
local C_Timer = C_Timer
local PlaySound = PlaySound
local wipe = wipe
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local string_format = string.format
local math_floor = math.floor
local math_ceil = math.ceil
local math_min = math.min
local math_max = math.max

-- Import utilities (will be available after Utils module loads)
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local CreateStandardDropdown = RaidMount.CreateStandardDropdown
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Initialize filter variables with proper defaults
RaidMount.currentFilter = RaidMount.currentFilter or "All"
RaidMount.currentExpansionFilter = RaidMount.currentExpansionFilter or "All"
RaidMount.currentContentTypeFilter = RaidMount.currentContentTypeFilter or "All"
RaidMount.currentDifficultyFilter = RaidMount.currentDifficultyFilter or "All"
RaidMount.currentSearch = RaidMount.currentSearch or ""
RaidMount.sortColumn = RaidMount.sortColumn or "mountName"
RaidMount.sortDescending = RaidMount.sortDescending or false

-- Performance optimization variables
RaidMount.textureCache = RaidMount.textureCache or {}
RaidMount.performanceStats = RaidMount.performanceStats or {
    textureCache = { hits = 0, misses = 0 }
}

-- Track last non-stats view
RaidMount.lastViewType = RaidMount.lastViewType or "list"

-- cachedFontPath is handled by Utils.lua
-- rowHeight is handled by MountList_Core.lua

-- PrintAddonMessage is handled by RaidMount.lua

local function ClearContentFrameChildren()
    if not RaidMount.ContentFrame then return end
    for _, child in pairs({ RaidMount.ContentFrame:GetChildren() }) do
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
    RaidMount.currentFilter, RaidMount.currentExpansionFilter, RaidMount.currentContentTypeFilter, RaidMount.currentDifficultyFilter, RaidMount.currentSearch =
        "All", "All", "All", "All", ""
    
    -- Clear filter cache to prevent cached 0 results
    if RaidMount.ClearFilterCache then
        RaidMount.ClearFilterCache()
    end
    
    for _, dropdown in pairs({ RaidMount.ExpansionDropdown, RaidMount.CollectedDropdown, RaidMount.ContentTypeDropdown, RaidMount.DifficultyDropdown }) do
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
    
    -- Force refresh lockouts immediately when UI opens
    if RaidMount.ForceRefreshLockouts then
        RaidMount.ForceRefreshLockouts()
    end
    
    -- Reset filters to ensure proper initialization
    if RaidMount.ClearAllFilters then
        RaidMount.ClearAllFilters()
    else
        ResetAllFilters()
    end
    
    -- Ensure initialization and data loading before populating UI
    if RaidMount.EnsureInitialized then
        RaidMount.EnsureInitialized()
    end
    
    -- Use delayed population to ensure data is loaded
    RaidMount.ScheduleDelayedTask(0.1, function()
        -- Refresh character data when UI is opened
        if RaidMount.PopulateCharacterMountData then
            RaidMount.PopulateCharacterMountData()
        end
        
        if RaidMount.PopulateUI then
            RaidMount.PopulateUI()
        end
    end, "showui_populate")
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
        { text = "Mount",                    pos = 50,  width = 180, align = "LEFT",   sortKey = "mountName" },
        { text = "Raid",                     pos = 240, width = 130, align = "LEFT",   sortKey = "raidName" },
        { text = "Boss",                     pos = 380, width = 100, align = "LEFT",   sortKey = "bossName" },
        { text = "Drop Rate",                pos = 490, width = 70,  align = "CENTER", sortKey = "dropRate" },
        { text = "Expansion",                pos = 570, width = 90,  align = "LEFT",   sortKey = "expansion" },
        { text = "Attempts",                 pos = 670, width = 50,  align = "CENTER", sortKey = "attempts" },
        { text = "Collected",                pos = 730, width = 50,  align = "CENTER", sortKey = "collected" },
        { text = "Instance",               pos = 790, width = 120, align = "CENTER" },
        { text = RaidMount.L("COORDINATES"), pos = 920, width = 60, align = "CENTER" }
    }

    local headerTexts = {}

    for i, column in ipairs(columns) do
        local header = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        header:SetPoint("LEFT", headerFrame, "LEFT", column.pos, -5)
        header:SetWidth(column.width)
        header:SetJustifyH(column.align)
        header:SetFont(RaidMount.cachedFontPath, 11, "OUTLINE")
        header:SetTextColor(0.8, 0.8, 0.8, 1)
        header:SetText(column.text)

        headerTexts[i] = { header = header, originalText = column.text, sortKey = column.sortKey }

        if not header then
            print("RaidMount: Error - Failed to create header for column " .. column.text)
        end

        -- Only create clickable buttons for columns with sortKey
        if column.sortKey then
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
                        local arrowChar = RaidMount.sortDescending and " |TInterface\\Buttons\\Arrow-Down-Up:12:12|t" or
                            " |TInterface\\Buttons\\Arrow-Up-Up:12:12|t"
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
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    -- Title
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -15)
    title:SetText("|cFF33CCFFRaid|r and |cFF33CCFFDungeon|r |cFFFF0000Mount|r |cFFFFD700Tracker|r")
    title:SetFont(RaidMount.cachedFontPath, 24, "OUTLINE")

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

    -- Set up scroll callbacks for optimized scrolling
    RaidMount.SetupScrollFrameCallbacks()
end

-- Setup optimized scroll callbacks (delegates to Buttons module)
-- This function is now handled by the Buttons module
-- The actual implementation is in RaidMountUI_MountList_Buttons.lua

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
    label:SetFont(RaidMount.cachedFontPath, 12, "OUTLINE")
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
        GameTooltip:AddLine(string_format(RaidMount.L("PROGRESS_FORMAT"), collected, total, percent), 1, 1, 1)
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
            versionText:SetText("|cFF666666Version: 29.07.25.45|r")
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
            local arrowChar = RaidMount.sortDescending and " |TInterface\\Buttons\\Arrow-Down-Up:12:12|t" or
                " |TInterface\\Buttons\\Arrow-Up-Up:12:12|t"
            headerData.header:SetText(headerData.originalText .. arrowChar)
            headerData.header:SetTextColor(1, 0.8, 0, 1) -- Gold for active sort
        else
            headerData.header:SetText(headerData.originalText)
            headerData.header:SetTextColor(0.8, 0.8, 0.8, 1) -- Normal color
        end
    end
end

-- Optimized UI population with reduced debug output and better error handling
function RaidMount.PopulateUI()
    -- Early exit checks
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then 
        return 
    end

    -- Ensure data is loaded with single retry
    if not RaidMount.mountInstances or #RaidMount.mountInstances == 0 then
        if RaidMount.EnsureInitialized then
            RaidMount.EnsureInitialized()
        end
        -- Single retry with task scheduler
        RaidMount.ScheduleDelayedTask(0.02, function() -- Reduced from 0.05s to 0.02s
            if RaidMount.PopulateUI and RaidMount.mountInstances and #RaidMount.mountInstances > 0 then
                RaidMount.PopulateUI()
            end
        end, "populate_ui_retry")
        return
    end

    -- Get and validate mount data
    local success, mountData = pcall(RaidMount.GetCombinedMountData)
    if not success or not mountData or #mountData == 0 then
        return
    end

    -- Use optimized filter and sort with error handling
    local filteredSuccess, filteredData = pcall(RaidMount.OptimizedFilterAndSort, mountData)
    if not filteredSuccess or not filteredData then
        return
    end

    -- Update header display to show current sort
    if RaidMount.UpdateHeaderDisplay then
        pcall(RaidMount.UpdateHeaderDisplay)
    end

    -- Ensure scroll frame is visible
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:Show()
    end

    -- Update the mount list display immediately with optimized rendering
    if RaidMount.SetFilteredData then
        pcall(RaidMount.SetFilteredData, filteredData)
    end

    -- Force immediate scroll frame update with reduced overhead
    if RaidMount.UpdateVisibleRowsOptimized then
        pcall(RaidMount.UpdateVisibleRowsOptimized)
    elseif RaidMount.UpdateVisibleRows then
        pcall(RaidMount.UpdateVisibleRows)
    end

    -- Update icon view if it's active
    if RaidMount.isIconView and RaidMount.RefreshIconView then
        pcall(RaidMount.RefreshIconView)
    end

    -- Update mount counts
    if RaidMount.UpdateMountCounts then
        pcall(RaidMount.UpdateMountCounts)
    end
    
    -- Update filter status display immediately
    if RaidMount.UpdateFilterStatusDisplay then
        pcall(RaidMount.UpdateFilterStatusDisplay)
    end
end

-- Optimized view switching with consolidated updates
function RaidMount.ShowView(viewType)
    
    -- Clear any cached lockout data to ensure fresh data
    if RaidMount.ClearTooltipCache then
        RaidMount.ClearTooltipCache()
    end
    
    -- Aggressively hide all possible views first
    if RaidMount.StatsFrame then
        RaidMount.StatsFrame:Hide()
        RaidMount.StatsFrame:SetParent(nil)
        RaidMount.StatsFrame = nil
    end
    if RaidMount.HideIconView then RaidMount.HideIconView() end
    
    -- Don't hide scroll frame for list view
    if viewType ~= "list" and RaidMount.ScrollFrame then 
        RaidMount.ScrollFrame:Hide() 
    end

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
        -- Show list view
        if RaidMount.ScrollFrame then
            RaidMount.ScrollFrame:Show()
            RaidMount.ScrollFrame:SetVerticalScroll(0)
            if RaidMount.ClearVisibleRows then RaidMount.ClearVisibleRows() end
            
            -- Single consolidated update instead of multiple calls
            RaidMount.ScheduleDelayedTask(0.1, function()
                if RaidMount.PopulateUI then RaidMount.PopulateUI() end
                if RaidMount.UpdateVisibleRowsOptimized then
                    RaidMount.UpdateVisibleRowsOptimized()
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
        -- Ensure initialization (with safety check)
        if RaidMount.EnsureInitialized then
            RaidMount.EnsureInitialized()
        end
        
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

-- Clear all filters function (delegates to Filters module)
-- This function is now handled by the Filters module
-- The actual implementation is in RaidMountUI_Filters.lua

-- Remove duplicate function definitions - these are now in UI/RaidMountUI_Filters.lua
-- function RaidMount.OptimizedFilterAndSort(mountData)
-- function RaidMount.GetCombinedMountData()
-- function RaidMount.UpdateMountCounts()

-- Export functions for other modules
RaidMount.ClearContentFrameChildren = ClearContentFrameChildren
RaidMount.ResetAllFilters = ResetAllFilters
RaidMount.ResetDropdown = ResetDropdown

-- Function to show boss drop mounts in a copyable window
function RaidMount.ShowDropMountWindow(dropMounts)
    -- Create the window if it doesn't exist
    if not RaidMount.DropMountFrame then
        RaidMount.DropMountFrame = CreateFrame("Frame", "RaidMountDropFrame", UIParent, "BasicFrameTemplateWithInset")
        RaidMount.DropMountFrame:SetSize(600, 500)
        RaidMount.DropMountFrame:SetPoint("CENTER")
        RaidMount.DropMountFrame:SetMovable(true)
        RaidMount.DropMountFrame:EnableMouse(true)
        RaidMount.DropMountFrame:RegisterForDrag("LeftButton")
        RaidMount.DropMountFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        RaidMount.DropMountFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

        -- Title
        RaidMount.DropMountFrame.title = RaidMount.DropMountFrame:CreateFontString(nil, "OVERLAY",
            "GameFontHighlightLarge")
        RaidMount.DropMountFrame.title:SetPoint("TOP", 0, -10)
        RaidMount.DropMountFrame.title:SetText("Boss Drop Mounts - Spell IDs")

        -- Subtitle
        RaidMount.DropMountFrame.subtitle = RaidMount.DropMountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        RaidMount.DropMountFrame.subtitle:SetPoint("TOP", 0, -30)
        RaidMount.DropMountFrame.subtitle:SetTextColor(0.8, 0.8, 0.8, 1)

        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, RaidMount.DropMountFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)

        -- Create edit box for copyable text
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(550)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

        scrollFrame:SetScrollChild(editBox)
        RaidMount.DropMountFrame.editBox = editBox

        -- Close button
        local closeButton = CreateFrame("Button", nil, RaidMount.DropMountFrame, "UIPanelButtonTemplate")
        closeButton:SetSize(80, 25)
        closeButton:SetPoint("BOTTOMRIGHT", -20, 10)
        closeButton:SetText(RaidMount.L("CLOSE"))
        closeButton:SetScript("OnClick", function()
            -- Clean up header frame before hiding
            if RaidMount.HeaderFrame then
                RaidMount.HeaderFrame:Hide()
                RaidMount.HeaderFrame:SetParent(nil)
                RaidMount.HeaderFrame = nil
            end
            RaidMount.DropMountFrame:Hide()
        end)

        -- Select All button
        local selectButton = CreateFrame("Button", nil, RaidMount.DropMountFrame, "UIPanelButtonTemplate")
        selectButton:SetSize(80, 25)
        selectButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
        selectButton:SetText(RaidMount.L("SELECT_ALL"))
        selectButton:SetScript("OnClick", function()
            RaidMount.DropMountFrame.editBox:SetFocus()
            RaidMount.DropMountFrame.editBox:HighlightText()
        end)
    end

    -- Build the text content
    local textContent = string.format("Boss Drop Mounts from Mount Journal (%d total)\n", #dropMounts)
    textContent = textContent .. "Format: [Status] Mount Name (MountID: X, SpellID: Y)\n"
    textContent = textContent .. "Status: ✓ = Collected, ✗ = Not Collected\n\n"

    for _, mount in ipairs(dropMounts) do
        local statusIcon = mount.isCollected and "✓" or "✗"
        textContent = textContent .. string.format("%s %s (MountID: %d, SpellID: %d)\n",
            statusIcon, mount.name, mount.MountID, mount.spellID)
    end

    -- Set the text and adjust height
    RaidMount.DropMountFrame.editBox:SetText(textContent)
    RaidMount.DropMountFrame.editBox:SetHeight(math.max(400, #dropMounts * 15 + 100))

    -- Show the window
    RaidMount.DropMountFrame:Show()
end

function RaidMount.HideUI()
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
    end

    -- Reset search state to prevent timer conflicts
    if RaidMount.ResetSearchState then
        RaidMount.ResetSearchState()
    end
    
    -- Clean up mount list resources
    if RaidMount.CleanupMountList then
        RaidMount.CleanupMountList()
    end
end

-- Comprehensive cleanup function for addon shutdown
function RaidMount.CleanupUI()
    -- Hide UI first
    RaidMount.HideUI()
    
    -- Clean up all UI components
    if RaidMount.CleanupMountList then
        RaidMount.CleanupMountList()
    end
    
    -- Clear caches
    if RaidMount.ClearTextureCache then
        RaidMount.ClearTextureCache()
    end
    
    if RaidMount.ClearTooltipCache then
        RaidMount.ClearTooltipCache()
    end
    
    -- Clean up task scheduler (handled by Core/RaidMountSession.lua)
    
end
