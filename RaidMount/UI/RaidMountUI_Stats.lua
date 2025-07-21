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
    
    -- Create a dedicated stats frame
    local statsFrame = CreateFrame("ScrollFrame", nil, RaidMount.RaidMountFrame)
    statsFrame:SetPoint("TOPLEFT", 15, -165)
    statsFrame:SetPoint("BOTTOMRIGHT", -35, 40)
    statsFrame:SetFrameLevel(RaidMount.RaidMountFrame:GetFrameLevel() + 10)
    
    -- Create content frame for the scroll frame
    local statsContent = CreateFrame("Frame", nil, statsFrame)
    statsContent:SetSize(statsFrame:GetWidth() - 20, 1600) -- Increased height for all charts
    statsFrame:SetScrollChild(statsContent)
    
    -- Add background with gradient
    local statsBg = statsFrame:CreateTexture(nil, "BACKGROUND")
    statsBg:SetAllPoints()
    statsBg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble")
    statsBg:SetVertexColor(0.1, 0.1, 0.1, 0.95)
    
    -- Enable mouse wheel scrolling
    statsFrame:EnableMouseWheel(true)
    statsFrame:SetScript("OnMouseWheel", function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = math.max(0, math.min(maxScroll, current - (delta * 40)))
        self:SetVerticalScroll(newScroll)
    end)
    
    -- Play sound on stats view load
    PlaySound(567459, "SFX") -- SOUNDKIT.IG_MAINMENU_OPTION
    
    -- Store the stats frame for cleanup
    RaidMount.StatsFrame = statsFrame
    
    -- Use the stats content frame for positioning
    local frame = statsContent
    
    local mountData = RaidMount.GetCombinedMountData()
    if not mountData then return end
    
    -- Initialize stats tracking
    if not RaidMount.statsElements then
        RaidMount.statsElements = {}
    end
    
    -- Main stats title with glow
    local mainTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    mainTitle:SetPoint("TOPLEFT", 20, -20)
            mainTitle:SetFont(RaidMount.cachedFontPath, 18, "OUTLINE")
    mainTitle:SetTextColor(1, 0.82, 0, 1)
    mainTitle:SetText(RaidMount.L("DETAILED_STATS") or "Detailed Stats")
    mainTitle:SetShadowColor(0, 0, 0, 1)
    mainTitle:SetShadowOffset(2, -2)
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
                collected = mount.collected,
                attemptHistory = mount.attemptHistory or {attempts}
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
    local chartWidth = 300
    local chartHeight = 200
    
    -- LEFT COLUMN: Overall Statistics
    local overallHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    overallHeader:SetPoint("TOPLEFT", leftColumn, yPos)
            overallHeader:SetFont(RaidMount.cachedFontPath, 16, "OUTLINE")
    overallHeader:SetTextColor(1, 0.82, 0, 1)
    overallHeader:SetText(RaidMount.L("OVERALL_STATS") or "Overall Stats")
    overallHeader:SetShadowColor(0, 0, 0, 1)
    overallHeader:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, overallHeader)
    yPos = yPos - 25
    
    -- Progress Circle: Overall Collection Percentage
    local overallPercentage = (collectedMounts / totalMounts) * 100
    local progressCircleFrame = CreateFrame("Frame", nil, frame)
    progressCircleFrame:SetSize(100, 100)
    progressCircleFrame:SetPoint("TOPLEFT", leftColumn + 10, yPos)
    
    -- Circle background
    local circleBg = progressCircleFrame:CreateTexture(nil, "BACKGROUND")
    circleBg:SetAllPoints()
    circleBg:SetColorTexture(0.1, 0.1, 0.1, 0.8)
    
    -- Draw progress arc
    local radius = 40
    local centerX, centerY = 50, 50
    local arcAngle = (overallPercentage / 100) * 2 * math.pi
    local numSegments = math.floor(overallPercentage / 5) -- 5% per segment
    for i = 1, numSegments do
        local startAngle = (i - 1) * (arcAngle / numSegments)
        local endAngle = i * (arcAngle / numSegments)
        local arc = progressCircleFrame:CreateTexture(nil, "ARTWORK")
        arc:SetSize(radius * 2, radius * 2)
        arc:SetPoint("CENTER")
        arc:SetTexture("Interface\\Buttons\\WHITE8X8")
        arc:SetVertexColor(0.2, 0.8, 0.2, 0.9)
        arc:SetTexCoord(0.5 - math.cos(startAngle) / 2, 0.5 + math.sin(startAngle) / 2, 0.5 - math.cos(endAngle) / 2, 0.5 + math.sin(endAngle) / 2)
        
        -- Animate arc
        local animGroup = arc:CreateAnimationGroup()
        local anim = animGroup:CreateAnimation("Alpha")
        anim:SetFromAlpha(0)
        anim:SetToAlpha(1)
        anim:SetDuration(0.5)
        anim:SetStartDelay((i - 1) * 0.02)
        animGroup:Play()
        table.insert(RaidMount.statsElements, arc)
    end
    
    -- Progress text
    local circleText = progressCircleFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    circleText:SetPoint("CENTER")
            circleText:SetFont(RaidMount.cachedFontPath, 14, "OUTLINE")
    circleText:SetText(string.format("%.1f%%", overallPercentage))
    circleText:SetTextColor(1, 1, 1, 1)
    circleText:SetShadowColor(0, 0, 0, 1)
    circleText:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, progressCircleFrame)
    
    -- Tooltip for progress circle
    progressCircleFrame:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(string.format("Collection Progress\n%d / %d (%.1f%%)", collectedMounts, totalMounts, overallPercentage))
        GameTooltip:Show()
    end)
    progressCircleFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    
    yPos = yPos - 120
    
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
        statText:SetFont(RaidMount.cachedFontPath, 12, "OUTLINE")
        statText:SetText(stat)
        statText:SetShadowColor(0, 0, 0, 1)
        statText:SetShadowOffset(1, -1)
        table.insert(RaidMount.statsElements, statText)
        yPos = yPos - 18
    end
    
    yPos = yPos - 20
    
    -- Stacked Bar Chart: Collected vs Uncollected by Expansion
    local expansionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    expansionHeader:SetPoint("TOPLEFT", leftColumn, yPos)
            expansionHeader:SetFont(RaidMount.cachedFontPath, 16, "OUTLINE")
    expansionHeader:SetTextColor(1, 0.82, 0, 1)
    expansionHeader:SetText(RaidMount.L("BY_EXPANSION") or "By Expansion")
    expansionHeader:SetShadowColor(0, 0, 0, 1)
    expansionHeader:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, expansionHeader)
    yPos = yPos - 25
    
    -- Sort expansions by total mounts
    local sortedExpansions = {}
    for expansion, stats in pairs(expansionStats) do
        table.insert(sortedExpansions, {name = expansion, stats = stats})
    end
    table.sort(sortedExpansions, function(a, b) return a.stats.total > b.stats.total end)
    
    local maxTotal = 0
    for _, exp in ipairs(sortedExpansions) do
        maxTotal = math.max(maxTotal, exp.stats.total)
    end
    
    for i, expansion in ipairs(sortedExpansions) do
        local name = expansion.name
        local stats = expansion.stats
        local collected = stats.collected
        local uncollected = stats.total - stats.collected
        local barWidth = 300
        
        -- Expansion name
        local expansionName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        expansionName:SetPoint("TOPLEFT", leftColumn + 10, yPos)
                    expansionName:SetFont(RaidMount.cachedFontPath, 12, "OUTLINE")
        expansionName:SetText(name)
        expansionName:SetTextColor(0.9, 0.9, 0.9, 1)
        expansionName:SetShadowColor(0, 0, 0, 1)
        expansionName:SetShadowOffset(1, -1)
        table.insert(RaidMount.statsElements, expansionName)
        yPos = yPos - 18
        
        -- Stacked bar frame for interactivity
        local stackBarFrame = CreateFrame("Frame", nil, frame)
        stackBarFrame:SetSize(barWidth, 20)
        stackBarFrame:SetPoint("TOPLEFT", leftColumn + 20, yPos)
        
        -- Collected segment with tooltip
        local collectedWidth = (collected / maxTotal) * barWidth
        local collectedBarFrame = CreateFrame("Frame", nil, stackBarFrame)
        collectedBarFrame:SetSize(collectedWidth, 20)
        collectedBarFrame:SetPoint("LEFT")
        local collectedBar = collectedBarFrame:CreateTexture(nil, "ARTWORK")
        collectedBar:SetAllPoints()
        collectedBar:SetColorTexture(0.2, 0.8, 0.2, 0.9)
        collectedBarFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("%s\nCollected: %d", name, collected))
            GameTooltip:Show()
        end)
        collectedBarFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        -- Animate collected segment
        local animGroup1 = collectedBar:CreateAnimationGroup()
        local anim1 = animGroup1:CreateAnimation("Scale")
        anim1:SetScale(1, 20 / 0.01)
        anim1:SetDuration(0.5)
        anim1:SetStartDelay((i - 1) * 0.05)
        animGroup1:Play()
        
        -- Uncollected segment with tooltip
        local uncollectedWidth = (uncollected / maxTotal) * barWidth
        local uncollectedBarFrame = CreateFrame("Frame", nil, stackBarFrame)
        uncollectedBarFrame:SetSize(uncollectedWidth, 20)
        uncollectedBarFrame:SetPoint("LEFT", collectedWidth, 0)
        local uncollectedBar = uncollectedBarFrame:CreateTexture(nil, "ARTWORK")
        uncollectedBar:SetAllPoints()
        uncollectedBar:SetColorTexture(0.8, 0.2, 0.2, 0.9)
        uncollectedBarFrame:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("%s\nUncollected: %d", name, uncollected))
            GameTooltip:Show()
        end)
        uncollectedBarFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        -- Animate uncollected segment
        local animGroup2 = uncollectedBar:CreateAnimationGroup()
        local anim2 = animGroup2:CreateAnimation("Scale")
        anim2:SetScale(1, 20 / 0.01)
        anim2:SetDuration(0.5)
        anim2:SetStartDelay((i - 1) * 0.05 + 0.25)
        animGroup2:Play()
        
        -- Bar background
        local stackBg = stackBarFrame:CreateTexture(nil, "BACKGROUND")
        stackBg:SetAllPoints()
        stackBg:SetColorTexture(0.1, 0.1, 0.1, 0.6)
        
        table.insert(RaidMount.statsElements, stackBarFrame)
        yPos = yPos - 30
    end
    
    -- RIGHT COLUMN: Bar Chart, Line Chart, Line Graph
    local rightYPos = -60
    
    -- Bar Chart: Most Attempted Mounts
    local barChartHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    barChartHeader:SetPoint("TOPLEFT", rightColumn, rightYPos)
            barChartHeader:SetFont(RaidMount.cachedFontPath, 16, "OUTLINE")
    barChartHeader:SetTextColor(1, 0.82, 0, 1)
    barChartHeader:SetText(RaidMount.L("MOST_ATTEMPTED_MOUNTS") or "Most Attempted Mounts")
    barChartHeader:SetShadowColor(0, 0, 0, 1)
    barChartHeader:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, barChartHeader)
    rightYPos = rightYPos - 25
    
    local barChartFrame = CreateFrame("Frame", nil, frame)
    barChartFrame:SetSize(chartWidth, chartHeight)
    barChartFrame:SetPoint("TOPLEFT", rightColumn + 10, rightYPos)
    
    -- Chart background
    local barChartBg = barChartFrame:CreateTexture(nil, "BACKGROUND")
    barChartBg:SetAllPoints()
    barChartBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
    
    -- Draw bars with animation
    local maxDisplay = math.min(15, #mostAttemptedMounts)
    local maxAttempts = mostAttemptedMounts[1] and mostAttemptedMounts[1].attempts or 1
    local barWidth = (chartWidth - (maxDisplay - 1) * 5) / maxDisplay
    
    for i = 1, maxDisplay do
        local mount = mostAttemptedMounts[i]
        local barHeight = (mount.attempts / maxAttempts) * (chartHeight - 30)
        
        local bar = barChartFrame:CreateTexture(nil, "ARTWORK")
        bar:SetSize(barWidth, 0)
        bar:SetPoint("BOTTOMLEFT", (i - 1) * (barWidth + 5), 30)
        if mount.attempts >= 20 then
            bar:SetColorTexture(0.9, 0.1, 0.1, 0.9)
        elseif mount.attempts >= 15 then
            bar:SetColorTexture(1, 0.3, 0.3, 0.9)
        elseif mount.attempts >= 10 then
            bar:SetColorTexture(1, 0.5, 0, 0.9)
        elseif mount.attempts >= 5 then
            bar:SetColorTexture(1, 0.82, 0, 0.9)
        else
            bar:SetColorTexture(0.6, 0.6, 0.6, 0.9)
        end
        
        -- Animate bar growth with sound
        local animGroup = bar:CreateAnimationGroup()
        local anim = animGroup:CreateAnimation("Scale")
        anim:SetScale(1, barHeight / 0.01)
        anim:SetDuration(0.5)
        anim:SetStartDelay((i - 1) * 0.05)
        animGroup:SetScript("OnPlay", function() PlaySound(567459, "SFX") end)
        animGroup:Play()
        bar:SetSize(barWidth, barHeight)
        table.insert(RaidMount.statsElements, bar)
        
        -- Mount name label (rotated)
        local displayName = mount.name
        if #displayName > 10 then
            displayName = displayName:sub(1, 7) .. "..."
        end
        local label = barChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("BOTTOMLEFT", (i - 1) * (barWidth + 5) + barWidth / 2, 5)
                    label:SetFont(RaidMount.cachedFontPath, 10, "OUTLINE")
        label:SetText(displayName)
        label:SetTextColor(1, 1, 1, 1)
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)
        label:SetRotation(math.rad(-45))
        table.insert(RaidMount.statsElements, label)
        
        -- Attempt count above bar
        local attemptText = barChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        attemptText:SetPoint("BOTTOM", bar, "TOP", 0, 2)
                    attemptText:SetFont(RaidMount.cachedFontPath, 10, "OUTLINE")
        attemptText:SetText(mount.attempts)
        attemptText:SetTextColor(1, 1, 1, 1)
        attemptText:SetShadowColor(0, 0, 0, 1)
        attemptText:SetShadowOffset(1, -1)
        table.insert(RaidMount.statsElements, attemptText)
        
        -- Tooltip
        bar:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("%s\nSource: %s\nAttempts: %d\nCollected: %s", mount.name, mount.source, mount.attempts, mount.collected and "Yes" or "No"))
            GameTooltip:Show()
        end)
        bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end
    
    -- Y-axis label
    local yAxisLabel = barChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yAxisLabel:SetPoint("TOPLEFT", -40, -10)
    yAxisLabel:SetFont(cachedFontPath, 11, "OUTLINE")
    yAxisLabel:SetText("Attempts")
    yAxisLabel:SetTextColor(1, 0.82, 0, 1)
    yAxisLabel:SetShadowColor(0, 0, 0, 1)
    yAxisLabel:SetShadowOffset(1, -1)
    yAxisLabel:SetRotation(math.rad(-90))
    table.insert(RaidMount.statsElements, yAxisLabel)
    
    -- X-axis label
    local xAxisLabel = barChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xAxisLabel:SetPoint("BOTTOM", barChartFrame, "BOTTOM", 0, -20)
    xAxisLabel:SetFont(cachedFontPath, 11, "OUTLINE")
    xAxisLabel:SetText("Mounts")
    xAxisLabel:SetTextColor(1, 0.82, 0, 1)
    xAxisLabel:SetShadowColor(0, 0, 0, 1)
    xAxisLabel:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, xAxisLabel)
    
    rightYPos = rightYPos - chartHeight - 40
    
    -- Line Chart: Attempt History for Most Attempted Mount
    if mostAttemptedMount and mostAttemptedMount.attemptHistory and #mostAttemptedMount.attemptHistory > 1 then
        local lineChartHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        lineChartHeader:SetPoint("TOPLEFT", rightColumn, rightYPos)
        lineChartHeader:SetFont(cachedFontPath, 16, "OUTLINE")
        lineChartHeader:SetTextColor(1, 0.82, 0, 1)
        lineChartHeader:SetText(string.format(RaidMount.L("ATTEMPT_HISTORY") or "Attempt History: %s", mostAttemptedMount.name))
        lineChartHeader:SetShadowColor(0, 0, 0, 1)
        lineChartHeader:SetShadowOffset(1, -1)
        table.insert(RaidMount.statsElements, lineChartHeader)
        rightYPos = rightYPos - 25
        
        local lineChartFrame = CreateFrame("Frame", nil, frame)
        lineChartFrame:SetSize(chartWidth, chartHeight)
        lineChartFrame:SetPoint("TOPLEFT", rightColumn + 10, rightYPos)
        
        -- Chart background
        local lineChartBg = lineChartFrame:CreateTexture(nil, "BACKGROUND")
        lineChartBg:SetAllPoints()
        lineChartBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
        
        -- Draw line graph
        local attemptHistory = mostAttemptedMount.attemptHistory
        local maxAttemptsInHistory = math.max(unpack(attemptHistory))
        local numPoints = math.min(#attemptHistory, 10)
        
        for i = 1, numPoints - 1 do
            local x1 = (i - 1) * (chartWidth / (numPoints - 1))
            local x2 = i * (chartWidth / (numPoints - 1))
            local y1 = (attemptHistory[i] / maxAttemptsInHistory) * (chartHeight - 30)
            local y2 = (attemptHistory[i + 1] / maxAttemptsInHistory) * (chartHeight - 30)
            
            -- Draw line segment
            local line = lineChartFrame:CreateLine()
            line:SetStartPoint("BOTTOMLEFT", x1, y1 + 30)
            line:SetEndPoint("BOTTOMLEFT", x2, y2 + 30)
            line:SetColorTexture(1, 0.82, 0, 0.9)
            line:SetThickness(3)
            table.insert(RaidMount.statsElements, line)
            
            -- Draw point with glow
            local point = lineChartFrame:CreateTexture(nil, "OVERLAY")
            point:SetSize(10, 10)
            point:SetPoint("BOTTOMLEFT", x1 - 5, y1 + 25)
            point:SetTexture("Interface\\Buttons\\WHITE8X8")
            point:SetVertexColor(1, 0.82, 0, 1)
            table.insert(RaidMount.statsElements, point)
            
            -- Tooltip
            point:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(string.format("%s\nSession %d: %d attempts", mostAttemptedMount.name, i, attemptHistory[i]))
                GameTooltip:Show()
            end)
            point:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
        
        -- Last point
        local lastPoint = lineChartFrame:CreateTexture(nil, "OVERLAY")
        lastPoint:SetSize(10, 10)
        lastPoint:SetPoint("BOTTOMLEFT", chartWidth - 5, ((attemptHistory[numPoints] / maxAttemptsInHistory) * (chartHeight - 30)) + 25)
        lastPoint:SetTexture("Interface\\Buttons\\WHITE8X8")
        lastPoint:SetVertexColor(1, 0.82, 0, 1)
        table.insert(RaidMount.statsElements, lastPoint)
        
        lastPoint:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(string.format("%s\nSession %d: %d attempts", mostAttemptedMount.name, numPoints, attemptHistory[numPoints]))
            GameTooltip:Show()
        end)
        lastPoint:SetScript("OnLeave", function() GameTooltip:Hide() end)
        
        -- Y-axis label
        local yAxisLabel = lineChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        yAxisLabel:SetPoint("TOPLEFT", -40, -10)
        yAxisLabel:SetFont(RaidMount.cachedFontPath, 11, "OUTLINE")
        yAxisLabel:SetText("Attempts")
        yAxisLabel:SetTextColor(1, 0.82, 0, 1)
        yAxisLabel:SetShadowColor(0, 0, 0, 1)
        yAxisLabel:SetShadowOffset(1, -1)
        yAxisLabel:SetRotation(math.rad(-90))
        table.insert(RaidMount.statsElements, yAxisLabel)
        
        -- X-axis label
        local xAxisLabel = lineChartFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        xAxisLabel:SetPoint("BOTTOM", lineChartFrame, "BOTTOM", 0, -20)
        xAxisLabel:SetFont(cachedFontPath, 11, "OUTLINE")
        xAxisLabel:SetText("Sessions")
        xAxisLabel:SetTextColor(1, 0.82, 0, 1)
        xAxisLabel:SetShadowColor(0, 0, 0, 1)
        xAxisLabel:SetShadowOffset(1, -1)
        table.insert(RaidMount.statsElements, xAxisLabel)
        
        rightYPos = rightYPos - chartHeight - 40
    end
    
    -- Line Graph: Collected Mounts by Expansion
    local lineGraphHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lineGraphHeader:SetPoint("TOPLEFT", rightColumn, rightYPos)
    lineGraphHeader:SetFont(cachedFontPath, 16, "OUTLINE")
    lineGraphHeader:SetTextColor(1, 0.82, 0, 1)
    lineGraphHeader:SetText(RaidMount.L("COLLECTED_BY_EXPANSION") or "Collected by Expansion")
    lineGraphHeader:SetShadowColor(0, 0, 0, 1)
    lineGraphHeader:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, lineGraphHeader)
    rightYPos = rightYPos - 25
    
    local lineGraphFrame = CreateFrame("Frame", nil, frame)
    lineGraphFrame:SetSize(chartWidth, chartHeight)
    lineGraphFrame:SetPoint("TOPLEFT", rightColumn + 10, rightYPos)
    
    -- Chart background
    local lineGraphBg = lineGraphFrame:CreateTexture(nil, "BACKGROUND")
    lineGraphBg:SetAllPoints()
    lineGraphBg:SetColorTexture(0.05, 0.05, 0.05, 0.7)
    
    -- Draw line graph
    local maxCollected = 0
    for _, exp in ipairs(sortedExpansions) do
        maxCollected = math.max(maxCollected, exp.stats.collected)
    end
    
    local prevX, prevY = nil, nil
    for i, exp in ipairs(sortedExpansions) do
        if exp.stats.collected > 0 then
            local x = (i - 1) * (chartWidth / (#sortedExpansions - 1))
            local y = (exp.stats.collected / maxCollected) * (chartHeight - 30) + 30
            
            -- Draw point
            local point = lineGraphFrame:CreateTexture(nil, "OVERLAY")
            point:SetSize(10, 10)
            point:SetPoint("BOTTOMLEFT", x - 5, y - 5)
            point:SetTexture("Interface\\Buttons\\WHITE8X8")
            point:SetVertexColor(0.2, 0.8, 0.2, 1) -- Green for collected
            table.insert(RaidMount.statsElements, point)
            
            -- Draw line segment
            if prevX and prevY then
                local line = lineGraphFrame:CreateLine()
                line:SetStartPoint("BOTTOMLEFT", prevX, prevY)
                line:SetEndPoint("BOTTOMLEFT", x, y)
                line:SetColorTexture(0.2, 0.8, 0.2, 0.9)
                line:SetThickness(3)
                table.insert(RaidMount.statsElements, line)
            end
            prevX, prevY = x, y
            
            -- Tooltip
            point:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText(string.format("%s\nCollected: %d", exp.name, exp.stats.collected))
                GameTooltip:Show()
            end)
            point:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end
    end
    
    -- Y-axis label
    local yAxisLabel = lineGraphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    yAxisLabel:SetPoint("TOPLEFT", -40, -10)
    yAxisLabel:SetFont(cachedFontPath, 11, "OUTLINE")
    yAxisLabel:SetText("Collected")
    yAxisLabel:SetTextColor(1, 0.82, 0, 1)
    yAxisLabel:SetShadowColor(0, 0, 0, 1)
    yAxisLabel:SetShadowOffset(1, -1)
    yAxisLabel:SetRotation(math.rad(-90))
    table.insert(RaidMount.statsElements, yAxisLabel)
    
    -- X-axis label
    local xAxisLabel = lineGraphFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    xAxisLabel:SetPoint("BOTTOM", lineGraphFrame, "BOTTOM", 0, -20)
    xAxisLabel:SetFont(cachedFontPath, 11, "OUTLINE")
    xAxisLabel:SetText("Expansions")
    xAxisLabel:SetTextColor(1, 0.82, 0, 1)
    xAxisLabel:SetShadowColor(0, 0, 0, 1)
    xAxisLabel:SetShadowOffset(1, -1)
    table.insert(RaidMount.statsElements, xAxisLabel)
    
    rightYPos = rightYPos - chartHeight - 40
    
    -- Add "Back" button
    local backButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    backButton:SetSize(100, 30)
    backButton:SetPoint("BOTTOM", 0, 10)
    backButton:SetText(RaidMount.L("BACK") or "Back")
    backButton:SetNormalFontObject("GameFontNormal")
    backButton:SetHighlightFontObject("GameFontHighlight")
    backButton:SetScript("OnClick", function()
        RaidMount.ToggleStatsView()
    end)
    table.insert(RaidMount.statsElements, backButton)
end