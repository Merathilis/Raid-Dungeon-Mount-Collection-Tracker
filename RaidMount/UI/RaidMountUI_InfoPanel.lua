-- Info Panel module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Create info panel for mount details
function RaidMount.CreateInfoPanel(frame)
    if frame.infoPanel then return frame.infoPanel end
    
    local infoPanel = CreateFrame("Frame", nil, frame)
    infoPanel:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 35)
    infoPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 35)
    infoPanel:SetHeight(120)
    
    -- Professional background with subtle gradient
    local bg = infoPanel:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.12, 0.95)
    
    -- Top border accent
    local topBorder = infoPanel:CreateTexture(nil, "BORDER")
    topBorder:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 0, 0)
    topBorder:SetPoint("TOPRIGHT", infoPanel, "TOPRIGHT", 0, 0)
    topBorder:SetHeight(2)
    topBorder:SetColorTexture(0.3, 0.6, 1, 0.8)
    
    infoPanel:Hide()
    frame.infoPanel = infoPanel
    
    -- HEADER SECTION (Top row with icon, name, status) - contained within panel
    local icon = infoPanel:CreateTexture(nil, "OVERLAY")
    icon:SetSize(36, 36)
    icon:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 10, -8)
    infoPanel.icon = icon

    -- Mount Name (large, prominent but contained)
    local name = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 12, -2)
    name:SetFont(cachedFontPath, 22, "OUTLINE") -- Increased font size further
    name:SetJustifyH("LEFT")
    name:SetWidth(300)
    infoPanel.name = name

    -- Status icon and text - positioned to not overlap
    local statusIcon = infoPanel:CreateTexture(nil, "OVERLAY")
    statusIcon:SetSize(22, 22) -- Larger status icon
    statusIcon:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    infoPanel.statusIcon = statusIcon
    
    local statusText = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", statusIcon, "RIGHT", 6, 0)
    statusText:SetFont(cachedFontPath, 16, "OUTLINE") -- Increased font size further
    statusText:SetJustifyH("LEFT")
    statusText:SetWidth(200)
    infoPanel.statusText = statusText

    -- MAIN CONTENT AREA - Four column layout with columns moved up
    -- Column 1: Source Information (Left) - positioned below status, NO HEADER
    local source = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    source:SetPoint("TOPLEFT", statusIcon, "BOTTOMLEFT", 0, -8)
    source:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    source:SetJustifyH("LEFT")
    source:SetWidth(180)
    infoPanel.source = source

    local boss = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boss:SetPoint("TOPLEFT", source, "BOTTOMLEFT", 0, -3)
    boss:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    boss:SetJustifyH("LEFT")
    boss:SetWidth(180)
    infoPanel.boss = boss

    local location = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    location:SetPoint("TOPLEFT", boss, "BOTTOMLEFT", 0, -3)
    location:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    location:SetJustifyH("LEFT")
    location:SetWidth(180)
    infoPanel.location = location

    -- Column 2: Attempt Tracking - MOVED UP to align with mount name
    local col2Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col2Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 320, -8) -- Aligned with mount name
    col2Header:SetFont(cachedFontPath, 14, "OUTLINE") -- Increased font size further
    col2Header:SetText("|cFFFFD700ATTEMPT TRACKING|r")
    col2Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col2Header = col2Header

    local totalAttempts = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalAttempts:SetPoint("TOPLEFT", col2Header, "BOTTOMLEFT", 0, -3)
    totalAttempts:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    totalAttempts:SetJustifyH("LEFT")
    totalAttempts:SetWidth(180)
    infoPanel.totalAttempts = totalAttempts

    local charAttempts1 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts1:SetPoint("TOPLEFT", totalAttempts, "BOTTOMLEFT", 0, -2)
    charAttempts1:SetFont(cachedFontPath, 12, "OUTLINE") -- Increased font size further
    charAttempts1:SetJustifyH("LEFT")
    charAttempts1:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts1:SetWidth(180)
    infoPanel.charAttempts1 = charAttempts1

    local charAttempts2 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts2:SetPoint("TOPLEFT", charAttempts1, "BOTTOMLEFT", 0, -2)
    charAttempts2:SetFont(cachedFontPath, 12, "OUTLINE") -- Increased font size further
    charAttempts2:SetJustifyH("LEFT")
    charAttempts2:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts2:SetWidth(180)
    infoPanel.charAttempts2 = charAttempts2

    local charAttempts3 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts3:SetPoint("TOPLEFT", charAttempts2, "BOTTOMLEFT", 0, -2)
    charAttempts3:SetFont(cachedFontPath, 12, "OUTLINE") -- Increased font size further
    charAttempts3:SetJustifyH("LEFT")
    charAttempts3:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts3:SetWidth(180)
    infoPanel.charAttempts3 = charAttempts3

    local charAttempts4 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts4:SetPoint("TOPLEFT", charAttempts3, "BOTTOMLEFT", 0, -2)
    charAttempts4:SetFont(cachedFontPath, 12, "OUTLINE") -- Increased font size further
    charAttempts4:SetJustifyH("LEFT")
    charAttempts4:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts4:SetWidth(180)
    infoPanel.charAttempts4 = charAttempts4

    -- Column 3: Status & Lockout - now with lockout timer
    local col3Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col3Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 510, -8) -- Aligned with mount name
    col3Header:SetFont(cachedFontPath, 14, "OUTLINE") -- Increased font size further
    col3Header:SetText("|cFFFFD700STATUS & LOCKOUT|r")
    col3Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col3Header = col3Header

    local lockoutStatus = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockoutStatus:SetPoint("TOPLEFT", col3Header, "BOTTOMLEFT", 0, -3)
    lockoutStatus:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    lockoutStatus:SetJustifyH("LEFT")
    lockoutStatus:SetWidth(160)
    infoPanel.lockoutStatus = lockoutStatus

    local lockoutTimer = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockoutTimer:SetPoint("TOPLEFT", lockoutStatus, "BOTTOMLEFT", 0, -2)
    lockoutTimer:SetFont(cachedFontPath, 13, "OUTLINE") -- Replaced lastAttempt with lockoutTimer
    lockoutTimer:SetJustifyH("LEFT")
    lockoutTimer:SetWidth(160)
    lockoutTimer:SetTextColor(1, 0.8, 0.2, 1) -- Orange color for timer
    infoPanel.lockoutTimer = lockoutTimer

    local collectionDate = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    collectionDate:SetPoint("TOPLEFT", lockoutTimer, "BOTTOMLEFT", 0, -2)
    collectionDate:SetFont(cachedFontPath, 13, "OUTLINE") -- Increased font size further
    collectionDate:SetJustifyH("LEFT")
    collectionDate:SetWidth(160)
    collectionDate:SetTextColor(0.6, 1, 0.6, 1)
    infoPanel.collectionDate = collectionDate

    -- Column 4: Description - MOVED UP to align with attempt tracking
    local col4Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col4Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 680, -8) -- Aligned with mount name
    col4Header:SetFont(cachedFontPath, 14, "OUTLINE") -- Increased font size further
    col4Header:SetText("|cFFFFD700DESCRIPTION|r")
    col4Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col4Header = col4Header

    local description = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOPLEFT", col4Header, "BOTTOMLEFT", 0, 2)
    description:SetPoint("TOPRIGHT", infoPanel, "TOPRIGHT", -10, -18)
    description:SetFont(cachedFontPath, 14, "OUTLINE") -- Adjusted font size to 14 for balance
    description:SetJustifyH("LEFT")
    description:SetTextColor(0.9, 0.9, 0.9, 1)
    description:SetHeight(90) -- Much larger description area
    infoPanel.description = description
    
    return infoPanel
end

-- Show info panel with mount data
function RaidMount.ShowInfoPanel(data)
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame.infoPanel then return end
    
    local panel = RaidMount.RaidMountFrame.infoPanel
    panel:Show()
    
    -- Icon
    local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    if data.mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(data.mountID)
        if iconFile then icon = iconFile end
    end
    panel.icon:SetTexture(icon)
    
    -- Mount Name with rarity coloring - truncated if too long
    local nameColor = "|cFFA335EE" -- Default purple for raid mounts
    if data.mountID and C_MountJournal then
        local mountName, spellID, iconFile, isActive, isUsable, sourceType = C_MountJournal.GetMountInfoByID(data.mountID)
        if mountName and sourceType then
            local quality = 4 -- Default to epic
            if sourceType == 7 or sourceType == 9 then quality = 5 -- TCG/Promotional
            elseif sourceType == 2 or sourceType == 3 or sourceType == 6 then quality = 3 end -- Quest/Vendor/Profession
            
            if quality == 3 then
                nameColor = data.collected and "|cFF0070DD" or "|cFF0055AA" -- Blue
            elseif quality == 4 then
                nameColor = data.collected and "|cFFA335EE" or "|cFF7F26BB" -- Purple
            elseif quality == 5 then
                nameColor = data.collected and "|cFFFF8000" or "|cFFBF6000" -- Orange
            end
        end
    end
    
    -- Truncate mount name if too long to prevent overflow
    local mountName = data.mountName or "Unknown Mount"
    if #mountName > 30 then
        mountName = mountName:sub(1, 27) .. "..."
    end
    panel.name:SetText(nameColor .. mountName .. "|r")
    
    -- Status icon and text
    if data.collected then
        panel.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        panel.statusText:SetText("|cFF00FF00Collected|r")
    else
        panel.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        panel.statusText:SetText("|cFFFF6666Not Collected|r")
    end
    
    -- Column 1: Source Information - now with more space and no header
    local raidName = data.raidName or data.dungeonName or data.location or "Unknown"
    if #raidName > 22 then raidName = raidName:sub(1, 19) .. "..." end
    panel.source:SetText("Raid: |cFFFFFFFF" .. raidName .. "|r")
    
    local bossName = data.bossName or "Unknown"
    if #bossName > 22 then bossName = bossName:sub(1, 19) .. "..." end
    panel.boss:SetText("Boss: |cFFDDA0DD" .. bossName .. "|r")
    
    local locationName = data.location or "Unknown"
    if #locationName > 22 then locationName = locationName:sub(1, 19) .. "..." end
    panel.location:SetText("Zone: |cFF87CEEB" .. locationName .. "|r")
    
    -- Column 2: Attempt Tracking - now with much more space for alts
    local attempts = tonumber(data.attempts) or 0
    local attemptsColor = attempts > 0 and "|cFFFFD700" or "|cFFCCCCCC"
    panel.totalAttempts:SetText("Total Attempts: " .. attemptsColor .. attempts .. "|r")
    
    -- Character attempts breakdown - now with 4 lines for more alts
    panel.charAttempts1:SetText("")
    panel.charAttempts2:SetText("")
    panel.charAttempts3:SetText("")
    panel.charAttempts4:SetText("")
    
    local trackingKey = data.spellID or data.mountID
    local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
    
    if attemptData and type(attemptData) == "table" and attemptData.characters then
        local characterAttempts = {}
        for charName, count in pairs(attemptData.characters) do
            if type(count) == "number" and count > 0 then
                local shortName = charName:match("([^%-]+)") or charName
                if #shortName > 12 then shortName = shortName:sub(1, 12) end
                local lastAttemptDate = "Never"
                if attemptData.lastAttemptDates and attemptData.lastAttemptDates[charName] then
                    lastAttemptDate = attemptData.lastAttemptDates[charName]
                end
                table.insert(characterAttempts, {
                    name = shortName, 
                    count = count, 
                    lastAttempt = lastAttemptDate
                })
            end
        end
        
        if #characterAttempts > 0 then
            table.sort(characterAttempts, function(a, b) return a.count > b.count end)
            
            -- Display up to 4 characters now
            if characterAttempts[1] then
                panel.charAttempts1:SetText(characterAttempts[1].name .. ": " .. characterAttempts[1].count .. " attempts (" .. characterAttempts[1].lastAttempt .. ")")
            end
            if characterAttempts[2] then
                panel.charAttempts2:SetText(characterAttempts[2].name .. ": " .. characterAttempts[2].count .. " attempts (" .. characterAttempts[2].lastAttempt .. ")")
            end
            if characterAttempts[3] then
                panel.charAttempts3:SetText(characterAttempts[3].name .. ": " .. characterAttempts[3].count .. " attempts (" .. characterAttempts[3].lastAttempt .. ")")
            end
            if characterAttempts[4] then
                panel.charAttempts4:SetText(characterAttempts[4].name .. ": " .. characterAttempts[4].count .. " attempts (" .. characterAttempts[4].lastAttempt .. ")")
            elseif #characterAttempts > 4 then
                panel.charAttempts4:SetText("|cFF999999+" .. (#characterAttempts - 3) .. " more characters|r")
            end
        end
    end
    
    -- Column 3: Status & Lockout - now with lockout timer
    if data.lockoutStatus and data.lockoutStatus ~= "Unknown" then
        local lockoutColor = data.lockoutStatus == "No lockout" and "|cFF00FF00" or "|cFFFF6666"
        local lockoutText = data.lockoutStatus
        if #lockoutText > 18 then lockoutText = lockoutText:sub(1, 15) .. "..." end
        panel.lockoutStatus:SetText("Lockout: " .. lockoutColor .. lockoutText .. "|r")
    else
        panel.lockoutStatus:SetText("Lockout: |cFFCCCCCCUnknown|r")
    end
    
    -- Lockout Timer - Use the actual lockout data from the game API
    local lockoutTimerText = "Available Now"
    local lockoutColor = "|cFF00FF00" -- Green for available
    
    -- First, check if we have actual lockout data from the game API
    if data.lockoutStatus and data.lockoutStatus ~= "Unknown" and data.lockoutStatus ~= "No lockout" then
        -- If there's a lockout, use the same time as the lockout status
        lockoutTimerText = data.lockoutStatus
        lockoutColor = "|cFFFF6666" -- Red for locked out
    else
        -- Fallback to addon tracking if no game API lockout data
        local trackingKey = data.spellID or data.mountID
        local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
        local currentCharacter = UnitName("player") .. "-" .. GetRealmName()
        
        if attemptData and attemptData.lastAttemptDates and attemptData.lastAttemptDates[currentCharacter] then
            local lastAttemptDate = attemptData.lastAttemptDates[currentCharacter]
            
            -- Parse the date (assuming format is dd/mm/yy)
            if lastAttemptDate and lastAttemptDate ~= "Never" then
                local day, month, year = lastAttemptDate:match("(%d+)/(%d+)/(%d+)")
                if day and month and year then
                    -- Convert to full year
                    year = tonumber(year)
                    if year < 50 then
                        year = year + 2000
                    else
                        year = year + 1900
                    end
                    
                    -- Calculate next reset (weekly reset is Tuesday)
                    local lastAttemptTime = time({year = year, month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0})
                    local currentTime = time()
                    
                    -- Find next Tuesday reset
                    local currentDate = date("*t", currentTime)
                    local daysUntilTuesday = (3 - currentDate.wday + 7) % 7 -- Tuesday is day 3
                    if daysUntilTuesday == 0 and currentDate.hour < 9 then -- Reset is at 9 AM
                        daysUntilTuesday = 0
                    elseif daysUntilTuesday == 0 then
                        daysUntilTuesday = 7
                    end
                    
                    local nextResetTime = time({
                        year = currentDate.year,
                        month = currentDate.month,
                        day = currentDate.day + daysUntilTuesday,
                        hour = 9,
                        min = 0,
                        sec = 0
                    })
                    
                    -- Check if last attempt was after the most recent reset
                    local lastResetTime = nextResetTime - (7 * 24 * 60 * 60) -- Previous Tuesday
                    if lastAttemptTime > lastResetTime then
                        -- Character is locked out
                        local timeUntilReset = nextResetTime - currentTime
                        if timeUntilReset > 0 then
                            local days = math.floor(timeUntilReset / (24 * 60 * 60))
                            local hours = math.floor((timeUntilReset % (24 * 60 * 60)) / (60 * 60))
                            local minutes = math.floor((timeUntilReset % (60 * 60)) / 60)
                            
                            if days > 0 then
                                lockoutTimerText = string.format("%dd %dh %dm", days, hours, minutes)
                            elseif hours > 0 then
                                lockoutTimerText = string.format("%dh %dm", hours, minutes)
                            else
                                lockoutTimerText = string.format("%dm", minutes)
                            end
                            lockoutColor = "|cFFFF6666" -- Red for locked out
                        end
                    end
                end
            end
        end
    end
    
    panel.lockoutTimer:SetText("Next Attempt: " .. lockoutColor .. lockoutTimerText .. "|r")
    
    if data.collected then
        local collectionText = data.collectionDate or "Unknown Date"
        if #collectionText > 18 then collectionText = collectionText:sub(1, 15) .. "..." end
        panel.collectionDate:SetText("Collected: |cFF00FF00" .. collectionText .. "|r")
    else
        panel.collectionDate:SetText("")
    end
    
    -- Column 4: Description - now with much more space
    local descText = data.description or ""
    
    -- If no description in data, try to find it from mount data
    if descText == "" and RaidMount.mountInstances then
        for _, mount in ipairs(RaidMount.mountInstances) do
            if (mount.mountName == data.mountName or mount.MountID == data.mountID or mount.spellID == data.spellID) and mount.description then
                descText = mount.description
                break
            end
        end
    end
    
    if descText ~= "" then
        -- Allow much longer descriptions with the larger area
        if #descText > 300 then
            descText = descText:sub(1, 297) .. "..."
        end
        panel.description:SetText(descText)
    else
        panel.description:SetText("No description available.")
    end
end

-- Hide info panel
function RaidMount.HideInfoPanel()
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
        RaidMount.RaidMountFrame.infoPanel:Hide()
    end
end

-- Update info panel position when ScrollFrame is resized
function RaidMount.UpdateInfoPanelPosition()
    if not RaidMount.RaidMountFrame or not RaidMount.ScrollFrame then return end
    
    -- Move content frame up to make space for info panel
    RaidMount.ScrollFrame:ClearAllPoints()
    RaidMount.ScrollFrame:SetPoint("TOPLEFT", 15, -165)
    RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", -35, 160)
end 