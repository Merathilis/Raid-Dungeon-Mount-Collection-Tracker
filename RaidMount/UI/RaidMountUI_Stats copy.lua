-- Stats module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- SHOW DETAILED STATS VIEW
function RaidMount.ShowDetailedStatsView()
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame:IsShown() then return end
    
    -- Clear existing content
    if RaidMount.ClearContentFrameChildren then
        RaidMount.ClearContentFrameChildren()
    end
    
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
    mainTitle:SetText(RaidMount.L("DETAILED_STATS"))
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
    overallHeader:SetText(RaidMount.L("OVERALL_STATS"))
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
    expansionHeader:SetText(RaidMount.L("BY_EXPANSION"))
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
    mostAttemptedHeader:SetText(RaidMount.L("MOST_ATTEMPTED"))
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
    backButton:SetText(RaidMount.L("BACK"))
    backButton:SetScript("OnClick", function()
        RaidMount.ToggleStatsView()
    end)
    table.insert(RaidMount.statsElements, backButton)
end 