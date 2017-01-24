
local standardLogic = {}

 function standardLogic.currenttime(localTimezone)
    if localTimezone then
        return os.time()   
    else
        return os.time(os.date("!*t", os.time()))    
    end
end

function standardLogic.gettime(time, format)
    if  nil == format then
        format = "%Y-%m-%d %H:%M:%S"
    end

    if nil == time then
        error('bad argument #1 (string expected, got no value)')
    end

    if type(time) == 'number' then
        return os.date(format, time)
    else if type(time) == 'string' then
            assert(false, 'Not implemented')
        end
    end
end

function standardLogic.gettimeparts(time)
    local timeStr = standardLogic.gettime(time, "%Y-%m-%dT%H:%M:%S+01:00")
    local inYear, inMonth, inDay, inHour, inMinute, inSecond, inZone = string.match(timeStr, '^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)(.-)$')
    return inYear, inMonth, inDay, inHour, inMinute, inSecond, inZone
end

function standardLogic.now()
    return standardLogic.currenttime()
end

function standardLogic.getself()
    return inmation
end

local overrides = {}

inmation = {}

setmetatable(inmation, {__index = function(self, name)
    print(name)
    -- First used overwritten implementation
    if nil ~= overrides[name] then
        return overrides[name]
    end
    -- Second use standard implementation
    if nil ~= standardLogic[name] then
        return standardLogic[name]
    end
    assert(nil, string.format("Method '%s' not implemented, make use of method 'inmation.setOverride(name, closure)' to add a custom implementation.", name))
end})

inmation.setOverride = function(name, closure)
    overrides[name] = closure
end

inmation.clearOverrides = function()
    overrides = {}
end

return inmation