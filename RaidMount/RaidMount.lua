local addonName, RaidMount = ...
RaidMount = RaidMount or {}
RaidMountAttempts = RaidMountAttempts or {}  -- ✅ Persistent storage for attempts

-- ✅ Ensure mountInstances is loaded
if not RaidMount.mountInstances then
    print("ERROR: mountInstances is nil! Ensure MountData.lua is loaded.")
    RaidMount.mountInstances = {}
end

-- ✅ Ensure required functions exist
if not RaidMount.PlayerHasMount or not RaidMount.GetRaidLockout then
    print("ERROR: Required functions are missing! Ensure MountCheck.lua and LockoutCheck.lua are loaded.")
    return
end

local mountInstances = RaidMount.mountInstances

-- ✅ Initialize Attempts After Player Login
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    for _, mount in ipairs(mountInstances) do
        if not RaidMountAttempts[mount.mountID] then
            RaidMountAttempts[mount.mountID] = 0
        end  
    end  
end)  


    -- ✅ Track Boss Kills Per Character
local bossKillFrame = CreateFrame("Frame")
bossKillFrame:RegisterEvent("BOSS_KILL")
bossKillFrame:SetScript("OnEvent", function(_, _, bossID, bossName)
    local playerName = UnitName("player")
    local realmName = GetRealmName()
    local characterID = playerName .. "-" .. realmName  -- Unique per character

    for _, mount in ipairs(mountInstances) do
        if mount.bossName == bossName then
            local mountID = mount.mountID

            -- ✅ Ensure correct table structure for each mount attempt
            if type(RaidMountAttempts[mountID]) ~= "table" then
                RaidMountAttempts[mountID] = { total = 0, characters = {} }
            end

            -- Increment total attempts
            RaidMountAttempts[mountID].total = (RaidMountAttempts[mountID].total or 0) + 1

            -- Increment character-specific attempts
            RaidMountAttempts[mountID].characters[characterID] = (RaidMountAttempts[mountID].characters[characterID] or 0) + 1

            print("Attempt recorded for " .. mount.mountName .. " by " .. characterID .. ". Total attempts: " .. RaidMountAttempts[mountID].total)
        end
    end
end)



--  Get Attempt Count
function RaidMount.GetAttempts(mountID)
    return RaidMountAttempts[mountID] or 0
end

--  Reset Attempts
function RaidMount.ResetAttempts(mountID)
    RaidMountAttempts[mountID] = 0
    print("Attempts for mount ID " .. mountID .. " have been reset.")
end

--  Get Difficulty Color
function RaidMount.GetDifficultyColor(difficulty)
    return (difficulty == "Mythic" and "|cFFFF8000") or (difficulty == "Heroic" and "|cFF0070DD") or "|cFFFFFFFF"
end

--  Get Lockout Color
function RaidMount.GetLockoutColor(raidName)
    local resetTime = RaidMount.GetRaidLockout(raidName)
    return (resetTime == "No lockout") and "|cFF00FF00" or "|cFFFF0000"
end

--  Format Mount Data for UI
function RaidMount.GetFormattedMountData()
    local formattedData = {}
    for _, mount in ipairs(RaidMount.mountInstances) do
        local hasMount = RaidMount.PlayerHasMount(mount.mountID, mount.itemID)
        table.insert(formattedData, {
            raidName = mount.raidName or "Unknown",
            bossName = mount.bossName or "Unknown",
            mountName = mount.mountName or "Unknown",
            location = mount.location or "Unknown",
            dropRate = mount.dropRate or "Unknown",
            resetTime = RaidMount.GetRaidLockout(mount.raidName),
            difficulty = mount.difficulty or "Unknown",
            collected = hasMount,
            attempts = RaidMount.GetAttempts(mount.mountID) or 0,
            mountID = mount.mountID or nil  -- Ensure mountID is passed
        })
    end
    return formattedData
end



