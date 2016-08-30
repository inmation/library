-- Self-monitoring simplified
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

slfmonLib =
{
	SysMon =
	{
		-- other libraries referenced
		ess = nil,
		env = nil,
		obj = nil,
		kpi = nil,
	
		-- the comp table holds the definition which objects to monitor
		comp = { },
		
		-- the following def tables hold information what to expose per object type
		mondef = { },
		sysdef = { },
		cordef = { },
		condef = { },
		
		-- the init function populates the def table hierarchy
		-- the tables must be given like
		-- { { C="Lag", K="Network Lag Avg.", T=60, A="mean" }, 
		-- 	 { C="Lag", K="Network Lag Max.", T=60, A="max" }
		-- 	 { C="Lag", K="Network QoS", T=60, A="count", S=60 }
		--   { C="Compression", k="Compression Avg.", T=60, A="mean" } 
		-- }
		-- where 	C=Name of the Performance Counter
		-- 			K=Name of the resulting KPI
		--			T=Time base for Aggregation
		--			A=Function to be used from the Sampler
		--			S=Setpoint for percentage calculation
		
		-- some constants
		DATAFOLDER = "_Data",
		SYSTEMSFOLDER = "_Systems",
		COREFOLDER = "_Cores",
		CONNECTORFOLDER = "_Connectors",
		dataroot = nil,
		sysroot = nil,
		treecall = 0,
		
		-- code injection
		templateSamplers =  
[==========[
local essLib = require"inmation.Essentials"
local env = essLib.Env
local smpLib = require"inmation.Sampling"
local smp = smpLib.Sampler
local tbase = ___TIMEBASE___
local MSEC = 1000
local val = nil
local valtime = nil
function main()
	env:entry()
	local t = inmation.now()
	if 1 == env.calls then
		smp.keepone = false
		smp.trange = tbase * MSEC
	end
	local v, q, t = inmation.get("I1___PERFTYPE___")
	smp:sample("I1", v, q, t)
	if nil ~= env:newminute() then
		val = smp:___SMPTYPE___("I1", tbase * MSEC, t - (tbase * MSEC)) __SCALEEQU__
		valtime = t
		inmation.set("O1", val, 0, t)
	end
	if valtime >= t - tbase * MSEC then
		return val
	else
		return nil
	end
end
return main		
]==========],
			
		init = function(self, mondef, sysdef, cordef, condef)
			-- libs and stuff
			self.ess = require"inmation.Essentials"
			self.env = self.ess.Env
			self.obj = require"inmation.Objects"
			self.kpi = require"inmation.KPI.Objects"
	
			-- assign settings
			self.mondef = mondef
			self.sysdef = sysdef
			self.cordef = cordef
			self.condef = condef
		end,
		
		scanComponents = function(self)
			-- find systems
			local path = "/"
			local mask = ""
			local systemname = ""
			local corename = ""
			local connname = ""
			for obj in self.ess.objects({ "MODEL_CLASS_SYSTEM" }) do
				systemname = obj.ObjectName
				if nil == self.comp[systemname] then
					self.comp[systemname] = { 
											  FND=inmation.now(),
											  ROO=nil,
											  PRF={},
											  CORES={} 
											}
					--self.env:debug("SYSTEM FOUND", "Call#" .. self.env.calls .. ":" .. systemname)
				end
			end
			-- find cores
			for obj in self.ess.objects({ "MODEL_CLASS_CORE" }) do
				corename = obj.ObjectName
				systemname = obj:parent().ObjectName
				local exist = false
				for k,v in pairs(self.comp[systemname]["CORES"]) do
					if corename == k then
						exist = true
					end
				end
				if not exist then
					--self.env:debug("CORE FOUND", "Call#" .. self.env.calls .. ":" .. systemname .. "/" .. corename)
					local tsub = { 
								   PAT=obj:path(),
								   FND=inmation.now(),
								   ROO=nil,
								   LOC=obj.Location.LocationName, 
					               LAT=obj.Location.Latitude, 
								   LON=obj.Location.Longitude, 
								   ALT=obj.Location.Altitude,
								   CHG=true,
								   PRF={},
								   CONNS={} 
								  }
					self.comp[systemname]["CORES"][corename] = tsub	
				else
					if self.comp[systemname]["CORES"][corename]["LOC"] ~= obj.Location.LocationName or
					   self.comp[systemname]["CORES"][corename]["LAT"] ~= obj.Location.Latitude or
					   self.comp[systemname]["CORES"][corename]["LON"] ~= obj.Location.Longitude or 
					   self.comp[systemname]["CORES"][corename]["ALT"] ~= obj.Location.Altitude then
						self.ess.env:debug("CORE LOCATION CHANGE", "Call#" .. self.ess.env.calls .. ":" .. systemname .. "/" .. corename)
					else
						self.comp[systemname]["CORES"][corename]["CHG"] = false
					end
				end
			end
			-- find connectors
			local conncnt = 0
			for obj in self.ess.objects({ "MODEL_CLASS_CONNECTOR" }) do
				connname = obj.ObjectName
				corename = nil
				local o = obj:parent()
				repeat
					if "MODEL_CLASS_CORE" == o:type() then
						corename = o.ObjectName
					else
						o = o:parent()
					end
				until nil ~= corename or "MODEL_CLASS_SYSTEM" == o:type()
				if nil == corename then error("Parent Core not found") end
				systemname = o:parent().ObjectName
				for k,v in pairs(self.comp[systemname]["CORES"][corename]["CONNS"]) do
					if connname == k then
						exist = true
					end
				end
				if not exist then
					conncnt = conncnt + 1
					--self.env:debug("CONNECTOR FOUNself.env:debug(" .. conncnt ..")", "Call#" .. self.env.calls .. ": " .. systemname .. "/" .. corename .. "/" .. connname)
					local tsub = { PAT=obj:path(),
								   FND=inmation.now(),
								   ROO=nil,
								   LOC=obj.Location.LocationName, 
					               LAT=obj.Location.Latitude, 
								   LON=obj.Location.Longitude, 
								   ALT=obj.Location.Altitude,
								   PRF= { },
								   CHG=true
								  }
					self.comp[systemname]["CORES"][corename]["CONNS"][connname] = tsub	
				else
					if self.comp[systemname]["CORES"][corename]["CONNS"][connname]["LOC"] ~= obj.Location.LocationName or
					   self.comp[systemname]["CORES"][corename]["CONNS"][connname]["LAT"] ~= obj.Location.Latitude or
					   self.comp[systemname]["CORES"][corename]["CONNS"][connname]["LON"] ~= obj.Location.Longitude or 
					   self.comp[systemname]["CORES"][corename]["CONNS"][connname]["ALT"] ~= obj.Location.Altitude then
						self.env:debug("CONNECTOR LOCATION CHANGE", "Call#" .. self.env.calls .. ":" .. systemname .. "/" .. corename .. "/" .. connname)
					else
						self.comp[systemname]["CORES"][corename]["CONNS"][connname]["CHG"] = false
					end
				end
			end
		end,
		
		syscount = function(self)
			local r = 0
			for k,v in pairs(self.comp) do
				r = r + 1
			end
			return r
		end,
		
		corecount = function(self, system)
			local r = 0
			for k,v in pairs(self.comp) do
				for kk, vv in pairs(v["CORES"]) do
					r = r + 1
				end
			end
			return r
		end,
		
		connectorcount = function(self, system, core)
			local r = 0
			for k,v in pairs(self.comp) do
				for kk, vv in pairs(v["CORES"]) do
					for kkk, vvv in pairs(vv["CONNS"]) do
						r = r + 1
					end
				end
			end
			return r
		end,
		
		adjustScript = function(self, aggtype, srctype, prftype, timebase, equbase)
			local r
			local equ = ""
			if nil ~= equbase then
				equ = " * 100 / " .. equbase
			end
			if 1 == srctype:find("@obj") then
				r = self.templateSamplers:gsub("___TIMEBASE___", tostring(timebase)):gsub("___PERFTYPE___", ".Performance." .. prftype):gsub("___SMPTYPE___", aggtype):gsub("__SCALEEQU__", equ)
			elseif 1 == srctype:find("@calc") then
			else
				r = self.templateSamplers:gsub("___TIMEBASE___", tostring(timebase)):gsub("___PERFTYPE___", ""):gsub("___SMPTYPE___", aggtype):gsub("__SCALEEQU__", equ)
			end
			return r
		end,
		
		createRefs = function(self, object, src, trg)
			inmation.setreferences(object, {{ name="I1", path=src }, { name="O1", path=trg, type=0x300000000 }})
		end,
		
		ensureReferences = function(self, object, condef, root, src, trg)
			local link = condef["S"]
			if 1 == link:find("@") then
				if "@obj" == link then
					-- Link to the real object
					self.createRefs(self, object, src, trg)
				else
					--src = root .. "/_prfkpi." .. link
					--self.createRefs(self, object, src, trg)
				end
			else
				-- Link to another input of the same folder
				src = root .. "/_prfkpi." .. link
				self.createRefs(self, object, src, trg)
			end
		end,
	
		ensureSystemDataObjects = function(system)
		end,
		
		ensureCoreDataObjects = function(system, core)
		end,
		
		ensureConnectorDataObjects = function(self, system, core, connector)
			-- get the essential stuff from the in-memory collection	
			local compdef = self.comp[system]["CORES"][core]["CONNS"][connector]
			if nil == compdef then error("COMPDEF nil for system=" .. system .. ", core=" .. core .. ", connector=" .. connector) end
			local root = compdef["ROO"]
			if nil == root then error("COMPDEF[ROO] nil for system=" .. system .. ", core=" .. core .. ", connector=" .. connector) end
			local src = compdef["PAT"]
			if nil == src then error("COMPDEF[PAT] nil for system=" .. system .. ", core=" .. core .. ", connector=" .. connector) end
			
			-- create all KPI sources in the I/O model according to the specification
			local trg = nil
			for k,v in pairs(self.condef) do
			
				-- Make sure the data holder exists (will be linked to the KPIs)
				local kpiname = "_prfkpi." .. v["K"]
				local kpipath = root .. "/" .. kpiname
				test = inmation.getobject(kpipath)
				if not validobject(test) then
					if nil ~= self.mondef["S"] then system = self.mondef["S"] end
					local ck = { "KPI_Link", "KPI_DisplayOrder", "KPI_Path", "KPI_Category", "KPI_Source" }
					local cv = { "TRUE", tostring(k), "/" .. self.mondef["N"] .. "/" .. system .. "/" .. core .. "/" .. connector, v["Y"], src}
					
					self.env:reset()
					self.env:debug("ENSURE HOLDER in PATH", root)
				
					local hldobj = self.obj.ensureHolder(root,
														 kpiname,
														 v["D"] .. " (KPI Source)",
														 nil,
														 nil,
														 false,
														 nil,
														 nil,
														 v["E"],
														 0,
														 true,
														 ck,
														 cv,
														 nil)
					if not validobject(hldobj) then error("HolderItem (KPI Source)'" .. kpipath .. "' is not valid") end
					trg = kpipath
				end
			
				-- Make sure the sampler exists
				local smpname = "_prfsmp." .. v["K"]
				local smppath = root .. "/" .. smpname
				local test = inmation.getobject(smppath)
				if not validobject(test) then
					local script = self.adjustScript(self, v["A"], v["S"], v["C"], v["T"], v["X"])
					local actobj = self.obj.ensureAction(root, 
										                 smpname, 
										                 v["D"] .. " (Sampler)",
										                 nil,
										                 nil,
										                 v["E"],
										                 0,
										                 false,
														 script,
														 nil,
														 nil)
					if not validobject(actobj) then error("ActionItem (KPI Sampler)'" .. smppath .. "' is not valid") end
					self.ensureReferences(self, actobj, v, root, src, trg)
				end
			end
		end,
		
		updDataTree = function(self)
			local upd = 0 == self.treecall
			local s
			self.treecall = self.treecall + 1
			if 0 == syscount then
				self.env:debug("NO SYSTEM COLLECTED", "Data Tree is not validated")
				return
			end
			local p, o = self.obj.ensureFolder(inmation.getself():parent():path(), self.DATAFOLDER, "Auto-generated performance data folder")
			if not validobject(o) then error("Data folder could not be created/validated") end
			self.dataroot = p
			p, o = self.obj.ensureFolder(self.dataroot, self.SYSTEMSFOLDER, "Auto-generated performance data folder for all systems")
			if not validobject(o) then error("Systems data folder could not be created/validated") end
			self.sysroot = p
			-- Create the performance data hierarchy for systems, cores and connectors
			for k,v in pairs(self.comp) do
				self.env:debug("FOLDER", self.sysroot .. "/" .. "_" .. k)
				p, o = self.obj.ensureFolder(self.sysroot, "_" .. k, "Auto-generated performance data folder for system '"  .. k .. "'")
				if not validobject(o) then error("System data folder for '" .. k .. "' could not be created/validated") end
				if nil == self.comp[k]["ROO"] then self.comp[k]["ROO"] = p end
				self.ensureSystemDataObjects(self, k)
				if 0 ~= self.corecount(self, k) then
					self.env:debug("FOLDER", self.comp[k]["ROO"] .. "/" .. self.COREFOLDER)
					p, o, s = self.obj.ensureFolder(self.comp[k]["ROO"], self.COREFOLDER, "Auto-generated performance data folder for Core servers of system '"  .. k .. "'")
					if not validobject(o) then error("Core root data folder for '" .. k .. "' could not be created/validated") end
					self.env:debug("FOLDER VALIDATED", p .. " " .. s)
					for kk,vv in pairs(v["CORES"]) do
						self.env:debug("FOLDER", p .. "/" .. "_" .. kk)
						p, o, s = self.obj.ensureFolder(p, "_" .. kk, "Auto-generated performance data folder for Core server '" .. kk .. "' of system '"  .. k .. "'", vv)
						if not validobject(o) then error("Core server data folder for '" .. kk .. "' could not be created/validated") end
						self.env:debug("FOLDER VALIDATED", p .. " " .. s)
						if nil == self.comp[k]["CORES"][kk]["ROO"] then self.comp[k]["CORES"][kk]["ROO"] = p end
						self.ensureCoreDataObjects(self, k, kk)
						if 0 ~= self.connectorcount(self, k, kk) then
							self.env:debug("FOLDER", self.comp[k]["CORES"][kk]["ROO"] .. "/" .. self.CONNECTORFOLDER)
							p, o, s = self.obj.ensureFolder(self.comp[k]["CORES"][kk]["ROO"], self.CONNECTORFOLDER, "Auto-generated performance data folder for Connector servers of Core server '" .. kk .. "' of System '"  .. k .. "'")
							if not validobject(o) then error("Connector server data folder for Core server '" .. kk .. "' of system '" .. k .. "' could not be created/validated") end
							self.env:debug("FOLDER VALIDATED", p .. " " .. s)
							for kkk,vvv in pairs(vv["CONNS"]) do
								local pc
								self.env:debug("FOLDER", p .. "/" ..  "_" .. kkk)
								pc, o, s = self.obj.ensureFolder(p, "_" .. kkk, "Auto-generated performance data folder for Connector server '" .. kkk .. "' of Core server '" .. kk .. "' of System '"  .. k .. "'", vvv)
								self.env:debug("FOLDER VALIDATED", pc .. " " .. s)
								if nil == pc or "" == pc then error("ensureFolder returned nil or empty path") end
								if not validobject(o) then error("Connector server data folder for '" .. kkk .. "' could not be created/validated") end
								if nil == self.comp[k]["CORES"][kk]["CONNS"][kkk]["ROO"] then self.comp[k]["CORES"][kk]["CONNS"][kkk]["ROO"] = pc end
								self.ensureConnectorDataObjects(self, k, kk, kkk)
							end
						end
					end
				end
			end
		end,
		
		updKpiTree = function(self)
			local t = { }
			-- search all objects prefixed with _prfkpi in the actual connector root path
			for obj in self.ess.iotree(self.mondef["P"], true, true, "_prfkpi", { "MODEL_CLASS_HOLDERITEM" }) do
				local tk = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyName")
				local tv = inmation.getvalue(obj:path() .. ".CustomOptions.CustomProperties.CustomPropertyValue")
				if #tk ~= #tv then error("Key-value list for KPI assignment uneven for object=" .. obj:path() .. " k=" .. #tk .. " v=" .. #tv) end
				local kpiname = obj.ObjectName:sub(9)
				local folder = obj:parent()
				
				-- create a simplified key-value list from the two lists
				local tx = { }
				for n = 1, #tk do
					if not tk[n]:find("KPI_") then error("Key is not a KPI_ key") end
					tx[tk[n]:sub(5)] = tv[n]
				end
				
				-- find out what source and type this is
				local srcobj = inmation.getobject(tx["Source"])
				if not validobject(srcobj) then error("KPI source object not valid") end
				local srcpath, srcname = inmation.splitpath(srcobj:path())
				
				-- set the description
				local desc = ""
				local comptype = ""
				if "MODEL_CLASS_CONNECTOR" == srcobj:type() then
					comptype = "connector"
				elseif "MODEL_CLASS_CORE" == srcobj:type() then
					comptype = "core"
				elseif "MODEL_CLASS_SYSTEM" == srcobj:type() then
					comptype = "system"
				end
				if 0 < #comptype then
					local readable = ""
					desc = "The __TBASE__ __TYPE__ '" .. tx["Category"] .. "'-KPI for the " .. comptype .. " object '" .. srcname .. "'"
					local posdot = kpiname:find("%.")
					if nil ~= posdot then
						local xt = kpiname:sub(posdot+1):upper()
						if "AVG" == xt then
							readable = "average"
						elseif "MAX" == xt then
							readable = "maximum"
						elseif "PCT" == xt then
							readable = "percentage"
						else 
							readable = "unknown"
						end
					else
						readable = "calculated"
					end
					desc = desc:gsub("__TYPE__", readable)
					readable = ""
					local posspc = (#kpiname - kpiname:reverse():find("%s")) + 1
					if nil ~= posspc then
						local xt = ""
						if nil ~= posdot and posdot > posspc then
							xt = kpiname:sub(posspc+1, posdot-1):upper()
						else
							xt = kpiname:sub(posspc+1):upper()
						end
						if "24H" == xt then
							readable = "rolling 24-hour"
						elseif "1H" == xt then
							readable = "rolling hour"
						elseif "1M" == xt then
							readable = "rolling minute"
						end
					end
					desc = desc:gsub("__TBASE__", readable)
				end
				
				-- create the KPI
				local kpipath = tx["Path"]
				local cat = tx["Category"]:upper()
				
				-- parametrize it
				local settings = { }
				
				settings["ObjectDescription"] = desc
				settings["AggregateSelection"] = "AGG_TYPE_RAW"				
				settings["DisplayOrder"] = tonumber(tx["DisplayOrder"])
				settings["KpiDisplayFormats.DisplayFormat"] = "NUM_ENG_UNIT"

				-- the default settings for the categories
				if "QOS" == cat or "AVAILABILITY" == cat then
					settings["EngineeringUnit"]   					= "%"
					settings["KpiDisplayFormats.EngineeringUnit"]   = "%"
					settings["KpiLimits.KpiMax"] 					= 100.0
					settings["KpiLimits.KpiTarget"] 				= 98.0
					settings["KpiLimits.KpiL"] 						= 95.0
					settings["KpiLimits.KpiLL"] 					= 90.0
					settings["KpiLimits.KpiLLL"]					= 75.0
					settings["KpiLimits.KpiMin"] 					= 0.0
				elseif "NETWORKLAG" == cat then
					settings["EngineeringUnit"]   					= "ms"
					settings["KpiDisplayFormats.EngineeringUnit"]   = "ms"
					settings["KpiLimits.KpiMax"] 					= 10000.0
					settings["KpiLimits.KpiHHH"] 					= 5000.0
					settings["KpiLimits.KpiHH"] 					= 2500.0
					settings["KpiLimits.KpiH"]						= 1000.0
					settings["KpiLimits.KpiTarget"] 				= 150.0
					settings["KpiLimits.KpiMin"] 					= 0.0
				elseif "DATACOMPRESSION" == cat then
					settings["EngineeringUnit"]   					= "%"
					settings["KpiDisplayFormats.EngineeringUnit"]   = "%"
					settings["KpiLimits.KpiMax"] 					= 100.0
					settings["KpiLimits.KpiTarget"] 				= 50.0
					settings["KpiLimits.KpiL"] 						= 35.0
					settings["KpiLimits.KpiLL"] 					= 25.0
					settings["KpiLimits.KpiLLL"]					= 10.0
					settings["KpiLimits.KpiMin"] 					= 0.0
				end
				
				settings["Location.LocationStrategy"] = "LOC_STRAT_STATIC"
				settings["Location.LocationName"] = folder.Location.LocationName
				settings["Location.Latitude"] = folder.Location.Latitude
				settings["Location.Longitude"] = folder.Location.Longitude
				
				settings["ProcessValueLink"] = obj:path()
		
				--error(kpipath .. "/" .. kpiname)
				self.kpi.ensureKPI(kpipath .. "/" .. kpiname, settings, true)
				
				local kpiobj = inmation.getobject(kpipath .. "/" kpiname)
				if validobject(kpiobj) then
					local location = { LOC=folder.Location.LocationName, LON=folder.Location.Longitude, LAT=folder.Location.Latitude, ALT=0 }
					self.obj.updLocation(kpiobj, location)
					self.obj.updLocation(kpiobj:parent(), location)
				end
			end
		end
	}
}

return slfmonLib
