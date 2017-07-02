GrindTimer = {}

GrindTimer.Name = "GrindTimer"
GrindTimer.RecentExpEvents = {}
GrindTimer.RecentEventTimeWindow = 600 -- Only remember events from the last 10 minutes of exp gains.
GrindTimer.Version = "1.5.0"

GrindTimer.AccountDefaults =
{
    Opacity = 1,
    OutlineText = false,
    TextColor = {R = 0.65, G = 0.65, B = 0.65},
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
    AverageExpPerHour = 0,
    RecentKills = 0,
    TargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1,
    TargetLevelType = IsUnitChampion("player") and "Champion" or "Normal"
}

function GrindTimer.OnAddOnLoaded(eventCode, addonName)
    if addonName ~= GrindTimer.Name then return end
    GrindTimer.Initialize()
end

function GrindTimer.Initialize(eventCode, addonName)
    ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DISPLAY", "Toggle Window")
    EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_EXPERIENCE_GAIN, GrindTimer.OnExpGained)
    GrindTimer.SavedVariables = ZO_SavedVars:New("GrindTimerVars", GrindTimer.Version, "Character", GrindTimer.Defaults)
    GrindTimer.AccountSavedVariables = ZO_SavedVars:NewAccountWide("GrindTimerVars", GrindTimer.Version, "Account", GrindTimer.AccountDefaults)
    GrindTimer.InitializeUI()
end

function GrindTimer.Reset()
    local isChamp = IsUnitChampion("player")
    local championPoints = isChamp and GetPlayerChampionPointsEarned() or nil
    local targetLevel = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1

    GrindTimer.SavedVariables.TargetHours = 0
    GrindTimer.SavedVariables.TargetMinutes = 0
    GrindTimer.SavedVariables.TargetExpRemaining = GrindTimer.GetTargetLevelEXP(GetUnitLevel("player"), targetLevel, isChamp and 3 or 1, GetPlayerChampionPointsEarned())
    GrindTimer.SavedVariables.KillsNeeded = 0
    GrindTimer.SavedVariables.LevelsPerHour = 0
    GrindTimer.SavedVariables.AverageExpPerHour = 0
    GrindTimer.SavedVariables.RecentKills = 0
    GrindTimer.SavedVariables.Mode = "Next"
    GrindTimer.SavedVariables.TargetLevel = isChamp and championPoints+1 or GetUnitLevel("player")+1
    GrindTimer.SavedVariables.TargetLevelType = isChamp and "Champion" or "Normal"
    GrindTimer.RecentExpEvents = {}
end

function GrindTimer.AddEventToArray(newExpEvent)
    table.insert(GrindTimer.RecentExpEvents, newExpEvent)
    GrindTimer.CleanupExpiredEvents()
end

function GrindTimer.CleanupExpiredEvents()
    for key, recentExpEvent in pairs(GrindTimer.RecentExpEvents) do
        if recentExpEvent:IsExpired() then
            GrindTimer.RecentExpEvents[key] = nil;
        end
    end
end

function GrindTimer.OnExpGained(eventCode, reason, level, playerPreviousExp, playerCurrentExp, championPoints)
    local timestamp = GetTimeStamp()
    local playerExpGained = playerCurrentExp - playerPreviousExp

    -- Create ExpEvent object for tracking recent experience gains.
    local newExpEvent = GrindTimerExpEvent:New(timestamp, playerExpGained, reason)
    GrindTimer.AddEventToArray(newExpEvent)

    if GrindTimer.SavedVariables.Mode == "Next" then
        GrindTimer.NextLevelUpdate(timestamp, level, playerPreviousExp, playerCurrentExp, championPoints)
    elseif GrindTimer.SavedVariables.Mode == "Target" then
        GrindTimer.TargetLevelUpdate(timestamp, level, playerPreviousExp, playerCurrentExp, championPoints)
    end
end

function GrindTimer.NextLevelUpdate(timestamp, level, playerPreviousExp, playerCurrentExp, championPoints)
    local isChamp = IsUnitChampion("player")
    local playerCurrentMaxExp = isChamp and GetNumChampionXPInChampionPoint(championPoints) or GetUnitXPMax("player")

    local playerExpNeeded = playerCurrentMaxExp - playerCurrentExp
    local leveledUp = playerExpNeeded < 0

    if leveledUp and not isChamp then
        level = level + 1
        playerExpNeeded = GetUnitXPMax("player") + playerExpNeeded
    elseif leveledUp and isChamp then
        championPoints = (GetPlayerChampionPointsEarned() > 0) and championPoints + 1 or 0
        playerExpNeeded = GetNumChampionXPInChampionPoint(championPoints) + playerExpNeeded
    end

    local expGainPerMinute = GrindTimer.GetExpGainPerMinute()
    local hours, minutes = GrindTimer.GetLevelTimeRemaining(expGainPerMinute, playerExpNeeded)
    local averageExpPerKill, recentKills = GrindTimer.GetAverageExpPerKill()
    local killsNeeded = math.ceil(playerExpNeeded / averageExpPerKill)
    local expGainPerHour = math.floor(expGainPerMinute*60)
    local levelsPerHour = GrindTimer.GetLevelsPerHour()

    GrindTimer.SaveVars(hours, minutes, playerExpNeeded, recentKills, killsNeeded, expGainPerHour, levelsPerHour)
    GrindTimer.UpdateLabels()
end

function GrindTimer.TargetLevelUpdate(timestamp, level, playerPreviousExp, playerCurrentExp, championPoints)
    local targetLevel = GrindTimer.SavedVariables.TargetLevel
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType
    local isChamp = IsUnitChampion("player")
    local playerExpNeeded = 0

    if not isChamp and targetLevelType == "Normal" then
        playerExpNeeded = GrindTimer.GetTargetLevelEXP(level, targetLevel, 1, championPoints)
    elseif not isChamp and targetLevelType == "Champion" then
        playerExpNeeded = GrindTimer.GetTargetLevelEXP(level, targetLevel, 2, championPoints)
    elseif isChamp then
        playerExpNeeded = GrindTimer.GetTargetLevelEXP(level, targetLevel, 3, championPoints)
    end

    local expGainPerMinute = GrindTimer.GetExpGainPerMinute()
    local hours, minutes = GrindTimer.GetLevelTimeRemaining(expGainPerMinute, playerExpNeeded)
    local averageExpPerKill, recentKills = GrindTimer.GetAverageExpPerKill()
    local killsNeeded = math.ceil(playerExpNeeded / averageExpPerKill)
    local expGainPerHour = math.floor(expGainPerMinute*60)
    local levelsPerHour = GrindTimer.GetLevelsPerHour()

    GrindTimer.SaveVars(hours, minutes, playerExpNeeded, recentKills, killsNeeded, expGainPerHour, levelsPerHour)
    GrindTimer.UpdateLabels()
end

function GrindTimer.GetTargetLevelEXP(level, targetLevel, mode, championPoints)
    --[[
    mode 1 = Both player and target level are not champion.
    mode 2 = player is not champion, but target level is. Does not currently work.
    mode 3 = player is champion, therefore target level also is.
    ]]

    local totalExpRequired = 0    

    if mode == 1 then
        targetLevel = (tonumber(targetLevel) == 50) and 49 or targetLevel
        for i = level, targetLevel-1 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end

    --[[
    elseif mode == 2 then
        -- Normal Levels.
        for i = level, 50 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end

        -- Champion Levels.
        --if championPoints then
        for i = (championPoints) and championPoints or 0, targetLevel do
            local champLevelExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + levelExp
        end
    ]]

    elseif mode == 3 then
        for i = championPoints, targetLevel-1 do
            local champLevelExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + champLevelExp
        end
    end

    totalExpRequired = IsUnitChampion("player") and totalExpRequired - GetPlayerChampionXP() or totalExpRequired - GetUnitXP("player")
    return totalExpRequired
end

function GrindTimer.GetExpGainPerMinute()

    local totalExpGained = 0
    local firstRememberedEvent = 0
    local iteration = 0

    for key, recentExpEvent in pairs(GrindTimer.RecentExpEvents) do
        if iteration == 0 then
            firstRememberedEvent = recentExpEvent.Timestamp
        end

        totalExpGained = totalExpGained + recentExpEvent.ExpGained
        iteration = iteration + 1
    end

    local timeDiff = GetDiffBetweenTimeStamps(GetTimeStamp(), firstRememberedEvent)

    if timeDiff == 0 then
        timeDiff = 1
    end

    local expGainPerMinute = totalExpGained / (timeDiff/60)

    return expGainPerMinute
end

function GrindTimer.GetLevelsPerHour()
    local expGainPerMinute = GrindTimer.GetExpGainPerMinute()
    local expGainPerHour = (expGainPerMinute ~= 0) and math.floor(expGainPerMinute*60) or 0
    if expGainPerHour == 0 then
        return 0
    end
    local isChamp = IsUnitChampion("player")
    local expNeededToLevelUp = 0
    local playerLevel = isChamp and GetPlayerChampionPointsEarned() or GetUnitLevel("player")
    local levelsPerHour = 0

    if isChamp then
        -- Champion leels gained in the next hour.
        for i = playerLevel, playerLevel+100 do
            local expInLevel = GetNumChampionXPInChampionPoint(i)
            if levelsPerHour == 0 then
                expNeededToLevelUp = expInLevel - GetPlayerChampionXP()
                expGainPerHour = expGainPerHour - expNeededToLevelUp
                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    break
                end
            else
                expGainPerHour = expGainPerHour - expInLevel
                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    break
                end
            end
        end
    else
        -- Normal levels in the next hour, up to level 50.
        local levelsTil50 = 50-playerLevel
        local normalLoopBroken = false

        for i = playerLevel, playerLevel+levelsTil50 do
            local expInLevel = GetNumExperiencePointsInLevel(playerLevel)
            if levelsPerHour == 0 then
                expNeededToLevelUp = expInLevel - GetUnitXP("player")
                expGainPerHour = expGainPerHour - expNeededToLevelUp
                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    normalLoopBroken = true
                    break
                end
            else
                expGainPerHour = expGainPerHour - expInLevel
                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    normalLoopBroken = true
                    break
                end
            end
        end

        -- If player will pass normal level 50 in the next hour, calculate champion levels gained as well.
        --[[ Returns nil if player isn't champion...
        if not normalLoopBroken then
            for i = 0, 100-levelsTil50 do
                local expInLevel = GetNumChampionXPInChampionPoint(i)
                expGainPerHour = expGainPerHour - expInLevel
                if expGainPerHour >= 0 then
                    levelsPerHour = levelsPerHour + 1
                else
                    break
                end
            end
        end     
        ]]   
    end
    return levelsPerHour
end

function GrindTimer.GetAverageExpPerKill()
    local totalExpGained = 0
    local kills = 0

    for key, recentExpEvent in pairs(GrindTimer.RecentExpEvents) do
        if recentExpEvent.Reason == 0 then
            totalExpGained = totalExpGained + recentExpEvent.ExpGained
            kills = kills + 1
        end
    end

    local average = totalExpGained / kills
    return average, kills
end

function GrindTimer.GetLevelTimeRemaining(expGainPerMinute, expRemaining)
    local actualMinutesToLevel = math.ceil(expRemaining / expGainPerMinute)
    local minutesToLevel = 0
    local hoursToLevel = 0

    if actualMinutesToLevel > 60 then
        hoursToLevel = math.floor(actualMinutesToLevel / 60)
        minutesToLevel = actualMinutesToLevel - math.floor(actualMinutesToLevel/60) * 60
    else
        minutesToLevel = actualMinutesToLevel
    end

    return hoursToLevel, minutesToLevel
end

function GrindTimer.SaveVars(hours, minutes, playerExpNeeded, recentKills, killsNeeded, expGainPerHour, levelsPerHour)
    GrindTimer.SavedVariables.TargetHours = hours
    GrindTimer.SavedVariables.TargetMinutes = minutes
    GrindTimer.SavedVariables.TargetExpRemaining = playerExpNeeded
    GrindTimer.SavedVariables.RecentKills = recentKills
    GrindTimer.SavedVariables.KillsNeeded = killsNeeded
    GrindTimer.SavedVariables.AverageExpPerHour = expGainPerHour
    GrindTimer.SavedVariables.LevelsPerHour = levelsPerHour
end

EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED, GrindTimer.OnAddOnLoaded)
