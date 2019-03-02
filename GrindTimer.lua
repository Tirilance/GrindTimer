GrindTimer = {}

GrindTimer.Name = "GrindTimer"
GrindTimer.Version = "1.9.6"
GrindTimer.SavedVariableVersion = "1"
GrindTimer.AccountSavedVariablesVersion = "1"
GrindTimer.UIInitialized = false

local DungeonInfo = {}
local LastUpdateTimestamp = GetTimeStamp()
local UpdateTimer = 5 -- Update every 5 seconds
local DungeonName = nil
local IsPlayerInDungeon = false
local IsPlayerInDolmen = false

local AccountDefaults =
{
    Opacity = 1,
    OutlineText = false,
    TextColor = { 0.65, 0.65, 0.65 },
    Locked = false,
    OffsetX = 400,
    OffsetY = 100,
    FirstLabelType = 1,
    SecondLabelType = 2,
    SecondLabelEnabled = true
}

local Defaults =
{
    Mode = "Next",
    TargetHours = 0,
    TargetMinutes = 0,
    TargetExpRemaining = IsUnitChampion("player") and GetNumChampionXPInChampionPoint(GetPlayerChampionPointsEarned()) - GetPlayerChampionXP() or GetUnitXPMax("player") - GetUnitXP("player"),
    KillsNeeded = 0,
    LevelsPerHour = 0,
    ExpPerHour = 0,
    RecentKills = 0,
    LastDungeonName = nil,
    DungeonRunsNeeded = 0,
    DolmensNeeded = 0,
    TargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1,
    TargetLevelType = IsUnitChampion("player") and "Champion" or "Normal",
    IsPlayerChampion = IsUnitChampion("player")
}

-- ExpEvents used to track exp gains.
local ExpEvent = { EventCount = 0, Events = {}, Timeout = 900 }

function ExpEvent.Create(timestamp, expGained, isDungeon, isDolmen, reason)
    local newExpEvent = {}

    newExpEvent.Timestamp = timestamp
    newExpEvent.ExpGained = expGained
    newExpEvent.IsDungeon = isDungeon
    newExpEvent.IsDolmen = isDolmen

    if reason == 0 or reason == 24 or reason == 26 then
        newExpEvent.Reason = "Kill"
    elseif reason == 7 then
        newExpEvent.Reason = "DolmenClosed"
    else
        newExpEvent.Reason = "Other"
    end
    
    newExpEvent.IsExpired = function(self)
        return GetDiffBetweenTimeStamps(GetTimeStamp(), self.Timestamp) > ExpEvent.Timeout
    end

    table.insert(ExpEvent.Events, newExpEvent)
    ExpEvent.EventCount = ExpEvent.EventCount + 1

    return newExpEvent
end

local function ClearExpiredExpEvents()
    for key, expEvent in pairs(ExpEvent.Events) do
        if expEvent:IsExpired() then
            ExpEvent.Events[key] = nil
            ExpEvent.EventCount = ExpEvent.EventCount - 1
        end
    end
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

local function GetExpNeeded()
    local isChamp = GrindTimer.SavedVariables.IsPlayerChampion
    local championPoints = GetPlayerChampionPointsEarned()
    local currentExp = isChamp and GetPlayerChampionXP() or GetUnitXP("player")
    local maxExp = isChamp and GetNumChampionXPInChampionPoint(championPoints) or GetUnitXPMax("player")
    local expNeeded = 0

    if GrindTimer.SavedVariables.Mode == "Next" then
        expNeeded = maxExp - currentExp
    else
        expNeeded = GetTargetLevelExp(championPoints, isChamp)
    end
    return expNeeded
end

local function GetExpGainPerMinute()
    local totalExpGained = 0
    local firstRememberedEvent = 0
    local count = 0

    for key, expEvent in pairs(ExpEvent.Events) do
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
        for i = championPoints, championPoints+1000 do
            local expInLevel = GetNumChampionXPInChampionPoint(i)
            if i == championPoints then
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
        -- Normal levels up to 50 in the next hour.
        for i = playerLevel, 49 do
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
        -- Champion levels surpassing level 50 in the next hour.
        if expGainPerHour >= 0 then
            for i = championPoints, championPoints+1000 do
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
        minutesToLevel = rawMinutesToLevel - math.floor(rawMinutesToLevel/60) * 60
    else
        minutesToLevel = rawMinutesToLevel
    end

    return hoursToLevel, minutesToLevel
end

-- Returns average kill exp and number of kills in last 15 minutes
local function GetKillInfo()
    local totalExpGained = 0
    local kills = 0

    for key, expEvent in pairs(ExpEvent.Events) do
        if expEvent.Reason == "Kill" then
            totalExpGained = totalExpGained + expEvent.ExpGained
            kills = kills + 1
        end
    end

    local average = totalExpGained / kills
    return average, kills
end

local function GetDolmensNeeded(expNeeded)
    local totalExpGained = 0
    local totalDolmensClosed = 0

    for key, expEvent in pairs(ExpEvent.Events) do
        if expEvent.IsDolmen then
            totalExpGained = totalExpGained + expEvent.ExpGained

            if expEvent.Reason == "DolmenClosed" then
                totalDolmensClosed = totalDolmensClosed + 1
            end
        end
    end

    local averageDolmenExp = totalExpGained / totalDolmensClosed
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
    local runCount, exp, average = nil    

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

-- Formats numbers to include separators every third digit.
local function FormatNumber(num)
    return zo_strformat("<<1>>", ZO_LocalizeDecimalNumber(num))
end

local function UpdateVars()
    GrindTimer.SavedVariables.IsPlayerChampion = IsUnitChampion("player")

    local expNeeded = GetExpNeeded()
    local expGainPerMinute = GetExpGainPerMinute()
    local expGainPerHour = math.floor(expGainPerMinute*60)
    local levelsPerHour = GetLevelsPerHour(expGainPerHour)
    local hours, minutes = GetLevelTimeRemaining(expGainPerMinute, expNeeded)
    local averageExpPerKill, recentKills = GetKillInfo()
    local killsNeeded = math.ceil(expNeeded / averageExpPerKill)
    local dolmensNeeded = GetDolmensNeeded(expNeeded)

    -- Check for INF / IND
    hours = (hours == math.huge or hours == -math.huge) and 0 or hours
    minutes = (minutes ~= minutes or minutes == math.huge or minutes == -math.huge) and 0 or minutes
    averageExpPerKill = (averageExpPerKill ~= averageExpPerKill) and 0 or averageExpPerKill
    killsNeeded = (killsNeeded ~= killsNeeded) and 0 or killsNeeded
    expGainPerHour = (expGainPerHour ~= expGainPerHour) and 0 or expGainPerHour
    dolmensNeeded = (dolmensNeeded == math.huge or dolmensNeeded ~= dolmensNeeded) and 0 or dolmensNeeded

    GrindTimer.SavedVariables.TargetHours = hours
    GrindTimer.SavedVariables.TargetMinutes = minutes
    GrindTimer.SavedVariables.TargetExpRemaining = FormatNumber(expNeeded)
    GrindTimer.SavedVariables.RecentKills = FormatNumber(recentKills)
    GrindTimer.SavedVariables.KillsNeeded = FormatNumber(killsNeeded)
    GrindTimer.SavedVariables.ExpPerHour = FormatNumber(expGainPerHour)
    GrindTimer.SavedVariables.LevelsPerHour = FormatNumber(levelsPerHour)
    GrindTimer.SavedVariables.DolmensNeeded = FormatNumber(dolmensNeeded)
end

local function Update(eventCode, reason, level, previousExp, currentExp, championPoints)
    local currentTimestamp = GetTimeStamp()
    ClearExpiredExpEvents()

    if reason == 0 or reason == 24 or reason == 26 or reason == 7 and IsPlayerInDolmen then
        local currentPlayerLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned() or GetUnitLevel("player")

        if GrindTimer.SavedVariables.TargetLevel == currentPlayerLevel then
            GrindTimer.SetNewTargetLevel(currentPlayerLevel+1)
        end

        local expGained = currentExp - previousExp
        
        ExpEvent.Create(currentTimestamp, expGained, IsPlayerInDungeon, IsPlayerInDolmen, reason)
    end

    UpdateVars()
    GrindTimer.UpdateUIControls()
    LastUpdateTimestamp = currentTimestamp
end

local function UpdateDungeonInfo()
    local dungeonRunsNeeded = GetDungeonRunsNeeded(GetExpNeeded())

    if dungeonRunsNeeded ~= nil then
        -- Check for INF
        dungeonRunsNeeded = (dungeonRunsNeeded == math.huge or dungeonRunsNeeded == -math.huge) and 0 or dungeonRunsNeeded
        
        GrindTimer.SavedVariables.DungeonRunsNeeded = FormatNumber(dungeonRunsNeeded)
        GrindTimer.SavedVariables.LastDungeonName = DungeonName
    end
end

local function PlayerActivated(eventCode, initial)
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

local function Initialize(eventCode, addonName)
    if addonName == GrindTimer.Name then

        GrindTimer.SavedVariables = ZO_SavedVars:New("GrindTimerVars", GrindTimer.SavedVariableVersion, "Character", Defaults)
        GrindTimer.AccountSavedVariables = ZO_SavedVars:NewAccountWide("GrindTimerVars", GrindTimer.AccountSavedVariablesVersion, "Account", AccountDefaults)

        ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DISPLAY", "Toggle Window")

        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_EXPERIENCE_GAIN, Update)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ZONE_CHANGED, ZoneChanged)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
        EVENT_MANAGER:UnregisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED)

        GrindTimer.InitializeUI()
    end
end

function GrindTimer.Reset()
    local isChamp = IsUnitChampion("player")

    ExpEvent.Events = {}
    ExpEvent.EventCount = 0

    GrindTimer.SavedVariables.Mode = "Next"
    GrindTimer.SavedVariables.TargetLevel = isChamp and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1
    GrindTimer.SavedVariables.TargetLevelType = isChamp and "Champion" or "Normal"
    GrindTimer.SavedVariables.TargetHours = 0
    GrindTimer.SavedVariables.TargetMinutes = 0
    GrindTimer.SavedVariables.KillsNeeded = 0
    GrindTimer.SavedVariables.LevelsPerHour = 0
    GrindTimer.SavedVariables.ExpPerHour = 0
    GrindTimer.SavedVariables.RecentKills = 0
    GrindTimer.SavedVariables.TargetExpRemaining = FormatNumber(GetExpNeeded())
    GrindTimer.SavedVariables.LastDungeonName = nil
    GrindTimer.SavedVariables.DungeonRunsNeeded = 0
    GrindTimer.SavedVariables.DolmensNeeded = 0
    GrindTimer.SavedVariables.IsPlayerChampion = isChamp
end

-- Updates Grind Timer every 5 seconds if no exp is gained within those 5 seconds.
function GrindTimer.TimedUpdate()
    if GrindTimer.UIInitialized then
        local currentTimestamp = GetTimeStamp()

        if GetDiffBetweenTimeStamps(currentTimestamp, LastUpdateTimestamp) >= UpdateTimer then
            ClearExpiredExpEvents()
            UpdateVars()
            GrindTimer.UpdateUIControls()
            LastUpdateTimestamp = currentTimestamp
        end
    end
end

function GrindTimer.SetNewTargetLevel(targetLevel)
    GrindTimer.SavedVariables.TargetLevel = targetLevel
    UpdateVars()
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
