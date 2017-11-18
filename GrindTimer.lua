GrindTimer = {}

GrindTimer.Name = "GrindTimer"
GrindTimer.ExpEvents = {}
GrindTimer.ExpEventTimeWindow = 900 -- Remember exp events from the last 15 minutes.
GrindTimer.LastUpdateTimestamp = GetTimeStamp()
GrindTimer.UpdateTimer = 5 -- Update every 5 seconds
GrindTimer.SettingsInitialized = false
GrindTimer.Version = "1.6.2"

GrindTimer.AccountDefaults =
{
    Opacity = 1,
    OutlineText = false,
    TextColor = {0.65, 0.65, 0.65},
    Locked = false,
    OffsetX = 400,
    OffsetY = 100,
    FirstLabelType = 1,
    SecondLabelType = 2
}

GrindTimer.Defaults =
{
    Mode = "Next",
    TargetHours = 0,
    TargetMinutes = 0,
    TargetExpRemaining = IsUnitChampion("player") and GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned()) - GetPlayerChampionXP() or GetUnitXPMax("player") - GetUnitXP("player"),
    KillsNeeded = 0,
    LevelsPerHour = 0,
    ExpPerHour = 0,
    RecentKills = 0,
    TargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1,
    TargetLevelType = IsUnitChampion("player") and "Champion" or "Normal"
}

function GrindTimer.Initialize(eventCode, addonName)
    if addonName == GrindTimer.Name then
        ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DISPLAY", "Toggle Window")
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_EXPERIENCE_GAIN, GrindTimer.Update)
        GrindTimer.SavedVariables = ZO_SavedVars:New("GrindTimerVars", GrindTimer.Version, "Character", GrindTimer.Defaults)
        GrindTimer.AccountSavedVariables = ZO_SavedVars:NewAccountWide("GrindTimerVars", GrindTimer.Version, "Account", GrindTimer.AccountDefaults)
        GrindTimer.InitializeUI()
        EVENT_MANAGER:UnregisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED)
    end
end

function GrindTimer.Reset()
    local isChamp = IsUnitChampion("player")

    GrindTimer.ExpEvents = {}
    GrindTimer.SavedVariables.Mode = "Next"
    GrindTimer.SavedVariables.TargetLevel = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
    GrindTimer.SavedVariables.TargetLevelType = isChamp and "Champion" or "Normal"
    GrindTimer.SavedVariables.TargetHours = 0
    GrindTimer.SavedVariables.TargetMinutes = 0
    GrindTimer.SavedVariables.KillsNeeded = 0
    GrindTimer.SavedVariables.LevelsPerHour = 0
    GrindTimer.SavedVariables.ExpPerHour = 0
    GrindTimer.SavedVariables.RecentKills = 0
    GrindTimer.SavedVariables.TargetExpRemaining = GrindTimer.GetExpNeeded()
end

-- ExpEvents used to track exp gains.
function GrindTimer.NewExpEvent(timestamp, expGained)
    local expEvent = {}
    expEvent.Timestamp = timestamp
    expEvent.ExpGained = expGained

    expEvent.IsExpired = function(self)
        return GetDiffBetweenTimeStamps(GetTimeStamp(), self.Timestamp) > GrindTimer.ExpEventTimeWindow
    end
    return expEvent
end

function GrindTimer.CreateExpEvent(timestamp, expGained)
    local newExpEvent = GrindTimer.NewExpEvent(timestamp, expGained)
    table.insert(GrindTimer.ExpEvents, newExpEvent)
end

function GrindTimer.CleanupExpiredEvents()
    for key, expEvent in pairs(GrindTimer.ExpEvents) do
        if expEvent:IsExpired() then
            GrindTimer.ExpEvents[key] = nil;
        end
    end
end

function GrindTimer.Update(eventCode, reason, level, previousExp, currentExp, championPoints)
    local currentTimestamp = GetTimeStamp()
    GrindTimer.CleanupExpiredEvents()

    if reason == 0 or reason == 24 or reason == 26 then
        local expGained = currentExp - previousExp
        GrindTimer.CreateExpEvent(currentTimestamp, expGained)
    end

    GrindTimer.UpdateVars()
    GrindTimer.UpdateUIControls()
    GrindTimer.LastUpdateTimestamp = currentTimestamp
end

function GrindTimer.TimedUpdate()
    if GrindTimer.SettingsInitialized then
        local currentTimestamp = GetTimeStamp()

        if GetDiffBetweenTimeStamps(currentTimestamp, GrindTimer.LastUpdateTimestamp) >= GrindTimer.UpdateTimer then
            GrindTimer.CleanupExpiredEvents()
            GrindTimer.UpdateVars()
            GrindTimer.UpdateUIControls()
            GrindTimer.LastUpdateTimestamp = currentTimestamp
        end
    end
end

function GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.SavedVariables.TargetLevel = targetLevel
    GrindTimer.UpdateVars()
end

function GrindTimer.GetExpNeeded()
    local isChamp = IsUnitChampion("player")
    local level = GetUnitLevel("player")
    local championPoints = GetPlayerChampionPointsEarned()
    local currentExp = isChamp and GetPlayerChampionXP() or GetUnitXP("player")
    local maxExp = isChamp and GetNumChampionXPInChampionPoint(championPoints) or GetUnitXPMax("player")
    local expNeeded = 0

    if GrindTimer.SavedVariables.Mode == "Next" then
        expNeeded = maxExp - currentExp
    else
        expNeeded = GrindTimer.GetTargetLevelExp(level, championPoints, isChamp)
    end
    return expNeeded
end

function GrindTimer.GetTargetLevelExp(level, championPoints, isChamp)
    local targetLevel = GrindTimer.SavedVariables.TargetLevel
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType
    local totalExpRequired = 0

    if not isChamp and targetLevelType == "Normal" then
        for i = level, targetLevel-1 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end
        totalExpRequired = totalExpRequired - GetUnitXP("player")

    elseif not isChamp and targetLevelType == "Champion" then
        for i = level, 49 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end
        for i = championPoints, targetLevel-1 do
            local championPointExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + championPointExp
        end
        totalExpRequired = totalExpRequired - GetPlayerChampionXP() - GetUnitXP("player")
        
    elseif isChamp then
        for i = championPoints, targetLevel-1 do
            local championPointExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + championPointExp
        end
        totalExpRequired = totalExpRequired - GetPlayerChampionXP()
    end
    
    return totalExpRequired
end

function GrindTimer.GetExpGainPerMinute()
    local totalExpGained = 0
    local firstRememberedEvent = 0
    local count = 0

    for key, expEvent in pairs(GrindTimer.ExpEvents) do
        if count == 0 then
            firstRememberedEvent = expEvent.Timestamp
        end

        totalExpGained = totalExpGained + expEvent.ExpGained
        count = count + 1
    end

    local timeDiff = GetDiffBetweenTimeStamps(GetTimeStamp(), firstRememberedEvent)
    timeDiff = (timeDiff == 0) and 1 or timeDiff

    local expGainPerMinute = totalExpGained / (timeDiff/60)
    return expGainPerMinute
end

function GrindTimer.GetLevelsPerHour(expGainPerHour)
    if expGainPerHour == 0 then
        return 0
    end
    local isChamp = IsUnitChampion("player")
    local playerLevel = isChamp and GetPlayerChampionPointsEarned() or GetUnitLevel("player")
    local levelsPerHour = 0

    if isChamp then
        -- Champion levels gained in the next hour.
        for i = playerLevel, 1000 do
            local expInLevel = GetNumChampionXPInChampionPoint(i)
            if i == playerLevel then
                expNeeded = expInLevel - GetPlayerChampionXP()
                expGainPerHour = expGainPerHour - expNeeded
            else
                expGainPerHour = expGainPerHour - expInLevel
            end
            if expGainPerHour >= 0 then
                levelsPerHour = levelsPerHour + 1
            else
                break
            end
        end
    else
        -- Normal levels in the next hour, up to level 50.
        local levelsTil50 = (50-playerLevel-1) + playerLevel

        for i = playerLevel, levelsTil50 do
            local expInLevel = GetNumExperiencePointsInLevel(i)
            if i == playerLevel then
                expNeeded = expInLevel - GetUnitXP("player")
                expGainPerHour = expGainPerHour - expNeeded
            else
                expGainPerHour = expGainPerHour - expInLevel
            end
            if expGainPerHour >= 0 then
                levelsPerHour = levelsPerHour + 1
            else
                break
            end
        end
        if expGainPerHour >= 0 then
            for i = 0, 1000 do
                local expInLevel = GetNumChampionXPInChampionPoint(i)
                expGainPerHour = expGainPerHour - expInLevel

                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    break
                end
            end
        end
    end
    return levelsPerHour
end

function GrindTimer.GetKillInfo()
    local totalExpGained = 0
    local kills = 0

    for key, expEvent in pairs(GrindTimer.ExpEvents) do
        totalExpGained = totalExpGained + expEvent.ExpGained
        kills = kills + 1
    end

    local average = totalExpGained / kills
    return average, kills
end

function GrindTimer.GetLevelTimeRemaining(expGainPerMinute, expRemaining)
    local rawMinutesToLevel = math.ceil(expRemaining / expGainPerMinute)
    local minutesToLevel = 0
    local hoursToLevel = 0

    if rawMinutesToLevel > 60 then
        hoursToLevel = math.floor(rawMinutesToLevel / 60)
        minutesToLevel = rawMinutesToLevel - math.floor(rawMinutesToLevel/60) * 60
    else
        minutesToLevel = rawMinutesToLevel
    end

    return hoursToLevel, minutesToLevel
end

function GrindTimer.UpdateVars()
    local expNeeded = GrindTimer.GetExpNeeded()
    local expGainPerMinute = GrindTimer.GetExpGainPerMinute()
    local expGainPerHour = math.floor(expGainPerMinute*60)
    local levelsPerHour = GrindTimer.GetLevelsPerHour(expGainPerHour)
    local hours, minutes = GrindTimer.GetLevelTimeRemaining(expGainPerMinute, expNeeded)
    local averageExpPerKill, recentKills = GrindTimer.GetKillInfo()
    local killsNeeded = math.ceil(expNeeded / averageExpPerKill)

    -- Check for INF / IND
    hours = (hours == math.huge or hours == -math.huge) and 0 or hours
    minutes = (minutes ~= minutes or minutes == math.huge or minutes == -math.huge) and 0 or minutes
    averageExpPerKill = (averageExpPerKill ~= averageExpPerKill) and 0 or averageExpPerKill
    killsNeeded = (killsNeeded ~= killsNeeded) and 0 or killsNeeded
    expGainPerHour = (expGainPerHour ~= expGainPerHour) and 0 or expGainPerHour

    GrindTimer.SavedVariables.TargetHours = hours
    GrindTimer.SavedVariables.TargetMinutes = minutes
    GrindTimer.SavedVariables.TargetExpRemaining = expNeeded
    GrindTimer.SavedVariables.RecentKills = recentKills
    GrindTimer.SavedVariables.KillsNeeded = killsNeeded
    GrindTimer.SavedVariables.ExpPerHour = expGainPerHour
    GrindTimer.SavedVariables.LevelsPerHour = levelsPerHour
end

EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED, GrindTimer.Initialize)
