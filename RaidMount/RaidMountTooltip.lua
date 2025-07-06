-- Enhanced tooltip functionality with caching and class colors
local addonName, RaidMount = ...

RaidMount = RaidMount or {}

-- Tooltip cache for performance optimization
local tooltipCache = {}
local cacheSize = 50 -- Maximum cached tooltips
local cacheHits = 0
local cacheMisses = 0

-- Class color definitions (fallback if RAID_CLASS_COLORS is not available)
local CLASS_COLORS = {
    ["DEATHKNIGHT"] = {0.77, 0.12, 0.23},
    ["DEMONHUNTER"] = {0.64, 0.19, 0.79},
    ["DRUID"] = {1.0, 0.49, 0.04},
    ["EVOKER"] = {0.2, 0.58, 0.5},
    ["HUNTER"] = {0.67, 0.83, 0.45},
    ["MAGE"] = {0.41, 0.8, 0.94},
    ["MONK"] = {0.0, 1.0, 0.59},
    ["PALADIN"] = {0.96, 0.55, 0.73},
    ["PRIEST"] = {1.0, 1.0, 1.0},
    ["ROGUE"] = {1.0, 0.96, 0.41},
    ["SHAMAN"] = {0.0, 0.44, 0.87},
    ["WARLOCK"] = {0.58, 0.51, 0.79},
    ["WARRIOR"] = {0.78, 0.61, 0.43}
}

-- Function to get class color for a character
local function GetClassColor(characterName)
    if not characterName then return 0.7, 1, 0.7 end -- Default light green
    
    -- Try to get class info from saved variables or guild roster
    local classInfo = nil
    
    -- Check if we have class data stored (you'll need to implement this storage)
    if RaidMountCharacterClasses and RaidMountCharacterClasses[characterName] then
        classInfo = RaidMountCharacterClasses[characterName]
    else
        -- Try to get class from current guild roster or group
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
        -- Use WoW's built-in class colors if available
        local classColors = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classInfo]
        if classColors then
            return classColors.r, classColors.g, classColors.b
        end
        
        -- Fall back to our custom class colors
        local customColors = CLASS_COLORS[classInfo]
        if customColors then
            return customColors[1], customColors[2], customColors[3]
        end
    end
    
    -- Default to light green if no class info found
    return 0.7, 1, 0.7
end

-- Function to store character class info when available
function RaidMount.StoreCharacterClass(characterName, class)
    if not characterName or not class then return end
    
    RaidMountCharacterClasses = RaidMountCharacterClasses or {}
    RaidMountCharacterClasses[characterName] = class
end

-- Function to scan and store current group/guild class info
function RaidMount.ScanAndStoreClassInfo()
    RaidMountCharacterClasses = RaidMountCharacterClasses or {}
    
    -- Scan current group
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
    
    -- Scan guild roster
    local guildName = GetGuildInfo("player")
    if guildName then
        local numMembers = GetNumGuildMembers()
        for i = 1, numMembers do
            local name, _, _, _, class = GetGuildRosterInfo(i)
            if name and class then
                local shortName = name:match("([^%-]+)") or name
                RaidMountCharacterClasses[shortName] = class
                RaidMountCharacterClasses[name] = class -- Store both versions
            end
        end
    end
end

-- Generate cache key for a mount
local function GetTooltipCacheKey(mount, lockoutStatus)
    if not mount then return nil end
    local key = (mount.MountID or mount.spellID or "") .. "_" .. (mount.collected and "1" or "0") .. "_" .. (lockoutStatus or "none")
    return key
end

-- Cache management
local function AddToCache(key, tooltipData)
    if #tooltipCache >= cacheSize then
        table.remove(tooltipCache, 1) -- Remove oldest entry
    end
    tooltipCache[key] = tooltipData
end

-- Show tooltip with mount information (optimized with caching and class colors)
function RaidMount.ShowTooltip(frame, mount, lockoutStatus)
    if not frame or not mount then
        return
    end
    
    -- Check cache first
    local cacheKey = GetTooltipCacheKey(mount, lockoutStatus)
    local cachedData = tooltipCache[cacheKey]
    
    if cachedData then
        cacheHits = cacheHits + 1
        -- Apply cached tooltip data
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        
        for _, line in ipairs(cachedData) do
            if line.type == "text" then
                GameTooltip:AddLine(line.text, unpack(line.color or {1, 1, 1}))
            elseif line.type == "double" then
                GameTooltip:AddDoubleLine(line.left, line.right, unpack(line.leftColor or {1, 1, 1}), unpack(line.rightColor or {1, 1, 1}))
            end
        end
        
        GameTooltip:Show()
        return
    end
    
    cacheMisses = cacheMisses + 1
    
    -- Build tooltip data for caching
    local tooltipData = {}
    
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Mount name (colored by collection status)
    local nameColor
    if mount.collectorsBounty then
        nameColor = mount.collected and "|cFFFFE0A0" or "|cFFD4AF37" -- Golden colors for Collector's Bounty mounts
    else
        nameColor = mount.collected and "|cFF00FF00" or "|cFFFF0000" -- Standard colors
    end
    local nameText = nameColor .. (mount.mountName or "Unknown Mount") .. "|r"
    GameTooltip:AddLine(nameText, 1, 1, 1)
    table.insert(tooltipData, {type = "text", text = nameText, color = {1, 1, 1}})
    
    -- Source information
    if mount.raidName or mount.dungeonName then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
        
        local sourceText = "|cFFFFFF00Source:|r " .. (mount.raidName or mount.dungeonName)
        GameTooltip:AddLine(sourceText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = sourceText, color = {1, 1, 1}})
        
        local bossText = "|cFFFFFF00Boss:|r " .. (mount.bossName or "Unknown")
        GameTooltip:AddLine(bossText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = bossText, color = {1, 1, 1}})
        
        if mount.difficulty then
            local diffText = "|cFFFFFF00Difficulty:|r " .. mount.difficulty
            GameTooltip:AddLine(diffText, 1, 1, 1)
            table.insert(tooltipData, {type = "text", text = diffText, color = {1, 1, 1}})
        end
    end
    
    -- Description (if available)
    if mount.description then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
        
        local descHeader = "|cFF00CCFFDescription:|r"
        GameTooltip:AddLine(descHeader, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = descHeader, color = {1, 1, 1}})
        
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
            table.insert(tooltipData, {type = "text", text = descLine, color = {0.9, 0.9, 0.9}})
        end
    end
    
    -- Drop rate and attempts
    if mount.dropRate then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
        
        local dropText = "|cFFFFFF00Drop Rate:|r " .. mount.dropRate
        GameTooltip:AddLine(dropText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = dropText, color = {1, 1, 1}})
        
        -- Add Collector's Bounty information if present
        if mount.collectorsBounty then
            local bountyText
            if mount.collectorsBounty == true then
                bountyText = "|cFF00FF00Collector's Bounty:|r +5% drop chance"
            else
                bountyText = "|cFFFFFF00Collector's Bounty:|r " .. mount.collectorsBounty
            end
            GameTooltip:AddLine(bountyText, 1, 1, 1)
            table.insert(tooltipData, {type = "text", text = bountyText, color = {1, 1, 1}})
        end
    end
    
    local attempts = mount.attempts or 0
    local attemptsColor = attempts > 0 and "|cFFFF8080" or "|cFFCCCCCC"
    local attemptsText = "|cFFFFFF00Total Attempts:|r " .. attemptsColor .. attempts .. "|r"
    GameTooltip:AddLine(attemptsText, 1, 1, 1)
    table.insert(tooltipData, {type = "text", text = attemptsText, color = {1, 1, 1}})
    
    local trackingKey = mount.spellID or mount.MountID
    local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
    
    if attemptData and type(attemptData) == "table" and attemptData.characters then
        local hasCharacterData = false
        for _, _ in pairs(attemptData.characters) do
            hasCharacterData = true
            break
        end
        
        if hasCharacterData then
            GameTooltip:AddLine(" ", 1, 1, 1)
            table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
            
            local charHeader = "|cFF00CCFFCharacter Attempts:|r"
            GameTooltip:AddLine(charHeader, 0.8, 0.8, 1)
            table.insert(tooltipData, {type = "text", text = charHeader, color = {0.8, 0.8, 1}})
            
            local characterAttempts = {}
            for charName, count in pairs(attemptData.characters) do
                if type(count) == "number" and count > 0 then
                    local shortName = charName:match("([^%-]+)") or charName
                    table.insert(characterAttempts, {name = shortName, count = count})
                end
            end
            
            table.sort(characterAttempts, function(a, b) return a.count > b.count end)
            
            local maxShow = math.min(8, #characterAttempts)
            for i = 1, maxShow do
                local char = characterAttempts[i]
                -- Get class color for this character
                local r, g, b = GetClassColor(char.name)
                GameTooltip:AddDoubleLine("  " .. char.name .. ":", tostring(char.count), r, g, b, 1, 1, 1)
                table.insert(tooltipData, {
                    type = "double", 
                    left = "  " .. char.name .. ":", 
                    right = tostring(char.count), 
                    leftColor = {r, g, b}, 
                    rightColor = {1, 1, 1}
                })
            end
            
            if #characterAttempts > maxShow then
                local moreText = "  ... and " .. (#characterAttempts - maxShow) .. " more"
                GameTooltip:AddLine(moreText, 0.6, 0.6, 0.6)
                table.insert(tooltipData, {type = "text", text = moreText, color = {0.6, 0.6, 0.6}})
            end
        end
    end
    
    if mount.lastAttempt then
        GameTooltip:AddLine(" ", 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
        
        local lastText = "|cFFFFFF00Last Attempt:|r " .. mount.lastAttempt
        GameTooltip:AddLine(lastText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = lastText, color = {1, 1, 1}})
    end
    
    -- Collection status
    GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
    table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
    
    local statusText = mount.collected and "|cFFFF0000Collected|r" or "|cFF00FF00Not Collected|r"
    local statusLine = "|cFFFFFF00Status:|r " .. statusText
    GameTooltip:AddLine(statusLine, 1, 1, 1)
    table.insert(tooltipData, {type = "text", text = statusLine, color = {1, 1, 1}})
    
    -- Lockout information
    if lockoutStatus and lockoutStatus ~= "Unknown" then
        local lockoutColor = lockoutStatus == "No lockout" and "|cFF00FF00" or "|cFFFF0000"
        local lockoutText = "|cFFFFFF00Lockout:|r " .. lockoutColor .. lockoutStatus .. "|r"
        GameTooltip:AddLine(lockoutText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = lockoutText, color = {1, 1, 1}})
    end
    
    -- Expansion
    if mount.expansion then
        local expText = "|cFFFFFF00Expansion:|r " .. mount.expansion
        GameTooltip:AddLine(expText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = expText, color = {1, 1, 1}})
    end
    
    -- Additional information for special mounts
    if mount.location and mount.location ~= mount.raidName and mount.location ~= mount.dungeonName then
        local locText = "|cFFFFFF00Location:|r " .. mount.location
        GameTooltip:AddLine(locText, 1, 1, 1)
        table.insert(tooltipData, {type = "text", text = locText, color = {1, 1, 1}})
    end
    
    -- Mount and Spell IDs for reference
    if mount.MountID then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        table.insert(tooltipData, {type = "text", text = " ", color = {1, 1, 1}})
        
        local mountIDText = "|cFF888888Mount ID:|r " .. mount.MountID
        GameTooltip:AddLine(mountIDText, 0.7, 0.7, 0.7)
        table.insert(tooltipData, {type = "text", text = mountIDText, color = {0.7, 0.7, 0.7}})
        
        if mount.spellID and mount.spellID ~= mount.MountID then
            local spellIDText = "|cFF888888Spell ID:|r " .. mount.spellID
            GameTooltip:AddLine(spellIDText, 0.7, 0.7, 0.7)
            table.insert(tooltipData, {type = "text", text = spellIDText, color = {0.7, 0.7, 0.7}})
        end
        if mount.itemID then
            local itemIDText = "|cFF888888Item ID:|r " .. mount.itemID
            GameTooltip:AddLine(itemIDText, 0.7, 0.7, 0.7)
            table.insert(tooltipData, {type = "text", text = itemIDText, color = {0.7, 0.7, 0.7}})
        end
    end
    
    -- Cache the tooltip data
    if cacheKey then
        AddToCache(cacheKey, tooltipData)
    end
    
    GameTooltip:Show()
end

-- Cache management functions
function RaidMount.ClearTooltipCache()
    tooltipCache = {}
    cacheHits = 0
    cacheMisses = 0
end

function RaidMount.GetTooltipCacheStats()
    return {
        hits = cacheHits,
        misses = cacheMisses,
        size = #tooltipCache,
        hitRate = cacheHits + cacheMisses > 0 and (cacheHits / (cacheHits + cacheMisses) * 100) or 0
    }
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

    local nameColor = mount.collected and "|cFFFF4444" or "|cFF44FF44"  -- Red if collected, Green if needed
    GameTooltip:SetText(nameColor .. (mount.mountName or "Unknown") .. "|r")
    
    local attempts = RaidMount.GetAttempts(mount.MountID) or 0
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
        
        -- Scan for class info when addon loads
        C_Timer.After(2, function()
            RaidMount.ScanAndStoreClassInfo()
        end)
    elseif event == "GROUP_ROSTER_UPDATE" or event == "GUILD_ROSTER_UPDATE" then
        -- Update class info when group or guild changes
        RaidMount.ScanAndStoreClassInfo()
    end
end

-- Register events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:SetScript("OnEvent", OnEvent)