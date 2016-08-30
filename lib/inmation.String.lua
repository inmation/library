-- String and split stuff simplified
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

strLib = {

	-- tries to guess the separator in a string
	-- cnt is the hint count
	-- fix (true/false) indicates no tolerance if set, if not found number must be equal or greater than cnt
	guess_separator = function (str, cnt, fix)
		local _, count = string.gsub(str, "\t", "")
		if (not fix and count >= cnt) or (fix and count == cnt) then return "\t" end
		_, count = string.gsub(str, ";", "")
		if (not fix and count >= cnt) or (fix and count == cnt) then return ";" end
		_, count = string.gsub(str, "|", "")
		if (not fix and count >= cnt) or (fix and count == cnt) then return "|" end
		_, count = string.gsub(str, ",", "")
		if (not fix and count >= cnt) or (fix and count == cnt) then return "," end
		return nil		
	end,
	
	validate_separator = function(str, sep, minocc)
		return minocc <= str:find(sep)
	end,
	
	-- splits a string where sep is a separator (if not given defaults to space)
	split = function(str, sep)
		-- returns an array of fields based on text and delimiter (one character only)
		local result = {}
		local magic = "().%+-*?[]^$"
		if delim == nil then
			delim = "%s"
		elseif string.find(sep, magic, 1, true) then
			-- escape magic
			sep = "%" .. sep
		end

		local pattern = "[^" .. sep .. "]+"
		for w in string.gmatch(str, pattern) do
			table.insert(result, w)
		end
		return result
	end,
	
	-- strips out the few unwanted characters
	clean = function(str)
		local r = str
		for n = 1, #str do
			if 0x20 > str:byte(n) or 0xA0 == str:byte(n) then
				--error("Here->" .. string.format("%X-%X-%X", str:byte(n-1), str:byte(n), str:byte(n+1)))
				r = r:sub(1, n-1) .. r:sub(n+1)
			end
		end
		return r
	end,
	
	-- splits a string and takes care about empty fields and quotation marks
	splitex = function(str, sep, quoted)
		local SL = strLib
		local result = { }
		local opos = nil
		local pos = str:find(sep, opos)
		opos = 1
		local empty = (opos == pos)
		if (not empty) and quoted then 
			local eq
			local sq = str:find('"', opos)
			if opos + 1 == sq then
				eq = str:find('"', sq + 1)	
				if nil ~= sq and nil ~= eq then
					if pos > sq and pos < eq then
						-- adjust (search next after end quote)
						pos = str:find(sep, eq)
					end
				end
			end
		end
		while nil ~= pos do
			local tx = str:sub(opos, pos - 1)
			if quoted then
				-- clean out the quote
				if 2 <= #tx then
					if '"' == tx:sub(1,1) then tx = tx:sub(2) end
					if '"' == tx:sub(-1,-1) then tx = tx:sub(1, #tx-1) end
				end
			end
			table.insert(result, SL.clean(tx))
			opos = pos + 1
			pos = str:find(sep, opos)
			if nil ~= pos then
				local empty = (opos + 1 == pos)
				if (not empty) and quoted then 
					local eq
					local sq = str:find('"', opos)
					if opos == sq then
						eq = str:find('"', sq + 1)	
						if nil ~= sq and nil ~= eq then
							if pos > sq and pos < eq then
								-- adjust (search next after end quote)
								pos = str:find(sep, eq)
							end
						end
					end
				end
			end
		end
		-- last field
		tx = str:sub(opos)
		if quoted then
			-- clean out the quote
			if 2 <= #tx then
				if '"' == tx:sub(1,1) then tx = tx:sub(2) end
				if '"' == tx:sub(-1,-1) then tx = tx:sub(1, #tx-1) end
			end
		end
		table.insert(result, SL.clean(tx))
		return result
	end,

	extr = function(arr, pattern)
		local first = { }
		local second = { }
		for i = 1, #arr do
			local s = arr[i]:match(pattern)
			if nil ~= s then
				local r = arr[i]:gsub(pattern, "", 1)
				if ("string" ~= type(r)) then
					error(r)
				end
				table.insert(first, r) --:gsub("^%s*(.-)%s*$", "%1"))
			else
				table.insert(first, arr[i])
			end			
			if nil == s or 0 == #s then 
				table.insert(second, "") 
			else 
				table.insert(second, s) --:gsub("^%s*(.-)%s*$", "%1")) 
			end
		end
		
		return first, second
	end

}

return strLib