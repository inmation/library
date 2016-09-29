-- Object work simplified
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

local strLib = require("inmation.String")

objLib = {
	-- conditional return
	iif = function(cond, yes, no)
		if cond then return yes else return no end
	end,

	inmationSafePath = function(path)
		local pathFields = strLib.split(path, '/')
		local result = ''
		for i, v in ipairs(pathFields) do
			if v ~= '' then
				if result == '' then
					result = v
				else
					result = result .. '/' .. v
				end
			end
		end
		return result
	end,
	
	exists = function(path, name)
		if nil == path then error("Name without path: " .. name) end
		local o = inmation.obj(path .. "/" .. name)
		return nil ~= o and "table" == type(o) and #o.ObjectName
	end,
	
	pconcat = function(path, name, validate)
		if "string" ~= type(name) then
			error("invalid object name (" .. type(name) .. ")")
		elseif 0 == #name then
			error("null length object name given")
		end
		if "string" ~= type(path) then
			error("invalid path type (" .. type(path) .. ") to be concatenated with '" .. name .. "'")
		elseif 0 == #path then
			error("null length object path given to be concatenated with '" .. name .. "'")
		end
		if validate then
			local o = inmation.obj(path)
			--if nil == o then error ("path does not exist") end
		end
		local op = path .. "/" .. name
		return op, objLib.iif(validate, nil ~= inmation.obj(op), nil)
	end,

	-- valid inmation object
	validobject = function(objorpath)
		if "string" == type(objorpath) then
			local o = inmation.obj(objorpath)
			return "table" == type(o) -- and "string" == o.ObjectName end (requires consistency on ObjectName)
		elseif "table" == type(objorpath) then
			local p = objorpath:path()
			return "string" == type(p) and 0 < #p
		else
			return false
		end		
	end,

	isholderobject = function(obj)
		return "table" == type(obj) and "MODEL_CLASS_HOLDERITEM" == obj:type() 
	end,
	isfolderobject = function(obj)
		return "table" == type(obj) and "MODEL_CLASS_GENFOLDER" == obj:type() 
	end,
	isioobject = function(obj)
		return "table" == type(obj) and "MODEL_CLASS_IOITEM" == obj:type() 
	end,
	
	updLocationNoCommit = function(obj, loc)
		if nil == obj then error("updLocation called without valid object") end
		local com = false
		if nil ~= loc then
			if "string" == type(loc["LOC"]) and loc["LOC"] ~= obj.Location.LocationName then 
				obj.Location.LocationName = loc["LOC"]
				com = true
			end
			if "number" == type(loc["LAT"]) and loc["LAT"] ~= obj.Location.Latitude then 
				obj.Location.Latitude = loc["LAT"]
				com = true
			end
			if "number" == type(loc["LON"]) and loc["LON"] ~= obj.Location.Longitude then 
				obj.Location.Longitude = loc["LON"]
				com = true
			end
			if "number" == type(loc["ALT"]) and loc["ALT"] ~= obj.Location.Altitude then 
				obj.Location.Altitude = loc["ALT"]
				com = true
			end
			if com then
				obj.Location.LocationStrategy = "LOC_STRAT_STATIC"
			end
		end
		return com
	end,
	
	updLocation = function(obj, loc)
		local mod = false
		if objLib.updLocationNoCommit(obj, loc) then
			obj:commit()
			mod = true
		end
		return mod
	end,
	
	
	equalCustom = function(ock, ocv, ack, acv)
		local chg = false
		for n = 1, #ack do
			local fnd = false
			-- find matching key in object
			for nn = 1, #ock do
				if ock[nn] == ack[n] then
					fnd = true
					-- compare data
					chg = ocv[nn] ~= acv[n]
					if chg then 
						-- first difference suffices
						--error("Updating object because not no match: OCV=" .. ocv[nn] .. " , ACV=" .. acv[n])
						break 
					end
				end
			end
			-- new key?
			if not fnd then 
				--error("Updating object because not fnd: " .. ack[n])
				chg = true 
			end	
			-- any change?
			if chg then
				break
			end
		end
		--error("equalCustom exit for ACV[1]=" ..acv[1] .. "CHG=" .. tostring(chg))
		return not chg
	end,
	
	getCustom = function(obj, key)
		if not validobject(obj) then return nil end
		local ck = obj.CustomOptions.CustomProperties.CustomPropertyName
		local cv = obj.CustomOptions.CustomProperties.CustomPropertyValue
		for n = 1, #ck do
			if ck[n] == key then
				return cv[n]
			end
		end
		return nil
	end,
	
	updCustom = function(obj, ck, cv)
		if #ck ~= #cv then error("Unmatched pairs in custom key/value array (keys=" .. #ck .. " , values=" .. #cv) end
		local mod = false
		local ock = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName")
		local ocv = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue")
		-- check on field size change
		local chg = #ock ~= #ck
		-- check whether the new field is lesser entries than what the object holds currently
		local lsr = #ock > #ck
		-- no change in sizes, check content
		if not chg then
			-- loop thru given keys
			for n = 1, #ck do
				local fnd = false
				-- find matching key in object
				for nn = 1, #ock do
					if ock[nn] == ck[n] then
						fnd = true
						-- compare data
						chg = ocv[nn] ~= cv[n]
						if chg then 
							-- first difference suffices
							break 
						end
					end
				end
				-- new key?
				if not fnd then 
					chg = true 
				end	
				-- any change?
				if chg then
					break
				end
			end
		end
		-- changes to apply?
		if chg then
			if lsr then
				-- lesser entries, clear object data first
				local eck = nil
				local ecv = nil
				inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName", eck)
				inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue", ecv)
			end
			-- finally apply new settings
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName", ck)
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue", cv)
			mod = true
		end
		return mod
	end,
	
	updUseCases = function(obj, uct)
		if "string" == type(obj) then obj = inmation.getobject(obj) end
		if not validobject(obj) then error("invalid root object in updUseCases call") end
		repeat
			local ock = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName")
			local ocv = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue")
			local found = 0
			local set = false
			for n=1, #ock do
				if "INMATION.USECASES" == ock[n]:upper() then
					found = n
				end
			end
			if 0 == found then
				table.insert(ock, "inmation.UseCases")
				local s = ""
				for nn = 1, #uct do
					if 1 < nn then s = ss .. ";" end
					s = s .. uct[nn]
				end
				table.insert(ocv, s)
				set = true
			else
				local t = { }
				local s = ocv[found]
				local pat = "[^;]+"
				for w in string.gmatch(s, pat) do
					table.insert(t, w)
				end
				local uchange = false
				for uci = 1, #uct do 
					local ucfound = false
					for exi = 1, #t do
						if t[exi]:upper() == uct[uci]:upper() then
							ucfound = true
							break
						end
					end
					if not ucfound then
						if 0 < #s then s = s .. ";" end
						s = s .. uct[uci]
						uchange = true
					end
				end
				if uchange then
					ocv[found] = s
					set = true
				end
			end
			if set then
				inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName", ock)
				inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue", ocv)
			end
			obj = obj:parent()
		until ("MODEL_CLASS_SYSTEM" == obj:type())
	end,
	
	ensureFolder = function(path, name, desc, loc, ck, cv)
		local L = objLib
		local obj
		local p = path .. "/" .. name
		local com = false
		local s 
		if not objLib.exists(path, name) then
			obj = inmation.createobject(path, "MODEL_CLASS_GENFOLDER")
			obj.ObjectName = name
			com = true
			s = "Ensured by creation '" .. p .. "'"
		else
			obj = inmation.getobject(p)
			if not #obj.ObjectName then error("Ambiguous") end
			s = "Ensured existing '" .. p .. "'"
		end
		
		if "string" == type(desc) and desc ~= obj.ObjectDescription then 
			obj.ObjectDescription = desc
			com = true
		end
		
		if nil ~= loc then
			local c = objLib.updLocationNoCommit(obj, loc)
			com = com or c
		end
		
		if nil ~= ck then
			if #ck == #cv then
				local ock = obj.CustomOptions.CustomProperties.CustomPropertyName
				local ocv = obj.CustomOptions.CustomProperties.CustomPropertyValue
				if (#ck ~= #ock) or (not L.equalCustom(ock, ocv, ck, cv)) then
					obj.CustomOptions.CustomProperties.CustomPropertyName = ck
					obj.CustomOptions.CustomProperties.CustomPropertyValue = cv
					com = true
				end
			end
		end
		
		if com then
			obj:commit()
		end
		
		return p, obj, s
	end,

	ensureFolderPath = function(originPath, extensionPath)
		local nodePath = originPath
		local pathFields = strLib.split(extensionPath, '/')

		for i, folderName in ipairs(pathFields) do

			if  folderName ~= '' then
				local folderPath = nodePath .. '/' .. folderName
				local folderObj = inmation.getobject(folderPath)

				if not folderObj then
					folderObj = inmation.createobject(nodePath, "MODEL_CLASS_GENFOLDER")
					folderObj.ObjectName = folderName
					folderObj:commit()
				end
				-- Modify node path for next level
				nodePath = nodePath .. '/' .. folderName
			end
		end
		return inmation.getobject(originPath .. '/' .. extensionPath)
	end,
	
	-- Action Items are missing a location compound!
	ensureAction = function(path, name, desc, sysal, dispal, eu, dp, arc, script, custkeys, custvals)
		local p
		local obj
		if not objLib.exists(path, name) then
			obj = inmation.createobject(path, "MODEL_CLASS_ACTIONITEM")
			obj.ObjectName = name
			if nil ~= desc then obj.ObjectDescription = desc end
			if nil ~= sysal then obj.SystemAlias = sysal end
			if nil ~= dispal then obj.DisplayAlias = dispal end
			if nil ~= eu then obj.OpcEngUnit = eu end
			if nil ~= dp then obj.DecimalPlaces = dp end
			if nil ~= arc and arc then
				obj.ArchiveOptions.ArchiveSelector = "ARC_PRODUCTION"
				obj.ArchiveOptions.StorageStrategy = "STORE_RAW_HISTORY"
			end
			if nil ~= loc then
				objLib.updLocationNoCommit(obj, loc)
			end
			if nil ~= script then
				obj.AdvancedLuaScript = script
			end
			obj:commit()
			p = obj:path()
		else
			p = path .. "/" .. name
			obj = inmation.getobject(p)
			if nil ~= desc then if desc ~= obj.ObjectDescription then obj.ObjectDescription = desc end end
			if nil ~= sysal then if sysal ~= obj.SystemAlias then obj.SystemAlias = sysal end end
			if nil ~= dispal then if dispal ~= obj.DisplayAlias then obj.DisplayAlias = dispal end end
			if nil ~= eu then if eu ~= obj.OpcEngUnit then obj.OpcEngUnit = eu end end
			if nil ~= dp then if dp ~= obj.DecimalPlaces then obj.DecimalPlaces = dp end end
			if nil ~= arc and arc then
				if "ARC_PRODUCTION" ~= obj.ArchiveOptions.ArchiveSelector then obj.ArchiveOptions.ArchiveSelector = "ARC_PRODUCTION" end
				if "STORE_RAW_HISTORY" ~= obj.ArchiveOptions.StorageStrategy then obj.ArchiveOptions.StorageStrategy = "STORE_RAW_HISTORY" end
			end
			if nil ~= script and obj.AdvancedLuaScript ~= script then
				obj.AdvancedLuaScript = script
			end
			obj:commit()
		end
		if nil ~= custkeys and nil ~= custvals and #custkeys == #custvals then
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName", custkeys)
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue", custvals)
		end
		return p, obj
	end,
	
	ensureHolder = function(path, name, desc, data, datafnc, enforcedata, sysal, dispal, eu, dp, arc, custkeys, custvals, loc)
		local p
		local obj
		if not objLib.exists(path, name) then
			obj = inmation.createobject(path, "MODEL_CLASS_HOLDERITEM")
			obj.ObjectName = name
			if nil ~= desc then obj.ObjectDescription = desc end
			if nil ~= sysal then obj.SystemAlias = sysal end
			if nil ~= dispal then obj.DisplayAlias = dispal end
			if nil ~= eu then obj.OpcEngUnit = eu end
			if nil ~= dp then obj.DecimalPlaces = dp end
			if nil ~= arc and arc then
				obj.ArchiveOptions.ArchiveSelector = "ARC_PRODUCTION"
				obj.ArchiveOptions.StorageStrategy = "STORE_RAW_HISTORY"
			end
			if nil ~= loc then
				objLib.updLocationNoCommit(obj, loc)
			end
			obj:commit()
			p = obj:path()
		else
			p = path .. "/" .. name
			obj = inmation.getobject(p)
			if nil ~= desc and desc ~= obj.ObjectDescription then obj.ObjectDescription = desc end
			if nil ~= sysal then if sysal ~= obj.SystemAlias then obj.SystemAlias = sysal end end
			if nil ~= dispal then if dispal ~= obj.DisplayAlias then obj.DisplayAlias = dispal end end
			if nil ~= eu then if eu ~= obj.OpcEngUnit then obj.OpcEngUnit = eu end end
			if nil ~= dp then if dp ~= obj.DecimalPlaces then obj.DecimalPlaces = dp end end
			if nil ~= arc and arc then
				if "ARC_PRODUCTION" ~= obj.ArchiveOptions.ArchiveSelector then obj.ArchiveOptions.ArchiveSelector = "ARC_PRODUCTION" end
				if "STORE_RAW_HISTORY" ~= obj.ArchiveOptions.StorageStrategy then obj.ArchiveOptions.StorageStrategy = "STORE_RAW_HISTORY" end
			end
			if nil ~= loc then
				objLib.updLocationNoCommit(obj, loc)
			end
			obj:commit()
		end
		if nil ~= data then
			local x = inmation.get(p)
			if x ~= data and enforcedata or nil == x then
				if nil ~= datafnc then
					datafnc(p, data)
				else
					inmation.set(p, data)
				end
			end
		end
		if nil ~= custkeys and nil ~= custvals and #custkeys == #custvals then
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName", custkeys)
			inmation.setvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue", custvals)
		end
		
		return p, obj
	end,
	-- options = {
	--		description = string,
	--		data = variant,
	--		dataCallback = function,
	--		enforceData = boolean,
	--		systemAlias = string,
	--		displayAlias = string,
	--		opcEngUnit = string,
	-- 		decimalPlaces = number, 
	--		enableArchiving = boolean,
	--		customPropertiesKeys = table,
	--		customPropertiesValues = table,
	--		location = table
	-- }
	ensureHolderWithOptions = function(parentPath, objectName, options)
		if type(options) ~= "table" then return end
		return objLib.ensureHolder(parentPath, objectName, options.description, options.data, options.dataCallback, options.enforceData, 
			options.systemAlias, options.DisplayAlias, options.opcEngUnit, options.decimalPlaces, options.enableArchiving, 
			options.customPropertiesKeys, options.customPropertiesValues, options.location)
	end
}

return objLib
