-- inmationEssentials
-- Tool Functions and Standard Script Environment
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

	-- global functions

	-- conditional return
	function iif(cond, yes, no)
		if cond then return yes else return no end
	end
	
	function pconcat(path, name, validate)
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
		return op, iif(validate, nil ~= inmation.obj(op), nil)
	end

	-- valid inmation object
	function validobject(objorpath)
		if "string" == type(objorpath) then
			local o = inmation.obj(objorpath)
			return "table" == type(o) -- and "string" == o.ObjectName end (requires consistency on ObjectName)
		elseif "table" == type(objorpath) then
			local p = objorpath:path()
			return "string" == type(p) and 0 < #p
		else
			return false
		end		
	end
		
	-- checks a string or something else on type and content (may not be empty), recursive on tables
	-- takes: anything, optional string_only omits the boolean result
	-- returns: success, the trimmed string (optional) 
	function validtrimmedstring(s, string_only)
		local sx
		if "number" == type(s) then 
			sx = "" .. s
		elseif "string" == type(s) then
			sx = s
		elseif "table" == type(s) then
			sx = ""
			for n = 1, #s do
				if 1 < n then 
					sx = string.format(sx .. "\t%s", valid_trimmed_string(s[n], true))
				else
					sx = "" .. s[n]
				end
			end 
		end
		-- do we have something which is not a string?
		if "string" ~= type(sx) then 
			if string_only then
				return ""
			else
				return false
			end
		end
		-- final trim
		local st = string.gsub(sx, "^%s*(.-)%s*$", "%1")
		if 0 == #st then 
			-- indicate failure
			if string_only then
				return ""
			else
				return false
			end
		end
		-- what does the user want back?
		if string_only then
			return st
		else
			return true, st
		end
	end

essLib = {	
	-- conditional assignment
	condexp = function(boolexp, iftrue, iffalse)		
		if boolexp then return iftrue else return iffalse end	
	end,	
	-- returns true if a given quality value is either good UA or good COM OPC quality	
	goodquality = function(q)		
		return 0 == q or 0xFFFF00C0 == q
	end,
	-- valid, non-empty string test
	hascontent = function(s)		
		return "string" == type(s) and 0 < #s	
	end,	
	-- valid non-zero number test
	nonzero = function(x)		
		return "number" == type(x) and .0 < x 	
	end,	
	-- current millisecond
	millisecond = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d%d", 21))
	end,	
	-- current second
	second = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d", 18))	
	end,	
	-- current minute
	minute = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d", 15))
	end,
	-- current hour
	hour = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d", 12))	
	end,
	-- current day
	day = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d", 9))
	end,
	-- current month
	month = function(posix)		
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d", 6))
	end,
	-- current year
	year = function(posix)
		local t = posix
		if nil == t then t = inmation.now() end
		return tonumber(string.match(inmation.gettime(t), "%d%d%d%d", 1))
	end,	
	-- searches object types
	searchtype = function(from, typ, down)
		local t = { }
		if nil == down then down = true end
		if down then
			-- search down
			local kids = from:children()
			for n = 1, #kids do
				if typ == kids[n]:type() then
					table.insert(t, kids[n]:path())
					table.insert(t, searchtype(kids[n], typ))
				end
			end	
		else
		-- search up
			local o = from:parent()
			while nil ~= o do
				if typ == o:type() then
					table.insert(t, o:path())
					break
				end
				-- $BUGBUG if we iterate higher, the connector crashes
				if "MODEL_CLASS_SYSTEM" == o:type() then
					break
				end
				o = o:parent()
			end
		end
		return t
	end,
	-- get a particular object on the same level in the tree
	peerobject = function(name, typ)
		local path = inmation.slf():parent():path() .. "/" .. name
		local o = inmation.obj(path)
		if nil ~= o then
			return o
		end
		return nil
	end,
	ensureobject = function(path, otype)
		local o = inmation.obj(path)
		if nil == o then
			local par, nam = inmation.splitpath(path)
			o = inmation.new(par, otype)
			--if not validobject(o) then
				--error("Could not create object")
			--else
				o.ObjectName = nam
				o:commit()
				return o
			--end
		else
			if o:type() == otype then
				return o
			else
				return nil
			end
		end
	end,
	-- carries a property update out only in necessary
	propupdate = function(obj, prp, v)
		if nil == prp then
			p = obj:path()
		else
			p = obj:path() .. "." .. prp
		end
		local x = inmation.get(p)
		if x ~= v then
			inmation.set(p, v)
			return true
		end
		return false
	end,

	-- loads the persistent data for a holder item object, by reading out its persistency buffer
	-- this is a temporar workaround until the system suports it by itself
	loadholder = function(path)
		local loaded = false
		local o = inmation.obj(path)

		-- target object validation
		if not validobject(o) then error("'" .. path .. "' is not a valid object") end
		if "MODEL_CLASS_HOLDERITEM" ~= o:type() then error("'" .. path .. "' is not a HolderItem object") end
		if not o.DataPersistencyOptions.PersistData then return loaded end
		
		-- any data persisted?
		local sx = o.DataPersistencyOptions.PersistBuffer
		if not validtrimmedstring(sx) then return loaded end

		local v,q,t
		local typat = "(!~x=)"
		local vpat = "(!~v=)"
		local qpat = "(!~q=)"
		local tpat = "(!~t=)"
		local ty
		local chpat = "(%a+)"
		local txpat = "(.* !~q=)"
		local nupat = "(%d+)"
		typat, ty = sx:match(typat .. chpat)
		vpat, v = sx:match(vpat .. txpat)
		v = v:sub(1, v:len() - 5) 
		qpat, q = sx:match(qpat .. nupat)
		tpat, t = sx:match(tpat .. nupat)
		if 0 == #ty or 2 < #ty then error("Invalid length of type indication ('" .. ty .. "') in buffer") end
		if "a" == ty:sub(1,1) then
			local t1 = { }
			local s1 = 1
			local p1, p2 = v:find("<!>", s1)
			local tp1 = nil
			if nil == p1 then tp1 = nil else tp1 = p1 - 1 end 
			local sx1 = tp1
			while nil ~= p1 do
				table.insert(t1, sx1)
				s1 = p2 + 1
				p1, p2 = v:find("<!>", s1)
				if nil == p1 then
					sx1 = v:sub(s1)
				else
					sx1 = v:sub(s1, p1 - 1)
				end
			end
			-- insert last element
			table.insert(t1, sx1)
	
			-- transform data types
			if "b" == ty:sub(2,2) then
				local t2 = { }
				for n = 1, #t1 do
					table.insert(t2, "true" == t1[n])
				end
				v = t2
			elseif "r" == ty:sub(2,2) then
				local t2 = { }
				for n = 1, #t1 do
					table.insert(t2, tonumber(t1[n]))
				end
				v = t2
			elseif "s" == ty:sub(2,2) then
				v = t1
			end
		else
			if 1 ~= #ty then error("Invalid non-array type indication ('" .. ty .. "') in buffer") end
			if "b" == ty:sub(1,1) then
				v = 0 ~= tonumber(v)
			elseif "r" == ty:sub(1,1) then
				v = tonumber(v)
			elseif "s" == ty:sub(1,1) then
				-- v = v
			elseif ("n" == ty:sub(1,1)) or ("u" == ty:sub(1,1)) then
				-- v = v (nil)
			else
				error("Invalid type indication character in buffer (" .. sx .. ")")
			end
		end
		inmation.set(o:path(), v, q, t)
		return true, sx
	end,

	-- reads the value from a holder item object, auto-loading from persistency buffer, if required
	-- this is a temporar workaround until the system suports it by itself
	readholder = function(path)
		local v, q, t = inmation.get(path)
		if nil == v and essLib.loadholder(path) then
			v,q,t = inmation.get(path)
		end
		return v,q,t
	end,

	-- write to a holder item object, making sure data can be reloaded from persistency buffer
	-- this is a temporar workaround until the system suports it by itself
	writeholder = function(path, v, q, t)
		local datapersisted = false
		local o = inmation.obj(path)
		if nil == q then q = 0 end
		if nil == t then t = inmation.now() end

		-- target object validation
		if not validobject(o) then error("'" .. path .. "' is not a valid object") end
		if "MODEL_CLASS_HOLDERITEM" ~= o:type() then error("'" .. path .. "' is not a HolderItem object") end

		-- do a regular set and branch out if the holder is not set for persistency
		inmation.set(path, v, q, t)
		if not o.DataPersistencyOptions.PersistData then 
			o.DataPersistencyOptions.PersistData = true
		end

		-- create the standard string for the persisted v, indicating table/simple, type and content
		local sx = ""
		local ty = ""
		if "table" == type(v) then
			ty = "a"

			-- the v type is taken from the first array element, if any
			if 0 < #v then
				if "boolean" == type(v[1]) then
					ty = ty .. "b"
					for n = 1, #v do
						if 1 == n then 
							sx = tostring(v[n])
						else
							sx = sx .. "<!>" .. tostring(v[n])
						end
					end
				elseif "number" == type(v[1]) then
					ty = ty .. "r"
					for n = 1, #v do
						if 1 == n then 
							sx = tostring(v[n])
						else
							sx = sx .. "<!>" .. tostring(v[n])
						end
					end
				elseif "string" == type(v[1]) then
					ty = ty .. "s"
					for n = 1, #v do
						if 1 == n then 
							sx = v[n]
						else
							sx = sx .. "<!>" .. v[n]
						end
					end
				elseif "nil" == type(v[1]) then
					ty = ty .. "n"
				else
					ty = ty .. "u"
				end
			else
				ty = ty .. "e"
			end
		elseif "boolean" == type(v) then
			ty = "b"
			sx = tostring(v)
		elseif "number" == type(v) then
			ty = "r"
			sx = tostring(v)
		elseif "string" == type(v) then
			ty = "s"
			sx = v
		elseif "nil" == type(v) then
			ty = "n"
		end

		-- write to the buffer property
		o.DataPersistencyOptions.PersistBuffer = "!~x=" .. ty .. " !~v=" .. sx .. " !~q=" .. tostring(q) .. " !~t=" .. tostring(t)
		o:commit()

		datapersisted = 0 < #sx
		return datapersisted
	end,

	-- create a reference
	createref = function (trgobj, refobj, refname)
		if not validobject(trgobj) then error("Target object not set or invalid") end
		if not validobject(refobj) then error("Referenced object not set or invalid") end
		if "string" ~= type(refname) or 0 == #refname then error("Reference name invalid") end
		local t = trgobj.refs
		local created = true
		local changed = false
		for n = 1, #t do
			-- ref exists?
			if t[n].path == refobj:path() then
				created = false
				-- under the same name?
				if t[n].name ~= refname then
					-- rename the reference
					changed = true
					t[n].name = refname
				end
			end
		end
		if created then
			table.insert(t, { name = refname, path = refobj:path() } )
		end
		if created or changed then
			trgobj:commit()
		end
		return created, changed
	end,
	-- treewalk in the iotree
	iotree = function(search, dynonly, fullpath, pattern, objects)
		-- initialization
		local patflt = "string" == type(pattern) and 0 < #pattern
		local objflt = "table" == type(objects) and 0 < #objects
		local ot = inmation.find(search, 1, dynonly, fullpath)
		local rt = { }
		local it = 0
		local ie = #ot
		if patflt or objflt then
			for n = 1, ie do
				local pass = true
				if patflt then
					pass = string.match(ot[n]:path(), pattern)
				end
				local objmatch = false
				if pass and objflt then
					for n1 = 1, #objects do
						if objects[n1] == ot[n]:type() then 
							objmatch = true
							break
						end 
					end
				end
				pass = pass and iif(objflt, objmatch, true) 
				if pass then
					table.insert(rt, ot[n])
				end
			end
			ie = #rt
		end
		-- iterator
		return function()
			it = it + 1
			if ie < it then return nil else return iif(patflt or objflt, rt[it], ot[it]) end
		end 
	end,
	-- helper for the objects function
	go = function(from, typ, t, depth, maxdepth)
		depth = depth + 1
		local kids = from:children()
		if #kids > 0 then
			for n = 1, #kids do
				if typ == "*" or typ == kids[n]:type() then
					table.insert(t, kids[n]:path())
				end
				if depth <= maxdepth then
					essLib.go(kids[n], typ, t, depth, maxdepth)
				end
			end	
		end
		depth = depth - 1
	end,
	-- alternative object search by type and limited nesting
	objects = function(types)
		local t = { }
		local it = 0
		for n=1, #types do
			local dep = 0
			local mdep = 4
			if "MODEL_CLASS_SYSTEM" == types[n] then 
				mdep = 1
			elseif "MODEL_CLASS_CORE" == types[n] then
				mdep = 2
			end
			essLib.go(inmation.getobject("/"), types[n], t, dep, mdep)
		end
		-- iterator
		return function()
			it = it + 1
			if #t >= it then return inmation.getobject(t[it]) else return nil end
		end 
	end,
	
	istable = function(x) return "table" == type(x) end,
	isbool = function(x) return "boolean" == type(x) end,
	isnumber = function(x) return "number" == type(x) end,
	isstring = function(x) return "string" == type(x) end,
	isobject = function(x) return essLib.istable(x) and nil ~= x:type() end,
	istimespan = function(x, y) return essLib.isnumber(x) and essLib.isnumber(y) and y > x end,
	
	-- sorted table iterator
	spairs = function(t, order)
		-- collect the keys
		local keys = {}
		for k in pairs(t) do keys[#keys+1] = k end
		-- if order function given, sort by it by passing the table and keys a, b,
	    -- otherwise just sort the keys 
		if order then
			table.sort(keys, function(a,b) return order(t, a, b) end)
		else
			table.sort(keys)
		end

		-- return the iterator function
		local i = 0
		return function()
			i = i + 1
			if keys[i] then
				return keys[i], t[keys[i]]
			end
		end
	end,
	-- inmation.Essentials	-- Env	-- this is a simple execution environment
	Env = {
		calls = 0,
		start = 0,
		time = 0,
		isot = "",
		conn = "",
		relay = "",
		core = "",
		system = "",
		minute = -1,
		hour = -1,
		day = - 1,
		parent_folder = "",
		internals_folder = "",
		intermediates_folder = "",
		summary_folder = "",
		control_folder = "",
		tdebug = { },
		tenv = { },
		tsoft = { },
		entry = function(self)
			self.calls = self.calls + 1
			self.time = inmation.now()
			self.isot = inmation.time(self.time) .. "Z"
			if 1 == self.calls then
				self.start = self.time
				local t = essLib.searchtype(inmation.slf(), "MODEL_CLASS_CONNECTOR", false)
				if 0 ~= #t then
					self.conn = t[1]
				end
				t = essLib.searchtype(inmation.slf(), "MODEL_CLASS_RELAY", false)
				if 0 ~= #t then
					self.relay = t[1]
				end	
				t = essLib.searchtype(inmation.slf(), "MODEL_CLASS_CORE", false)
				if 0 ~= #t then		
					self.core = t[1]
				end	
				t = essLib.searchtype(inmation.slf(), "MODEL_CLASS_SYSTEM", false)
				if 0 ~= #t then
					self.system = t[1]
				end
			end
			if "MODEL_CLASS_DATASOURCE" ~= inmation.slf():type() then
				if 0 == #self.parent_folder then self.parent_folder = inmation.splitpath(inmation.slf():path()) end
			else
				if 0 == #self.parent_folder then self.parent_folder = inmation.slf():path() end
			end
		end,
		systemname = function(self)
			local p, n = inmation.split(self.system)
			return n
		end,
		corename = function(self)
			local p, n = inmation.split(self.core)
			return n
		end,
		ensure = function(self, imed, summ)
			if "MODEL_CLASS_DATASOURCE" ~= inmation.slf():type() then
				if 0 == #self.parent_folder then self.parent_folder = inmation.splitpath(inmation.slf():path()) end
			else
				if 0 == #self.parent_folder then self.parent_folder = inmation.slf():path() end
			end
			if 0 == #self.internals_folder then
				local o = essLib.ensureobject(self.parent_folder .. "/" .. "_Internals", "MODEL_CLASS_GENFOLDER")
				self.internals_folder = o:path()
			end
			if imed and 0 == #self.intermediates_folder then
				local o = essLib.ensureobject(self.parent_folder .. "/" .. "_Intermediates", "MODEL_CLASS_GENFOLDER")
				self.intermediates_folder = o:path()
			end
			if summ and 0 == #self.summary_folder then
				local o = essLib.ensureobject(self.parent_folder .. "/" .. "_Summary", "MODEL_CLASS_GENFOLDER")
				self.summary_folder = o:path()
			end
		end,
		ensureSwitches = function(self, names)
			if "MODEL_CLASS_DATASOURCE" ~= inmation.slf():type() then
				if 0 == #self.parent_folder then self.parent_folder = inmation.splitpath(inmation.slf():path()) end
			else
				if 0 == #self.parent_folder then self.parent_folder = inmation.slf():path() end
			end
			if 0 == #self.control_folder then
				local o = essLib.ensureobject(self.parent_folder .. "/" .. "_Control", "MODEL_CLASS_GENFOLDER")
				self.control_folder = o:path()
			end
			for n=1, #names do
				local o = essLib.ensureobject(self.control_folder .. "/" .. "_Run_" .. names[n], "MODEL_CLASS_HOLDERITEM")
				if nil == inmation.get(o:path()) then essLib.writeholder(o:path(), false) end
				local o = essLib.ensureobject(self.control_folder .. "/" .. "_Executes_" .. names[n], "MODEL_CLASS_HOLDERITEM")
				if nil == inmation.get(o:path()) then essLib.writeholder(o:path(), false) end
			end
		end,
		testSwitches = function(self, names)
			if 0 == #self.control_folder then error ("Control folder not set") end
			local o = inmation.obj(self.control_folder)
			local t = o:children()
			local ton = {}
			for n = 1, #t do
				if t[n]:path():find("_Run_") and true == inmation.getvalue(t[n]:path()) then
					local s = t[n].ObjectName:sub(#("_Run_") + 1)
					if 0 < #s then
						table.insert(ton, s)
					end
				end
			end
			return ton
		end,
		flagExecution = function(self, name, on)
			if 0 == #self.control_folder then error ("Control folder not set") end
			local p = pconcat(self.control_folder, "_Executes_" .. name)
			if not validobject(inmation.getobject(p)) then error("No valid execution flag object for '" .. name .. "'") end
			inmation.setvalue(p, on)
		end,
		testExecution = function(self)
			if 0 == #self.control_folder then error ("Control folder not set") end
			local o = inmation.obj(self.control_folder)
			local t = o:children()
			local ton = {}
			for n = 1, #t do
				if t[n]:path():find("_Executes_") and true == inmation.getvalue(t[n]:path()) then
					return true
				end
			end
			return false
		end,
		resetSwitch = function(self, name)
			if 0 == #self.control_folder then error ("Control folder not set") end
			name = "_Run_" ..name
			local p = pconcat(self.control_folder, name)
			inmation.set(p, false)
		end,
		debug = function(self, label, content)
			if 0 == #self.internals_folder then error("_Internals folder not set. Call env:ensure() before.") end
			local o = essLib.ensureobject(self.internals_folder .. "/" .. "_Debug", "MODEL_CLASS_HOLDERITEM")
			if not validobject(o) then error("'_Debug' target object does not exist") end
			if nil == label or 0 == #label then
				self.tdebug = {}
				inmation.set(o:path(), content)
			elseif nil == content and 0 < #label then
				self.tdebug = {}
				inmation.set(o:path(), label)
			elseif nil == label and nil == content then
				self.tdebug = {}
				inmation.set(o:path(), nil)
			else
				if essLib.istable(content) then
				
					local ts = ""
					for nx = 1, #content do
						if 1 < nx then ts = ts .. ";" end
						ts = ts .. tostring(content[nx])
					end
					self.tdebug[label] = ts
				else
					self.tdebug[label] = tostring(content)
				end
				local t = { }
				for key, value in pairs(self.tdebug) do
					local s = key .. "=" .. value
					table.insert(t, s)
				end
				inmation.set(o:path(), t)
			end
		end,
		softerror = function(self, content)
			if 0 == #self.internals_folder then error("_Internals folder not set. Call env:ensure() before.") end
			local o = essLib.ensureobject(self.internals_folder .. "/" .. "_SoftErrors", "MODEL_CLASS_HOLDERITEM")
			if not validobject(o) then error("'_SoftErrors' target object does not exist") end
			if nil ~= content then
				table.insert(self.tsoft, content)
			end
			inmation.set(o:path(), self.tsoft)
		end,
		ensureholderdata = function(self, rootpath, debugger)
			local n = 0
			if "MODEL_CLASS_DATASOURCE" ~= inmation.slf():type() then
				if 0 == #self.parent_folder then self.parent_folder = inmation.splitpath(inmation.slf():path()) end
			else
				if 0 == #self.parent_folder then self.parent_folder = inmation.slf():path() end
			end
			if 0 == self.calls then error("calls not counted. Call env:entry() before.") end			
			if 1 == self.calls then
				local p = iif(nil == rootpath or 0 == #rootpath, self.parent_folder, rootpath)
				local n1 = 0
				for object in essLib.iotree(p, true, true, nil, { "MODEL_CLASS_HOLDERITEM" }) do
					if nil == inmation.get(object:path()) then
						n1 = n1 + 1
						if nil ~= debugger then debugger("ensureholderdata#" .. n1 .." (loading)", 544, object:path()) end
						if essLib.loadholder(object:path()) then
							n = n + 1
						end
					end
				end
			end
			return n
		end,
		newminute = function(self, full)
			local m = essLib.minute()
			local trig = m ~= self.minute
			self.minute = m
			if full and self.time - self.start < 60 * 1000 then return nil end	
			if trig then return m end
			return nil
		end,
		newhour = function(self, full)			
			local h = essLib.hour()
			local trig = h ~= self.hour
			self.hour = h
			if full and self.time - self.start < 60 * 60 * 1000 then return nil end
			if trig then return h end
			return nil
		end,
		newday = function(self, full)
			local d = essLib.day()
			local trig = d ~= self.day
			self.day = d
			if full and self.time - self.start < 24 * 60 * 60 * 1000 then return nil end
			if trig then return d end
			return nil
		end,
		set = function(self, label, content)
			local lx = "[" .. label .. "]"
			self.tenv[lx] = content
		end,
		get = function(self, label)
			local lx = "[" .. label .. "]"
			return self.tenv[lx]
		end,
		reset = function(self)
			self.tenv = {}
			self.tsoft = { }
			self.softerror(self)
		end,
		debugenv = function(self, label)
			local lx = "[" .. label .. "]"
			self.debug(self, lx, self.tenv[lx])
		end,
		exit = function(self)
			return inmation.now() - self.time
		end	
	}
}

return essLib