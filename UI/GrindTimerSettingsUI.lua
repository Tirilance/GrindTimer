local windowHidden = true
local coveredControls = {}

function GrindTimer.UpdateSettingsWindowButtons()

    local labelButtons = { GrindTimerSettingsWindowFirstLabelDropdownButton,
                           GrindTimerSettingsWindowSecondLabelDropdownButton }

    local labelValues = { GrindTimer.AccountSavedVariables.FirstLabelType,
                          GrindTimer.AccountSavedVariables.SecondLabelType }

    for i in ipairs(labelButtons) do
        if labelValues[i] == GrindTimer.Metric.DolmensRemaining then
            labelButtons[i]:SetText("Dolmens until goal")

        elseif labelValues[i] == GrindTimer.Metric.DungeonRunsRemaining then
            labelButtons[i]:SetText("Dungeon runs until goal")

        elseif labelValues[i] == GrindTimer.Metric.ExpPerMinute then
            labelButtons[i]:SetText("Experience per minute")

        elseif labelValues[i] == GrindTimer.Metric.ExpPerHour then
            labelButtons[i]:SetText("Experience per hour")

        elseif labelValues[i] == GrindTimer.Metric.ExpRemaining then
            labelButtons[i]:SetText("Experience until goal")

        elseif labelValues[i] == GrindTimer.Metric.KillsInSession then
            labelButtons[i]:SetText("Kills in current session")

        elseif labelValues[i] == GrindTimer.Metric.KillsRecently then
            labelButtons[i]:SetText("Kills in last 15 minutes")

        elseif labelValues[i] == GrindTimer.Metric.KillsRemaining then
            labelButtons[i]:SetText("Kills until goal")

        elseif labelValues[i] == GrindTimer.Metric.LevelsInSession then
            labelButtons[i]:SetText("Levels in current session")

        elseif labelValues[i] == GrindTimer.Metric.LevelsPerHour then
            labelButtons[i]:SetText("Levels per hour")

        elseif labelValues[i] == GrindTimer.Metric.TimeRemaining then
            labelButtons[i]:SetText("Time until goal")
        end
    end
end

function GrindTimer.InitializeSettingsMenu()
    local r, g, b = unpack(GrindTimer.AccountSavedVariables.TextColor)
    local outlineTextChecked = GrindTimer.AccountSavedVariables.OutlineText and BSTATE_PRESSED or BSTATE_NORMAL
    local abbreviateNumbersChecked = GrindTimer.AccountSavedVariables.AbbreviateNumbers and BSTATE_PRESSED or BSTATE_NORMAL
    local abbreviateTimeChecked = GrindTimer.AccountSavedVariables.AbbreviateTime and BSTATE_PRESSED or BSTATE_NORMAL
    local secondLabelEnabled = GrindTimer.AccountSavedVariables.SecondLabelEnabled
    local secondLabelChecked = secondLabelEnabled and BSTATE_PRESSED or BSTATE_NORMAL
    local fontSize = GrindTimer.AccountSavedVariables.FontSize

    GrindTimerSettingsWindowOpacityTextBox:SetText(GrindTimer.AccountSavedVariables.Opacity * 100)
    GrindTimerSettingsWindowOutlineCheckBox:SetState(outlineTextChecked)
    GrindTimerSettingsWindowSecondLabelCheckBox:SetState(secondLabelChecked)
    GrindTimerSettingsWindowAbbreviateNumbersCheckBox:SetState(abbreviateNumbersChecked)
    GrindTimerSettingsWindowAbbreviateTimeCheckBox:SetState(abbreviateTimeChecked)
    GrindTimerSettingsWindowSecondLabelDropdownButton:SetEnabled(secondLabelEnabled)
    GrindTimerSettingsWindowColorSelectButtonColorPickerTexture:SetColor(r, g, b, 1)
    GrindTimerSettingsWindowFontSizeTextBox:SetText(fontSize)

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

    GrindTimerSettingsWindowCloseButton:SetHidden(false)

    for key, control in pairs(coveredControls) do
        control:SetHidden(isMenuClosed)
    end

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
    secondDropDownMenu:SetHidden(not isMenuClosed)

    for key, control in pairs(coveredControls) do
        control:SetHidden(isMenuClosed)
    end

    GrindTimerSettingsWindowCloseButton:SetHidden(isMenuClosed)
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

    for key, control in pairs(coveredControls) do
        control:SetHidden(false)
    end

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

function GrindTimer.AbbreviateNumbersCheckBoxChecked(checkBox)
    local abbreviateNumbers = GrindTimer.AccountSavedVariables.AbbreviateNumbers

    if abbreviateNumbers then
        checkBox:SetState(BSTATE_NORMAL)
        GrindTimer.AccountSavedVariables.AbbreviateNumbers = false
    else
        checkBox:SetState(BSTATE_PRESSED)
        GrindTimer.AccountSavedVariables.AbbreviateNumbers = true
    end

    GrindTimer.SetFontUpdateFlag()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.AbbreviateTimeCheckBoxChecked(checkBox)
    local abbreviateTime = GrindTimer.AccountSavedVariables.AbbreviateTime

    if abbreviateTime then
        checkBox:SetState(BSTATE_NORMAL)
        GrindTimer.AccountSavedVariables.AbbreviateTime = false
    else
        checkBox:SetState(BSTATE_PRESSED)
        GrindTimer.AccountSavedVariables.AbbreviateTime = true
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

function GrindTimer.FontSizeTextSubmitted(textBox, minValue, maxValue)
    local currentNumber = tonumber(textBox:GetText())

    if not currentNumber or currentNumber < minValue then
        currentNumber = minValue
        textBox:SetText(minValue)
    elseif currentNumber > maxValue then
        currentNumber = maxValue
        textBox:SetText(maxValue)
    end

    GrindTimer.AccountSavedVariables.FontSize = currentNumber

    GrindTimer.SetFontUpdateFlag()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.AddUIControlsToTable(control)
    table.insert(coveredControls, control)
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

    for key, control in pairs(coveredControls) do
        control:SetHidden(false)
    end

    GrindTimerSettingsWindow:SetHidden(true)
    windowHidden = true
end
