-- File parsing support
-- (c) 2016 inmation Software GmbH, free to use/modify for anyone
-- Author: timo.klingenmeier@inmation.com
-- Version 1.1 
-- Date 2016-08-15

parseLib = {

	stringLib,

	-- the MemTable reads a file into a memory table (like a worksheet)
	MemTable = {
		ioLib,			--	=> reference to the io libary (standard)
		sLib,			--	=> reference to the string library (inmation)
		st,				--	=> support table (to be provided by main script using setsupported() before using any other function)
		errs = { },		-- 	=> last error stack
		th = { },		-- 	=> header table
		columns = { },	--	=> the column names
		units = { },	--	=> the optional units in the column names	
		td = { },		-- 	=> data table
		sep = nil,		--	=> separator
		maxhdrcnt = 0,	-- 	=> number of lines counted as header
		detected = nil,	--	=> the detected ordinal number
		category = nil,	--	=> the detected file category
		readable = nil,	--	=> the detected readable name
		usecase = nil,	--	=> the detected use casee name
		app = nil,		--	=> the detected application	
		quoted = false,	--	=> whether or not fields are quoted
		asc = false,	--	=> ascending time stamps expected	
		tcorr = 0,		-- 	=> time correction mode
		tcols = nil,	-- 	=> applies to which columns
		ncols = nil,	--	=> numeric columns
		byear = 0,		--	=> base year, can be set by the calling script
		lyear = 0,		--	=> helper value for time correction	
		lmonth = 0,		--	=> helper value for time correction
		lday = 0,		--	=> helper value for time correction
		relaxed = true,	-- 	=> hint for failed conversions
		
		-- MemTable:err
		-- stores most recent error on stack and can return nil to the caller
		-- serr 			=> string to store
		err = function(self, serr)
			local s = inmation.gettime(inmation.now())
			s = s .. "; " .. serr
			table.insert(self.errs, s)
			return nil
		end,

		-- MemTable:reseterr
		-- clears error table
		reseterr = function(self)
			errs = { }
		end,

		-- MemTable:ensure
		-- ensures the minimal runtime environment
		ensure = function(self)
			if nil == parseLib.stringLib then 
				parseLib.stringLib = require"inmation.String"
			end	
			self.sLib = parseLib.stringLib
			if nil == self.sLib then self.err(self, "function ParseLib.MemTable.ensure; could not find inmation.String library"); return false end 
			self.ioLib = require"io"
			if nil == self.ioLib then self.err(self, "function ParseLib.MemTable.ensure; could not load io library"); return false end 
			return true
		end,
		
		-- MemTable:setbaseyear
		-- can be set by the calling script as a hint to define the "base year" of the data
		setbaseyear = function(self, val)
			self.byear = val
		end,

		-- MemTable:setsupported
		-- takes an array of supported text file definitions
		setsupported = function(self, supporttable)
			if "table" ~= type(supporttable) then self.err(self, "function ParseLib.MemTable.setsupported; wrong type of supporttable"); return false end 
			self.st = supporttable
			return true
		end,
		
		-- MemTable:parseheader
		-- parses header lines
		-- fn 				=> file name
		-- hdcnt 			=> number of header lines
		parseheader = function(self, ln)
			if not self.ensure(self) then self.err(self, "function ParseLib.MemTable.parseheader; ensure failed"); return false end 
			if 1 == self.lncnt then
				for i = 1, #self.st do
					
					self.sep = self.sLib.guess_separator(ln, self.st[i]["col"]-1, true)
					if nil ~= self.sep then
						--error("Line: <" .. ln .. ">")
						self.columns = self.sLib.split(ln, self.sep)
						local colmatch = true
						for n = 1, #self.st[i]["con"] do
							if self.columns[n] ~= self.st[i]["con"][n] then
								if 5 == i then
									--local sxx = "Here #" .. n .. " File:" .. self.columns[n] .. " Def:" .. self.st[i]["con"][n]
									--error(sxx)
									--error("Def5: " .. n .. " Col: " .. self.columns[n])
								end
								colmatch = false
							end
							if not colmatch then break end
						end
						if colmatch then
							if nil ~= self.st[i]["uni"] then
								self.columns, self.units = self.sLib.extr(self.columns, self.st[i]["uni"])
							end
							self.quoted = self.st[i]["quo"]
							self.detected = self.st[i]["ord"]
							self.category = self.st[i]["cat"]
							self.readable = self.st[i]["nam"]
							self.usecase = self.st[i]["use"]
							self.app = self.st[i]["app"]
							self.tcorr = self.st[i]["tcm"]
							self.tcols = self.st[i]["tco"]
							self.ncols = self.st[i]["num"]
							self.asc = self.st[i]["asc"]
							self.maxhdrcnt = self.lncnt
							return true
						end
					end
				end
				self.err(self, "function ParseLib.MemTable.parseheader; support tables not matched at all")				
				return false
			else
				if "string" ~= type(self.sep) or 0 == #self.sep then self.err(self, "function ParseLib.MemTable.parseheader; lncnt=" .. self.lncnt .. "; separator not set"); return false end 
			end
			self.maxhdrcnt = self.lncnt
			return true
		end,
		
		-- MemTable:getname
		-- returns the detected readable name
		getname = function(self)
			return self.readable
		end,
		-- MemTable:getuc
		-- returns the detected use case
		getuc = function(self)
			return self.usecase
		end,
		-- MemTable:getapp
		-- returns the detected app name
		getapp = function(self)
			return self.app
		end,
		
		
		-- MemTable:parsedata
		-- parses header lines
		-- fn 				=> file name
		-- hdcnt 			=> number of header lines
		parsedata = function(self, ln)
			if not self.ensure(self) then self.err(self, "function ParseLib.MemTable.parseheader; ensure failed"); return false end 
			if "string" ~= type(self.sep) or 0 == #self.sep then self.err(self, "function ParseLib.MemTable.parsedata; lncnt=" .. self.lncnt .. "; separator not set"); return false end 
			if "string" ~= type(ln) then self.err(self, "function ParseLib.MemTable.parsedata; lncnt=" .. self.lncnt .. "; invalid line type (" .. type(ln) .. ")"); return false end 
			local t = self.sLib.splitex(ln, self.sep, self.quoted)
			local idx = self.lncnt - self.maxhdrcnt
			self.td[idx] = t
			return true
		end,

		-- MemTable:corrtimefield
		-- corrects various time formats to standard ISO8601
		-- data 			=> data field
		-- line 			=> line number
		corrtimefield = function(self, data, line, linec)
			local F = "error in function ParseLib.MemTable.corrtimefield: "
			local r = data
			if nil == r or (0 == #r) then
				return "<empty>"
			end
			if nil == self.tcorr then return r end
			local year
			local mont
			local mons
			local day
			local hour
			local minu
			local seco
			local frac
			local am = false
			local pm = false
			
			-- conversion strategy #1 is from "HH::MM AM/PM, DD MMM" without a year
			if 1 == self.tcorr then
				seco = 0
				frac = 0
				hour = tonumber(data:sub(1,2))
				minu = tonumber(data:sub(4,5))
				day = tonumber(data:sub(11,12))
				-- month business
				mons = data:sub(14,16):upper()
				if "JAN" == mons then mont = 1
				elseif "FEB" == mons then mont = 2
				elseif "MAR" == mons then mont = 3
				elseif "APR" == mons then mont = 4
				elseif "MAY" == mons then mont = 5
				elseif "JUN" == mons then mont = 6
				elseif "JUL" == mons then mont = 7
				elseif "AUG" == mons then mont = 8
				elseif "SEP" == mons then mont = 9
				elseif "OCT" == mons then mont = 10
				elseif "NOV" == mons then mont = 11
				elseif "DEC" == mons then mont = 12
				end
				-- $BUGBUG fix this
				if 19 > #data then
					-- first, overwrite missing year with current UTC year
					year = inmation.gettimeparts(inmation.currenttime())
					-- second, check whether there is a valid base year
					if 2000 < self.byear then
						year = self.byear
					end
					-- third, check for a roll-over to a smaller month in an ascending file
					if self.asc and (0 < self.lmonth) and (self.lmonth > mont) and (1 == mont) then
						--error("line: " .. line .. " lmonth:" .. self.lmonth .. " mont:" .. mont)
						if 2000 < self.lyear then
							year = self.lyear + 1
						end
					end
				else
					year = tonumber(data:sub(18))
				end

			-- conversion strategy #2 is from "M/D/YYYY H:M AM/PM" (12-hour clock) or "M/D/YYYY H:M" (24-hour clock)
			elseif 2 == self.tcorr then
				local rex = '([^/%s:]+)'
				local n = 1
				for x in data:gmatch(rex) do
					if 1 == n then mont = tonumber(x)
					elseif 2 == n then day = tonumber(x)
					elseif 3 == n then year = tonumber(x)
					elseif 4 == n then hour = tonumber(x)
					elseif 5 == n then minu = tonumber(x)
					elseif 6 == n then
						if "AM" == x then
							am = true
						elseif "PM" == x then
							pm = true
						else
							return self.err(self, F .. "expected AM/PM for mode (" .. self.tcorr .. ") in field #6, got '" .. x .. "'")
						end
					else
						return self.err(self, F .. "invalid number of time fields for mode (" .. self.tcorr .. ")")
					end
					n = n + 1
				end
				seco = 0
				frac = 0
				
			-- conversion strategy #3 is from "YYYY-MM-DD HH:mm" (ISO-near)
			elseif 3 == self.tcorr then
				local posix
				data = data .. ":00.000Z"
				data = data:gsub("%s", "T")
				--error("test: " .. test .. " Line: " .. linec)
				posix = inmation.gettime(data)
				r = inmation.gettime(posix)
				return r
			else
				return self.err(self, F .. "invalid time correction mode specified (" .. self.tcorr .. ")")
			end
			
			-- test the integrity, depending on how relaxed we are put a zero posix date in the table or throw
			local good = true
			if "number" ~= type(year) or (0 == year) then good = false end
			if "number" ~= type(mont) or (1 > mont) or (12 < mont) then good = false end
			if "number" ~= type(day) or (1 > day) or (31 < day) then good = false end
			if "number" ~= type(hour) or (23 < hour) then good = false end
			if "number" ~= type(minu) or (59 < minu) then good = false end
			if "number" ~= type(seco) or (59 < seco) then good = false end
			if "number" ~= type(frac) or (999 < frac) then good = false end
			
			if not good then
				if self.relaxed then
					return "1970-01-01T00:00:00.000Z"
				else
					return self.err(self, F .. "time correction error, given data=" .. data)
				end
			end
			
			-- correct two-digit years
			if 100 > year then year = year + 2000 end
			
			-- let inmation see the thing as ISO
			local s = string.format("%04d-%02d-%02dT%02d:%02d:%02d.%03dZ", year, mont, day, hour, minu, seco, frac)
			
			-- and retrieve the POSIX value back
			local posix = inmation.gettime(s)
			
			-- correction #1 AM/PM
			if "AM" == data:sub(7,8) then
				if 12 == hour then
					posix = posix - 12 * 60 * 60 * 1000
				end
			elseif "PM" == data:sub(7,8) then
				if 12 ~= hour then
					posix = posix + 12 * 60 * 60 * 1000
				end
			end
				
			-- next correction UTC conversion
			-- $BUG$BUG implement!		
			
			-- result is a proper ISO timestamp
			r = inmation.gettime(posix)
			
			-- save the recent date
			self.lyear = year
			self.lmonth = mont
			self.lday = day
			
			return r
		end,

		-- MemTable:corrtime
		-- corrects all datetime fields which are loaded in memory according to the actual schema 
		corrtime = function(self, line)
			if nil ~= self.tcols then
				for n = 1, #self.tcols do
					self.lyear = 0
					self.lmonth = 0
					self.lday = 0
					local idx = self.tcols[n]
					for nn = 1, #self.td do
						self.td[nn][idx] = self.corrtimefield(self, self.td[nn][idx], nn)
					end
				end
			end
		end,
		
		-- MemTable:corrnumfield
		-- corrects numerical fields
		-- data 			=> data field
		-- line 			=> line number
		corrnumfield = function(self, data, line)
			return data:gsub("%,", "")
		end,
		
		-- MemTable:corrtime
		-- corrects all datetime fields which are loaded in memory according to the actual schema 
		corrnum = function(self)
			if nil ~= self.ncols then
				for n = 1, #self.ncols do
					local idx = self.ncols[n]
					for nn = 1, #self.td do
						self.td[nn][idx] = self.corrnumfield(self, self.td[nn][idx], nn)
					end
				end
			end
		end,
		
		-- MemTable:loadf
		-- load a text file into memory according to the options given
		-- fn 				=> file name
		-- hdcnt 			=> number of header lines
		loadf = function(self, fn, hdcnt)
			if not self.ensure(self) then self.err(self, "function ParseLib.MemTable.parseheader; ensure failed"); return false end 
			local f = self.ioLib.open(fn)
			if nil == f then self.err(self, "function ParseLib.MemTable.loadf; file '" .. fn .. "' could not be opened"); return false end
			self.lncnt = 0
			for ln in f:lines() do
				self.lncnt = self.lncnt + 1
				if self.lncnt <= hdcnt then
					if not self.parseheader(self, ln) then self.err(self, "function ParseLib.MemTable.loadf; parseheader failed"); return false end
				else
					if not self.parsedata(self, ln) then self.err(self, "function ParseLib.MemTable.loadf; parsedata failed"); return false end
				end
			end
			if 0 ~= self.tcorr then
				self.corrtime(self)
			end
			if nil ~= self.ncols then
				self.corrnum(self)
			end
			f:close()
			return true
		end,
		
		rowcnt = function(self)
			return #self.td
		end,
		
		fieldcnt = function(self, row)
			if nil == self.td[row] then return 0 end
			return #self.td[row]
		end,
		
		-- MemTable:datarow
		-- returns a single row as a key-value list of field names (column headers) and field content
		datarow = function(self, row)
			if nil == self.td[row] then return nil end
			local r = { }
			for n=1, #self.td[row] do
				r[self.columns[n]] = self.td[row][n]
			end
			return r
		end,
		
		getunits = function(self)
			local r = { }
			for n=1, #self.columns do
				r[self.columns[n]] = self.units[n]
			end
			return r
		end,
		
		plainrow = function(self, row)
			return self.td[row]
		end,
		
		-- MemTable:foreachRow
		-- calls a callback routine scrolling down the table
		foreachRow = function(self, cb)
			for n = 1, #self.td do
				local res = cb(self.datarow(self, n), self.getunits(self), self.usecase, self.app)
				if not res then return false end
			end
			return true
		end,
		
		-- MemTable:dispose
		-- frees all memory 
		dispose = function(self)
			self.st = nil
			self.errs = { }
			self.th = { }
			self.columns = { }
			self.units = { }
			self.td = { }
			self.sep = nil
			self.maxhdrcnt = 0
			self.detected = nil
			self.category = nil
			self.readable = nil	
			self.usecase = nil
			self.app = nil                     
			self.quoted = false
			self.asc = false	
			self.tcorr = 0
			self.tcols = nil
			self.ncols = nil
			self.byear = 0
			self.lyear = 0	
			self.lmonth = 0
			self.lday = 0
			self.relaxed = true
			self.reseterr(self)
		end
	}
}
return parseLib
