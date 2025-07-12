local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local RAIDMOUNT_PREFIX = "|cFF33CCFFRaid|r|cFFFF0000Mount|r"

local function PrintAddonMessage(message, isError)
end


RaidMountAttempts = RaidMountAttempts or {}

local ADDON_VERSION = "12.07.25.25"
PrintAddonMessage("Updated to version " .. ADDON_VERSION)

local function ScanExistingMountCollection()
    PrintAddonMessage(RaidMount.L("SCANNING_FIRST_TIME"))
    RaidMount.RefreshMountCollection()
end


local cachedPlayerInfo = nil
local function GetCachedPlayerInfo()
    if not cachedPlayerInfo then
        cachedPlayerInfo = UnitName("player") .. "-" .. GetRealmName()
    end
    return cachedPlayerInfo
end

-- Session tracking
local currentSessionID = 1
local lastSessionTime = 0
local SESSION_TIMEOUT = 3600 -- 1 hour timeout for new session

-- Initialize session tracking
local function InitializeSessionTracking()
    if not RaidMountSaved then
        RaidMountSaved = {}
    end
    if not RaidMountSaved.currentSessionID then
        RaidMountSaved.currentSessionID = 1
    end
    if not RaidMountSaved.lastSessionTime then
        RaidMountSaved.lastSessionTime = 0
    end
    currentSessionID = RaidMountSaved.currentSessionID
    lastSessionTime = RaidMountSaved.lastSessionTime
end

-- Check if we need a new session
local function CheckNewSession()
    local currentTime = time()
    if currentTime - lastSessionTime > SESSION_TIMEOUT then
        currentSessionID = currentSessionID + 1
        lastSessionTime = currentTime
        RaidMountSaved.currentSessionID = currentSessionID
        RaidMountSaved.lastSessionTime = lastSessionTime
    end
end

local function InitializeAddon()
    if not RaidMount.mountInstances or not RaidMount.Coordinates then
        C_Timer.After(1, InitializeAddon)
        return
    end

    if not RaidMount.PlayerHasMount or not RaidMount.GetRaidLockout then
        C_Timer.After(1, InitializeAddon)
        return
    end

    if not RaidMountSaved then RaidMountSaved = {} end
    if RaidMountSaved.enhancedTooltip == nil then
        RaidMountSaved.enhancedTooltip = true
    end
    RaidMountTooltipEnabled = RaidMountSaved.enhancedTooltip
    
    -- Initialize session tracking
    InitializeSessionTracking()
    
    ScanExistingMountCollection()
    PrintAddonMessage(RaidMount.L("LOADED_MESSAGE", ADDON_VERSION))
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
    local initializedCount = 0
    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local attemptData = RaidMountAttempts[mount.spellID]
        local statisticsToCheck = mount.statisticIds
        
        if mount.statisticIdsByDifficulty then
            statisticsToCheck = {}
            for _, diffStats in pairs(mount.statisticIdsByDifficulty) do
                for _, statId in ipairs(diffStats) do
                    table.insert(statisticsToCheck, statId)
                end
            end
        end
        
        if attemptData and statisticsToCheck and not attemptData.statisticsInitialized then
            local maxAttempts = 0
            
            for _, statId in ipairs(statisticsToCheck) do
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
end

function RaidMount.VerifyStatistics()
    local verifiedCount = 0
    local correctedCount = 0
    local corrections = {}
    
    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local attemptData = RaidMountAttempts[mount.spellID]
        local statisticsToCheck = mount.statisticIds
        
        if mount.statisticIdsByDifficulty then
            statisticsToCheck = {}
            for _, diffStats in pairs(mount.statisticIdsByDifficulty) do
                for _, statId in ipairs(diffStats) do
                    table.insert(statisticsToCheck, statId)
                end
            end
        end
        
        if attemptData and statisticsToCheck then
            local maxStatValue = 0
            local usedStatId = nil
            
            for _, statId in ipairs(statisticsToCheck) do
                local statValue = GetStatisticValue(statId)
                if statValue > maxStatValue then
                    maxStatValue = statValue
                    usedStatId = statId
                end
            end
            
            verifiedCount = verifiedCount + 1
            
            if maxStatValue > (attemptData.total or 0) then
                local oldTotal = attemptData.total or 0
                attemptData.total = maxStatValue
                correctedCount = correctedCount + 1
                
                table.insert(corrections, {
                    mountName = mount.mountName,
                    oldTotal = oldTotal,
                    newTotal = maxStatValue,
                    statId = usedStatId
                })
            end
        end
    end
    
    return {
        verified = verifiedCount,
        corrected = correctedCount,
        corrections = corrections
    }
end

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
        PlaySound(8959, "Master")
    end

    attemptData.total = (attemptData.total or 0) + 1
    attemptData.characters[characterID] = (attemptData.characters[characterID] or 0) + 1
    attemptData.classes = attemptData.classes or {}
    attemptData.classes[characterID] = select(2, UnitClass("player"))
    attemptData.lastAttemptDates = attemptData.lastAttemptDates or {}
    attemptData.lastAttemptDates[characterID] = date("%d/%m/%y")
    attemptData.lastAttempt = currentTime
    
    local statisticsToCheck = mount.statisticIds
    if mount.statisticIdsByDifficulty then
        local difficultyID = select(3, GetInstanceInfo())
        local difficultyName = "Normal"
        if difficultyID == 17 then difficultyName = "LFR"
        elseif difficultyID == 14 then difficultyName = "Normal"
        elseif difficultyID == 15 then difficultyName = "Heroic"
        elseif difficultyID == 16 then difficultyName = "Mythic"
        end
        
        if mount.statisticIdsByDifficulty[difficultyName] then
            statisticsToCheck = mount.statisticIdsByDifficulty[difficultyName]
        end
    end
    
    if statisticsToCheck then
        C_Timer.After(3, function()
            local maxStatValue = 0
            for _, statId in ipairs(statisticsToCheck) do
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
local function ShowVersionMessage()
    print("|cFF33CCFFRaid|r|cFFFF0000Mount|r v" .. ADDON_VERSION)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("UPDATE_EXPANSION_LEVEL")
eventFrame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "RaidMount" then
        InitializeAddon()
    elseif event == "PLAYER_LOGIN" then
        ShowVersionMessage()
    end
end)

-- Enhanced Boss Kill Tracking
local bossKillFrame = CreateFrame("Frame")
bossKillFrame:RegisterEvent("BOSS_KILL")
bossKillFrame:RegisterEvent("ENCOUNTER_END")
bossKillFrame:RegisterEvent("NEW_MOUNT_ADDED")

bossKillFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "NEW_MOUNT_ADDED" then
        return
    end
    
    local encounterName, success, difficultyID
    if event == "BOSS_KILL" then
        local bossID, bossName = ...
        encounterName = bossName
        success = true
        difficultyID = select(3, GetInstanceInfo()) -- Get current difficulty
    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName_temp, difficultyID_temp, groupSize, success_temp = ...
        encounterName = encounterName_temp
        difficultyID = difficultyID_temp
        success = success_temp
        if not success then return end
    else
        return
    end

    local characterID = GetCachedPlayerInfo()
    local currentTime = time()
    local hasFoundMatch = false

    -- Convert difficulty ID to string for comparison
    local difficultyName = "Normal"
    if difficultyID == 17 then difficultyName = "LFR"
    elseif difficultyID == 14 then difficultyName = "Normal"
    elseif difficultyID == 15 then difficultyName = "Heroic"
    elseif difficultyID == 16 then difficultyName = "Mythic"
    end

    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local bossToMatch = mount.bossName
        
        -- Check if this mount has difficulty-specific boss names
        if mount.bossNameByDifficulty and mount.bossNameByDifficulty[difficultyName] then
            bossToMatch = mount.bossNameByDifficulty[difficultyName]
        end
        
        if bossToMatch == encounterName then
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

-- Get current session ID
function RaidMount.GetCurrentSessionID()
    CheckNewSession()
    return currentSessionID
end

-- Record Attempt (Enhanced with session tracking)
function RaidMount.RecordBossAttempt(encounterName, difficultyName)
    -- Get current difficulty if not provided
    if not difficultyName then
        local difficultyID = select(3, GetInstanceInfo())
        difficultyName = "Normal"
        if difficultyID == 17 then difficultyName = "LFR"
        elseif difficultyID == 14 then difficultyName = "Normal"
        elseif difficultyID == 15 then difficultyName = "Heroic"
        elseif difficultyID == 16 then difficultyName = "Mythic"
        end
    end
    if not encounterName then return end
    
    CheckNewSession()
    
    for _, mount in ipairs(RaidMount.mountInstances or {}) do
        local bossToMatch = mount.bossName
        
        -- Check if this mount has difficulty-specific boss names
        if mount.bossNameByDifficulty and mount.bossNameByDifficulty[difficultyName] then
            bossToMatch = mount.bossNameByDifficulty[difficultyName]
        end
        
        if bossToMatch and bossToMatch == encounterName then
            local trackingKey = mount.spellID
            if not RaidMountAttempts[trackingKey] then
                RaidMountAttempts[trackingKey] = {
                    total = 0,
                    characters = {},
                    lastAttempt = nil,
                    collected = false,
                    sessionHistory = {} -- New: session-based attempt history
                }
            end
            
            local charKey = UnitName("player") .. "-" .. GetRealmName()
            RaidMountAttempts[trackingKey].total = (RaidMountAttempts[trackingKey].total or 0) + 1
            RaidMountAttempts[trackingKey].characters[charKey] = (RaidMountAttempts[trackingKey].characters[charKey] or 0) + 1
            
            -- Add/update class info for this character
            RaidMountAttempts[trackingKey].classes = RaidMountAttempts[trackingKey].classes or {}
            RaidMountAttempts[trackingKey].classes[charKey] = select(2, UnitClass("player")) -- e.g., "DRUID"
            
            -- Add/update per-character last attempt date in UK format
            RaidMountAttempts[trackingKey].lastAttemptDates = RaidMountAttempts[trackingKey].lastAttemptDates or {}
            RaidMountAttempts[trackingKey].lastAttemptDates[charKey] = date("%d/%m/%y")
            RaidMountAttempts[trackingKey].lastAttempt = time()
            
            -- Session history tracking
            if not RaidMountAttempts[trackingKey].sessionHistory then
                RaidMountAttempts[trackingKey].sessionHistory = {}
            end
            RaidMountAttempts[trackingKey].sessionHistory[currentSessionID] = (RaidMountAttempts[trackingKey].sessionHistory[currentSessionID] or 0) + 1
            
            if RaidMount.PopulateUI then RaidMount.PopulateUI() end
        end
    end
end

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
                lastAttempt = date("%d/%m/%y", attemptData.lastAttempt)
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
        
        local lockoutInfo = RaidMount.GetRaidLockout(mount.raidName)
        table.insert(formattedData, {
            raidName = mount.raidName or RaidMount.L("UNKNOWN"),
            bossName = mount.bossName or RaidMount.L("UNKNOWN"),
            mountName = mount.mountName or RaidMount.L("UNKNOWN"),
            location = mount.location or RaidMount.L("UNKNOWN"),
            dropRate = mount.dropRate or "~1%",
            resetTime = lockoutInfo,
            lockoutStatus = lockoutInfo,
            difficulty = mount.difficulty or RaidMount.L("UNKNOWN"),
            expansion = mount.expansion or RaidMount.L("UNKNOWN"),
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



-- Slash command handler
SLASH_RAIDMOUNT1 = "/rm"

SlashCmdList["RAIDMOUNT"] = function(msg)
    local command = msg:lower():trim()
    
    if command == "" then
        RaidMount.ShowUI()
    elseif command == "help" then
        RaidMount.ShowHelpCommands()
    elseif command == "stats" then
        RaidMount.ShowStatsCommand()
    elseif command == "reset" then
        RaidMount.ResetCommand()
    elseif command == "refresh" then
        RaidMount.RefreshCommand()
    elseif command == "verify" then
        RaidMount.VerifyCommand()
    elseif command == "debug" or command == "debugcoords" then
        if RaidMount.DebugCoordinates then
            RaidMount.DebugCoordinates()
        else
            print("Debug function not available")
        end
    elseif command == "version" then
        print("|cFF33CCFFRaid|r|cFFFF0000Mount|r v" .. ADDON_VERSION)
    else
        PrintAddonMessage(RaidMount.L("UNKNOWN_COMMAND", command), true)
    end
end

-- Show help commands
function RaidMount.ShowHelpCommands()
    PrintAddonMessage(RaidMount.L("HELP_TITLE"), false)
    print("|cFFFFFF00/rm|r - " .. RaidMount.L("HELP_OPEN"))
    print("|cFFFFFF00/rm help|r - " .. RaidMount.L("HELP_HELP"))
    print("|cFFFFFF00/rm stats|r - " .. RaidMount.L("HELP_STATS"))
    print("|cFFFFFF00/rm reset|r - " .. RaidMount.L("HELP_RESET"))
    print("|cFFFFFF00/rm refresh|r - " .. RaidMount.L("HELP_REFRESH"))
    print("|cFFFFFF00/rm verify|r - " .. RaidMount.L("HELP_VERIFY"))
end

-- Show stats command
function RaidMount.ShowStatsCommand()
    if not RaidMount.RaidMountFrame then
        RaidMount.CreateMainFrame()
    end
    
    RaidMount.RaidMountFrame:Show()
    RaidMount.isStatsView = true
    
    if RaidMount.ShowDetailedStatsView then
        RaidMount.ShowDetailedStatsView()
        PrintAddonMessage("Statistics view displayed.", false)
    else
        PrintAddonMessage("Statistics view not available.", true)
    end
end

-- Reset command with confirmation
function RaidMount.ResetCommand()
    if not RaidMount.resetConfirmationPending then
        RaidMount.resetConfirmationPending = true
        PrintAddonMessage(RaidMount.L("RESET_CONFIRMATION"), true)
        PrintAddonMessage(RaidMount.L("RESET_CONFIRM_AGAIN"), false)
        
        C_Timer.After(10, function()
            RaidMount.resetConfirmationPending = false
        end)
    else
        RaidMount.resetConfirmationPending = false
        RaidMount.ResetAttempts()
        PrintAddonMessage(RaidMount.L("RESET_COMPLETE"), false)
        
        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    end
end

-- Refresh command
function RaidMount.RefreshCommand()
    if RaidMount.RefreshMountCollection then
        RaidMount.RefreshMountCollection()
        PrintAddonMessage(RaidMount.L("REFRESH_COMPLETE"), false)
        
        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    else
        PrintAddonMessage("Refresh function not available.", true)
    end
end

-- Verify command
function RaidMount.VerifyCommand()
    if RaidMount.VerifyStatistics then
        local results = RaidMount.VerifyStatistics()
        
        if results.verified == 0 then
            print("No mounts with Blizzard statistics found to verify.")
        else
            print(string.format("Verified %d mounts against Blizzard statistics.", results.verified))
            
            if results.corrected > 0 then
                print(string.format("Updated %d mount(s) with higher attempt counts from Blizzard data:", results.corrected))
                for _, correction in ipairs(results.corrections) do
                    print(string.format("  %s: %d → %d attempts (Stat ID: %s)", 
                        correction.mountName, 
                        correction.oldTotal, 
                        correction.newTotal, 
                        correction.statId or "Unknown"))
                end
            else
                print("All mount attempt counts match Blizzard statistics.")
            end
        end
        
        -- Refresh UI if open
        if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
            if RaidMount.isStatsView then
                RaidMount.ShowDetailedStatsView()
            else
                RaidMount.PopulateUI()
            end
        end
    else
        PrintAddonMessage(RaidMount.L("VERIFY_COMPLETE"), false)
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
        closeButton:SetText(RaidMount.L("CLOSE"))
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
        selectButton:SetText(RaidMount.L("SELECT_ALL"))
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
end

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