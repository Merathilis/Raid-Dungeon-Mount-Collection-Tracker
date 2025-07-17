local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Enhanced lockout checking with better formatting
function RaidMount.GetRaidLockout(instanceName)
	if not instanceName then return "No lockout" end

	-- Debug block removed

	for i = 1, GetNumSavedInstances() do
		local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)

		if name and name:lower():find(instanceName:lower()) then
			if locked or extended then
				-- Calculate time remaining
				local days = math.floor(reset / 86400)
				local hours = math.floor((reset % 86400) / 3600)
				local minutes = math.floor((reset % 3600) / 60)

				-- Format time string
				local timeString = ""
				if days > 0 then
					timeString = string.format("%dd %dh %dm", days, hours, minutes)
				elseif hours > 0 then
					timeString = string.format("%dh %dm", hours, minutes)
				elseif minutes > 0 then
					timeString = string.format("%dm", minutes)
				else
					timeString = "< 1m"
				end

				return timeString
			end
		end
	end

	return "No lockout"
end

-- Enhanced lockout color with time formatting
function RaidMount.GetLockoutColor(instanceName, isRaid)
	if not isRaid then
		return "|cFF00FF00", "", false
	end

	for i = 1, GetNumSavedInstances() do
		local name, id, reset, difficulty, locked, extended = GetSavedInstanceInfo(i)
		if name and instanceName and name:lower():find(instanceName:lower()) then
			if locked or extended then
				local days = math.floor(reset / 86400)
				local hours = math.floor((reset % 86400) / 3600)
				local minutes = math.floor((reset % 3600) / 60)

				local timeString = ""
				if days > 0 then
					timeString = string.format("%dd %dh %dm", days, hours, minutes)
				elseif hours > 0 then
					timeString = string.format("%dh %dm", hours, minutes)
				elseif minutes > 0 then
					timeString = string.format("%dm", minutes)
				else
					timeString = "< 1m"
				end

				return "|cFFFF0000", timeString, true
			end
		end
	end

	return "|cFF00FF00", "", false
end

-- Get detailed lockout information for tooltip
function RaidMount.GetDetailedLockoutInfo(instanceName)
	if not instanceName then return nil end

	local lockouts = {}

	for i = 1, GetNumSavedInstances() do
		local name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)

		if name and name:lower():find(instanceName:lower()) then
			if locked or extended then
				local days = math.floor(reset / 86400)
				local hours = math.floor((reset % 86400) / 3600)
				local minutes = math.floor((reset % 3600) / 60)

				table.insert(lockouts, {
					difficulty = difficultyName or "Unknown",
					timeRemaining = {days = days, hours = hours, minutes = minutes},
					extended = extended
				})
			end
		end
	end

	return lockouts
end

-- Check if player can enter instance
function RaidMount.CanEnterInstance(instanceName, difficulty)
	if not instanceName then return true end

	for i = 1, GetNumSavedInstances() do
		local name, id, reset, savedDifficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName = GetSavedInstanceInfo(i)

		if name and name:lower():find(instanceName:lower()) then
			if difficulty and difficultyName then
				if difficultyName:lower() == difficulty:lower() then
					return not (locked or extended)
				end
			else
				return not (locked or extended)
			end
		end
	end

	return true
end
