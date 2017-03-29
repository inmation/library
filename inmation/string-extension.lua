-- inmation.string-extension
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation BNX
--
-- Version history:
--
-- 20161121.2   Moved pathJoin to inmation.path library.
-- 20160919.1   Initial release.
--
function string:split(sep)
    local _sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", _sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

-- Is string nil or empty
function string.isEmpty(str)
	return (str or '') == ''
end


-- Lua 5.1+ base64 v3.0 (c) 2009 by Alex Kloss <alexthkloss@web.de>
-- licensed under the terms of the LGPL2

-- character table string
local BASE64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='

function string.encodeBase64String(data)
    return ((data:gsub('.', function(x)
        local r, b= '', x:byte()
        for i= 8, 1, -1 do r = r .. (b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return BASE64_CHARS:sub(c+1,c+1)
    end) .. ({ '', '==', '=' })[#data%3+1])
end

function string.decodeBase64String(data)
    data = string.gsub(data, '[^' .. BASE64_CHARS .. '=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r, f = '', (BASE64_CHARS:find(x)-1)
        for i = 6, 1, -1 do r = r .. (f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i = 1, 8 do c = c + (x:sub(i,i)=='1' and 2^(8-i) or 0) end
        return string.char(c)
    end))
end
