local objectsLib = require('inmation.objects')

local tests = {

    test_ = function()
        assert(objectsLib, "Could not load library")
    end,

    execute = function(self)
        print('Begin objects_tests')
        self:test_()
        print('End objects_tests')
    end
}

return tests