-- Utils and constants for RaidMount UI
local addonName, RaidMount = ...

-- Color palette
RaidMount.COLORS = {
    primary = {0.4, 0.4, 0.4, 1},
    primaryDark = {0.2, 0.2, 0.2, 1},
    secondary = {0.6, 0.6, 0.6, 1},
    background = {0.05, 0.05, 0.05, 0.95},
    panelBg = {0.1, 0.1, 0.1, 0.9},
    headerBg = {0.02, 0.02, 0.02, 0.95},
    collected = {0.2, 0.8, 0.2, 1},
    uncollected = {0.9, 0.4, 0.4, 1},
    neutral = {0.7, 0.7, 0.7, 1},
    text = {0.95, 0.95, 0.95, 1},
    textSecondary = {0.8, 0.8, 0.8, 1},
    textMuted = {0.6, 0.6, 0.6, 1},
    gold = {1, 0.82, 0, 1},
    warning = {1, 0.65, 0, 1},
    success = {0.2, 0.8, 0.2, 1},
    error = {0.9, 0.2, 0.2, 1},
}

RaidMount.cachedFontPath = "Fonts\\FRIZQT__.TTF"

-- PrintAddonMessage is handled by RaidMount.lua

function RaidMount.CreateStyledBackground(parent, color, hoverColor)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(parent)
    bg:SetColorTexture(unpack(color or RaidMount.COLORS.panelBg))
    if hoverColor then
        parent:SetScript("OnEnter", function() bg:SetColorTexture(unpack(hoverColor)) end)
        parent:SetScript("OnLeave", function() bg:SetColorTexture(unpack(color or RaidMount.COLORS.panelBg)) end)
    end
    local border = parent:CreateTexture(nil, "BORDER")
    border:SetAllPoints(parent)
    border:SetColorTexture(unpack(RaidMount.COLORS.primary))
    border:SetAlpha(0.3)
    return bg, border
end

function RaidMount.CreateStandardFontString(parent, fontType, text, fontSize, color)
    local fontString = parent:CreateFontString(nil, "OVERLAY", fontType or "GameFontNormal")
    if fontSize then fontString:SetFont(RaidMount.cachedFontPath, fontSize, "OUTLINE") end
    if text then fontString:SetText(text) end
    if color then fontString:SetTextColor(unpack(color)) end
    return fontString
end

function RaidMount.PositionElement(element, parent, anchor, xOffset, yOffset)
    element:SetPoint(anchor or "TOPLEFT", parent, anchor or "TOPLEFT", xOffset or 0, yOffset or 0)
end

function RaidMount.CreateLabeledCheckbox(parent, labelText, xPos, yPos, isChecked, onClickCallback)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", xPos, yPos)
    checkbox:SetChecked(isChecked)
    checkbox.text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    checkbox.text:SetText(labelText)
    checkbox:SetScript("OnClick", function(self)
        if onClickCallback then onClickCallback(self:GetChecked()) end
    end)
    return checkbox
end

-- Create standard dropdown (placeholder - needs full implementation)
function RaidMount.CreateStandardDropdown(parent, options, defaultValue, onSelectionChanged)
    local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    
    UIDropDownMenu_Initialize(dropdown, function()
        for _, option in ipairs(options or {}) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option
            info.func = function()
                UIDropDownMenu_SetSelectedName(dropdown, option)
                UIDropDownMenu_SetText(dropdown, option)
                if onSelectionChanged then onSelectionChanged(option) end
            end
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    UIDropDownMenu_SetSelectedName(dropdown, defaultValue or "All")
    UIDropDownMenu_SetText(dropdown, defaultValue or "All")
    
    return dropdown
end