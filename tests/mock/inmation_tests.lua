-- inmation is loaded globaly
assert(inmation, 'inmation mock not loaded')

tests = {
    test_now = function(self)
        local dateNow = inmation.now()
        assert(dateNow ~= nil, "Test_datenow failed; No valid date returned")
    end,

     test_currenttime = function(self)
        local dateNow = inmation.currenttime()
        assert(dateNow ~= nil, "Test_datenow failed; No valid date returned")
    end,

    test_gettimebynumber = function(self)
       -- local dateTime = inmation.gettime(1417506063871)
       -- local expectedResult = '2014-12-02T07:41:03.871Z'
       -- assert(dateTime ~= expectedResult, string.format("test_gettimebynumber failed; Expected '%s' got '%s'", expectedResult, dateTime))
    end,

    test_override = function(self)
        inmation.setOverride('createobject', function (parentPath, modelClass, type)
            return { 
                id = 1,
                parentPath = parentPath,
                modelClass = modelClass,
                type = type
            }
        end)

        local obj = inmation.createobject('/helloworld/', 'Folder', 'OBJ')
        assert(obj.id == 1, "Should recieve object with id = 1")
    end,

    test_get_override = function(self)
        inmation.setOverride('getobject', function (objPath)
            return { 
                id = 999
            }
        end)

        local obj = inmation.getobject('/helloworld/')
        assert(obj.id == 999, "Should recieve object with id = 999")
    end,

    test_getvalue_override = function(self)
        inmation.setOverride('getvalue', function (propPath)
            return 1234
        end)

        local value = inmation.getvalue('/helloworld/')
        assert(value == 1234, "Should receive value 1234")
    end,

    execute = function(self)
        print("Begin inmation_tests")
        self:test_now()
        self:test_currenttime()
        self:test_gettimebynumber()
        self:test_override()
        self:test_get_override()
        self:test_getvalue_override()
        print("End inmation_tests")
    end
}

return tests