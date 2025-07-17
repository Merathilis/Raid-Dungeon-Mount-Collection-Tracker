local addonName, RaidMount = ...
RaidMount = RaidMount or {}

RaidMount.MountCache = {}

function RaidMount.RefreshMountCollection()
	RaidMount.ClearMountCache()

	local collectedCount = 0
	local totalChecked = 0

	local collectedSpellIDs = {}
	local mountIDs = C_MountJournal.GetMountIDs()

	if mountIDs then
		for _, mountID in ipairs(mountIDs) do
			local name, spellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(mountID)

			if isCollected and spellID then
				collectedSpellIDs[spellID] = true
			end
		end
	end

	for _, mount in ipairs(RaidMount.mountInstances or {}) do
		if mount.spellID then
			totalChecked = totalChecked + 1
			local hasMount = collectedSpellIDs[mount.spellID] == true

			local trackingKey = mount.spellID

			if not RaidMountAttempts[trackingKey] then
				RaidMountAttempts[trackingKey] = {
					total = 0,
					characters = {},
					lastAttempt = nil,
					collected = false
				}
			end

			RaidMountAttempts[trackingKey].collected = hasMount
			mount.collected = hasMount

			if hasMount then
				collectedCount = collectedCount + 1
			end
		end
	end

	if RaidMount.PopulateUI then
		RaidMount.PopulateUI()
	end
end

local mountCache = {}
local cacheExpiry = {}
local CACHE_DURATION = 300

function RaidMount.PlayerHasMount(mountID, itemID, spellID)
	if not mountID then
		return false
	end

	local cacheKey = tostring(mountID)
	if mountCache[cacheKey] and cacheExpiry[cacheKey] and GetTime() < cacheExpiry[cacheKey] then
		return mountCache[cacheKey]
	end

	local hasMount = false

	if mountID and IsSpellKnown(mountID) then
		hasMount = true
	end

	if not hasMount and C_MountJournal then
		local mountIDs = C_MountJournal.GetMountIDs()
		if mountIDs then
			for _, jMountID in ipairs(mountIDs) do
				local name, jSpellID, icon, isActive, isUsable, sourceType, isFavorite, isFactionSpecific, faction, shouldHideOnChar, isCollected = C_MountJournal.GetMountInfoByID(jMountID)

				if jMountID == mountID or (spellID and jSpellID == spellID) then
					hasMount = isCollected == true
					break
				end
			end
		end
	end

	if not hasMount and itemID and itemID > 0 then
		if C_Item and C_Item.DoesItemExistByID then
			if C_Item.DoesItemExistByID(itemID) then
				local itemCount = C_Item.GetItemCount(itemID, true, false, true)
				if itemCount > 0 then
					hasMount = true
				end
			end
		end
	end

	mountCache[cacheKey] = hasMount
	cacheExpiry[cacheKey] = GetTime() + CACHE_DURATION

	return hasMount
end

function RaidMount.ClearMountCache()
	mountCache = {}
	cacheExpiry = {}
end
