FieldDeviceLib = {
	
	Device = {
		SUPPORTED = {{ order=1, vendor="SAMSON", input="FILE", origin="TROVIS", sepcount=41 }},
		detected = nil,
		separator = nil,
		columns = { },
		units = { },
		
		detect = function(self, s)
			self.separator = nil
			if nil == self.separator then
				local sLib = require"inmation.String"
				for i = 1, #self.SUPPORTED do
					self.separator = sLib.guess_separator(s, self.SUPPORTED[i]["sepcount"], true)
					if nil ~= self.separator then
						self.detected = self.SUPPORTED[i]["order"]
						self.columns = sLib.split(s, self.separator)
						if "SAMSON" == self.vendor(self) then
							self.columns, self.units = sLib.extr(self.columns, "%[(.-)%]")
						end
						return true
					end
				end
			end
			return false
		end,
		vendor = function(self)
			if nil == self.detected then return nil end
			for i = 1, #self.SUPPORTED do
				if self.detected == self.SUPPORTED[i]["order"] then
					return self.SUPPORTED[i]["vendor"]
				end
			end
			return nil
		end,
		origin = function(self)
			if nil == self.detected then return nil end
			for i = 1, #self.SUPPORTED do
				if self.detected == self.SUPPORTED[i]["order"] then
					return self.SUPPORTED[i]["origin"]
				end
			end
			return nil
		end,
		getcolcnt = function(self)
			if nil == self.detected then return nil end
			for i = 1, #self.SUPPORTED do
				if self.detected == self.SUPPORTED[i]["order"] then
					return self.SUPPORTED[i]["sepcount"] + 1
				end
			end
			return nil
		end,
		field = function(self, t, fld)
			local idx = 0
			for i=1, #self.columns do
				if self.columns[i]:upper() == fld:upper() then
					idx = i
					break
				end
			end
			if idx ~= 0 then
				return t[idx], idx
			else
				return nil
			end
		end,
		ismultiline = function(self, str)
			if "SAMSON" == self.vendor(self) then
				local sLib = require"inmation.String"
				local t = sLib.splitex(str, self.separator)
				if 21 > #t then return true end
			end
			return false
		end,
		getid = function(self, str)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			if #t ~= self.getcolcnt(self) then
				local ess = require"inmation.Essentials"
				local env = ess.Env
				env:debug("PROBLEM", t)
				--error("column count mismatch:" .. #t)
			end
			local id, num = self.field(self, t, "ID#")	
			local cont = nil ~= id and 0 < #id
			return id, cont, num
		end,
		gettime = function(self, ztime, offs)
			local dx, hx, mx, secx = self.splitophours(self, offs)
			--error("Values: dx=" .. dx .. " hx=" .. hx .. " mx=" .. mx .. " sx=" .. secx)
			local posix = (secx * 1000) + (mx * 60 * 1000) + (hx * 60 * 60 * 1000) + (dx * 24 * 60 * 60 * 1000)
			posix = ztime + posix
			local sqlt = inmation.gettime(posix)
			sqlt = sqlt:gsub("T", " ")
			sqlt = sqlt:gsub("%.(.-)Z", "")
			return posix, sqlt
		end,
		getvalue = function(self, str, id)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if nil ~= id then if xid ~= id then error("Value ident does not match:" .. xid) end end
			local name, num2 = self.field(self, t, "Name")
			local val, num3 = self.field(self, t, "ProcessedValue")
			local unit, num4 = self.field(self, t, "Unit")
			local help, num5 = self.field(self, t, "HelpText")
			return tostring(xid), name, tostring(val), unit, help
		end,
		getcyclecount = function(self, str, f1, f2, f3)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, f1)
			local x2, num = self.field(self, t, f2)
			local x3, num = self.field(self, t, f3)
			return x1, x2, x3
		end,
		getvalvepositions = function(self, str, f1, f2, f3)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, f1)
			local essLib = require"inmation.Essentials"
			local env = essLib.Env
			env:debug("VALVE", t)
			if nil == x1 then error(f1 .. " did not match in the given line (#t=" .. #t .. ")") end
			local x2, num = self.field(self, t, f2)
			if nil == x2 then error(f2 .. " did not match in the given line (#t=" .. #t .. ")") end
			local x3, num = self.field(self, t, f3)
			if nil == x3 then error(f3 .. " did not match in the given line (#t=" .. #t .. ")") end
			return x1, x2, x3
		end,
		splitophours = function(self, orgh)
			local pos = orgh:find("%.")
			local opos = 1
			local dx = 0
			if nil ~= pos then 
				dx = tonumber(orgh:sub(1, pos - 1))
				opos = pos + 1
			end	
			pos = orgh:find("%:", opos)
			if nil == pos then error("Operation hours do not contain first ':' character") end
			local hx = tonumber(orgh:sub(opos, pos - 1))
			opos = pos + 1
			pos = orgh:find("%:", opos)
			if nil == pos then error("Operation hours do not contain second ':' character") end
			local mx = tonumber(orgh:sub(opos, pos - 1))
			opos = pos + 1
			local sx = tonumber(orgh:sub(opos))
			return dx, hx, mx, sx
		end,
		getophours = function(self, str, id, basetime)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("Operation hours ident does not match:" .. xid) end
			local orgx, num = self.field(self, t, "ProcessedValue")
			local dx, hx, mx, secx = self.splitophours(self, orgx)
			--error("Values: dx=" .. dx .. " hx=" .. hx .. " mx=" .. mx .. " sx=" .. secx)
			local posix = (secx * 1000) + (mx * 60 * 1000) + (hx * 60 * 60 * 1000) + (dx * 24 * 60 * 60 * 1000)
			local abstime = basetime - posix
			local absiso = inmation.gettime(abstime)
			return orgx, posix, abstime, absiso
		end,
		getmessage = function(self, str, id)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("Message ident does not match: " .. xid .. " (given " .. id ..")") end
			local msgs, snum = self.field(self, t, "Name")
			msgs = msgs:match("%((.-)%)")
			local msg, num = self.field(self, t, "ProcessedValue")
			return msgs, msg -- sequence number, message text
		end,
		getmessagetime = function(self, str, id, ztime)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("Message time ident does not match: " .. xid .. " (given " .. id ..")") end
			local tim, num = self.field(self, t, "ProcessedValue")
			local posix, sqlt = self.gettime(self, ztime, tim)
			return posix, sqlt
		end,
		getendpos = function(self, str, id)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("End pos ident does not match: " .. xid .. " (given " .. id ..")") end
			local name, nnum = self.field(self, t, "Name")
			local seq = name:match("Messpunkt%s(.*)")
			local pos, num = self.field(self, t, "ProcessedValue")
			return seq, pos
		end,
		getendpostime = function(self, str, id, ztime)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("End pos time ident does not match: " .. xid .. " (given " .. id ..")") end
			local tim, num = self.field(self, t, "ProcessedValue")
			local posix, sqlt = self.gettime(self, ztime, tim)
			return posix, sqlt
		end,
		getendposspeed = function(self, str, id)
			local sLib = require"inmation.String"
			local t = sLib.splitex(str, self.separator)
			local x1, num = self.field(self, t, "ID#")
			local xid = tonumber(x1)
			if xid ~= id then error("End pos speed ident does not match: " .. xid .. " (given " .. id ..")") end
			local speed, num = self.field(self, t, "ProcessedValue")
			return speed
		end,
		
		isdir = function(self, str)
		end,
		
	}
	
}
return FieldDeviceLib