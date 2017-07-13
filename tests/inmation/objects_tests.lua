local objectsLib = require('inmation.objects')

local tests = {

    test_ = function()
        assert(objectsLib, "Could not load library")
    end
}

return tests