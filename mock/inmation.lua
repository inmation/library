
inmation = {

}

 -- Parent can be a parent object or the parent path string.
 function inmation.createobject(parent, objectName)
    assert(nil, 'createobject not implemented')
end

 function inmation.currenttime(localTimezone)
    if localTimezone then
        return os.time()   
    else
        return os.time(os.date("!*t", os.time()))    
    end
end

function inmation.getobject(path)
    assert(nil, 'getobject not implemented')
end

function inmation.gettime(time, format)
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

function inmation.gettimeparts(time)
    local timeStr = inmation.gettime(time, "%Y-%m-%dT%H:%M:%S+01:00")
    local inYear, inMonth, inDay, inHour, inMinute, inSecond, inZone = string.match(timeStr, '^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)(.-)$')
    return inYear, inMonth, inDay, inHour, inMinute, inSecond, inZone
end

function inmation.now()
    return inmation.currenttime()
end

return inmation