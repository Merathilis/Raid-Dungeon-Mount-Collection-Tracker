local addonName, RaidMount = ...
RaidMount = RaidMount or {}

--  Helper to format time remaining
local function FormatTimeRemaining(seconds)
    local days = math.floor(seconds / (24 * 3600))
    local hours = math.floor((seconds % (24 * 3600)) / 3600)
    local minutes = math.floor((seconds % 3600) / 60)

    local timeString = ""
    if days > 0 then timeString = timeString .. days .. "d " end
    if hours > 0 then timeString = timeString .. hours .. "h " end
    if minutes > 0 then timeString = timeString .. minutes .. "m" end

    return timeString
end

--  Main function to get weekly raid lockouts only
function RaidMount.GetRaidLockout(raidName)
    for i = 1, GetNumSavedInstances() do
        local name, _, reset, _, locked, extended, _, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)

        -- ✅ Filter: Only Weekly Raids (skip dungeons and non-raids)
        if isRaid and name == raidName then
            if reset > 0 and locked then
                return FormatTimeRemaining(reset), difficultyName
            elseif extended then
                return "Extended", difficultyName
            end
        end
    end
    return "No lockout", nil
end
