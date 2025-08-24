-- Character Data Checker for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Character Data Checker Frame
local characterCheckerFrame = nil
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Create the character checker frame
local function CreateCharacterCheckerFrame()
    if characterCheckerFrame then return characterCheckerFrame end
    
    characterCheckerFrame = CreateFrame("Frame", "RaidMountCharacterChecker", UIParent, "BackdropTemplate")
    characterCheckerFrame:SetSize(400, 300)
    -- Position relative to main RaidMount frame if it exists, otherwise center
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
        characterCheckerFrame:SetPoint("LEFT", RaidMount.RaidMountFrame, "RIGHT", 10, 0)
    else
        characterCheckerFrame:SetPoint("CENTER")
    end
    characterCheckerFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    characterCheckerFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    characterCheckerFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    characterCheckerFrame:SetMovable(true)
    characterCheckerFrame:EnableMouse(true)
    characterCheckerFrame:RegisterForDrag("LeftButton")
    characterCheckerFrame:SetScript("OnDragStart", characterCheckerFrame.StartMoving)
    characterCheckerFrame:SetScript("OnDragStop", characterCheckerFrame.StopMovingOrSizing)
    characterCheckerFrame:Hide()
    
    -- Title
    local title = characterCheckerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", characterCheckerFrame, "TOP", 0, -15)
    title:SetFont(cachedFontPath, 24, "OUTLINE")
    title:SetText("|cFF33CCFFRaid|r and |cFF33CCFFDungeon|r |cFFFF0000Mount|r |cFFFFD700Tracker|r - Alt Data")
    characterCheckerFrame.title = title
    
    -- Close button
    local closeButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", characterCheckerFrame, "TOPRIGHT", -5, -5)
    closeButton:SetScript("OnClick", function() characterCheckerFrame:Hide() end)
    
    -- Add a subtitle for instructions
    local subtitle = characterCheckerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOP", characterCheckerFrame, "TOP", 0, -45)
    subtitle:SetFont(cachedFontPath, 12, "OUTLINE")
    subtitle:SetText("|cFF999999Alt mount attempt data|r")
    subtitle:SetTextColor(0.6, 0.6, 0.6, 1)
    
    -- Scroll frame for character list (adjusted to make room for buttons)
    local scrollFrame = CreateFrame("ScrollFrame", nil, characterCheckerFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", characterCheckerFrame, "TOPLEFT", 15, -70)
    scrollFrame:SetPoint("BOTTOMRIGHT", characterCheckerFrame, "BOTTOMRIGHT", -35, 50)
    
    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(350, 800)
    scrollFrame:SetScrollChild(scrollChild)
    
    characterCheckerFrame.scrollFrame = scrollFrame
    characterCheckerFrame.scrollChild = scrollChild
    
    -- Add buttons at the bottom
    local refreshButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelButtonTemplate")
    refreshButton:SetSize(80, 25)
    refreshButton:SetPoint("BOTTOMLEFT", characterCheckerFrame, "BOTTOMLEFT", 15, 10)
    refreshButton:SetText("Refresh")
    refreshButton:SetScript("OnClick", function()
        if RaidMount.RefreshCommand then
            RaidMount.RefreshCommand()
        else
            print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Refresh function not available.")
        end
    end)
    
    local verifyButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelButtonTemplate")
    verifyButton:SetSize(80, 25)
    verifyButton:SetPoint("LEFT", refreshButton, "RIGHT", 10, 0)
    verifyButton:SetText("Verify")
    verifyButton:SetScript("OnClick", function()
        if RaidMount.VerifyCommand then
            RaidMount.VerifyCommand()
        else
            print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Verify function not available.")
        end
    end)
    

    
    return characterCheckerFrame
end

-- Get character data status (HYBRID APPROACH)
local function GetCharacterDataStatus(characterID)
    if not RaidMountAttempts then return "No data" end
    
    local mountCount = 0
    local totalAttempts = 0
    
    -- HYBRID APPROACH: Check both character-specific and global data
    
    -- 1. Check character-specific data (preferred)
    local charData = RaidMountAttempts[characterID]
    if charData then
        -- Check character-specific attempts
        if charData.attempts then
            for spellID, attemptData in pairs(charData.attempts) do
                local count = 0
                if type(attemptData) == "number" then
                    count = attemptData
                elseif type(attemptData) == "table" and attemptData.count then
                    count = attemptData.count
                end
                
                if count > 0 then
                    mountCount = mountCount + 1
                    totalAttempts = totalAttempts + count
                end
            end
        end
        
        -- Check character-specific statistics
        if charData.statistics then
            for spellID, statData in pairs(charData.statistics) do
                if statData.attempts and statData.attempts > 0 then
                    mountCount = mountCount + 1
                    totalAttempts = totalAttempts + statData.attempts
                end
            end
        end
    end
    
    -- 2. Check global data (legacy compatibility) - also check for normalized IDs
    for trackingKey, attemptData in pairs(RaidMountAttempts) do
        if type(attemptData) == "table" and attemptData.characters then
            -- Check both the original characterID and normalized versions
            local charAttemptData = attemptData.characters[characterID]
            if not charAttemptData then
                -- Try to find by character name only (for normalized IDs)
                local charName = characterID:match("([^%-]+)")
                if charName then
                    for charID, data in pairs(attemptData.characters) do
                        if charID:match("^" .. charName) then
                            charAttemptData = data
                            break
                        end
                    end
                end
            end
            
            if charAttemptData then
                local count = 0
                
                if type(charAttemptData) == "number" then
                    count = charAttemptData
                elseif type(charAttemptData) == "table" and charAttemptData.count then
                    count = charAttemptData.count
                end
                
                if count > 0 then
                    mountCount = mountCount + 1
                    totalAttempts = totalAttempts + count
                end
            end
        end
    end
    
    if mountCount > 0 then
        return string.format("|cFF00FF00%d mounts, %d attempts|r", mountCount, totalAttempts)
    else
        return "|cFFFF0000No data|r"
    end
end

-- Get character class color
local function GetCharacterClassColor(characterID)
    if not RaidMountAttempts then return "FFFFFF" end
    
    local charData = RaidMountAttempts[characterID]
    if charData and charData.class then
        local colors = {
            ["WARRIOR"] = "C79C6E",
            ["PALADIN"] = "F58CBA",
            ["HUNTER"] = "ABD473",
            ["ROGUE"] = "FFF569",
            ["PRIEST"] = "FFFFFF",
            ["DEATHKNIGHT"] = "C41F3B",
            ["SHAMAN"] = "0070DE",
            ["MAGE"] = "69CCF0",
            ["WARLOCK"] = "9482C9",
            ["MONK"] = "00FF96",
            ["DRUID"] = "FF7D0A",
            ["DEMONHUNTER"] = "A330C9",
            ["EVOKER"] = "33937F"
        }
        return colors[charData.class] or "FFFFFF"
    end
    
    return "FFFFFF"
end

-- Update character checker display
function RaidMount.UpdateCharacterChecker()
    local frame = CreateCharacterCheckerFrame()
    local scrollChild = frame.scrollChild
    
    -- Clear existing content
    for i = 1, scrollChild:GetNumChildren() do
        local child = select(i, scrollChild:GetChildren())
        if child then
            child:Hide()
            child:SetParent(nil)
        end
    end
    
    -- Get all character IDs from saved data
    local characters = {}
    local normalizedCharacters = {} -- Track normalized names to merge duplicates
    
    -- Add characters from RaidMountAttempts (new structure)
    if RaidMountAttempts then
        for characterID, charData in pairs(RaidMountAttempts) do
            -- Only process character names (strings), not spell IDs (numbers)
            if type(characterID) == "string" and type(charData) == "table" then
                -- Check if this looks like a character name (contains a dash for realm)
                if characterID:find("-") then
                    local charName, realmName = characterID:match("([^%-]+)%-([^%-]+)")
                    local normalizedID = RaidMount.NormalizeCharacterID(charName, realmName)
                    
                    if normalizedID then
                        normalizedCharacters[normalizedID] = normalizedCharacters[normalizedID] or {}
                        table.insert(normalizedCharacters[normalizedID], {
                            originalID = characterID,
                            hasMountData = true,
                            lastSeen = charData.lastSeen,
                            level = charData.level,
                            class = charData.class
                        })
                    end
                end
            end
        end
    end
    
    -- Only add characters that have actually attempted mounts (from RaidMountSaved.loggedCharacters)
    if RaidMountSaved and RaidMountSaved.loggedCharacters then
        for characterID, charInfo in pairs(RaidMountSaved.loggedCharacters) do
            -- Check if this character has any mount attempts
            local hasAttempts = false
            if RaidMountAttempts then
                -- Check character-specific data
                local charData = RaidMountAttempts[characterID]
                if charData and charData.attempts then
                    for spellID, attemptData in pairs(charData.attempts) do
                        local count = 0
                        if type(attemptData) == "number" then
                            count = attemptData
                        elseif type(attemptData) == "table" and attemptData.count then
                            count = attemptData.count
                        end
                        if count > 0 then
                            hasAttempts = true
                            break
                        end
                    end
                end
                
                -- Check global data if no character-specific attempts found
                if not hasAttempts then
                    for trackingKey, attemptData in pairs(RaidMountAttempts) do
                        if type(attemptData) == "table" and attemptData.characters then
                            local charAttemptData = attemptData.characters[characterID]
                            if charAttemptData then
                                local count = 0
                                if type(charAttemptData) == "number" then
                                    count = charAttemptData
                                elseif type(charAttemptData) == "table" and charAttemptData.count then
                                    count = charAttemptData.count
                                end
                                if count > 0 then
                                    hasAttempts = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
            
            -- Only add characters who have actually attempted mounts
            if hasAttempts then
                local charName, realmName = characterID:match("([^%-]+)%-([^%-]+)")
                local normalizedID = RaidMount.NormalizeCharacterID(charName, realmName)
                
                if normalizedID then
                    normalizedCharacters[normalizedID] = normalizedCharacters[normalizedID] or {}
                    table.insert(normalizedCharacters[normalizedID], {
                        originalID = characterID,
                        hasMountData = false,
                        lastSeen = charInfo.lastLogin and date("%Y-%m-%d", charInfo.lastLogin) or "Unknown",
                        level = charInfo.level,
                        class = charInfo.class
                    })
                end
            end
        end
    end
    
    -- Merge duplicate entries and create final character list
    for normalizedID, entries in pairs(normalizedCharacters) do
        -- Use the entry with the most recent data or mount data
        local bestEntry = entries[1]
        for _, entry in ipairs(entries) do
            if entry.hasMountData and not bestEntry.hasMountData then
                bestEntry = entry
            elseif entry.lastSeen and (not bestEntry.lastSeen or entry.lastSeen > bestEntry.lastSeen) then
                bestEntry = entry
            end
        end
        
        characters[normalizedID] = {
            hasMountData = bestEntry.hasMountData,
            lastSeen = bestEntry.lastSeen,
            level = bestEntry.level,
            class = bestEntry.class
        }
    end
    
    -- Sort characters alphabetically (only strings)
    local sortedCharacters = {}
    for characterID in pairs(characters) do
        -- Only add string character IDs to avoid sorting errors
        if type(characterID) == "string" then
            table.insert(sortedCharacters, characterID)
        end
    end
    table.sort(sortedCharacters)
    
    -- Create character list
    local yOffset = 0
    for i, characterID in ipairs(sortedCharacters) do
        local shortName = characterID:match("([^%-]+)") or characterID
        local realmName = characterID:match("^[^%-]+%-([^%-]+)$") or "Unknown"
        local charInfo = characters[characterID]
        local status = GetCharacterDataStatus(characterID)
        local color = GetCharacterClassColor(characterID)
        
        -- Character name and realm
        local nameText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        nameText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, yOffset)
        nameText:SetFont(cachedFontPath, 14, "OUTLINE")
        nameText:SetText("|cFF" .. color .. shortName .. "|r - " .. realmName)
        nameText:SetJustifyH("LEFT")
        
        -- Status
        local statusText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        statusText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 180, yOffset)
        statusText:SetFont(cachedFontPath, 14, "OUTLINE")
        statusText:SetText(status)
        statusText:SetJustifyH("LEFT")
        
        -- Last seen info
        if charInfo.lastSeen then
            local lastSeenText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lastSeenText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 350, yOffset)
            lastSeenText:SetFont(cachedFontPath, 12, "OUTLINE")
            lastSeenText:SetTextColor(0.7, 0.7, 0.7, 1)
            lastSeenText:SetText("Last: " .. charInfo.lastSeen)
            lastSeenText:SetJustifyH("LEFT")
        end
        
        yOffset = yOffset - 25
    end
    
    if #sortedCharacters == 0 then
        local noDataText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noDataText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, 0)
        noDataText:SetFont(cachedFontPath, 14, "OUTLINE")
        noDataText:SetText("|cFF999999No alt data found. Use /rm refresh on each character.|r")
    end
    
    frame:Show()
end

-- Slash command handler
local function SlashCommandHandler(msg)
    if msg == "characters" or msg == "chars" or msg == "check" then
        RaidMount.UpdateCharacterChecker()
    else
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r Alt Checker:")
        print("  /rm characters - Show alt data status")
        print("  /rm chars - Same as above")
        print("  /rm check - Same as above")
    end
end

-- Register slash command
SLASH_RAIDMOUNT_CHARACTERS1 = "/rm"
SLASH_RAIDMOUNT_CHARACTERS2 = "/raidmount"
SlashCmdList["RAIDMOUNT_CHARACTERS"] = function(msg)
    if msg:match("^characters?") or msg:match("^chars?") or msg:match("^check") then
        SlashCommandHandler(msg)
    end
end 