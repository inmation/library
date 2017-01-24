InmationObjMock = {}
InmationObjMock.__index = InmationObjMock

function InmationObjMock:new(inmObjMock)
    inmObjMock = inmObjMock or {}   -- create object if user does not provide one
    setmetatable(inmObjMock, self)
    self.__index = self
    return inmObjMock
end

function InmationObjMock:path()
    return self.pathStr
end

function InmationObjMock:parent()
    return self.parentObj
end

return InmationObjMock