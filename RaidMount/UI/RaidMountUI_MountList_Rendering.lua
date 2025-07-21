-- Mount List Rendering module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
-- cachedFontPath is handled by Utils.lua

-- Row creation and management
local function GetRowFromPool(parent)
    local row = table.remove(RaidMount.rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(RaidMount.rowHeight)

        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()

        row.texts = {}
        for i = 1, 8 do -- Reduced from 10 to 8 for performance
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetFont(RaidMount.cachedFontPath, 13, "OUTLINE")
            row.texts[i] = text
        end

        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.data and RaidMountTooltipEnabled then
                if RaidMount.ShowTooltip then
                    -- Get current lockout status for this mount's raid
                    local currentLockoutStatus = "Unknown"
                    if self.data and self.data.raidName then
                        currentLockoutStatus = RaidMount.GetRaidLockout(self.data.raidName)
                    end
                    RaidMount.ShowTooltip(self, self.data, currentLockoutStatus)
                end
            end
            self.bg:SetColorTexture(unpack(COLORS.primaryDark or { 0.2, 0.2, 0.2, 1 }))

            if self.data and RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                if RaidMount.ShowInfoPanel then
                    RaidMount.ShowInfoPanel(self.data)
                end
            end
        end)

        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.originalRowColor then
                self.bg:SetColorTexture(unpack(self.originalRowColor))
            end
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                RaidMount.RaidMountFrame.infoPanel:Hide()
            end
        end)
    end

    -- Ensure event handlers are set (safety check for pooled rows)
    if not row:GetScript("OnEnter") then
        row:SetScript("OnEnter", function(self)
            if self.data and RaidMountTooltipEnabled then
                if RaidMount.ShowTooltip then
                    -- Get current lockout status for this mount's raid
                    local currentLockoutStatus = "Unknown"
                    if self.data and self.data.raidName then
                        currentLockoutStatus = RaidMount.GetRaidLockout(self.data.raidName)
                    end
                    RaidMount.ShowTooltip(self, self.data, currentLockoutStatus)
                end
            end
            self.bg:SetColorTexture(unpack(COLORS.primaryDark or { 0.2, 0.2, 0.2, 1 }))

            if self.data and RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                if RaidMount.ShowInfoPanel then
                    RaidMount.ShowInfoPanel(self.data)
                end
            end
        end)
    end

    if not row:GetScript("OnLeave") then
        row:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            if self.originalRowColor then
                self.bg:SetColorTexture(unpack(self.originalRowColor))
            end
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                RaidMount.RaidMountFrame.infoPanel:Hide()
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
        row.originalRowColor = nil

        -- Properly clean up difficulty buttons
        if row.difficultyButtons then
            for _, button in pairs(row.difficultyButtons) do
                button:Hide()
                button:ClearAllPoints()
                if button.ButtonTint then
                    button.ButtonTint:Hide()
                end
                -- Clear scripts to prevent memory leaks
                button:SetScript("OnEnter", nil)
                button:SetScript("OnLeave", nil)
                button:SetScript("OnClick", nil)
            end
        end

        -- Hide difficulty container if it exists
        if row.difficultyContainer then
            row.difficultyContainer:Hide()
        end

        -- Clear all textures and references
        if row.icon then
            row.icon:SetTexture(nil)
        end
        if row.statusIcon then
            row.statusIcon:SetTexture(nil)
        end
        if row.lockoutIcon then
            row.lockoutIcon:SetTexture(nil)
        end

        -- Clear text content
        for i = 1, #row.texts do
            row.texts[i]:SetText("")
        end

        -- Don't clear the main row event handlers - they need to persist for reuse
        -- Only clear child element handlers that were set above

        table.insert(RaidMount.rowPool, row)
    end
end

-- Row content update
function RaidMount.UpdateRowContent(row, data)
    if not row or not data then return end



    row.data = data

    local rowColor = { 0.05, 0.05, 0.1, 0.3 }
    row.bg:SetColorTexture(unpack(rowColor))
    row.originalRowColor = rowColor

    for i = 1, #row.texts do
        row.texts[i]:SetText("")
        row.texts[i]:ClearAllPoints()
    end

    local columns = {
        { pos = 10,  width = 30 },  -- Icon
        { pos = 50,  width = 180 }, -- Mount Name
        { pos = 240, width = 130 }, -- Raid/Source
        { pos = 380, width = 100 }, -- Boss
        { pos = 490, width = 70 },  -- Drop Rate
        { pos = 570, width = 90 },  -- Expansion
        { pos = 670, width = 50 },  -- Attempts
        { pos = 730, width = 50 },  -- Status
        { pos = 790, width = 120 }, -- Lockout
        { pos = 920, width = 60 },  -- Coordinates
    }

    -- Icon (using texture instead of text)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "OVERLAY")
        row.icon:SetSize(20, 20)
    end
    row.icon:SetPoint("LEFT", row, "LEFT", columns[1].pos, 0)

    local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"

    -- Get mount IDs from data (note: source data uses MountID with capital letters)
    local mountID = data.mountID -- From formatted data
    local spellID = data.spellID -- From formatted data

    -- Use the same icon loading logic as the info panel
    if mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(mountID)
        if iconFile then
            iconTexture = iconFile
        else
            if spellID then
                local mountIDs = C_MountJournal.GetMountIDs()
                if mountIDs then
                    for _, id in ipairs(mountIDs) do
                        local name, mountSpellID, icon = C_MountJournal.GetMountInfoByID(id)
                        if mountSpellID == spellID and icon then
                            iconTexture = icon
                            break
                        end
                    end
                end
            end
        end
    end
    row.icon:SetTexture(iconTexture)

    -- Use unified mount coloring system with quality-based colors
    local nameColor = RaidMount.GetMountNameColor and RaidMount.GetMountNameColor(data) or "|cFFFFFFFF"
    
    row.texts[1]:SetPoint("LEFT", row, "LEFT", columns[2].pos, 0)
    row.texts[1]:SetText(nameColor .. (data.mountName or "Unknown") .. "|r")
    row.texts[1]:SetWidth(columns[2].width)
    row.texts[1]:SetJustifyH("LEFT")

    -- Raid/Source
    row.texts[2]:SetPoint("LEFT", row, "LEFT", columns[3].pos, 0)
    row.texts[2]:SetText(data.raidName or data.location or "Unknown")
    row.texts[2]:SetWidth(columns[3].width)
    row.texts[2]:SetJustifyH("LEFT")
    row.texts[2]:SetTextColor(1, 0.82, 0, 1) -- Gold color

    -- Boss
    row.texts[3]:SetPoint("LEFT", row, "LEFT", columns[4].pos, 0)
    row.texts[3]:SetText(data.bossName or "Unknown")
    row.texts[3]:SetWidth(columns[4].width)
    row.texts[3]:SetJustifyH("LEFT")
    row.texts[3]:SetTextColor(0.8, 0.8, 0.8, 1) -- Light gray

    -- Drop Rate
    row.texts[4]:SetPoint("LEFT", row, "LEFT", columns[5].pos, 0)
    row.texts[4]:SetText(data.dropRate or "~1%")
    row.texts[4]:SetWidth(columns[5].width)
    row.texts[4]:SetJustifyH("CENTER")
    row.texts[4]:SetTextColor(1, 1, 0, 1) -- Yellow

    -- Expansion
    row.texts[5]:SetPoint("LEFT", row, "LEFT", columns[6].pos, 0)
    row.texts[5]:SetText(data.expansion or "Unknown")
    row.texts[5]:SetWidth(columns[6].width)
    row.texts[5]:SetJustifyH("LEFT")
    row.texts[5]:SetTextColor(0.6, 0.8, 1, 1) -- Light blue

    -- Attempts
    row.texts[6]:SetPoint("LEFT", row, "LEFT", columns[7].pos, 0)
    local attempts = data.attempts or 0
    local attemptsColor = attempts > 0 and "|cFFFFFF00" or "|cFFFFFFFF"
    row.texts[6]:SetText(attemptsColor .. attempts .. "|r")
    row.texts[6]:SetWidth(columns[7].width)
    row.texts[6]:SetJustifyH("CENTER")

    if not row.statusIcon then
        row.statusIcon = row:CreateTexture(nil, "OVERLAY")
        row.statusIcon:SetSize(18, 18)
    end
    row.statusIcon:SetPoint("CENTER", row, "LEFT", columns[8].pos + (columns[8].width / 2), 0)

    if data.collected then
        row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        row.statusIcon:Show()
    else
        row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        row.statusIcon:Show()
    end

    row.texts[7]:SetText("")

    if not row.lockoutIcon then
        row.lockoutIcon = row:CreateTexture(nil, "OVERLAY")
        row.lockoutIcon:SetSize(14, 14)
    end

    local hasLockout, difficultyIDs, sharedDifficulties, contentType = RaidMount.GetLockoutInfo(data)

    -- Clear any existing difficulty buttons
    if row.difficultyButtons then
        for _, button in pairs(row.difficultyButtons) do
            button:Hide()
        end
    end

    if hasLockout and difficultyIDs and type(difficultyIDs) == "table" then
        -- Show simplified difficulty buttons (performance optimized)
        row.lockoutIcon:Hide()
        row.texts[8]:SetText("")

        -- Create difficulty container if it doesn't exist
        if not row.difficultyContainer then
            row.difficultyContainer = CreateFrame("Frame", nil, row)
            row.difficultyContainer:SetSize(80, 20)
            row.difficultyContainer:SetPoint("LEFT", row, "LEFT", columns[9].pos, 0)
            row.difficultyContainer:SetPoint("RIGHT", row, "LEFT", columns[9].pos + columns[9].width, 0)
        end
        row.difficultyContainer:Show()

        -- Create simplified difficulty buttons (max 3 for performance)
        if not row.difficultyButtons then
            row.difficultyButtons = {}
        end

        -- Check if this mount has shared difficulties and should show combined text
        local hasSharedDifficulties = sharedDifficulties and next(sharedDifficulties) ~= nil
        local shouldShowCombined = hasSharedDifficulties and contentType == "Raid"
        
        -- Determine how many buttons to show and their text
        local buttonTexts = {}
        local buttonCount = 0
        
        if shouldShowCombined then
            -- Show combined text for shared lockouts
            buttonTexts = { "10/25" }
            buttonCount = 1
        else
            -- Show individual difficulty buttons
            buttonCount = math.min(4, #difficultyIDs)
            for i = 1, buttonCount do
                local diffID = difficultyIDs[i]
                local btnText = "?"
                if contentType == "World" then
                    btnText = "W"
                elseif contentType == "Holiday" then
                    btnText = "H"
                else
                    btnText = RaidMount.GetDifficultyButtonText and RaidMount.GetDifficultyButtonText(diffID, contentType, data) or "N"
                end
                buttonTexts[i] = btnText
            end
        end
        
        -- Calculate total width of all buttons and spacing
        local buttonWidth = 32 -- Increased width to fit larger font
        local buttonSpacing = 34 -- Increased spacing for better visual separation
        local totalWidth = (buttonCount - 1) * buttonSpacing + buttonWidth
        
        for i = 1, buttonCount do
            if not row.difficultyButtons[i] then
                local button = CreateFrame("Button", nil, row.difficultyContainer)
                button:SetSize(32, 22) -- Increased size to fit larger font
                
                -- Create background texture for clean green button look
                local bg = button:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints()
                bg:SetColorTexture(0.3, 0.7, 0.3, 0.9) -- Lighter green background
                button.bg = bg
                
                -- Create border texture
                local border = button:CreateTexture(nil, "BORDER")
                border:SetAllPoints()
                border:SetColorTexture(0.2, 0.5, 0.2, 1) -- Lighter green border
                button.border = border
                
                local text = button:CreateFontString(nil, "OVERLAY")
                text:SetPoint("CENTER")
                text:SetFont(RaidMount.cachedFontPath, 11, "OUTLINE") -- Larger font for better readability
                text:SetTextColor(1, 1, 1, 1) -- White text
                button.text = text
                
                row.difficultyButtons[i] = button
            end

            local button = row.difficultyButtons[i]
            button:ClearAllPoints()
            
            -- Center the button group in the container
            local containerWidth = row.difficultyContainer:GetWidth()
            local startX = (containerWidth - totalWidth) / 2
            button:SetPoint("LEFT", row.difficultyContainer, "LEFT", startX + (i-1) * buttonSpacing, 0)
            button:Show()

            -- Set button text
            button.text:SetText(buttonTexts[i])
            
            -- Color coding with clean styling
            local isAvailable = true
            if data.raidName and RaidMount.GetEffectiveLockoutStatus then
                if shouldShowCombined then
                    -- For combined buttons, check the primary difficulty (usually the first one)
                    local primaryDiffID = difficultyIDs[1]
                    isAvailable = RaidMount.GetEffectiveLockoutStatus(data.raidName, primaryDiffID, sharedDifficulties)
                else
                    -- For individual buttons, check the specific difficulty
                    local diffID = difficultyIDs[i]
                    isAvailable = RaidMount.GetEffectiveLockoutStatus(data.raidName, diffID, sharedDifficulties)
                end
            end
            
            if isAvailable then
                -- Available: Clean lighter green button
                button.bg:SetColorTexture(0.3, 0.7, 0.3, 0.9)
                button.border:SetColorTexture(0.2, 0.5, 0.2, 1)
                button.text:SetTextColor(1, 1, 1, 1) -- White text
            else
                -- Locked: Cheerful red button
                button.bg:SetColorTexture(0.8, 0.2, 0.2, 0.9)
                button.border:SetColorTexture(0.6, 0.1, 0.1, 1)
                button.text:SetTextColor(1, 1, 1, 1) -- White text
            end
            
            -- Add click functionality to change raid/dungeon difficulty
            button:SetScript("OnClick", function(self)
                local diffID = shouldShowCombined and difficultyIDs[1] or difficultyIDs[i]
                if diffID then
                    -- Map difficulty IDs to WoW's difficulty system
                    local DungeonDifficulty = { Normal = 1, Heroic = 2, Mythic = 23 }
                    local RaidDifficulty = { Legacy10 = 3, Legacy25 = 4, Legacy10H = 5, Legacy25H = 6, LFR = 17, Normal = 14, Heroic = 15, Mythic = 16 }
                    
                    local difficultyKey
                    for key, dd in pairs(DungeonDifficulty) do
                        if dd == diffID then
                            difficultyKey = key; break
                        end
                    end
                    
                    if not difficultyKey then
                        for key, rd in pairs(RaidDifficulty) do
                            if rd == diffID then
                                difficultyKey = key; break
                            end
                        end
                    end
                    
                    if difficultyKey then
                        -- Use the correct WoW API functions
                        if contentType == "Dungeon" then
                            if difficultyKey == "Normal" then
                                SetDungeonDifficultyID(1)
                            elseif difficultyKey == "Heroic" then
                                SetDungeonDifficultyID(2)
                            elseif difficultyKey == "Mythic" then
                                SetDungeonDifficultyID(23)
                            end
                        elseif contentType == "Raid" then
                            if difficultyKey == "LFR" then
                                SetRaidDifficultyID(17)
                            elseif difficultyKey == "Normal" then
                                SetRaidDifficultyID(14)
                            elseif difficultyKey == "Heroic" then
                                SetRaidDifficultyID(15)
                            elseif difficultyKey == "Mythic" then
                                SetRaidDifficultyID(16)
                            elseif difficultyKey == "Legacy10" then
                                SetRaidDifficultyID(3)
                            elseif difficultyKey == "Legacy25" then
                                SetRaidDifficultyID(4)
                            elseif difficultyKey == "Legacy10H" then
                                SetRaidDifficultyID(5)
                            elseif difficultyKey == "Legacy25H" then
                                SetRaidDifficultyID(6)
                            end
                        end
                        
                        -- Show confirmation message
                        local difficultyName = buttonTexts[i]
                        local instanceName = data.raidName or data.instanceName or "Unknown Instance"
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFF33CCFFRaidMount:|r " .. RaidMount.L("DIFFICULTY_SET", instanceName, difficultyName)))
                    end
                end
            end)
        end

        -- Hide unused buttons
        for i = buttonCount + 1, #row.difficultyButtons do
            if row.difficultyButtons[i] then
                row.difficultyButtons[i]:Hide()
            end
        end

        -- Hide the text column since we're using buttons
        row.texts[8]:SetText("")
    elseif hasLockout and type(difficultyIDs) == "string" then
        -- This is the original lockout time string
        row.lockoutIcon:Hide()

        row.texts[8]:SetPoint("LEFT", row, "LEFT", columns[9].pos, 0)
        row.texts[8]:SetText("|cFFFF8000" .. difficultyIDs .. "|r")
        row.texts[8]:SetWidth(columns[9].width)
        row.texts[8]:SetJustifyH("CENTER")
        row.texts[8]:SetTextColor(1, 0.5, 0, 1)

        -- Hide difficulty container if it exists
        if row.difficultyContainer then
            row.difficultyContainer:Hide()
        end
    else
        -- No lockout or difficulty info
        row.lockoutIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        row.lockoutIcon:SetPoint("LEFT", row, "LEFT", columns[9].pos + (columns[9].width / 2) - 8, 0)
        row.lockoutIcon:Show()

        row.texts[8]:SetText("")

        -- Hide difficulty container if it exists
        if row.difficultyContainer then
            row.difficultyContainer:Hide()
        end
    end

    -- Map button functionality
    if RaidMount.CreateMapButton then
        RaidMount.CreateMapButton(row, data, columns)
    end
end

-- Scroll frame update functions
local function UpdateVisibleRows()
    if not RaidMount.ScrollFrame or not RaidMount.ScrollFrame.scrollChild then return end

    local scrollChild = RaidMount.ScrollFrame.scrollChild
    local scrollTop = RaidMount.ScrollFrame:GetVerticalScroll()
    local frameHeight = RaidMount.ScrollFrame:GetHeight()

    local startRow = math.max(1, math.floor(scrollTop / RaidMount.rowHeight) + 1)
    local endRow = math.min(RaidMount.totalRows, startRow + math.ceil(frameHeight / RaidMount.rowHeight) + 1)

    RaidMount.PreloadUpcomingTextures(startRow, endRow)

    for _, row in pairs(RaidMount.visibleRows) do
        ReturnRowToPool(row)
    end
    wipe(RaidMount.visibleRows)

    for i = startRow, endRow do
        if RaidMount.filteredData[i] then
            local row = GetRowFromPool(scrollChild)
            row.data = RaidMount.filteredData[i]

            -- Position the row
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * RaidMount.rowHeight)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * RaidMount.rowHeight)

            -- Update row content
            RaidMount.UpdateRowContent(row, RaidMount.filteredData[i])

            RaidMount.visibleRows[i] = row
        end
    end
end

local function UpdateVisibleRowsOptimized()
    if not RaidMount.ScrollFrame or not RaidMount.ScrollFrame.scrollChild then return end

    local scrollChild = RaidMount.ScrollFrame.scrollChild
    local scrollTop = RaidMount.ScrollFrame:GetVerticalScroll()
    local frameHeight = RaidMount.ScrollFrame:GetHeight()

    local startRow = math.max(1, math.floor(scrollTop / RaidMount.rowHeight) + 1)
    local endRow = math.min(RaidMount.totalRows, startRow + math.ceil(frameHeight / RaidMount.rowHeight) + 1)

    RaidMount.PreloadUpcomingTextures(startRow, endRow)

    local newVisibleRows = {}
    local rowsToReuse = {}

    for i = startRow, endRow do
        if RaidMount.filteredData[i] then
            local existingRow = RaidMount.visibleRows[i]
            if existingRow then
                rowsToReuse[i] = existingRow
                newVisibleRows[i] = existingRow
            end
        end
    end

    for rowIndex, row in pairs(RaidMount.visibleRows) do
        if not rowsToReuse[rowIndex] then
            ReturnRowToPool(row)
        end
    end

    for i = startRow, endRow do
        if RaidMount.filteredData[i] and not newVisibleRows[i] then
            local row = GetRowFromPool(scrollChild)
            row.data = RaidMount.filteredData[i]

            -- Position the row
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * RaidMount.rowHeight)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * RaidMount.rowHeight)

            -- Update row content
            RaidMount.UpdateRowContent(row, RaidMount.filteredData[i])

            newVisibleRows[i] = row
        end
    end

    for i = startRow, endRow do
        if RaidMount.filteredData[i] and rowsToReuse[i] then
            local row = rowsToReuse[i]
            row.data = RaidMount.filteredData[i]
            RaidMount.UpdateRowContent(row, RaidMount.filteredData[i])
        end
    end

    wipe(RaidMount.visibleRows)
    for k, v in pairs(newVisibleRows) do
        RaidMount.visibleRows[k] = v
    end
end

local function UpdateScrollChildHeight()
    if RaidMount.ScrollFrame and RaidMount.ScrollFrame.scrollChild then
        local totalHeight = RaidMount.totalRows * RaidMount.rowHeight
        RaidMount.ScrollFrame.scrollChild:SetHeight(totalHeight)
    end
end

-- Export rendering functions
RaidMount.GetRowFromPool = GetRowFromPool
RaidMount.ReturnRowToPool = ReturnRowToPool
RaidMount.UpdateVisibleRows = UpdateVisibleRows
RaidMount.UpdateVisibleRowsOptimized = UpdateVisibleRowsOptimized
RaidMount.UpdateScrollChildHeight = UpdateScrollChildHeight 