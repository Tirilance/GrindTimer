local extendedControls = {} -- Controls affected by using the extender button to show or hide more UI options
local controlsExtended = false
local labelsInitialized = false
local timeline
local GrindTimerMaxHeight = 175

function GrindTimer.InitializeUI()
    GrindTimerWindow:ClearAnchors()
    GrindTimerWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, GrindTimer.AccountSavedVariables.OffsetX, GrindTimer.AccountSavedVariables.OffsetY)

    local grindTimerFragment = ZO_HUDFadeSceneFragment:New(GrindTimerWindow, 0, 0)
    SCENE_MANAGER:GetScene("hud"):AddFragment(grindTimerFragment)
    SCENE_MANAGER:GetScene("hudui"):AddFragment(grindTimerFragment)
    
    GrindTimer.InitializeAnimations()
    GrindTimer.InitializeUIControls()
    GrindTimer.SettingsInitialized = true
end

function GrindTimer.AddToExtendedControlsArray(control)
    table.insert(extendedControls, control)
end

function GrindTimer.OnWindowShown()
    GrindTimer.UpdateUIOpacity()
end

function GrindTimer.SaveWindowPosition(window)
    GrindTimer.AccountSavedVariables.OffsetX = window:GetLeft()
    GrindTimer.AccountSavedVariables.OffsetY = window:GetTop()
end

function GrindTimer.UpdateUIOpacity()
    local opacity = GrindTimer.AccountSavedVariables.Opacity
    GrindTimerWindow:SetAlpha(opacity)
    GrindTimerWindowSettingsButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowResetButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowLevelEntryBoxBackdrop:SetAlpha(opacity)
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

function GrindTimer.InitializeAnimations()
    timeline = ANIMATION_MANAGER:CreateTimeline()
    timeline:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG)
    extendAnimation = timeline:InsertAnimation(ANIMATION_SIZE, GrindTimerWindow)

    local width = GrindTimerWindow:GetWidth()
    local startHeight = GrindTimerWindow:GetHeight()
    extendAnimation:SetStartAndEndHeight(startHeight, GrindTimerMaxHeight)
    extendAnimation:SetStartAndEndWidth(width, width)
    extendAnimation:SetDuration(500)
    extendAnimation:SetEasingFunction(ZO_EaseInOutQuartic)

    for key, control in pairs(extendedControls) do
        local fadeAnimation = timeline:InsertAnimation(ANIMATION_ALPHA, control)
        fadeAnimation:SetAlphaValues(0,1)
        fadeAnimation:SetDuration(500)
        fadeAnimation:SetEasingFunction(ZO_EaseInOutQuartic)
    end
end

function GrindTimer.InitializeUIControls()
    for key, control in pairs(extendedControls) do
        control:SetHidden(true)
    end
    GrindTimerWindow:SetDimensions(345, 70)

    local locked = GrindTimer.AccountSavedVariables.Locked
    local lockButtonState = locked and BSTATE_PRESSED or BSTATE_NORMAL
    GrindTimerWindow:SetMovable(not locked)
    GrindTimerWindowLockButton:SetState(lockButtonState)

    GrindTimer.UpdateUIControls()
    GrindTimer.UpdateUIOpacity()
    GrindTimer.InitializeSettingsMenu()
end

function GrindTimer.UpdateUIControls()
    GrindTimer.UpdateLabels()
    GrindTimer.UpdateButtons()
    GrindTimer.UpdateLevelEntryBox()
end

function GrindTimer.UpdateLabels()
    GrindTimerWindowLevelTypeLabel:SetHidden(not controlsExtended or mode == "Next" and true or false)

    local firstLabelString, secondLabelString = GrindTimer.GetLabelStrings()
    GrindTimerWindowFirstOptionLabel:SetText(firstLabelString)
    GrindTimerWindowSecondOptionLabel:SetText(secondLabelString)
end

function GrindTimer.GetLabelStrings()
    local hours = GrindTimer.SavedVariables.TargetHours
    local minutes = GrindTimer.SavedVariables.TargetMinutes
    local expNeeded = GrindTimer.SavedVariables.TargetExpRemaining
    local targetLevel = GrindTimer.SavedVariables.TargetLevel
    local firstLabelType = GrindTimer.AccountSavedVariables.FirstLabelType
    local secondLabelType = GrindTimer.AccountSavedVariables.SecondLabelType
    local recentKills = GrindTimer.SavedVariables.RecentKills
    local killsNeeded = GrindTimer.SavedVariables.KillsNeeded
    local averageExpPerHour = GrindTimer.SavedVariables.ExpPerHour
    local levelsPerHour = GrindTimer.SavedVariables.LevelsPerHour

    local firstLabelString = ""
    local secondLabelString = ""

    local mode = GrindTimer.SavedVariables.Mode

    -- Mode dependant strings.
    if mode == "Next" then
        local nextLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

        if firstLabelType == 1 then
            firstLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, nextLevel)
        elseif firstLabelType == 2 then
            firstLabelString = string.format("%s Experience needed until level %s", expNeeded, nextLevel)
        elseif firstLabelType == 3 then
            firstLabelString = string.format("%s Kills needed until level %s", killsNeeded, nextLevel)
        end

        if secondLabelType == 1 then
            secondLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, nextLevel)
        elseif secondLabelType == 2 then
            secondLabelString = string.format("%s Experience needed until level %s", expNeeded, nextLevel)
        elseif secondLabelType == 3 then
            secondLabelString = string.format("%s Kills needed until level %s", killsNeeded, nextLevel)
        end

    elseif mode == "Target" then
        if firstLabelType == 1 then
            firstLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, targetLevel)
        elseif firstLabelType == 2 then
            firstLabelString = string.format("%s Experience needed until level %s", expNeeded, targetLevel)
        elseif firstLabelType == 3 then
            firstLabelString = string.format("%s Kills needed until level %s", killsNeeded, targetLevel)
        end

        if secondLabelType == 1 then
            secondLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, targetLevel)
        elseif secondLabelType == 2 then
            secondLabelString = string.format("%s Experience needed until level %s", expNeeded, targetLevel)
        elseif secondLabelType == 3 then
            secondLabelString = string.format("%s Kills needed until level %s", killsNeeded, targetLevel)
        end
    end

    -- Mode independent strings.
    if firstLabelType == 4 then
        firstLabelString = string.format("%s Experience gained per hour", averageExpPerHour)
    elseif firstLabelType == 5 then
        firstLabelString = string.format("%s Levels gained per hour", levelsPerHour)
    elseif firstLabelType == 6 then
        firstLabelString = string.format("%s Kills in last 15 minutes", recentKills)
    end

    if secondLabelType == 4 then
        secondLabelString = string.format("%s Experience gained per hour", averageExpPerHour)
    elseif secondLabelType == 5 then
        secondLabelString = string.format("%s Levels gained per hour", levelsPerHour)
    elseif secondLabelType == 6 then
        secondLabelString = string.format("%s Kills in last 15 minutes", recentKills)
    end

    return firstLabelString, secondLabelString
end

function GrindTimer.UpdateButtons()
    local mode = GrindTimer.SavedVariables.Mode
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType

    GrindTimerWindowExtendButton:SetState(controlsExtended and BSTATE_PRESSED or BSTATE_NORMAL)

    if mode == "Next" then
        GrindTimerWindowNextModeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowNormalTypeButton:SetHidden(true)
        GrindTimerWindowChampionTypeButton:SetHidden(true)

    elseif mode == "Target" then
        GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowTargetModeButton:SetState(BSTATE_PRESSED)

        if targetLevelType == "Normal" and controlsExtended then
            GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowNormalTypeButton:SetHidden(false)
            GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
            GrindTimerWindowChampionTypeButton:SetHidden(false)

        elseif targetLevelType == "Champion" and controlsExtended then            
            GrindTimerWindowChampionTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowChampionTypeButton:SetHidden(false)

            if IsUnitChampion("player") then
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)
                GrindTimerWindowNormalTypeButton:SetHidden(true)
            else
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)
                GrindTimerWindowNormalTypeButton:SetHidden(false)
            end
        end
    end
end

function GrindTimer.UpdateLevelEntryBox()
    local mode = GrindTimer.SavedVariables.Mode

    if mode == "Next" then
        GrindTimerWindowLevelEntryBox:SetHidden(true)
        GrindTimerWindowLevelEntryLabel:SetHidden(true)
    elseif mode == "Target" and controlsExtended then
        GrindTimerWindowLevelEntryBox:SetHidden(false)
        GrindTimerWindowLevelEntryLabel:SetHidden(false)
        GrindTimerWindowLevelEntryBox:SetText(GrindTimer.SavedVariables.TargetLevel)
    end
end

function GrindTimer.ToggleDisplay()
    GrindTimerWindow:SetHidden(not GrindTimerWindow:IsHidden())
end

-- Hides or shows the options normally hidden by the collapsed extender button.
function GrindTimer.UpdateExtendedControls()
    for key, control in pairs(extendedControls) do
        control:SetHidden(controlsExtended)
    end
    controlsExtended = not controlsExtended
    GrindTimer.UpdateUIControls()
end

function GrindTimer.ExtendButtonClicked()
    if (controlsExtended) then
        timeline:PlayBackward()
    else
        timeline:PlayForward()
    end
    GrindTimer.UpdateExtendedControls()
end

function GrindTimer.LevelEntryTextChanged(textBox)
    local currentText = textBox:GetText()
    local currentNumber = tonumber(currentText)
    if currentText == "" then return end

    -- If character entered is not a number, remove that character from the edit box.
    if currentNumber == nil then
        textBox:SetText(currentText:sub(1, -2))
        return
    end

    if GrindTimer.SavedVariables.TargetLevelType == "Normal" and currentNumber > 50 then
        textBox:SetText("50")
    end
end

function GrindTimer.LevelEntryTextSubmitted(textBox)
    local currentText = textBox:GetText()
    local currentNumber = tonumber(currentText)
    local isChamp = IsUnitChampion("player")
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType

    if currentText ~= nil and currentText ~= "" then
        -- Player level is lower than target normal level.
        if targetLevelType == "Normal" and not isChamp and currentNumber <= GetUnitLevel("player") then
            GrindTimer.SetNewTargetLevel(GetUnitLevel("player")+1)

        -- Target champion level is lower than current champion level.
        elseif targetLevelType == "Champion" and currentNumber <= GetPlayerChampionPointsEarned() then
            GrindTimer.SetNewTargetLevel(GetPlayerChampionPointsEarned()+1)
        else
            GrindTimer.SetNewTargetLevel(currentText)
        end

        textBox:SetText(GrindTimer.SavedVariables.TargetLevel)
    else
        -- If text is somehow invalid after LevelEntryTextChanged checks or just empty, reset target level and set it again.
        local newTarget = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
        GrindTimer.SetNewTargetLevel(newTarget)
        textBox:SetText(newTarget)
    end

    GrindTimer.UpdateUIControls()
end

function GrindTimer.NextModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)

    GrindTimer.SavedVariables.Mode = "Next"
    local targetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.TargetModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)

    GrindTimer.SavedVariables.Mode = "Target"
    local targetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimerWindowLevelEntryBox:SetText(targetLevel)
    GrindTimer.SavedVariables.TargetLevelType = IsUnitChampion("player") and "Champion" or "Normal"
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.NormalTypeButtonClicked(button)
    if IsUnitChampion("player") then return end
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)

    local currentText = GrindTimerWindowLevelEntryBox:GetText()
    local currentNumber = tonumber(currentText)

    if currentNumber ~= nil and currentNumber > 50 then
        GrindTimerWindowLevelEntryBox:SetText("50")
    elseif currentText == "" or currentNumber < GetUnitLevel("player") then
        local newTargetLevel = GetUnitLevel("player")+1
        GrindTimerWindowLevelEntryBox:SetText(newTargetLevel)
    end

    local targetLevel = GrindTimerWindowLevelEntryBox:GetText()

    GrindTimer.SavedVariables.TargetLevelType = "Normal"
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.ChampionTypeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)
    
    local currentText = GrindTimerWindowLevelEntryBox:GetText()
    local currentNumber = tonumber(currentText)

    GrindTimer.SavedVariables.TargetLevelType = "Champion"

    if currentNumber ~= nil and currentNumber <= GetPlayerChampionPointsEarned() then
        GrindTimerWindowLevelEntryBox:SetText(GetPlayerChampionPointsEarned()+1)
        GrindTimer.SetNewTargetLevel(GetPlayerChampionPointsEarned()+1)
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
    GrindTimerSettingsWindow:SetHidden(not GrindTimerSettingsWindow:IsHidden())
end
