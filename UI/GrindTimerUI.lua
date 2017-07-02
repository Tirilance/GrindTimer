local extendedControls = {} -- Controls affected by using the extender button to show or hide more UI options
local optionsExtended = false

function GrindTimer.InitializeUI()
    GrindTimerWindow:ClearAnchors()
    GrindTimerWindow:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, GrindTimer.AccountSavedVariables.OffsetX, GrindTimer.AccountSavedVariables.OffsetY)

    local grindTimerFragment = ZO_HUDFadeSceneFragment:New(GrindTimerWindow, 0, 0)
    SCENE_MANAGER:GetScene("hud"):AddFragment(grindTimerFragment)
    SCENE_MANAGER:GetScene("hudui"):AddFragment(grindTimerFragment)

    local mode = GrindTimer.SavedVariables.Mode
    local locked = GrindTimer.AccountSavedVariables.Locked
    local lockedState = locked and BSTATE_PRESSED or BSTATE_NORMAL

    GrindTimerWindow:SetMovable(not locked)
    GrindTimerWindowLockButton:SetState(lockedState)
    GrindTimer.UpdateUIOpacity()
    GrindTimer.UpdateLabels()
    GrindTimer.InitializeSettingsMenu()
end

function GrindTimer.AddToExtendedControlsArray(control)
    table.insert(extendedControls, control)
end

function GrindTimer.OnWindowShown()
    local opacity = GrindTimer.AccountSavedVariables.Opacity
    GrindTimerWindow:SetAlpha(opacity)
    GrindTimerWindowSettingsButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowResetButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowLevelEntryBoxBackdrop:SetAlpha(opacity)
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

function GrindTimer.UpdateButtons()
    local mode = GrindTimer.SavedVariables.Mode
    local targetType = GrindTimer.SavedVariables.TargetLevelType

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

        if targetType == "Normal" then
            GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowNormalTypeButton:SetHidden(false)
            GrindTimerWindowChampionTypeButton:SetState(BSTATE_DISABLED)
            GrindTimerWindowChampionTypeButton:SetHidden(true)

        elseif targetType == "Champion" then
            GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)
            GrindTimerWindowNormalTypeButton:SetHidden(true)
            GrindTimerWindowChampionTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowChampionTypeButton:SetHidden(false)
        end
    end
end

function GrindTimer.UpdateLevelEntryBox()
    local mode = GrindTimer.SavedVariables.Mode

    if mode == "Next" then
        GrindTimerWindowLevelEntryBox:SetHidden(true)
        GrindTimerWindowLevelEntryLabel:SetHidden(true)
    elseif mode == "Target" then
        GrindTimerWindowLevelEntryBox:SetHidden(false)
        GrindTimerWindowLevelEntryLabel:SetHidden(false)
        GrindTimerWindowLevelEntryBox:SetText(GrindTimer.SavedVariables.TargetLevel)
    end
end

function GrindTimer.ToggleDisplay()
    GrindTimerWindow:SetHidden(not GrindTimerWindow:IsHidden())
end

-- Hides or shows the options normally hidden by the collapsed extender button.
function GrindTimer.OptionExtenderButtonClicked(button)
    if optionsExtended then
        for key, control in pairs(extendedControls) do
            control:SetHidden(true)
        end

        GrindTimerWindow:SetDimensions(345, 70)
        button:SetState(BSTATE_NORMAL)
        optionsExtended = false
    else
        for key, control in pairs(extendedControls) do
            control:SetHidden(false)
        end

        GrindTimerWindow:SetDimensions(345, 175)
        button:SetState(BSTATE_PRESSED)
        optionsExtended = true

        GrindTimer.UpdateLabels()
        GrindTimer.UpdateButtons()
        GrindTimer.UpdateLevelEntryBox()
    end
end

function GrindTimer.SaveWindowPosition(window)
    GrindTimer.AccountSavedVariables.OffsetX = window:GetLeft()
    GrindTimer.AccountSavedVariables.OffsetY = window:GetTop()
end

function GrindTimer.UpdateLabels()
    local hours = GrindTimer.SavedVariables.TargetHours
    local minutes = GrindTimer.SavedVariables.TargetMinutes
    local playerExpNeeded = GrindTimer.SavedVariables.TargetExpRemaining
    local targetLevel = GrindTimer.SavedVariables.TargetLevel
    local firstLabel = GrindTimer.AccountSavedVariables.FirstLabelType
    local secondLabel = GrindTimer.AccountSavedVariables.SecondLabelType
    local recentKills = GrindTimer.SavedVariables.RecentKills
    local killsNeeded = GrindTimer.SavedVariables.KillsNeeded
    local averageExpPerHour = GrindTimer.SavedVariables.AverageExpPerHour
    local levelsPerHour = GrindTimer.SavedVariables.LevelsPerHour

    local firstLabelString = ""
    local secondLabelString = ""

    local mode = GrindTimer.SavedVariables.Mode
    local nextLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    if not optionsExtended or mode == "Next" then
        GrindTimerWindowLevelTypeLabel:SetHidden(true)
    else
        GrindTimerWindowLevelTypeLabel:SetHidden(false)
    end

    -- Mode dependant strings.
    if mode == "Next" then

        if firstLabel == 1 then
            firstLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, nextLevel)
        elseif firstLabel == 2 then
            firstLabelString = string.format("%s Experience needed until level %s", playerExpNeeded, nextLevel)
        elseif firstLabel == 3 then
            firstLabelString = string.format("%s Kills needed until level %s", killsNeeded, nextLevel)
        end

        if secondLabel == 1 then
            secondLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, nextLevel)
        elseif secondLabel == 2 then
            secondLabelString = string.format("%s Experience needed until level %s", playerExpNeeded, nextLevel)
        elseif secondLabel == 3 then
            secondLabelString = string.format("%s Kills needed until level %s", killsNeeded, nextLevel)
        end

    elseif mode == "Target" then
        if firstLabel == 1 then
            firstLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, targetLevel)
        elseif firstLabel == 2 then
            firstLabelString = string.format("%s Experience needed until level %s", playerExpNeeded, targetLevel)
        elseif firstLabel == 3 then
            firstLabelString = string.format("%s Kills needed until level %s", killsNeeded, targetLevel)
        end

        if secondLabel == 1 then
            secondLabelString = string.format("%s Hours %s Minutes until level %s", hours, minutes, targetLevel)
        elseif secondLabel == 2 then
            secondLabelString = string.format("%s Experience needed until level %s", playerExpNeeded, targetLevel)
        elseif secondLabel == 3 then
            secondLabelString = string.format("%s Kills needed until level %s", killsNeeded, targetLevel)
        end
    end

    -- Mode independent strings.
    if firstLabel == 4 then
        firstLabelString = string.format("%s Experience gained per hour", averageExpPerHour)
    elseif firstLabel == 5 then
        firstLabelString = string.format("%s Levels gained per hour", levelsPerHour)
    elseif firstLabel == 6 then
        firstLabelString = string.format("%s Kills in last 10 minutes", recentKills)
    end

    if secondLabel == 4 then
        secondLabelString = string.format("%s Experience gained per hour", averageExpPerHour)
    elseif secondLabel == 5 then
        secondLabelString = string.format("%s Levels gained per hour", levelsPerHour)
    elseif secondLabel == 6 then
        secondLabelString = string.format("%s Kills in last 10 minutes", recentKills)
    end

    GrindTimerWindowFirstOptionLabel:SetText(firstLabelString)
    GrindTimerWindowSecondOptionLabel:SetText(secondLabelString)
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

    local targetType = GrindTimer.SavedVariables.TargetLevelType
    if targetType == "Normal" and currentNumber > 50 then
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
            GrindTimer.UpdateNewTargetLevel(GetUnitLevel("player")+1)

        -- Player is champion and target level is not.
        --[[elseif isChamp and targetLevelType == "Normal" and isChamp then
            GrindTimer.UpdateNewTargetLevel(GetPlayerChampionPointsEarned()+1)]]

        -- If target champion level is lower than current champion level.
        elseif targetLevelType == "Champion" and currentNumber <= GetPlayerChampionPointsEarned() then            
            GrindTimer.UpdateNewTargetLevel(GetPlayerChampionPointsEarned()+1)
        else
            GrindTimer.UpdateNewTargetLevel(currentText)
        end

        textBox:SetText(GrindTimer.SavedVariables.TargetLevel)
        GrindTimer.UpdateLabels()
    else
        -- If text is somehow invalid after LevelEntryTextChanged checks or just empty, reset target level and set it again.
        local newTarget = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
        textBox:SetText(newTarget)

        GrindTimer.SavedVariables.TargetLevel = newTarget
        GrindTimer.UpdateLabels()
    end
end

function GrindTimer.UpdateNewTargetLevel(targetLevel)
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType
    local isChamp = IsUnitChampion("player")
    local mode = isChamp and 3 or 1
    --[[
    local mode = 0    
    if isChamp then
        mode = 3
    else
        mode = (targetLevelType == "Normal") and 1 or 2
    end
    ]]
    local playerExpNeeded = GrindTimer.GetTargetLevelEXP(GetUnitLevel("player"), targetLevel, mode, GetPlayerChampionPointsEarned())
    local expGainPerMinute = GrindTimer.GetExpGainPerMinute()
    local hours, minutes = GrindTimer.GetLevelTimeRemaining(expGainPerMinute, playerExpNeeded)
    local averageExpPerKill, recentKills = GrindTimer.GetAverageExpPerKill()
    local killsNeeded = math.ceil(playerExpNeeded / averageExpPerKill)
    local levelsPerHour = GrindTimer.GetLevelsPerHour()
    local expGainPerHour = 0

    -- Check for INF / IND
    hours = (hours == math.huge or hours == -math.huge) and 0 or hours
    minutes = (minutes ~= minutes or minutes == math.huge or minutes == -math.huge) and 0 or minutes
    averageExpPerKill = (averageExpPerKill ~= averageExpPerKill) and 0 or averageExpPerKill
    killsNeeded = (killsNeeded ~= killsNeeded) and 0 or killsNeeded
    expGainPerHour = (expGainPerMinute ~= 0) and math.floor(expGainPerMinute*60) or 0

    GrindTimer.SavedVariables.TargetLevel = targetLevel
    GrindTimer.SaveVars(hours, minutes, playerExpNeeded, recentKills, killsNeeded, expGainPerHour, levelsPerHour)
end

function GrindTimer.NextModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)    
    GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)

    GrindTimer.SavedVariables.Mode = "Next"
    local isChamp = IsUnitChampion("player")
    local targetLevel = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimer.SavedVariables.TargetLevelType = isChamp and "Champion" or "Normal"
    GrindTimer.SavedVariables.TargetLevel = targetLevel

    GrindTimer.UpdateNewTargetLevel(targetLevel)
    GrindTimer.UpdateButtons()
    GrindTimer.UpdateLabels()
    GrindTimer.UpdateLevelEntryBox()
end

function GrindTimer.TargetModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)

    GrindTimer.SavedVariables.Mode = "Target"
    local isChamp = IsUnitChampion("player")
    local targetLevel = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
    local targetType = isChamp and "Champion" or "Normal"

    GrindTimer.SavedVariables.TargetLevelType = targetType
    GrindTimerWindowLevelEntryBox:SetText(targetLevel)

    if isChamp then
        GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)
        GrindTimerWindowChampionTypeButton:SetState(BSTATE_PRESSED)
    else
        GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowChampionTypeButton:SetState(BSTATE_DISABLED)
    end

    GrindTimer.UpdateButtons()
    GrindTimer.UpdateLabels()
    GrindTimer.UpdateLevelEntryBox()
end

function GrindTimer.NormalTypeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowChampionTypeButton:SetState(IsUnitChampion("player") and BSTATE_NORMAL or BSTATE_DISABLED)  

    GrindTimer.SavedVariables.TargetLevelType = "Normal"
    local currentText = GrindTimerWindowLevelEntryBox:GetText()
    local currentNumber = tonumber(currentText)

    if currentNumber ~= nil and currentNumber > 50 then
        GrindTimerWindowLevelEntryBox:SetText("50")
    elseif currentText == "" then
        local newTargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
        GrindTimerWindowLevelEntryBox:SetText(newTargetLevel)
    end

    GrindTimer.SavedVariables.TargetLevel = GrindTimerWindowLevelEntryBox:GetText()
end

function GrindTimer.ChampionTypeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)

    if IsUnitChampion("player") then
        GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)        
    else
        GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)
    end

    GrindTimer.SavedVariables.TargetLevelType = "Champion"

    local currentText = GrindTimerWindowLevelEntryBox:GetText()
    local currentNumber = tonumber(currentText)
    local nextLevel = GetPlayerChampionPointsEarned()+1

    if currentNumber ~= nil and currentNumber < nextLevel then
        GrindTimerWindowLevelEntryBox:SetText(nextLevel)
    end
end

function GrindTimer.ResetButtonClicked()
    GrindTimer.Reset()
    GrindTimer.UpdateNewTargetLevel(IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1)
    GrindTimer.UpdateLabels()
    GrindTimer.UpdateButtons()
    GrindTimer.UpdateLevelEntryBox()
end

function GrindTimer.SettingsButtonClicked()
    GrindTimerSettingsWindow:SetHidden(not GrindTimerSettingsWindow:IsHidden())
end
