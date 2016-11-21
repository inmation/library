-- inmation.condition
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20161018.1   Initial release.
--

conditionLib = {

    createCondition = function(self, property, operator, value)
        return { property = property, operator = operator, value = value }
    end,

    pattern = function(self, operator, value)
        if operator == 'Contains' then
            return tostring(value)
        elseif operator == 'StartsWith' then
            return '^' .. tostring(value)
        elseif operator == 'EndsWith' then
            return tostring(value) .. '$'
        elseif operator == 'Equals' then
            return value
        end
        return nil
    end,

    matchCondition = function(self, condition, obj)
        local property = assert(condition.property, "Condition doesn't contain a property")
        local operator = assert(condition.operator, "Condition doesn't contain a operator")
        local value = assert(condition.value, "Condition doesn't contain a value")

        local objProp = obj[property]
        
        if operator == 'Equals' then
            return objProp == value
        else
            local ptn = self:pattern(operator, value)
            local result = string.match(objProp, ptn)
            return result ~= nil
        end
    end,

    matchConditions = function(self, conditionList, obj)
        for i,condition in ipairs(conditionList) do
            local result = self:matchCondition(condition, obj)
            if result == true then
                return true
            end
        end
        return false
    end
}

function conditionLib.iif(expression, truePart, falsePart)		
    if expression then return truePart else return falsePart end	
end

return conditionLib