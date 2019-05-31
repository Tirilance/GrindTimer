local extendedControls = {} -- UI controls modified by extending or retracting the window.
local contextControls = {} -- Right click context menu buttons for selecting metrics.
local fontControls = {} -- UI controls modified when changing font size.

local windowExtended = false
local extendAnimationTimeline

local normalFont = "$(BOLD_FONT)|$(KB_18)|soft-shadow-thin"
local outlineFont = "$(BOLD_FONT)|$(KB_18)|outline"
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

local function UpdateLabels()
    local isHidden = not windowExtended

    GrindTimerWindowModeLabel:SetHidden(isHidden)
    GrindTimerWindowLevelTextBoxLabel:SetHidden(isHidden)
    GrindTimerWindow:SetHidden()

    if GrindTimer.SavedVariables.Mode == 1 or isHidden then
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

    -- Next level mode
    if mode == 1 then
        GrindTimerWindowNextModeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowNextModeButton:SetHidden(isHidden)

        GrindTimerWindowTargetModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowTargetModeButton:SetHidden(isHidden)

        GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowNormalTypeButton:SetHidden(true)

        GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowChampionTypeButton:SetHidden(true)

    -- Target level mode
    elseif mode == 2 then
        GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)
        GrindTimerWindowNextModeButton:SetHidden(isHidden)

        GrindTimerWindowTargetModeButton:SetState(BSTATE_PRESSED)
        GrindTimerWindowTargetModeButton:SetHidden(isHidden)

        -- Normal target level
        if targetLevelType == 1 then
            GrindTimerWindowNormalTypeButton:SetState(BSTATE_PRESSED)
            GrindTimerWindowNormalTypeButton:SetHidden(isHidden)

            GrindTimerWindowChampionTypeButton:SetState(BSTATE_NORMAL)
            GrindTimerWindowChampionTypeButton:SetHidden(isHidden)

        -- Champion target level
        elseif targetLevelType == 2 then
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

    if mode == 1 then
        GrindTimerWindowLevelTextBox:SetHidden(true)
        GrindTimerWindowLevelTextBoxLabel:SetHidden(true)
    elseif mode == 2 then
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
    UpdateLabels()
    UpdateButtons()
    UpdateLevelTextBox()
    UpdateUIOpacity()
end

function GrindTimer.ToggleDisplay()
    GrindTimerWindow:SetHidden(not GrindTimerWindow:IsHidden())
end

-- Hides or shows the options normally hidden by the collapsed extender button.
function GrindTimer.UpdateExtendedControls()
    for key, control in pairs(extendedControls) do
        if control == GrindTimerWindowLevelTypeLabel then
            if GrindTimer.AccountSavedVariables.Mode == "Target" then
                control:SetHidden(controlsExtended)
            end
        else
        control:SetHidden(controlsExtended)
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

function GrindTimer.LevelTextBoxSubmitted(textBox, minValue, maxValue)
    local currentNumber = tonumber(textBox:GetText())

    if not currentNumber or currentNumber < minValue then
        currentNumber = minValue
        textBox:SetText(minValue)
    elseif currentNumber > maxValue then
        currentNumber = maxValue
        textBox:SetText(maxValue)
end

    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType

        -- Target normal level is lower than current normal level.
    if targetLevelType == 1 and not isChamp and currentNumber <= GetUnitLevel("player") then
            GrindTimer.SetNewTargetLevel(GetUnitLevel("player")+1)

        -- Target champion level is lower than current champion level.
    elseif targetLevelType == 2 and currentNumber <= GetPlayerChampionPointsEarned() then
            GrindTimer.SetNewTargetLevel(GetPlayerChampionPointsEarned()+1)
        else
        GrindTimer.SetNewTargetLevel(currentNumber)
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
    GrindTimerWindowLevelTypeLabel:SetHidden(true)

    GrindTimer.SavedVariables.Mode = 1
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.TargetModeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNextModeButton:SetState(BSTATE_NORMAL)
    GrindTimerWindowLevelTypeLabel:SetHidden(false)

    GrindTimer.SavedVariables.Mode = 2
    local targetLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimerWindowLevelTextBox:SetText(targetLevel)
    GrindTimer.SavedVariables.TargetLevelType = GrindTimer.SavedVariables.IsPlayerChampion and 2 or 1
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
        local newTargetLevel = GetUnitLevel("player")+1
        GrindTimerWindowLevelTextBox:SetText(newTargetLevel)
    end

    local targetLevel = GrindTimerWindowLevelTextBox:GetText()

    GrindTimer.SavedVariables.TargetLevelType = 1
    GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.UpdateUIControls()
end

function GrindTimer.ChampionTypeButtonClicked(button)
    button:SetState(BSTATE_PRESSED)
    GrindTimerWindowNormalTypeButton:SetState(BSTATE_NORMAL)

    local currentText = GrindTimerWindowLevelTextBox:GetText()
    local currentNumber = tonumber(currentText)

    GrindTimer.SavedVariables.TargetLevelType = 2

    if currentNumber ~= nil and currentNumber <= GetPlayerChampionPointsEarned() then
        GrindTimerWindowLevelTextBox:SetText(GetPlayerChampionPointsEarned()+1)
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
