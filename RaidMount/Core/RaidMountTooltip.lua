local addonName, RaidMount = ...

RaidMount = RaidMount or {}

-- Performance optimization: Use local variables for frequently accessed functions
local time = time
local UnitName = UnitName
local GetRealmName = GetRealmName
local UnitClass = UnitClass
local GetGuildInfo = GetGuildInfo
local GetNumGuildMembers = GetNumGuildMembers
local GetGuildRosterInfo = GetGuildRosterInfo
local GetNumGroupMembers = GetNumGroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local C_Timer = C_Timer
local CreateFrame = CreateFrame
local wipe = wipe
local pairs = pairs
local ipairs = ipairs
local tonumber = tonumber
local string_match = string.match
local string_lower = string.lower
local string_gsub = string.gsub

local tooltipCache = {}
local cacheSize = 30 -- Reduced cache size
local cacheHits = 0
local cacheMisses = 0
local cacheCleanupThreshold = 40 -- Clean cache when it gets too large

-- Difficulty mapping for readable tooltips
local DIFFICULTY_NAMES = {
    [1] = "Normal (5)",
    [2] = "Heroic (5)",
    [3] = "10-player",
    [4] = "25-player",
    [5] = "10H",
    [6] = "25H",
    [7] = "LFR",
    [14] = "Normal",
    [15] = "Heroic",
    [16] = "Mythic",
    [17] = "LFR",
    [23] = "Mythic (5)",
}

local CLASS_COLORS = {
    ["DEATHKNIGHT"] = { 0.77, 0.12, 0.23 },
    ["DEMONHUNTER"] = { 0.64, 0.19, 0.79 },
    ["DRUID"] = { 1.0, 0.49, 0.04 },
    ["EVOKER"] = { 0.2, 0.58, 0.5 },
    ["HUNTER"] = { 0.67, 0.83, 0.45 },
    ["MAGE"] = { 0.41, 0.8, 0.94 },
    ["MONK"] = { 0.0, 1.0, 0.59 },
    ["PALADIN"] = { 0.96, 0.55, 0.73 },
    ["PRIEST"] = { 1.0, 1.0, 1.0 },
    ["ROGUE"] = { 1.0, 0.96, 0.41 },
    ["SHAMAN"] = { 0.0, 0.44, 0.87 },
    ["WARLOCK"] = { 0.58, 0.51, 0.79 },
    ["WARRIOR"] = { 0.78, 0.61, 0.43 }
}

local function GetClassColor(characterName)
    if not characterName then return 0.7, 1, 0.7 end

    local classInfo = nil

    if RaidMountCharacterClasses and RaidMountCharacterClasses[characterName] then
        classInfo = RaidMountCharacterClasses[characterName]
    else
        local guildName = GetGuildInfo("player")
        if guildName then
            local numMembers = GetNumGuildMembers()
            for i = 1, numMembers do
                local name, _, _, _, class = GetGuildRosterInfo(i)
                if name and name:match("([^%-]+)") == characterName:match("([^%-]+)") then
                    classInfo = class
                    break
                end
            end
        end
    end

    if classInfo then
        local classColors = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classInfo]
        if classColors then
            return classColors.r, classColors.g, classColors.b
        end

        local customColors = CLASS_COLORS[classInfo]
        if customColors then
            return customColors[1], customColors[2], customColors[3]
        end
    end

    return 0.7, 1, 0.7
end

function RaidMount.StoreCharacterClass(characterName, class)
    if not characterName or not class then return end

    RaidMountCharacterClasses = RaidMountCharacterClasses or {}
    RaidMountCharacterClasses[characterName] = class
end

function RaidMount.ScanAndStoreClassInfo()
    RaidMountCharacterClasses = RaidMountCharacterClasses or {}

    local numGroupMembers = GetNumGroupMembers()
    if numGroupMembers > 0 then
        for i = 1, numGroupMembers do
            local name, _, _, _, class = GetRaidRosterInfo(i)
            if name and class then
                local shortName = name:match("([^%-]+)") or name
                RaidMountCharacterClasses[shortName] = class
                RaidMountCharacterClasses[name] = class -- Store both versions
            end
        end
    end

    local guildName = GetGuildInfo("player")
    if guildName then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, class = GetGuildRosterInfo(i)
            if name and class then
                local shortName = name:match("([^%-]+)") or name
                RaidMountCharacterClasses[shortName] = class
                RaidMountCharacterClasses[name] = class
            end
        end
    end
end

local function GetTooltipCacheKey(mount, lockoutStatus)
    if not mount then return nil end
    -- Include character lockout data in cache key to ensure tooltips update when lockouts change
    local lockoutHash = ""
    if RaidMountSaved and RaidMountSaved.characterLockouts and mount.raidName then
        local lockoutCount = 0
        for charName, charLockouts in pairs(RaidMountSaved.characterLockouts) do
            if type(charLockouts) == "table" then
                for instanceName, lockoutData in pairs(charLockouts) do
                    if instanceName and mount.raidName and
                        (instanceName:lower():find(mount.raidName:lower()) or
                            mount.raidName:lower():find(instanceName:lower())) then
                        lockoutCount = lockoutCount + 1
                    end
                end
            end
        end
        lockoutHash = "_locks" .. lockoutCount
    end

    local key = (mount.MountID or mount.spellID or "") ..
    "_" .. (mount.collected and "1" or "0") .. "_" .. (lockoutStatus or "none") .. lockoutHash
    return key
end

local function AddToCache(key, tooltipData)
    -- Clean cache if it gets too large
    local count = 0
    for _ in pairs(tooltipCache) do count = count + 1 end

    if count >= cacheCleanupThreshold then
        -- Remove oldest 50% of entries
        local toRemove = {}
        local removeCount = 0
        for cacheKey, _ in pairs(tooltipCache) do
            table.insert(toRemove, cacheKey)
            removeCount = removeCount + 1
            if removeCount >= math.floor(count / 2) then
                break
            end
        end

        for _, cacheKey in ipairs(toRemove) do
            tooltipCache[cacheKey] = nil
        end
    end

    tooltipCache[key] = tooltipData
end

-- Function to clear tooltip cache
function RaidMount.ClearTooltipCache()
    wipe(tooltipCache)
    cacheHits = 0
    cacheMisses = 0
end

function RaidMount.ShowTooltip(frame, mount, lockoutStatus)
    if not frame or not mount then
        return
    end
    
    -- Force refresh lockouts to ensure current data
    if RaidMount.ForceRefreshLockouts then
        RaidMount.ForceRefreshLockouts()
    end

    -- Get current lockout status for this specific mount's raid
    local currentLockoutStatus = "Unknown"
    local allLockoutInfo = {}

    if mount.raidName then
        -- Use the new function for more accurate lockout checking
        if mount.DifficultyIDs and #mount.DifficultyIDs > 0 then
            -- For mounts with multiple difficulties, check all relevant lockouts
            for _, diffID in ipairs(mount.DifficultyIDs) do
                local difficultyName = nil
                if diffID == 17 then
                    difficultyName = "LFR"
                elseif diffID == 14 then
                    difficultyName = "Normal"
                elseif diffID == 15 then
                    difficultyName = "Heroic"
                elseif diffID == 16 then
                    difficultyName = "Mythic"
                elseif diffID == 3 then
                    difficultyName = "10 Player"
                elseif diffID == 4 then
                    difficultyName = "25 Player"
                elseif diffID == 5 then
                    difficultyName = "10 Player (Heroic)"
                elseif diffID == 6 then
                    difficultyName = "25 Player (Heroic)"
                end

                if difficultyName then
                    local lockoutTime, canEnter = RaidMount.GetDifficultyLockoutStatus(mount.raidName, diffID, mount.expansion)
                    table.insert(allLockoutInfo, {
                        difficulty = difficultyName,
                        canEnter = canEnter,
                        lockoutTime = lockoutTime
                    })
                end
            end
            -- Set current lockout status to the first available or locked status
            if #allLockoutInfo > 0 then
                currentLockoutStatus = allLockoutInfo[1].lockoutTime
            end
        else
            -- Single difficulty mount - use the basic lockout check
            currentLockoutStatus = RaidMount.GetRaidLockout(mount.raidName)
            table.insert(allLockoutInfo, {
                difficulty = mount.difficulty or "Unknown",
                canEnter = currentLockoutStatus == "No lockout",
                lockoutTime = currentLockoutStatus
            })
        end
    end

    local cacheKey = GetTooltipCacheKey(mount, currentLockoutStatus)
    local cachedData = tooltipCache[cacheKey]

    if cachedData then
        cacheHits = cacheHits + 1
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()

        for _, line in ipairs(cachedData) do
            if line.type == "text" then
                GameTooltip:AddLine(line.text, unpack(line.color or { 1, 1, 1 }))
            elseif line.type == "double" then
                GameTooltip:AddDoubleLine(line.left, line.right, unpack(line.leftColor or { 1, 1, 1 }),
                    unpack(line.rightColor or { 1, 1, 1 }))
            end
        end

        GameTooltip:Show()
        return
    end

    cacheMisses = cacheMisses + 1

    local tooltipData = {}

    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    -- Use unified mount coloring system with quality-based colors
    local nameColor = RaidMount.GetMountNameColor(mount)
    local nameText = nameColor .. (mount.mountName or "Unknown Mount") .. "|r"

    -- Add Collector's Bounty indicator
    if mount.collectorsBounty then
        nameText = nameText .. " |cFFFFD700[Collector's Bounty]|r"
    end
    GameTooltip:AddLine(nameText, 1, 1, 1)
    table.insert(tooltipData, { type = "text", text = nameText, color = { 1, 1, 1 } })

    if mount.raidName or mount.dungeonName then
        GameTooltip:AddLine(" ", 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local sourceText = "|cFFFFFF00Source:|r " .. (mount.raidName or mount.dungeonName)
        GameTooltip:AddLine(sourceText, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = sourceText, color = { 1, 1, 1 } })

        local bossText = "|cFFFFFF00Boss:|r " .. (mount.bossName or "Unknown")
        GameTooltip:AddLine(bossText, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = bossText, color = { 1, 1, 1 } })

        if mount.difficulty then
            -- Use corrected difficulty logic similar to button display
            local diffText
            if mount.DifficultyIDs and #mount.DifficultyIDs > 0 then
                -- Check for shared difficulties first
                if mount.SharedDifficulties and next(mount.SharedDifficulties) then
                    diffText = "|cFFFFFF00Difficulty:|r 10/25 Player"
                else
                    -- Use the first difficulty ID with fallback to difficulty string
                    local difficultyID = mount.DifficultyIDs[1]
                    if difficultyID then
                        -- Use the same logic as button text generation
                        local DungeonDifficulty = { Normal = 1, Heroic = 2, Mythic = 23 }
                        local RaidDifficulty = { Legacy10 = 3, Legacy25 = 4, Legacy10H = 5, Legacy25H = 6, LFR = 17, Normal = 14, Heroic = 15, Mythic = 16 }
                        
                        local dKey
                        for key, dd in pairs(DungeonDifficulty) do
                            if dd == difficultyID then
                                dKey = key; break
                            end
                        end
                        
                        if not dKey then
                            for key, rd in pairs(RaidDifficulty) do
                                if rd == difficultyID then
                                    dKey = key; break
                                end
                            end
                        end
                        
                        -- Apply the same corrections as button logic
                        if mount.contentType == "Raid" and mount.difficulty:find("25") and dKey == "Normal" then
                            diffText = "|cFFFFFF00Difficulty:|r 25 Player"
                        elseif mount.contentType == "Dungeon" and mount.difficulty == "Heroic" and dKey == "Normal" then
                            diffText = "|cFFFFFF00Difficulty:|r Heroic"
                        else
                            diffText = "|cFFFFFF00Difficulty:|r " .. mount.difficulty
                        end
                    else
                        diffText = "|cFFFFFF00Difficulty:|r " .. mount.difficulty
                    end
                end
            else
                diffText = "|cFFFFFF00Difficulty:|r " .. mount.difficulty
            end
            GameTooltip:AddLine(diffText, 1, 1, 1)
            table.insert(tooltipData, { type = "text", text = diffText, color = { 1, 1, 1 } })
        end
    end

    if mount.description then
        GameTooltip:AddLine(" ", 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local descHeader = "|cFF00CCFFDescription:|r"
        GameTooltip:AddLine(descHeader, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = descHeader, color = { 1, 1, 1 } })

        -- Split description into multiple lines if it's too long
        local maxLineLength = 60
        local description = mount.description
        local lines = {}

        while #description > maxLineLength do
            local spacePos = description:sub(1, maxLineLength):find(" [^ ]*$")
            if spacePos then
                table.insert(lines, description:sub(1, spacePos - 1))
                description = description:sub(spacePos + 1)
            else
                table.insert(lines, description:sub(1, maxLineLength))
                description = description:sub(maxLineLength + 1)
            end
        end

        if #description > 0 then
            table.insert(lines, description)
        end

        for i, line in ipairs(lines) do
            local descLine = "  " .. line
            GameTooltip:AddLine(descLine, 0.9, 0.9, 0.9)
            table.insert(tooltipData, { type = "text", text = descLine, color = { 0.9, 0.9, 0.9 } })
        end
    end

    -- Drop rate and attempts
    if mount.dropRate then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local dropText = "|cFFFFFF00Drop Rate:|r " .. mount.dropRate
        GameTooltip:AddLine(dropText, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = dropText, color = { 1, 1, 1 } })


    end

    local attempts = mount.attempts or 0
    local attemptsColor = attempts > 0 and "|cFFFF8080" or "|cFFCCCCCC"
    local attemptsText = "|cFFFFFF00Total Attempts:|r " .. attemptsColor .. attempts .. "|r"
    GameTooltip:AddLine(attemptsText, 1, 1, 1)
    table.insert(tooltipData, { type = "text", text = attemptsText, color = { 1, 1, 1 } })

    if mount.lastAttempt then
        GameTooltip:AddLine(" ", 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local lastText = "|cFFFFFF00Last Attempt:|r " .. mount.lastAttempt
        GameTooltip:AddLine(lastText, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = lastText, color = { 1, 1, 1 } })
    end

    -- Collection status
    GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
    table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

    local statusText, statusColor
    if mount.collected then
        statusText = "Collected"
        statusColor = "|cFF00FF00" -- green
    else
        statusText = "Not Collected"
        statusColor = "|cFFFF3333" -- red
    end
    local statusLine = "|cFFFFFF00Status:|r " .. statusColor .. statusText .. "|r"
    GameTooltip:AddLine(statusLine, 1, 1, 1)
    table.insert(tooltipData, { type = "text", text = statusLine, color = { 1, 1, 1 } })

    -- Enhanced lockout information for multiple difficulties
    if #allLockoutInfo > 0 then
        GameTooltip:AddLine(" ", 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local lockoutHeader = "|cFFFFFF00Lockout Status:|r"
        GameTooltip:AddLine(lockoutHeader, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = lockoutHeader, color = { 1, 1, 1 } })

        -- Check if this mount has shared difficulties
        local hasSharedDifficulties = mount.SharedDifficulties and next(mount.SharedDifficulties) ~= nil
        local shouldShowCombined = hasSharedDifficulties and mount.contentType == "Raid"
        
        if shouldShowCombined then
            -- Show combined lockout status for shared difficulties
            local primaryLockoutInfo = allLockoutInfo[1] -- Use the first difficulty as primary
            local statusColor = primaryLockoutInfo.canEnter and "|cFF00FF00" or "|cFFFF0000"
            local statusText = primaryLockoutInfo.canEnter and "Available" or "Locked"
            local timeText = primaryLockoutInfo.lockoutTime ~= "No lockout" and " (" .. primaryLockoutInfo.lockoutTime .. ")" or ""

            local lockoutLine = "  10/25 Player: " .. statusColor .. statusText .. timeText .. "|r"
            GameTooltip:AddLine(lockoutLine, 1, 1, 1)
            table.insert(tooltipData, { type = "text", text = lockoutLine, color = { 1, 1, 1 } })
        else
            -- Show individual difficulty lockout status
            for _, lockoutInfo in ipairs(allLockoutInfo) do
                local statusColor = lockoutInfo.canEnter and "|cFF00FF00" or "|cFFFF0000"
                local statusText = lockoutInfo.canEnter and "Available" or "Locked"
                local timeText = lockoutInfo.lockoutTime ~= "No lockout" and " (" .. lockoutInfo.lockoutTime .. ")" or ""

                local lockoutLine = "  " .. lockoutInfo.difficulty .. ": " .. statusColor .. statusText .. timeText .. "|r"
                GameTooltip:AddLine(lockoutLine, 1, 1, 1)
                table.insert(tooltipData, { type = "text", text = lockoutLine, color = { 1, 1, 1 } })
            end
        end
    elseif currentLockoutStatus and currentLockoutStatus ~= "Unknown" then
        -- Fallback for single difficulty mounts
        local lockoutColor = currentLockoutStatus == "No lockout" and "|cFF00FF00" or "|cFFFF0000"
        local lockoutText = "|cFFFFFF00Current Lockout:|r " .. lockoutColor .. currentLockoutStatus .. "|r"
        GameTooltip:AddLine(lockoutText, 1, 1, 1)
        table.insert(tooltipData, { type = "text", text = lockoutText, color = { 1, 1, 1 } })
    end

    -- Cross-character lockout information - only show if current character has no lockouts for this raid
    if mount.raidName and RaidMount.GetCrossCharacterLockoutSummary then
        -- Check if current character has any lockouts for this raid
        local currentCharHasLockout = false
        if currentLockoutStatus and currentLockoutStatus ~= "No lockout" and currentLockoutStatus ~= "Unknown" then
            currentCharHasLockout = true
        end
        
        -- Only show cross-character info if current character has no lockouts for this raid
        if not currentCharHasLockout then
            local crossCharSummary = RaidMount.GetCrossCharacterLockoutSummary(mount)
            
            if crossCharSummary and crossCharSummary.totalLocked > 0 then
                -- Get current character key to filter it out
                local currentCharKey = RaidMount.GetCurrentCharacterID()
                local currentCharAttempts = 0
                
                -- Filter out current character from the list
                local otherLockedChars = {}
                
                for _, char in ipairs(crossCharSummary.lockedChars) do
                    if char.character ~= currentCharKey then
                        table.insert(otherLockedChars, char)
                    end
                end
                
                -- Only show if there are other characters with lockout info
                if #otherLockedChars > 0 then
                GameTooltip:AddLine(" ", 1, 1, 1)
                table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

                local crossCharHeader = "|cFFFFFF00Alts:|r"
                GameTooltip:AddLine(crossCharHeader, 1, 1, 1)
                table.insert(tooltipData, { type = "text", text = crossCharHeader, color = { 1, 1, 1 } })

                -- Group lockouts by character
                local charLockouts = {}
                for _, char in ipairs(otherLockedChars) do
                    local charName = char.character:match("^([^-]+)") -- Remove realm name
                    if not charLockouts[charName] then
                        charLockouts[charName] = {
                            name = charName,
                            class = char.class,
                            difficulties = {},
                            timeRemaining = char.timeRemaining
                        }
                    end
                    table.insert(charLockouts[charName].difficulties, char.difficulty)
                end

                -- Show locked characters
                for charName, charData in pairs(charLockouts) do
                    local classColor = "|cFFFFFFFF" -- Default white
                    
                    if charData.class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[charData.class] then
                        classColor = RAID_CLASS_COLORS[charData.class].colorStr or "|cFFFFFFFF"
                    end
                    
                    local timeText = RaidMount.EnhancedLockout and RaidMount.EnhancedLockout:FormatTimeRemaining(charData.timeRemaining) or "Unknown"
                    
                    -- Format difficulties
                    local difficultyText
                    if #charData.difficulties > 1 then
                        -- Multiple difficulties - use abbreviations
                        local abbrevMap = {
                            ["Looking For Raid"] = "LFR",
                            ["Normal"] = "N",
                            ["Heroic"] = "H", 
                            ["Mythic"] = "M"
                        }
                        local abbrevList = {}
                        for _, diff in ipairs(charData.difficulties) do
                            table.insert(abbrevList, abbrevMap[diff] or diff)
                        end
                        difficultyText = table.concat(abbrevList, ",")
                    else
                        -- Single difficulty - use full name
                        difficultyText = charData.difficulties[1]
                    end
                    
                    -- Use single line with color codes for better visibility
                    local fullText = "  " .. charName .. " |cFFFF0000" .. difficultyText .. " " .. timeText .. "|r"
                    
                    GameTooltip:AddLine(fullText, 1, 1, 1)
                    table.insert(tooltipData, { type = "text", text = fullText, color = { 1, 1, 1 } })
                end
            end
        end
        end
    end

    -- Mount and Spell IDs for reference
    if mount.MountID then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, { type = "text", text = " ", color = { 1, 1, 1 } })

        local mountIDText = "|cFF888888Mount ID:|r " .. mount.MountID
        GameTooltip:AddLine(mountIDText, 0.7, 0.7, 0.7)
        table.insert(tooltipData, { type = "text", text = mountIDText, color = { 0.7, 0.7, 0.7 } })

        if mount.spellID and mount.spellID ~= mount.MountID then
            local spellIDText = "|cFF888888Spell ID:|r " .. mount.spellID
            GameTooltip:AddLine(spellIDText, 0.7, 0.7, 0.7)
            table.insert(tooltipData, { type = "text", text = spellIDText, color = { 0.7, 0.7, 0.7 } })
        end
        if mount.itemID then
            local itemIDText = "|cFF888888Item ID:|r " .. mount.itemID
            GameTooltip:AddLine(itemIDText, 0.7, 0.7, 0.7)
            table.insert(tooltipData, { type = "text", text = itemIDText, color = { 0.7, 0.7, 0.7 } })
        end
    end

    -- Cache the tooltip data
    if cacheKey then
        AddToCache(cacheKey, tooltipData)
    end

    GameTooltip:Show()
end

function RaidMount.GetTooltipCacheStats()
    return {
        hits = cacheHits,
        misses = cacheMisses,
        size = #tooltipCache,
        hitRate = cacheHits + cacheMisses > 0 and (cacheHits / (cacheHits + cacheMisses) * 100) or 0
    }
end

-- Clear cache when lockout information might have changed
function RaidMount.ClearTooltipCacheOnLockoutChange()
    -- Clear cache when lockout information changes
    RaidMount.ClearTooltipCache()
end

-- Alternative tooltip for mini-display (if needed)
function RaidMount.ShowMiniTooltip(self, mount)
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()

    if not mount then
        GameTooltip:SetText("No mount data", 1, 0.2, 0.2)
        GameTooltip:Show()
        return
    end

    -- Use unified mount coloring system with quality-based colors
    local nameColor = RaidMount.GetMountNameColor(mount)
    GameTooltip:SetText(nameColor .. (mount.mountName or "Unknown") .. "|r")

    local attempts = RaidMount.GetAttempts(mount) or 0
    GameTooltip:AddLine("Attempts: " .. attempts, 1, 1, 0)

    if mount.collected then
        GameTooltip:AddLine("|cFFFF4444Collected!|r", 1, 0.3, 0.3)
    else
        GameTooltip:AddLine(mount.dropRate or "~1%", 0.8, 0.8, 0.8)
    end

    GameTooltip:Show()
end

-- Event handler to automatically scan for class info
local function OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and ... == addonName then
        -- Initialize class data storage
        RaidMountCharacterClasses = RaidMountCharacterClasses or {}

        -- Clear tooltip cache on addon load to ensure fresh data
        RaidMount.ClearTooltipCache()

        -- Scan for class info when addon loads
        C_Timer.After(2, function()
            RaidMount.ScanAndStoreClassInfo()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        -- Update class info when group or guild changes
        RaidMount.ScanAndStoreClassInfo()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        -- Clear tooltip cache when entering new areas (potential lockout changes)
        RaidMount.ClearTooltipCacheOnLockoutChange()
    elseif event == "INSTANCE_LOCK_START" or event == "INSTANCE_LOCK_STOP" then
        -- Clear tooltip cache when instance lockout status changes
        RaidMount.ClearTooltipCacheOnLockoutChange()
    end
end

-- Register events with cleanup capability
local tooltipEventFrame = CreateFrame("Frame", "RaidMountTooltipEventFrame")
tooltipEventFrame:RegisterEvent("ADDON_LOADED")
tooltipEventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
tooltipEventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
tooltipEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
tooltipEventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
tooltipEventFrame:RegisterEvent("INSTANCE_LOCK_START")
tooltipEventFrame:RegisterEvent("INSTANCE_LOCK_STOP")
tooltipEventFrame:SetScript("OnEvent", OnEvent)

-- Cleanup function for tooltip system
function RaidMount.CleanupTooltipSystem()
    if tooltipEventFrame then
        tooltipEventFrame:UnregisterAllEvents()
        tooltipEventFrame:SetScript("OnEvent", nil)
    end

    RaidMount.ClearTooltipCache()

    if RaidMountCharacterClasses then
        wipe(RaidMountCharacterClasses)
    end
end
