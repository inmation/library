local InmationObjMock = {

}

InmationObjMock.__index = InmationObjMock

function InmationObjMock.new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, InmationObjMock)
    return o
end

function InmationObjMock:path()
    return self.pathStr
end

function InmationObjMock:parent()
    return self.parentObj
end

return InmationObjMock