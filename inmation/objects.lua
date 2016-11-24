-- inmation.objects
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20161103.1   Initial release.
--
local objectLib = require("inmation.object")
local pathLib = require("inmation.path")

MODEL_CLASS_DATASOURCE = 'MODEL_CLASS_DATASOURCE'
MODEL_CLASS_GENFOLDER = 'MODEL_CLASS_GENFOLDER'
MODEL_CLASS_HOLDERITEM = 'MODEL_CLASS_HOLDERITEM'
MODEL_CLASS_ACTIONITEM = 'MODEL_CLASS_ACTIONITEM'

objectsLib = {

	ensureObject = function(self, parentPath, propertyList)
		if type(propertyList) ~= "table" then return nil, 'PropertyList has to be a table.' end

        local parentObj = inmation.getobject(parentPath)
        if parentObj == nil then
            return nil, tring.format("Unable to create object with non existing parent path '%s'.", parentPath)
        end

        local objectName = propertyList['ObjectName']
        if objectName == nil then return nil, 'ObjectName not found in propertyList.' end
     
        local path = pathLib.join(parentPath, objectName)
        
        local inmObj= inmation.getobject(path)

        if inmObj== nil then
            if propertyList.Type == nil then return nil, 'Type not found in propertyList.' end
            inmObj = inmation.createobject(parentPath, propertyList.Type)
            inmObj.ObjectName = objectName

            -- Mandatory properties which requires to commit before able to continue.
            if propertyList.ServerType then
                inmObj.ServerType = propertyList.ServerType
                if propertyList.ServerType == 'EP_OPC_UA' then
                    inmObj['UaConnection']['OpcUaServerUrl'] = propertyList['UaConnection.OpcUaServerUrl']
                end
            end
            
            if propertyList.GenerationType then inmObj.GenerationType = propertyList.GenerationType end
            inmObj:commit()
        else 
            local objType = inmObj:type()
            if propertyList.Type ~= nil and objType ~= propertyList.Type then
                return nil, string.format("Object is of type '%s' instead of '%s'.", objType, propertyList.Type) 
            end
            -- TODO: At the moment to possible to test ServerType since it returns a number instead of a string.
            -- if propertyList.ServerType ~= nil and inmObj.ServerType ~= propertyList.ServerType then
            --     return nil, string.format("Object is of ServerType '%s' instead of '%s'.", inmObj.ServerType, propertyList.ServerType) 
            -- end 
        end
        
        objectLib:modifyProperties(inmObj, propertyList)
        return inmObj, nil
	end,

    ensureFolderPath = function(self, originPath, extensionPath)
		local nodePath = originPath
		local pathFields = strLib.split(extensionPath, '/')

		for i, folderName in ipairs(pathFields) do

			if  folderName ~= '' then
                local propertyList = {
                    ObjectName = folderName,
                    Type = "MODEL_CLASS_GENFOLDER"
                }
                self:ensureObject(nodePath, propertyList)
	
				-- Modify node path for next level
				nodePath = nodePath .. '/' .. folderName
			end
		end
		return inmation.getobject(originPath .. '/' .. extensionPath)
	end
}

return objectsLib