local addonName, RaidMount = ...
RaidMount = RaidMount or {}

if not RaidMount then
    print("|cFFFF0000RaidMount Error:|r RaidMount table is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
    return
end

-- Initialize global table for attempts
if not RaidMountAttempts then
    RaidMountAttempts = {}
end

-- UI State variables
local currentFilter = "Uncollected"
local currentSearch = ""
local currentExpansionFilter = "All"
local sortColumn = "mountName"
local sortDescending = false

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"
local cachedColors = {
    collected = "|cFFFF0000",
    uncollected = "|cFF00FF00",
    white = "|cFFFFFFFF",
    gray = "|cFFCCCCCC",
    yellow = "|cFFFFFF00",
    red = "|cFFFF8080",
    green = "|cFF00FF00"
}

-- Text element pool for reuse
local textElementPool = {}
local poolIndex = 1

-- Throttling mechanism for UI updates
local lastUpdateTime = 0
local updateThrottleDelay = 0.1

-- Create main frame
local function CreateMainFrame()
    if RaidMount.RaidMountFrame then return end
    
    local frameWidth = RaidMountSettings.compactMode and 1050 or 1200
    
    RaidMount.RaidMountFrame = CreateFrame("Frame", "RaidMountFrame", UIParent, "BasicFrameTemplateWithInset")
    RaidMount.RaidMountFrame:SetSize(frameWidth, 700)
    RaidMount.RaidMountFrame:SetPoint("CENTER")
    RaidMount.RaidMountFrame:SetMovable(true)
    RaidMount.RaidMountFrame:EnableMouse(true)
    RaidMount.RaidMountFrame:RegisterForDrag("LeftButton")
    RaidMount.RaidMountFrame:SetClampedToScreen(true)
    RaidMount.RaidMountFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    RaidMount.RaidMountFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    RaidMount.RaidMountFrame.title = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    RaidMount.RaidMountFrame.title:SetPoint("TOP", RaidMount.RaidMountFrame, "TOP", 0, -10)
    RaidMount.RaidMountFrame.title:SetText("Raid & Dungeon Mount Collection Tracker")
    RaidMount.RaidMountFrame:Hide()
end

-- Function to resize UI based on compact mode
local function ResizeUIForCompactMode()
    if not RaidMount.RaidMountFrame then return end
    
    local frameWidth = RaidMountSettings.compactMode and 1050 or 1200
    local contentWidth = RaidMountSettings.compactMode and 1000 or 1140
    
    RaidMount.RaidMountFrame:SetWidth(frameWidth)
    
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:SetPoint("TOPLEFT", 10, -110)
        RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", RaidMountSettings.compactMode and -40 or -30, 40)
    end
    
    if RaidMount.ContentFrame then
        RaidMount.ContentFrame:SetWidth(contentWidth)
    end
    
    if RaidMount.HeaderFrame then
        RaidMount.HeaderFrame:SetWidth(contentWidth)
    end
end

-- Create search box
local function CreateSearchBox()
    if RaidMount.SearchBox then return end
    
    RaidMount.SearchBox = CreateFrame("EditBox", "RaidMountSearchBox", RaidMount.RaidMountFrame, "InputBoxTemplate")
    RaidMount.SearchBox:SetSize(200, 32)
    RaidMount.SearchBox:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 15, -40)
    RaidMount.SearchBox:SetAutoFocus(false)
    RaidMount.SearchBox:SetText("Search mounts...")
    RaidMount.SearchBox:SetTextColor(0.5, 0.5, 0.5, 1)
    
    local searchLabel = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    searchLabel:SetPoint("BOTTOMLEFT", RaidMount.SearchBox, "TOPLEFT", 0, 5)
    searchLabel:SetText("Search:")
    
    RaidMount.SearchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search mounts..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    RaidMount.SearchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Search mounts...")
            self:SetTextColor(0.5, 0.5, 0.5, 1)
        end
    end)
    
    RaidMount.SearchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local text = self:GetText()
            if text ~= "Search mounts..." then
                local newSearch = text:lower()
                if newSearch ~= currentSearch then
                    currentSearch = newSearch
                    RaidMount.PopulateUI()
                end
            end
        end
    end)
end

-- Create expansion filter dropdown
local function CreateExpansionFilter()
    if RaidMount.ExpansionDropdown then return end
    
    local expansionLabel = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    expansionLabel:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 350, -35)
    expansionLabel:SetText("Expansion:")
    
    RaidMount.ExpansionDropdown = CreateFrame("Frame", "RaidMountExpansionDropdown", RaidMount.RaidMountFrame, "UIDropDownMenuTemplate")
    RaidMount.ExpansionDropdown:SetPoint("TOPLEFT", expansionLabel, "BOTTOMLEFT", -15, -5)

    local expansions = {"All", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm", "Mists of Pandaria", 
                       "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within"}

    UIDropDownMenu_Initialize(RaidMount.ExpansionDropdown, function(self, level)
        for _, expansion in ipairs(expansions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = expansion
            info.func = function()
                UIDropDownMenu_SetSelectedName(RaidMount.ExpansionDropdown, expansion)
                currentExpansionFilter = expansion
                RaidMount.PopulateUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(RaidMount.ExpansionDropdown, "All")
    UIDropDownMenu_SetWidth(RaidMount.ExpansionDropdown, 180)
    UIDropDownMenu_JustifyText(RaidMount.ExpansionDropdown, "LEFT")
end

-- Create collection filter dropdown
local function CreateCollectedFilterDropdown()
    if RaidMount.CollectedDropdown then return end
    
    local collectionLabel = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    collectionLabel:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 570, -35)
    collectionLabel:SetText("Status:")
    
    RaidMount.CollectedDropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", RaidMount.RaidMountFrame, "UIDropDownMenuTemplate")
    RaidMount.CollectedDropdown:SetPoint("TOPLEFT", collectionLabel, "BOTTOMLEFT", -15, -5)

    local filters = {"All", "Collected", "Uncollected"}

    UIDropDownMenu_Initialize(RaidMount.CollectedDropdown, function(self, level)
        for _, filter in ipairs(filters) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = filter
            info.func = function()
                UIDropDownMenu_SetSelectedName(RaidMount.CollectedDropdown, filter)
                currentFilter = filter
                RaidMount.PopulateUI()
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(RaidMount.CollectedDropdown, RaidMountSettings.filterDefault or "Uncollected")
    UIDropDownMenu_SetWidth(RaidMount.CollectedDropdown, 150)
    UIDropDownMenu_JustifyText(RaidMount.CollectedDropdown, "LEFT")
end

-- Create settings button
local function CreateSettingsButton()
    if RaidMount.SettingsButton then return end
    
    RaidMount.SettingsButton = CreateFrame("Button", "RaidMountSettingsButton", RaidMount.RaidMountFrame, "UIPanelButtonTemplate")
    RaidMount.SettingsButton:SetSize(80, 25)
    RaidMount.SettingsButton:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 750, -40)
    RaidMount.SettingsButton:SetText("Settings")
    RaidMount.SettingsButton:SetScript("OnClick", function()
        RaidMount.ShowSettingsPanel()
    end)
end

-- Create mount count display
local function UpdateMountCounts()
    local totalMounts, collectedMounts = 0, 0
    local combinedData = RaidMount.GetCombinedMountData()

    for _, mount in ipairs(combinedData) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    if not RaidMount.RaidMountFrame.mountCountText then
        RaidMount.RaidMountFrame.mountCountText = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        RaidMount.RaidMountFrame.mountCountText:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 15, -75)
    end

    local percentage = totalMounts > 0 and math.floor((collectedMounts / totalMounts) * 100) or 0
    RaidMount.RaidMountFrame.mountCountText:SetText(
        string.format("|cFFFFFF00Total:|r %d  |cFFFFFF00Collected:|r %d  |cFFFFFF00Progress:|r %.1f%%", 
        totalMounts, collectedMounts, percentage)
    )
end

-- Get combined mount data
function RaidMount.GetCombinedMountData()
    local combinedData = {}

    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local attempts = RaidMount.GetAttempts(mount)
        local trackingKey = mount.spellID
        local attemptData = RaidMountAttempts[trackingKey]
        local lastAttempt = nil
        local hasMount = false
        
        if attemptData and type(attemptData) == "table" then
            hasMount = attemptData.collected or false
            if attemptData.lastAttempt then
                lastAttempt = date("%m/%d/%y", attemptData.lastAttempt)
            end
        end
        
        if not hasMount then
            hasMount = RaidMount.PlayerHasMount(mount.mountID, mount.itemID, mount.spellID)
            if hasMount and attemptData then
                attemptData.collected = true
            end
        end
        
        local mountEntry = {
            raidName = mount.raidName or "Unknown",
            bossName = mount.bossName or "Unknown",
            mountName = mount.mountName or "Unknown",
            location = mount.location or "Unknown",
            dropRate = mount.dropRate or "~1%",
            resetTime = RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(mount.raidName) or "Unknown",
            difficulty = mount.difficulty or "Unknown",
            expansion = mount.expansion or "Unknown",
            collected = hasMount,
            attempts = attempts,
            lastAttempt = lastAttempt,
            mountID = mount.mountID,
            spellID = mount.spellID,
            itemID = mount.itemID,
            contentType = mount.contentType or "Raid",
            type = mount.contentType or "Raid"
        }
        
        table.insert(combinedData, mountEntry)
    end

    return combinedData
end

-- Filter and sort data
local function FilterAndSortData(data)
    local filtered = {}
    
    for _, mount in ipairs(data) do
        if mount and type(mount) == "table" then
            if currentFilter == "All" or 
               (currentFilter == "Collected" and mount.collected) or
               (currentFilter == "Uncollected" and not mount.collected) then
                
                if currentExpansionFilter == "All" or mount.expansion == currentExpansionFilter then
                    
                    if currentSearch == "" or 
                       (mount.mountName and mount.mountName:lower():find(currentSearch)) or
                       (mount.raidName and mount.raidName:lower():find(currentSearch)) or
                       (mount.bossName and mount.bossName:lower():find(currentSearch)) then
                        table.insert(filtered, mount)
                    end
                end
            end
        end
    end
    
    table.sort(filtered, function(a, b)
        if not a and not b then
            return false
        end
        if not a then
            return false
        end
        if not b then
            return true
        end
        if type(a) ~= "table" or type(b) ~= "table" then
            return false
        end
        
        local aVal = a[sortColumn]
        local bVal = b[sortColumn]
        
        if not aVal and not bVal then
            return false
        end
        if not aVal then
            return false
        end
        if not bVal then
            return true
        end
        
        if type(aVal) == "number" and type(bVal) == "number" then
            return sortDescending and aVal > bVal or aVal < bVal
        else
            local aStr = tostring(aVal):lower()
            local bStr = tostring(bVal):lower()
            return sortDescending and aStr > bStr or aStr < bStr
        end
    end)
    
    return filtered
end

-- Create scroll frame and content
local function CreateScrollFrame()
    if RaidMount.ScrollFrame then return end
    
    local contentWidth = RaidMountSettings.compactMode and 1000 or 1140
    
    RaidMount.ScrollFrame = CreateFrame("ScrollFrame", nil, RaidMount.RaidMountFrame, "UIPanelScrollFrameTemplate")
    RaidMount.ScrollFrame:SetPoint("TOPLEFT", 10, -110)
    RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", RaidMountSettings.compactMode and -40 or -30, 40)

    RaidMount.ContentFrame = CreateFrame("Frame", nil, RaidMount.ScrollFrame)
    RaidMount.ContentFrame:SetSize(contentWidth, 580)
    RaidMount.ScrollFrame:SetScrollChild(RaidMount.ContentFrame)
end

-- Create column headers
local function CreateColumnHeaders()
    if RaidMount.HeaderFrame then 
        -- Clear existing headers when mode changes
        for _, child in pairs({RaidMount.HeaderFrame:GetChildren()}) do
            child:Hide()
        end
        RaidMount.HeaderFrame:SetParent(nil)
        RaidMount.HeaderFrame = nil
    end
    
    local contentWidth = RaidMountSettings.compactMode and 1000 or 1140
    
    RaidMount.HeaderFrame = CreateFrame("Frame", nil, RaidMount.RaidMountFrame)
    RaidMount.HeaderFrame:SetPoint("TOPLEFT", RaidMount.ScrollFrame, "TOPLEFT", 0, 25)
    RaidMount.HeaderFrame:SetSize(contentWidth, 20)
    
    -- Cache font settings
    local fontSize = RaidMountSettings.fontSize or 11
    
    local headers
    if RaidMountSettings.compactMode then
        -- Compact mode headers - only essential columns
        headers = {
            {text = "Mount Name", width = 250, key = "mountName", xPos = 5},
            {text = "Source", width = 200, key = "raidName", xPos = 260}, 
            {text = "Boss", width = 180, key = "bossName", xPos = 465},
            {text = "Attempts", width = 100, key = "attempts", xPos = 650},
            {text = "Status", width = 120, key = "collected", xPos = 755},
            {text = "Lockout", width = 120, key = "resetTime", xPos = 880}
        }
    else
        -- Full mode headers - all columns
        headers = {
            {text = "Mount Name", width = 180, key = "mountName", xPos = 5},
            {text = "Source", width = 150, key = "raidName", xPos = 190}, 
            {text = "Boss", width = 130, key = "bossName", xPos = 345},
            {text = "Expansion", width = 120, key = "expansion", xPos = 480},
            {text = "Difficulty", width = 80, key = "difficulty", xPos = 605},
            {text = "Drop Rate", width = 70, key = "dropRate", xPos = 690},
            {text = "Attempts", width = 80, key = "attempts", xPos = 765},
            {text = "Status", width = 80, key = "collected", xPos = 850},
            {text = "Lockout", width = 100, key = "resetTime", xPos = 935},
            {text = "Last Try", width = 80, key = "lastAttempt", xPos = 1040}
        }
    end
    
    for _, header in ipairs(headers) do
        local headerBtn = CreateFrame("Button", nil, RaidMount.HeaderFrame)
        headerBtn:SetSize(header.width, 20)
        headerBtn:SetPoint("TOPLEFT", header.xPos, 0)
        headerBtn:SetNormalFontObject("GameFontNormalSmall")
        headerBtn:SetText(header.text)
        
        -- Set custom font size for headers using cached values
        headerBtn:GetFontString():SetFont(cachedFontPath, fontSize)
        
        -- Set alignment once
        headerBtn:GetFontString():SetJustifyH(header.key == "mountName" and "LEFT" or "CENTER")
        
        headerBtn:SetScript("OnClick", function()
            if sortColumn == header.key then
                sortDescending = not sortDescending
            else
                sortColumn = header.key
                sortDescending = false
            end
            RaidMount.PopulateUI()
        end)
        
        -- Add sort indicator
        local indicator = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        indicator:SetPoint("RIGHT", headerBtn, "RIGHT", -5, 0)
        headerBtn.indicator = indicator
    end
end

-- Update sort indicators
local function UpdateSortIndicators()
    if not RaidMount.HeaderFrame then return end
    
    for _, child in ipairs({RaidMount.HeaderFrame:GetChildren()}) do
        if child.indicator then
            child.indicator:SetText("")
        end
    end
    
    -- Find the active sort header and add indicator
    local headers
    if RaidMountSettings.compactMode then
        headers = {"mountName", "raidName", "bossName", "attempts", "collected", "resetTime"}
    else
        headers = {"mountName", "raidName", "bossName", "expansion", "difficulty", "dropRate", "attempts", "collected", "resetTime", "lastAttempt"}
    end
    
    for i, key in ipairs(headers) do
        if key == sortColumn then
            local headerBtn = select(i, RaidMount.HeaderFrame:GetChildren())
            if headerBtn and headerBtn.indicator then
                headerBtn.indicator:SetText(sortDescending and "▼" or "▲")
            end
            break
        end
    end
end

-- Update font sizes for all text elements
function RaidMount.UpdateFontSizes()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    
    -- Refresh the UI to apply new font sizes
    RaidMount.PopulateUI()
end

-- Optimized text element creation with pooling
local function GetOrCreateTextElement(parent, text, xOffset, yOffset, width, color, justifyH, allowWordWrap)
    local element = textElementPool[poolIndex]
    
    if not element then
        element = parent:CreateFontString(nil, "OVERLAY")
        textElementPool[poolIndex] = element
    end
    
    poolIndex = poolIndex + 1
    
    element:SetParent(parent)
    element:SetPoint("TOPLEFT", xOffset, yOffset)
    element:SetWidth(width)
    element:SetJustifyH(justifyH or "CENTER")
    
    -- Enable word wrapping if requested (typically for mount names)
    if allowWordWrap then
        element:SetWordWrap(true)
        element:SetJustifyV("TOP")
        element:SetMaxLines(0) -- Allow unlimited lines
    else
        element:SetWordWrap(false)
        element:SetMaxLines(1) -- Single line only
    end
    
    -- Use cached font settings with compact mode adjustment
    local fontSize = RaidMountSettings.fontSize or 11
    if RaidMountSettings.compactMode then
        fontSize = math.max(8, fontSize - 1)  -- Reduce font size by 1 in compact mode, minimum 8
    end
    element:SetFont(cachedFontPath, fontSize)
    
    -- Handle color codes properly to avoid blank rectangles
    local displayText = text or ""
    if color and color ~= "" then
        -- If color is provided, use it
        element:SetText(color .. displayText .. "|r")
    else
        -- No color provided, use white
        element:SetText(cachedColors.white .. displayText .. "|r")
    end
    
    element:Show()

    return element
end

-- Populate UI with optimizations and throttling
function RaidMount.PopulateUI(forceUpdate)
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    
    -- Throttle updates unless forced
    local currentTime = GetTime()
    if not forceUpdate and (currentTime - lastUpdateTime) < updateThrottleDelay then
        return
    end
    lastUpdateTime = currentTime
    
    local combinedData = RaidMount.GetCombinedMountData()
    local filteredData = FilterAndSortData(combinedData)
    
    -- Group mounts by content type
    local groupedMounts = {
        Raid = {},
        Dungeon = {},
        World = {},
        Special = {},
        Holiday = {}
    }
    
    -- Sort mounts into groups
    for _, mount in ipairs(filteredData) do
        local contentType = mount.contentType or "Raid" -- Default to Raid if not specified
        if groupedMounts[contentType] then
            table.insert(groupedMounts[contentType], mount)
        else
            table.insert(groupedMounts.Raid, mount) -- Fallback to Raid
        end
    end
    
    -- Reset pool index for reuse
    poolIndex = 1
    
    -- Hide all existing elements efficiently
    for i = 1, #textElementPool do
        textElementPool[i]:Hide()
    end
    
    -- Clear previous lines reference
    RaidMount.ContentFrame.textLines = {}

    UpdateMountCounts()
    UpdateSortIndicators()
    
    local yOffset = -10
    local lineHeight = 16
    local headerHeight = 25
    local lineIndex = 1
    
    -- Define display order and headers
    local contentOrder = {
        {key = "Raid", header = "Raid Mounts", color = "|cFFFFD700"},
        {key = "Dungeon", header = "Dungeon Mounts", color = "|cFF00BFFF"},
        {key = "World", header = "World Boss Mounts", color = "|cFF32CD32"},
        {key = "Special", header = "Special Mounts", color = "|cFFFF69B4"},
        {key = "Holiday", header = "Holiday Event Mounts", color = "|cFFFF6600"}
    }
    
    -- Display each content type group
    for _, contentInfo in ipairs(contentOrder) do
        local mounts = groupedMounts[contentInfo.key]
        
        -- Only show section if it has mounts
        if mounts and #mounts > 0 then
            -- Create section header - use clean header text with separate color parameter
            local headerElement = GetOrCreateTextElement(RaidMount.ContentFrame, contentInfo.header, 10, yOffset, 1000, contentInfo.color, "LEFT")
            headerElement:SetFont(cachedFontPath, (RaidMountSettings.fontSize or 11) + 2) -- Larger font for headers
            yOffset = yOffset - headerHeight
            
            -- Display mounts in this section
            for i, mount in ipairs(mounts) do
                local collectedColor = mount.collected and cachedColors.collected or cachedColors.uncollected
                local statusText = mount.collected and "Collected" or "Missing"
                local lockoutColor = RaidMount.GetLockoutColor(mount.raidName)
                local lockoutStatus = mount.resetTime or "Unknown"
                
                local line = {}
                local mountNameElement
                
                if RaidMountSettings.compactMode then
                    -- Compact mode - only essential columns
                    mountNameElement = GetOrCreateTextElement(RaidMount.ContentFrame, mount.mountName, 5, yOffset, 250, collectedColor, "LEFT", true)
                    line[1] = mountNameElement
                    line[2] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.raidName or mount.dungeonName, 260, yOffset, 200, cachedColors.white)
                    line[3] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.bossName, 465, yOffset, 180, cachedColors.white)
                    line[4] = GetOrCreateTextElement(RaidMount.ContentFrame, tostring(mount.attempts or 0), 650, yOffset, 100, cachedColors.red)
                    line[5] = GetOrCreateTextElement(RaidMount.ContentFrame, statusText, 755, yOffset, 120, collectedColor)
                    line[6] = GetOrCreateTextElement(RaidMount.ContentFrame, lockoutStatus, 880, yOffset, 120, lockoutColor)
                    
                    -- Only set up tooltips if enabled - for compact mode (6 elements)
                    if RaidMountSettings.showTooltips then
                        for j = 1, 6 do
                            local element = line[j]
                            -- Clear any existing scripts first
                            element:SetScript("OnEnter", nil)
                            element:SetScript("OnLeave", nil)
                            
                            -- Set up improved tooltip handling
                            element:SetScript("OnEnter", function(self)
                                -- Only show tooltip if we're actually over this element and not in a UI interaction
                                local cursorX, cursorY = GetCursorPosition()
                                local scale = UIParent:GetEffectiveScale()
                                cursorX, cursorY = cursorX / scale, cursorY / scale
                                
                                -- Check if cursor is actually within the element bounds
                                local left, bottom, width, height = self:GetLeft(), self:GetBottom(), self:GetWidth(), self:GetHeight()
                                if left and bottom and width and height then
                                    local right, top = left + width, bottom + height
                                    if cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top then
                                        -- Add small delay to prevent accidental tooltips during scrolling
                                        C_Timer.After(0.1, function()
                                            if self:IsMouseOver() and RaidMount.ShowTooltip then
                                                RaidMount.ShowTooltip(self, mount, lockoutStatus)
                                            end
                                        end)
                                    end
                                end
                            end)
                            element:SetScript("OnLeave", function(self)
                                GameTooltip:Hide()
                            end)
                            
                            -- Ensure tooltips hide when scrolling or clicking elsewhere
                            element:SetScript("OnHide", function(self)
                                GameTooltip:Hide()
                            end)
                        end
                    end
                else
                    -- Full mode - all columns
                    mountNameElement = GetOrCreateTextElement(RaidMount.ContentFrame, mount.mountName, 5, yOffset, 200, collectedColor, "LEFT", true)
                    line[1] = mountNameElement
                    line[2] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.raidName or mount.dungeonName, 210, yOffset, 160, cachedColors.white)
                    line[3] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.bossName, 375, yOffset, 120, cachedColors.white)
                    line[4] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.expansion, 500, yOffset, 100, cachedColors.gray)
                    line[5] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.difficulty, 605, yOffset, 80, RaidMount.GetDifficultyColor(mount.difficulty))
                    line[6] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.dropRate, 690, yOffset, 70, cachedColors.yellow)
                    line[7] = GetOrCreateTextElement(RaidMount.ContentFrame, tostring(mount.attempts or 0), 765, yOffset, 60, cachedColors.red)
                    line[8] = GetOrCreateTextElement(RaidMount.ContentFrame, statusText, 830, yOffset, 100, collectedColor)
                    line[9] = GetOrCreateTextElement(RaidMount.ContentFrame, lockoutStatus, 935, yOffset, 100, lockoutColor)
                    line[10] = GetOrCreateTextElement(RaidMount.ContentFrame, mount.lastAttempt or "Never", 1040, yOffset, 100, cachedColors.gray)
                    
                    -- Only set up tooltips if enabled - for full mode (10 elements)
                    if RaidMountSettings.showTooltips then
                        for j = 1, 10 do
                            local element = line[j]
                            -- Clear any existing scripts first
                            element:SetScript("OnEnter", nil)
                            element:SetScript("OnLeave", nil)
                            
                            -- Set up improved tooltip handling
                            element:SetScript("OnEnter", function(self)
                                -- Only show tooltip if we're actually over this element and not in a UI interaction
                                local cursorX, cursorY = GetCursorPosition()
                                local scale = UIParent:GetEffectiveScale()
                                cursorX, cursorY = cursorX / scale, cursorY / scale
                                
                                -- Check if cursor is actually within the element bounds
                                local left, bottom, width, height = self:GetLeft(), self:GetBottom(), self:GetWidth(), self:GetHeight()
                                if left and bottom and width and height then
                                    local right, top = left + width, bottom + height
                                    if cursorX >= left and cursorX <= right and cursorY >= bottom and cursorY <= top then
                                        -- Add small delay to prevent accidental tooltips during scrolling
                                        C_Timer.After(0.1, function()
                                            if self:IsMouseOver() and RaidMount.ShowTooltip then
                                                RaidMount.ShowTooltip(self, mount, lockoutStatus)
                                            end
                                        end)
                                    end
                                end
                            end)
                            element:SetScript("OnLeave", function(self)
                                GameTooltip:Hide()
                            end)
                            
                            -- Ensure tooltips hide when scrolling or clicking elsewhere
                            element:SetScript("OnHide", function(self)
                                GameTooltip:Hide()
                            end)
                        end
                    end
                end
                
                -- Calculate dynamic line height based on mount name text height
                local actualLineHeight = lineHeight
                if mountNameElement then
                    local textHeight = mountNameElement:GetStringHeight()
                    if textHeight > lineHeight then
                        actualLineHeight = textHeight + 2 -- Add small padding
                    end
                end
                
                yOffset = yOffset - actualLineHeight
                RaidMount.ContentFrame.textLines[lineIndex] = line
                lineIndex = lineIndex + 1
            end
            
            -- Add extra spacing after each section
            yOffset = yOffset - 10
        end
    end
    
    -- Update content frame height
    local contentHeight = math.max(580, math.abs(yOffset) + 50)
    RaidMount.ContentFrame:SetHeight(contentHeight)
end

-- Global tooltip management to prevent interference with other UI elements
local function SetupGlobalTooltipManagement()
    local tooltipManager = CreateFrame("Frame")
    
    -- Hide tooltips when clicking anywhere or when UI elements get focus
    tooltipManager:SetScript("OnUpdate", function(self)
        -- Hide tooltips if user is interacting with input fields
        if RaidMount.SearchBox and RaidMount.SearchBox:HasFocus() then
            GameTooltip:Hide()
        end
        
        -- Hide tooltips if dropdowns are open
        if DropDownList1 and DropDownList1:IsVisible() then
            GameTooltip:Hide()
        end
        
        -- Hide tooltips if settings panel is open and has mouse focus
        if RaidMount.SettingsFrame and RaidMount.SettingsFrame:IsVisible() and RaidMount.SettingsFrame:IsMouseOver() then
            GameTooltip:Hide()
        end
    end)
    
    -- Register for global mouse events
    tooltipManager:RegisterEvent("GLOBAL_MOUSE_DOWN")
    tooltipManager:SetScript("OnEvent", function(self, event)
        if event == "GLOBAL_MOUSE_DOWN" then
            -- Hide tooltips on any mouse click
            GameTooltip:Hide()
        end
    end)
end

-- Initialize tooltip management when UI is first created
local function InitializeTooltipManagement()
    if not RaidMount.tooltipManagerInitialized then
        SetupGlobalTooltipManagement()
        RaidMount.tooltipManagerInitialized = true
    end
end

-- Show UI function
function RaidMount.ShowUI()
    CreateMainFrame()
    CreateSearchBox()
    CreateExpansionFilter()
    CreateCollectedFilterDropdown()
    CreateSettingsButton()
    CreateScrollFrame()
    CreateColumnHeaders()
    
    -- Initialize tooltip management
    InitializeTooltipManagement()
    
    RaidMount.RaidMountFrame:Show()
    RaidMount.PopulateUI()
end

-- Settings panel
function RaidMount.ShowSettingsPanel()
    if RaidMount.SettingsFrame then
        RaidMount.SettingsFrame:Show()
        return
    end
    
    -- Create settings frame
    RaidMount.SettingsFrame = CreateFrame("Frame", "RaidMountSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
    RaidMount.SettingsFrame:SetSize(450, 420)
    RaidMount.SettingsFrame:SetPoint("CENTER")
    RaidMount.SettingsFrame:SetMovable(true)
    RaidMount.SettingsFrame:EnableMouse(true)
    RaidMount.SettingsFrame:RegisterForDrag("LeftButton")
    RaidMount.SettingsFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    RaidMount.SettingsFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    
    -- Title
    local title = RaidMount.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOP", 0, -10)
    title:SetText("RaidMount Settings")
    
    -- Version display
    local versionText = RaidMount.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    versionText:SetPoint("TOP", 0, -25)
    versionText:SetText("Version: 02.06.25.02")
    versionText:SetTextColor(0.7, 0.7, 0.7, 1)
    
    -- Settings checkboxes with better organization
    local yOffset = -50
    local settings = {
        {
            category = "Interface",
            options = {
                {key = "showTooltips", text = "Show Tooltips", tooltip = "Display detailed tooltips when hovering over mounts"},
                {key = "showMinimapButton", text = "Show Minimap Button", tooltip = "Display the minimap button for easy access"},
                {key = "compactMode", text = "Compact Mode", tooltip = "Use a more compact display for the mount list"},
            }
        },
        {
            category = "Audio",
            options = {
                {key = "soundOnDrop", text = "Sound on Mount Drop", tooltip = "Play a sound when you obtain a mount"},
            }
        }
    }
    
    for _, category in ipairs(settings) do
        -- Category header
        local categoryHeader = RaidMount.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        categoryHeader:SetPoint("TOPLEFT", 20, yOffset)
        categoryHeader:SetText("|cFF33CCFF" .. category.category .. "|r")
        yOffset = yOffset - 25
        
        for _, setting in ipairs(category.options) do
            local checkbox = CreateFrame("CheckButton", nil, RaidMount.SettingsFrame, "UICheckButtonTemplate")
            checkbox:SetPoint("TOPLEFT", 30, yOffset)
            checkbox:SetChecked(RaidMountSettings[setting.key])
            checkbox:SetScript("OnClick", function(self)
                local newValue = self:GetChecked()
                RaidMountSettings[setting.key] = newValue
                
                -- Handle special cases with immediate updates
                if setting.key == "showMinimapButton" then
                    if newValue then
                        if RaidMount.MinimapButton then
                            RaidMount.MinimapButton:Show()
                        end
                    else
                        if RaidMount.MinimapButton then
                            RaidMount.MinimapButton:Hide()
                        end
                    end
                elseif setting.key == "compactMode" then
                    -- Recreate headers and refresh UI for compact mode changes
                    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
                        ResizeUIForCompactMode() -- Resize the UI first
                        CreateColumnHeaders() -- Recreate headers for new mode
                        RaidMount.PopulateUI(true) -- Force update
                    end
                elseif setting.key == "showTooltips" then
                    -- Tooltips will be enabled/disabled on next UI interaction
                    print("|cFF33CCFFRaidMount:|r Tooltips " .. (newValue and "enabled" or "disabled"))
                elseif setting.key == "soundOnDrop" then
                    print("|cFF33CCFFRaidMount:|r Mount drop sounds " .. (newValue and "enabled" or "disabled"))
                end
            end)
            
            local label = RaidMount.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
            label:SetText(setting.text)
            
            -- Tooltip
            checkbox:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(setting.tooltip, nil, nil, nil, nil, true)
                GameTooltip:Show()
            end)
            checkbox:SetScript("OnLeave", function() GameTooltip:Hide() end)
            
            yOffset = yOffset - 25
        end
        
        -- Add Font Size Slider after Interface category
        if category.category == "Interface" then
            -- Font Size Slider
            local fontSizeLabel = RaidMount.SettingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fontSizeLabel:SetPoint("TOPLEFT", 30, yOffset)
            fontSizeLabel:SetText("Font Size:")
            yOffset = yOffset - 25
            
            local fontSizeSlider = CreateFrame("Slider", "RaidMountFontSizeSlider", RaidMount.SettingsFrame, "OptionsSliderTemplate")
            fontSizeSlider:SetPoint("TOPLEFT", 30, yOffset)
            fontSizeSlider:SetSize(200, 20)
            fontSizeSlider:SetMinMaxValues(8, 16)
            fontSizeSlider:SetValue(RaidMountSettings.fontSize or 11)
            fontSizeSlider:SetValueStep(1)
            fontSizeSlider:SetObeyStepOnDrag(true)
            
            -- Slider labels
            fontSizeSlider.Low = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            fontSizeSlider.Low:SetPoint("TOPLEFT", fontSizeSlider, "BOTTOMLEFT", 0, 3)
            fontSizeSlider.Low:SetText("8")
            
            fontSizeSlider.High = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
            fontSizeSlider.High:SetPoint("TOPRIGHT", fontSizeSlider, "BOTTOMRIGHT", 0, 3)
            fontSizeSlider.High:SetText("16")
            
            fontSizeSlider.Text = fontSizeSlider:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
            fontSizeSlider.Text:SetPoint("CENTER", fontSizeSlider, "CENTER", 0, -15)
            fontSizeSlider.Text:SetText("Font Size: " .. (RaidMountSettings.fontSize or 11))
            
            fontSizeSlider:SetScript("OnValueChanged", function(self, value)
                local roundedValue = math.floor(value + 0.5)
                RaidMountSettings.fontSize = roundedValue
                self.Text:SetText("Font Size: " .. roundedValue)
                -- Update the UI if it's open
                if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
                    RaidMount.UpdateFontSizes()
                end
            end)
            
            yOffset = yOffset - 40
        end
        
        yOffset = yOffset - 10 -- Extra space between categories
    end
    
    -- Buttons at the bottom
    local buttonY = 20
    
    -- Reset button
    local resetButton = CreateFrame("Button", nil, RaidMount.SettingsFrame, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 25)
    resetButton:SetPoint("BOTTOMLEFT", 20, buttonY)
    resetButton:SetText("Reset All Data")
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("RAIDMOUNT_RESET_CONFIRM")
    end)
    
    -- Rescan button
    local rescanButton = CreateFrame("Button", nil, RaidMount.SettingsFrame, "UIPanelButtonTemplate")
    rescanButton:SetSize(100, 25)
    rescanButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    rescanButton:SetText("Rescan Mounts")
    rescanButton:SetScript("OnClick", function()
        print("|cFF33CCFFRaidMount:|r Rescanning mount collection...")
        RaidMountSettings.hasScannedCollection = false
        RaidMount.RefreshMountCollection()
    end)
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, RaidMount.SettingsFrame, "UIPanelButtonTemplate")
    closeButton:SetSize(80, 25)
    closeButton:SetPoint("BOTTOMRIGHT", -20, buttonY)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
        RaidMount.SettingsFrame:Hide()
    end)
end

-- Reset confirmation popup
StaticPopupDialogs["RAIDMOUNT_RESET_CONFIRM"] = {
    text = "Are you sure you want to reset all attempt data? This cannot be undone!",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function()
        RaidMount.ResetAttempts()
        RaidMount.PopulateUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Initialize UI when addon is loaded
local uiFrame = CreateFrame("Frame")
uiFrame:RegisterEvent("ADDON_LOADED")
uiFrame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName == "RaidMount" then
        -- Initialize default filter
        currentFilter = RaidMountSettings.filterDefault or "Uncollected"
    end
end) 