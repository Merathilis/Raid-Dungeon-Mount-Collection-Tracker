-- Filters and search module for RaidMount UI
local addonName, RaidMount = ...

-- Import utilities
local COLORS = RaidMount.COLORS
local CreateStandardFontString = RaidMount.CreateStandardFontString
local PrintAddonMessage = RaidMount.PrintAddonMessage

-- Cache frequently accessed values
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- CREATE SEARCH AND FILTER COMPONENTS
function RaidMount.CreateSearchAndFilters()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Search box
    local searchBox = CreateFrame("EditBox", "RaidMountSearchBox", frame)
    searchBox:SetSize(250, 30)
    searchBox:SetPoint("TOPLEFT", 20, -70)
    searchBox:SetAutoFocus(false)
    searchBox:SetFontObject("ChatFontNormal")
    searchBox:SetTextInsets(10, 10, 0, 0)
    
    local editBg = searchBox:CreateTexture(nil, "BACKGROUND")
    editBg:SetAllPoints()
    editBg:SetColorTexture(0.05, 0.05, 0.1, 0.9)
    
    local placeholder = "Search mounts, raids, or bosses..."
    searchBox:SetText(placeholder)
    searchBox:SetTextColor(0.6, 0.6, 0.6, 1)
    
    searchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == placeholder then
            self:SetText("")
            self:SetTextColor(1, 1, 1, 1)
        end
    end)
    
    searchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText(placeholder)
            self:SetTextColor(0.6, 0.6, 0.6, 1)
        end
    end)
    
    searchBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput and self:GetText() ~= placeholder then
            RaidMount.currentSearch = self:GetText():lower()
            C_Timer.After(0.2, function() -- Reduced delay for faster response
                if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
                    RaidMount.PopulateUI()
                end
            end)
        elseif self:GetText() == "" or self:GetText() == placeholder then
            RaidMount.currentSearch = ""
            if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() and not RaidMount.isStatsView then
                RaidMount.PopulateUI()
            end
        end
    end)
    
    RaidMount.SearchBox = searchBox
    
    -- Create filter dropdowns
    RaidMount.CreateFilterDropdowns()
end

-- CREATE FILTER DROPDOWNS
function RaidMount.CreateFilterDropdowns()
    local frame = RaidMount.RaidMountFrame
    if not frame then return end
    
    -- Status filter
    local collectedDropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", frame, "UIDropDownMenuTemplate")
    collectedDropdown:SetPoint("TOPLEFT", 300, -65)
    UIDropDownMenu_Initialize(collectedDropdown, function()
        local options = {"All", "Collected", "Uncollected"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(collectedDropdown, option)
                UIDropDownMenu_SetText(collectedDropdown, option)
                RaidMount.currentFilter = option
                if not RaidMount.isStatsView then 
                    C_Timer.After(0.1, function() -- Small delay to ensure UI updates
                        RaidMount.PopulateUI() 
                    end)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedName(collectedDropdown, "All")
    UIDropDownMenu_SetText(collectedDropdown, "All")
    UIDropDownMenu_SetWidth(collectedDropdown, 150)
    RaidMount.CollectedDropdown = collectedDropdown
    
    -- Expansion filter
    local expansionDropdown = CreateFrame("Frame", "RaidMountExpansionDropdown", frame, "UIDropDownMenuTemplate")
    expansionDropdown:SetPoint("TOPLEFT", 500, -65)
    UIDropDownMenu_Initialize(expansionDropdown, function()
        local options = {"All", "Classic", "The Burning Crusade", "Wrath of the Lich King", "Cataclysm", "Mists of Pandaria", "Warlords of Draenor", "Legion", "Battle for Azeroth", "Shadowlands", "Dragonflight", "The War Within", "Holiday Event"}
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(expansionDropdown, option)
                UIDropDownMenu_SetText(expansionDropdown, option)
                RaidMount.currentExpansionFilter = option
                if not RaidMount.isStatsView then 
                    C_Timer.After(0.1, function() -- Small delay to ensure UI updates
                        RaidMount.PopulateUI() 
                    end)
                end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    UIDropDownMenu_SetSelectedName(expansionDropdown, "All")
    UIDropDownMenu_SetText(expansionDropdown, "All")
    UIDropDownMenu_SetWidth(expansionDropdown, 180)
    RaidMount.ExpansionDropdown = expansionDropdown
end

-- FILTER AND SORT MOUNT DATA
function RaidMount.FilterAndSortMountData(mountData)
    local filtered = {}
    local debugCounts = {total = 0, collected = 0, uncollected = 0, filtered = 0}
    
    for _, mount in ipairs(mountData) do
        local includeMount = true
        debugCounts.total = debugCounts.total + 1
        
        -- Debug collection status
        if mount.collected then
            debugCounts.collected = debugCounts.collected + 1
        else
            debugCounts.uncollected = debugCounts.uncollected + 1
        end
        
        -- Filter by collection status (improved logic)
        if RaidMount.currentFilter == "Collected" then
            if not mount.collected then
                includeMount = false
            end
        elseif RaidMount.currentFilter == "Uncollected" then
            if mount.collected then
                includeMount = false
            end
        end
        
        -- Filter by expansion (improved matching)
        if RaidMount.currentExpansionFilter ~= "All" then
            local mountExpansion = mount.expansion or "Unknown"
            if mountExpansion ~= RaidMount.currentExpansionFilter then
                includeMount = false
            end
        end
        
        -- Filter by search text (improved search)
        if RaidMount.currentSearch and RaidMount.currentSearch ~= "" and RaidMount.currentSearch ~= "search mounts, raids, or bosses..." then
            local searchText = RaidMount.currentSearch:lower()
            local mountText = (mount.mountName or ""):lower() .. " " .. 
                            (mount.raidName or ""):lower() .. " " .. 
                            (mount.bossName or ""):lower() .. " " ..
                            (mount.location or ""):lower() .. " " ..
                            (mount.expansion or ""):lower() .. " " ..
                            (mount.difficulty or ""):lower()
            
            -- Support partial matching (e.g., "ony" matches "Onyxian")
            local found = false
            for word in searchText:gmatch("%S+") do
                if mountText:find(word, 1, true) then
                    found = true
                    break
                end
            end
            
            if not found then
                includeMount = false
            end
        end
        
        if includeMount then
            table.insert(filtered, mount)
            debugCounts.filtered = debugCounts.filtered + 1
        end
    end
    
    -- Debug output for troubleshooting
    if RaidMount.currentFilter ~= "All" or RaidMount.currentExpansionFilter ~= "All" or (RaidMount.currentSearch and RaidMount.currentSearch ~= "") then
        -- Removed for production
    end
    
    -- Sort data
    table.sort(filtered, function(a, b)
        local aVal = a[RaidMount.sortColumn] or ""
        local bVal = b[RaidMount.sortColumn] or ""
        if RaidMount.sortDescending then
            return aVal > bVal
        else
            return aVal < bVal
        end
    end)
    
    return filtered
end

-- UPDATE MOUNT COUNTS
function RaidMount.UpdateMountCounts()
    local totalMounts, collectedMounts = 0, 0
    local combinedData = RaidMount.GetCombinedMountData()

    for _, mount in ipairs(combinedData) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    local percentage = totalMounts > 0 and (collectedMounts / totalMounts) * 100 or 0
    
    if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame.progressBar then
        local bar = RaidMount.RaidMountFrame.progressBar
        bar:SetMinMaxValues(0, totalMounts)
        bar:SetValue(collectedMounts)
        bar.label:SetText(string.format("%d / %d (%.1f%%)", collectedMounts, totalMounts, percentage))
        bar.collected = collectedMounts
        bar.total = totalMounts
    end
end 