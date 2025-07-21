local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local ICON_SIZE = 54
local ICON_PADDING = 4
local ICON_PADDING_Y = 20 -- Increased vertical padding
local ICONS_PER_ROW = 10

local iconGridFrame

function RaidMount.ShowIconView()
    if iconGridFrame and iconGridFrame:IsShown() and not RaidMount.isRefreshing then return end
    if not iconGridFrame then
        iconGridFrame = CreateFrame("Frame", nil, RaidMount.RaidMountFrame)
        -- Uniform containment: match list view
        iconGridFrame:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 15, -180)
        iconGridFrame:SetPoint("BOTTOMRIGHT", RaidMount.RaidMountFrame, "BOTTOMRIGHT", -35, 160)
        iconGridFrame:SetFrameLevel(RaidMount.RaidMountFrame:GetFrameLevel() + 10)
        iconGridFrame:EnableMouse(true)
        iconGridFrame:SetMovable(false)
        iconGridFrame.icons = {}
        iconGridFrame.scroll = CreateFrame("ScrollFrame", nil, iconGridFrame, "UIPanelScrollFrameTemplate")
        -- Uniform scroll frame containment: match list view
        iconGridFrame.scroll:SetPoint("TOPLEFT", iconGridFrame, "TOPLEFT", 0, 0)
        iconGridFrame.scroll:SetPoint("BOTTOMRIGHT", iconGridFrame, "BOTTOMRIGHT", -20, 0)
        iconGridFrame.scrollChild = CreateFrame("Frame", nil, iconGridFrame.scroll)
        iconGridFrame.scrollChild:SetSize(1, 1)
        iconGridFrame.scroll:SetScrollChild(iconGridFrame.scrollChild)
        iconGridFrame.scrollChild:EnableMouse(false)
    end
    iconGridFrame:Show()
    local gridWidth = iconGridFrame:GetWidth() or 900
    local gridHeight = iconGridFrame:GetHeight() or 400
    ICONS_PER_ROW = math.floor((gridWidth + ICON_PADDING) / (ICON_SIZE + ICON_PADDING))
    if ICONS_PER_ROW < 1 then ICONS_PER_ROW = 1 end
    local visibleRows = math.floor((gridHeight + ICON_PADDING) / (ICON_SIZE + ICON_PADDING))
    if visibleRows < 1 then visibleRows = 1 end
    local usedWidth = ICONS_PER_ROW * (ICON_SIZE + ICON_PADDING)
    local xOffset = 0
    if usedWidth < gridWidth then
        xOffset = math.floor((gridWidth - usedWidth) / 2)
    end
    for _, btn in ipairs(iconGridFrame.icons) do btn:Hide() end
    local filteredData = RaidMount.FilterAndSortMountData(RaidMount.GetCombinedMountData())
    local row, col = 0, 0
    local idx = 1
    for i, data in ipairs(filteredData) do
        local btn = iconGridFrame.icons[idx]
        if not btn then
            btn = CreateFrame("Button", nil, iconGridFrame.scrollChild)
            btn:SetSize(ICON_SIZE, ICON_SIZE)
            btn:SetFrameLevel(iconGridFrame.scrollChild:GetFrameLevel() + 10)
            btn:EnableMouse(true)
            btn.icon = btn:CreateTexture(nil, "ARTWORK")
            btn.icon:SetAllPoints()
            -- Map icon inside main icon bounds (bottom right)
            btn.mapIcon = btn:CreateTexture(nil, "OVERLAY")
            btn.mapIcon:SetSize(18, 18)
            btn.mapIcon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -2, 2)
            btn.mapIcon:SetTexture("Interface/Icons/INV_Misc_Map_01")
            -- btn.mapIcon:Hide() -- Temporarily disabled for testing
            btn.mapButton = CreateFrame("Button", nil, btn)
            btn.mapButton:SetSize(32, 32)
            btn.mapButton:SetPoint("CENTER", btn.mapIcon, "CENTER")
            btn.mapButton:EnableMouse(true)
            btn.mapButton:SetFrameLevel(btn:GetFrameLevel() + 2)
            btn.mapButton:Hide()
            btn.mapButton:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Set waypoint for this mount", 1, 1, 1)
                GameTooltip:Show()
            end)
            btn.mapButton:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
            end)
            btn.mapButton:SetScript("OnClick", function(self)
                local data = self:GetParent().data
                if not data or not data.coordinates then return end
                local x, y = data.coordinates:match("(%d+%.?%d*)%,(%d+%.?%d*)")
                if x and y then
                    x, y = tonumber(x), tonumber(y)
                    local mapID = data.mapID or (C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player"))
                    if mapID and UiMapPoint and C_Map and C_Map.SetUserWaypoint and C_SuperTrack then
                        local uiMapPoint = UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100)
                        C_Map.SetUserWaypoint(uiMapPoint)
                        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
                        print(string.format("RaidMount: Waypoint set for %s at %.1f, %.1f", data.mountName or "Mount", x, y))
                    end
                    if TomTom then
                        TomTom:AddWaypoint(mapID, x / 100, y / 100, {
                            title = data.mountName or "Mount Waypoint",
                            persistent = false,
                            minimap = true,
                            world = true,
                        })
                        print(string.format("RaidMount: TomTom waypoint set for %s at %.1f, %.1f", data.mountName or "Mount", x, y))
                    end
                end
            end)
            btn:SetScript("OnEnter", function(self)
                if RaidMountTooltipEnabled and RaidMount.ShowTooltip then
                    -- Get current lockout status for this mount's raid
                    local currentLockoutStatus = "Unknown"
                    if self.data and self.data.raidName then
                        currentLockoutStatus = RaidMount.GetRaidLockout(self.data.raidName)
                    end
                    RaidMount.ShowTooltip(self, self.data, currentLockoutStatus)
                end
                if RaidMount.ShowInfoPanel then
                    RaidMount.ShowInfoPanel(self.data)
                end
            end)
            btn:SetScript("OnLeave", function(self)
                GameTooltip:Hide()
                if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.infoPanel then
                    RaidMount.RaidMountFrame.infoPanel:Hide()
                end
            end)
            iconGridFrame.icons[idx] = btn
        end
        btn.data = data
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
        btn.icon:SetTexture(iconTexture)
        btn.icon:SetDesaturated(not data.collected)
        -- Add status icon (tick or X) in bottom-left corner
        if not btn.statusIcon then
            btn.statusIcon = btn:CreateTexture(nil, "OVERLAY")
            btn.statusIcon:SetSize(18, 18)
            btn.statusIcon:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 2, 2)
        end
        if data.collected then
            btn.statusIcon:SetTexture("Interface/RaidFrame/ReadyCheck-Ready")
        else
            btn.statusIcon:SetTexture("Interface/RaidFrame/ReadyCheck-NotReady")
        end
        btn.statusIcon:Show()
        btn:SetPoint("TOPLEFT", iconGridFrame.scrollChild, "TOPLEFT", xOffset + col * (ICON_SIZE + ICON_PADDING), -row * (ICON_SIZE + ICON_PADDING_Y))
        -- Map icon always visible if coordinates exist
        if data.coordinates then
            btn.mapIcon:Show()
            btn.mapButton:Show()
        else
            btn.mapIcon:Hide()
            btn.mapButton:Hide()
        end
        btn:Show()
        col = col + 1
        if col >= ICONS_PER_ROW then col = 0; row = row + 1 end
        idx = idx + 1
    end
    for i = idx, #iconGridFrame.icons do
        iconGridFrame.icons[i]:Hide()
    end
    local totalRows = math.ceil(#filteredData / ICONS_PER_ROW)
    iconGridFrame.scrollChild:SetSize(ICONS_PER_ROW * (ICON_SIZE + ICON_PADDING), totalRows * (ICON_SIZE + ICON_PADDING_Y))
    -- Only hide the scroll bar and disable mouse wheel, do not disable mouse on scroll or scrollChild
    -- if iconGridFrame.scroll.ScrollBar then
    --     iconGridFrame.scroll.ScrollBar:Hide()
    --     iconGridFrame.scroll.ScrollBar.Show = function() end
    -- end
    -- iconGridFrame.scroll:EnableMouseWheel(false)
    -- iconGridFrame.scroll:SetScript("OnMouseWheel", nil)
    -- iconGridFrame.scrollChild:SetFrameLevel(iconGridFrame:GetFrameLevel() - 1)
end

function RaidMount.HideIconView()
    if iconGridFrame then iconGridFrame:Hide() end
end

function RaidMount.RefreshIconView()
    if iconGridFrame and iconGridFrame:IsShown() then
        RaidMount.isRefreshing = true
        RaidMount.ShowIconView()
        RaidMount.isRefreshing = false
    end
end 
