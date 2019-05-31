local windowHidden = true

function GrindTimer.UpdateSettingsWindowButtons()

    local labelButtons = { GrindTimerSettingsWindowFirstLabelDropdownButton,
                            GrindTimerSettingsWindowSecondLabelDropdownButton }

    local labelValues = { GrindTimer.AccountSavedVariables.FirstLabelType,
                            GrindTimer.AccountSavedVariables.SecondLabelType }

    for i in ipairs(labelButtons) do
        if labelValues[i] == 1 then
            labelButtons[i]:SetText("Dolmens until goal")

        elseif labelValues[i] == 2 then
            labelButtons[i]:SetText("Dungeon runs until goal")

        elseif labelValues[i] == 3 then
            labelButtons[i]:SetText("Experience per hour")

        elseif labelValues[i] == 4 then
            labelButtons[i]:SetText("Experience until goal")

        elseif labelValues[i] == 5 then
            labelButtons[i]:SetText("Kills in current session")

        elseif labelValues[i] == 6 then
            labelButtons[i]:SetText("Kills in last 15 minutes")

        elseif labelValues[i] == 7 then
            labelButtons[i]:SetText("Kills until goal")

        elseif labelValues[i] == 8 then
            labelButtons[i]:SetText("Levels in current session")

        elseif labelValues[i] == 9 then
            labelButtons[i]:SetText("Levels per hour")

        elseif labelValues[i] == 10 then
            labelButtons[i]:SetText("Time until goal")

        end
    end
end

function GrindTimer.InitializeSettingsMenu()
    local r, g, b = unpack(GrindTimer.AccountSavedVariables.TextColor)
    local outlineTextChecked = GrindTimer.AccountSavedVariables.OutlineText and BSTATE_PRESSED or BSTATE_NORMAL
    local secondLabelEnabled = GrindTimer.AccountSavedVariables.SecondLabelEnabled
    local secondLabelChecked = secondLabelEnabled and BSTATE_PRESSED or BSTATE_NORMAL
    local fontSize = GrindTimer.AccountSavedVariables.FontSize

    GrindTimerSettingsWindowOpacityTextBox:SetText(GrindTimer.AccountSavedVariables.Opacity * 100)
    GrindTimerSettingsWindowOutlineCheckBox:SetState(outlineTextChecked)
    GrindTimerSettingsWindowSecondLabelCheckBox:SetState(secondLabelChecked)
    GrindTimerSettingsWindowSecondLabelDropdownButton:SetEnabled(secondLabelEnabled)
    GrindTimerSettingsWindowColorSelectButtonColorPickerTexture:SetColor(r, g, b, 1)
    GrindTimerSettingsWindowFontSizeSlider:SetValue(fontSize)
    GrindTimerSettingsWindowFontSizeSliderTextBox:SetText(fontSize)

    GrindTimer.UpdateSettingsWindowButtons()

    local grindTimerSettingsFragment = ZO_HUDFadeSceneFragment:New(GrindTimerSettingsWindow, 0, 0)
    SCENE_MANAGER:GetScene("hud"):AddFragment(grindTimerSettingsFragment)
    SCENE_MANAGER:GetScene("hudui"):AddFragment(grindTimerSettingsFragment)

    GrindTimerSettingsWindow:SetHidden(true)
end

function GrindTimer.SettingsFirstLabelDropdownClicked()
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    local isMenuClosed = firstDropDownMenu:IsHidden()

    -- Hide or show controls that may be overlapped by the dropdown menus.
    GrindTimerSettingsWindowCloseButton:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOpacityTextBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowFontSizeSlider:SetHidden(isMenuClosed)

    if isMenuClosed then
        firstDropDownMenu:SetHidden(false)
        secondDropDownButton:SetHidden(true)
        secondDropDownMenu:SetHidden(true)
    else
        firstDropDownMenu:SetHidden(true)
        secondDropDownButton:SetHidden(false)
    end
end

function GrindTimer.SettingsSecondLabelDropdownClicked()
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    local isMenuClosed = secondDropDownMenu:IsHidden()

    -- Hide or show controls that may be overlapped by the dropdown menus.
    secondDropDownMenu:SetHidden(not isMenuClosed)
    GrindTimerSettingsWindowCloseButton:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOpacityTextBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(isMenuClosed)
    GrindTimerSettingsWindowFontSizeSlider:SetHidden(isMenuClosed)
end

function GrindTimer.SettingsMetricOptionClicked(targetLabel, selectedMetric)
    if targetLabel == 1 then
        GrindTimer.AccountSavedVariables.FirstLabelType = selectedMetric

        GrindTimerSettingsWindowFirstLabelDropdownOptions:SetHidden(true)
        GrindTimerSettingsWindowSecondLabelDropdownButton:SetHidden(false)
    elseif targetLabel == 2 then
        GrindTimer.AccountSavedVariables.SecondLabelType = selectedMetric

        GrindTimerSettingsWindowSecondLabelDropdownOptions:SetHidden(true)
        GrindTimerSettingsWindowCloseButton:SetHidden(false)
    end

    GrindTimer.UpdateMetricLabels()

    GrindTimerSettingsWindowOpacityTextBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)
    GrindTimerSettingsWindowFontSizeSlider:SetHidden(false)

    GrindTimer.UpdateSettingsWindowButtons()
end

function GrindTimer.FirstLabelDropdownOptionClicked(selectedMetric)
    GrindTimer.AccountSavedVariables.FirstLabelType = selectedMetric
    GrindTimer.UpdateMetricLabels()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    firstDropDownMenu:SetHidden(true)

    local secondDropDownButton = GrindTimerSettingsWindowSecondLabelDropdownButton
    secondDropDownButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityTextBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    GrindTimer.UpdateSettingsWindowButtons()
end

function GrindTimer.SecondLabelDropdownOptionClicked(selectedMetric)
    GrindTimer.AccountSavedVariables.SecondLabelType = selectedMetric
    GrindTimer.UpdateMetricLabels()

    -- When a dropdown option is clicked, hide the dropdown menu and reveal any hidden overlapped controls.
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions
    secondDropDownMenu:SetHidden(true)

    local closeButton = GrindTimerSettingsWindowCloseButton
    closeButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityTextBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)

    GrindTimer.UpdateSettingsWindowButtons()
end

function GrindTimer.OpacityTextBoxSubmitted(textBox, minValue, maxValue)
    local currentNumber = tonumber(textBox:GetText())

    if not currentNumber or currentNumber < minValue then
        currentNumber = minValue
        textBox:SetText(minValue)
    elseif currentNumber > maxValue then
        currentNumber = maxValue
        textBox:SetText(maxValue)
    end

    GrindTimer.AccountSavedVariables.Opacity = currentNumber * 0.01
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

    GrindTimer.SetFontUpdateFlag()
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

    GrindTimer.SetFontUpdateFlag()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.ColorPickerOpen(texture)

    local function ColorSelected(r, g, b)
        texture:SetColor(r, g, b, 1)

        GrindTimer.AccountSavedVariables.TextColor = {r, g, b}

        GrindTimer.SetFontUpdateFlag()
        GrindTimer.UpdateUIControls()
    end

    local currentR, currentG, currentB = unpack(GrindTimer.AccountSavedVariables.TextColor)
    COLOR_PICKER:Show(ColorSelected, currentR, currentG, currentB)
end

function GrindTimer.FontSizeValueChanged(slider, value)
    GrindTimerSettingsWindowFontSizeSliderTextBox:SetText(value)
    GrindTimer.AccountSavedVariables.FontSize = value

    GrindTimer.SetFontUpdateFlag()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.FontSizeTextSubmitted(textBox, minValue, maxValue)
    local currentNumber = tonumber(textBox:GetText())

    if not currentNumber or currentNumber < minValue then
        currentNumber = minValue
        textBox:SetText(minValue)
    elseif currentNumber > maxValue then
        currentNumber = maxValue
        textBox:SetText(maxValue)
    end

    GrindTimerSettingsWindowFontSizeSlider:SetValue(currentNumber)
    GrindTimer.AccountSavedVariables.FontSize = currentNumber

    GrindTimer.SetFontUpdateFlag()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.SettingsWindowShown()
    GrindTimerSettingsWindow:SetHidden(windowHidden)
end

function GrindTimer.SettingsWindowToggled()
    windowHidden = not windowHidden
    GrindTimerSettingsWindow:SetHidden(windowHidden)
end

function GrindTimer.SettingsCloseButtonClicked()
    local firstDropDownMenu = GrindTimerSettingsWindowFirstLabelDropdownOptions
    local secondDropDownMenu = GrindTimerSettingsWindowSecondLabelDropdownOptions

    -- Make sure if window is closed while a dropdown is open that overlapped controls don't stay hidden.
    firstDropDownMenu:SetHidden(true)
    secondDropDownMenu:SetHidden(true)
    GrindTimerSettingsWindowFirstLabelDropdownButton:SetHidden(false)
    GrindTimerSettingsWindowSecondLabelDropdownButton:SetHidden(false)
    GrindTimerSettingsWindowOpacityTextBox:SetHidden(false)
    GrindTimerSettingsWindowOutlineCheckBox:SetHidden(false)
    GrindTimerSettingsWindowColorSelectButton:SetHidden(false)
    GrindTimerSettingsWindowFontSizeSlider:SetHidden(false)
    GrindTimerSettingsWindow:SetHidden(true)
    windowHidden = true
end
