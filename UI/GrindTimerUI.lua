local extendedControls = {} -- UI controls affected by extending or retracting the window.
local controlsExtended = false
local labelsInitialized = false
local extendAnimationTimeline

local function InitializeAnimations()
    extendAnimationTimeline = ANIMATION_MANAGER:CreateTimeline()
    extendAnimationTimeline:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG)
    extendAnimation = extendAnimationTimeline:InsertAnimation(ANIMATION_SIZE, GrindTimerWindow)

    local width = GrindTimerWindow:GetWidth()
    local startHeight = GrindTimerWindow:GetHeight()
    extendAnimation:SetStartAndEndHeight(startHeight, 175)
    extendAnimation:SetStartAndEndWidth(width, width)
    extendAnimation:SetDuration(500)
    extendAnimation:SetEasingFunction(ZO_EaseInOutQuartic)

    for key, control in pairs(extendedControls) do
        local fadeAnimation = extendAnimationTimeline:InsertAnimation(ANIMATION_ALPHA, control)
        fadeAnimation:SetAlphaValues(0,1)
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

            if dolmensNeeded == 0 then
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

local function UpdateUIOpacity()
    local opacity = GrindTimer.AccountSavedVariables.Opacity
    GrindTimerWindow:SetAlpha(opacity)
    GrindTimerWindowSettingsButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowResetButtonBackdrop:SetAlpha(opacity)
    GrindTimerWindowLevelEntryBoxBackdrop:SetAlpha(opacity)
end

local function UpdateLabels()
    GrindTimerWindowLevelTypeLabel:SetHidden(not controlsExtended or (mode == "Next" and true or false))
    GrindTimerWindowSecondOptionLabel:SetHidden(not GrindTimer.AccountSavedVariables.SecondLabelEnabled)

    local firstLabelString, secondLabelString = unpack(GetLabelStrings())
    GrindTimerWindowFirstOptionLabel:SetText(firstLabelString)
    GrindTimerWindowSecondOptionLabel:SetText(secondLabelString)
end

local function UpdateButtons()
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

            if GrindTimer.SavedVariables.IsPlayerChampion then
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_DISABLED)
                GrindTimerWindowNormalTypeButton:SetHidden(true)
            else
                GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)
                GrindTimerWindowNormalTypeButton:SetHidden(false)
            end
        end
    end
end

local function UpdateLevelEntryBox()
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

local function InitializeUIControls()
    for key, control in pairs(extendedControls) do
        control:SetHidden(true)
    end
    GrindTimerWindow:SetDimensions(345, 70)

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

function GrindTimer.AddToExtendedControlsArray(control)
    table.insert(extendedControls, control)
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
    UpdateLabels()
    UpdateButtons()
    UpdateLevelEntryBox()
    UpdateUIOpacity()
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
        extendAnimationTimeline:PlayBackward()
    else
        extendAnimationTimeline:PlayForward()
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
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
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
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.TargetModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)

    GrindTimer.SavedVariables.Mode = "Target"
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimerWindowLevelEntryBox:SetText(targetLevel)
    GrindTimer.SavedVariables.TargetLevelType = GrindTimer.SavedVariables.IsPlayerChampion and "Champion" or "Normal"
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.NormalTypeButtonClicked(button)
    if GrindTimer.SavedVariables.IsPlayerChampion then
        return
    end
    
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
    GrindTimer.SettingsWindowToggled()
end
