local addonName, RaidMount = ...

-- Enhanced tooltip functionality
RaidMount = RaidMount or {}

-- Show tooltip with mount information
function RaidMount.ShowTooltip(frame, mount, lockoutStatus)
    if not frame or not mount then
        return
    end
    
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    
    -- Mount name (colored by collection status)
    local nameColor = mount.collected and "|cFF00FF00" or "|cFFFF0000"
    GameTooltip:AddLine(nameColor .. (mount.mountName or "Unknown Mount") .. "|r", 1, 1, 1)
    
    -- Source information
    if mount.raidName or mount.dungeonName then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        GameTooltip:AddLine("|cFFFFFF00Source:|r " .. (mount.raidName or mount.dungeonName), 1, 1, 1)
        GameTooltip:AddLine("|cFFFFFF00Boss:|r " .. (mount.bossName or "Unknown"), 1, 1, 1)
        
        if mount.difficulty then
            GameTooltip:AddLine("|cFFFFFF00Difficulty:|r " .. mount.difficulty, 1, 1, 1)
        end
    end
    
    -- Drop rate and attempts
    if mount.dropRate then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        GameTooltip:AddLine("|cFFFFFF00Drop Rate:|r " .. mount.dropRate, 1, 1, 1)
    end
    
    local attempts = mount.attempts or 0
    local attemptsColor = attempts > 0 and "|cFFFF8080" or "|cFFCCCCCC"
    GameTooltip:AddLine("|cFFFFFF00Total Attempts:|r " .. attemptsColor .. attempts .. "|r", 1, 1, 1)
    
    local trackingKey = mount.spellID or mount.mountID
    local attemptData = RaidMountAttempts and RaidMountAttempts[trackingKey]
    
    if attemptData and type(attemptData) == "table" and attemptData.characters then
        local hasCharacterData = false
        for _, _ in pairs(attemptData.characters) do
            hasCharacterData = true
            break
        end
        
        if hasCharacterData then
            GameTooltip:AddLine(" ", 1, 1, 1)
            GameTooltip:AddLine("|cFF00CCFFCharacter Attempts:|r", 0.8, 0.8, 1)
            
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
                GameTooltip:AddDoubleLine("  " .. char.name .. ":", tostring(char.count), 0.7, 1, 0.7, 1, 1, 1)
            end
            
            if #characterAttempts > maxShow then
                GameTooltip:AddLine("  ... and " .. (#characterAttempts - maxShow) .. " more", 0.6, 0.6, 0.6)
            end
        end
    end
    
    if mount.lastAttempt then
        GameTooltip:AddLine(" ", 1, 1, 1)
        GameTooltip:AddLine("|cFFFFFF00Last Attempt:|r " .. mount.lastAttempt, 1, 1, 1)
    end
    
    -- Collection status
    GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
    local statusText = mount.collected and "|cFFFF0000Collected|r" or "|cFF00FF00Not Collected|r"
    GameTooltip:AddLine("|cFFFFFF00Status:|r " .. statusText, 1, 1, 1)
    
    -- Lockout information
    if lockoutStatus and lockoutStatus ~= "Unknown" then
        local lockoutColor = lockoutStatus == "No lockout" and "|cFF00FF00" or "|cFFFF0000"
        GameTooltip:AddLine("|cFFFFFF00Lockout:|r " .. lockoutColor .. lockoutStatus .. "|r", 1, 1, 1)
    end
    
    -- Expansion
    if mount.expansion then
        GameTooltip:AddLine("|cFFFFFF00Expansion:|r " .. mount.expansion, 1, 1, 1)
    end
    
    -- Additional information for special mounts
    if mount.location and mount.location ~= mount.raidName and mount.location ~= mount.dungeonName then
        GameTooltip:AddLine("|cFFFFFF00Location:|r " .. mount.location, 1, 1, 1)
    end
    
    -- Mount and Spell IDs for reference
    if mount.mountID then
        GameTooltip:AddLine(" ", 1, 1, 1) -- Blank line
        GameTooltip:AddLine("|cFF888888Mount ID:|r " .. mount.mountID, 0.7, 0.7, 0.7)
        if mount.spellID and mount.spellID ~= mount.mountID then
            GameTooltip:AddLine("|cFF888888Spell ID:|r " .. mount.spellID, 0.7, 0.7, 0.7)
        end
        if mount.itemID then
            GameTooltip:AddLine("|cFF888888Item ID:|r " .. mount.itemID, 0.7, 0.7, 0.7)
        end
    end
    
    GameTooltip:Show()
end

-- Alternative tooltip for mini-display (if needed)
function RaidMount.ShowMiniTooltip(self, mount)
    if not RaidMountSettings.showTooltips then return end
    
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
    
    local attempts = RaidMount.GetAttempts(mount.mountID) or 0
    GameTooltip:AddLine("Attempts: " .. attempts, 1, 1, 0)
    
    if mount.collected then
        GameTooltip:AddLine("|cFFFF4444Collected!|r", 1, 0.3, 0.3)
    else
        GameTooltip:AddLine(mount.dropRate or "~1%", 0.8, 0.8, 0.8)
    end

    GameTooltip:Show()
end
