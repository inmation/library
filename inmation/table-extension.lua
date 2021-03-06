-- inmation.table-extension
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20170911.3   Added istable, isTable, toString
-- 20161028.2   Added map, imap, ifind
-- 20160919.1   Initial release.
--

function table.istable(tbl)
    return type (tbl) == 'table'
end

table.isTable = table.istable

function table.val_to_str(v)
  if "string" == type(v) then
    v = string.gsub( v, "\n", "\\n" )
    if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
      return "'" .. v .. "'"
    end
    return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
  else
    return "table" == type(v) and table.tostring(v) or
      tostring(v)
  end
end

function table.key_to_str(k)
  if "string" == type(k) and string.match(k, "^[_%a][_%a%d]*$") then
    return k
  else
    return "[" .. table.val_to_str(k) .. "]"
  end
end

function table.tostring(tbl)
  local result, done = {}, {}
  for k, v in ipairs(tbl) do
    table.insert(result, table.val_to_str(v))
    done[k]  = true
  end
  for k, v in pairs(tbl) do
    if not done[k] then
      table.insert(result, table.key_to_str(k) .. "=" .. table.val_to_str(v) )
    end
  end
  return "{" .. table.concat( result, "," ) .. "}"
end

table.toString = table.tostring

function table.map(tbl, predicate)
    local result = {}
    for k,v in pairs(tbl) do
        if type(predicate) == 'function' then
            local item = predicate(k, v)
            table.insert(result, item)
        end
    end
    return result
end

function table.imap(tbl, predicate)
    local result = {}
    for i,v in ipairs(tbl) do
        if type(predicate) == 'function' then
            local item = predicate(v, i)
            table.insert(result, item)
        end
    end
    result.ireduce = table.ireduce
    return result
end

function table.find(tbl, predicate)
    for k,v in pairs(tbl) do
        if type(predicate) == 'function' then
            local found = predicate(k, v)
              if found then
                return v, k
              end
        end
    end
end

function table.ifind(tbl, predicate)
    for i,v in ipairs(tbl) do
        if type(predicate) == 'function' then
            local found = predicate(v, i)
            if found then
                return v, i
            end
        end
    end
end

function table.contains(tbl, elem)
	if type(tbl) ~= 'table' then return nil end
	for _,val in pairs(tbl) do
		if val == elem then return true end
	end
	return false
end

function table.dictlen(dict)
	if type(dict) ~= 'table' then return nil end
	local count = 0
	for _,_ in pairs(dict) do count = count + 1	end
	return count
end

function table.imerge(tbl1, tbl2)
    for _,v in ipairs(tbl2) do table.insert(tbl1, v) end
    return tbl1
end

function table.ireduce(tbl, predicate, initialvalue)
    local accumulator = initialvalue
    local skipIndexOne = false
    if initialvalue == nil then
        accumulator = tbl[1]
        skipIndexOne = true
    end

    for i,v in ipairs(tbl) do
        if skipIndexOne and i == 1 then
            skipIndexOne = false
        else
            if type(predicate) == 'function' then
                accumulator = predicate(accumulator, v, i, tbl)
            end
        end
    end
    return accumulator
end