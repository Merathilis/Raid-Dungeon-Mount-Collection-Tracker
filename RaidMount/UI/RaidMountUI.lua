local addonName, RaidMount = ...
RaidMount = RaidMount or {}

if not RaidMount then
	print("|cFF33CCFFRaid|r|cFFFF0000Mount|r |cFFFF0000Error:|r " .. RaidMount.L("ERROR_RAIDMOUNT_NIL"))
	return
end

if not RaidMountAttempts then
	RaidMountAttempts = {}
end

local currentFilter = "All"
local currentContentTypeFilter = "All"
local currentSearch = ""
local currentExpansionFilter = "All"
local sortColumn = "mountName"
local sortDescending = false
local isStatsView = false

local cachedFontPath = "Fonts\\FRIZQT__.TTF"

local mountLookupBySpellID = {}
local mountLookupByName = {}
local expansionMountCounts = {}

function RaidMount.BuildMountLookupTables()
	if not RaidMount.mountInstances then return end

	mountLookupBySpellID = {}
	mountLookupByName = {}
	expansionMountCounts = {}

	for i, mount in ipairs(RaidMount.mountInstances) do
		if mount.spellID then
			mountLookupBySpellID[mount.spellID] = mount
		end
		if mount.mountName then
			mountLookupByName[mount.mountName:lower()] = mount
		end

		local expansion = mount.expansion or "Unknown"
		if not expansionMountCounts[expansion] then
			expansionMountCounts[expansion] = 0
		end
		expansionMountCounts[expansion] = expansionMountCounts[expansion] + 1
	end
end

local staticMountDataCache = nil
local staticDataVersion = 0
local filteredDataCache = nil
local sortCache = nil
local lastFilterState = {hash = ""}
local mountDataCache = nil

local mountDataCacheTime = 0
local CACHE_DURATION = 30

local function InvalidateCache()
	staticMountDataCache = nil
	filteredDataCache = nil
	sortCache = nil
	mountDataCache = nil
	mountDataCacheTime = 0
	lastFilterState = {hash = ""}
end

function RaidMount.GetCombinedMountData()
	local currentTime = GetTime()
	if mountDataCache and mountDataCacheTime > 0 and (currentTime - mountDataCacheTime) < CACHE_DURATION then
		return mountDataCache
	end

	local combinedData = {}

	if not RaidMount.mountInstances then
		return combinedData
	end

	for _, mount in ipairs(RaidMount.mountInstances) do
		local trackingKey = mount.spellID
		local attempts = RaidMount.GetAttempts and RaidMount.GetAttempts(mount) or 0
		local attemptData = RaidMountAttempts[trackingKey]
		local lastAttempt = "Never"
		local hasMount = false

		if attemptData and type(attemptData) == "table" then
			hasMount = attemptData.collected or false
			if attemptData.lastAttempt then
				lastAttempt = date("%d/%m/%y", attemptData.lastAttempt)
			end
		end

		if not hasMount and RaidMount.PlayerHasMount then
			hasMount = RaidMount.PlayerHasMount(mount.MountID, mount.itemID, mount.spellID)
			if hasMount and attemptData then
				attemptData.collected = true
			end
		end

		local lockoutInfo = RaidMount.GetRaidLockout and RaidMount.GetRaidLockout(mount.raidName) or "Unknown"
		table.insert(combinedData, {
			raidName = mount.raidName or "Unknown",
			bossName = mount.bossName or "Unknown",
			mountName = mount.mountName or "Unknown",
			location = mount.location or mount.raidName or "Unknown",
			dropRate = mount.dropRate or "~1%",
			resetTime = lockoutInfo,
			lockoutStatus = lockoutInfo,
			difficulty = mount.difficulty or "Unknown",
			expansion = mount.expansion or "Unknown",
			collected = hasMount,
			attempts = attempts,
			lastAttempt = lastAttempt,
			mountID = mount.MountID,
			spellID = mount.spellID,
			itemID = mount.itemID,
			contentType = mount.contentType or "Raid",
			type = mount.contentType or "Raid",
			collectorsBounty = mount.collectorsBounty
		})
	end

	mountDataCache = combinedData
	mountDataCacheTime = currentTime

	return combinedData
end

function RaidMount.ClearMountCache()
	InvalidateCache()
end

-- Get account-wide character data for a mount
local function GetAccountWideData(trackingKey)
	if not RaidMountAttempts[trackingKey] then
		RaidMountAttempts[trackingKey] = {
			total = 0,
			characters = {},
			lastAttempt = nil,
			collected = false
		}
	end

	local currentPlayer = UnitName("player") .. "-" .. GetRealmName()
	local accountData = RaidMountAttempts[trackingKey]

	if not accountData.characters then
		accountData.characters = {}
	end

	local totalAttempts = accountData.total or 0
	local lastAttemptDate = nil
	local charactersWithAttempts = {}
	local collectedBy = nil

	for charId, attempts in pairs(accountData.characters) do
		if attempts and attempts > 0 then
			-- Convert character ID back to readable name
			local charName = charId
			if charId == currentPlayer then
				charName = UnitName("player")
			else
				-- Try to extract character name from ID
				charName = charId:match("^([^%-]+)") or charId
			end

			table.insert(charactersWithAttempts, {
				name = charName,
				attempts = attempts,
				isCurrent = charId == currentPlayer
			})
		end
	end

	-- Sort characters by attempts (descending)
	table.sort(charactersWithAttempts, function(a, b) return a.attempts > b.attempts end)

	-- Get last attempt date
	if accountData.lastAttempt then
		lastAttemptDate = date("%d/%m/%y", accountData.lastAttempt) -- UK format
	end

	return {
		totalAttempts = totalAttempts,
		charactersWithAttempts = charactersWithAttempts,
		lastAttemptDate = lastAttemptDate,
		collectedBy = collectedBy
	}
end

RaidMount.ShowIconView = RaidMount.ShowIconView or function() end
RaidMount.HideIconView = RaidMount.HideIconView or function() end



