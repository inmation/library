-- inmation.object
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20161103.1   Initial release.
--
require('inmation.table-extension')
require('inmation.string-extension')

-- Proxy trace functions to optional traceAgent.
local tracer = setmetatable({}, {
  __index = function(self, method)
    if traceAgent then
        return function(self, msg, timespan) 
            if type(traceAgent[method]) == 'function' then
                return traceAgent[method](traceAgent, msg, timespan)
            end
        end
    end
    -- Return empty function when traceAgent is not loaded.
    return function() end
  end
})

local scriptLibraryHelper = function(inmObj)

    local result = {
        inmObj = inmObj,

        -- dirty flag whichs indicates an item is added or modified
        dirty = false,

        ----------------------------------------------------------------------------
        -- Assigns the script items changes to the inmation object and commits the object changes.
        -- @param onlyAssign Indicates the item changes should only be assigned to the inmation object. 
            -- The object changes will not be committed to the system.
        -- @return nil       
        ----------------------------------------------------------------------------
        commit = function(self, onlyAssign)
            local scriptLibrary = self.inmObj.ScriptLibrary
            -- Fetch all names from script list.
            scriptLibrary.LuaModuleName = table.imap(self.scriptList, function(scriptItem)
                return scriptItem.LuaModuleName
            end)

            -- Fetch all script bodies from script list.
            scriptLibrary.AdvancedLuaScript = table.imap(self.scriptList, function(scriptItem)
                return scriptItem.AdvancedLuaScript
            end)

            -- Fetch all execution flags from script list.
            scriptLibrary.LuaModuleMandatoryExecution = table.imap(self.scriptList, function(scriptItem)
                return scriptItem.LuaModuleMandatoryExecution
            end)

            -- In case of a larger transaction hold the inmation commit.
            if not onlyAssign then
                self.inmObj:commit()
            end
        end,

        ----------------------------------------------------------------------------
        -- Resets the in memory scriptList which contains the script items.
        -- @return nil       
        ----------------------------------------------------------------------------
        reset = function(self)
            local scriptList = {}
            local originalScriptList = {}

            local scriptLibrary = self.inmObj.ScriptLibrary
            for i, moduleName in ipairs(scriptLibrary.LuaModuleName) do
                local scriptItem = {
                    LuaModuleName = scriptLibrary.LuaModuleName[i],
                    AdvancedLuaScript = scriptLibrary.AdvancedLuaScript[i],
                    LuaModuleMandatoryExecution = scriptLibrary.LuaModuleMandatoryExecution[i]
                }
                table.insert(scriptList, scriptItem)
                table.insert(originalScriptList, scriptItem)
             end
            self.scriptList = scriptList
            self.originalScriptList = scriptList
        end,

        addedScriptItems = function(self)
            local addedScriptItems = {}
            for i, scriptItem in ipairs(self.scriptList) do
                local matchScriptItem = table.ifind(self.originalScriptList, function(originalScriptItem) 
                    return scriptItem.LuaModuleName == originalScriptItem.LuaModuleName
                end)

              if matchScriptItem == nil then
                table.insert(addedScriptItems, scriptItem)
              end
            end
            return addedScriptItems
        end,

        changedScriptItems = function(self)
            local changedScriptItems = {}
            for i, scriptItem in ipairs(self.scriptList) do
              if scriptItem.oldAdvancedLuaScript ~= nil or scriptItem.oldLuaModuleMandatoryExecution ~= nil then
                table.insert( changedScriptItems, scriptItem)
              end
            end
            return changedScriptItems
        end,
        ----------------------------------------------------------------------------
        -- Clears the in memory scriptList which contains the script items.
        -- @return nil       
        ----------------------------------------------------------------------------
        clear = function(self)
           self.scriptList = {}
           dirty = false
        end,

        ----------------------------------------------------------------------------
        -- Creates a script items.
        -- @param LuaModuleName The module name for the script item
        -- @param AdvancedLuaScript The script body value for the script item
        -- @param LuaModuleMandatoryExecution The mandatory execution flag for the script item
        -- @return nil       
        ----------------------------------------------------------------------------
        createScriptItem = function(self, LuaModuleName, AdvancedLuaScript, LuaModuleMandatoryExecution)
            return {
                LuaModuleName = LuaModuleName,
                AdvancedLuaScript = AdvancedLuaScript,
                LuaModuleMandatoryExecution = LuaModuleMandatoryExecution
            }
        end,
        
        ----------------------------------------------------------------------------
        -- Adds a script item in the scriptLibrary of an object.
        -- @param inmObj Object which contains the scriptLibrary to extend.
        -- @param scriptItem Table which contain the script properties. This table must contain the properties 'moduleName' and 'AdvancedLuaScript'.
                -- The property 'LuaModuleMandatoryExecution' is optional. If not provided the default value 'false' will be used.
        -- @return nil when the script item is added successfully. In case of an error an error message will be returned.        
        ----------------------------------------------------------------------------
        appendScriptItem = function(self, scriptItem)
            if type(scriptItem.LuaModuleName) ~= 'string' or #scriptItem.LuaModuleName == 0 then
                return 'Module name is null or empty'
            end

            if type(scriptItem.AdvancedLuaScript) ~= 'string' or #scriptItem.AdvancedLuaScript == 0 then
                return 'Script body is null or empty'
            end

            local matchScriptItem = table.ifind(self.scriptList, function(storedScriptItem) 
                return scriptItem.LuaModuleName == storedScriptItem.LuaModuleName
            end)
            if matchScriptItem then
                return 'Does already contain a script with module name ' .. scriptItem.LuaModuleName
            end

            table.insert(self.scriptList, scriptItem)
            self.dirty = true
        end,

        ----------------------------------------------------------------------------
        -- Adds a script item in the scriptLibrary of an object.
        -- @param inmObj Object which contains the scriptLibrary to extend.
        -- @param scriptItem Table which contain the script properties. This table must contain the properties 'moduleName' and 'AdvancedLuaScript'.
                -- The property 'LuaModuleMandatoryExecution' is optional. If not provided the default value 'false' will be used.
        -- @return nil when the script item is modified successfully. In case of an error an error message will be returned.        
        ----------------------------------------------------------------------------
        modifyScriptItem = function(self, scriptItem)
            local matchScriptItem = table.ifind(self.scriptList, function(storedScriptItem) 
                return scriptItem.LuaModuleName == storedScriptItem.LuaModuleName
            end)
            if nil == matchScriptItem then
                return 'Does not contain a script with module name ' .. scriptItem.LuaModuleName
            end

            -- Update properties.
            if scriptItem.AdvancedLuaScript and type(scriptItem.AdvancedLuaScript) == 'string' and matchScriptItem.AdvancedLuaScript ~= scriptItem.AdvancedLuaScript then
                if matchScriptItem.oldAdvancedLuaScript == nil then
                     matchScriptItem.oldAdvancedLuaScript = matchScriptItem.AdvancedLuaScript
                end
                matchScriptItem.AdvancedLuaScript = scriptItem.AdvancedLuaScript
                self.dirty = true
            end

            if scriptItem.LuaModuleMandatoryExecution and type(scriptItem.LuaModuleMandatoryExecution) == 'boolean' and matchScriptItem.LuaModuleMandatoryExecution ~= scriptItem.LuaModuleMandatoryExecution  then
                if matchScriptItem.oldLuaModuleMandatoryExecution == nil then
                     matchScriptItem.oldLuaModuleMandatoryExecution = matchScriptItem.LuaModuleMandatoryExecution
                     error('LuaModuleMandatoryExecution changed')
                end
                matchScriptItem.LuaModuleMandatoryExecution = scriptItem.LuaModuleMandatoryExecution
                self.dirty = true
            end  
        end,
        
        ----------------------------------------------------------------------------
        -- Updates or adds a script item in the scriptLibrary of an object.
        -- @param inmObj Object which contains the scriptLibrary to modify or insert.
        -- @param scriptItem Table which contain the script properties. This table must contain the properties 'moduleName' and 'AdvancedLuaScript'.
                -- The property 'LuaModuleMandatoryExecution' is optional. If not provided the default value 'false' will be used.
        -- @return nil in case the upsert is succesfull. In case of an error an error message will be returned.
        ----------------------------------------------------------------------------
        upsertScriptItem = function (self, scriptItem)
             local matchScriptItem = table.ifind(self.scriptList, function(storedScriptItem) 
                return scriptItem.LuaModuleName == storedScriptItem.LuaModuleName
            end)
            if matchScriptItem then
                return self:modifyScriptItem(scriptItem)    
            else
                return self:appendScriptItem(scriptItem)   
            end     
        end
    }

    result:reset();
    return result
end

local customPropertiesHelper = function(inmObj)

    local result = {
        inmObj = inmObj,

      -- dirty flag whichs indicates an item is added or modified
        dirty = false,

        ----------------------------------------------------------------------------
        -- Assigns the custom property changes to the inmation object and commits the object changes.
        -- @param onlyAssign Indicates the item changes should only be assigned to the inmation object. 
            -- The object changes will not be committed to the system.
        -- @return nil       
        ----------------------------------------------------------------------------
        commit = function(self, onlyAssign)
            local customProperties = self.inmObj.CustomOptions.CustomProperties
            -- Fetch all names from custom property list.
            customProperties.CustomPropertyName = table.imap(self.customPropertyList, function(propItem)
                return propItem.CustomPropertyName
            end)

            -- Fetch all property values from custom property list.
            customProperties.CustomPropertyValue = table.imap(self.customPropertyList, function(propItem)
                return propItem.CustomPropertyValue
            end)

            -- In case of a larger transaction hold the inmation commit.
            if not onlyAssign then
                self.inmObj:commit()
            end
        end,

        ----------------------------------------------------------------------------
        -- Resets the in memory customPropertyList which contains the propertyItems items.
        -- @return nil       
        ----------------------------------------------------------------------------
        reset = function(self)
            local customPropertyList = {}
            local originalCustomPropertyList = {}
            local objCustomProperties = self.inmObj.CustomOptions.CustomProperties
            for i, propName in ipairs(objCustomProperties.CustomPropertyName) do
                local propItem = {
                    CustomPropertyName = objCustomProperties.CustomPropertyName[i],
                    CustomPropertyValue = objCustomProperties.CustomPropertyValue[i]
                }

                table.insert(customPropertyList, propItem)
                table.insert(originalCustomPropertyList, propItem)
             end
            self.customPropertyList = customPropertyList
            self.originalCustomPropertyList = originalCustomPropertyList
        end,

        addedCustomPropertyItems = function(self)
            local addedPropertyItems = {}
            for i, propItem in ipairs(self.customPropertyList) do
                local matchPropertyItem = table.ifind(self.originalCustomPropertyList, function(originalPropItem) 
                    return propItem.CustomPropertyName == originalPropItem.CustomPropertyName
                end)

              if matchPropertyItem == nil then
                table.insert(addedPropertyItems, propItem)
              end
            end
            return addedPropertyItems
        end,

        changedCustomPropertyItems = function(self)
            local changedPropertyItems = {}
            for i, propItem in ipairs(self.customPropertyList) do
              if propItem.oldPropValue ~= nil then
                table.insert(changedPropertyItems, propItem)
              end
            end
            return changedPropertyItems
        end,

        ----------------------------------------------------------------------------
        -- Clears the in memory custom property list which contains the property items.
        -- @return nil       
        ----------------------------------------------------------------------------
        clear = function(self)
           self.customPropertyList = {}
            dirty = false
        end,

        ----------------------------------------------------------------------------
        -- Creates a custom property item.
        -- @param CustomPropertyName The name for the property item
        -- @param CustomPropertyValue The value for the property item
        -- @return nil       
        ----------------------------------------------------------------------------
        createCustomPropertyItem = function(self, CustomPropertyName, CustomPropertyValue)
            return {
                CustomPropertyName = CustomPropertyName,
                CustomPropertyValue = CustomPropertyValue
            }
        end,
        
        ----------------------------------------------------------------------------
        -- Adds a property item in CustomProperties of an object.
        -- @param inmObj Object which contains the CustomProperties to extend.
        -- @param propertyItem Table which contain the custom properties. This table must contain the properties 'CustomPropertyName' and 'CustomPropertyValue'.
        -- @return nil when the property item is added successfully. In case of an error an error message will be returned.        
        ----------------------------------------------------------------------------
        appendCustomPropertyItem = function(self, customPropertyItem)
            if type(customPropertyItem.CustomPropertyName) ~= 'string' or #customPropertyItem.CustomPropertyName == 0 then
                return 'Name is null or empty'
            end

            if customPropertyItem.CustomPropertyValue == nil then
                return 'Value is null'
            end

            local matchPropItem = table.ifind(self.customPropertyList, function(storedPropItem) 
                return customPropertyItem.CustomPropertyName == storedPropItem.CustomPropertyName
            end)
            if matchPropItem then
                return 'Does already contain a property with name ' .. customPropertyItem.CustomPropertyName
            end

            table.insert(self.customPropertyList, customPropertyItem)
            self.dirty = true
        end,

        ----------------------------------------------------------------------------
        -- Modifies a custom property item in CustomProperties of an object.
        -- @param inmObj Object which contains the CustomProperties to extend.
        -- @param customPropertyItem Table which contain the custom property properties. This table must contain the properties 'CustomPropertyName' and 'CustomPropertyValue'.
        -- @return nil when the Custom property item is modified successfully. In case of an error an error message will be returned.        
        ----------------------------------------------------------------------------
        modifyCustomPropertyItem = function(self, customPropertyItem)
            local matchPropertyItem = table.ifind(self.customPropertyList, function(storedPropItem) 
                return customPropertyItem.CustomPropertyName == storedPropItem.CustomPropertyName
            end)
            if nil == matchPropertyItem then
                return 'Does not contain a property with name ' .. customPropertyItem.CustomPropertyName
            end
            
            if customPropertyItem.CustomPropertyValue and matchPropertyItem.CustomPropertyValue ~= customPropertyItem.CustomPropertyValue then
                if matchPropertyItem.oldPropValue == nil then
                     matchPropertyItem.oldPropValue = matchPropertyItem.CustomPropertyValue
                end
                matchPropertyItem.CustomPropertyValue = customPropertyItem.CustomPropertyValue
                self.dirty = true
            end
        end,
        
        ----------------------------------------------------------------------------
        -- Updates or adds a property item in the CustomProperties of an object.
        -- @param inmObj Object which contains the CustomProperties to modify or insert.
        -- @param customPropertyItem Table which contain the custom property properties. This table must contain the properties 'CustomPropertyName' and 'CustomPropertyValue'.
        -- @return nil in case the upsert is succesfull. In case of an error an error message will be returned.
        ----------------------------------------------------------------------------
        upsertCustomPropertyItem = function (self, customPropertyItem)
             local matchPropertyItem = table.ifind(self.customPropertyList, function(storedPropItem) 
                return customPropertyItem.CustomPropertyName == storedPropItem.CustomPropertyName
            end)
            if matchPropertyItem then
                return self:modifyCustomPropertyItem(customPropertyItem)    
            else
                return self:appendCustomPropertyItem(customPropertyItem)   
            end     
        end
    }

    result:reset();
    return result
end

objectLib = {

    ----------------------------------------------------------------------------
    -- Creates a script library helper object which can be used to perform script item changes.
    -- @param inmObj Object which contains the scriptLibrary to modify or extend.
    -- @return scriptLibraryHelper library object.
    ----------------------------------------------------------------------------
    scriptLibraryHelper = function(self, obj)
        tracer:traceVerbose('Creating scriptLibraryHelper')
        result = scriptLibraryHelper(obj)
        return result
    end,

    ----------------------------------------------------------------------------
    -- Creates a custom properties helper object which can be used to perform custom property item changes.
    -- @param inmObj Object which contains the CustomProperties to modify or extend.
    -- @return customPropertiesHelper object.
    ----------------------------------------------------------------------------
    customPropertiesHelper = function(self, obj)
        tracer:traceVerbose('Creating customPropertiesHelper')
        result = customPropertiesHelper(obj)
        return result
    end,

    ----------------------------------------------------------------------------
    -- Gets the property of an object by property path.
    -- @param inmObj Object which contains the property to retrieve.
    -- @return First return value contains the object property. 
        --When the property path cannot be resolved the first return value is nil, the second return value contains an error message.
    ----------------------------------------------------------------------------
    propertyValueByPath = function(self, inmObj, propertyPath)
        local err = nil
        local propNameList = propertyPath:split('.')

        local propItem = inmObj
        tracer:traceVerbose(string.format("propertyValueByPath; object '%s' propertyPath '%s'", inmObj.ObjectName, propertyPath))
        for i, propName in ipairs(propNameList) do
            propItem = propItem[propName]
            
            if propItem == nil then 
                return nil, string.format("Incorrect property path in '%s'; property '%s' does not exist.", propertyPath, propName)
            end
        end
        return propItem, nil      
    end,

    propertyCompoundByPath = function(self, inmObj, propertyPath)
       local propNameList = propertyPath:split('.')

       local propCompoundItem = inmObj
       local lastIndex = #propNameList
       for i, propName in ipairs(propNameList) do
            local accessProperty = function(propertyName)
                return propCompoundItem[propName]
            end
            -- Access property by suppressing the error when it doesn't exit.
           local succeeded, compoundItem = pcall(accessProperty, propName)
            if succeeded then propCompoundItem = compoundItem else propCompoundItem = nil end
           if propCompoundItem == nil then 
               return nil, nil, string.format("Incorrect property path in '%s'; property '%s' does not exist.", propertyPath, propName)
           end
           
           if i == lastIndex -1 then   
               local assignablePropName = propNameList[lastIndex]
               return propCompoundItem, assignablePropName
           end
       end
   end,

    modifyProperty = function(self, inmObj, propName, propValue, onlyAssign)
        local propItem, err = self:propertyValueByPath(inmObj, propName)
        if propItem == nil then
            error(err or "Item nil returned by propertyByPath.")
        end

        local objPointer = inmObj
        local err = nil
        -- If property contains a dot it is a path to a compound property.
        if propName:match('[.]') then
            objPointer, propName, err = self:propertyCompoundByPath(inmObj, propName)
        end

        if objPointer[propName] ~= propValue then
            objPointer[propName] = propValue
            tracer:traceInfo(string.format("Object '%s'; Changed value of property '%s' from '%s' to '%s'.", inmObj:path(), propName, objPointer[propName], propValue))
            if not onlyAssign then
                inmObj:commit()
            end
            return true
        end
        return false
    end,

    modifyProperties = function(self, inmObj, propertyList, onlyAssign)
		if type(propertyList) ~= "table" then return nil, 'PropertyList has to be a table.' end

        if inmObj == nil then
            return
        end
        tracer:traceInfo(string.format("modifyProperties for obj '%s'", inmObj:path()))
        -- List with { propertyName = {} }
        local propertyIgnoreList = {}

        -- Check path.
        if propertyList.Path then
            assert(inmObj:path() == propertyList.Path, string.format("Object path mismatch; '%s' != '%s'", inmObj:path(), propertyList.Path))
            propertyIgnoreList.Path = {}
        end

        -- Check object type.
        if propertyList.Type then
            assert(inmObj:type() == propertyList.Type, string.format("Object type mismatch; '%s' != '%s'", inmObj:type(), propertyList.Type))
            propertyIgnoreList.Type = {}
        end

        -- Check object ServerType property.
        if propertyList.ServerType ~= nil then
        --     TODO: At the moment it is not possible to test ServerType since it returns a number (enum) instead of a string.
        --     assert(inmObj.ServerType == propertyList.ServerType, string.format("Object ServerType mismatch; '%s' != '%s'", inmObj.ServerType, propertyList.ServerType))
            propertyIgnoreList.ServerType = {}
        end 

        local isInmObjModified = false
        if propertyList.ScriptLibrary then 
            propertyIgnoreList.ScriptLibrary = {}
            local scriptLibraryHelper = self:scriptLibraryHelper(inmObj)
            if propertyList.ScriptLibrary.explicit == true then
                scriptLibraryHelper:clear()	
            end

            for i, scriptListItem in ipairs(propertyList.ScriptLibrary) do
                scriptLibraryHelper:upsertScriptItem(scriptItem)    
            end
            
            local changed = scriptLibraryHelper:changedScriptItems()
            local added = scriptLibraryHelper:addedScriptItems()
             tracer:traceVerbose(string.format("Object %s; modify script library: '%d' items changed, '%d' items added", inmObj:path(), #changed, #added))
            if scriptLibraryHelper.dirty then
                tracer:traceInfo(string.format("scriptLibraryHelper for '%s' committing...", inmObj:path()))
                scriptLibraryHelper:commit(true)
                isInmObjModified = true
            end
        end

        if propertyList.CustomProperties then 
            propertyIgnoreList.CustomProperties = {} 
            local customPropertiesHelper = self:customPropertiesHelper(inmObj)
            for i, customPropItem in ipairs(propertyList.CustomProperties) do
                tracer:traceVerbose(string.format("Object %s; modify custom property '%s'.", inmObj:path(), customPropItem.CustomPropertyName))
                customPropertiesHelper:upsertCustomPropertyItem(customPropItem)
            end

            local changed = customPropertiesHelper:changedCustomPropertyItems()
            local added = customPropertiesHelper:addedCustomPropertyItems()
            tracer:traceVerbose(string.format("Object %s; modify custom property: '%d' items changed, '%d' items added", inmObj:path(), #changed, #added))
            if customPropertiesHelper.dirty then
                tracer:traceInfo(string.format("customPropertiesHelper for '%s' committing...", inmObj:path()))
                customPropertiesHelper:commit(true)
                isInmObjModified = true
            end
        end

        -- Linkprocessvalue for generic kpi items
        if propertyList.processValue then
            propertyIgnoreList.processValue = {} 
            -- Check wether the object exist in the IOModel
            local pvObj = inmation.getobject(propertyList.processValue)
            if  pvObj ~= nil then
                inmation.linkprocessvalue(propertyList.Path, propertyList.processValue)
            else
                tracer:traceError(string.format("Failed to link processvalue for generic kpi item %s; Object with path '%s' does not exist in the IOModel.", propertyList.Path, propertyList.processValue))
            end
        end

        -- refs
        if propertyList.refs then
            -- Check wether all reference paths exists. If not ignore the refs property and trace an error.
            for i, ref in ipairs(propertyList.refs) do
                local refObj = inmation.getobject(ref.path)
                if  refObj == nil then
                    propertyIgnoreList.refs = {} 
                    tracer:traceError(string.format("Failed to reference object with path '%s'; Object does not exist.", ref.path))
                end
            end
        end

        -- Iterate through the remaining properties.
        for propName, propValue in pairs(propertyList) do
            if nil == propertyIgnoreList[propName] then
                tracer:traceInfo(string.format("modifyProperties for obj '%s', property '%s'", inmObj:path(), propName))
                if (self:modifyProperty(inmObj, propName, propValue, true)) then
                    isInmObjModified = true
                end
            end
        end
        
        if isInmObjModified and not onlyAssign then
            tracer:traceInfo(string.format("Object '%s' committing...", inmObj:path()))
            inmObj:commit()
            tracer:traceInfo(string.format("Object '%s' committed successfully.", inmObj:path()))
        end
        return isInmObjModified, nil
	end
}

return objectLib