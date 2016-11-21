local objectsLib = require('inmation.objects')

tests = {

    test_ = function(self)

    end,

    execute = function(self)
        print('Begin objects_tests')
        self:test_()
        print('End objects_tests')
    end
}

return tests