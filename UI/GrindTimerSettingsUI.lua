local fontControls = {}

local function UpdateFonts()
    local normalFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thin"
    local outlineFont = "$(BOLD_FONT)|$(KB_18)|outline"
    local r, g, b = unpack(GrindTimer.AccountSavedVariables.TextColor)

    for key, control in pairs(fontControls) do
        -- Apply color to font controls
        if control:GetType() == CT_BUTTON then
            control:SetNormalFontColor(r, g, b, 1)
        else
            control:SetColor(r, g, b, 1)
        end

        -- Apply font to font controls
        if GrindTimer.AccountSavedVariables.OutlineText then
            control:SetFont(outlineFont)
        else
            control:SetFont(normalFont)
        end
    end
end

local function UpdateSettingWindowButtons()
    
    local labelButtons = { GrindTimerSettingsWindowFirstLabelDropdownButton,
                            GrindTimerSettingsWindowSecondLabelDropdownButton }

    local labelValues = { GrindTimer.AccountSavedVariables.FirstLabelType,
                            GrindTimer.AccountSavedVariables.SecondLabelType }

    for i in ipairs(labelButtons) do
        if labelValues[i] == 1 then
            labelButtons[i]:SetText("Time until level")

        elseif labelValues[i] == 2 then
            labelButtons[i]:SetText("Experience until level")

        elseif labelValues[i] == 3 then
            labelButtons[i]:SetText("Kills until level")

        elseif labelValues[i] == 4 then
            labelButtons[i]:SetText("Experience per hour")

        elseif labelValues[i] == 5 then
            labelButtons[i]:SetText("Levels per hour")

        elseif labelValues[i] == 6 then
            labelButtons[i]:SetText("Kills in last 15 minutes")
        end
    end
end

function GrindTimer.InitializeSettingsMenu()
    local r, g, b = unpack(GrindTimer.AccountSavedVariables.TextColor)
    local outlineTextChecked = GrindTimer.AccountSavedVariables.OutlineText and BSTATE_PRESSED or BSTATE_NORMAL
    local secondLabelEnabled = GrindTimer.AccountSavedVariables.SecondLabelEnabled
    local secondLabelChecked = secondLabelEnabled and BSTATE_PRESSED or BSTATE_NORMAL

    GrindTimerSettingsWindowOpacityEntryBox:SetText(GrindTimer.AccountSavedVariables.Opacity * 100)    
    GrindTimerSettingsWindowOutlineCheckBox:SetState(outlineTextChecked)
    GrindTimerSettingsWindowSecondLabelCheckBox:SetState(secondLabelChecked)
    GrindTimerSettingsWindowSecondLabelDropdownButton:SetEnabled(secondLabelEnabled)
    GrindTimerSettingsWindowColorSelectButtonColorPickerTexture:SetColor(r, g, b, 1)

    UpdateSettingWindowButtons()
    UpdateFonts()
end

function GrindTimer.AddToFontControlsArray(control)
    table.insert(fontControls, control)
end

function GrindTimer.FirstLabelDropdownClicked()
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    local isMenuClosed = firstDropDownMenu:IsHidden()
    
    -- Hide or show controls that may be overlapped by the dropdown menus.
    GrindTimerSettingsWindowCloseButton:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(isMenuClosed)

    if isMenuClosed then
        firstDropDownMenu:SetHidden(false)
        secondDropDownButton:SetHidden(true)
        secondDropDownMenu:SetHidden(true)
    else
        firstDropDownMenu:SetHidden(true)
        secondDropDownButton:SetHidden(false)
    end
end

function GrindTimer.FirstLabelDropdownOptionClicked(option)
    GrindTimer.AccountSavedVariables.FirstLabelType = option
    GrindTimer.UpdateUIControls()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    firstDropDownMenu:SetHidden(true)

    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    secondDropDownButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    UpdateSettingWindowButtons()
end

function GrindTimer.SecondLabelDropdownClicked()
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local isMenuClosed = secondDropDownMenu:IsHidden()

    -- Hide or show controls that may be overlapped by the dropdown menus.
    secondDropDownMenu:SetHidden(not isMenuClosed)
    GrindTimerSettingsWindowCloseButton:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(isMenuClosed)
end

function GrindTimer.SecondLabelDropdownOptionClicked(option)
    GrindTimer.AccountSavedVariables.SecondLabelType = option
    GrindTimer.UpdateUIControls()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    secondDropDownMenu:SetHidden(true)

    local closeButton = GrindTimerSettingsWindowCloseButton
    closeButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    UpdateSettingWindowButtons()
end

function GrindTimer.OpacityEntryTextChanged(textBox)
    local currentText = textBox:GetText()
    local currentNumber = tonumber(currentText)
    if currentText == "" then return end

    -- If character entered is not a number, remove that character from the edit box.
    if currentNumber == nil then
        textBox:SetText(currentText:sub(1, -2))
        return
    end

    if currentNumber > 100 then
        textBox:SetText("100")
    end

    if currentNumber < 0 then
        textBox:SetText("0")
    end

    local newOpacity = currentNumber / 100
    GrindTimer.AccountSavedVariables.Opacity = newOpacity
    GrindTimer.UpdateUIControls()
end

function GrindTimer.OpacityEntryTextSubmitted(textBox)
    local currentText = textBox:GetText()
    local currentNumber = tonumber(currentText)
    local newOpacity = 0

    if currentNumber ~= nil and currentText ~= "" then
        newOpacity = currentNumber / 100
    else
        textBox:SetText("0")
    end
    
    GrindTimer.AccountSavedVariables.Opacity = newOpacity
    GrindTimer.UpdateUIControls()
end

function GrindTimer.SecondLabelCheckBoxChecked(checkBox)
    if GrindTimer.AccountSavedVariables.SecondLabelEnabled then
        GrindTimer.AccountSavedVariables.SecondLabelEnabled = false
        GrindTimerSettingsWindowSecondLabelDropdownButton:SetEnabled(false)
        checkBox:SetState(BSTATE_NORMAL)
    else
        GrindTimer.AccountSavedVariables.SecondLabelEnabled = true
        GrindTimerSettingsWindowSecondLabelDropdownButton:SetEnabled(true)
        checkBox:SetState(BSTATE_PRESSED)
    end

    GrindTimer.UpdateUIControls()
end

function GrindTimer.OutlineTextCheckBoxChecked(checkBox)
    local outlineText = GrindTimer.AccountSavedVariables.OutlineText
    if outlineText then
        checkBox:SetState(BSTATE_NORMAL)
        GrindTimer.AccountSavedVariables.OutlineText = false
    else
        checkBox:SetState(BSTATE_PRESSED)
        GrindTimer.AccountSavedVariables.OutlineText = true
    end

    UpdateFonts()
end

function GrindTimer.ColorPickerOpen(texture)

    local function ColorSelected(r, g, b)
        texture:SetColor(r, g, b, 1)

        for key, control in pairs(fontControls) do
            if control:GetType() == CT_BUTTON then
                control:SetNormalFontColor(r, g, b, 1)
            else
                control:SetColor(r, g, b, 1)
            end
        end

        GrindTimer.AccountSavedVariables.TextColor = {r, g, b}
    end

    local currentR, currentG, currentB = unpack(GrindTimer.AccountSavedVariables.TextColor)
    COLOR_PICKER:Show(ColorSelected, currentR, currentG, currentB)
end

function GrindTimer.SettingsClosed()
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions

    -- Make sure if window is closed while a dropdown is open that overlapped controls don't stay hidden.
    firstDropDownMenu:SetHidden(true)
    secondDropDownMenu:SetHidden(true)
    GrindTimerSettingsWindowFirstLabelDropdownButton:SetHidden(false)
    GrindTimerSettingsWindowSecondLabelDropdownButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)
    GrindTimerSettingsWindow:SetHidden(true)
end
