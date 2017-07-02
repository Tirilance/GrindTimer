local fontControls = {}

function GrindTimer.InitializeSettingsMenu()
    local r = GrindTimer.AccountSavedVariables.TextColor.R
    local g = GrindTimer.AccountSavedVariables.TextColor.G
    local b = GrindTimer.AccountSavedVariables.TextColor.B
    local OutlineTextChecked = (GrindTimer.AccountSavedVariables.OutlineText) and BSTATE_PRESSED or BSTATE_NORMAL
    GrindTimer.UpdateSettingWindowButtons()
    GrindTimerSettingsWindowOpacityEntryBox:SetText(GrindTimer.AccountSavedVariables.Opacity * 100)    
    GrindTimerSettingsWindowFontCheckBox:SetState(OutlineTextChecked)
    GrindTimerSettingsWindowColorSelectButtonColorPickerTexture:SetColor(r, g, b, 1)
    GrindTimer.UpdateFonts()
end

function GrindTimer.AddToFontControlsArray(control)
    table.insert(fontControls, control)
end

function GrindTimer.FirstLabelDropdownClick()
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    local isMenuClosed = firstDropDownMenu:IsHidden()
    
    -- Hide or show controls that may be overlapped by the dropdown menus.
    GrindTimerSettingsWindowCloseButton:SetHidden(false)
    GrindTimerSettingsWindowFontCheckBox:SetHidden(isMenuClosed)
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
    GrindTimer.UpdateLabels()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    firstDropDownMenu:SetHidden(true)

    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    secondDropDownButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(false)
    GrindTimerSettingsWindowFontCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    GrindTimer.UpdateSettingWindowButtons()
end

function GrindTimer.SecondLabelDropdownClick()
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local isMenuClosed = secondDropDownMenu:IsHidden()

    -- Hide or show controls that may be overlapped by the dropdown menus.
    secondDropDownMenu:SetHidden(not isMenuClosed)
    GrindTimerSettingsWindowCloseButton:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowFontCheckBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(isMenuClosed)
end

function GrindTimer.SecondLabelDropdownOptionClicked(option)
    GrindTimer.AccountSavedVariables.SecondLabelType = option
    GrindTimer.UpdateLabels()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    secondDropDownMenu:SetHidden(true)

    local closeButton = GrindTimerSettingsWindowCloseButton
    closeButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityEntryBox:SetHidden(false)
    GrindTimerSettingsWindowFontCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    GrindTimer.UpdateSettingWindowButtons()
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
    GrindTimer.UpdateUIOpacity()
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
    GrindTimer.UpdateUIOpacity()
end

function GrindTimer.OutlineTextCheckboxChecked(checkBox)
    local outlineText = GrindTimer.AccountSavedVariables.OutlineText
    if outlineText then
        checkBox:SetState(BSTATE_NORMAL)
        GrindTimer.AccountSavedVariables.OutlineText = false
    else
        checkBox:SetState(BSTATE_PRESSED)
        GrindTimer.AccountSavedVariables.OutlineText = true
    end

    GrindTimer.UpdateFonts()
end

function GrindTimer.UpdateFonts()
    local normalFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thin"
    local outlineFont = "$(BOLD_FONT)|$(KB_18)|outline"
    local r = GrindTimer.AccountSavedVariables.TextColor.R
    local g = GrindTimer.AccountSavedVariables.TextColor.G
    local b = GrindTimer.AccountSavedVariables.TextColor.B

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

        GrindTimer.AccountSavedVariables.TextColor.R = r
        GrindTimer.AccountSavedVariables.TextColor.G = g
        GrindTimer.AccountSavedVariables.TextColor.B = b
    end

    local currentR = GrindTimer.AccountSavedVariables.TextColor.R
    local currentG = GrindTimer.AccountSavedVariables.TextColor.G
    local currentB = GrindTimer.AccountSavedVariables.TextColor.B

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
    GrindTimerSettingsWindowFontCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)
    GrindTimerSettingsWindow:SetHidden(true)
end

function GrindTimer.UpdateSettingWindowButtons()
    local firstLabelType = GrindTimer.AccountSavedVariables.FirstLabelType
    local secondLabelType = GrindTimer.AccountSavedVariables.SecondLabelType
    local firstComboButton = GrindTimerSettingsWindowFirstLabelDropdownButton
    local secondComboButton = GrindTimerSettingsWindowSecondLabelDropdownButton

    if firstLabelType == 1 then
        firstComboButton:SetText("Time until level")
    elseif firstLabelType == 2 then
        firstComboButton:SetText("Experience until level")
    elseif firstLabelType == 3 then
        firstComboButton:SetText("Kills until level")
    elseif firstLabelType == 4 then
        firstComboButton:SetText("Experience per hour")
    elseif firstLabelType == 5 then
        firstComboButton:SetText("Levels per hour")
    elseif firstLabelType == 6 then
        firstComboButton:SetText("Kills in last 10 minutes")
    end

    if secondLabelType == 1 then
        secondComboButton:SetText("Time until level")
    elseif secondLabelType == 2 then
        secondComboButton:SetText("Experience until level")
    elseif secondLabelType == 3 then
        secondComboButton:SetText("Kills until level")
    elseif secondLabelType == 4 then
        secondComboButton:SetText("Experience per hour")
    elseif secondLabelType == 5 then
        secondComboButton:SetText("Levels per hour")
    elseif secondLabelType == 6 then
        secondComboButton:SetText("Kills in last 10 minutes")
    end
end
