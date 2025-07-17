-- Minimap Button for RaidMount
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local buttonName = "RaidMountMinimapButton"
local minimapButton
local dragAngle = 0

-- Saved position
RaidMountSettings = RaidMountSettings or {}
RaidMountSettings.minimap = RaidMountSettings.minimap or { angle = 0 }

dragAngle = RaidMountSettings.minimap.angle or 0

local function UpdateButtonPosition()
	local angle = dragAngle or 0
	local minimapWidth = Minimap:GetWidth() / 2
	local minimapHeight = Minimap:GetHeight() / 2
	local radius = math.min(minimapWidth, minimapHeight) - 5 -- 5px padding from edge
	local x = math.cos(math.rad(angle)) * radius
	local y = math.sin(math.rad(angle)) * radius
	minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnDragStart(self)
	self:SetScript("OnUpdate", function(self)
		local mx, my = Minimap:GetCenter()
		local px, py = GetCursorPosition()
		local scale = Minimap:GetEffectiveScale()
		px, py = px / scale, py / scale
		local dx, dy = px - mx, py - my
		dragAngle = math.deg(math.atan2(dy, dx)) % 360
		RaidMountSettings.minimap.angle = dragAngle
		UpdateButtonPosition()
	end)
end

local function OnDragStop(self)
	self:SetScript("OnUpdate", nil)
end

local function OnClick(self, button)
	if RaidMount.ShowUI then
		RaidMount.ShowUI()
	end
end

local function OnEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText("RaidMount: Open/Close Tracker", 1, 1, 1)
	GameTooltip:Show()
end

local function OnLeave(self)
	GameTooltip:Hide()
end

function RaidMount.CreateMinimapButton()
	if minimapButton then return end
	minimapButton = CreateFrame("Button", buttonName, Minimap)
	minimapButton:SetSize(32, 32)
	minimapButton:SetFrameStrata("MEDIUM")
	minimapButton:SetMovable(true)
	minimapButton:RegisterForDrag("LeftButton")
	minimapButton:SetClampedToScreen(true)

	-- (No border, no background)

	-- Larger blue 'R' with shadow
	local rText = minimapButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	rText:SetFont("Fonts\\FRIZQT__.TTF", 17, "OUTLINE")
	rText:SetText("R")
	rText:SetTextColor(0.1, 0.6, 1, 1)
	rText:SetPoint("LEFT", minimapButton, "LEFT", 7, 0)
	rText:SetShadowColor(0, 0, 0, 0.8)
	rText:SetShadowOffset(1, -1)

	-- Slightly smaller red 'M' with shadow, right next to 'R'
	local mText = minimapButton:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	mText:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
	mText:SetText("M")
	mText:SetTextColor(1, 0.1, 0.1, 1)
	mText:SetPoint("LEFT", rText, "RIGHT", -5, -1)
	mText:SetShadowColor(0, 0, 0, 0.8)
	mText:SetShadowOffset(1, -1)

	minimapButton:SetScript("OnDragStart", OnDragStart)
	minimapButton:SetScript("OnDragStop", OnDragStop)
	minimapButton:SetScript("OnClick", OnClick)
	minimapButton:SetScript("OnEnter", OnEnter)
	minimapButton:SetScript("OnLeave", OnLeave)

	UpdateButtonPosition()
end

-- Create the button on ADDON_LOADED
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, event, arg1)
	if arg1 == addonName then
		RaidMount.CreateMinimapButton()
	end
end)
