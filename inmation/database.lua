-- inmation.database
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20160925.1   Initial release.
--
-- Information about luasql.odbc library:
-- http://www.tutorialspoint.com/lua/lua_database_access.htm
--

local dbLib = {
	-- conditional assignment
	iif = function(boolexp, iftrue, iffalse)
		if boolexp then return iftrue else return iffalse end
	end,

	db = {
		driver = nil,
		env = nil,
		con = nil,
		src = "",
		name = "",
		usr = "",
		pwd = "",
		cursors = { },
		opentime = 0,
		set = function(self, src, name, usr, pwd)
			self.src = src
			self.name = name
			self.usr = usr
			self.pwd = pwd
		end,

		setname = function(self, name)
			self.name = name
		end,

		open = function(self)
			self.driver = require"luasql.odbc"
			local x = inmation.now()
			self.env = self.driver:odbc()
			self.con = self.env:connect(self.src, self.usr, self.pwd)
			self.opentime = inmation.now() - x
			return nil ~= self.driver and nil ~= self.env and nil ~= self.con
		end,

		close = function(self)
			local n = #self.cursors
			while 0 < n do
				self.cursors[n]:close()
				n = n - 1
			end
			self.cursors = { }
			if nil ~= self.con then self.con:close() end
			if nil ~= self.env then self.env:close() end
		end,

		insert = function(self, insert_statement)
			if self.env == nil then error("Invalid database environment") end
			if self.con == nil then error("Invalid database connection") end
			local status, errorString = assert(self.con:execute(insert_statement))
			return status, errorString
		end,

		-- DEPRECATED: Use 'execute' which also works with insert and update statements.
		rows = function(self, sql_statement)
			if self.env == nil then error("Invalid database environment") end
			if self.con == nil then error("Invalid database connection") end
			table.insert(self.cursors, assert(self.con:execute(sql_statement)))
			return function ()
				return self.cursors[#self.cursors]:fetch()
			end
		end,

		execute = function(self, sql_statement, callback)
			if self.env == nil then error("Invalid database environment") end
			if self.con == nil then error("Invalid database connection") end
			local res = assert(self.con:execute(sql_statement))
			if type(res) ~= "number" and nil ~= res.fetch then
				-- Result is a cursor
				local cur = res
				-- Store cursor so it can be closed later
				table.insert(self.cursors, cur)
				if type(callback) == 'function' then
					-- Invoke callback function for every row
					local row = cur:fetch ({}, "a")
					local rowcount = 0
					while row do
						rowcount = rowcount + 1
						callback(row)
						-- reusing the table of results
						row = cur:fetch (row, "a")
					end
					return rowcount
				else
					-- Return function to fetch the rows
					return function ()
						return cur:fetch()
					end
				end
			else
				-- Result is number of rows affected
				return res
			end
		end,

		closecursor = function(self)
			local i = #self.cursors
			if 0 < i then
				self.cursors[i]:close()
				self.cursors[i] = nil
			end
		end,

		numberofopencursors = function(self)
			return #self.cursors
		end,

		-- assembles table names correctly

		sqltable = function(self, name)
			return self.name .. "." .. name
		end,

		sqlfield = function(_, dbtable, field)
			return dbtable .. "." .. field
		end,

		-- assembles SQL field names correctly with a NULL replacement option
		sqlfields = function(self, dbtable, fields, replace_null)
			local s = ""
			for n = 1, #fields do
				if nil ~= replace_null then
					local sr = " CASE WHEN " .. self:sqlfld(dbtable, fields[n]) .. " IS NULL THEN '" .. replace_null .. "' ELSE " .. self:sqlfld(dbtable, fields[n]) .. " END AS s_" .. fields[n]
					s = s .. self.iif(1 == n, sr, ", " .. sr)
				else
					s = s .. self.iif(1 == n, dbtable .. "." .. fields[n], ", " .. dbtable .. "." .. fields[n])
				end
			end
			return s
		end
	}
}

return dbLib