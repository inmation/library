local objectLib = require('inmation.object')

tests = {
    test_createScriptLibraryHelper = function(self)
        local objMock = {
            ScriptLibrary = {
                LuaModuleName = {},
                AdvancedLuaScript = {},
                LuaModuleMandatoryExecution = {}
             }
        }
      
        local scriptLibraryHelper = objectLib:scriptLibraryHelper(objMock)

        assert(scriptLibraryHelper, 'Failed to create helper')
    end,

    execute = function(self)
        print('Begin object_tests')
        self:test_createScriptLibraryHelper()
        print('End object_tests')
    end
}

return tests