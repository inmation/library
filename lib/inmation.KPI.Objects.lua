-- KPI Object work simplified
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

kpiobjLib = {
	essLib = require"inmation.Essentials",
	env = essLib.Env,
	ensureKPI = function(path, settings, check_settings)
		local chkset = (nil ~= check_settings) and ("boolean" == type(check_settings)) and check_settings
		local obj = inmation.getobject(path)
		local exist = nil ~= obj and "table" == type(obj)
		
		-- fast route if the user only wants the object to be there
		if exist and not chkset then return obj end
		
		-- the more tedious way
		-- split and organize the KPI path
		local tpath = { }
		local tpathr = { }
		local x = { }
		if not exist then	
			local splitted = false
			local parent, child = inmation.splitpath(path)
			repeat 
				if nil ~= child and #child ~= 0 then
					table.insert(tpathr, child)
				end
				if nil ~= parent and 0 ~= #parent then
					parent, child = inmation.splitpath(parent)
				else
					splitted = true
				end
			until splitted
			
			-- reverse order of object names to start at model root
			local tpathrsz = #tpathr
			n = tpathrsz
			while n > 0 do
				table.insert(tpath, tpathr[n])
				n = n - 1
			end
			
			-- create the tree
			local newpath = ""
			kpi = false
			for n = 1, #tpath do
				kpi = n == #tpath
				if not kpi then
					local otype
					-- create a hierarchy object
					if 1 == n then
						otype = "MODEL_CLASS_ENTERPRISE"
					elseif 2 == n then
						otype = "MODEL_CLASS_DIVISION"
					elseif 3 == n then
						otype = "MODEL_CLASS_SITE"
					elseif 4 == n then
						otype = "MODEL_CLASS_PLANTCOMPOUND"
					elseif 5 == n then
						otype = "MODEL_CLASS_PLANT"
					elseif 6 == n then
						otype = "MODEL_CLASS_AREA"
					elseif 7 == n then
						otype = "MODEL_CLASS_PROCESSCELL"
					elseif 8 == n then
						otype = "MODEL_CLASS_UNIT"
					elseif 9 == n then
						otype = "MODEL_CLASS_EQUIPMENTMODULE"
					elseif 10 == n then
						otype = "MODEL_CLASS_CONTROLMODULE"
					else
					end
					if nil ~= otype then
						local test = inmation.getobject(newpath .. "/" .. tpath[n])
						if nil == test then
							if "string" ~= type(tpath[n]) or 0 == #tpath[n] then error("Invalid object name") end
							local newobj = inmation.createobject(newpath, otype)
							newobj.ObjectName = tpath[n]
							newobj:commit()
						end
						newpath = newpath .. "/" .. tpath[n]
					end
				else
					-- create the KPI object
					if "string" ~= type(tpath[n]) or 0 == #tpath[n] then error("Invalid KPI name") end
					local newkpi = inmation.createobject(newpath, "MODEL_CLASS_GENKPI")
					newkpi.ObjectName = tpath[n]
					newkpi:commit()
				end
			end
		end
		if (nil ~= settings and not exist) or (nil ~= check_settings and check_settings) then
			for key, val in pairs(settings) do
				if "ProcessValueLink" == key then
					inmation.linkprocessvalue(path, val)
				else
					if key == "DisplayOrder" then
						local x = inmation.getvalue(path .. "." .. key)
						if x ~= val then
							error("DisplayOrder: "  .. x .. " Setpoint: " .. val)
						end
					end
					inmation.setvalue(path .. "." .. key, val)
				end
			end
		end
		
		return tpath
	end
}

return kpiobjLib
