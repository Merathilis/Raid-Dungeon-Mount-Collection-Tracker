-- ElvUI Skinning support
local addonName, RaidMount = ...
RaidMount = RaidMount or {}

local E = unpack(ElvUI)
local S = E:GetModule("Skins")

function RaidMount.SkinMainFrame()
	local frame = RaidMount.RaidMountFrame
	if not frame then return end

	frame:StripTextures()
	frame:SetTemplate("Transparent")
	S:HandleCloseButton(frame.CloseButton)
	frame.Title:FontTemplate(nil, 26)
end

function RaidMount.SkinHeaderFrame()
	local frame = RaidMount.HeaderFrame
	if not frame then return end

	frame:StripTextures()
	frame:SetTemplate("Transparent")
end

function RaidMount.SkinScrollFrame()
	local frame = RaidMount.RaidMountFrame
	if not frame then return end

	local scrollFrame = RaidMount.ScrollFrame
	if scrollFrame.ScrollBar then
		S:HandleScrollBar(scrollFrame.ScrollBar)
	end
end

function RaidMount.SkinSearchAndFilters()
	local searchBox = RaidMount.SearchBox

	S:HandleEditBox(searchBox)
end

function RaidMount.SkinFilterDropdowns()
	local frame = RaidMount.RaidMountFrame
	if not frame then return end

	local collectedDropdown = RaidMount.CollectedDropdown
	S:HandleDropDownBox(collectedDropdown)
	collectedDropdown.Text:ClearAllPoints()
	collectedDropdown.Text:SetPoint("CENTER", collectedDropdown.backdrop)

	local expansionDropdown = RaidMount.ExpansionDropdown
	S:HandleDropDownBox(expansionDropdown, 160)
	expansionDropdown.Text:ClearAllPoints()
	expansionDropdown.Text:SetPoint("CENTER")

	local contentTypeDropdown = RaidMount.ContentTypeDropdown
	S:HandleDropDownBox(contentTypeDropdown)
	contentTypeDropdown.Text:ClearAllPoints()
	contentTypeDropdown.Text:SetPoint("CENTER")

	local difficultyDropdown = RaidMount.DifficultyDropdown
	S:HandleDropDownBox(difficultyDropdown, 130)
	difficultyDropdown.Text:ClearAllPoints()
	difficultyDropdown.Text:SetPoint("CENTER")

	local clearFiltersButton = RaidMount.ClearFiltersButton
	S:HandleButton(clearFiltersButton)

	local iconViewButton = RaidMount.FilterContainer.IconViewButton
	S:HandleButton(iconViewButton)
end

function RaidMount.SkinProgressBar()
	local frame = RaidMount.RaidMountFrame
	if not frame then return end

	local progressBar = frame.progressBar
	progressBar:StripTextures()
	progressBar:SetStatusBarTexture(E.media.normTex)
	progressBar:CreateBackdrop()
	E:RegisterStatusBar(progressBar)
end

function RaidMount.SkinButtons()
	local frame = RaidMount.RaidMountFrame
	if not frame then return end

	local statsBtn = frame.StatsButton
	S:HandleButton(statsBtn)

	local tooltipCheckbox = frame.tooltipCheckbox
	S:HandleCheckBox(tooltipCheckbox)

	local soundCheckbox = frame.soundCheckbox
	S:HandleCheckBox(soundCheckbox)

	local popupCheckbox = frame.popupCheckbox
	S:HandleCheckBox(popupCheckbox)

	local charCheckerButton = frame.charCheckerButton
	S:HandleButton(charCheckerButton)
end

function RaidMount.ElvUI()
	if not E then return end

	RaidMount.SkinMainFrame()
	RaidMount.SkinHeaderFrame()
	RaidMount.SkinScrollFrame()
	RaidMount.SkinSearchAndFilters()
	RaidMount.SkinFilterDropdowns()
	RaidMount.SkinProgressBar()
	RaidMount.SkinButtons()
end
