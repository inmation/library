-- inmation.Time
-- Time Helpers
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

timeLib = {
	FMT_ISO	= "%04d-%02d-%02dT%02d:%02d:%02d.%03dZ",
	FMT_ISO_NO_MS = "%04d-%02d-%02dT%02d:%02d:%02dZ", 

	isotimestr = function(year, month, day, hour, minute, second, ms)
		local y = 0
		local m = 1
		local d = 1
		local h = 0
		local min = 0
		local s = 0
		local ms = 0
		local noms = false
		if "number" == type(year) then 
			y = year
			if 100 > y then if 75 > y then y = y + 2000 else y = y + 1900 end end
		else
			local s = inmation.tim(inmation.now())
			return s:sub(1,10) .. "T" .. s:sub(12) .. "Z"
		end
		if 1975 > y then error("valid years range from 1975.., given '" .. y .. "'") end
		if "number" == type(month) then 
			m = month
			if 1 > m or 12 < m then error("valid months range from 1..12, given '" .. m .. "'") end
		end
		if "number" == type(day) then 
			d = day
			if 1 > d or 31 < d then error("valid days range from 1..31, given '" .. d .. "'") end
		end
		if "number" == type(hour) then 
			h = hour
			if 0 > h or 23 < h then error("valid hours range from 0..23, given '" .. h .. "'") end
		end
		if "number" == type(minute) then 
			min = minute
			if 0 > min or 59 < min then error("valid minutes range from 0..59, given '" .. min .. "'") end
		end
		if "number" == type(second) then 
			s = second
			if 0 > s or 59 < s then error("valid seconds range from 0..59, given '" .. s .. "'") end
		end
		if "number" == type(millisecond) then 
			ms = millisecond
			if 0 > ms or 999 < ms then error("valid milliseconds range from 0..999, given '" .. ms .. "'") end
		else
			noms = true
		end
		if noms then
			return string.format(timeLib.FMT_ISO_NO_MS, y, m, d, h, min, s)
		else
			return string.format(timeLib.FMT_ISO, y, m, d, h, min, s, ms)
		end
	end,

	posixfromstr = function(timestring, debugger)
		local utc = false
		local s
		if "string" ~= type(timestring) then error("invalid time string") end
		if "Z" == timestring:sub(#timestring) then
			utc = true
			timestring = timestring:sub(1, #timestring - 1)
		end
		timestring = timestring:gsub("T", " ")
		if nil ~= debugger then debugger("posixfromstr", 99, timestring) end
		if nil == timestring:find(".") then
			return inmation.tim(timestring, timeLib.FMT_INM_NO_MS)
		else
			return inmation.time(timestring)
		end
	end,

	isofromposix = function(posix)
		local s = inmation.time(posix)
		s = s:gsub(" ", "T")
		return s
	end,

	parts = function(dt)
		local sdt 
		if "number" == type(dt) then
			sdt = timeLib.isofromposix(dt)		
		elseif "string" == type(dt) then
			sdt = dt
		else
			error("invalid input")
		end
		local y,m,d,h,min,s,ms
		y = tonumber(sdt:sub(1,4))
		m = tonumber(sdt:sub(6,7))
		d = tonumber(sdt:sub(9,10))
		h = tonumber(sdt:sub(12,13))
		if nil == h then h = 0 end
		min = tonumber(sdt:sub(15,16))
		if nil == min then min = 0 end
		s = tonumber(sdt:sub(18,19))
		if nil == s then s = 0 end
		ms = tonumber(sdt:sub(21,23))
		if nil == ms then ms = 0 end
		return y,m,d,h,min,s,ms
	end,
	secsms = function(s)
		return s * 1000
	end,
	minsms = function(m)
		return m * 60 * 1000
	end,
	hoursms = function(h)
		return h * 60 * 60 * 1000
	end,
	daysms = function(d)
		return d * 24 * 60 * 60 * 1000
	end,
	compare = function(t1, t2)
		local n1, n2
		if "string" == type(t1) then n1 = timeLib.posixfromstr(t1) else n1 = t1 end
		if "string" == type(t2) then n2 = timeLib.posixfromstr(t2) else n2 = t2 end
		if "number" ~= type(n1) or "number" ~= type(n2) then error("non-numeric posix timestamps found") end
		if n1 == n2 then return 0 end
		if n1 < n2 then return 2 end
		if n2 < n1 then return 1 end
	end,

	time = {
		posix = 0,
		stack = { },
		init = function(self, x)
			if nil == x then
				self.posix = inmation.now()
			elseif "string" == type(x) then
				self.posix = timeLib.posixfromstr(x)
			elseif "table" == type(x) then
				local xx = inmation.get(x:path())
				if "number" == type(xx) then
					self.posix = xx
				elseif "string" == type(xx) then
					self.posix = timeLib.posixfromstr(xx)
				else 
					error("invalid object content for type conversion ('" .. x .. "')")
				end
			elseif "number" == type(x) then
				self.posix = x
			else 
				error("unsupported init value data type ('" .. type(x) .. "')")
			end
		end,
		iso = function(self)
			return timeLib.isofromposix(self.posix)
		end,
		align = function(self, code, init)
			local y,m,d,h,min,s,ms = timeLib.parts(self.posix)
			local set = -1
			if nil ~= init then
				if "number" ~= type(init) then
					error("Invalid init value ('" .. init .. "')")
				else
					set = init
				end
			end
			if "Y" == code:upper() then
				m = 1; d = 1; h = 0; min = 0; s = 0; ms = 0
				if -1 < set then 
					y = set
				end
			elseif "m" == code then
				d = 1; h = 0; min = 0; s = 0; ms = 0
				if -1 < set then 
					m = set
				end
			elseif "d" == code then
				h = 0; min = 0; s = 0; ms = 0
				if -1 < set then 
					d = set
				end
			elseif "H" == code:upper() then
				min = 0; s = 0; ms = 0
				if -1 < set then 
					h = set
				end
			elseif "M" == code then
				s = 0; ms = 0
				if -1 < set then 
					min = set
				end
			elseif "S" == code:upper() then
				ms = 0
				if -1 < set then 
					s = set
				end
			elseif "F" == code:upper() then
				if -1 < set then 
					ms = set
				end
			else
				error("unrecognized alignment code ('" .. code .. "')")
			end
			local i = timeLib.isotimestr(y,m,d,h,min,s,ms)
			self.posix = timeLib.posixfromstr(i)
			return self.posix
		end,
		advance = function(self, val, code)
			if "number" ~= type(val) or "string" ~= type(code) then error ("invalid advance parameters") end
			local offset = 0
			if "Y" == code:upper() then
			elseif "m" == code then
			elseif "d" == code then
				offset = val * 24 * 60 * 60 * 1000
			elseif "H" == code:upper() then
				offset = val * 60 * 60 * 1000
			elseif "M" == code then
				offset = val * 60 * 1000
			elseif "S" == code:upper() then
				offset = val * 1000
			elseif "F" == code:upper() then
				offset = val
			else
				error("unrecognized alignment code ('" .. code .. "')")
			end
			self.posix = self.posix + offset
			return self.posix
		end,
		push = function(self)
			self.stack[#self.stack + 1] = self.posix
		end,
		pop = function(self)
			if 0 == #self.stack then error ("nothing to pop on stack") end
			self.posix = self.stack[#self.stack]
			self.stack[#self.stack] = nil
		end
	}
}

return timeLib