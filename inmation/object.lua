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

        changedSriptItems = function(self)
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
            -- matchScriptItem.LuaModuleName = scriptItem.LuaModuleName
            
            if scriptItem.AdvancedLuaScript and type(scriptItem.AdvancedLuaScript) == 'string' and matchScriptItem.AdvancedLuaScript ~= scriptItem.AdvancedLuaScript then
                if matchScriptItem.oldAdvancedLuaScript == nil then
                     matchScriptItem.oldAdvancedLuaScript = matchScriptItem.AdvancedLuaScript
                end
                matchScriptItem.AdvancedLuaScript = scriptItem.AdvancedLuaScript
            end

            if scriptItem.LuaModuleMandatoryExecution and type(scriptItem.LuaModuleMandatoryExecution) == 'boolean' and matchScriptItem.LuaModuleMandatoryExecution ~= scriptItem.LuaModuleMandatoryExecution  then
                if matchScriptItem.oldLuaModuleMandatoryExecution == nil then
                     matchScriptItem.oldLuaModuleMandatoryExecution = matchScriptItem.LuaModuleMandatoryExecution
                     error('LuaModuleMandatoryExecution changed')
                end
                matchScriptItem.LuaModuleMandatoryExecution = scriptItem.LuaModuleMandatoryExecution
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
    -- Gets the property of an object by property path.
    -- @param inmObj Object which contains the property to retrieve.
    -- @return First return value contains the object property. 
        --When the property path cannot be resolved the first return value is nil, the second return value contains an error message.
    ----------------------------------------------------------------------------
    propertyValueByPath = function(self, inmObj, propertyPath)
        local err = nil
        local propNameList = propertyPath:split('.')

        local propItem = inmObj
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
            propCompoundItem = propCompoundItem[propName]
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
            trace:traceInfo(string.format("Object '%s'; Changed value of property '%s' from '%s' to '%s'.", inmObj:path(), propName, objPointer[propName], propValue))
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
        trace:traceInfo(string.format("modifyProperties for obj '%s'", inmObj:path()))
        -- List with { propertyName = {} }
        local propertyIgnoreList = {}

        if propertyList.ScriptLibrary then propertyIgnoreList.ScriptLibrary = true end

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

        -- Iterate through the remaining properties.
        local isInmObjModified = false
        for propName, propValue in pairs(propertyList) do
            if nil ~= propertyIgnoreList[propName] then
                if (self:modifyProperty(inmObj, propName, propValue, true)) then
                    isInmObjModified = true
                end
            end
        end

        if isInmObjModified and not onlyAssign then
            inmObj:commit()
            trace:traceInfo(string.format("Object '%s' committed successfully.", inmObj:path()))
        end
        return isInmObjModified, nil
	end
}

return objectLib