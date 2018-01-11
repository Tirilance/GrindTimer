GrindTimer = {}

GrindTimer.Name = "GrindTimer"
GrindTimer.Version = "1.7.0"
GrindTimer.UIInitialized = false

local ExpEvents = {}
local DungeonRunExpEvents = {}
local DungeonInfo = {}
local ExpEventTimeWindow = 900 -- Remember exp events from the last 15 minutes.
local LastUpdateTimestamp = GetTimeStamp()
local UpdateTimer = 5 -- Update every 5 seconds
local DungeonName = nil

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
    TargetLevel = IsUnitChampion("player") and GetPlayerChampionPointsEarned()+1 or GetUnitLevel("player")+1,
    TargetLevelType = IsUnitChampion("player") and "Champion" or "Normal"
}

-- ExpEvents used to track exp gains.
local function NewExpEvent(timestamp, expGained)
    local expEvent = {}
    expEvent.Timestamp = timestamp
    expEvent.ExpGained = expGained
    
    expEvent.IsExpired = function(self)
        return GetDiffBetweenTimeStamps(GetTimeStamp(), self.Timestamp) > ExpEventTimeWindow
    end
    return expEvent
end

local function CreateExpEvent(timestamp, expGained)
    local newExpEvent = NewExpEvent(timestamp, expGained)
    table.insert(ExpEvents, newExpEvent)

    if DungeonName ~= nil then
        table.insert(DungeonRunExpEvents, newExpEvent)
    end
end

local function ClearExpiredExpEvents()
    for key, expEvent in pairs(ExpEvents) do
        if expEvent:IsExpired() then
            ExpEvents[key] = nil
        end
    end
end

local function ClearDungeonExpEvents()
    for key, expEvent in pairs(DungeonRunExpEvents) do
        DungeonRunExpEvents[key] = nil
    end
end

local function GetTargetLevelExp(level, championPoints, isChamp)
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
    local isChamp = IsUnitChampion("player")
    local level = GetUnitLevel("player")
    local championPoints = GetPlayerChampionPointsEarned()
    local currentExp = isChamp and GetPlayerChampionXP() or GetUnitXP("player")
    local maxExp = isChamp and GetNumChampionXPInChampionPoint(championPoints) or GetUnitXPMax("player")
    local expNeeded = 0

    if GrindTimer.SavedVariables.Mode == "Next" then
        expNeeded = maxExp - currentExp
    else
        expNeeded = GetTargetLevelExp(level, championPoints, isChamp)
    end
    return expNeeded
end

local function GetExpGainPerMinute()
    local totalExpGained = 0
    local firstRememberedEvent = 0
    local count = 0

    for key, expEvent in pairs(ExpEvents) do
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
        -- Normal levels up to 50 in the next hour.
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
        -- Champion levels surpassing level 50 in the next hour.
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

    for key, expEvent in pairs(ExpEvents) do
        totalExpGained = totalExpGained + expEvent.ExpGained
        kills = kills + 1
    end

    local average = totalExpGained / kills
    return average, kills
end

local function GetDungeonRunsNeeded(expNeeded)
    local averagePerRun = DungeonInfo[DungeonName].Average

    if averagePerRun ~= nil then
        local runsNeeded = math.ceil(expNeeded / averagePerRun)

        return runsNeeded
    end
end

local function GetDungeonRunExp()
    local totalExpGained = 0

    for key, expEvent in pairs(DungeonRunExpEvents) do
        totalExpGained = totalExpGained + expEvent.ExpGained
    end

    return totalExpGained
end

local function IncrementDungeonRuns()
    local dungeonInfo = DungeonInfo[DungeonName]    
    local runCount, exp, average = nil

    if dungeonInfo ~= nil then
        runCount = dungeonInfo.RunCount + 1
        exp = dungeonInfo.Experience + GetDungeonRunExp()
        average = exp / runCount
    else
        runCount = 1
        exp = GetDungeonRunExp()
        average = exp
    end

    DungeonInfo[DungeonName] = { Experience = exp, RunCount = runCount, Average = average }
end

-- Formats numbers to include commas every third digit.
local function FormatNumber(num)
    return tostring(math.floor(num)):reverse():gsub("(%d%d%d)","%1,"):gsub(",(%-?)$","%1"):reverse()
end

local function UpdateVars()
    local expNeeded = GetExpNeeded()
    local expGainPerMinute = GetExpGainPerMinute()
    local expGainPerHour = math.floor(expGainPerMinute*60)
    local levelsPerHour = GetLevelsPerHour(expGainPerHour)
    local hours, minutes = GetLevelTimeRemaining(expGainPerMinute, expNeeded)
    local averageExpPerKill, recentKills = GetKillInfo()
    local killsNeeded = math.ceil(expNeeded / averageExpPerKill)

    -- Check for INF / IND
    hours = (hours == math.huge or hours == -math.huge) and 0 or hours
    minutes = (minutes ~= minutes or minutes == math.huge or minutes == -math.huge) and 0 or minutes
    averageExpPerKill = (averageExpPerKill ~= averageExpPerKill) and 0 or averageExpPerKill
    killsNeeded = (killsNeeded ~= killsNeeded) and 0 or killsNeeded
    expGainPerHour = (expGainPerHour ~= expGainPerHour) and 0 or expGainPerHour

    GrindTimer.SavedVariables.TargetHours = hours
    GrindTimer.SavedVariables.TargetMinutes = minutes
    GrindTimer.SavedVariables.TargetExpRemaining = FormatNumber(expNeeded)
    GrindTimer.SavedVariables.RecentKills = FormatNumber(recentKills)
    GrindTimer.SavedVariables.KillsNeeded = FormatNumber(killsNeeded)
    GrindTimer.SavedVariables.ExpPerHour = FormatNumber(expGainPerHour)
    GrindTimer.SavedVariables.LevelsPerHour = FormatNumber(levelsPerHour) 
end

local function Update(eventCode, reason, level, previousExp, currentExp, championPoints)
    local currentTimestamp = GetTimeStamp()
    ClearExpiredExpEvents()

    if reason == 0 or reason == 24 or reason == 26 then
        local expGained = currentExp - previousExp
        CreateExpEvent(currentTimestamp, expGained)
    end

    UpdateVars()
    GrindTimer.UpdateUIControls()
    LastUpdateTimestamp = currentTimestamp
end

local function UpdateDungeonInfo()
    local dungeonRunsNeeded = GetDungeonRunsNeeded(GetExpNeeded())
    
    GrindTimer.SavedVariables.DungeonRunsNeeded = FormatNumber(dungeonRunsNeeded)
    GrindTimer.SavedVariables.LastDungeonName = DungeonName
end

local function PlayerActivated(eventCode, initial)
    if IsUnitInDungeon("player") then
        DungeonName = GetUnitZone("player")
    elseif DungeonName ~= nil then
        IncrementDungeonRuns()
        UpdateDungeonInfo()
        ClearDungeonExpEvents()
        DungeonName = nil        
    end
end

local function Initialize(eventCode, addonName)
    if addonName == GrindTimer.Name then

        GrindTimer.SavedVariables = ZO_SavedVars:New("GrindTimerVars", GrindTimer.Version, "Character", Defaults)
        GrindTimer.AccountSavedVariables = ZO_SavedVars:NewAccountWide("GrindTimerVars", GrindTimer.Version, "Account", AccountDefaults)

        ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_DISPLAY", "Toggle Window")

        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_EXPERIENCE_GAIN, Update)
        EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_PLAYER_ACTIVATED, PlayerActivated)
        EVENT_MANAGER:UnregisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED)

        GrindTimer.InitializeUI()
    end
end

function GrindTimer.Reset()
    local isChamp = IsUnitChampion("player")

    ExpEvents = {}
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

EVENT_MANAGER:RegisterForEvent(GrindTimer.Name, EVENT_ADD_ON_LOADED, Initialize)
