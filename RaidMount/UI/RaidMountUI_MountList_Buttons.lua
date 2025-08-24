-- Mount List Buttons module for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Import utilities
local COLORS = RaidMount.COLORS
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Map button creation
function RaidMount.CreateMapButton(row, data, columns)
    if not row.mapButton then
        row.mapButton = CreateFrame("Button", nil, row)
        row.mapButton:SetSize(40, RaidMount.rowHeight)
        row.mapButton:SetPoint("CENTER", row, "LEFT", columns[10].pos + (columns[10].width / 2), 0)

        row.mapIcon = row.mapButton:CreateTexture(nil, "OVERLAY")
        row.mapIcon:SetSize(16, 16)
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
                            title = string.format("%s (%s)", currentData.mountName or "Mount Location",
                                coords.instance or ""),
                            persistent = false,
                            minimap = true,
                            world = true,
                            crazy = true -- Enables cross-continent pathfinding
                        })

                        if success then
                            waypointSet = true
                            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                "|cFF33CCFFRaidMount:|r TomTom waypoint set for %s at %s (%.1f, %.1f)",
                                currentData.mountName or "Mount", coords.zone, coords.x, coords.y))
                            DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                "|cFF33CCFFRaidMount:|r Instance: %s | Expansion: %s",
                                coords.instance or "Unknown", currentData.expansion or "Unknown"))
                            -- Special guidance for world bosses
                            if currentData.contentType == "World" and coords.note then
                                DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFFFF8000RaidMount:|r %s", coords.note))
                            end
                        end
                    elseif TomTom and TomTom.AddWaypoint and not mapID then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000RaidMount:|r Could not find map ID for zone: " ..
                            tostring(coords.zone))
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
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFF33CCFFRaidMount:|r Waypoint set for %s at %s (%.1f, %.1f)",
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
                                    DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF00FF00RaidMount Travel Guide:|r %s",
                                        travelGuide[routeKey]))
                                else
                                    DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                        "|cFFFF8000RaidMount:|r Cross-expansion travel: %s -> %s (%s)",
                                        currentZone, coords.zone, currentData.expansion or "Unknown"))
                                end
                            else
                                DEFAULT_CHAT_FRAME:AddMessage(string.format(
                                    "|cFFFF8000RaidMount:|r Travel needed: %s -> %s (%s)",
                                    currentZone, coords.zone, currentData.expansion or "Unknown"))
                            end
                        end
                    end
                    -- Fallback: Just show location info without opening map
                    if not waypointSet then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFF33CCFFRaidMount:|r %s location: %s (%s) - %.1f, %.1f",
                            currentData.mountName or "Mount", coords.zone, coords.instance or "Unknown", coords.x,
                            coords.y))
                        DEFAULT_CHAT_FRAME:AddMessage(string.format(
                            "|cFFFF8000RaidMount:|r Install TomTom addon for better cross-expansion waypoint support"))
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

-- Scroll frame setup
function RaidMount.SetupScrollFrameCallbacks()
    if RaidMount.ScrollFrame then
        -- Enable mouse wheel scrolling
        RaidMount.ScrollFrame:EnableMouseWheel(true)

        -- Throttled scroll update to prevent FPS drops
        local lastScrollUpdate = 0
        local scrollUpdateThrottle = 0.016 -- ~60 FPS

        RaidMount.ScrollFrame:SetScript("OnVerticalScroll", function(self, offset)
            self:SetVerticalScroll(offset)

            local currentTime = GetTime()
            if currentTime - lastScrollUpdate >= scrollUpdateThrottle then
                lastScrollUpdate = currentTime
                RaidMount.UpdateVisibleRowsOptimized()
            else
                -- Queue update for next frame
                RaidMount.ScheduleDelayedTask(scrollUpdateThrottle - (currentTime - lastScrollUpdate), function()
                    if GetTime() - lastScrollUpdate >= scrollUpdateThrottle then
                        lastScrollUpdate = GetTime()
                        RaidMount.UpdateVisibleRowsOptimized()
                    end
                end)
            end
        end)

        RaidMount.ScrollFrame:SetScript("OnMouseWheel", function(self, delta)
            local currentScroll = self:GetVerticalScroll()
            local maxScroll = math.max(0, (RaidMount.totalRows * RaidMount.rowHeight) - self:GetHeight())
            local scrollStep = RaidMount.rowHeight * 2 -- Reduced from 3 for smoother scrolling

            local newOffset = currentScroll - (delta * scrollStep)
            newOffset = math.max(0, math.min(newOffset, maxScroll))

            self:SetVerticalScroll(newOffset)

            -- Immediate update for mouse wheel (feels more responsive)
            local currentTime = GetTime()
            if currentTime - lastScrollUpdate >= scrollUpdateThrottle then
                lastScrollUpdate = currentTime
                RaidMount.UpdateVisibleRowsOptimized()
            end
        end)

        -- Ensure the scroll frame can receive mouse events
        RaidMount.ScrollFrame:EnableMouse(true)
    end
end

-- Get visible row count
function RaidMount.GetVisibleRowCount()
    local count = 0
    for _ in pairs(RaidMount.visibleRows) do
        count = count + 1
    end
    return count
end 