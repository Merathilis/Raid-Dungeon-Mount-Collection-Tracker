local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local RAIDMOUNT_PREFIX = "|cFF33CCFFRaid|r|cFFFF0000Mount|r"

-- Helper function for consistent addon messages
local function PrintAddonMessage(message, isError)
    local prefix = isError and "|cFFFF0000RaidMount Error:|r" or "|cFF33CCFFRaidMount:|r"
    print(RAIDMOUNT_PREFIX .. " " .. message)
end


RaidMountSettings = RaidMountSettings or {
    showTooltips = true,
    soundOnDrop = true,
    compactMode = false,

    filterDefault = "Uncollected",
    hasScannedCollection = false,
    debugPerformance = false,
    uiScale = 1.0
}


RaidMountAttempts = RaidMountAttempts or {}


local ADDON_VERSION = "24.06.27.03"
if not RaidMountSettings.version or RaidMountSettings.version ~= ADDON_VERSION then
    RaidMountSettings.version = ADDON_VERSION
    PrintAddonMessage("Updated to version " .. ADDON_VERSION)
end

-- Ensure mountInstances is loaded
if not RaidMount.mountInstances then
    print(RAIDMOUNT_PREFIX .. " Error:|r mountInstances is nil! Ensure MountData.lua is loaded.")
    RaidMount.mountInstances = {}
end

-- Ensure required functions exist
if not RaidMount.PlayerHasMount or not RaidMount.GetRaidLockout then
    print(RAIDMOUNT_PREFIX .. " Error:|r Required functions missing! Ensure MountCheck.lua and LockoutCheck.lua are loaded.")
    return
end

local mountInstances = RaidMount.mountInstances

-- Scan existing mount collection (for fresh installs)
local function ScanExistingMountCollection()
    if RaidMountSettings.hasScannedCollection then
        return
    end
    
    PrintAddonMessage("Scanning your mount collection for the first time...")
    
    RaidMount.RefreshMountCollection()
    
    RaidMountSettings.hasScannedCollection = true
end


local cachedPlayerInfo = nil
local function GetCachedPlayerInfo()
    if not cachedPlayerInfo then
        cachedPlayerInfo = UnitName("player") .. "-" .. GetRealmName()
    end
    return cachedPlayerInfo
end

local function InitializeAddon()
    ScanExistingMountCollection()
    
    if not RaidMountSettings.seenWelcome then
        RaidMountSettings.seenWelcome = true
        print(RAIDMOUNT_PREFIX .. " v" .. ADDON_VERSION .. " loaded! Use |cFFFFFF00/rm|r to open the mount tracker.")
    end
end


local function GetStatisticValue(statisticId)
    if not statisticId then return 0 end
    
    local value = GetStatistic(statisticId)
    if value and value ~= "--" and tonumber(value) then
        return tonumber(value)
    end
    return 0
end


local function InitializeFromStatistics()
    if not RaidMountSettings.statisticsInitialized then

        
        local initializedCount = 0
        for _, mount in ipairs(mountInstances) do
            local attemptData = RaidMountAttempts[mount.spellID]
            if attemptData and mount.statisticIds and not attemptData.statisticsInitialized then
                local maxAttempts = 0
                
                for _, statId in ipairs(mount.statisticIds) do
                    local statValue = GetStatisticValue(statId)
                    if statValue > maxAttempts then
                        maxAttempts = statValue
                    end
                end
                
                if maxAttempts > (attemptData.total or 0) then
                    attemptData.total = maxAttempts
                    attemptData.statisticsInitialized = true
                    initializedCount = initializedCount + 1
                end
            end
        end
        
        if initializedCount > 0 then
    
        end
        
        RaidMountSettings.statisticsInitialized = true
    end
end

-- Verify attempt counts against statistics (backup system)
function RaidMount.VerifyStatistics()
    
    
    local verifiedCount = 0
    local correctedCount = 0
    
    for _, mount in ipairs(mountInstances) do
        local attemptData = RaidMountAttempts[mount.spellID]
        if attemptData and mount.statisticIds then
            local maxStatValue = 0
            
            -- Get the highest statistic value for this mount
            for _, statId in ipairs(mount.statisticIds) do
                local statValue = GetStatisticValue(statId)
                if statValue > maxStatValue then
                    maxStatValue = statValue
                end
            end
            
            verifiedCount = verifiedCount + 1
            
            -- If statistics show more attempts, update our count
            if maxStatValue > (attemptData.total or 0) then
                local oldTotal = attemptData.total or 0
                attemptData.total = maxStatValue
                correctedCount = correctedCount + 1
            end
        end
    end
    
    
end

-- Enhanced attempt tracking with statistics backup
local function RecordAttemptWithStatistics(mount, characterID, currentTime)
    local trackingKey = mount.spellID
    local attemptData = RaidMountAttempts[trackingKey]
    
    if type(attemptData) ~= "table" then
        attemptData = { 
            total = 0, 
            characters = {},
            lastAttempt = nil,
            collected = false,
            statisticsInitialized = false
        }
        RaidMountAttempts[trackingKey] = attemptData
    end

    local hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
    if hasMount and not attemptData.collected then
        attemptData.collected = true
        if RaidMountSettings.soundOnDrop then
            PlaySound(8959, "Master")
        end
    end

    attemptData.total = (attemptData.total or 0) + 1
    attemptData.characters[characterID] = (attemptData.characters[characterID] or 0) + 1
    attemptData.lastAttempt = currentTime
    
    if mount.statisticIds then
        C_Timer.After(3, function()
            local maxStatValue = 0
            for _, statId in ipairs(mount.statisticIds) do
                local statValue = GetStatisticValue(statId)
                if statValue > maxStatValue then
                    maxStatValue = statValue
                end
            end
            
            if maxStatValue > attemptData.total then
                attemptData.total = maxStatValue
            end
        end)
    end
end

-- Initialize Attempts After Player Login
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_EXPANSION_LEVEL")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RaidMount" then
        -- Initialize attempts for all mounts
        for _, mount in ipairs(mountInstances) do
            if not RaidMountAttempts[mount.spellID] then
                RaidMountAttempts[mount.spellID] = {
                    total = 0,
                    characters = {},
                    lastAttempt = nil,
                    collected = false,
                    statisticsInitialized = false
                }
            end
        end
    elseif event == "PLAYER_LOGIN" or event == "UPDATE_EXPANSION_LEVEL" then
        -- Initialize after player login when statistics are available
        C_Timer.After(2, function()
            InitializeAddon()
            InitializeFromStatistics()
        end)
    end
end)

-- Enhanced Boss Kill Tracking
local bossKillFrame = CreateFrame("Frame")
bossKillFrame:RegisterEvent("BOSS_KILL")
bossKillFrame:RegisterEvent("ENCOUNTER_END")
bossKillFrame:RegisterEvent("NEW_MOUNT_ADDED")

bossKillFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "NEW_MOUNT_ADDED" then
        C_Timer.After(0.5, function()
            print(RAIDMOUNT_PREFIX .. ":|r New mount detected! Refreshing collection status...")
            RaidMount.ClearMountCache()
            RaidMount.RefreshMountCollection()
            -- Invalidate static cache since mount collection changed
            if RaidMount.InvalidateStaticData then
                RaidMount.InvalidateStaticData()
            end
        end)
        return
    end
    
    local encounterName, success
    if event == "BOSS_KILL" then
        local bossID, bossName = ...
        encounterName = bossName
        success = true
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName_temp, difficultyID, groupSize, success_temp = ...
        encounterName = encounterName_temp
        success = success_temp
        if not success then return end
    else
        return
    end

    local characterID = GetCachedPlayerInfo()
    local currentTime = time()
    local hasFoundMatch = false

    for _, mount in ipairs(mountInstances) do
        if mount.bossName == encounterName then
            hasFoundMatch = true
            
            RecordAttemptWithStatistics(mount, characterID, currentTime)
        end
    end
    
    if hasFoundMatch then
        -- Encounter processed successfully - invalidate static cache since attempt data changed
        if RaidMount.InvalidateStaticData then
            RaidMount.InvalidateStaticData()
        end
    end
end)

-- Get Attempt Count (with backward compatibility)
function RaidMount.GetAttempts(mount)
    local trackingKey
    if type(mount) == "table" then
        trackingKey = mount.spellID  -- Use Spell ID for new system
    else
        trackingKey = mount  -- Legacy: direct ID passed
    end
    
    local attempts = RaidMountAttempts[trackingKey]
    if type(attempts) == "number" then
        return attempts
    elseif type(attempts) == "table" then
        return attempts.total or 0
    end
    return 0
end

-- Get Character-specific attempts
function RaidMount.GetCharacterAttempts(mount, characterID)
    local trackingKey
    if type(mount) == "table" then
        trackingKey = mount.spellID  -- Use Spell ID for new system
    else
        trackingKey = mount  -- Legacy: direct ID passed
    end
    
    local attempts = RaidMountAttempts[trackingKey]
    if type(attempts) == "table" and attempts.characters then
        return attempts.characters[characterID] or 0
    end
    return 0
end

-- Reset Attempts
function RaidMount.ResetAttempts(mount)
    if mount then
        local trackingKey
        if type(mount) == "table" then
            trackingKey = mount.spellID  -- Use Spell ID for new system
        else
            trackingKey = mount  -- Legacy: direct ID passed
        end
        
        RaidMountAttempts[trackingKey] = {
            total = 0,
            characters = {},
            lastAttempt = nil,
            collected = false
        }
        print(RAIDMOUNT_PREFIX .. ":|r Attempts for mount ID " .. trackingKey .. " have been reset.")
    else
        -- Reset all attempts
        for id, _ in pairs(RaidMountAttempts) do
            RaidMountAttempts[id] = {
                total = 0,
                characters = {},
                lastAttempt = nil,
                collected = false
            }
        end
        print(RAIDMOUNT_PREFIX .. ":|r All attempts have been reset.")
    end
    
    -- Invalidate static cache since attempt data changed
    if RaidMount.InvalidateStaticData then
        RaidMount.InvalidateStaticData()
    end
end

-- Get Difficulty Color
function RaidMount.GetDifficultyColor(difficulty)
    local colors = {
        ["Mythic"] = "|cFFFF8000",
        ["Heroic"] = "|cFF0070DD", 
        ["Normal"] = "|cFFFFFFFF",
        ["LFR"] = "|cFF1EFF00"
    }
    return colors[difficulty] or "|cFFFFFFFF"
end

-- Get Lockout Color
function RaidMount.GetLockoutColor(raidName)
    local resetTime = RaidMount.GetRaidLockout(raidName)
    return (resetTime == "No lockout") and "|cFF00FF00" or "|cFFFF0000"
end

-- Enhanced Format Mount Data for UI
function RaidMount.GetFormattedMountData()
    local formattedData = {}
    for _, mount in ipairs(RaidMount.mountInstances) do
        local attempts = RaidMount.GetAttempts(mount)
        local trackingKey = mount.spellID  -- Use Spell ID as primary key
        local attemptData = RaidMountAttempts[trackingKey]
        local lastAttempt = nil
        local hasMount = false
        
        -- Check collection status from stored data first, then live check
        if attemptData and type(attemptData) == "table" then
            hasMount = attemptData.collected or false
            if attemptData.lastAttempt then
                lastAttempt = date("%m/%d/%y", attemptData.lastAttempt)
            end
        end
        
        -- Double-check with live mount journal if not marked as collected
        if not hasMount then
            hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
            -- Update stored data if we found it's actually collected
            if hasMount and attemptData then
                attemptData.collected = true
            end
        end
        
        table.insert(formattedData, {
            raidName = mount.raidName or "Unknown",
            bossName = mount.bossName or "Unknown",
            mountName = mount.mountName or "Unknown",
            location = mount.location or "Unknown",
            dropRate = mount.dropRate or "~1%",
            resetTime = RaidMount.GetRaidLockout(mount.raidName),
            difficulty = mount.difficulty or "Unknown",
            expansion = mount.expansion or "Unknown",
            collected = hasMount,
            attempts = attempts,
            lastAttempt = lastAttempt,
            mountID = mount.MountID,
            spellID = mount.spellID,
            itemID = mount.itemID,
            type = "Raid"
        })
    end
    return formattedData
end

-- Settings functions
function RaidMount.GetSetting(key)
    return RaidMountSettings[key]
end

function RaidMount.SetSetting(key, value)
    RaidMountSettings[key] = value
end

-- Slash command handler
SLASH_RAIDMOUNT1 = "/rm"

SlashCmdList["RAIDMOUNT"] = function(msg)
    local command = msg:lower():trim()
    
    if command == "" then
        RaidMount.ShowUI()
    else
        -- Only show UI for any other command
        RaidMount.ShowUI()
    end
end

-- Function to show boss drop mounts in a copyable window
function RaidMount.ShowDropMountWindow(dropMounts)
    -- Create the window if it doesn't exist
    if not RaidMount.DropMountFrame then
        RaidMount.DropMountFrame = CreateFrame("Frame", "RaidMountDropFrame", UIParent, "BasicFrameTemplateWithInset")
        RaidMount.DropMountFrame:SetSize(600, 500)
        RaidMount.DropMountFrame:SetPoint("CENTER")
        RaidMount.DropMountFrame:SetMovable(true)
        RaidMount.DropMountFrame:EnableMouse(true)
        RaidMount.DropMountFrame:RegisterForDrag("LeftButton")
        RaidMount.DropMountFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
        RaidMount.DropMountFrame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
        
        -- Title
        RaidMount.DropMountFrame.title = RaidMount.DropMountFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
        RaidMount.DropMountFrame.title:SetPoint("TOP", 0, -10)
        RaidMount.DropMountFrame.title:SetText("Boss Drop Mounts - Spell IDs")
        
        -- Subtitle
        RaidMount.DropMountFrame.subtitle = RaidMount.DropMountFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        RaidMount.DropMountFrame.subtitle:SetPoint("TOP", 0, -30)
        RaidMount.DropMountFrame.subtitle:SetTextColor(0.8, 0.8, 0.8, 1)
        
        -- Create scroll frame
        local scrollFrame = CreateFrame("ScrollFrame", nil, RaidMount.DropMountFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", 10, -50)
        scrollFrame:SetPoint("BOTTOMRIGHT", -30, 40)
        
        -- Create edit box for copyable text
        local editBox = CreateFrame("EditBox", nil, scrollFrame)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetWidth(550)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        
        scrollFrame:SetScrollChild(editBox)
        RaidMount.DropMountFrame.editBox = editBox
        
        -- Close button
        local closeButton = CreateFrame("Button", nil, RaidMount.DropMountFrame, "UIPanelButtonTemplate")
        closeButton:SetSize(80, 25)
        closeButton:SetPoint("BOTTOMRIGHT", -20, 10)
        closeButton:SetText("Close")
        closeButton:SetScript("OnClick", function()
            -- Clean up header frame before hiding
            if RaidMount.HeaderFrame then
                RaidMount.HeaderFrame:Hide()
                RaidMount.HeaderFrame:SetParent(nil)
                RaidMount.HeaderFrame = nil
            end
            RaidMount.DropMountFrame:Hide()
        end)
        
        -- Select All button
        local selectButton = CreateFrame("Button", nil, RaidMount.DropMountFrame, "UIPanelButtonTemplate")
        selectButton:SetSize(80, 25)
        selectButton:SetPoint("RIGHT", closeButton, "LEFT", -10, 0)
        selectButton:SetText("Select All")
        selectButton:SetScript("OnClick", function()
            RaidMount.DropMountFrame.editBox:SetFocus()
            RaidMount.DropMountFrame.editBox:HighlightText()
        end)
    end
    
    -- Build the text content
    local textContent = string.format("Boss Drop Mounts from Mount Journal (%d total)\n", #dropMounts)
    textContent = textContent .. "Format: [Status] Mount Name (MountID: X, SpellID: Y)\n"
    textContent = textContent .. "Status: ✓ = Collected, ✗ = Not Collected\n\n"
    
    for _, mount in ipairs(dropMounts) do
        local statusIcon = mount.isCollected and "✓" or "✗"
        textContent = textContent .. string.format("%s %s (MountID: %d, SpellID: %d)\n", 
            statusIcon, mount.name, mount.MountID, mount.spellID)
    end
    
    -- Set the text and adjust height
    RaidMount.DropMountFrame.editBox:SetText(textContent)
    RaidMount.DropMountFrame.editBox:SetHeight(math.max(400, #dropMounts * 15 + 100))
    
    -- Show the window
    RaidMount.DropMountFrame:Show()
    
    print(RAIDMOUNT_PREFIX .. ":|r Found " .. #dropMounts .. " boss drop mounts. Window opened for easy copying!")
end

-- Removed PrintHelp function - all functionality moved to settings UI

-- Performance monitoring system
RaidMount.performanceStats = RaidMount.performanceStats or {
    tooltipCache = {hits = 0, misses = 0},
    textureCache = {hits = 0, misses = 0},
    updateCount = 0,
    lastUpdateTime = 0,
    frameTime = 0
}
local performanceStats = RaidMount.performanceStats

function RaidMount.GetPerformanceStats()
    local stats = {
        tooltipCache = RaidMount.GetTooltipCacheStats(),
        textureCache = {
            size = RaidMount.textureCache and #RaidMount.textureCache or 0,
            hits = performanceStats.textureCache.hits,
            misses = performanceStats.textureCache.misses
        },
        updates = performanceStats.updateCount,
        frameTime = performanceStats.frameTime
    }
    return stats
end

function RaidMount.ResetPerformanceStats()
    performanceStats = {
        tooltipCache = {hits = 0, misses = 0},
        textureCache = {hits = 0, misses = 0},
        updateCount = 0,
        lastUpdateTime = 0,
        frameTime = 0
    }
    RaidMount.ClearTooltipCache()
end





