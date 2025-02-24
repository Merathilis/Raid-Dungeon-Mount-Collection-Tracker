local addonName, RaidMount = ...
RaidMount = RaidMount or {}

--  Cache to avoid duplicate checks
RaidMount.MountCache = {}

--  Check if player owns the mount (by mountID or itemID)
function RaidMount.PlayerHasMount(mountID, itemID)
    

    -- Check cache first
    if RaidMount.MountCache[mountID] ~= nil then
        return RaidMount.MountCache[mountID]
    end

    -- Convert itemID to mountID if needed
    if not mountID and itemID then
        mountID = C_MountJournal.GetMountFromItem(itemID)
    end

    -- If still nil, return false
    if not mountID then
        return false
    end

    -- Check player's mount collection
    local collectedMounts = C_MountJournal.GetMountIDs()
    for _, collectedID in ipairs(collectedMounts) do
        local _, _, _, _, _, _, _, _, _, _, collected = C_MountJournal.GetMountInfoByID(collectedID)
        if collectedID == mountID and collected then
            RaidMount.MountCache[mountID] = true  -- Cache result
            return true
        end
    end

    -- Cache as false if not collected
    RaidMount.MountCache[mountID] = false
    return false
end
