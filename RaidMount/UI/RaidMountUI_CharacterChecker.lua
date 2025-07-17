-- Character Data Checker for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

-- Character Data Checker Frame
local characterCheckerFrame = nil
local cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- Create the character checker frame
local function CreateCharacterCheckerFrame()
	if characterCheckerFrame then return characterCheckerFrame end

	characterCheckerFrame = CreateFrame("Frame", "RaidMountCharacterChecker", UIParent, "BackdropTemplate")
	characterCheckerFrame:SetSize(400, 300)
	-- Position relative to main RaidMount frame if it exists, otherwise center
	if RaidMount.RaidMountFrame and RaidMount.RaidMountFrame:IsShown() then
		characterCheckerFrame:SetPoint("LEFT", RaidMount.RaidMountFrame, "RIGHT", 10, 0)
	else
		characterCheckerFrame:SetPoint("CENTER")
	end
	characterCheckerFrame:SetBackdrop({
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	characterCheckerFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
	characterCheckerFrame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
	characterCheckerFrame:SetMovable(true)
	characterCheckerFrame:EnableMouse(true)
	characterCheckerFrame:RegisterForDrag("LeftButton")
	characterCheckerFrame:SetScript("OnDragStart", characterCheckerFrame.StartMoving)
	characterCheckerFrame:SetScript("OnDragStop", characterCheckerFrame.StopMovingOrSizing)
	characterCheckerFrame:Hide()

	-- Title
	local title = characterCheckerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", characterCheckerFrame, "TOP", 0, -15)
	title:SetFont(cachedFontPath, 24, "OUTLINE")
	title:SetText("|cFF33CCFFRaid|r and |cFF33CCFFDungeon|r |cFFFF0000Mount|r |cFFFFD700Tracker|r - Alt Data")
	characterCheckerFrame.title = title

	-- Close button
	local closeButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelCloseButton")
	closeButton:SetPoint("TOPRIGHT", characterCheckerFrame, "TOPRIGHT", -5, -5)
	closeButton:SetScript("OnClick", function() characterCheckerFrame:Hide() end)

	-- Add a subtitle for instructions
	local subtitle = characterCheckerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	subtitle:SetPoint("TOP", characterCheckerFrame, "TOP", 0, -45)
	subtitle:SetFont(cachedFontPath, 12, "OUTLINE")
	subtitle:SetText("|cFF999999Alt mount attempt data|r")
	subtitle:SetTextColor(0.6, 0.6, 0.6, 1)

	-- Scroll frame for character list (adjusted to make room for buttons)
	local scrollFrame = CreateFrame("ScrollFrame", nil, characterCheckerFrame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", characterCheckerFrame, "TOPLEFT", 15, -70)
	scrollFrame:SetPoint("BOTTOMRIGHT", characterCheckerFrame, "BOTTOMRIGHT", -35, 50)

	local scrollChild = CreateFrame("Frame", nil, scrollFrame)
	scrollChild:SetSize(350, 800)
	scrollFrame:SetScrollChild(scrollChild)

	characterCheckerFrame.scrollFrame = scrollFrame
	characterCheckerFrame.scrollChild = scrollChild

	-- Add buttons at the bottom
	local refreshButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelButtonTemplate")
	refreshButton:SetSize(80, 25)
	refreshButton:SetPoint("BOTTOMLEFT", characterCheckerFrame, "BOTTOMLEFT", 15, 10)
	refreshButton:SetText("Refresh")
	refreshButton:SetScript("OnClick", function()
		if RaidMount.RefreshCommand then
			RaidMount.RefreshCommand()
		else
			print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Refresh function not available.")
		end
	end)

	local verifyButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelButtonTemplate")
	verifyButton:SetSize(80, 25)
	verifyButton:SetPoint("LEFT", refreshButton, "RIGHT", 10, 0)
	verifyButton:SetText("Verify")
	verifyButton:SetScript("OnClick", function()
		if RaidMount.VerifyCommand then
			RaidMount.VerifyCommand()
		else
			print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Verify function not available.")
		end
	end)

	local debugButton = CreateFrame("Button", nil, characterCheckerFrame, "UIPanelButtonTemplate")
	debugButton:SetSize(80, 25)
	debugButton:SetPoint("LEFT", verifyButton, "RIGHT", 10, 0)
	debugButton:SetText("Debug")
	debugButton:SetScript("OnClick", function()
		if RaidMount.DebugDataCommand then
			RaidMount.DebugDataCommand()
		else
			print("|cFF33CCFFRaid|r|cFFFF0000Mount|r: Debug function not available.")
		end
	end)

	return characterCheckerFrame
end

-- Get character data status
local function GetCharacterDataStatus(characterID)
	if not RaidMountAttempts then return "No data" end

	local hasData = false
	local mountCount = 0
	local totalAttempts = 0

	for spellID, attemptData in pairs(RaidMountAttempts) do
		if type(attemptData) == "table" and attemptData.characters then
			local charData = attemptData.characters[characterID]
			if charData then
				hasData = true
				mountCount = mountCount + 1

				local count = 0
				if type(charData) == "number" then
					count = charData
				elseif type(charData) == "table" and charData.count then
					count = charData.count
				end
				totalAttempts = totalAttempts + count
			end
		end
	end

	if hasData then
		return string.format("|cFF00FF00%d mounts, %d attempts|r", mountCount, totalAttempts)
	else
		return "|cFFFF0000No data|r"
	end
end

-- Get character class color
local function GetCharacterClassColor(characterID)
	if not RaidMountAttempts then return "FFFFFF" end

	for spellID, attemptData in pairs(RaidMountAttempts) do
		if type(attemptData) == "table" and attemptData.classes and attemptData.classes[characterID] then
			local class = attemptData.classes[characterID]
			local colors = {
				["WARRIOR"] = "C79C6E",
				["PALADIN"] = "F58CBA",
				["HUNTER"] = "ABD473",
				["ROGUE"] = "FFF569",
				["PRIEST"] = "FFFFFF",
				["DEATHKNIGHT"] = "C41F3B",
				["SHAMAN"] = "0070DE",
				["MAGE"] = "69CCF0",
				["WARLOCK"] = "9482C9",
				["MONK"] = "00FF96",
				["DRUID"] = "FF7D0A",
				["DEMONHUNTER"] = "A330C9",
				["EVOKER"] = "33937F"
			}
			return colors[class] or "FFFFFF"
		end
	end

	return "FFFFFF"
end

-- Update character checker display
function RaidMount.UpdateCharacterChecker()
	local frame = CreateCharacterCheckerFrame()
	local scrollChild = frame.scrollChild

	-- Clear existing content
	for i = 1, scrollChild:GetNumChildren() do
		local child = select(i, scrollChild:GetChildren())
		if child then
			child:Hide()
			child:SetParent(nil)
		end
	end

	-- Get all character IDs from saved data (both mount data and logged characters)
	local characters = {}

	-- Add characters from mount attempt data
	if RaidMountAttempts then
		for spellID, attemptData in pairs(RaidMountAttempts) do
			if type(attemptData) == "table" and attemptData.characters then
				for characterID, charData in pairs(attemptData.characters) do
					if not characters[characterID] then
						characters[characterID] = { hasMountData = true }
					end
				end
			end
		end
	end

	-- Add characters that have logged in (from RaidMountSaved.loggedCharacters)
	if RaidMountSaved and RaidMountSaved.loggedCharacters then
		for characterID, charInfo in pairs(RaidMountSaved.loggedCharacters) do
			if not characters[characterID] then
				characters[characterID] = { hasMountData = false }
			end
		end
	end

	-- Sort characters alphabetically
	local sortedCharacters = {}
	for characterID in pairs(characters) do
		table.insert(sortedCharacters, characterID)
	end
	table.sort(sortedCharacters)

	-- Create character list
	local yOffset = 0
	for i, characterID in ipairs(sortedCharacters) do
		local shortName = characterID:match("([^%-]+)") or characterID
		local realmName = characterID:match("^[^%-]+%-([^%-]+)$") or "Unknown"
		local charInfo = characters[characterID]
		local status = GetCharacterDataStatus(characterID)
		local color = GetCharacterClassColor(characterID)

		-- Character name and realm
		local nameText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		nameText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, yOffset)
		nameText:SetFont(cachedFontPath, 14, "OUTLINE")
		nameText:SetText("|cFF" .. color .. shortName .. "|r - " .. realmName)
		nameText:SetJustifyH("LEFT")

		-- Status
		local statusText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		statusText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 180, yOffset)
		statusText:SetFont(cachedFontPath, 14, "OUTLINE")

		if charInfo and charInfo.hasMountData then
			statusText:SetText(status)
		else
			statusText:SetText("|cFF999999Logged in, no mount data|r")
		end
		statusText:SetJustifyH("LEFT")

		yOffset = yOffset - 25
	end

	if #sortedCharacters == 0 then
		local noDataText = frame.scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		noDataText:SetPoint("TOPLEFT", frame.scrollChild, "TOPLEFT", 10, 0)
		noDataText:SetFont(cachedFontPath, 14, "OUTLINE")
		noDataText:SetText("|cFF999999No alt data found. Use /rm refresh on each character.|r")
	end

	frame:Show()
end

-- Slash command handler
local function SlashCommandHandler(msg)
	if msg == "characters" or msg == "chars" or msg == "check" then
		RaidMount.UpdateCharacterChecker()
	else
		print("|cFF33CCFFRaid|r|cFFFF0000Mount|r Alt Checker:")
		print("  /rm characters - Show alt data status")
		print("  /rm chars - Same as above")
		print("  /rm check - Same as above")
	end
end

-- Register slash command
SLASH_RAIDMOUNT_CHARACTERS1 = "/rm"
SLASH_RAIDMOUNT_CHARACTERS2 = "/raidmount"
SlashCmdList["RAIDMOUNT_CHARACTERS"] = function(msg)
	if msg:match("^characters?") or msg:match("^chars?") or msg:match("^check") then
		SlashCommandHandler(msg)
	end
end
