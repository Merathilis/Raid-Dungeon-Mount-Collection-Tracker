-- Info Panel module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Define class colors at the top of the file
local CLASS_COLORS = {
    DEATHKNIGHT = "C41F3B",
    DEMONHUNTER = "A330C9",
    DRUID       = "FF7D0A",
    EVOKER      = "33937F",
    HUNTER      = "ABD473",
    MAGE        = "69CCF0",
    MONK        = "00FF96",
    PALADIN     = "F58CBA",
    PRIEST      = "FFFFFF",
    ROGUE       = "FFF569",
    SHAMAN      = "0070DE",
    WARLOCK     = "9482C9",
    WARRIOR     = "C79C6E",
}

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
    name:SetFont(cachedFontPath, 22, "OUTLINE")
    name:SetJustifyH("LEFT")
    name:SetWidth(300)
    infoPanel.name = name

    -- Status icon and text - positioned to not overlap
    local statusIcon = infoPanel:CreateTexture(nil, "OVERLAY")
    statusIcon:SetSize(22, 22)
    statusIcon:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -4)
    infoPanel.statusIcon = statusIcon
    
    local statusText = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    statusText:SetPoint("LEFT", statusIcon, "RIGHT", 6, 0)
    statusText:SetFont(cachedFontPath, 16, "OUTLINE")
    statusText:SetJustifyH("LEFT")
    statusText:SetWidth(200)
    infoPanel.statusText = statusText

    -- MAIN CONTENT AREA - Four column layout with columns moved up
    -- Column 1: Source Information (Left) - positioned below status, NO HEADER
    local source = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    source:SetPoint("TOPLEFT", statusIcon, "BOTTOMLEFT", 0, -8)
    source:SetFont(cachedFontPath, 13, "OUTLINE")
    source:SetJustifyH("LEFT")
    source:SetWidth(180)
    infoPanel.source = source

    local boss = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    boss:SetPoint("TOPLEFT", source, "BOTTOMLEFT", 0, -3)
    boss:SetFont(cachedFontPath, 13, "OUTLINE")
    boss:SetJustifyH("LEFT")
    boss:SetWidth(180)
    infoPanel.boss = boss

    local location = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    location:SetPoint("TOPLEFT", boss, "BOTTOMLEFT", 0, -3)
    location:SetFont(cachedFontPath, 13, "OUTLINE")
    location:SetJustifyH("LEFT")
    location:SetWidth(180)
    infoPanel.location = location

    -- Column 2: Attempt Tracking - MOVED UP to align with mount name
    local col2Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col2Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 320, -8)
    col2Header:SetFont(cachedFontPath, 14, "OUTLINE")
    col2Header:SetText("|cFFFFD700" .. RaidMount.L("ATTEMPT_TRACKING") .. "|r")
    col2Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col2Header = col2Header

    local totalAttempts = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    totalAttempts:SetPoint("TOPLEFT", col2Header, "BOTTOMLEFT", 0, -3)
    totalAttempts:SetFont(cachedFontPath, 13, "OUTLINE")
    totalAttempts:SetJustifyH("LEFT")
    totalAttempts:SetWidth(180)
    infoPanel.totalAttempts = totalAttempts

    local charAttempts1 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts1:SetPoint("TOPLEFT", totalAttempts, "BOTTOMLEFT", 0, -2)
    charAttempts1:SetFont(cachedFontPath, 12, "OUTLINE")
    charAttempts1:SetJustifyH("LEFT")
    charAttempts1:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts1:SetWidth(180)
    infoPanel.charAttempts1 = charAttempts1

    local charAttempts2 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts2:SetPoint("TOPLEFT", charAttempts1, "BOTTOMLEFT", 0, -2)
    charAttempts2:SetFont(cachedFontPath, 12, "OUTLINE")
    charAttempts2:SetJustifyH("LEFT")
    charAttempts2:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts2:SetWidth(180)
    infoPanel.charAttempts2 = charAttempts2

    local charAttempts3 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts3:SetPoint("TOPLEFT", charAttempts2, "BOTTOMLEFT", 0, -2)
    charAttempts3:SetFont(cachedFontPath, 12, "OUTLINE")
    charAttempts3:SetJustifyH("LEFT")
    charAttempts3:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts3:SetWidth(180)
    infoPanel.charAttempts3 = charAttempts3

    local charAttempts4 = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    charAttempts4:SetPoint("TOPLEFT", charAttempts3, "BOTTOMLEFT", 0, -2)
    charAttempts4:SetFont(cachedFontPath, 12, "OUTLINE")
    charAttempts4:SetJustifyH("LEFT")
    charAttempts4:SetTextColor(0.7, 1, 0.7, 1)
    charAttempts4:SetWidth(180)
    infoPanel.charAttempts4 = charAttempts4

    -- Column 3: Status & Lockout - now with lockout timer
    local col3Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col3Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 510, -8)
    col3Header:SetFont(cachedFontPath, 14, "OUTLINE")
    col3Header:SetText("|cFFFFD700" .. RaidMount.L("STATUS_LOCKOUT") .. "|r")
    col3Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col3Header = col3Header

    local lockoutStatus = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockoutStatus:SetPoint("TOPLEFT", col3Header, "BOTTOMLEFT", 0, -3)
    lockoutStatus:SetFont(cachedFontPath, 13, "OUTLINE")
    lockoutStatus:SetJustifyH("LEFT")
    lockoutStatus:SetWidth(160)
    infoPanel.lockoutStatus = lockoutStatus

    local lockoutTimer = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockoutTimer:SetPoint("TOPLEFT", lockoutStatus, "BOTTOMLEFT", 0, -2)
    lockoutTimer:SetFont(cachedFontPath, 13, "OUTLINE")
    lockoutTimer:SetJustifyH("LEFT")
    lockoutTimer:SetWidth(160)
    lockoutTimer:SetTextColor(1, 0.8, 0.2, 1)
    infoPanel.lockoutTimer = lockoutTimer



    local collectionDate = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    collectionDate:SetPoint("TOPLEFT", lockoutTimer, "BOTTOMLEFT", 0, -2)
    collectionDate:SetFont(cachedFontPath, 13, "OUTLINE")
    collectionDate:SetJustifyH("LEFT")
    collectionDate:SetWidth(160)
    collectionDate:SetTextColor(0.6, 1, 0.6, 1)
    infoPanel.collectionDate = collectionDate

    -- Column 4: Description - MOVED UP to align with attempt tracking
    local col4Header = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    col4Header:SetPoint("TOPLEFT", infoPanel, "TOPLEFT", 680, -8)
    col4Header:SetFont(cachedFontPath, 14, "OUTLINE")
    col4Header:SetText("|cFFFFD700" .. RaidMount.L("DESCRIPTION") .. "|r")
    col4Header:SetTextColor(1, 0.84, 0, 1)
    infoPanel.col4Header = col4Header

    local description = infoPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    description:SetPoint("TOPLEFT", col4Header, "BOTTOMLEFT", 0, 2)
    description:SetPoint("TOPRIGHT", infoPanel, "TOPRIGHT", -10, -18)
    description:SetFont(cachedFontPath, 14, "OUTLINE")
    description:SetJustifyH("LEFT")
    description:SetTextColor(0.9, 0.9, 0.9, 1)
    description:SetHeight(90)
    infoPanel.description = description
    
    return infoPanel
end

-- Helper function to get class color
local function GetClassColor(class)
    if not class then return "FFFFFF" end
    local upperClass = class:upper()
    return CLASS_COLORS[upperClass] or "FFFFFF"
end

-- Helper function to ensure class data is stored when tracking attempts
function RaidMount.StoreClassData(trackingKey, characterName)
    -- Don't wipe RaidMountAttempts - just ensure it exists
    if not RaidMountAttempts then
        RaidMountAttempts = {}
    end
    
    if not RaidMountAttempts[trackingKey] then
        RaidMountAttempts[trackingKey] = {
            characters = {},
            lastAttemptDates = {},
            classes = {}
        }
    end
    
    -- Store the current character's class
    local _, class = UnitClass("player")
    if class then
        RaidMountAttempts[trackingKey].classes = RaidMountAttempts[trackingKey].classes or {}
        RaidMountAttempts[trackingKey].classes[characterName] = class
    end
end

-- Add this helper near the top (after local variables):
local function GetMountIcon(data)
    local iconTexture = "Interface/Icons/INV_Misc_QuestionMark"
    if data.mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(data.mountID)
        if iconFile then
            iconTexture = iconFile
        else
            if data.spellID then
                local mountIDs = C_MountJournal.GetMountIDs()
                if mountIDs then
                    for _, mountID in ipairs(mountIDs) do
                        local name, spellID, icon = C_MountJournal.GetMountInfoByID(mountID)
                        if spellID == data.spellID and icon then
                            iconTexture = icon
                            break
                        end
                    end
                end
            end
        end
    end
    return iconTexture
end

-- Show info panel with mount data
function RaidMount.ShowInfoPanel(data)
    if not RaidMount.RaidMountFrame or not RaidMount.RaidMountFrame.infoPanel then return end
    
    local panel = RaidMount.RaidMountFrame.infoPanel
    panel:Show()
    
    -- Icon
    panel.icon:SetTexture(GetMountIcon(data))
    
    -- Use unified mount coloring system with quality-based colors
    local nameColor = RaidMount.GetMountNameColor(data)
    
    -- Truncate mount name if too long to prevent overflow
    local mountName = data.mountName or "Unknown Mount"
    if #mountName > 30 then
        mountName = mountName:sub(1, 27) .. "..."
    end
    panel.name:SetText(nameColor .. mountName .. "|r")
    
    -- Status icon and text
    if data.collected then
        panel.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        panel.statusText:SetText("|cFF00FF00" .. RaidMount.L("COLLECTED") .. "|r")
    else
        panel.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        panel.statusText:SetText("|cFFFF6666" .. RaidMount.L("NOT_COLLECTED") .. "|r")
    end
    
    -- Column 1: Source Information - now with more space and no header
    local raidName = data.raidName or data.dungeonName or data.location or RaidMount.L("UNKNOWN")
    if #raidName > 22 then raidName = raidName:sub(1, 19) .. "..." end
    panel.source:SetText(RaidMount.L("RAID") .. ": |cFFFFFFFF" .. raidName .. "|r")
    
    local bossName = data.bossName or RaidMount.L("UNKNOWN")
    if #bossName > 22 then bossName = bossName:sub(1, 19) .. "..." end
    panel.boss:SetText(RaidMount.L("BOSS") .. ": |cFFDDA0DD" .. bossName .. "|r")
    
    local locationName = data.location or RaidMount.L("UNKNOWN")
    if #locationName > 22 then locationName = locationName:sub(1, 19) .. "..." end
    panel.location:SetText(RaidMount.L("ZONE") .. ": |cFF87CEEB" .. locationName .. "|r")
    
    -- Column 2: Attempt Tracking - now with much more space for alts
    local attempts = tonumber(data.attempts) or 0
    local attemptsColor = attempts > 0 and "|cFFFFD700" or "|cFFCCCCCC"
    panel.totalAttempts:SetText(RaidMount.L("TOTAL_ATTEMPTS") .. ": " .. attemptsColor .. attempts .. "|r")
    
    -- Character attempts breakdown - now with 4 lines for more alts
    panel.charAttempts1:SetText("")
    panel.charAttempts2:SetText("")
    panel.charAttempts3:SetText("")
    panel.charAttempts4:SetText("")
    
    local trackingKey = data.spellID or data.mountID
    local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
    
    -- Use character-specific data structure instead of global data
    local currentCharacter = UnitFullName("player")
    local characterAttempts = {}
    local seenCharacters = {} -- Track normalized character names to prevent duplicates
    
    -- First, try to get character-specific data (preferred method)
    if currentCharacter and RaidMountAttempts[currentCharacter] and RaidMountAttempts[currentCharacter].attempts then
        local charAttempts = RaidMountAttempts[currentCharacter].attempts[trackingKey]
        if charAttempts and charAttempts.count and charAttempts.count > 0 then
            local shortName = currentCharacter:match("([^%-]+)") or currentCharacter
            if #shortName > 12 then shortName = shortName:sub(1, 12) end
            
            local lastAttemptDate = "Never"
            if charAttempts.lastAttempt then
                lastAttemptDate = date("%d/%m/%y", charAttempts.lastAttempt)
            end
            
            -- Get class and color the name
            local class = nil
            if charAttempts.class then
                class = charAttempts.class
            end
            
            local color = GetClassColor(class)
            local coloredName = "|cFF" .. color .. shortName .. "|r"
            
            table.insert(characterAttempts, {
                name = coloredName,
                count = charAttempts.count,
                lastAttempt = lastAttemptDate,
                normalizedName = currentCharacter
            })
        end
    end
    
    -- Fallback to global data structure for other characters (legacy support)
    if attemptData and type(attemptData) == "table" and attemptData.characters then
        for charName, charData in pairs(attemptData.characters) do
            -- Skip current character as we already handled it above
            if charName ~= currentCharacter then
                local count = 0
                if type(charData) == "number" then
                    -- Old format migration
                    count = charData
                elseif type(charData) == "table" and charData.count then
                    -- New format
                    count = charData.count
                end
                
                -- Only show characters who have actually attempted this mount
                if count > 0 then
                    -- Normalize character name to prevent duplicates
                    local charNameOnly = charName:match("([^%-]+)") or charName
                    local realmName = charName:match("^[^%-]+%-([^%-]+)$") or "Unknown"
                    local normalizedName = RaidMount.NormalizeCharacterID and RaidMount.NormalizeCharacterID(charNameOnly, realmName) or charNameOnly
                    
                    -- Skip if we've already seen this character
                    if seenCharacters[normalizedName] then
                        -- Merge attempts if duplicate found
                        for _, existing in ipairs(characterAttempts) do
                            if existing.normalizedName == normalizedName then
                                existing.count = existing.count + count
                                -- Use the most recent date
                                local currentDate = attemptData.lastAttemptDates and attemptData.lastAttemptDates[charName] or "Never"
                                if currentDate ~= "Never" and (existing.lastAttempt == "Never" or currentDate > existing.lastAttempt) then
                                    existing.lastAttempt = currentDate
                                end
                                break
                            end
                        end
                    else
                        seenCharacters[normalizedName] = true
                        
                        local shortName = charNameOnly
                        if #shortName > 12 then shortName = shortName:sub(1, 12) end
                        
                        local lastAttemptDate = "Never"
                        if attemptData.lastAttemptDates and attemptData.lastAttemptDates[charName] then
                            lastAttemptDate = attemptData.lastAttemptDates[charName]
                        end
                        
                        -- Get class and color the name
                        local class = nil
                        if attemptData.classes and attemptData.classes[charName] then
                            class = attemptData.classes[charName]
                        end
                        
                        local color = GetClassColor(class)
                        local coloredName = "|cFF" .. color .. shortName .. "|r"
                        
                        table.insert(characterAttempts, {
                            name = coloredName,
                            count = count,
                            lastAttempt = lastAttemptDate,
                            normalizedName = normalizedName
                        })
                    end
                end
            end
        end
        

        
        -- Clean up any incorrect date entries for characters who haven't attempted
        if attemptData.lastAttemptDates then
            for charName, attemptDate in pairs(attemptData.lastAttemptDates) do
                local charData = attemptData.characters[charName]
                local count = 0
                if type(charData) == "number" then
                    count = charData
                elseif type(charData) == "table" and charData.count then
                    count = charData.count
                end
                
                -- Remove date entry if character has no attempts
                if count == 0 then
                    attemptData.lastAttemptDates[charName] = nil
                end
            end
        end
        
        if #characterAttempts > 0 then
            table.sort(characterAttempts, function(a, b) return a.count > b.count end)
            
            -- Debug: Print what we're about to display
    
            
            
                    -- Display up to 4 characters now
        if characterAttempts[1] then
            local text1 = characterAttempts[1].name .. ": " .. characterAttempts[1].count .. " attempts (" .. characterAttempts[1].lastAttempt .. ")"
            panel.charAttempts1:SetText(text1)
        end
        if characterAttempts[2] then
            local text2 = characterAttempts[2].name .. ": " .. characterAttempts[2].count .. " attempts (" .. characterAttempts[2].lastAttempt .. ")"
            panel.charAttempts2:SetText(text2)
        end
        if characterAttempts[3] then
            local text3 = characterAttempts[3].name .. ": " .. characterAttempts[3].count .. " attempts (" .. characterAttempts[3].lastAttempt .. ")"
            panel.charAttempts3:SetText(text3)
        end
        if characterAttempts[4] then
            local text4 = characterAttempts[4].name .. ": " .. characterAttempts[4].count .. " attempts (" .. characterAttempts[4].lastAttempt .. ")"
            panel.charAttempts4:SetText(text4)
        elseif #characterAttempts > 4 then
            local textMore = "|cFF999999+" .. (#characterAttempts - 3) .. RaidMount.L("MORE_CHARACTERS") .. "|r"
            panel.charAttempts4:SetText(textMore)
        end
        end
    end
    
    -- Column 3: Status & Lockout - now with lockout timer
    local isLockedOut = false
    local lockoutTimerText = "Available now"
    


    -- Get current lockout information using the new function
    if data.raidName then
        if data.DifficultyIDs and #data.DifficultyIDs > 0 then
            -- For mounts with multiple difficulties, check all relevant lockouts
            local allLockoutInfo = {}
            local anyLockedOut = false
            
            -- Check if this mount has shared difficulties
            local hasSharedDifficulties = data.SharedDifficulties and next(data.SharedDifficulties) ~= nil
            
            for _, diffID in ipairs(data.DifficultyIDs) do
                local difficultyName = nil
                if diffID == 17 then difficultyName = "LFR"
                elseif diffID == 14 then difficultyName = "Normal"
                elseif diffID == 15 then difficultyName = "Heroic"
                elseif diffID == 16 then difficultyName = "Mythic"
                elseif diffID == 3 then 
                    difficultyName = hasSharedDifficulties and "10/25" or "10 Player"
                elseif diffID == 4 then 
                    difficultyName = hasSharedDifficulties and "10/25" or "25 Player"
                elseif diffID == 5 then 
                    difficultyName = hasSharedDifficulties and "10/25H" or "10 Player (Heroic)"
                elseif diffID == 6 then 
                    difficultyName = hasSharedDifficulties and "10/25H" or "25 Player (Heroic)"
                end
                
                if difficultyName then
                    local lockoutTime, canEnter = RaidMount.GetDifficultyLockoutStatus(data.raidName, diffID, data.expansion)
                    table.insert(allLockoutInfo, {
                        difficulty = difficultyName,
                        canEnter = canEnter,
                        lockoutTime = lockoutTime
                    })
                    
                    if not canEnter then
                        anyLockedOut = true
                    end
                end
            end
            
            -- Display lockout information for all difficulties
            if #allLockoutInfo > 0 then
                local lockoutText = ""
                local seenDifficulties = {} -- Track difficulties to avoid duplicates for shared lockouts
                local lineCount = 0
                
                for i, lockoutInfo in ipairs(allLockoutInfo) do
                    -- Skip duplicate entries for shared difficulties
                    if hasSharedDifficulties and (lockoutInfo.difficulty == "10/25" or lockoutInfo.difficulty == "10/25H") then
                        if seenDifficulties[lockoutInfo.difficulty] then
                            -- Skip this entry
                        else
                            seenDifficulties[lockoutInfo.difficulty] = true
                            
                            local statusColor = lockoutInfo.canEnter and "|cFF00FF00" or "|cFFFF0000"
                            local statusText = lockoutInfo.canEnter and "Available" or "Locked"
                            local timeText = lockoutInfo.lockoutTime ~= "No lockout" and " (" .. lockoutInfo.lockoutTime .. ")" or ""
                            
                            if lineCount > 0 then lockoutText = lockoutText .. "\n" end
                            lockoutText = lockoutText .. "  " .. lockoutInfo.difficulty .. ": " .. statusColor .. statusText .. timeText .. "|r"
                            lineCount = lineCount + 1
                        end
                    else
                        local statusColor = lockoutInfo.canEnter and "|cFF00FF00" or "|cFFFF0000"
                        local statusText = lockoutInfo.canEnter and "Available" or "Locked"
                        local timeText = lockoutInfo.lockoutTime ~= "No lockout" and " (" .. lockoutInfo.lockoutTime .. ")" or ""
                        
                        if lineCount > 0 then lockoutText = lockoutText .. "\n" end
                        lockoutText = lockoutText .. "  " .. lockoutInfo.difficulty .. ": " .. statusColor .. statusText .. timeText .. "|r"
                        lineCount = lineCount + 1
                    end
                end
                
                -- Just show the individual difficulty statuses, no redundant summary
                panel.lockoutStatus:SetText("")
                panel.lockoutTimer:SetText(lockoutText)
            else
                -- Fallback if no lockout info
                panel.lockoutStatus:SetText("")
                panel.lockoutTimer:SetText(RaidMount.L("NEXT_ATTEMPT") .. ": |cFF00FF00" .. RaidMount.L("AVAILABLE_NOW") .. "|r")
            end
        else
            -- Single difficulty mount - use the basic lockout check
            local currentLockout = RaidMount.GetRaidLockout(data.raidName)
            if currentLockout and currentLockout ~= "No lockout" then
                panel.lockoutStatus:SetText("")
                panel.lockoutTimer:SetText(RaidMount.L("NEXT_ATTEMPT") .. ": |cFFFF6666" .. currentLockout .. "|r")
            else
                panel.lockoutStatus:SetText("")
                panel.lockoutTimer:SetText(RaidMount.L("NEXT_ATTEMPT") .. ": |cFF00FF00" .. RaidMount.L("AVAILABLE_NOW") .. "|r")
            end
        end
    else
        -- No raid name - fallback to addon tracking
        local trackingKey = data.spellID or data.mountID
        local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
        local currentCharacter = RaidMount.GetCurrentCharacterID()
        if attemptData and attemptData.lastAttemptDates and attemptData.lastAttemptDates[currentCharacter] then
            local lastAttemptDate = attemptData.lastAttemptDates[currentCharacter]
            -- Parse the date (assuming format is dd/mm/yy)
            if lastAttemptDate and lastAttemptDate ~= "Never" then
                local day, month, year = lastAttemptDate:match("(%d+)/(%d+)/(%d+)")
                if day and month and year then
                    year = tonumber(year)
                    if year < 50 then year = year + 2000 else year = year + 1900 end
                    local lastAttemptTime = time({year = year, month = tonumber(month), day = tonumber(day), hour = 0, min = 0, sec = 0})
                    local currentTime = time()
                    local currentDate = date("*t", currentTime)
                    local daysUntilTuesday = (3 - currentDate.wday + 7) % 7
                    if daysUntilTuesday == 0 and currentDate.hour < 9 then daysUntilTuesday = 0 elseif daysUntilTuesday == 0 then daysUntilTuesday = 7 end
                    local nextResetTime = time({year = currentDate.year, month = currentDate.month, day = currentDate.day + daysUntilTuesday, hour = 9, min = 0, sec = 0})
                    local lastResetTime = nextResetTime - (7 * 24 * 60 * 60)
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
                            local lockoutColor = "|cFFFF6666" -- Red for locked out
                            isLockedOut = true
                        end
                    end
                end
            end
        end
        
        if isLockedOut then
            panel.lockoutStatus:SetText("")
            panel.lockoutTimer:SetText(RaidMount.L("NEXT_ATTEMPT") .. ": " .. lockoutColor .. lockoutTimerText .. "|r")
        else
            panel.lockoutStatus:SetText("")
            panel.lockoutTimer:SetText(RaidMount.L("NEXT_ATTEMPT") .. ": |cFF00FF00" .. RaidMount.L("AVAILABLE_NOW") .. "|r")
        end
    end
    

    
    if data.collected then
        local collectionText = data.collectionDate or "Unknown Date"
        if #collectionText > 18 then collectionText = collectionText:sub(1, 15) .. "..." end
        panel.collectionDate:SetText(RaidMount.L("COLLECTED_ON") .. " |cFF00FF00" .. collectionText .. "|r")
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
        panel.description:SetText(RaidMount.L("NO_DESCRIPTION"))
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