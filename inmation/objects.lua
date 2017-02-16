-- inmation.objects
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20170215.3   Added objectTree method to fetch a hierarchical (sub)model.
-- 20170206.2   Renamed previous Type is now ModelClass. New Type is to support third argument of inmation.createobject().
-- 20161103.1   Initial release.
--
local objectLib = require("inmation.object")
local pathLib = require("inmation.path")

MODEL_CLASS_DATASOURCE = 'MODEL_CLASS_DATASOURCE'
MODEL_CLASS_GENFOLDER = 'MODEL_CLASS_GENFOLDER'
MODEL_CLASS_HOLDERITEM = 'MODEL_CLASS_HOLDERITEM'
MODEL_CLASS_ACTIONITEM = 'MODEL_CLASS_ACTIONITEM'

local retrieveObjectTree = function(path, propertyPathList, maxDepth)

    local _maxDepth = maxDepth or 999
    retrieveTreeItem = function(inmObj, jsonParentList, depth)
        local path = inmObj:path()
        local jsonTreeNode = {
            ID = inmObj.ID,    
            Path = path,
            Type = inmObj:type(),    
            ObjectName = inmObj.ObjectName,
            ObjectDescription = inmObj.ObjectDescription,
        }
        table.insert(jsonParentList, jsonTreeNode)

        -- Retrieve the requested properties
        if nil ~= propertyPathList then  
            for i,propertyPath in ipairs(propertyPathList) do
                if nil == jsonTreeNode.properties then
                    jsonTreeNode.properties = {}
                end

                local accessProperty = function(path)
                    local propValue = inmation.getvalue(path)
                    return propValue or 'null'
                end
                -- Access property by suppressing the error when it doesn't exit.
                local succeeded, propV= pcall(accessProperty, path .. '.' .. propertyPath)

                if succeeded == true then
                    local prop = {}
                    prop.Path = propertyPath
                    prop.V = propV
                    table.insert(jsonTreeNode.properties, prop)
                end
            end
        end
            
        local children = inmObj:children()
        jsonTreeNode.children = {}
        
        if nil ~= children and #children > 0 and depth >= _maxDepth then
            jsonTreeNode.children = nil
        end
        
        if depth >= _maxDepth then return end
        for i,child in ipairs(children) do
            retrieveTreeItem(child, jsonTreeNode.children, depth + 1)
        end
    end

    local rootObj = inmation.getobject(path)
    local jsonTree = {} -- Array
    retrieveTreeItem(rootObj, jsonTree, 1)
    return jsonTree
end

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
            if propertyList.ModelClass == nil then return nil, 'ModelClass not found in propertyList.' end

            inmObj = inmation.createobject(parentPath, propertyList.ModelClass, propertyList.Type)
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
            local objClass = inmObj:type()
            if propertyList.ModelClass ~= nil and objClass ~= propertyList.ModelClass then
                return nil, string.format("Object is of model class '%s' instead of '%s'.", objClass, propertyList.ModelClass) 
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
	end,

    ----------------------------------------------------------------------------
    -- Retrieves a hierarchical (sub)model from a certain level (path).
    -- @param path The root level for the hierarchical model to retrieve.
    -- @param propertyPathList (Optional) A string array of property paths / names to retrieve for each item in the (sub)model.
    -- @param maxDepth (Optional) Maximum tree depth to retrieve. Default value is 999.
    -- @return Hierarchical sub(model) which contains for each object:
        -- ID, Path, Type, ObjectName, ObjectDescription 
        -- Properties array; contains the path & value of the properties of which the path or name matches an item in the propertyPathList
        -- Children array; Can be empty, filled or not present. In case (the maxDepth is reached and) an item in the Hierarchical sub(model) 
            -- does not contain the children array indicates that the children are not yet retrieved.     
    ----------------------------------------------------------------------------
    objectTree = function(self, path, propertyPathList, maxDepth)
        local objectTree = retrieveObjectTree(path, propertyPathList, maxDepth)
        return objectTree
    end
}

return objectsLib