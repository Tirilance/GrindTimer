GrindTimer = {}

GrindTimer.Name = "GrindTimer"
GrindTimer.Version = "1.13.6"
GrindTimer.SavedVariableVersion = "6"
GrindTimer.AccountSavedVariablesVersion = "6"
GrindTimer.UIInitialized = false

GrindTimer.Mode =
{
    Next = 1,
    Target = 2
}

GrindTimer.TargetType =
{
    Normal = 1,
    Champion = 2
}

GrindTimer.Metric =
{
    DolmensRemaining = 1,
    DungeonRunsRemaining = 2,
    ExpPerMinute = 3,
    ExpPerHour = 4,
    ExpRemaining = 5,
    KillsInSession = 6,
    KillsRecently = 7,
    KillsRemaining = 8,
    LevelsInSession = 9,
    LevelsPerHour = 10,
    TimeRemaining = 11
}

local DungeonInfo = {}
local LastUpdateTimestamp = GetTimeStamp()
local UpdateTimer = 5 -- Update every 5 seconds
local DungeonName
local IsPlayerInDungeon = false
local IsPlayerInDolmen = false
local CurrentSessionKills = 0
local CurrentSessionLevels = 0
local SessionStartLevel = 0

local AccountDefaults =
{
    Opacity = 1,
    OutlineText = false,
    TextColor = { 0.65, 0.65, 0.65 },
    FontSize = 18,
    Locked = false,
    OffsetX = 400,
    OffsetY = 100,
    FirstLabelType = GrindTimer.Metric.TimeRemaining,
    SecondLabelType = GrindTimer.Metric.ExpRemaining,
    SecondLabelEnabled = true,
    AbbreviateNumbers = false,
    AbbreviateTime = false
}

local Defaults =
{
    Mode = GrindTimer.Mode.Next,
    TargetHours = 0,
    TargetMinutes = 0,
    TargetSeconds = 0,
    TargetExpRemaining = IsUnitChampion("player") and GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned()) - GetPlayerChampionXP() or
        GetUnitXPMax("player") - GetUnitXP("player"),
    KillsNeeded = 0,
    LevelsPerHour = 0,
    ExpPerHour = 0,
    RecentKills = 0,
    LastDungeonName = nil,
    DungeonRunsNeeded = 0,
    DolmensNeeded = 0,
    SessionKills = 0,
    SessionLevels = 0,
    TargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned() + 1 or GetUnitLevel("player") + 1,
    TargetLevelType = IsUnitChampion("player") and GrindTimer.TargetType.Champion or GrindTimer.TargetType.Normal,
    IsPlayerChampion = IsUnitChampion("player")
}

-- ExpEvents used to track exp gains.
local ExpEvent =
{
    EventReason =
    {
        Kill = 1,
        Dolmen = 2,
        Other = 3
    },

    EventCount = 0,
    Events = {},
    Timeout = 900
}

function ExpEvent.Create(timestamp, expGained, isDungeon, isDolmen, reason)
    local newExpEvent = {}

    newExpEvent.Timestamp = timestamp
    newExpEvent.ExpGained = expGained
    newExpEvent.IsDungeon = isDungeon
    newExpEvent.IsDolmen = isDolmen

    if reason == 0 or reason == 24 or reason == 26 then
        newExpEvent.Reason = ExpEvent.EventReason.Kill
        CurrentSessionKills = CurrentSessionKills + 1
    elseif reason == 7 then
        newExpEvent.Reason = ExpEvent.EventReason.Dolmen
    else
        newExpEvent.Reason = ExpEvent.EventReason.Other
    end

    newExpEvent.IsExpired = function(self)
        return GetDiffBetweenTimeStamps(GetTimeStamp(), self.Timestamp) > ExpEvent.Timeout
    end

    table.insert(ExpEvent.Events, newExpEvent)
    ExpEvent.EventCount = ExpEvent.EventCount + 1

    return newExpEvent
end

local function ClearDungeonExpEvents()
    for key, expEvent in pairs(ExpEvent.Events) do
        if expEvent.IsDungeon then
            ExpEvent.Events[key] = nil
            ExpEvent.EventCount = ExpEvent.EventCount - 1
        end
    end
end

local function GetTargetLevelExp(championPoints, isChamp)
    local level = GetUnitLevel("player")
    local targetLevel = GrindTimer.SavedVariables.TargetLevel
    local targetLevelType = GrindTimer.SavedVariables.TargetLevelType
    local totalExpRequired = 0

    if not isChamp and targetLevelType == GrindTimer.TargetType.Normal then
        for i = level, targetLevel - 1 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end
        totalExpRequired = totalExpRequired - GetUnitXP("player")

    elseif not isChamp and targetLevelType == GrindTimer.TargetType.Champion then
        for i = level, 49 do
            local levelExp = GetNumExperiencePointsInLevel(i)
            totalExpRequired = totalExpRequired + levelExp
        end
        for i = championPoints, targetLevel - 1 do
            local championPointExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + championPointExp
        end
        totalExpRequired = totalExpRequired - GetPlayerChampionXP() - GetUnitXP("player")

    elseif isChamp then
        for i = championPoints, targetLevel - 1 do
            local championPointExp = GetNumChampionXPInChampionPoint(i)
            totalExpRequired = totalExpRequired + championPointExp
        end
        totalExpRequired = totalExpRequired - GetPlayerChampionXP()
    end

    return totalExpRequired
end

local function GetExpNeeded()
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
    local championPoints = GetPlayerChampionPointsEarned()
    local currentExp = isChamp and GetPlayerChampionXP() or GetUnitXP("player")
    local maxExp = isChamp and GetNumChampionXPInChampionPoint(championPoints) or GetUnitXPMax("player")
    local expNeeded = 0

    if GrindTimer.SavedVariables.Mode == GrindTimer.Mode.Next then
        expNeeded = maxExp - currentExp
    else
        expNeeded = GetTargetLevelExp(championPoints, isChamp)
    end
    return expNeeded
end

local function GetExpGainPerMinute(totalExpGained, oldestEventTimestamp)
    local timeDiff = GetDiffBetweenTimeStamps(GetTimeStamp(), oldestEventTimestamp)
    timeDiff = (timeDiff == 0) and 1 or timeDiff

    local expGainPerMinute = totalExpGained / (timeDiff / 60)
    return expGainPerMinute
end

local function GetLevelsPerHour(expGainPerHour)
    if expGainPerHour == 0 then
        return 0
    end
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
    local championPoints = GetPlayerChampionPointsEarned()
    local playerLevel = GetUnitLevel("player")
    local levelsPerHour = 0

    if isChamp then
        -- Champion levels gained in the next hour.
        for i = championPoints, championPoints + 1000 do
            local expInLevel = GetNumChampionXPInChampionPoint(i)
            if i == championPoints then
                local expNeeded = expInLevel - GetPlayerChampionXP()
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
        -- Normal levels up to 50 in the next hour.
        for i = playerLevel, 49 do
            local expInLevel = GetNumExperiencePointsInLevel(i)
            if i == playerLevel then
                local expNeeded = expInLevel - GetUnitXP("player")
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
        -- Champion levels surpassing level 50 in the next hour.
        if expGainPerHour >= 0 then
            for i = championPoints, championPoints + 1000 do
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

local function GetLevelTimeRemaining(expGainPerMinute, expRemaining)
    local rawMinutesToLevel = math.ceil(expRemaining / expGainPerMinute)
    local minutesToLevel = 0
    local hoursToLevel = 0

    if rawMinutesToLevel > 60 then
        hoursToLevel = math.floor(rawMinutesToLevel / 60)
        minutesToLevel = rawMinutesToLevel - math.floor(rawMinutesToLevel / 60) * 60
    else
        minutesToLevel = rawMinutesToLevel
    end

    return hoursToLevel, minutesToLevel
end

local function GetDolmensNeeded(expNeeded, dolmenExpGained, dolmensClosed)
    local averageDolmenExp = dolmenExpGained / dolmensClosed
    local dolmensNeeded = math.ceil(expNeeded / averageDolmenExp)

    return dolmensNeeded
end

local function GetDungeonRunsNeeded(expNeeded)
    local dungeonInfo = DungeonInfo[DungeonName]

    if dungeonInfo ~= nil then
        local averagePerRun = dungeonInfo.Average
        local runsNeeded = math.ceil(expNeeded / averagePerRun)

        return runsNeeded
    end
end

local function GetDungeonRunExp()
    local totalExpGained = 0

    for key, expEvent in pairs(ExpEvent.Events) do
        if expEvent.IsDungeon then
            totalExpGained = totalExpGained + expEvent.ExpGained
        end
    end

    return totalExpGained
end

local function IncrementDungeonRuns()
    local dungeonInfo = DungeonInfo[DungeonName]
    local runExp = GetDungeonRunExp()
    local runCount, exp, average = nil, nil, nil

    if dungeonInfo ~= nil and runExp > 0 then
        runCount = dungeonInfo.RunCount + 1
        exp = dungeonInfo.Experience + runExp
        average = exp / runCount
    elseif runExp > 0 then
        runCount = 1
        exp = runExp
        average = exp
    else
        return
    end

    DungeonInfo[DungeonName] = { Experience = exp, RunCount = runCount, Average = average }
end

local function UpdateVars()
    local expNeeded = GetExpNeeded()
    local oldestEventTimestamp = math.huge

    local totalExpGained = 0
    local expGainPerMinute = 0
    local expGainPerHour = 0
    local levelsPerHour = 0
    local hours, minutes, seconds = 0, 0, 0

    local killExpGained = 0
    local averageKillExp = 0
    local recentKillCount = 0
    local killsNeeded = 0

    local dolmenExpGained = 0
    local dolmensClosed = 0
    local dolmensNeeded = 0

    if ExpEvent.EventCount > 0 then
        for key, expEvent in pairs(ExpEvent.Events) do

            if expEvent:IsExpired() then
                ExpEvent.Events[key] = nil
                ExpEvent.EventCount = ExpEvent.EventCount - 1

            else
                totalExpGained = totalExpGained + expEvent.ExpGained

                if expEvent.Reason == ExpEvent.EventReason.Kill then
                    killExpGained = killExpGained + expEvent.ExpGained
                    recentKillCount = recentKillCount + 1
                end

                if expEvent.IsDolmen then
                    dolmenExpGained = dolmenExpGained + expEvent.ExpGained

                    if expEvent.Reason == ExpEvent.EventReason.Dolmen then
                        dolmensClosed = dolmensClosed + 1
                    end
                end

                if expEvent.Timestamp < oldestEventTimestamp then
                    oldestEventTimestamp = expEvent.Timestamp
                end
            end
        end

        expGainPerMinute = GetExpGainPerMinute(totalExpGained, oldestEventTimestamp)
        expGainPerHour = math.floor(expGainPerMinute * 60)
        levelsPerHour = GetLevelsPerHour(expGainPerHour)
        hours, minutes = GetLevelTimeRemaining(expGainPerMinute, expNeeded)
        seconds = (hours * 60 * 60) + (minutes * 60)

        averageKillExp = killExpGained / recentKillCount
        killsNeeded = math.ceil(expNeeded / averageKillExp)
        dolmensNeeded = GetDolmensNeeded(expNeeded, dolmenExpGained, dolmensClosed)

        local playerLevel = GrindTimer.SavedVariables.IsPlayerChampion and GetPlayerChampionPointsEarned() or GetUnitLevel("player")
        if playerLevel ~= SessionStartLevel then
            SessionLevels = playerLevel - SessionStartLevel
        end

        -- Check for INF / IND
        hours = (hours == math.huge or hours == -math.huge) and 0 or hours
        minutes = (minutes ~= minutes or minutes == math.huge or minutes == -math.huge) and 0 or minutes
        seconds = (seconds ~= seconds or seconds == math.huge or seconds == -math.huge) and 0 or seconds
        averageKillExp = (averageKillExp ~= averageKillExp) and 0 or averageKillExp
        killsNeeded = (killsNeeded ~= killsNeeded) and 0 or killsNeeded
        expGainPerHour = (expGainPerHour ~= expGainPerHour) and 0 or expGainPerHour
        dolmensNeeded = (dolmensNeeded ~= dolmensNeeded) and 0 or dolmensNeeded

        GrindTimer.SavedVariables.TargetHours = hours
        GrindTimer.SavedVariables.TargetMinutes = minutes
        GrindTimer.SavedVariables.TargetSeconds = seconds
        GrindTimer.SavedVariables.RecentKills = recentKillCount
        GrindTimer.SavedVariables.KillsNeeded = killsNeeded
        GrindTimer.SavedVariables.ExpPerHour = expGainPerHour
        GrindTimer.SavedVariables.LevelsPerHour = levelsPerHour
        GrindTimer.SavedVariables.DolmensNeeded = dolmensNeeded
        GrindTimer.SavedVariables.SessionKills = CurrentSessionKills
    end

    -- Update these metrics even without any active ExpEvents
    GrindTimer.SavedVariables.TargetExpRemaining = expNeeded
    GrindTimer.SavedVariables.SessionLevels = CurrentSessionLevels
end

local function Update(eventCode, reason, level, previousExp, currentExp, championPoints)
    local currentTimestamp = GetTimeStamp()
    local expGained = currentExp - previousExp

    ExpEvent.Create(currentTimestamp, expGained, IsPlayerInDungeon, IsPlayerInDolmen, reason)

    UpdateVars()
    GrindTimer.UpdateMetricLabels()
    LastUpdateTimestamp = currentTimestamp
end

local function UpdateDungeonInfo()
    local dungeonRunsNeeded = GetDungeonRunsNeeded(GetExpNeeded())

    if dungeonRunsNeeded ~= nil then
        -- Check for INF
        dungeonRunsNeeded = (dungeonRunsNeeded == math.huge or dungeonRunsNeeded == -math.huge) and 0 or dungeonRunsNeeded

        GrindTimer.SavedVariables.DungeonRunsNeeded = dungeonRunsNeeded
        GrindTimer.SavedVariables.LastDungeonName = DungeonName
    end
end

local function PlayerActivated(eventCode, initial)
    if initial then
        local isChamp = IsUnitChampion("player")
        SessionStartLevel = isChamp and GetPlayerChampionPointsEarned() or GetUnitLevel("player")
        GrindTimer.SavedVariables.IsPlayerChampion = isChamp
    end

    IsPlayerInDolmen = string.match(GetPlayerActiveSubzoneName(), "Dolmen") and true or false

    if IsUnitInDungeon("player") then
        IsPlayerInDungeon = true
        DungeonName = GetUnitZone("player")
    elseif DungeonName ~= nil then
        IncrementDungeonRuns()
        UpdateDungeonInfo()
        ClearDungeonExpEvents()
        IsPlayerInDungeon = false
        DungeonName = nil
    end
end

local function ZoneChanged(eventCode, zoneName, subZoneName, isNewSubzone, zoneId, subZoneId)
    IsPlayerInDolmen = string.match(subZoneName, "Dolmen") and true or false
end

local function NormalLevelGained(eventCode, unitTag, newLevel)
    if unitTag == "player" then
        if GrindTimer.SavedVariables.TargetLevel == newLevel then
            GrindTimer.SetNewTargetLevel(newLevel + 1)
        end

        if IsUnitChampion("player") then
            GrindTimer.SavedVariables.IsPlayerChampion = true
            GrindTimer.SetNewTargetLevel(GetPlayerChampionPointsEarned() + 1)
        end

        SessionLevels = SessionLevels + 1
    end
end

local function ChampionLevelGained(eventCode, championPointsGained)
    local currentChampionLevel = GetPlayerChampionPointsEarned()

    if GrindTimer.SavedVariables.TargetLevel == currentChampionLevel then
        GrindTimer.SetNewTargetLevel(currentChampionLevel + championPointsGained)
    end

    SessionLevels = SessionLevels + 1
end

local function Initialize(eventCode, addonName)
    if addonName == GrindTimer.Name then
        GrindTimer.SavedVariables = ZO_SavedVars:NewCharacterIdSettings("GrindTimerVars", GrindTimer.SavedVariableVersion, "Character", Defaults)
        GrindTimer.AccountSavedVariables = ZO_SavedVars:NewAccountWide("GrindTimerVars", GrindTimer.AccountSavedVariablesVersion, "Account", AccountDefaults)

        ZO_CreateStringId("SI_BINDING_NAME_GRIND_TIMER_TOGGLE", "Show/Hide Window")

        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_LEVEL_UPDATE, NormalLevelGained)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_CHAMPION_POINT_GAINED, ChampionLevelGained)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_EXPERIENCE_GAIN, Update)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ZONE_CHANGED, ZoneChanged)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_PLAYER_ACTIVATED, PlayerActivated)

        EVENT_MANAGER:UnregisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED)

        GrindTimer.InitializeUI()
    end
end

function GrindTimer.Reset()
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion

    CurrentSessionKills = 0
    CurrentSessionLevels = 0
    SessionStartLevel = isChamp and GetPlayerChampionPointsEarned() or GetUnitLevel("player")

    ExpEvent.Events = {}
    ExpEvent.EventCount = 0

    GrindTimer.SavedVariables.Mode = GrindTimer.Mode.Next
    GrindTimer.SavedVariables.TargetLevel = isChamp and GetPlayerChampionPointsEarned() + 1 or GetUnitLevel("player") + 1
    GrindTimer.SavedVariables.TargetLevelType = isChamp and GrindTimer.TargetType.Champion or GrindTimer.TargetType.Normal
    GrindTimer.SavedVariables.TargetHours = 0
    GrindTimer.SavedVariables.TargetMinutes = 0
    GrindTimer.SavedVariables.TargetSeconds = 0
    GrindTimer.SavedVariables.KillsNeeded = 0
    GrindTimer.SavedVariables.LevelsPerHour = 0
    GrindTimer.SavedVariables.ExpPerHour = 0
    GrindTimer.SavedVariables.RecentKills = 0
    GrindTimer.SavedVariables.TargetExpRemaining = GetExpNeeded()
    GrindTimer.SavedVariables.LastDungeonName = nil
    GrindTimer.SavedVariables.DungeonRunsNeeded = 0
    GrindTimer.SavedVariables.DolmensNeeded = 0
    GrindTimer.SavedVariables.SessionKills = 0
    GrindTimer.SavedVariables.SessionLevels = 0
    GrindTimer.SavedVariables.IsPlayerChampion = isChamp
end

-- Updates Grind Timer every 5 seconds if no exp is gained within those 5 seconds.
function GrindTimer.TimedUpdate()
    if GrindTimer.UIInitialized then
        local currentTimestamp = GetTimeStamp()

        if GetDiffBetweenTimeStamps(currentTimestamp, LastUpdateTimestamp) >= UpdateTimer then
            UpdateVars()
            GrindTimer.UpdateMetricLabels()
            LastUpdateTimestamp = currentTimestamp
        end
    end
end

function GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.SavedVariables.TargetLevel = targetLevel
    UpdateVars()
    GrindTimer.UpdateMetricLabels()
end

function GrindTimer.HasGainedExpFromDungeon(dungeonName)
    local dungeonInfo = DungeonInfo[dungeonName]

    if dungeonInfo ~= nil then
        local exp = dungeonInfo.Experience
        return exp > 0
    else
        return false
    end
end

EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED, Initialize)
