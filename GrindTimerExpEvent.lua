GrindTimerExpEvent = { Timestamp = 0; ExpGained = 0; Reason = 0 }

function GrindTimerExpEvent:New(time, exp, reason)
    local object = {}
    setmetatable({}, ExpEvent)

    object.Timestamp = time
    object.ExpGained = exp
    object.Reason = reason

    object.IsExpired = function(self)
        return GetDiffBetweenTimeStamps(GetTimeStamp(), self.Timestamp) > GrindTimer.RecentEventTimeWindow
    end
    return object
end