-- Mount List module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

local visibleRows = {}
local rowPool = {}
local maxVisibleRows = 30
local rowHeight = 25
local scrollOffset = 0
local totalRows = 0
local filteredData = {}

RaidMount.textureCache = RaidMount.textureCache or {}
local textureCache = RaidMount.textureCache
local preloadQueue = {}
local preloadDistance = 10

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
    
    table.insert(preloadQueue, mountID)
    
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
            
            if #preloadQueue > 0 then
                C_Timer.After(0.01, function()
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
        if RaidMount.performanceStats then
            RaidMount.performanceStats.textureCache.hits = (RaidMount.performanceStats.textureCache.hits or 0) + 1
        end
        return textureCache[mountID]
    end
    
    if RaidMount.performanceStats then
        RaidMount.performanceStats.textureCache.misses = (RaidMount.performanceStats.textureCache.misses or 0) + 1
    end
    
    local mountInfo = C_MountJournal.GetMountInfoByID(mountID)
    if mountInfo then
        textureCache[mountID] = mountInfo.iconFileID
        return mountInfo.iconFileID
    end
    
    return nil
end

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

local function GetRowFromPool(parent)
    local row = table.remove(rowPool)
    if not row then
        row = CreateFrame("Frame", nil, parent)
        row:SetHeight(rowHeight)
        
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        
        row.texts = {}
        for i = 1, 10 do
            local text = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetFont(cachedFontPath, 13, "OUTLINE")
            row.texts[i] = text
        end
        
        row:EnableMouse(true)
        row:SetScript("OnEnter", function(self)
            if self.data and RaidMountTooltipEnabled then
                if RaidMount.ShowTooltip then
                    RaidMount.ShowTooltip(self, self.data)
                end
            end
            self.bg:SetColorTexture(unpack(COLORS.primaryDark or {0.2, 0.2, 0.2, 1}))
            
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

function RaidMount.UpdateRowContent(row, data)
    if not row or not data then return end
    
    row.data = data
    
    local rowColor = {0.05, 0.05, 0.1, 0.3}
    row.bg:SetColorTexture(unpack(rowColor))
    row.originalRowColor = rowColor
    
    for i = 1, #row.texts do
        row.texts[i]:SetText("")
        row.texts[i]:ClearAllPoints()
    end
    
    local columns = {
        {pos = 10, width = 30}, -- Icon
        {pos = 50, width = 180}, -- Mount Name
        {pos = 240, width = 130}, -- Raid/Source
        {pos = 380, width = 100}, -- Boss
        {pos = 490, width = 70}, -- Drop Rate
        {pos = 570, width = 90}, -- Expansion
        {pos = 670, width = 50}, -- Attempts
        {pos = 730, width = 50}, -- Status
        {pos = 790, width = 120}, -- Lockout 
        {pos = 920, width = 60}, -- Coordinates
    }
    
    -- Icon (using texture instead of text)
    if not row.icon then
        row.icon = row:CreateTexture(nil, "OVERLAY")
        row.icon:SetSize(20, 20)
    end
    row.icon:SetPoint("LEFT", row, "LEFT", columns[1].pos, 0)
    
    local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    
    -- Try multiple approaches to get the mount icon
    if data.mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(data.mountID)
        if iconFile then 
            iconTexture = iconFile
        else
            -- Try using spellID as fallback
            if data.spellID then
                local mountIDs = C_MountJournal.GetMountIDs()
                if mountIDs then
                    for _, mountID in ipairs(mountIDs) do
                        local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)
                        if spellID == data.spellID and icon then
                            iconTexture = icon
                            break
                        end
                    end
                end
            end
        end
    end
    row.icon:SetTexture(iconTexture)
    
    local nameColor = "|cFFFFFFFF"
    local mountName, spellID, iconFile, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID
    
    -- Try to get mount info with fallback
    if data.mountID and C_MountJournal then
        mountName, spellID, iconFile, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected, mountID = C_MountJournal.GetMountInfoByID(data.mountID)
        
        -- If direct lookup failed, try spellID fallback
        if not mountName and data.spellID then
            local mountIDs = C_MountJournal.GetMountIDs()
            if mountIDs then
                for _, journalMountID in ipairs(mountIDs) do
                    local name, journalSpellID, icon, isActive, isUsable, journalSourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(journalMountID)
                    if journalSpellID == data.spellID then
                        mountName = name
                        sourceType = journalSourceType
                        break
                    end
                end
            end
        end
        
        if mountName then
            local quality = 4
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
                    quality = 4
                end
            end
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
            
            if not data.collected then
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
            
            if data.collectorsBounty then
                if data.collected then
                    nameColor = "|cFFFFE0A0"
                else
                    nameColor = "|cFFD4AF37"
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
    
    if not row.statusIcon then
        row.statusIcon = row:CreateTexture(nil, "OVERLAY")
        row.statusIcon:SetSize(16, 16)
    end
    row.statusIcon:SetPoint("LEFT", row, "LEFT", columns[8].pos + 17, 0)
    
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
    
    local hasLockout, timeRemaining = GetLockoutInfo(data)
    
    if hasLockout and timeRemaining then
        row.lockoutIcon:Hide()
        
        row.texts[8]:SetPoint("LEFT", row, "LEFT", columns[9].pos, 0)
        row.texts[8]:SetText("|cFFFF8000" .. timeRemaining .. "|r")
        row.texts[8]:SetWidth(columns[9].width)
        row.texts[8]:SetJustifyH("CENTER")
        row.texts[8]:SetTextColor(1, 0.5, 0, 1)
    else
        row.lockoutIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
        row.lockoutIcon:SetPoint("LEFT", row, "LEFT", columns[9].pos + (columns[9].width / 2) - 8, 0)
        row.lockoutIcon:Show()
        
        row.texts[8]:SetText("")
    end
    
    if not row.mapButton then
        row.mapButton = CreateFrame("Button", nil, row)
        row.mapButton:SetSize(40, rowHeight)
        row.mapButton:SetPoint("LEFT", row, "LEFT", 938, 0)
        
        row.mapIcon = row.mapButton:CreateTexture(nil, "OVERLAY")
        row.mapIcon:SetSize(14, 14)
        row.mapIcon:SetPoint("CENTER", row.mapButton, "CENTER", 0, 0)
        row.mapIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
        
        row.mapButton:SetScript("OnEnter", function(self)
            row.mapIcon:SetVertexColor(1, 1, 0, 1)
            local currentData = row.data
            if currentData then
                local coordKey = tonumber(currentData.mountID)
                local coords = nil
                if coordKey and RaidMount.Coordinates then
                    -- Direct lookup by mount ID
                    coords = RaidMount.Coordinates[coordKey]
                end
                
                if coords then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Click to open map", 1, 1, 1)
                    GameTooltip:AddLine(coords.zone or "Unknown Zone", 1, 0.82, 0, 1)
                    if coords.instance then
                        GameTooltip:AddLine(coords.instance, 0.8, 0.8, 0.8, 1)
                    end
                    -- Show special notes for world bosses
                    if coords.note then
                        GameTooltip:AddLine(coords.note, 1, 1, 0, 1)
                    end
                    -- Show content type for context
                    if currentData.contentType then
                        GameTooltip:AddLine(currentData.contentType, 0.6, 0.6, 1, 1)
                    end
                    GameTooltip:Show()
                end
            end
        end)
        
        row.mapButton:SetScript("OnLeave", function(self)
            row.mapIcon:SetVertexColor(1, 1, 1, 1) -- Back to normal
            GameTooltip:Hide()
        end)
        
        -- Click handler
        row.mapButton:SetScript("OnClick", function(self)
            local currentData = row.data -- Get current data from row
            if currentData then
                -- Use the mountID as a number for lookup
                local coordKey = tonumber(currentData.mountID)
                local coords = nil
                if coordKey and RaidMount.Coordinates then
                    -- Direct lookup by mount ID
                    coords = RaidMount.Coordinates[coordKey]
                end
                if coords and coords.zone and coords.x and coords.y then
                    local waypointSet = false
                    local mapID = nil
                    if C_Map and C_Map.GetMapInfo then
                        for i = 1, 2000 do
                            local mapInfo = C_Map.GetMapInfo(i)
                            if mapInfo and mapInfo.name == coords.zone then
                                mapID = i
                                break
                            end
                        end
                    end
                    -- TomTom support (preferred for cross-expansion travel)
                    if TomTom and TomTom.AddWaypoint and mapID then
                        -- TomTom can handle cross-continent waypoints better
                        local success = TomTom:AddWaypoint(mapID, coords.x / 100, coords.y / 100, {
                            title = string.format("%s (%s)", currentData.mountName or "Mount Location", coords.instance or ""),
                            persistent = false,
                            minimap = true,
                            world = true,
                            crazy = true  -- Enables cross-continent pathfinding
                        })
                        if success then
                            waypointSet = true
                            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r TomTom waypoint set for %s at %s (%.1f, %.1f)", 
                                currentData.mountName or "Mount", coords.zone, coords.x, coords.y))
                            DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r Instance: %s | Expansion: %s", 
                                coords.instance or "Unknown", currentData.expansion or "Unknown"))
                            -- Special guidance for world bosses
                            if currentData.contentType == "World" and coords.note then
                                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8000RaidMount:|r %s", coords.note))
                            end
                        end
                    elseif TomTom and TomTom.AddWaypoint and not mapID then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000RaidMount:|r Could not find map ID for zone: " .. tostring(coords.zone))
                    end
                    -- Try WoW's built-in waypoint system if TomTom not available or failed
                    if not waypointSet and C_Map and C_Map.SetUserWaypoint and mapID then
                        -- Set waypoint using WoW's built-in system
                        local waypoint = UiMapPoint.CreateFromCoordinates(mapID, coords.x / 100, coords.y / 100)
                        C_Map.SetUserWaypoint(waypoint)
                        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                        waypointSet = true
                        -- Set the map ID for the waypoint (but don't open the map)
                        if WorldMapFrame then
                            WorldMapFrame:SetMapID(mapID)
                        end
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r Waypoint set for %s at %s (%.1f, %.1f)", 
                            currentData.mountName or "Mount", coords.zone, coords.x, coords.y))
                        -- Provide intelligent travel guidance
                        local currentZone = GetZoneText()
                        if currentZone and currentZone ~= coords.zone then
                            local travelGuide = RaidMount.TravelGuides and RaidMount.TravelGuides[coords.zone]
                            if travelGuide then
                                -- Determine current expansion context
                                local routeKey = nil
                                if string.find(currentZone, "Dornogal") or string.find(currentZone, "Khaz Algar") then
                                    routeKey = "from_war_within"
                                elseif string.find(currentZone, "Valdrakken") or string.find(currentZone, "Dragon") then
                                    routeKey = "from_dragonflight"
                                elseif string.find(currentZone, "Oribos") or string.find(currentZone, "Shadowlands") then
                                    routeKey = "from_shadowlands"
                                end
                                if routeKey and travelGuide[routeKey] then
                                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00RaidMount Travel Guide:|r %s", travelGuide[routeKey]))
                                else
                                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8000RaidMount:|r Cross-expansion travel: %s → %s (%s)", 
                                        currentZone, coords.zone, currentData.expansion or "Unknown"))
                                end
                            else
                                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8000RaidMount:|r Travel needed: %s → %s (%s)", 
                                    currentZone, coords.zone, currentData.expansion or "Unknown"))
                            end
                        end
                    end
                    -- Fallback: Just show location info without opening map
                    if not waypointSet then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r %s location: %s (%s) - %.1f, %.1f", 
                            currentData.mountName or "Mount", coords.zone, coords.instance or "Unknown", coords.x, coords.y))
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8000RaidMount:|r Install TomTom addon for better cross-expansion waypoint support"))
                    end
                end
            end
        end)
    end
    
    if data then
        local coordKey = tonumber(data.mountID)
        local coords = nil
        if coordKey and RaidMount.Coordinates then
            coords = RaidMount.Coordinates[coordKey]
        end
   
        if coords then
            row.mapButton:Show()
            row.mapIcon:SetVertexColor(1, 1, 1, 1)
        else
            row.mapButton:Hide()
        end
    else
        row.mapButton:Hide()
    end
end

local function UpdateVisibleRows()
    if not RaidMount.ScrollFrame or not RaidMount.ScrollFrame.scrollChild then return end
    
    local scrollChild = RaidMount.ScrollFrame.scrollChild
    local scrollTop = RaidMount.ScrollFrame:GetVerticalScroll()
    local frameHeight = RaidMount.ScrollFrame:GetHeight()
    
    local startRow = math.max(1, math.floor(scrollTop / rowHeight) + 1)
    local endRow = math.min(totalRows, startRow + math.ceil(frameHeight / rowHeight) + 1)
    
    PreloadUpcomingTextures(startRow, endRow)
    
    for _, row in pairs(visibleRows) do
        ReturnRowToPool(row)
    end
    wipe(visibleRows)
    
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

local function UpdateScrollChildHeight()
    if RaidMount.ScrollFrame and RaidMount.ScrollFrame.scrollChild then
        local totalHeight = totalRows * rowHeight
        RaidMount.ScrollFrame.scrollChild:SetHeight(totalHeight)
    end
end

local function UpdateVisibleRowsOptimized()
    if not RaidMount.ScrollFrame or not RaidMount.ScrollFrame.scrollChild then return end
    
    local scrollChild = RaidMount.ScrollFrame.scrollChild
    local scrollTop = RaidMount.ScrollFrame:GetVerticalScroll()
    local frameHeight = RaidMount.ScrollFrame:GetHeight()
    
    local startRow = math.max(1, math.floor(scrollTop / rowHeight) + 1)
    local endRow = math.min(totalRows, startRow + math.ceil(frameHeight / rowHeight) + 1)
    
    PreloadUpcomingTextures(startRow, endRow)
    
    local newVisibleRows = {}
    local rowsToReuse = {}
    
    for i = startRow, endRow do
        if filteredData[i] then
            local existingRow = visibleRows[i]
            if existingRow then
                rowsToReuse[i] = existingRow
                newVisibleRows[i] = existingRow
            end
        end
    end
    
    for rowIndex, row in pairs(visibleRows) do
        if not rowsToReuse[rowIndex] then
            ReturnRowToPool(row)
        end
    end
    
    for i = startRow, endRow do
        if filteredData[i] and not newVisibleRows[i] then
            local row = GetRowFromPool(scrollChild)
            row.data = filteredData[i]
            
            -- Position the row
            row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -(i - 1) * rowHeight)
            row:SetPoint("TOPRIGHT", scrollChild, "TOPRIGHT", 0, -(i - 1) * rowHeight)
            
            -- Update row content
            RaidMount.UpdateRowContent(row, filteredData[i])
            
            newVisibleRows[i] = row
        end
    end
    
    for i = startRow, endRow do
        if filteredData[i] and rowsToReuse[i] then
            local row = rowsToReuse[i]
            row.data = filteredData[i]
            RaidMount.UpdateRowContent(row, filteredData[i])
        end
    end
    
    wipe(visibleRows)
    for k, v in pairs(newVisibleRows) do
        visibleRows[k] = v
    end
end

function RaidMount.SetFilteredData(data)
    local oldTotalRows = totalRows
    filteredData = data or {}
    totalRows = #filteredData
    
    if math.abs(totalRows - oldTotalRows) > 5 then
        UpdateScrollChildHeight()
    end
    
    UpdateVisibleRowsOptimized()
end

function RaidMount.GetVisibleRowCount()
    local count = 0
    for _ in pairs(visibleRows) do
        count = count + 1
    end
    return count
end

function RaidMount.ClearVisibleRows()
    for _, row in pairs(visibleRows) do
        ReturnRowToPool(row)
    end
    wipe(visibleRows)
end

function RaidMount.SetupScrollFrameCallbacks()
    if RaidMount.ScrollFrame then
        RaidMount.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            self:SetVerticalScroll(offset)
            UpdateVisibleRowsOptimized()
        end)
        
        RaidMount.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local newOffset = self:GetVerticalScroll() - (delta * rowHeight * 3)
            newOffset = math.max(0, math.min(newOffset, (totalRows * rowHeight) - self:GetHeight()))
            self:SetVerticalScroll(newOffset)
            UpdateVisibleRowsOptimized()
        end)
    end
end

RaidMount.UpdateVisibleRows = UpdateVisibleRows
RaidMount.UpdateVisibleRowsOptimized = UpdateVisibleRowsOptimized
RaidMount.GetRowFromPool = GetRowFromPool
RaidMount.ReturnRowToPool = ReturnRowToPool
