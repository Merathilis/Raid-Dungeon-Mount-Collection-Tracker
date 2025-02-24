local addonName, RaidMount = ...
RaidMount = RaidMount or {}

if not RaidMount then
    print("ERROR: RaidMount is nil. Ensure RaidMount.lua is loaded first.")
    return
end

-- ✅ Utility function to print nested tables for deep debugging
local function DeepPrintTable(tbl, indent)
    indent = indent or ""
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            DeepPrintTable(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- ✅ Assign Tooltip Function to RaidMount for Global Access
function RaidMount.ShowTooltip(self, mount, lockoutStatus)
    GameTooltip:Hide()
    GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
    GameTooltip:ClearLines()

    -- ✅ Check if mount data exists
    if not mount then
        print("ERROR: Mount data is nil.")
        GameTooltip:SetText("Mount data not found.")
        GameTooltip:Show()
        return
    end

    -- ✅ Check if mountID exists
    if not mount.mountID then
        print("❌ ERROR: mount.mountID is nil. Attempting to fallback using itemID.")
        if mount.itemID then
            mount.mountID = C_MountJournal.GetMountFromItem(mount.itemID)
            print("🔄 Fallback mountID from itemID: ", mount.mountID or "Failed")
        end
    end

    if not mount.mountID then
        GameTooltip:SetText("No Mount ID found.")
        GameTooltip:Show()
        return
    end

    

    -- ✅ Display Basic Mount Info
    GameTooltip:SetText(mount.mountName or "Unknown", 1, 1, 1)
    GameTooltip:AddLine("Instance: " .. (mount.raidName or mount.dungeonName))
    GameTooltip:AddLine("Type: " .. mount.type)
    GameTooltip:AddLine("Boss: " .. (mount.bossName or "Unknown"))
    GameTooltip:AddLine("Location: " .. (mount.location or "Unknown"))
    GameTooltip:AddLine("Drop Rate: " .. (mount.dropRate or "~1%"))

    -- ✅ Initialize total attempts
    local totalAttempts = 0
    local hasCharacterAttempts = false

    -- ✅ Access RaidMountAttempts for the current mountID
    if RaidMountAttempts and RaidMountAttempts[mount.mountID] then
        local attemptData = RaidMountAttempts[mount.mountID]
        

        -- Handle simple numeric attempts
        if type(attemptData) == "number" then
            totalAttempts = attemptData

        -- Handle table format with characters and total
        elseif type(attemptData) == "table" then
            totalAttempts = attemptData["total"] or 0

            -- ✅ Check for character-specific attempts
            if attemptData["characters"] and next(attemptData["characters"]) then
                hasCharacterAttempts = true
            end
        end
    else
    -- print("❌ No attempt data found for mountID:", mount.mountID)

    end

    -- ✅ Display Total Attempts
    GameTooltip:AddLine("Total Attempts: " .. totalAttempts)

    -- ✅ Display Per-Character Breakdown in GREEN 🟩
    if hasCharacterAttempts then
        GameTooltip:AddLine("|cFF00FF00Character Attempts:|r")  -- Green header
        for charName, count in pairs(RaidMountAttempts[mount.mountID]["characters"]) do
            if type(count) == "number" then
                GameTooltip:AddLine("|cFF00FF00- " .. charName .. ": " .. count .. " attempt(s)|r")  -- Green text
            end
        end
    elseif totalAttempts == 0 then
        GameTooltip:AddLine("No attempts yet.", 0.8, 0.2, 0.2)
    end

    -- ✅ Lockout Status in RED 🟥
    if lockoutStatus ~= "" then
        GameTooltip:AddLine("|cFFFF0000Lockout: " .. lockoutStatus .. "|r")  -- Red Lockout
    end

    GameTooltip:Show()
end
