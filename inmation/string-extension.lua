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
    local sep, fields = sep or ":", {}
    local pattern = string.format("([^%s]+)", sep)
    self:gsub(pattern, function(c) fields[#fields + 1] = c end)
    return fields
end

-- Is string nil or empty
function string.isEmpty(str)
	return (str or '') == ''
end