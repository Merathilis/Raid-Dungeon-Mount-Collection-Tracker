-- Core Localization system for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Initialize locale table
RaidMount.LOCALE = RaidMount.LOCALE or {}

-- Get localized string function
function RaidMount.L(key, ...)
	local locale = RaidMount.LOCALE or {}
	local text = locale[key] or key

	if select("#", ...) > 0 then
		return string.format(text, ...)
	end

	return text
end

-- Export the localization function
RaidMount.L = RaidMount.L
