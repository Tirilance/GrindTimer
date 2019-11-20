local extendedControls = {} -- UI controls modified by extending or retracting the window.
local contextControls = {} -- Right click context menu buttons for selecting metrics.
local fontControls = {} -- UI controls modified when changing font size.

local windowExtended = false
local fontUpdateFlag = true

local extendAnimationTimeline
local lastClickedLabel

local function UpdateExtendAnimationDimensions(width, height)
    extendAnimation:SetStartAndEndHeight(height, height * 2.5)
    extendAnimation:SetStartAndEndWidth(width, width)
end

local function InitializeAnimations()
    extendAnimationTimeline = ANIMATION_MANAGER:CreateTimeline()
    extendAnimationTimeline:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG)
    extendAnimation = extendAnimationTimeline:InsertAnimation(ANIMATION_SIZE, GrindTimerWindow)

    UpdateExtendAnimationDimensions(GrindTimerWindow:GetWidth(), GrindTimerWindow:GetHeight())

    extendAnimation:SetDuration(500)
    extendAnimation:SetEasingFunction(ZO_EaseInOutQuartic)

    for key, control in pairs(extendedControls) do
        local fadeAnimation = extendAnimationTimeline:InsertAnimation(ANIMATION_ALPHA, control)
        fadeAnimation:SetAlphaValues(0, 1)
        fadeAnimation:SetDuration(500)
        fadeAnimation:SetEasingFunction(ZO_EaseInOutQuartic)
    end
end

local function GetLabelStrings()
    local labelStrings = { "", "" }
    local labelValues = { GrindTimer.AccountSavedVariables.FirstLabelType,
                          GrindTimer.AccountSavedVariables.SecondLabelType }

    for i in ipairs(labelStrings) do
        if labelValues[i] == 1 then
            local dolmensNeeded = GrindTimer.SavedVariables.DolmensNeeded
            local targetLevel = GrindTimer.SavedVariables.TargetLevel

            if dolmensNeeded == "0" then
                labelStrings[i] = "Label updates upon closing a dolmen."
            else
                labelStrings[i] = string.format("%s Dolmens until level %s", dolmensNeeded, targetLevel)
            end

        elseif labelValues[i] == 2 then
            local dungeonRunsNeeded = GrindTimer.SavedVariables.DungeonRunsNeeded
            local lastDungeonName = GrindTimer.SavedVariables.LastDungeonName
            local targetLevel = GrindTimer.SavedVariables.TargetLevel

            if lastDungeonName ~= nil and GrindTimer.HasGainedExpFromDungeon(lastDungeonName) then
                labelStrings[i] = string.format("%s %s Runs until level %s", dungeonRunsNeeded, lastDungeonName, targetLevel)
            else
                labelStrings[i] = "Label updates upon exiting a dungeon."
            end

        elseif labelValues[i] == 3 then
            local averageExpPerHour = GrindTimer.SavedVariables.ExpPerHour
            labelStrings[i] = string.format("%s Experience gained per hour", averageExpPerHour)

        elseif labelValues[i] == 4 then
            local expNeeded = GrindTimer.SavedVariables.TargetExpRemaining
            local targetLevel = GrindTimer.SavedVariables.TargetLevel
            labelStrings[i] = string.format("%s Experience needed until level %s", expNeeded, targetLevel)

        elseif labelValues[i] == 5 then
            local sessionKills = GrindTimer.SavedVariables.SessionKills
            labelStrings[i] = string.format("%s Enemies killed in the current session", sessionKills)

        elseif labelValues[i] == 6 then
            local recentKills = GrindTimer.SavedVariables.RecentKills
            labelStrings[i] = string.format("%s Kills in last 15 minutes", recentKills)

        elseif labelValues[i] == 7 then
            local killsNeeded = GrindTimer.SavedVariables.KillsNeeded
            local targetLevel = GrindTimer.SavedVariables.TargetLevel
            labelStrings[i] = string.format("%s Kills needed until level %s", killsNeeded, targetLevel)

        elseif labelValues[i] == 8 then
            local sessionLevels = GrindTimer.SavedVariables.SessionLevels
            labelStrings[i] = string.format("%s Levels gained in the current session", sessionLevels)

        elseif labelValues[i] == 9 then
            local levelsPerHour = GrindTimer.SavedVariables.LevelsPerHour
            labelStrings[i] = string.format("%s Levels gained per hour", levelsPerHour)

        elseif labelValues[i] == 10 then
            local hours = GrindTimer.SavedVariables.TargetHours
            local minutes = GrindTimer.SavedVariables.TargetMinutes
            local targetLevel = GrindTimer.SavedVariables.TargetLevel
            labelStrings[i] = string.format("%s Hours %s Minutes until level %s", hours, minutes, targetLevel)
        end
    end

    return labelStrings
end

local function RescaleUI()
    local firstLabelWidth = GrindTimerWindowFirstMetricLabel:GetWidth()
    local secondLabelWidth = GrindTimerWindowSecondMetricLabel:GetWidth()
    local labelHeight = GrindTimerWindowFirstMetricLabel:GetHeight()

    local contextMenuWidth = GrindTimerWindowMetricContextMenuScalingLabel:GetWidth() + 10

    local biggestLabelWidth = (firstLabelWidth > secondLabelWidth) and firstLabelWidth or secondLabelWidth

    local windowWidth = (biggestLabelWidth + 50)
    local windowHeight = labelHeight * 2 + 30
    local windowHeightExtended = windowHeight * 2.5

    if windowExtended then
        GrindTimer.ExtendButtonClicked()
    end

    GrindTimerWindow:SetDimensions(windowWidth, windowHeight)
    GrindTimerWindowBackdrop:SetDimensions(windowWidth, windowHeight)
    UpdateExtendAnimationDimensions(windowWidth, windowHeight)

    GrindTimerWindowLockButton:ClearAnchors()
    GrindTimerWindowLockButton:SetAnchor(TOPRIGHT, GrindTimerWindow, TOPRIGHT, -15, windowHeight * 0.80)

    GrindTimerWindowSecondMetricLabel:ClearAnchors()
    GrindTimerWindowSecondMetricLabel:SetAnchor(TOP, GrindTimerWindow, TOP, 0, labelHeight)

    GrindTimerWindowTopDivider:SetWidth(windowWidth * 1.45)
    GrindTimerWindowTopDivider:ClearAnchors()
    GrindTimerWindowTopDivider:SetAnchor(TOP, GrindTimerWindow, TOP, 0, windowHeight * 0.75)

    GrindTimerWindowModeLabel:SetWidth(windowWidth * 0.15)
    GrindTimerWindowModeLabel:ClearAnchors()
    GrindTimerWindowModeLabel:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, 10, windowHeightExtended * 0.29)

    GrindTimerWindowNextModeButton:SetWidth(windowWidth * 0.29)
    GrindTimerWindowNextModeButton:SetHeight(labelHeight)
    GrindTimerWindowNextModeButton:ClearAnchors()
    GrindTimerWindowNextModeButton:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, 10, windowHeightExtended * 0.43)

    GrindTimerWindowTargetModeButton:SetWidth(windowWidth * 0.30)
    GrindTimerWindowTargetModeButton:SetHeight(labelHeight)
    GrindTimerWindowTargetModeButton:ClearAnchors()
    GrindTimerWindowTargetModeButton:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, 10, windowHeightExtended * 0.57)

    GrindTimerWindowLevelTypeLabel:SetWidth(windowWidth * 0.26)
    GrindTimerWindowLevelTypeLabel:SetHeight(labelHeight)
    GrindTimerWindowLevelTypeLabel:ClearAnchors()
    GrindTimerWindowLevelTypeLabel:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, windowWidth * 0.35, windowHeightExtended * 0.29)

    GrindTimerWindowNormalTypeButton:SetWidth(windowWidth * 0.29)
    GrindTimerWindowNormalTypeButton:SetHeight(labelHeight)
    GrindTimerWindowNormalTypeButton:ClearAnchors()
    GrindTimerWindowNormalTypeButton:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, windowWidth * 0.35, windowHeightExtended * 0.43)

    GrindTimerWindowChampionTypeButton:SetWidth(windowWidth * 0.29)
    GrindTimerWindowChampionTypeButton:SetHeight(labelHeight)
    GrindTimerWindowChampionTypeButton:ClearAnchors()
    GrindTimerWindowChampionTypeButton:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, windowWidth * 0.35, windowHeightExtended * 0.57)

    GrindTimerWindowLevelTextBoxLabel:SetWidth(windowWidth * 0.14)
    GrindTimerWindowLevelTextBoxLabel:SetHeight(labelHeight)
    GrindTimerWindowLevelTextBoxLabel:ClearAnchors()
    GrindTimerWindowLevelTextBoxLabel:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, windowWidth * 0.68, windowHeightExtended * 0.46)

    GrindTimerWindowLevelTextBox:SetWidth(windowWidth * 0.14)
    GrindTimerWindowLevelTextBox:ClearAnchors()
    GrindTimerWindowLevelTextBox:SetAnchor(TOPLEFT, GrindTimerWindow, TOPLEFT, windowWidth * 0.83, windowHeightExtended * 0.46)

    GrindTimerWindowLevelTextBoxBackdrop:SetWidth(windowWidth * 0.14)
    GrindTimerWindowLevelTextBoxBackdrop:ClearAnchors()
    GrindTimerWindowLevelTextBoxBackdrop:SetAnchor(TOPLEFT, GrindTimerWindowLevelTextBox, TOPLEFT, -5, -2)

    GrindTimerWindowBottomDivider:SetWidth(windowWidth * 1.45)
    GrindTimerWindowBottomDivider:ClearAnchors()
    GrindTimerWindowBottomDivider:SetAnchor(TOP, GrindTimerWindow, TOP, 0, windowHeightExtended * 0.71)

    GrindTimerWindowSettingsButton:SetWidth(windowWidth * 0.19)
    GrindTimerWindowSettingsButton:SetHeight(labelHeight)
    GrindTimerWindowSettingsButton:ClearAnchors()
    GrindTimerWindowSettingsButton:SetAnchor(BOTTOMLEFT, GrindTimerWindow, BOTTOMLEFT, 10, -10)

    GrindTimerWindowSettingsButtonBackdrop:SetWidth(windowWidth * 0.19)
    GrindTimerWindowSettingsButtonBackdrop:SetHeight(labelHeight)

    GrindTimerWindowResetButton:SetWidth(windowWidth * 0.19)
    GrindTimerWindowResetButton:SetHeight(labelHeight)
    GrindTimerWindowResetButton:ClearAnchors()
    GrindTimerWindowResetButton:SetAnchor(BOTTOMRIGHT, GrindTimerWindow, BOTTOMRIGHT, -10, -10)

    GrindTimerWindowResetButtonBackdrop:SetWidth(windowWidth * 0.19)
    GrindTimerWindowResetButtonBackdrop:SetHeight(labelHeight)

    GrindTimerWindowMetricContextMenu:SetWidth(contextMenuWidth)
    GrindTimerWindowMetricContextMenu:ClearAnchors()
    GrindTimerWindowMetricContextMenu:SetAnchor(TOPRIGHT, GrindTimerWindow, TOPRIGHT, contextMenuWidth + 15, 0)

    for key, control in pairs(contextControls) do
        control:SetWidth(contextMenuWidth)
    end
end

local function UpdateUIOpacity()
    local opacity = GrindTimer.AccountSavedVariables.Opacity
    GrindTimerWindow:SetAlpha(opacity)
    GrindTimerWindowSettingsButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowResetButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowLevelTextBoxBackdrop:SetAlpha(opacity)
end

local function UpdateFonts()
    local r, g, b = unpack(GrindTimer.AccountSavedVariables.TextColor)

    for key, control in pairs(fontControls) do

        -- Apply color to controls with text
        if control:GetType() == CT_BUTTON then
            control:SetNormalFontColor(r, g, b, 1)
        else
            control:SetColor(r, g, b, 1)
        end

        -- Apply font to controls with text
        local fontSize = GrindTimer.AccountSavedVariables.FontSize

        if GrindTimer.AccountSavedVariables.OutlineText then
            local outlineFont = string.format("$(BOLD_FONT)|$(KB_%s)|outline", fontSize)
            control:SetFont(outlineFont)
        else
            local normalFont = string.format("$(BOLD_FONT)|$(KB_%s)|soft-shadow-thin", fontSize)
            control:SetFont(normalFont)
        end
    end

    fontUpdateFlag = false

    RescaleUI()
end

local function UpdateLabels()
    local isHidden = not windowExtended

    GrindTimerWindowModeLabel:SetHidden(isHidden)
    GrindTimerWindowLevelTextBoxLabel:SetHidden(isHidden)
    GrindTimerWindow:SetHidden()

    if GrindTimer.SavedVariables.Mode == GrindTimer.Mode.Next or isHidden then
        GrindTimerWindowLevelTypeLabel:SetHidden(true)
    else
        GrindTimerWindowLevelTypeLabel:SetHidden(false)
    end
end

local function UpdateButtons()
    local mode = GrindTimer.SavedVariables.Mode
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType
    local isHidden = not windowExtended

    GrindTimerWindowExtendButton:SetState(windowExtended and BSTATE_PRESSED or BSTATE_NORMAL)

    if mode == GrindTimer.Mode.Next then
        GrindTimerWindowNextModeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowNextModeButton:SetHidden(isHidden)

        GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowTargetModeButton:SetHidden(isHidden)

        GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowNormalTypeButton:SetHidden(true)

        GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowChampionTypeButton:SetHidden(true)

    elseif mode == GrindTimer.Mode.Target then
        GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowNextModeButton:SetHidden(isHidden)

        GrindTimerWindowTargetModeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowTargetModeButton:SetHidden(isHidden)

        if targetLevelType == GrindTimer.Target.Normal then
            GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowNormalTypeButton:SetHidden(isHidden)

            GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
            GrindTimerWindowChampionTypeButton:SetHidden(isHidden)

        elseif targetLevelType == GrindTimer.Target.Champion then
            GrindTimerWindowChampionTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowChampionTypeButton:SetHidden(isHidden)

            if GrindTimer.SavedVariables.IsPlayerChampion then
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)
                GrindTimerWindowNormalTypeButton:SetHidden(true)
            else
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)
                GrindTimerWindowNormalTypeButton:SetHidden(isHidden)
            end
        end
    end

    GrindTimerWindowSettingsButton:SetHidden(isHidden)
    GrindTimerWindowResetButton:SetHidden(isHidden)
end

local function UpdateLevelTextBox()
    local mode = GrindTimer.SavedVariables.Mode
    local isHidden = not windowExtended

    if mode == GrindTimer.Mode.Next then
        GrindTimerWindowLevelTextBox:SetHidden(true)
        GrindTimerWindowLevelTextBoxLabel:SetHidden(true)

    elseif mode == GrindTimer.Mode.Target then
        GrindTimerWindowLevelTextBox:SetHidden(isHidden)
        GrindTimerWindowLevelTextBoxLabel:SetHidden(isHidden)
        GrindTimerWindowLevelTextBox:SetText(GrindTimer.SavedVariables.TargetLevel)
    end
end

local function InitializeUIControls()
    local locked = GrindTimer.AccountSavedVariables.Locked
    local lockButtonState = locked and BSTATE_PRESSED or BSTATE_NORMAL
    GrindTimerWindow:SetMovable(not locked)
    GrindTimerWindowLockButton:SetState(lockButtonState)

    GrindTimer.UpdateUIControls()
end

function GrindTimer.InitializeUI()
    GrindTimerWindow:ClearAnchors()
    GrindTimerWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, GrindTimer.AccountSavedVariables.OffsetX, GrindTimer.AccountSavedVariables.OffsetY)

    local grindTimerFragment = ZO_HUDFadeSceneFragment:New(GrindTimerWindow, 0, 0)
    SCENE_MANAGER:GetScene("hud"):AddFragment(grindTimerFragment)
    SCENE_MANAGER:GetScene("hudui"):AddFragment(grindTimerFragment)

    InitializeAnimations()
    InitializeUIControls()
    GrindTimer.InitializeSettingsMenu()
    GrindTimer.UIInitialized = true
end

function GrindTimer.SetFontUpdateFlag()
    fontUpdateFlag = true
end

function GrindTimer.AddControlsToTable(control, destTable, updateFont)
    if destTable == 1 then
        table.insert(extendedControls, control)
    elseif destTable == 2 then
        table.insert(contextControls, control)
    end

    if updateFont then
        table.insert(fontControls, control)
    end
end

function GrindTimer.OnWindowShown()
    UpdateUIOpacity()
end

function GrindTimer.SaveWindowPosition(window)
    GrindTimer.AccountSavedVariables.OffsetX = window:GetLeft()
    GrindTimer.AccountSavedVariables.OffsetY = window:GetTop()
end

function GrindTimer.ToggleWindowLock(lockButton)
    local locked = GrindTimer.AccountSavedVariables.Locked

    if locked then
        GrindTimer.AccountSavedVariables.Locked = false
        lockButton:SetState(BSTATE_NORMAL)
    else
        GrindTimer.AccountSavedVariables.Locked = true
        lockButton:SetState(BSTATE_PRESSED)
    end

    GrindTimerWindow:SetMovable(not GrindTimer.AccountSavedVariables.Locked)
end

function GrindTimer.UpdateUIControls()
    GrindTimer.UpdateMetricLabels()
    UpdateLabels()
    UpdateButtons()
    UpdateLevelTextBox()
    UpdateUIOpacity()

    if fontUpdateFlag then
        UpdateFonts()
    end
end

function GrindTimer.UpdateMetricLabels()
    GrindTimerWindowSecondMetricLabel:SetHidden(not GrindTimer.AccountSavedVariables.SecondLabelEnabled)

    local firstLabelString, secondLabelString = unpack(GetLabelStrings())
    GrindTimerWindowFirstMetricLabel:SetText(firstLabelString)
    GrindTimerWindowSecondMetricLabel:SetText(secondLabelString)

    local firstLabelWidth = GrindTimerWindowFirstMetricLabel:GetWidth()
    local secondLabelWidth = GrindTimerWindowSecondMetricLabel:GetWidth()
    local windowWidth = GrindTimerWindow:GetWidth()

    if firstLabelWidth >= windowWidth or secondLabelWidth >= windowWidth then
        RescaleUI()
    end
end

function GrindTimer.ToggleDisplay()
    GrindTimerWindow:SetHidden(not GrindTimerWindow:IsHidden())
end

function GrindTimer.ExtendButtonClicked()
    if (windowExtended) then
        extendAnimationTimeline:PlayBackward()
    else
        extendAnimationTimeline:PlayForward()
    end

    windowExtended = not windowExtended
    GrindTimer.UpdateUIControls()
end

function GrindTimer.LevelTextBoxSubmitted(textBox, minValue, maxNormalValue, maxChampionValue)
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType

    local minNormalValue = GetUnitLevel("player") + 1
    local minChampionValue = GetPlayerChampionPointsEarned() + 1

    local currentNumber = tonumber(textBox:GetText())

    if targetLevelType == GrindTimer.Target.Normal then
        if not currentNumber or currentNumber < minNormalValue then
            currentNumber = minNormalValue
            textBox:SetText(minNormalValue)
        elseif currentNumber > maxNormalValue then
            currentNumber = maxNormalValue
            textBox:SetText(maxNormalValue)
        end
    elseif targetLevelType == GrindTimer.Target.Champion then
        if not currentNumber or currentNumber < minChampionValue then
            currentNumber = minChampionValue
            textBox:SetText(minChampionValue)
        elseif currentNumber > maxChampionValue then
            currentNumber = maxChampionValue
            textBox:SetText(maxChampionValue)
        end
    end

    GrindTimer.SetNewTargetLevel(currentNumber)
    GrindTimer.UpdateMetricLabels()
end

function GrindTimer.MetricLabelClicked(targetLabel, button, upInside)
    local contextMenu = GrindTimerWindowMetricContextMenu
    local isHidden = contextMenu:IsHidden()

    if button == 2 and upInside and isHidden then
        lastClickedLabel = targetLabel
        contextMenu:SetHidden(false)
    elseif not contextMenu:IsHidden() then
        contextMenu:SetHidden(true)
    end
end

function GrindTimer.MetricContextMenuButtonClicked(selectedMetric)
    GrindTimerWindowMetricContextMenu:SetHidden(true)

    if lastClickedLabel == 1 then
        GrindTimer.AccountSavedVariables.FirstLabelType = selectedMetric
    elseif lastClickedLabel == 2 then
        GrindTimer.AccountSavedVariables.SecondLabelType = selectedMetric
    end

    GrindTimer.UpdateMetricLabels()
    GrindTimer.UpdateSettingsWindowButtons()
end

function GrindTimer.NextModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)
    GrindTimerWindowLevelTypeLabel:SetHidden(true)

    GrindTimer.SavedVariables.Mode = GrindTimer.Mode.Next
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned() + 1 or GetUnitLevel("player") + 1

    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.TargetModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)
    GrindTimerWindowLevelTypeLabel:SetHidden(false)

    GrindTimer.SavedVariables.Mode = GrindTimer.Mode.Target
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned() + 1 or GetUnitLevel("player") + 1

    GrindTimerWindowLevelTextBox:SetText(targetLevel)
    GrindTimer.SavedVariables.TargetLevelType = GrindTimer.SavedVariables.IsPlayerChampion and GrindTimer.Target.Champion or GrindTimer.Target.Normal
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.NormalTypeButtonClicked(button)
    if GrindTimer.SavedVariables.IsPlayerChampion then
        return
    end

    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)

    local currentText = GrindTimerWindowLevelTextBox:GetText()
    local currentNumber = tonumber(currentText)

    if currentNumber ~= nil and currentNumber > 50 then
        GrindTimerWindowLevelTextBox:SetText("50")
    elseif currentText == "" or currentNumber < GetUnitLevel("player") then
        local newTargetLevel = GetUnitLevel("player") + 1
        GrindTimerWindowLevelTextBox:SetText(newTargetLevel)
    end

    local targetLevel = GrindTimerWindowLevelTextBox:GetText()

    GrindTimer.SavedVariables.TargetLevelType = GrindTimer.Target.Normal
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.ChampionTypeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)

    local currentText = GrindTimerWindowLevelTextBox:GetText()
    local currentNumber = tonumber(currentText)

    GrindTimer.SavedVariables.TargetLevelType = GrindTimer.Target.Champion

    if currentNumber ~= nil and currentNumber <= GetPlayerChampionPointsEarned() then
        GrindTimerWindowLevelTextBox:SetText(GetPlayerChampionPointsEarned() + 1)
        GrindTimer.SetNewTargetLevel(GetPlayerChampionPointsEarned() + 1)
    elseif currentNumber ~= nil then
        GrindTimer.SetNewTargetLevel(currentText)
    end

    GrindTimer.UpdateUIControls()
end

function GrindTimer.ResetButtonClicked()
    GrindTimer.Reset()
    GrindTimer.UpdateUIControls()
end

function GrindTimer.SettingsButtonClicked()
    GrindTimer.SettingsWindowToggled()
end
