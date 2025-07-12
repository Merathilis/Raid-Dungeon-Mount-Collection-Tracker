-- RaidMount Popup System - Similar to Rarity addon
local addonName, RaidMount = ...

local popupFrame = nil
local currentZoneMounts = {}
local lastZone = nil
local popupVisible = false

-- At the top, define the set of world boss/rare MountIDs
local WORLD_BOSS_MOUNT_IDS = {
    [44168]=true, [63041]=true, [94228]=true, [94230]=true, [87771]=true, [95057]=true, [89783]=true, [634]=true, [643]=true,
    [90122]=true, [95044]=true, [90139]=true, [95053]=true, [758]=true, [1798]=true, [293]=true
}

-- Create the popup frame
local function CreatePopupFrame()
    if popupFrame then return popupFrame end
    
    -- Main popup frame
    popupFrame = CreateFrame("Frame", "RaidMountPopupFrame", UIParent, "BackdropTemplate")
    popupFrame:SetSize(420, 120) -- Increased width for better layout
    popupFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0) -- Center of the screen
    popupFrame:SetFrameStrata("HIGH")
    popupFrame:SetFrameLevel(100)
    
    -- Backdrop
    popupFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    popupFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
    popupFrame:SetBackdropBorderColor(0.8, 0.6, 0.2, 1)
    
    -- Title
    popupFrame.title = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    popupFrame.title:SetPoint("TOP", 0, -10)
    popupFrame.title:SetText("|cFF33CCFFRaid|r|cFFFF0000Mount|r Alert")
    popupFrame.title:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    
    -- Zone info
    popupFrame.zoneText = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.zoneText:SetPoint("TOP", popupFrame.title, "BOTTOM", 0, -5)
    popupFrame.zoneText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    popupFrame.zoneText:SetTextColor(1, 0.82, 0, 1)
    
    -- Mount count
    popupFrame.countText = popupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    popupFrame.countText:SetPoint("TOP", popupFrame.zoneText, "BOTTOM", 0, -5)
    popupFrame.countText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    popupFrame.countText:SetTextColor(0.8, 0.8, 0.8, 1)
    
    -- Close button
    popupFrame.closeButton = CreateFrame("Button", nil, popupFrame, "UIPanelCloseButton")
    popupFrame.closeButton:SetPoint("TOPRIGHT", -5, -5)
    popupFrame.closeButton:SetScript("OnClick", function()
        HidePopup()
    end)
    
    -- Make draggable
    popupFrame:SetMovable(true)
    popupFrame:EnableMouse(true)
    popupFrame:RegisterForDrag("LeftButton")
    popupFrame:SetScript("OnDragStart", popupFrame.StartMoving)
    popupFrame:SetScript("OnDragStop", popupFrame.StopMovingOrSizing)
    
    popupFrame:Hide()
    return popupFrame
end

-- Create mount entry in popup
local function CreateMountEntry(parent, mountData, yOffset)
    local entry = CreateFrame("Frame", nil, parent)
    entry:SetSize(400, 36) -- Increased width for better layout
    entry:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset)

    -- Mount icon (left)
    entry.icon = entry:CreateTexture(nil, "ARTWORK")
    entry.icon:SetSize(24, 24)
    entry.icon:SetPoint("LEFT", entry, "LEFT", 10, 0)
    local iconTexture = "Interface\\Icons\\INV_Misc_QuestionMark"
    if mountData.mountID and C_MountJournal then
        local _, _, iconFile = C_MountJournal.GetMountInfoByID(mountData.mountID)
        if iconFile then iconTexture = iconFile end
    end
    entry.icon:SetTexture(iconTexture)

    -- Mount name (colored)
    entry.nameText = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    entry.nameText:SetPoint("LEFT", entry.icon, "RIGHT", 10, 0)
    entry.nameText:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    entry.nameText:SetJustifyH("LEFT")
    entry.nameText:SetWidth(180)
    entry.nameText:SetHeight(24)
    entry.nameText:SetWordWrap(false)
    if mountData.collected then
        entry.nameText:SetText("|cFF00FF00" .. (mountData.mountName or "Unknown Mount") .. "|r")
    else
        entry.nameText:SetText("|cFFFFFFFF" .. (mountData.mountName or "Unknown Mount") .. "|r")
    end

    -- Tick/cross icon (next to name)
    entry.statusIcon = entry:CreateTexture(nil, "OVERLAY")
    entry.statusIcon:SetSize(16, 16)
    entry.statusIcon:SetPoint("LEFT", entry.nameText, "RIGHT", 8, 0)
    if mountData.collected then
        entry.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    else
        entry.statusIcon:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    end
    entry.statusIcon:Show()

    -- Coord/map pin button (right-aligned, always visible, icon-only)
    entry.coordButton = CreateFrame("Button", nil, entry)
    entry.coordButton:SetSize(22, 22)
    entry.coordButton:SetPoint("RIGHT", entry, "RIGHT", -16, 0)
    entry.coordIcon = entry.coordButton:CreateTexture(nil, "OVERLAY")
    entry.coordIcon:SetSize(16, 16)
    entry.coordIcon:SetPoint("CENTER", entry.coordButton, "CENTER", 0, 0)
    entry.coordIcon:SetTexture("Interface\\Icons\\INV_Misc_Map_01")
    entry.coordButton:SetScript("OnEnter", function(self)
        entry.coordIcon:SetVertexColor(1, 1, 0, 1)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Set waypoint to this mount's location", 1, 1, 1)
        local coordKey = mountData.mountID
        local coords = coordKey and RaidMount.Coordinates and RaidMount.Coordinates[coordKey]
        if coords then
            GameTooltip:AddLine(coords.zone or "Unknown Zone", 1, 0.82, 0, 1)
            if coords.instance then
                GameTooltip:AddLine(coords.instance, 0.8, 0.8, 0.8, 1)
            end
            if coords.note then
                GameTooltip:AddLine(coords.note, 1, 1, 0, 1)
            end
        end
        GameTooltip:Show()
    end)
    entry.coordButton:SetScript("OnLeave", function(self)
        entry.coordIcon:SetVertexColor(1, 1, 1, 1)
        GameTooltip:Hide()
    end)
    entry.coordButton:SetScript("OnClick", function(self)
        local coordKey = mountData.mountID
        local coords = coordKey and RaidMount.Coordinates and RaidMount.Coordinates[coordKey]
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
            if TomTom and TomTom.AddWaypoint and mapID then
                local success = TomTom:AddWaypoint(mapID, coords.x / 100, coords.y / 100, {
                    title = string.format("%s (%s)", mountData.mountName or "Mount", coords.instance or ""),
                    persistent = false,
                    minimap = true,
                    world = true,
                    crazy = true
                })
                if success then
                    waypointSet = true
                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r TomTom waypoint set for %s", mountData.mountName or "Mount"))
                end
            elseif TomTom and TomTom.AddWaypoint and not mapID then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000RaidMount:|r Could not find map ID for zone: " .. tostring(coords.zone))
            end
            if not waypointSet and C_Map and C_Map.SetUserWaypoint and mapID then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r Waypoint set for %s at %s (%.1f, %.1f)", mountData.mountName or "Mount", coords.zone, coords.x, coords.y))
                waypointSet = true
            end
            if not waypointSet then
                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF33CCFFRaidMount:|r %s location: %s (%.1f, %.1f)", mountData.mountName or "Mount", coords.zone, coords.x, coords.y))
            end
        end
    end)
    entry.coordButton:Show()
    if entry.waypointButton then entry.waypointButton:Hide() end
    return entry
end

-- Update popup content
local function UpdatePopupContent()
    if not popupFrame then return end

    -- Remove any previous mount entries
    if popupFrame.mountEntries then
        for _, entry in ipairs(popupFrame.mountEntries) do
            entry:Hide()
            entry:SetParent(nil)
        end
    end
    popupFrame.mountEntries = {}

    local currentZone = GetZoneText()
    popupFrame.zoneText:SetText(currentZone)

    local mountCount = #currentZoneMounts
    local collectedCount = 0
    for _, mount in ipairs(currentZoneMounts) do
        if mount.collected then
            collectedCount = collectedCount + 1
        end
    end
    popupFrame.countText:SetText(string.format("%d mounts available (%d collected)", mountCount, collectedCount))

    -- Create mount entries as direct children
    local yOffset = -65 -- Start below the countText (adjust as needed)
    for i, mountData in ipairs(currentZoneMounts) do
        local entry = CreateMountEntry(popupFrame, mountData, yOffset)
        table.insert(popupFrame.mountEntries, entry)
        yOffset = yOffset - 38 -- Spacing between entries
    end

    -- Set popup height to fit all entries
    local baseHeight = 90 -- Header + zone + countText
    local totalHeight = baseHeight + (#currentZoneMounts * 38)
    popupFrame:SetHeight(math.min(totalHeight, 400))
end

-- Show popup
local function ShowPopup()
    if not popupFrame then
        CreatePopupFrame()
    end
    
    UpdatePopupContent()
    popupFrame:Show()
    popupVisible = true
end

-- Hide popup
function HidePopup()
    if popupFrame then
        popupFrame:Hide()
        popupVisible = false
    end
end

-- Check if we should show popup for current zone
local function CheckZoneForMounts()
    local currentZone = GetZoneText()

    -- Don't show if popup is disabled
    if RaidMountSaved and RaidMountSaved.popupEnabled == false then
        HidePopup()
        return
    end
    -- Don't show if same zone or if zone is ignored
    if currentZone == lastZone then return end
    if RaidMount.popupIgnoreZones and RaidMount.popupIgnoreZones[currentZone] then return end
    
    lastZone = currentZone
    currentZoneMounts = {}
    
    -- Get all mount data and filter by current zone using coordinates
    local allMounts = RaidMount.GetCombinedMountData and RaidMount.GetCombinedMountData()
    if not allMounts then return end
    
    for _, mountData in ipairs(allMounts) do
        -- Check if this mount has coordinates for the current zone
        local coordKey = mountData.mountID
        if WORLD_BOSS_MOUNT_IDS[coordKey] then
            local coords = coordKey and RaidMount.Coordinates and RaidMount.Coordinates[coordKey]
            if coords and coords.zone == currentZone then
                table.insert(currentZoneMounts, mountData)
            end
        end
    end
    
    -- Show popup if we have mounts in this zone
    if #currentZoneMounts > 0 then
        PlaySound(8959, "Master")
        ShowPopup()
    else
        HidePopup()
    end
end

-- Event handling
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("ZONE_CHANGED")
eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    -- Small delay to ensure zone text is updated
    C_Timer.After(1, CheckZoneForMounts)
end)

-- Export functions
RaidMount.ShowMountPopup = ShowPopup
RaidMount.HideMountPopup = HidePopup
RaidMount.CheckZoneForMounts = CheckZoneForMounts 