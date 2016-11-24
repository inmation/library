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

    test_CustomPropertiesHelper_Create = function(self)
        local objMock = {
                CustomOptions ={
                    CustomProperties = {
                    CustomPropertyName = {'testName01'},
                    CustomPropertyValue = {'testValue01'},
                    }
                }
        }
      
        local customPropertiesHelper = objectLib:customPropertiesHelper(objMock)

        assert(customPropertiesHelper.customPropertyList[1].CustomPropertyName == 'testName01', 'Failed to create helper')
    end,

    test_CustomPropertiesHelper_UpsertCustomPropertyItem = function(self)
        local objMock = {
                CustomOptions ={
                    CustomProperties = {
                    CustomPropertyName = {'testName01','testName99'},
                    CustomPropertyValue = {'testValue01', 'testValue99'},
                    }
                }
        }
      
        local customPropertiesHelper = objectLib:customPropertiesHelper(objMock)

        assert(customPropertiesHelper.customPropertyList[1].CustomPropertyName == 'testName01', 'Failed to create helper')

        --create custom property item
        local customPropName = 'testName02'
        local customPropValue = 'testValue02'
        local customPropItem= customPropertiesHelper:createCustomPropertyItem(customPropName, customPropValue)
        assert(customPropItem, 'Failed to create custom property item')

        --append
        customPropertiesHelper:upsertCustomPropertyItem(customPropItem)
        assert(customPropertiesHelper.customPropertyList[3].CustomPropertyName == 'testName02', 'Failed to create custom property')
        assert(customPropertiesHelper.customPropertyList[3].CustomPropertyValue == 'testValue02', 'Failed to create custom property')

        --addedCustomPropertyItems
        local addedCustomPropertyList= customPropertiesHelper:addedCustomPropertyItems()
        assert(#addedCustomPropertyList == 1 and addedCustomPropertyList[1].CustomPropertyName == 'testName02', 'Failed to retrieve added custom property')

        --modify
        local customPropName2Modify = 'testName99'
        local customPropValue2Modify = 'testName99Modified'
        local customPropItem2Modify = customPropertiesHelper:createCustomPropertyItem(customPropName2Modify, customPropValue2Modify)
        customPropertiesHelper:upsertCustomPropertyItem(customPropItem2Modify)
        assert(customPropertiesHelper.customPropertyList[2].CustomPropertyValue == 'testName99Modified', 'Failed to modify custom property')

        --changedCustomPropertyItems
        local changed= customPropertiesHelper:changedCustomPropertyItems()
        assert(#changed == 1 and changed[1].CustomPropertyName == 'testName99', 'Failed to retrieve changed custom property')
    end,

    test_CustomPropertiesHelper_UpsertAdd = function(self)
        local objMock = {
                CustomOptions ={
                    CustomProperties = {
                    CustomPropertyName = {},
                    CustomPropertyValue = {},
                    }
                },

                commit = function()
                    return true
                end
        }
      
        local customPropertiesHelper = objectLib:customPropertiesHelper(objMock)

        local customPropertyList2Add = {
            {
                CustomPropertyName = "TestName01",
                CustomPropertyValue = 0.56484
            },
            {
                CustomPropertyName = "TestName02",
                CustomPropertyValue = 288
            },
            {
                CustomPropertyName = "TestName03",
                CustomPropertyValue = "TestValue03"
            }
        }

        for i, propItem in ipairs(customPropertyList2Add) do 
            customPropertiesHelper:upsertCustomPropertyItem(propItem)
            local addedCustomPropertyList = customPropertiesHelper:addedCustomPropertyItems()
            assert(addedCustomPropertyList ~= nil and #addedCustomPropertyList == i, 'Failed to add custom property')
            assert(addedCustomPropertyList[i].CustomPropertyName == propItem.CustomPropertyName, 'Failed to add custom property')
            assert(addedCustomPropertyList[i].CustomPropertyValue == propItem.CustomPropertyValue, 'Failed to add custom property')
        end
            assert(customPropertiesHelper.dirty == true, 'Dirty flag is incorrect')

            customPropertiesHelper:commit()
    end,

    test_CustomPropertiesHelper_UpsertModify = function(self)
        local objMock = {
                CustomOptions ={
                    CustomProperties = {
                        CustomPropertyName = {"TestName01", "TestName02", "TestName03", "TestName04"},
                        CustomPropertyValue = {0.3, 200, "TestString", "TestValue04"},
                    }
                },

                commit = function()
                    return true
                end
        }
      
        local customPropertiesHelper = objectLib:customPropertiesHelper(objMock)

        local customPropertyList = {
            {
                CustomPropertyName = "TestName01",
                CustomPropertyValue = 0.56484
            },
            {
                CustomPropertyName = "TestName02",
                CustomPropertyValue = 288
            },
            {
                CustomPropertyName = "TestName03",
                CustomPropertyValue = "TestValue03"
            }
        }

        for i, propItem in ipairs(customPropertyList) do 
            customPropertiesHelper:upsertCustomPropertyItem(propItem)
            local changedCustomPropertyList = customPropertiesHelper:changedCustomPropertyItems()
            assert(changedCustomPropertyList ~= nil and #changedCustomPropertyList == i, 'Failed to modify custom property')
            assert(changedCustomPropertyList[i].CustomPropertyName == propItem.CustomPropertyName, 'Failed to modify custom property')
            assert(changedCustomPropertyList[i].CustomPropertyValue == propItem.CustomPropertyValue, 'Failed to modify custom property')
            assert(changedCustomPropertyList[i].oldPropValue == objMock.CustomOptions.CustomProperties.CustomPropertyValue[i], 'Failed to modify custom property')
        end
        assert(customPropertiesHelper.dirty == true, 'Dirty flag is incorrect')

        customPropertiesHelper:commit()

    end,

    execute = function(self)
        print('Begin object_tests')
        self:test_createScriptLibraryHelper()
        self:test_CustomPropertiesHelper_Create()
        self:test_CustomPropertiesHelper_UpsertCustomPropertyItem()
        self:test_CustomPropertiesHelper_UpsertAdd()
        self:test_CustomPropertiesHelper_UpsertModify()
        print('End object_tests')
    end
}

return tests