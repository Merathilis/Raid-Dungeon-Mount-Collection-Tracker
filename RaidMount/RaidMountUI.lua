local addonName, RaidMount = ...
RaidMount = RaidMount or {}
DungeonMountData = DungeonMountData or {}

if not RaidMount then
    print("ERROR: RaidMount table is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
    return
end

-- ✅ Initialize global table for attempts
if not RaidMountAttempts then
    RaidMountAttempts = {}
end

-- ✅ Main Frame
if not RaidMount.RaidMountFrame then
    RaidMount.RaidMountFrame = CreateFrame("Frame", "RaidMountFrame", UIParent, "BasicFrameTemplateWithInset")
    RaidMount.RaidMountFrame:SetSize(1000, 550)
    RaidMount.RaidMountFrame:SetPoint("CENTER")
    RaidMount.RaidMountFrame:SetMovable(true)
    RaidMount.RaidMountFrame:EnableMouse(true)
    RaidMount.RaidMountFrame:RegisterForDrag("LeftButton")
    RaidMount.RaidMountFrame:SetClampedToScreen(true)
    RaidMount.RaidMountFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    RaidMount.RaidMountFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    -- Centered Title
    RaidMount.RaidMountFrame.title = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    RaidMount.RaidMountFrame.title:SetPoint("TOP", RaidMount.RaidMountFrame, "TOP", 0, -10)
    RaidMount.RaidMountFrame.title:SetText("Raid & Dungeon Mount Collection Tracker")
    RaidMount.RaidMountFrame:Hide()
end

-- ✅ Total Mounts and Collected Mounts Display
local function UpdateMountCounts()
    local totalMounts, collectedMounts = 0, 0

    -- ✅ Safety check for GetFormattedMountData
    if not RaidMount.GetFormattedMountData then
        print("❌ ERROR: GetFormattedMountData is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
        return
    end

    for _, mount in ipairs(RaidMount.GetFormattedMountData()) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    for _, mount in ipairs(DungeonMountData) do
        totalMounts = totalMounts + 1
        if mount.collected then
            collectedMounts = collectedMounts + 1
        end
    end

    if not RaidMount.RaidMountFrame.mountCountText then
        RaidMount.RaidMountFrame.mountCountText = RaidMount.RaidMountFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        RaidMount.RaidMountFrame.mountCountText:SetPoint("TOPLEFT", RaidMount.RaidMountFrame, "TOPLEFT", 15, -35)
    end

    RaidMount.RaidMountFrame.mountCountText:SetText("|cFFFFFF00Total Mounts:|r " .. totalMounts .. " |cFFFFFF00Collected:|r " .. collectedMounts)
end

-- ✅ ScrollFrame
RaidMount.ScrollFrame = CreateFrame("ScrollFrame", nil, RaidMount.RaidMountFrame, "UIPanelScrollFrameTemplate")
RaidMount.ScrollFrame:SetPoint("TOPLEFT", 10, -60)
RaidMount.ScrollFrame:SetPoint("BOTTOMRIGHT", -10, 10)

-- ✅ Content Frame
RaidMount.ContentFrame = CreateFrame("Frame", nil, RaidMount.ScrollFrame)
RaidMount.ContentFrame:SetSize(980, 480)
RaidMount.ScrollFrame:SetScrollChild(RaidMount.ContentFrame)

-- ✅ Filter Dropdown (All, Collected, Uncollected)
local currentFilter = "Uncollected"

local function CreateCollectedFilterDropdown(defaultFilter)
    local dropdown = CreateFrame("Frame", "RaidMountCollectedDropdown", RaidMount.RaidMountFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPRIGHT", RaidMount.RaidMountFrame, "TOPRIGHT", -10, -10)

    local filters = { "All", "Collected", "Uncollected" }

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        for _, filter in ipairs(filters) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = filter
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, filter)
                currentFilter = filter
                RaidMount.PopulateUI(filter)
            end
            UIDropDownMenu_AddButton(info)
        end
    end)

    UIDropDownMenu_SetSelectedName(dropdown, defaultFilter or "Uncollected")
    UIDropDownMenu_SetWidth(dropdown, 150)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
end

-- ✅ Get Lockout Color and Timer (d h m format)
function RaidMount.GetLockoutColor(instanceName, isRaid)
    if not isRaid then
        return "|cFF00FF00", "", false
    end

    for i = 1, GetNumSavedInstances() do
        local name, _, reset, _, locked, extended = GetSavedInstanceInfo(i)
        if name == instanceName then
            if locked or extended then
                local days = math.floor(reset / 86400)
                local hours = math.floor((reset % 86400) / 3600)
                local minutes = math.floor((reset % 3600) / 60)
                return "|cFFFF0000", string.format("%dd %dh %dm", days, hours, minutes), true
            end
        end
    end

    return "|cFF00FF00", "", false
end

-- ✅ Difficulty Color
function RaidMount.GetDifficultyColor(difficulty)
    if difficulty == "Mythic" then
        return "|cFFFFA500"
    elseif difficulty == "Heroic" then
        return "|cFF0000FF"
    else
        return "|cFFFFFFFF"
    end
end

-- ✅ CreateTextElement with Tooltip Support
local function CreateTextElement(text, xOffset, yOffset, width, color, mount, lockoutStatus)
    local element = RaidMount.ContentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    element:SetPoint("TOPLEFT", xOffset, yOffset)
    element:SetWidth(width)
    element:SetJustifyH("LEFT")
    element:SetText(color .. text .. "|r")

    -- ✅ Attach Tooltip
    element:SetScript("OnEnter", function(self)
        if not mount then
            print("❌ ERROR: No mount data passed to tooltip.")
            return
        end
        if RaidMount.ShowTooltip then
            RaidMount.ShowTooltip(self, mount, lockoutStatus)
        else
            print("ERROR: Tooltip function not found.")
        end
    end)

    element:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    return element
end

-- ✅ Populate UI with Proper Layout, Colors, and Filters
function RaidMount.PopulateUI(filterType)
    local combinedData = {}

    -- ✅ Ensure GetFormattedMountData exists before calling
    if not RaidMount.GetFormattedMountData then
        print("❌ ERROR: GetFormattedMountData is nil. Ensure RaidMount.lua is loaded before RaidMountUI.lua.")
        return
    end

    -- ✅ Combine Raid and Dungeon Data
    for _, raidMount in ipairs(RaidMount.GetFormattedMountData()) do
        raidMount.type = "Raid"
        table.insert(combinedData, raidMount)
    end

    for _, dungeonMount in ipairs(DungeonMountData) do
        dungeonMount.type = "Dungeon"
        table.insert(combinedData, dungeonMount)
    end

    -- ✅ Clear existing lines
    RaidMount.ContentFrame.textLines = RaidMount.ContentFrame.textLines or {}
    for _, line in ipairs(RaidMount.ContentFrame.textLines) do
        line:Hide()
    end
    RaidMount.ContentFrame.textLines = {}

    local startY = -10  -- Starting Y-axis position

    for _, mount in ipairs(combinedData) do
        local isRaid = (mount.type == "Raid")
        local lockoutColor, lockoutStatus, isLocked = RaidMount.GetLockoutColor(mount.raidName or mount.dungeonName, isRaid)
        local difficultyColor = RaidMount.GetDifficultyColor(mount.difficulty)
        local collectedColor = mount.collected and "|cFFAA00FF" or lockoutColor

        local totalAttempts = 0
        if type(mount.attempts) == "number" then
            totalAttempts = mount.attempts
        elseif type(mount.attempts) == "table" then
            for _, count in pairs(mount.attempts) do
                if type(count) == "number" then
                    totalAttempts = totalAttempts + count
                end
            end
        end

        -- ✅ Apply Filter (All, Collected, Uncollected)
        local showMount = true
        if filterType == "Collected" and not mount.collected then
            showMount = false
        elseif filterType == "Uncollected" and mount.collected then
            showMount = false
        end

        if showMount then
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement(mount.type, 10, startY, 60, "|cFFFFFFFF", mount, lockoutStatus))
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement(mount.raidName or mount.dungeonName, 80, startY, 200, lockoutColor, mount, lockoutStatus))
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement(mount.mountName or "Unknown", 290, startY, 200, collectedColor, mount, lockoutStatus))
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement(mount.difficulty or "Any", 500, startY, 100, difficultyColor, mount, lockoutStatus))
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement("Attempts: " .. totalAttempts, 620, startY, 70, "|cFFFFFF00", mount, lockoutStatus))

            local resetColor = isLocked and "|cFFFF0000" or "|cFFFFD700"
            table.insert(RaidMount.ContentFrame.textLines, CreateTextElement(lockoutStatus, 750, startY, 80, resetColor, mount, lockoutStatus))

            startY = startY - 20
        end
    end

    RaidMount.ContentFrame:SetHeight(math.abs(startY) + 40)
end

-- ✅ Slash Command
SLASH_RAIDMOUNT1 = "/rm"
SlashCmdList["RAIDMOUNT"] = function()
    if not RaidMount.RaidMountFrame then
        print("ERROR: RaidMount UI did not load correctly.")
        return
    end

    if RaidMount.RaidMountFrame:IsShown() then
        RaidMount.RaidMountFrame:Hide()
    else
        RaidMount.PopulateUI("Uncollected")
        CreateCollectedFilterDropdown("Uncollected")
        RaidMount.RaidMountFrame:Show()
    end
end
