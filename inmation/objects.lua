-- inmation.objects
-- inmation Script Library Lua Script
--
-- (c) 2018 inmation
--
-- Version history:
--
-- 20180404.5   From version 1.32 object id can only be fetched by 'numid' function.
-- 20171114.4   Added inspectClosure to objectTree().
-- 20170215.3   Added objectTree method to fetch a hierarchical (sub)model.
-- 20170206.2   Renamed previous Type is now ModelClass.
--              New Type is to support third argument of inmation.createobject().
-- 20161103.1   Initial release.
--
require('inmation.string-extension')
require('inmation.table-extension')

local objectLib = require("inmation.object")
local pathLib = require("inmation.path")

MODEL_CLASS_DATASOURCE = 'MODEL_CLASS_DATASOURCE'
MODEL_CLASS_GENFOLDER = 'MODEL_CLASS_GENFOLDER'
MODEL_CLASS_HOLDERITEM = 'MODEL_CLASS_HOLDERITEM'
MODEL_CLASS_ACTIONITEM = 'MODEL_CLASS_ACTIONITEM'

local retrieveObjectTree = function(path, propertyPathList, maxDepth, inspectClosure)

    local _maxDepth = maxDepth or 999
    -- Assign default proxy function.
    local _inspectClosure = function(treeNode)
        return treeNode
    end
    if type(inspectClosure) == 'function' then _inspectClosure = inspectClosure end
    -- Foreward declaration
    local retrieveTreeItem = nil
    retrieveTreeItem = function(inmObj, jsonParentList, depth)
        if inmObj == nil then return end
        local objPath = inmObj:path()
        local _id = inmObj:numid()
        local treeNode = {
            ID = _id,
            Path = objPath,
            Type = inmObj:type(),
            ObjectName = inmObj.ObjectName,
            ObjectDescription = inmObj.ObjectDescription,
        }

        -- Retrieve the requested properties
        if nil ~= propertyPathList then
            for _, propertyInfo in ipairs(propertyPathList) do
                local propertyPath = propertyInfo
                -- Use property path as tree node name.
                local treeNodePropName = propertyInfo
                if type(propertyInfo) == 'table' then
                    propertyPath = propertyInfo.p or propertyInfo.path
                    -- Use specific name or the property path.
                    treeNodePropName = propertyInfo.n or propertyInfo.name or propertyPath
                end

                if nil == treeNode.properties then
                    treeNode.properties = {}
                end

                -- Access property by suppressing the error when it doesn't exit.
                local propV = objectLib:propertyValueByPath(inmObj, propertyPath)
                if propV then
                    treeNode.properties[treeNodePropName] = propV
                end
            end
        end

        local children = inmObj:children()
        treeNode.children = {}

        if nil ~= children and #children > 0 and depth >= _maxDepth then
            treeNode.children = nil
        end

        -- Invoke closure so that the caller can inspect and stop adding this node in the tree.
        treeNode = _inspectClosure(treeNode, inmObj)
        if type(treeNode) ~= 'table' then return end

        table.insert(jsonParentList, treeNode)

        if depth >= _maxDepth then return end
        for _, child in ipairs(children) do
            retrieveTreeItem(child, treeNode.children, depth + 1)
        end
    end

    local rootObj = inmation.getobject(path)
    local jsonTree = {} -- Array
    retrieveTreeItem(rootObj, jsonTree, 1)
    return jsonTree
end

local objectsLib = {

	ensureObject = function(_, parentPath, propertyList)
		if type(propertyList) ~= "table" then return nil, 'PropertyList has to be a table.' end

        local parentObj = inmation.getobject(parentPath)
        if parentObj == nil then
            return nil, string.format("Unable to create object with non existing parent path '%s'.", parentPath)
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
                return nil, string.format("Object is of model class '%s' instead of '%s'.", objClass,
                    propertyList.ModelClass)
            end
            -- TODO: At the moment to possible to test ServerType since it returns a number instead of a string.
            -- if propertyList.ServerType ~= nil and inmObj.ServerType ~= propertyList.ServerType then
            --     return nil, string.format("Object is of ServerType '%s' instead of '%s'.", inmObj.ServerType,
            --          propertyList.ServerType)
            -- end
        end

        objectLib:modifyProperties(inmObj, propertyList)
        return inmObj, nil
	end,

    ensureFolderPath = function(self, originPath, extensionPath)
		local nodePath = originPath
		local pathFields = string.split(extensionPath, '/')

		for _, folderName in ipairs(pathFields) do

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
    -- @param propertyPathList (Optional) A string array of property paths / names to retrieve
    --      for each item in the (sub)model.
    -- @param maxDepth (Optional) Maximum tree depth to retrieve. Default value is 999.
    -- @param inspectClosure so that the caller can inspect and stop adding this node in the tree.
    -- @return Hierarchical sub(model) which contains for each object:
        -- ID, Path, Type, ObjectName, ObjectDescription
        -- Properties array; contains the path & value of the properties of which the path or name matches an
        -- item in the propertyPathList
        -- Children array; Can be empty, filled or not present. In case (the maxDepth is reached and) an item
        -- in the Hierarchical sub(model)
            -- does not contain the children array indicates that the children are not yet retrieved.
    ----------------------------------------------------------------------------
    objectTree = function(_, path, propertyPathList, maxDepth, inspectClosure)
        local objectTree = retrieveObjectTree(path, propertyPathList, maxDepth, inspectClosure)
        return objectTree
    end
}

return objectsLib