-- Mount List module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

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

-- Helper function to get lockout info
local function GetLockoutInfo(data)
    if not data or not data.raidName then
        return false, nil
    end
    
    local lockoutTime = RaidMount.GetRaidLockout(data.raidName)
    if lockoutTime and lockoutTime ~= "No lockout" then
        return true, lockoutTime
    end
    
    return false, nil
end

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
            if self.data and RaidMountTooltipEnabled then
                if RaidMount.ShowTooltip then
                    RaidMount.ShowTooltip(self, self.data)
                end
            end
            self.bg:SetColorTexture(unpack(COLORS.primaryDark or {0.2, 0.2, 0.2, 1}))
            
            -- Show info panel
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
            -- Hide info panel
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                RaidMount.RaidMountFrame.infoPanel:Hide()
            end
        end)
        
        -- Mount preview click handler removed
    end
    
    row:Show()
    return row
end

local function ReturnRowToPool(row)
    if row then
        row:Hide()
        row.data = nil
        row.originalRowColor = nil
        table.insert(rowPool, row)
    end
end

-- UPDATE ROW CONTENT
function RaidMount.UpdateRowContent(row, data)
    if not row or not data then return end
    
    -- Set row data
    row.data = data
    
    -- Set background color (alternating)
    local rowColor = {0.05, 0.05, 0.1, 0.3}
    row.bg:SetColorTexture(unpack(rowColor))
    row.originalRowColor = rowColor
    
    -- Clear all text first
    for i = 1, #row.texts do
        row.texts[i]:SetText("")
        row.texts[i]:ClearAllPoints()
    end
    
    -- Column positions - updated to remove Last Attempt and add Lockout
    local columns = {
        {pos = 10, width = 30}, -- Icon
        {pos = 50, width = 200}, -- Mount Name
        {pos = 260, width = 150}, -- Raid/Source
        {pos = 420, width = 120}, -- Boss
        {pos = 550, width = 80}, -- Drop Rate
        {pos = 640, width = 100}, -- Expansion
        {pos = 750, width = 60}, -- Attempts
        {pos = 820, width = 50}, -- Status
        {pos = 850, width = 100}, -- Lockout 
    }
    
    -- Icon (using texture instead of text)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "OVERLAY")
        row.icon:SetSize(20, 20)
    end
    row.icon:SetPoint("LEFT", row, "LEFT", columns[1].pos, 0)
    
    local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    if data.mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(data.mountID)
        if iconFile then iconTexture = iconFile end
    end
    row.icon:SetTexture(iconTexture)
    
    -- Mount Name (colored by rarity like mount journal)
    local nameColor = "|cFFFFFFFF" -- Default white
    if data.mountID and C_MountJournal then
        local mountName, spellID, iconFile, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(data.mountID)
        
        if mountName then
            -- Get mount rarity and apply appropriate color
            local creatureDisplayID, description, source, isSelfMount, mountTypeID, uiModelSceneID = C_MountJournal.GetMountInfoExtraByID(data.mountID)
            
            -- Try to get quality from mount data or use sourceType to determine rarity
            local quality = 4 -- Default to epic (purple) for most raid mounts
            
            -- Most raid mounts are epic quality
            if sourceType then
                if sourceType == 1 then -- Drop
                    quality = 4 -- Epic (purple)
                elseif sourceType == 2 then -- Quest
                    quality = 3 -- Rare (blue)
                elseif sourceType == 3 then -- Vendor
                    quality = 3 -- Rare (blue)
                elseif sourceType == 4 then -- World Event
                    quality = 4 -- Epic (purple)
                elseif sourceType == 5 then -- Achievement
                    quality = 4 -- Epic (purple)
                elseif sourceType == 6 then -- Profession
                    quality = 3 -- Rare (blue)
                elseif sourceType == 7 then -- Trading Card Game
                    quality = 5 -- Legendary (orange)
                elseif sourceType == 8 then -- Black Market
                    quality = 4 -- Epic (purple)
                elseif sourceType == 9 then -- Promotion
                    quality = 5 -- Legendary (orange)
                elseif sourceType == 10 then -- In-Game Shop
                    quality = 4 -- Epic (purple)
                else
                    quality = 4 -- Default to epic
                end
            end
            
            -- Apply quality colors (same as item quality colors)
            if quality == 0 then
                nameColor = "|cFF9D9D9D" -- Poor (gray)
            elseif quality == 1 then
                nameColor = "|cFFFFFFFF" -- Common (white)
            elseif quality == 2 then
                nameColor = "|cFF1EFF00" -- Uncommon (green)
            elseif quality == 3 then
                nameColor = "|cFF0070DD" -- Rare (blue)
            elseif quality == 4 then
                nameColor = "|cFFA335EE" -- Epic (purple)
            elseif quality == 5 then
                nameColor = "|cFFFF8000" -- Legendary (orange)
            elseif quality == 6 then
                nameColor = "|cFFE6CC80" -- Artifact (light orange)
            elseif quality == 7 then
                nameColor = "|cFF00CCFF" -- Heirloom (light blue)
            end
            
            -- If mount is not collected, make it slightly dimmer
            if not data.collected then
                -- Reduce opacity for uncollected mounts
                if quality == 0 then
                    nameColor = "|cFF6D6D6D" -- Dimmed gray
                elseif quality == 1 then
                    nameColor = "|cFFBFBFBF" -- Dimmed white
                elseif quality == 2 then
                    nameColor = "|cFF14BF00" -- Dimmed green
                elseif quality == 3 then
                    nameColor = "|cFF0055AA" -- Dimmed blue
                elseif quality == 4 then
                    nameColor = "|cFF7F26BB" -- Dimmed purple
                elseif quality == 5 then
                    nameColor = "|cFFBF6000" -- Dimmed orange
                elseif quality == 6 then
                    nameColor = "|cFFB39960" -- Dimmed artifact
                elseif quality == 7 then
                    nameColor = "|cFF0099BF" -- Dimmed heirloom
                end
            end
        end
    end
    
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
    
    -- Status - using Blizzard icons instead of emoticons
    if not row.statusIcon then
        row.statusIcon = row:CreateTexture(nil, "OVERLAY")
        row.statusIcon:SetSize(16, 16)
    end
    row.statusIcon:SetPoint("LEFT", row, "LEFT", columns[8].pos + 17, 0) -- Center the icon in the column
    
    if data.collected then
        -- Green checkmark for collected
        row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        row.statusIcon:Show()
    else
        -- Red X for not collected
        row.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
        row.statusIcon:Show()
    end
    
    -- Hide the text version of status since we're using icons
    row.texts[7]:SetText("")
    
    -- Lockout (replacing Last Attempt)
    if not row.lockoutIcon then
        row.lockoutIcon = row:CreateTexture(nil, "OVERLAY")
        row.lockoutIcon:SetSize(14, 14)
    end
    
    local hasLockout, timeRemaining = GetLockoutInfo(data)
    
    if hasLockout and timeRemaining then
        -- Hide the icon when showing timer
        row.lockoutIcon:Hide()
        
        -- Show time remaining text - centered to match header
        row.texts[8]:SetPoint("LEFT", row, "LEFT", columns[9].pos, 0)
        row.texts[8]:SetText("|cFFFF8000" .. timeRemaining .. "|r")
        row.texts[8]:SetWidth(columns[9].width)  -- Now width = 100 to match header
        row.texts[8]:SetJustifyH("CENTER")       -- Center within that width
        row.texts[8]:SetTextColor(1, 0.5, 0, 1)
    else
        -- No lockout - show green tick centered
        row.lockoutIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        row.lockoutIcon:SetPoint("LEFT", row, "LEFT", columns[9].pos + (columns[9].width / 2) - 8, 0) -- Center the icon
        row.lockoutIcon:Show()
        
        -- Clear the text
        row.texts[8]:SetText("")
    end
end

-- Update visible rows based on scroll position
local function UpdateVisibleRows()
    if not RaidMount.ScrollFrame or not RaidMount.ScrollFrame.scrollChild then return end
    
    local scrollChild = RaidMount.ScrollFrame.scrollChild
    local scrollTop = RaidMount.ScrollFrame:GetVerticalScroll()
    local frameHeight = RaidMount.ScrollFrame:GetHeight()
    
    -- Calculate which rows should be visible
    local startRow = math.max(1, math.floor(scrollTop / rowHeight) + 1)
    local endRow = math.min(totalRows, startRow + math.ceil(frameHeight / rowHeight) + 1)
    
    -- Preload textures for upcoming rows
    PreloadUpcomingTextures(startRow, endRow)
    
    -- Hide all current visible rows
    for _, row in pairs(visibleRows) do
        ReturnRowToPool(row)
    end
    wipe(visibleRows)
    
    -- Create/show rows for visible range
    for i = startRow, endRow do
        if filteredData[i] then
            local row = GetRowFromPool(scrollChild)
            row.data = filteredData[i]
            
            -- Position the row
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * rowHeight)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * rowHeight)
            
            -- Update row content
            RaidMount.UpdateRowContent(row, filteredData[i])
            
            visibleRows[i] = row
        end
    end
end

-- Update scroll child height based on total rows
local function UpdateScrollChildHeight()
    if RaidMount.ScrollFrame and RaidMount.ScrollFrame.scrollChild then
        local totalHeight = totalRows * rowHeight
        RaidMount.ScrollFrame.scrollChild:SetHeight(totalHeight)
    end
end

-- Set filtered data and update display
function RaidMount.SetFilteredData(data)
    filteredData = data or {}
    totalRows = #filteredData
    UpdateScrollChildHeight()
    UpdateVisibleRows()
end

-- Get visible row count
function RaidMount.GetVisibleRowCount()
    local count = 0
    for _ in pairs(visibleRows) do
        count = count + 1
    end
    return count
end

-- Clear all visible rows
function RaidMount.ClearVisibleRows()
    for _, row in pairs(visibleRows) do
        ReturnRowToPool(row)
    end
    wipe(visibleRows)
end

-- Set up scroll frame callbacks
function RaidMount.SetupScrollFrameCallbacks()
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            self:SetVerticalScroll(offset)
            UpdateVisibleRows()
        end)
        
        RaidMount.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local newOffset = self:GetVerticalScroll() - (delta * rowHeight * 3)
            newOffset = math.max(0, math.min(newOffset, (totalRows * rowHeight) - self:GetHeight()))
            self:SetVerticalScroll(newOffset)
            UpdateVisibleRows()
        end)
    end
end

-- Export functions
RaidMount.UpdateVisibleRows = UpdateVisibleRows
RaidMount.GetRowFromPool = GetRowFromPool
RaidMount.ReturnRowToPool = ReturnRowToPool
