local addonName, RaidMount = ...
RaidMount = RaidMount or {}

if not RaidMount then
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r |cFFFF0000Error:|r RaidMount table is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
    return
end

-- Initialize global table for attempts
if not RaidMountAttempts then
    RaidMountAttempts = {}
end

-- UI State variables
local currentFilter = "All"
local currentContentTypeFilter = "All"
local currentSearch = ""
local currentExpansionFilter = "All"
local sortColumn = "mountName"
local sortDescending = false
local isStatsView = false

-- Helper function for consistent addon messages
local function PrintAddonMessage(message, isError)
    local prefix = isError and "|cFF33CCFFRaid|r|cFFFF0000Mount|r |cFFFF0000Error:|r" or "|cFF33CCFFRaid|r|cFFFF0000Mount|r:|r"
    print(prefix .. " " .. message)
end



-- OPTIMIZED HELPER FUNCTIONS

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

-- Universal dropdown factory
local function CreateStandardDropdown(parent, name, label, options, defaultValue, onSelectCallback)
    local dropdownLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownLabel:SetText(label)
    dropdownLabel:SetFont(cachedFontPath, 12, "OUTLINE")
    
    local dropdown = CreateFrame("Frame", name, parent, "UIDropDownMenuTemplate")
    UIDropDownMenu_Initialize(dropdown, function()
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, option)
                UIDropDownMenu_SetText(dropdown, option)
                if onSelectCallback then onSelectCallback(option) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(dropdown, defaultValue)
    UIDropDownMenu_SetText(dropdown, defaultValue)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    
    return dropdown, dropdownLabel
end

-- Black Theme Color Palette
local COLORS = {
    -- Primary colors (gray tones for black theme)
    primary = {0.4, 0.4, 0.4, 1},           -- Gray
    primaryDark = {0.2, 0.2, 0.2, 1},       -- Dark gray
    secondary = {0.6, 0.6, 0.6, 1},         -- Light gray
    
    -- Background colors (black theme)
    background = {0.05, 0.05, 0.05, 0.95},  -- Almost black
    panelBg = {0.1, 0.1, 0.1, 0.9},         -- Dark gray
    headerBg = {0.02, 0.02, 0.02, 0.95},    -- Pure black
    
    -- Status colors
    collected = {0.2, 0.8, 0.2, 1},         -- Green
    uncollected = {0.9, 0.4, 0.4, 1},       -- Red
    neutral = {0.7, 0.7, 0.7, 1},           -- Gray
    
    -- Text colors
    text = {0.95, 0.95, 0.95, 1},           -- Off-white
    textSecondary = {0.8, 0.8, 0.8, 1},     -- Light gray
    textMuted = {0.6, 0.6, 0.6, 1},         -- Muted gray
    
    -- Accent colors
    gold = {1, 0.82, 0, 1},                 -- Gold
    warning = {1, 0.65, 0, 1},              -- Orange
    success = {0.2, 0.8, 0.2, 1},           -- Green
    error = {0.9, 0.2, 0.2, 1},             -- Red
}



-- Function to force refresh mount data
function RaidMount.ForceRefreshMountData()
    -- Clear all caches
    mountDataCache = nil
    mountDataCacheTime = 0
    RaidMount.ClearMountCache()
    
    -- Reset filters using helper function
    ResetAllFilters()
    
    -- Refresh mount collection
    RaidMount.RefreshMountCollection()
    
    -- Update UI if it's open - preserve current view state
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        if isStatsView then
            RaidMount.ShowDetailedStatsView()
        else
            RaidMount.PopulateUI()
        end
    end
    
    local mountData = RaidMount.GetCombinedMountData()
    PrintAddonMessage("Mount data refreshed! Found " .. #mountData .. " mounts.")
end

function RaidMount.Debug()
    local mountData = RaidMount.GetCombinedMountData()
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r:|r " .. #mountData .. " mounts loaded")
end

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Optimization: Create lookup tables for faster mount data access
local mountLookupBySpellID = {}
local mountLookupByName = {}
local expansionMountCounts = {}

-- Build lookup tables on initialization
local function BuildMountLookupTables()
    if not RaidMount.mountInstances then return end
    
    -- Clear existing lookups
    mountLookupBySpellID = {}
    mountLookupByName = {}
    expansionMountCounts = {}
    
    for i, mount in ipairs(RaidMount.mountInstances) do
        if mount.spellID then
            mountLookupBySpellID[mount.spellID] = i
        end
        if mount.mountName then
            mountLookupByName[mount.mountName:lower()] = i
        end
        
        -- Pre-calculate expansion counts
        local expansion = mount.expansion or "Unknown"
        if not expansionMountCounts[expansion] then
            expansionMountCounts[expansion] = 0
        end
        expansionMountCounts[expansion] = expansionMountCounts[expansion] + 1
    end
end

-- Text element pool for reuse (properly implemented)
-- Minimal memory approach - only create what's visible
local visibleRows = {}
local maxVisibleRows = 25 -- Only create frames for visible rows
local rowHeight = 25

-- Performance caches
-- Static data cache - only rebuild on actual game events
local staticMountDataCache = nil
local staticDataVersion = 0
local filteredDataCache = nil
local sortCache = nil
local lastFilterState = {hash = ""} -- Initialize with hash field
local mountDataCache = nil
local mountDataCacheTime = 0
local CACHE_DURATION = 30 -- Cache for 30 seconds

-- Throttling mechanism for UI updates (increased efficiency)
local lastUpdateTime = 0
local updateThrottleDelay = 0.05 -- Reduced from 0.1 for better responsiveness
local pendingUpdate = false





-- OPTIMIZED STYLING SYSTEM

-- Multi-purpose background creator with hover support
local function CreateStyledBackground(parent, color, hoverColor)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(parent)
    bg:SetColorTexture(unpack(color or COLORS.panelBg))
    
    if hoverColor then
        parent:SetScript("OnEnter", function() bg:SetColorTexture(unpack(hoverColor)) end)
        parent:SetScript("OnLeave", function() bg:SetColorTexture(unpack(color or COLORS.panelBg)) end)
    end
    
    -- Optional border
    local border = parent:CreateTexture(nil, "BORDER")
    border:SetAllPoints(parent)
    border:SetColorTexture(unpack(COLORS.primary))
    border:SetAlpha(0.3)
    
    return bg, border
end

-- Consolidated text creator
local function CreateStandardFontString(parent, fontType, text, fontSize, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", fontType or "GameFontNormal")
    if fontSize then fontString:SetFont(cachedFontPath, fontSize, "OUTLINE") end
    if text then fontString:SetText(text) end
    if color then fontString:SetTextColor(unpack(color)) end
    return fontString
end

-- Simplified positioning
local function PositionElement(element, parent, anchor, xOffset, yOffset)
    element:SetPoint(anchor or "TOPLEFT", parent, anchor or "TOPLEFT", xOffset or 0, yOffset or 0)
end

-- Compact checkbox creator
local function CreateLabeledCheckbox(parent, labelText, xPos, yPos, isChecked, onClickCallback)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", xPos, yPos)
    checkbox:SetSize(25, 25)
    checkbox:SetChecked(isChecked)
    
    local label = CreateStandardFontString(parent, "GameFontNormal", labelText, 12, COLORS.text)
    label:SetPoint("LEFT", checkbox, "RIGHT", 10, 0)
    
    if onClickCallback then
        checkbox:SetScript("OnClick", onClickCallback)
    end
    
    return checkbox, label
end

-- MEMORY-EFFICIENT MAIN FRAME SETUP
local function CreateMainFrame()
    if RaidMount.RaidMountFrame then return end
    
    -- Create frame programmatically for better memory control
    local frameWidth = RaidMountSettings.compactMode and 1100 or 1300
    local frame = CreateFrame("Frame", "RaidMountFrame", UIParent, "BackdropTemplate")
    RaidMount.RaidMountFrame = frame
    
    -- Configure frame properties efficiently
    frame:SetSize(frameWidth, 750)
    frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -20, -20)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetScale(RaidMountSettings.uiScale or 1.0)
    frame:SetToplevel(true)
    frame:Hide()
    
    -- Add to UI special frames for ESC handling
    tinsert(UISpecialFrames, "RaidMountFrame")
    
    -- Set up backdrop efficiently
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Drag functionality
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -8, -8)
    closeButton:SetScript("OnClick", function()
        -- Clean up header frame before hiding
        if RaidMount.HeaderFrame then
            RaidMount.HeaderFrame:Hide()
            RaidMount.HeaderFrame:SetParent(nil)
            RaidMount.HeaderFrame = nil
        end
        frame:Hide()
        -- Restore main mount list when closing settings
        if RaidMount.RaidMountFrame then
            RaidMount.RaidMountFrame:Show()
        end
    end)
    
    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("|cFF33CCFFRaid and Dungeon Mount Tracker|r")
    titleText:SetTextColor(0.2, 0.8, 1, 1)
    
    -- Mount count text
    frame.mountCountText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.mountCountText:SetPoint("TOPRIGHT", -20, -50)
    frame.mountCountText:SetText("|TInterface\\Icons\\Ability_Mount_RidingHorse:20:20:0:0|t Loading stats...")
    frame.mountCountText:Show()
    
    -- Version text
    local versionText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    versionText:SetPoint("BOTTOMLEFT", 10, 10)
    versionText:SetText("|cFF666666Version: 12.06.25.00|r")
    versionText:SetTextColor(0.4, 0.4, 0.4, 1)
end

-- Function to resize UI based on compact mode with improved styling
local function ResizeUIForCompactMode()
    if not RaidMount.RaidMountFrame then return end
    
    local frameWidth = RaidMountSettings.compactMode and 1100 or 1300
    local contentWidth = RaidMountSettings.compactMode and 1050 or 1240
    
    RaidMount.RaidMountFrame:SetWidth(frameWidth)
    
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:SetPoint("TOPLEFT", 15, -165)
        RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)
    end
    
    if RaidMount.ContentFrame then
        RaidMount.ContentFrame:SetWidth(contentWidth)
    end
    
    if RaidMount.HeaderFrame then
        RaidMount.HeaderFrame:SetWidth(contentWidth)
    end
end

-- OPTIMIZED SEARCH BOX
local function CreateSearchBox()
    if RaidMount.SearchBox then return end
    
    local container = CreateFrame("Frame", nil, RaidMount.RaidMountFrame)
    container:SetSize(250, 40)
    container:SetPoint("TOPLEFT", 20, -70)
    CreateStyledBackground(container, COLORS.panelBg)
    
    CreateStandardFontString(container, "GameFontNormal", "|cFF33CCFFSearch:|r", 12):SetPoint("BOTTOMLEFT", container, "TOPLEFT", 5, 5)
    
    local searchBox = CreateFrame("EditBox", "RaidMountSearchBox", container)
    RaidMount.SearchBox = searchBox
    searchBox:SetSize(230, 30)
    searchBox:SetPoint("CENTER")
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("ChatFontNormal")
    searchBox:SetTextInsets(10, 10, 0, 0)
    
    local editBg = searchBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.05, 0.05, 0.1, 0.9)
    
    local placeholder = "Search mounts, raids, or bosses..."
    searchBox:SetText(placeholder)
    searchBox:SetTextColor(unpack(COLORS.textMuted))
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == placeholder then
            self:SetText("")
            self:SetTextColor(unpack(COLORS.text))
        end
        editBg:SetColorTexture(unpack(COLORS.primaryDark))
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(placeholder)
            self:SetTextColor(unpack(COLORS.textMuted))
        end
        editBg:SetColorTexture(0.05, 0.05, 0.1, 0.9)
    end)
    
    -- Add search throttling to prevent spikes
    local searchTimer = nil
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= placeholder then
            local newSearch = self:GetText():lower()
            if newSearch ~= currentSearch then
                currentSearch = newSearch
                
                -- Cancel previous timer
                if searchTimer then
                    searchTimer:Cancel()
                end
                
                -- Throttle search updates
                searchTimer = C_Timer.After(0.3, function()
                    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then
                        RaidMount.PopulateUI()
                    end
                    searchTimer = nil
                end)
            end
        end
    end)
    
    CreateStandardFontString(container, "GameFontNormal", "|TInterface\\Icons\\INV_Misc_Spyglass_02:16:16:0:0|t", nil, COLORS.textMuted):SetPoint("RIGHT", searchBox, "RIGHT", -10, 0)
end

-- OPTIMIZED DROPDOWN FACTORY
local function CreateStyledDropdown(parent, label, options, defaultValue, callback, xOffset, yOffset)
    local container = CreateFrame("Frame", nil, parent)
    container:SetSize(200, 40)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
    
    CreateStandardFontString(container, "GameFontNormal", "|cFF33CCFF" .. label .. ":|r", 12):SetPoint("BOTTOMLEFT", container, "TOPLEFT", 5, 5)
    
    local dropdown = CreateFrame("Frame", nil, container, "UIDropDownMenuTemplate")
    dropdown:SetPoint("CENTER")
    CreateStyledBackground(dropdown, COLORS.panelBg)
    
    UIDropDownMenu_Initialize(dropdown, function()
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.colorCode = "|cFFFFFFFF"
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, option)
                UIDropDownMenu_SetText(dropdown, option)
                callback(option)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(dropdown, defaultValue)
    UIDropDownMenu_SetText(dropdown, defaultValue)
    UIDropDownMenu_SetWidth(dropdown, 170)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    
    return dropdown
end

-- CONSOLIDATED FILTER DROPDOWN CREATION
local function CreateFilterDropdowns()
    if RaidMount.ExpansionDropdown then return end
    
    -- Dropdown configurations: {name, label, position, options, width, callback}
    local configs = {
        {"ExpansionDropdown", "Expansion", {300, -65}, {"All", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within"}, 180, function(v) currentExpansionFilter = v; C_Timer.After(0.1, function() if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then RaidMount.PopulateUI() end end) end},
        {"CollectedDropdown", "Status", {530, -65}, {"All", "Collected", "Uncollected"}, 150, function(v) currentFilter = v; C_Timer.After(0.1, function() if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then RaidMount.PopulateUI() end end) end},
        {"ContentTypeDropdown", "Content", {700, -65}, {"All", "Raid", "Dungeon", "World", "Holiday", "Special"}, 120, function(v) currentContentTypeFilter = v; C_Timer.After(0.1, function() if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not isStatsView then RaidMount.PopulateUI() end end) end}
    }
    
    -- Create all dropdowns
    for _, config in ipairs(configs) do
        local name, label, pos, options, width, callback = unpack(config)
        
        local labelText = CreateStandardFontString(RaidMount.RaidMountFrame, "GameFontNormal", "|cFF33CCFF" .. label .. ":|r", 12)
        labelText:SetPoint("TOPLEFT", pos[1], pos[2])
        
        local dropdown = CreateFrame("Frame", "RaidMount" .. name, RaidMount.RaidMountFrame, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", -15, -8)
        
        UIDropDownMenu_Initialize(dropdown, function()
            for _, option in ipairs(options) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = option
                info.func = function()
                    UIDropDownMenu_SetSelectedName(dropdown, option)
                    UIDropDownMenu_SetText(dropdown, option)
                    callback(option)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)
        
        UIDropDownMenu_SetSelectedName(dropdown, "All")
        UIDropDownMenu_SetText(dropdown, "All")
        UIDropDownMenu_SetWidth(dropdown, width)
        UIDropDownMenu_JustifyText(dropdown, "LEFT")
        
        RaidMount[name] = dropdown
    end
end

-- OPTIMIZED BUTTON CREATION
local function CreateSettingsButton()
    if RaidMount.SettingsButton then return end
    
    -- Button configurations: {name, size, position, text, callback}
    local buttonConfigs = {
        {"SettingsButton", {100, 35}, {"TOPRIGHT", -20, -70}, "|TInterface\\Icons\\Trade_Engineering:16:16:0:0|t Settings", function() RaidMount.ShowSettingsPanel() end},
        {"StatsButton", {80, 35}, {"BOTTOMRIGHT", -120, 15}, "|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t Stats", function() RaidMount.ToggleStatsView() end}
    }
    
    -- Create buttons using factory pattern
    for _, config in ipairs(buttonConfigs) do
        local name, size, pos, text, callback = unpack(config)
        local button = CreateFrame("Button", "RaidMount" .. name, RaidMount.RaidMountFrame)
        button:SetSize(unpack(size))
        button:SetPoint(unpack(pos))
        CreateStyledBackground(button, COLORS.primary, COLORS.primaryDark)
        CreateStandardFontString(button, "GameFontNormal", text, 12, COLORS.text):SetPoint("CENTER")
        button:SetScript("OnClick", callback)
        RaidMount[name] = button
    end
    
    -- Resize handle removed - UI scaling now handled via settings panel slider
end

-- Create enhanced mount count display
local function UpdateMountCounts()
    local totalMounts, collectedMounts = 0, 0
    local combinedData = RaidMount.GetCombinedMountData()

    for _, mount in ipairs(combinedData) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    -- Ensure the mountCountText exists and is properly positioned
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame.mountCountText then
        return
    end

    local percentage = totalMounts > 0 and (collectedMounts / totalMounts) * 100 or 0
    
    -- Create a more visual progress bar with icons
    local filledBars = math.floor(percentage / 5)
    local emptyBars = 20 - filledBars
    local progressBar = "|cFF00FF00" .. string.rep("█", filledBars) .. "|r|cFF333333" .. string.rep("█", emptyBars) .. "|r"
    
    -- Use WoW texture icons instead of Unicode - made bigger
    local mountIconTexture = "|TInterface\\Icons\\Ability_Mount_RidingHorse:20:20:0:0|t"
    local collectedIconTexture = "|TInterface\\Icons\\Achievement_General:20:20:0:0|t"
    local progressIconTexture = "|TInterface\\Icons\\INV_Misc_Note_01:20:20:0:0|t"
    
    RaidMount.RaidMountFrame.mountCountText:SetText(
        string.format("%s |cFFFFD700%d|r  %s |cFF00FF00%d|r  %s |cFF33CCFF%.1f%%|r [%s]", 
        mountIconTexture, totalMounts, collectedIconTexture, collectedMounts, progressIconTexture, percentage, progressBar)
    )
end

-- Ultra-minimal frame system - only create what's absolutely needed
local function GetVisibleRow(index, parent)
    if not visibleRows[index] then
        local frame = CreateFrame("Frame", nil, parent)
        frame:SetSize(parent:GetWidth(), rowHeight)
        
        -- Single background texture
        frame.bg = frame:CreateTexture(nil, "BACKGROUND")
        frame.bg:SetAllPoints()
        
        -- Pre-create minimal text elements
        frame.texts = {}
        local maxCols = RaidMountSettings.compactMode and 6 or 10
        for i = 1, maxCols do
            frame.texts[i] = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            frame.texts[i]:SetFont(cachedFontPath, 13, "OUTLINE")
        end
        
        visibleRows[index] = frame
    end
    
    return visibleRows[index]
end

-- Clear all visible rows efficiently
-- REMOVED: This function is replaced by the new virtual scrolling ClearVisibleRows function

-- Dummy functions for compatibility
local function ReleaseFrame(frame) 
    -- Do nothing - we reuse frames
end

-- Get account-wide character data for a mount
local function GetAccountWideData(trackingKey)
    if not RaidMountAttempts[trackingKey] then
        RaidMountAttempts[trackingKey] = {
            total = 0,
            characters = {},
            lastAttempt = nil,
            collected = false
        }
    end
    
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    local accountData = RaidMountAttempts[trackingKey]
    
    -- Ensure character-specific data exists (using the existing format)
    if not accountData.characters then
        accountData.characters = {}
    end
    
    -- Calculate total attempts and gather character data
    local totalAttempts = accountData.total or 0
    local lastAttemptDate = nil
    local charactersWithAttempts = {}
    local collectedBy = nil
    
    -- Handle existing character data format (character ID -> attempt count)
    for charId, attempts in pairs(accountData.characters) do
        if attempts and attempts > 0 then
            -- Convert character ID back to readable name
            local charName = charId
            if charId == currentPlayer then
                charName = UnitName("player")
            else
                -- Try to extract character name from ID
                charName = charId:match("^([^%-]+)") or charId
            end
            
            table.insert(charactersWithAttempts, {
                name = charName,
                attempts = attempts,
                lastAttempt = accountData.lastAttempt
            })
        end
    end
    
    if accountData.lastAttempt then
        lastAttemptDate = date("%m/%d/%y", accountData.lastAttempt)
    end
    
    if accountData.collected then
        collectedBy = "Account-wide"
    end
    
    return {
        totalAttempts = totalAttempts,
        lastAttempt = lastAttemptDate,
        charactersWithAttempts = charactersWithAttempts,
        collectedBy = collectedBy,
        currentPlayerAttempts = accountData.characters[currentPlayer] or 0
    }
end

-- Cache-aware mount data retrieval with account-wide support (optimized)
-- Function to invalidate static data cache (call only when actual data changes)
function RaidMount.InvalidateStaticData()
    staticMountDataCache = nil
    staticDataVersion = staticDataVersion + 1
    filteredDataCache = nil
    sortCache = nil
end

function RaidMount.RefreshStaticCache()
    RaidMount.InvalidateStaticData()
    local data = RaidMount.GetCombinedMountData() -- This will rebuild the cache
    if RaidMount.PopulateUI and RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        if isStatsView then
            RaidMount.ShowDetailedStatsView()
        else
            RaidMount.PopulateUI()
        end
    end
    return data
end

-- Static data getter - only rebuilds when cache is invalid
function RaidMount.GetCombinedMountData()
    -- Return static cache if available (only rebuilds on actual game events)
    if staticMountDataCache then
        return staticMountDataCache
    end
    
    local currentTime = GetTime()
    
    -- Check if mount instances are loaded
    if not RaidMount.mountInstances or #RaidMount.mountInstances == 0 then
        PrintAddonMessage("Mount data not loaded yet. Waiting for mount files...", true)
        return {}
    end
    
    -- Build lookup tables if not already built
    if next(mountLookupBySpellID) == nil then
        BuildMountLookupTables()
    end
    
    -- Force refresh mount collection if cache is empty or very old
    if not mountDataCache or (currentTime - mountDataCacheTime) > (CACHE_DURATION * 2) then
        RaidMount.RefreshMountCollection()
    end
    
    -- Return cached data if still valid
    if mountDataCache and (currentTime - mountDataCacheTime) < CACHE_DURATION then
        return mountDataCache
    end
    
    local combinedData = {}
    
    -- Pre-calculate current player info to avoid repeated calls
    local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
    
    -- Process mount data with optimizations (removed problematic coroutine)
    local mountInstances = RaidMount.mountInstances
    local totalMounts = #mountInstances
    
    for i = 1, totalMounts do
        local mount = mountInstances[i]
        local trackingKey = mount.spellID
        local accountData = GetAccountWideData(trackingKey)
        
        -- Check if current character has the mount
        local hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
        if hasMount and RaidMountAttempts[trackingKey] and RaidMountAttempts[trackingKey].characters then
            if RaidMountAttempts[trackingKey].characters[currentPlayer] then
                RaidMountAttempts[trackingKey].characters[currentPlayer].collected = true
            end
        end
        
        -- Use cached values where possible
        local raidName = mount.raidName or "Unknown"
        local resetTime = mount.cachedResetTime
        if not resetTime then
            resetTime = RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(raidName) or "Unknown"
            mount.cachedResetTime = resetTime
        end
        
        local mountEntry = {
            raidName = raidName,
            bossName = mount.bossName or "Unknown",
            mountName = mount.mountName or "Unknown",
            location = mount.location or "Unknown",
            dropRate = mount.dropRate or "~1%",
            resetTime = resetTime,
            difficulty = mount.difficulty or "Unknown",
            expansion = mount.expansion or "Unknown",
            collected = hasMount or (accountData.collectedBy ~= nil),
            attempts = accountData.totalAttempts,
            lastAttempt = accountData.lastAttempt,
            mountID = mount.MountID,
            spellID = mount.spellID,
            itemID = mount.itemID,
            contentType = mount.contentType or "Raid",
            type = mount.contentType or "Raid",
            description = mount.description,
            charactersWithAttempts = accountData.charactersWithAttempts,
            collectedBy = accountData.collectedBy,
            currentPlayerAttempts = accountData.currentPlayerAttempts
        }
        
        combinedData[i] = mountEntry
    end
    
    mountDataCache = combinedData
    mountDataCacheTime = currentTime
    staticMountDataCache = combinedData
    
    return combinedData
end

-- Optimized filtering with caching
local function FilterAndSortData(data)
    -- Optimized filter state comparison using hash
    local currentStateHash = string.format("%s|%s|%s|%s|%s|%s", 
        currentFilter or "", 
        currentSearch or "", 
        currentExpansionFilter or "", 
        currentContentTypeFilter or "", 
        sortColumn or "", 
        tostring(sortDescending))
    
    -- Ensure lastFilterState is initialized
    if not lastFilterState then
        lastFilterState = {hash = ""}
    end
    
    local stateChanged = (lastFilterState.hash ~= currentStateHash)
    
    if stateChanged then
        lastFilterState.hash = currentStateHash
    end
    
    -- Return cached data if state hasn't changed
    if filteredDataCache and sortCache and not stateChanged then
        return filteredDataCache
    end
    
    local filtered = {}
    
    -- Pre-compile search pattern for better performance
    local searchPattern = currentSearch ~= "" and currentSearch:lower() or nil
    
    for _, mount in ipairs(data) do
        if mount and type(mount) == "table" then
            -- Quick filter checks
            local passesFilter = currentFilter == "All" or 
               (currentFilter == "Collected" and mount.collected) or
               (currentFilter == "Uncollected" and not mount.collected)
            
            if passesFilter then
                local passesExpansion = currentExpansionFilter == "All" or mount.expansion == currentExpansionFilter
                
                if passesExpansion then
                    local passesContentType = currentContentTypeFilter == "All" or mount.contentType == currentContentTypeFilter
                    
                    if passesContentType then
                        local passesSearch = not searchPattern or 
                           (mount.mountName and mount.mountName:lower():find(searchPattern, 1, true)) or
                           (mount.raidName and mount.raidName:lower():find(searchPattern, 1, true)) or
                           (mount.bossName and mount.bossName:lower():find(searchPattern, 1, true))
                        
                        if passesSearch then
                            table.insert(filtered, mount)
                        end
                    end
                end
            end
        end
    end
    
    -- Simple and bulletproof sorting
    if #filtered > 1 then
        -- Use pcall to catch any sorting errors
        local success, err = pcall(function()
            table.sort(filtered, function(a, b)
                -- Basic validation
                if not a or not b or type(a) ~= "table" or type(b) ~= "table" then
                    return false
                end
                
                -- Get values safely
                local aVal = a[sortColumn] or ""
                local bVal = b[sortColumn] or ""
                
                -- Always use string comparison for simplicity and reliability
                local aStr = tostring(aVal):lower()
                local bStr = tostring(bVal):lower()
                
                -- If values are equal, use mount name as tiebreaker
                if aStr == bStr then
                    local aName = tostring(a.mountName or ""):lower()
                    local bName = tostring(b.mountName or ""):lower()
                    return aName < bName
                end
                
                -- Simple comparison
                if sortDescending then
                    return aStr > bStr
                else
                    return aStr < bStr
                end
            end)
        end)
        
        -- If sorting failed, just skip it and continue
        if not success then
            print("RaidMount: Sorting failed, displaying unsorted data")
        end
    end
    
    -- Cache results
    filteredDataCache = filtered
    sortCache = true
    lastFilterState = currentFilterState
    
    return filtered
end

-- Virtual scrolling implementation
local visibleRows = {}
local rowPool = {}
local maxVisibleRows = 30 -- Number of rows to keep in memory
local rowHeight = 25
local scrollOffset = 0
local totalRows = 0
local filteredData = {}

-- Texture preloading system for smooth scrolling
RaidMount.textureCache = RaidMount.textureCache or {}
local textureCache = RaidMount.textureCache
local preloadQueue = {}
local preloadDistance = 10 -- Preload icons for next 10 rows

local function PreloadTexture(mountID)
    if not mountID or textureCache[mountID] then return end
    
    -- Queue texture for preloading
    table.insert(preloadQueue, mountID)
    
    -- Process queue in chunks to avoid frame drops
    if #preloadQueue == 1 then
        C_Timer.After(0.01, function()
            local toProcess = math.min(5, #preloadQueue)
            for i = 1, toProcess do
                local id = table.remove(preloadQueue, 1)
                if id then
                    local mountInfo = C_MountJournal.GetMountInfoByID(id)
                    if mountInfo then
                        textureCache[id] = mountInfo.iconFileID
                    end
                end
            end
            
            -- Continue processing if more in queue
            if #preloadQueue > 0 then
                C_Timer.After(0.01, function()
                    -- Recursive call to process more
                    local nextBatch = math.min(5, #preloadQueue)
                    for i = 1, nextBatch do
                        local id = table.remove(preloadQueue, 1)
                        if id then
                            local mountInfo = C_MountJournal.GetMountInfoByID(id)
                            if mountInfo then
                                textureCache[id] = mountInfo.iconFileID
                            end
                        end
                    end
                end)
            end
        end)
    end
end

local function GetCachedTexture(mountID)
    if textureCache[mountID] then
        -- Track cache hit
        if RaidMount.performanceStats then
            RaidMount.performanceStats.textureCache.hits = (RaidMount.performanceStats.textureCache.hits or 0) + 1
        end
        return textureCache[mountID]
    end
    
    -- Track cache miss
    if RaidMount.performanceStats then
        RaidMount.performanceStats.textureCache.misses = (RaidMount.performanceStats.textureCache.misses or 0) + 1
    end
    
    -- Fallback to direct lookup
    local mountInfo = C_MountJournal.GetMountInfoByID(mountID)
    if mountInfo then
        textureCache[mountID] = mountInfo.iconFileID
        return mountInfo.iconFileID
    end
    
    return nil
end

-- Preload textures for upcoming rows
local function PreloadUpcomingTextures(startIndex, endIndex)
    for i = startIndex, math.min(endIndex + preloadDistance, totalRows) do
        if filteredData[i] then
            local mountID = filteredData[i].MountID or filteredData[i].spellID
            if mountID then
                PreloadTexture(mountID)
            end
        end
    end
end

-- Row pool management
local function GetRowFromPool(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(rowHeight)
        
        -- Create background
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        
        -- Create text elements (10 columns max)
        row.texts = {}
        for i = 1, 10 do
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetFont(cachedFontPath, 13, "OUTLINE")
            row.texts[i] = text
        end
        
        -- Set up tooltip and click handlers
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.data and RaidMountSettings.showTooltips then
                RaidMount.ShowTooltip(self, self.data)
            end
            self.bg:SetColorTexture(unpack(COLORS.primaryDark))
        end)
        
        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.originalRowColor then
                self.bg:SetColorTexture(unpack(self.originalRowColor))
            end
        end)
        
        -- Add mount preview click handler
        row:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" and self.data and self.data.spellID and DressUpFrame then
                ShowUIPanel(DressUpFrame)
                -- Simplified mount preview to reduce CPU usage
                pcall(function()
                    if DressUpFrame.ModelScene then
                        DressUpFrame.ModelScene:SetFromModelSceneID(290, false, true)
                    end
                end)
            end
        end)
    end
    
    row:Show()
    return row
end

local function ReturnRowToPool(row)
    if row then
        row:Hide()
        row.data = nil
        table.insert(rowPool, row)
    end
end

-- Clear all visible rows and return to pool
local function ClearVisibleRows()
    for _, row in ipairs(visibleRows) do
        ReturnRowToPool(row)
    end
    visibleRows = {}
end

-- Update visible rows based on scroll position
local function UpdateVisibleRows()
    if not RaidMount.ContentFrame then return end
    
    local scrollFrame = RaidMount.ScrollFrame
    local scrollTop = scrollFrame:GetVerticalScroll()
    local frameHeight = scrollFrame:GetHeight()
    
    -- Calculate visible range
    local startIndex = math.floor(scrollTop / rowHeight) + 1
    local endIndex = math.min(startIndex + math.ceil(frameHeight / rowHeight) + 2, totalRows) -- +2 for buffer
    
    -- Clear existing rows
    for _, row in ipairs(visibleRows) do
        ReturnRowToPool(row)
    end
    visibleRows = {}
    
    -- Create only visible rows
    for i = startIndex, endIndex do
        if filteredData[i] then
            local row = GetRowFromPool(RaidMount.ContentFrame)
            local yOffset = -((i - 1) * rowHeight)
            
            row:SetPoint("TOPLEFT", 0, yOffset)
            row:SetSize(RaidMount.ContentFrame:GetWidth(), rowHeight)
            row.data = filteredData[i]
            
            -- Set up row content
            local data = filteredData[i]
            local rowIndex = i
            local fontSize = 13
            
            -- Efficient background with alternating colors
            local rowColor = (rowIndex % 2 == 0) and {0.1, 0.1, 0.15, 0.3} or {0.05, 0.05, 0.1, 0.3}
            row.bg:SetColorTexture(unpack(rowColor))
            row.originalRowColor = rowColor
            
            -- Consolidated column configurations
            local collectedColor = data.collected and COLORS.success or COLORS.text
            local statusColor = data.collected and COLORS.success or COLORS.error
            
            local columns = RaidMountSettings.compactMode and {
                {"mountName", 10, 280, collectedColor}, {"raidName", 295, 200, COLORS.textSecondary}, {"bossName", 500, 180, COLORS.textSecondary},
                {"attempts", 685, 100, COLORS.warning}, {"collected", 790, 120, statusColor, true}, {"resetTime", 915, 120, COLORS.textMuted}
            } or {
                {"mountName", 10, 200, collectedColor}, {"raidName", 215, 170, COLORS.textSecondary}, {"bossName", 390, 150, COLORS.textSecondary},
                {"expansion", 545, 140, COLORS.textMuted}, {"difficulty", 690, 90, COLORS.textMuted}, {"dropRate", 785, 80, COLORS.warning},
                {"attempts", 870, 80, COLORS.warning}, {"collected", 955, 80, statusColor, true}, {"resetTime", 1040, 100, COLORS.textMuted}, {"lastAttempt", 1145, 90, COLORS.textMuted}
            }
            
            -- Use pre-created text elements
            for j, column in ipairs(columns) do
                local key, xPos, width, color, isStatus = unpack(column)
                local text = row.texts[j]
                
                text:SetPoint("LEFT", xPos, 0)
                text:SetSize(width - 10, rowHeight)
                text:SetJustifyH("LEFT")
                text:SetJustifyV("MIDDLE")
                text:SetFont(cachedFontPath, fontSize, "OUTLINE")
                
                -- Consolidated value processing
                local value = data[key]
                if isStatus then
                    value = data.collected and "Collected" or "Missing"
                elseif key == "attempts" and value == 0 then
                    value = "-"
                elseif not value or value == "" then
                    value = "N/A"
                end
                
                local textStr = tostring(value)
                local maxChars = math.floor((width - 20) / 8)
                if #textStr > maxChars then
                    textStr = textStr:sub(1, maxChars - 3) .. "..."
                end
                
                text:SetText(textStr)
                text:SetTextColor(unpack(color))
                text:Show()
            end
            
            -- Hide unused elements
            for j = #columns + 1, #row.texts do
                row.texts[j]:Hide()
            end
            
            table.insert(visibleRows, row)
        end
    end
end

-- Event-driven update system with debouncing
local updateQueue = {}
local isUpdateScheduled = false
local lastUpdateTime = 0
local updateThrottleDelay = 0.1 -- 100ms throttle

local function ScheduleUpdate(priority)
    if isUpdateScheduled then return end
    
    isUpdateScheduled = true
    local delay = priority and 0.01 or updateThrottleDelay
    
    C_Timer.After(delay, function()
        isUpdateScheduled = false
        
        -- Process all queued updates
        local updates = updateQueue
        updateQueue = {}
        
        for _, updateFunc in ipairs(updates) do
            if type(updateFunc) == "function" then
                pcall(updateFunc)
            end
        end
    end)
end

local function QueueUpdate(updateFunc, priority)
    table.insert(updateQueue, updateFunc)
    ScheduleUpdate(priority)
end

-- Optimized scroll event handler
local function OnScrollValueChanged()
    local currentTime = GetTime()
    if currentTime - lastUpdateTime < 0.05 then -- 50ms throttle for scroll
        return
    end
    lastUpdateTime = currentTime
    
    QueueUpdate(UpdateVisibleRows, true) -- High priority for scroll
end

-- Optimized filter change handler
local function OnFilterChanged()
    QueueUpdate(function()
        filteredData = GetFilteredData()
        totalRows = #filteredData
        UpdateVisibleRows()
        PreloadUpcomingTextures(1, math.min(20, totalRows)) -- Preload first 20
    end)
end

-- Highly optimized PopulateUI function with virtual scrolling
function RaidMount.PopulateUI()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then
        return
    end

    -- Enhanced throttling with pending updates
    local currentTime = GetTime()
    if currentTime - lastUpdateTime < updateThrottleDelay then
        if not pendingUpdate then
            pendingUpdate = true
            C_Timer.After(updateThrottleDelay, function()
                if pendingUpdate then -- Check if still needed
                    pendingUpdate = false
                    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
                        RaidMount.PopulateUI()
                    end
                end
            end)
        end
        return
    end
    lastUpdateTime = currentTime
    
    if not RaidMount.ContentFrame then
        return
    end

    -- Get cached/filtered data
    local combinedData = RaidMount.GetCombinedMountData()
    filteredData = FilterAndSortData(combinedData)
    totalRows = #filteredData
    
    -- Update mount counts (cached)
    UpdateMountCounts()

    -- Update content frame size efficiently
    local totalHeight = math.max(600, totalRows * rowHeight + 50)
    if RaidMount.ContentFrame:GetHeight() ~= totalHeight then
        RaidMount.ContentFrame:SetHeight(totalHeight)
    end
    
    -- Update visible rows
    UpdateVisibleRows()
end


local function OnScrollRangeChanged(self, xRange, yRange)

end

-- Create scroll frame
local function CreateScrollFrame()
    if RaidMount.ScrollFrame then return end
    
    local contentWidth = RaidMountSettings.compactMode and 1050 or 1240
    
    RaidMount.ScrollFrame = CreateFrame("ScrollFrame", nil, RaidMount.RaidMountFrame, "UIPanelScrollFrameTemplate")
    RaidMount.ScrollFrame:SetPoint("TOPLEFT", 15, -165)
    RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", -35, 50)
    
    -- Enable mouse wheel scrolling
    RaidMount.ScrollFrame:EnableMouseWheel(true)
    RaidMount.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local scrollStep = 75
        local currentScroll = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        
        if delta > 0 then
            self:SetVerticalScroll(math.max(0, currentScroll - scrollStep))
        else
            self:SetVerticalScroll(math.min(maxScroll, currentScroll + scrollStep))
        end
        
        -- Update visible rows after scroll
        C_Timer.After(0.01, UpdateVisibleRows)
    end)
    
    -- Optimized scroll handling for virtual scrolling
    RaidMount.ScrollFrame:SetScript("OnScrollRangeChanged", function(self, xRange, yRange)
        -- Update visible rows when scroll range changes
        C_Timer.After(0.01, UpdateVisibleRows)
    end)
    
    -- Add scroll event handler for virtual scrolling
    RaidMount.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
        -- Update visible rows when scrolling
        C_Timer.After(0.01, UpdateVisibleRows)
    end)
    
    -- Style scrollbar
    local scrollBar = RaidMount.ScrollFrame.ScrollBar or _G[RaidMount.ScrollFrame:GetName().."ScrollBar"]
    if scrollBar then
        scrollBar:GetThumbTexture():SetColorTexture(unpack(COLORS.primary))
    end

    RaidMount.ContentFrame = CreateFrame("Frame", nil, RaidMount.ScrollFrame)
    RaidMount.ContentFrame:SetSize(contentWidth, 600)
    RaidMount.ScrollFrame:SetScrollChild(RaidMount.ContentFrame)
    
    -- Content background (cached texture)
    if not RaidMount.ContentFrame.bg then
        RaidMount.ContentFrame.bg = CreateStyledBackground(RaidMount.ContentFrame, {0.05, 0.05, 0.1, 0.5})
    end
end

-- Create column headers
local function CreateColumnHeaders()
    if RaidMount.HeaderFrame then 

        for _, child in pairs({RaidMount.HeaderFrame:GetChildren()}) do
            child:Hide()
        end
        RaidMount.HeaderFrame:SetParent(nil)
        RaidMount.HeaderFrame = nil
    end
    
    local contentWidth = RaidMountSettings.compactMode and 1050 or 1240
    
    RaidMount.HeaderFrame = CreateFrame("Frame", nil, RaidMount.RaidMountFrame)
    RaidMount.HeaderFrame:SetPoint("TOPLEFT", RaidMount.ScrollFrame, "TOPLEFT", 0, 30)
    RaidMount.HeaderFrame:SetSize(contentWidth, 25)
    

    local headerBg = CreateStyledBackground(RaidMount.HeaderFrame, COLORS.headerBg)
    

    local fontSize = 14
    
    local headers
    if RaidMountSettings.compactMode then
        -- Compact mode headers
        headers = {
            {text = "Mount Name", width = 280, key = "mountName", xPos = 10},
            {text = "Source", width = 200, key = "raidName", xPos = 295}, 
            {text = "Boss", width = 180, key = "bossName", xPos = 500},
            {text = "Attempts", width = 100, key = "attempts", xPos = 685},
            {text = "Status", width = 120, key = "collected", xPos = 790},
            {text = "Lockout", width = 120, key = "resetTime", xPos = 915}
        }
    else
        -- Full mode headers
        headers = {
            {text = "Mount Name", width = 200, key = "mountName", xPos = 10},
            {text = "Source", width = 170, key = "raidName", xPos = 215}, 
            {text = "Boss", width = 150, key = "bossName", xPos = 390},
            {text = "Expansion", width = 140, key = "expansion", xPos = 545},
            {text = "Difficulty", width = 90, key = "difficulty", xPos = 690},
            {text = "Drop Rate", width = 80, key = "dropRate", xPos = 785},
            {text = "Attempts", width = 80, key = "attempts", xPos = 870},
            {text = "Status", width = 80, key = "collected", xPos = 955},
            {text = "Lockout", width = 100, key = "resetTime", xPos = 1040},
            {text = "Last Try", width = 90, key = "lastAttempt", xPos = 1145}
        }
    end
    
    for i, header in ipairs(headers) do
        local headerButton = CreateFrame("Button", nil, RaidMount.HeaderFrame)
        headerButton:SetSize(header.width, 25)
        headerButton:SetPoint("LEFT", header.xPos, 0)
        
        -- Modern header button styling
        CreateStyledBackground(headerButton, {0, 0, 0, 0}, COLORS.primaryDark)
        
        local headerText = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        headerText:SetPoint("LEFT", 5, 0)
        headerText:SetText(header.text)
        headerText:SetFont(cachedFontPath, fontSize, "OUTLINE")
        headerText:SetTextColor(unpack(COLORS.gold))
        
        -- Sort indicator
        local sortIndicator = headerButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        sortIndicator:SetPoint("RIGHT", -5, 0)
        sortIndicator:SetFont(cachedFontPath, fontSize, "OUTLINE")
        
        if sortColumn == header.key then
            sortIndicator:SetText(sortDescending and "|TInterface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up:16:16:0:0|t" or "|TInterface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up:16:16:0:0|t")
            sortIndicator:SetTextColor(unpack(COLORS.secondary))
        else
            sortIndicator:SetText("")
        end
        
        headerButton:SetScript("OnClick", function()
            if sortColumn == header.key then
                sortDescending = not sortDescending
            else
                sortColumn = header.key
                sortDescending = false
            end
            
            -- Update all sort indicators
            for _, child in pairs({RaidMount.HeaderFrame:GetChildren()}) do
                local indicator = child:GetChildren() and select(2, child:GetChildren())
                if indicator and indicator.SetText then
                    indicator:SetText("")
    end
end

            sortIndicator:SetText(sortDescending and "|TInterface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up:16:16:0:0|t" or "|TInterface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up:16:16:0:0|t")
            sortIndicator:SetTextColor(unpack(COLORS.secondary))
    
            -- Only populate mount list if not in stats view
            if not isStatsView then
                RaidMount.PopulateUI()
            end
        end)
        end
    end
    
-- Cache invalidation functions
local function InvalidateCache()
    filteredDataCache = nil
    sortCache = nil
    mountDataCache = nil
    mountDataCacheTime = 0
end

-- Hook into data change events to invalidate cache
local function OnDataChanged()
    InvalidateCache()
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        RaidMount.PopulateUI()
        end
    end
    
-- Memory cleanup no longer needed with minimal frame approach

-- Minimal cleanup - no longer needed with static approach

-- Export cache invalidation and performance monitoring for external use
RaidMount.InvalidateUICache = InvalidateCache
RaidMount.OnDataChanged = OnDataChanged

RaidMount.GetMountLookupStats = function() 
    return {
        spellIDLookups = next(mountLookupBySpellID) and table.getn(mountLookupBySpellID) or 0,
        nameLookups = next(mountLookupByName) and table.getn(mountLookupByName) or 0,
        expansionCounts = expansionMountCounts
    }
end

-- Legacy function alias for backward compatibility
function RaidMount.DebugStats()
    RaidMount.Debug("stats")
end

-- Toggle between mount list and detailed stats view
function RaidMount.ToggleStatsView()
    if not RaidMount.RaidMountFrame then return end
    
    isStatsView = not isStatsView
    
    if isStatsView then
        -- Switch to stats view
        RaidMount.ShowDetailedStatsView()
        -- Update button text to "Back"
        if RaidMount.StatsButton and RaidMount.StatsButton.text then
            RaidMount.StatsButton.text:SetText("← Back")
        end
    else
        -- Switch back to mount list view
        RaidMount.ShowMountListView()
        -- Update button text back to "Stats"
        if RaidMount.StatsButton and RaidMount.StatsButton.text then
            RaidMount.StatsButton.text:SetText("|TInterface\\Icons\\INV_Misc_Note_01:16:16:0:0|t Stats")
        end
        end
    end
    
-- Show detailed stats view in the main UI
function RaidMount.ShowDetailedStatsView()
    if not RaidMount.ContentFrame then return end
    
    -- Clear existing content using helper function
    ClearContentFrameChildren()
    
    -- Get mount data for stats
    local combinedData = RaidMount.GetCombinedMountData()
    local stats = RaidMount.CalculateDetailedStats(combinedData)
    
    -- Create stats display
    RaidMount.CreateStatsDisplay(RaidMount.ContentFrame, stats)
end

-- Show normal mount list view
function RaidMount.ShowMountListView()
    if not RaidMount.ContentFrame then return end
    
    -- Clear existing content using helper function
    ClearContentFrameChildren()
    
    -- Repopulate with mount list
    RaidMount.PopulateUI()
end

-- Calculate detailed statistics
function RaidMount.CalculateDetailedStats(mountData)
    local stats = {
        total = 0,
        collected = 0,
        missing = 0,
        totalAttempts = 0,
        byExpansion = {},
        byDifficulty = {},
        byRaid = {},
        recentAttempts = {},
        topAttempted = {}
    }
    
    for _, mount in ipairs(mountData) do
        stats.total = stats.total + 1
        
        if mount.collected then
            stats.collected = stats.collected + 1
        else
            stats.missing = stats.missing + 1
        end
        
        stats.totalAttempts = stats.totalAttempts + (mount.attempts or 0)
        
        -- By expansion
        local expansion = mount.expansion or "Unknown"
        if not stats.byExpansion[expansion] then
            stats.byExpansion[expansion] = {total = 0, collected = 0, attempts = 0}
        end
        stats.byExpansion[expansion].total = stats.byExpansion[expansion].total + 1
        if mount.collected then
            stats.byExpansion[expansion].collected = stats.byExpansion[expansion].collected + 1
        end
        stats.byExpansion[expansion].attempts = stats.byExpansion[expansion].attempts + (mount.attempts or 0)
        
        -- By difficulty
        local difficulty = mount.difficulty or "Unknown"
        if not stats.byDifficulty[difficulty] then
            stats.byDifficulty[difficulty] = {total = 0, collected = 0, attempts = 0}
        end
        stats.byDifficulty[difficulty].total = stats.byDifficulty[difficulty].total + 1
        if mount.collected then
            stats.byDifficulty[difficulty].collected = stats.byDifficulty[difficulty].collected + 1
        end
        stats.byDifficulty[difficulty].attempts = stats.byDifficulty[difficulty].attempts + (mount.attempts or 0)
        
        -- By raid
        local raid = mount.raidName or "Unknown"
        if not stats.byRaid[raid] then
            stats.byRaid[raid] = {total = 0, collected = 0, attempts = 0}
        end
        stats.byRaid[raid].total = stats.byRaid[raid].total + 1
        if mount.collected then
            stats.byRaid[raid].collected = stats.byRaid[raid].collected + 1
        end
        stats.byRaid[raid].attempts = stats.byRaid[raid].attempts + (mount.attempts or 0)
        
        -- Top attempted mounts
        if mount.attempts and mount.attempts > 0 then
            table.insert(stats.topAttempted, {
                name = mount.mountName,
                attempts = mount.attempts,
                collected = mount.collected,
                raid = mount.raidName
            })
                        end
                    end
    
    -- Sort top attempted
    table.sort(stats.topAttempted, function(a, b) return a.attempts > b.attempts end)
    
    return stats
end

-- Create stats display in the content frame
function RaidMount.CreateStatsDisplay(parent, stats)
    local yOffset = -20
    local leftColumn = 50
    local rightColumn = 650
    
    -- Initialize stats elements tracking
    if not RaidMount.statsElements then
        RaidMount.statsElements = {}
    end
    
    -- Title
    local title = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", parent, "TOP", 0, yOffset)
    title:SetFont(cachedFontPath, 18, "OUTLINE")
    title:SetText("|cFF33CCFFDetailed Mount Collection Statistics|r")
    title:SetTextColor(unpack(COLORS.text))
    table.insert(RaidMount.statsElements, title)
    yOffset = yOffset - 40
    
    -- Overall Stats
    local overallTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    overallTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", leftColumn, yOffset)
    overallTitle:SetFont(cachedFontPath, 16, "OUTLINE")
    overallTitle:SetText("|cFFFFD700Overall Statistics|r")
    table.insert(RaidMount.statsElements, overallTitle)
    yOffset = yOffset - 25
    
    local percentage = stats.total > 0 and (stats.collected / stats.total) * 100 or 0
    local overallStats = {
        string.format("Total Mounts: |cFFFFFFFF%d|r", stats.total),
        string.format("Collected: |cFF00FF00%d|r (%.1f%%)", stats.collected, percentage),
        string.format("Missing: |cFFFF0000%d|r", stats.missing),
        string.format("Total Attempts: |cFF33CCFF%d|r", stats.totalAttempts),
        string.format("Average Attempts per Mount: |cFFFFFFFF%.1f|r", stats.total > 0 and (stats.totalAttempts / stats.total) or 0)
    }
    
    for _, statText in ipairs(overallStats) do
        local statLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", leftColumn + 20, yOffset)
        statLabel:SetFont(cachedFontPath, 15, "OUTLINE")
        statLabel:SetText(statText)
        statLabel:SetTextColor(unpack(COLORS.text))
        table.insert(RaidMount.statsElements, statLabel)
        yOffset = yOffset - 22
    end
    
    yOffset = yOffset - 20
    
    -- By Expansion Stats
    local expTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    expTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", leftColumn, yOffset)
    expTitle:SetFont(cachedFontPath, 16, "OUTLINE")
    expTitle:SetText("|cFFFFD700By Expansion|r")
    table.insert(RaidMount.statsElements, expTitle)
    yOffset = yOffset - 25
    
    -- Order expansions chronologically
    local expansionOrder = {
        "Classic",
        "The Burning Crusade", 
        "Wrath of the Lich King",
        "Cataclysm",
        "Mists of Pandaria",
        "Warlords of Draenor",
        "Legion",
        "Battle for Azeroth",
        "Shadowlands",
        "Dragonflight",
        "The War Within"
    }
    
    -- Create ordered list of expansions that exist in our data
    local orderedExpansions = {}
    for _, expansion in ipairs(expansionOrder) do
        if stats.byExpansion[expansion] then
            table.insert(orderedExpansions, expansion)
        end
    end
    
    -- Add any expansions not in our predefined order (like "Unknown")
    for expansion, data in pairs(stats.byExpansion) do
        local found = false
        for _, orderedExp in ipairs(orderedExpansions) do
            if orderedExp == expansion then
                found = true
                break
            end
        end
        if not found then
            table.insert(orderedExpansions, expansion)
        end
    end
    
    for _, expansion in ipairs(orderedExpansions) do
        local data = stats.byExpansion[expansion]
        local expPercentage = data.total > 0 and (data.collected / data.total) * 100 or 0
        local expText = string.format("%s: |cFF00FF00%d|r/|cFFFFFFFF%d|r (%.1f%%) - |cFF33CCFF%d attempts|r", 
            expansion, data.collected, data.total, expPercentage, data.attempts)
        
        local expLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", leftColumn + 20, yOffset)
        expLabel:SetFont(cachedFontPath, 15, "OUTLINE")
        expLabel:SetText(expText)
        expLabel:SetTextColor(unpack(COLORS.text))
        table.insert(RaidMount.statsElements, expLabel)
        yOffset = yOffset - 20
    end
    
    -- Right column - Top Attempted Mounts
    yOffset = -85 -- Reset for right column
    local topTitle = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    topTitle:SetPoint("TOPLEFT", parent, "TOPLEFT", rightColumn, yOffset)
    topTitle:SetFont(cachedFontPath, 16, "OUTLINE")
    topTitle:SetText("|cFFFFD700Most Attempted Mounts|r")
    table.insert(RaidMount.statsElements, topTitle)
    yOffset = yOffset - 25
    
    for i = 1, math.min(15, #stats.topAttempted) do
        local mount = stats.topAttempted[i]
        local statusIcon = mount.collected and "|TInterface\\Icons\\Achievement_General:16:16:0:0|t" or "|TInterface\\Icons\\Ability_Warrior_Revenge:16:16:0:0|t"
        local mountText = string.format("%s %s - |cFF33CCFF%d attempts|r (%s)", 
            statusIcon, mount.name, mount.attempts, mount.raid)
        
        local mountLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        mountLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", rightColumn + 20, yOffset)
        mountLabel:SetFont(cachedFontPath, 15, "OUTLINE")
        mountLabel:SetText(mountText)
        mountLabel:SetTextColor(unpack(COLORS.text))
        table.insert(RaidMount.statsElements, mountLabel)
        yOffset = yOffset - 20
    end
end

-- Main UI initialization function
function RaidMount.ShowUI()
    -- Check if mount data is loaded, if not wait a bit
    if not RaidMount.mountInstances or #RaidMount.mountInstances == 0 then
        PrintAddonMessage("Mount data not ready, retrying in 1 second...", true)
        C_Timer.After(1, function()
            RaidMount.ShowUI()
        end)
        return
    end
    
    -- Ensure mount data is fresh when opening UI
    RaidMount.RefreshMountCollection()
    
    -- Reset filters to "All" to ensure data shows
    ResetAllFilters()
    
    CreateMainFrame()
    CreateSearchBox()
    CreateFilterDropdowns()
    CreateSettingsButton()
    CreateScrollFrame()
    CreateColumnHeaders()
    
    ResizeUIForCompactMode()
    
    RaidMount.RaidMountFrame:Show()
    
    -- Ensure frame is visible (removed problematic fade-in animation)
    RaidMount.RaidMountFrame:SetAlpha(1)
    
    -- Force populate UI with a slight delay to ensure everything is ready
    C_Timer.After(0.1, function()
    RaidMount.PopulateUI()
    end)
    
    PrintAddonMessage("UI loaded with " .. #RaidMount.mountInstances .. " mounts!", false)
end

-- OPTIMIZED SETTINGS PANEL
function RaidMount.ShowSettingsPanel()
    if RaidMount.SettingsFrame then
        if RaidMount.SettingsFrame:IsShown() then
            RaidMount.SettingsFrame:Hide()
            RaidMount.SettingsFrame:ClearAllPoints()
            RaidMount.SettingsFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        else
            RaidMount.SettingsFrame:ClearAllPoints()
            RaidMount.SettingsFrame:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPRIGHT", 10, 0)
            RaidMount.SettingsFrame:Show()
        end
        return
    end
    
    -- Create settings frame programmatically for memory efficiency
    local frame = CreateFrame("Frame", "RaidMountSettingsFrame", UIParent, "BackdropTemplate")
    RaidMount.SettingsFrame = frame
    frame:SetSize(420, 520)
    frame:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPRIGHT", 10, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    
    -- Add to UI special frames
    tinsert(UISpecialFrames, "RaidMountSettingsFrame")
    
    -- Set up backdrop
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:SetBackdropColor(0.1, 0.1, 0.1, 0.9)
    frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    
    -- Drag functionality
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", -8, -8)
    closeButton:SetScript("OnClick", function()
        -- Clean up header frame before hiding
        if RaidMount.HeaderFrame then
            RaidMount.HeaderFrame:Hide()
            RaidMount.HeaderFrame:SetParent(nil)
            RaidMount.HeaderFrame = nil
        end
        frame:Hide()
        -- Restore main mount list when closing settings
        if RaidMount.RaidMountFrame then
            RaidMount.RaidMountFrame:Show()
        end
    end)
    
    -- Title
    local titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("|cFF33CCFFRaidMount Settings|r")
    titleText:SetTextColor(0.2, 0.8, 1, 1)
    
    -- Settings content using factory pattern
    local yPos = -60
    
    -- Checkbox configurations: {label, setting, callback}
    local checkboxConfigs = {
        {"Compact Mode (fewer columns)", "compactMode", function(checked) 
            RaidMountSettings.compactMode = checked
            -- Clean up header frame before UI changes
            RaidMount.CleanupHeaderFrame()
            ResizeUIForCompactMode()
            CreateColumnHeaders()
            
            -- Preserve current view state - don't force mount list view if we're in stats view
            if isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end},
        {"Show enhanced tooltips", "showTooltips", function(checked) RaidMountSettings.showTooltips = checked end}
    }
    
    -- Create checkboxes
    for _, config in ipairs(checkboxConfigs) do
        CreateLabeledCheckbox(frame, config[1], 20, yPos, RaidMountSettings[config[2]], function(self) config[3](self:GetChecked()) end)
        yPos = yPos - 40
    end
    
    yPos = yPos - 20
    
    -- UI Scale section with slider
    CreateStandardFontString(frame, "GameFontNormal", "|cFF33CCFFUI Scale|r", 13, COLORS.text):SetPoint("TOPLEFT", 20, yPos)
    yPos = yPos - 30
    
    -- Scale slider
    local scaleSlider = CreateFrame("Slider", nil, frame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", 20, yPos)
    scaleSlider:SetSize(350, 20)
    scaleSlider:SetMinMaxValues(0.5, 2.5)
    scaleSlider:SetValue(RaidMountSettings.uiScale or 1.0)
    scaleSlider:SetValueStep(0)  -- No stepping for maximum smoothness
    scaleSlider:SetObeyStepOnDrag(false)
    
    -- Slider labels
    local minLabel = CreateStandardFontString(frame, "GameFontNormalSmall", "0.5x", 10, COLORS.textMuted)
    minLabel:SetPoint("BOTTOMLEFT", scaleSlider, "TOPLEFT", 0, 5)
    
    local maxLabel = CreateStandardFontString(frame, "GameFontNormalSmall", "2.5x", 10, COLORS.textMuted)
    maxLabel:SetPoint("BOTTOMRIGHT", scaleSlider, "TOPRIGHT", 0, 5)
    
    -- Current scale display
    local scaleDisplay = CreateStandardFontString(frame, "GameFontNormal", string.format("%.2fx", RaidMountSettings.uiScale or 1.0), 12, COLORS.text)
    scaleDisplay:SetPoint("LEFT", scaleSlider, "RIGHT", 15, 0)
    
    -- Smooth slider functionality - only update display during drag, apply scale on release
    local isDragging = false
    
    scaleSlider:SetScript("OnValueChanged", function(self, value)
        -- Always update the display text and color
        scaleDisplay:SetText(string.format("%.2fx", value))
        
        -- Color coding based on scale
        if value < 0.8 then
            scaleDisplay:SetTextColor(1, 1, 0, 1) -- Yellow for small
        elseif value > 1.5 then
            scaleDisplay:SetTextColor(1, 0.5, 0, 1) -- Orange for large
        else
            scaleDisplay:SetTextColor(unpack(COLORS.text)) -- Normal color
        end
        
        -- Only apply the actual scale if not dragging (for click-to-set)
        if not isDragging then
            RaidMountSettings.uiScale = value
            if RaidMount.RaidMountFrame then
                RaidMount.RaidMountFrame:SetScale(value)
            end
        end
    end)
    
    -- Track when dragging starts
    scaleSlider:SetScript("OnMouseDown", function(self)
        isDragging = true
    end)
    
    -- Apply the scale when dragging ends
    scaleSlider:SetScript("OnMouseUp", function(self)
        isDragging = false
        local value = self:GetValue()
        value = math.floor(value * 100 + 0.5) / 100 -- Round to nearest 0.01
        self:SetValue(value)
        RaidMountSettings.uiScale = value
        scaleDisplay:SetText(string.format("%.2fx", value))
        
        -- Apply the final scale
        if RaidMount.RaidMountFrame then
            RaidMount.RaidMountFrame:SetScale(value)
        end
    end)
    
    yPos = yPos - 35
    
    yPos = yPos - 60
    
    -- Utility section
    CreateStandardFontString(frame, "GameFontNormal", "|cFF33CCFFUtility Functions|r", 13, COLORS.text):SetPoint("TOPLEFT", 20, yPos)
    yPos = yPos - 35
    
    -- Button configurations: {text, position, callback}
    local buttonConfigs = {
        {"Rescan Mounts", {"TOPLEFT", 20, yPos}, function() 
            RaidMount.CleanupHeaderFrame()
            PrintAddonMessage("Rescanning mount collection...")
            RaidMountSettings.hasScannedCollection = false
            RaidMount.RefreshMountCollection()
        end},
        {"Refresh Data", {"LEFT", nil, "RIGHT", 10, 0}, function() 
            RaidMount.CleanupHeaderFrame()
            RaidMount.ForceRefreshMountData()
        end}
    }
    
    local lastButton
    for _, config in ipairs(buttonConfigs) do
        local btn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        btn:SetSize(120, 30)
        btn:SetText(config[1])
        btn:SetScript("OnClick", config[3])
        
        if config[2][2] then -- Absolute positioning
            btn:SetPoint(unpack(config[2]))
        else -- Relative positioning
            btn:SetPoint(config[2][1], lastButton, unpack(config[2], 3))
        end
        lastButton = btn
    end
    
    yPos = yPos - 40
    
    -- Reset button with warning
    local resetBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 30)
    resetBtn:SetPoint("TOPLEFT", 20, yPos)
    resetBtn:SetText("Reset All Data")
    resetBtn:SetScript("OnClick", function() StaticPopup_Show("RAIDMOUNT_RESET_CONFIRM") end)
    
    CreateStandardFontString(frame, "GameFontNormal", "|cFFFF6666Warning: This will delete all attempt data!|r", 10, {1, 0.4, 0.4, 1}):SetPoint("LEFT", resetBtn, "RIGHT", 15, 0)
    
    frame:Show()
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
    InvalidateCache()
    PrintAddonMessage("UI reset. Use /rm to reopen.")
end

-- Initialize UI system
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RaidMount" then
        -- Build lookup tables for optimized performance
        C_Timer.After(1, BuildMountLookupTables)
        -- Build initial static cache
        C_Timer.After(3, function()
            if RaidMount.GetCombinedMountData then
                RaidMount.GetCombinedMountData() -- This will build the static cache
            end
        end)
    elseif event == "PLAYER_LOGIN" then
        -- Rebuild lookup tables after login when all data is available
        C_Timer.After(2, BuildMountLookupTables)
        -- Build initial static cache after login
        C_Timer.After(5, function()
            if RaidMount.GetCombinedMountData then
                RaidMount.GetCombinedMountData() -- This will build the static cache
            end
        end)
    end
end) 


function RaidMount.HideAllFrames()
    print("|cFF33CCFFRaidMount:|r Hiding all RaidMount frames...")
    
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
        
        -- Hide all child frames and regions
        for i = 1, RaidMount.RaidMountFrame:GetNumChildren() do
            local child = select(i, RaidMount.RaidMountFrame:GetChildren())
            if child then
                child:Hide()
            end
        end
        
        -- Hide all regions (textures, font strings, etc.)
        for i = 1, RaidMount.RaidMountFrame:GetNumRegions() do
            local region = select(i, RaidMount.RaidMountFrame:GetRegions())
            if region and region.Hide then
                region:Hide()
            end
        end
        
        print("- Hidden: RaidMountFrame and all children")
    end
    
    if RaidMount.SettingsFrame then
        RaidMount.SettingsFrame:Hide()
        -- Move off-screen to ensure it's completely hidden
        RaidMount.SettingsFrame:ClearAllPoints()
        RaidMount.SettingsFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -5000, -5000)
        print("- Hidden: SettingsFrame")
    end
    
    if RaidMount.DropMountFrame then
        RaidMount.DropMountFrame:Hide()
        print("- Hidden: DropMountFrame")
    end
    
    -- Hide any stray frames
    for i = 1, UIParent:GetNumChildren() do
        local child = select(i, UIParent:GetChildren())
        local name = child:GetName()
        if name and name:find("RaidMount") then
            child:Hide()
            print("- Hidden stray frame:", name)
        end
    end
    
    print("|cFF33CCFFRaidMount:|r All frames hidden. Check if grey bar is gone.")
end

-- Force reload UI function


function RaidMount.DebugAllFrames()
    print("|cFF33CCFFRaidMount Enhanced Debug:|r")
    
    -- Check all named frames
    local namedFrames = {
        "RaidMountFrame",
        "RaidMountSettingsFrame", 
        "RaidMountDropFrame",
        "RaidMountSearchBox",
        "RaidMountCollectedDropdown",
        "RaidMountExpansionDropdown",
        "RaidMountStatsButton",
        "RaidMountSettingsButton",
        "RaidMountResizeHandle"
    }
    
    for _, frameName in ipairs(namedFrames) do
        local frame = _G[frameName]
        if frame then
            local parentName = "UIParent"
            if frame:GetParent() and frame:GetParent().GetName then
                parentName = frame:GetParent():GetName() or "UIParent"
            end
            
            print(string.format("- %s: Shown=%s, Size=%dx%d, Parent=%s", 
                frameName, 
                tostring(frame:IsShown()), 
                frame:GetWidth(), 
                frame:GetHeight(),
                parentName
            ))
            
            -- Check if frame has position
            local point, relativeTo, relativePoint, x, y = frame:GetPoint()
            if point then
                local relativeToName = "Unknown"
                if relativeTo and relativeTo.GetName then
                    relativeToName = relativeTo:GetName() or "Unknown"
                end
                print(string.format("  Position: %s %s %s %.1f %.1f", point, relativeToName, relativePoint, x, y))
            end
        end
    end
    
    -- Check all children of UIParent for unnamed RaidMount frames
    print("- Checking UIParent children:")
    for i = 1, UIParent:GetNumChildren() do
        local child = select(i, UIParent:GetChildren())
        local name = nil
        
        -- Safely get the name
        if child and child.GetName then
            name = child:GetName()
        end
        
        -- Check if it's a RaidMount frame (named or created by us)
        if (name and name:find("RaidMount")) or 
           (child == RaidMount.RaidMountFrame) or 
           (child == RaidMount.SettingsFrame) or
           (child == RaidMount.DropMountFrame) then
            
            local frameName = name or "UNNAMED"
            local width, height = 0, 0
            if child.GetWidth and child.GetHeight then
                width, height = child:GetWidth(), child:GetHeight()
            end
            
            print(string.format("  Found: %s - Shown=%s, Size=%dx%d", 
                frameName, 
                tostring(child:IsShown()), 
                width, 
                height
            ))
        end
    end
end

-- Nuclear option: Completely destroy all RaidMount frames
function RaidMount.DestroyAllFrames()
    print("|cFF33CCFFRaidMount:|r DESTROYING all RaidMount frames...")
    
    -- Destroy main frames
    if RaidMount.RaidMountFrame then
        RaidMount.RaidMountFrame:Hide()
        RaidMount.RaidMountFrame:SetParent(nil)
        RaidMount.RaidMountFrame = nil
        print("- Destroyed: RaidMountFrame")
    end
    
    if RaidMount.SettingsFrame then
        RaidMount.SettingsFrame:Hide()
        RaidMount.SettingsFrame:SetParent(nil)
        RaidMount.SettingsFrame = nil
        print("- Destroyed: SettingsFrame")
    end
    
    if RaidMount.DropMountFrame then
        RaidMount.DropMountFrame:Hide()
        RaidMount.DropMountFrame:SetParent(nil)
        RaidMount.DropMountFrame = nil
        print("- Destroyed: DropMountFrame")
    end
    
    -- Clear all frame references
    RaidMount.ContentFrame = nil
    RaidMount.ScrollFrame = nil
    RaidMount.HeaderFrame = nil
    RaidMount.SearchBox = nil
    RaidMount.CollectedDropdown = nil
    RaidMount.ExpansionDropdown = nil
    RaidMount.SettingsButton = nil
    RaidMount.StatsButton = nil
    RaidMount.ResizeHandle = nil
    
    -- Destroy any named frames
    local namedFrames = {
        "RaidMountFrame",
        "RaidMountSettingsFrame", 
        "RaidMountDropFrame",
        "RaidMountSearchBox",
        "RaidMountCollectedDropdown",
        "RaidMountExpansionDropdown",
        "RaidMountStatsButton",
        "RaidMountSettingsButton",
        "RaidMountResizeHandle"
    }
    
    for _, frameName in ipairs(namedFrames) do
        local frame = _G[frameName]
        if frame then
            frame:Hide()
            frame:SetParent(nil)
            _G[frameName] = nil
            print("- Destroyed global:", frameName)
        end
    end
    
    -- Clear frame pools
    -- Frame pool no longer needed
    textElementPool = {}
    
    print("|cFF33CCFFRaidMount:|r All frames destroyed. Check if grey bar is gone.")
end

-- Find and hide the specific grey bar frame
function RaidMount.FindAndHideGreyBar()
    print("|cFF33CCFFRaidMount:|r Searching for grey bar frame...")
    
    local function hideFrameRecursively(frame, depth)
        if not frame then return end
        
        depth = depth or 0
        local indent = string.rep("  ", depth)
        
        -- Check if this frame might be the grey bar
        if frame.GetWidth and frame.GetHeight then
            local width, height = frame:GetWidth(), frame:GetHeight()
            local name = "UNNAMED"
            if frame.GetName and frame:GetName() then
                name = frame:GetName()
            end
            
            -- Look for frames that might be the grey bar (wide and short)
            if width > 300 and height < 100 and height > 10 then
                print(string.format("%sPotential grey bar: %s (%.0fx%.0f)", indent, name, width, height))
                if frame.Hide then
                    frame:Hide()
                    print(string.format("%s  -> HIDDEN", indent))
                end
            end
        end
        
        -- Check children
        if frame.GetNumChildren then
            for i = 1, frame:GetNumChildren() do
                local child = select(i, frame:GetChildren())
                hideFrameRecursively(child, depth + 1)
            end
        end
        
        -- Check regions (textures, etc.)
        if frame.GetNumRegions then
            for i = 1, frame:GetNumRegions() do
                local region = select(i, frame:GetRegions())
                if region and region.Hide and region.GetWidth and region.GetHeight then
                    local width, height = region:GetWidth(), region:GetHeight()
                    if width > 300 and height < 100 and height > 10 then
                        print(string.format("%sPotential grey bar region: (%.0fx%.0f)", indent, width, height))
                        region:Hide()
                        print(string.format("%s  -> HIDDEN", indent))
                    end
                end
            end
        end
    end
    
    -- Search through RaidMount frames
    if RaidMount.RaidMountFrame then
        print("Searching RaidMountFrame...")
        hideFrameRecursively(RaidMount.RaidMountFrame)
    end
    
    if RaidMount.SettingsFrame then
        print("Searching SettingsFrame...")
        hideFrameRecursively(RaidMount.SettingsFrame)
    end
    
    -- Search through all UIParent children for any RaidMount-related frames
    print("Searching UIParent children...")
    for i = 1, UIParent:GetNumChildren() do
        local child = select(i, UIParent:GetChildren())
        local name = ""
        if child and child.GetName then
            name = child:GetName() or ""
        end
        
        if name:find("RaidMount") then
            print("Searching " .. name .. "...")
            hideFrameRecursively(child)
        end
    end
    
    print("|cFF33CCFFRaidMount:|r Grey bar search complete.")
end

-- Memory pooling system for strings and tables
local stringPool = {}
local tablePool = {}
local maxPoolSize = 100

local function GetStringFromPool()
    return table.remove(stringPool) or ""
end

local function ReturnStringToPool(str)
    if #stringPool < maxPoolSize then
        table.insert(stringPool, str)
    end
end

local function GetTableFromPool()
    local tbl = table.remove(tablePool)
    if tbl then
        -- Clear the table for reuse
        for k in pairs(tbl) do
            tbl[k] = nil
        end
        return tbl
    end
    return {}
end

local function ReturnTableToPool(tbl)
    if #tablePool < maxPoolSize then
        -- Clear the table
        for k in pairs(tbl) do
            tbl[k] = nil
        end
        table.insert(tablePool, tbl)
    end
end

-- Optimized string operations
local function SafeStringSub(str, start, finish)
    if not str then return "" end
    local result = str:sub(start, finish)
    return result ~= "" and result or ""
end

local function TruncateString(str, maxLength)
    if not str or #str <= maxLength then return str end
    return str:sub(1, maxLength - 3) .. "..."
end

local RAIDMOUNT_PREFIX = "|cFF33CCFFRaid|r|cFFFF0000Mount|r"



-- Remove HideAllViews from ShowMountListView and ShowDetailedStatsView to restore original behavior
local oldShowDetailedStatsView = RaidMount.ShowDetailedStatsView
function RaidMount.ShowDetailedStatsView(...)
    if oldShowDetailedStatsView then return oldShowDetailedStatsView(...) end
end

local oldShowMountListView = RaidMount.ShowMountListView
function RaidMount.ShowMountListView(...)
    if oldShowMountListView then return oldShowMountListView(...) end
end

-- Only keep HideAllViews for ShowSettingsPanel to hide other panels when opening settings
local oldShowSettingsPanel = RaidMount.ShowSettingsPanel
function RaidMount.ShowSettingsPanel(...)
    -- Don't hide anything - show settings alongside main window
    if oldShowSettingsPanel then return oldShowSettingsPanel(...) end
end

-- Global header cleanup function to prevent grey bar
function RaidMount.CleanupHeaderFrame()
    if RaidMount.HeaderFrame then
        RaidMount.HeaderFrame:Hide()
        RaidMount.HeaderFrame:SetParent(nil)
        RaidMount.HeaderFrame = nil
    end
end

-- Hook into all frame hide operations
local function HookFrameHide(frame, frameName)
    if frame and frame.Hide then
        local originalHide = frame.Hide
        frame.Hide = function(self)
            RaidMount.CleanupHeaderFrame()
            return originalHide(self)
        end
    end
end

-- Apply hooks when frames are created
local function ApplyHeaderCleanupHooks()
    if RaidMount.RaidMountFrame then
        HookFrameHide(RaidMount.RaidMountFrame, "RaidMountFrame")
    end
    if RaidMount.SettingsFrame then
        HookFrameHide(RaidMount.SettingsFrame, "SettingsFrame")
    end
    if RaidMount.DropMountFrame then
        HookFrameHide(RaidMount.DropMountFrame, "DropMountFrame")
    end
end

-- Apply hooks after a short delay to ensure frames are created
C_Timer.After(1, ApplyHeaderCleanupHooks)