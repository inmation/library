-- inmation.condition
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20161018.1   Initial release.
--

local conditionLib = {

    ----------------------------------------------------------------------------
    -- Creates a condition object which can be used to check whether a property value of
    -- an inmation object matches the condition.
    -- @param property inmation object property path to check the value of.
    -- @param operator The operator to create a string match pattern for. The value can be
    --  'Contains', 'StartsWith', 'EndsWith' or 'Equals'
    -- @return A condition table, which contains the properties property, operator and value.
    -----------------------------------------------------------------------------
    createCondition = function(_, property, operator, value)
        return { property = property, operator = operator, value = value }
    end,

    ----------------------------------------------------------------------------
    -- Creates a string match pattern based on the provided operator and value.
    -- @param property inmation object property path to check the value of.
    -- @param operator The operator to create a search pattern for. The value can be
    --  'Contains', 'StartsWith', 'EndsWith' or 'Equals'
    -- @return string match pattern.
    -----------------------------------------------------------------------------
    pattern = function(_, operator, value)
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

    ----------------------------------------------------------------------------
    -- Matches one condition with the provided object.
    -- @param condition Table which contains the property path, operator and
    --  property value to search for.
    -- @param obj Object which contain the property to check.
    -- @return boolen whether the condition matches.
    -----------------------------------------------------------------------------
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

    ----------------------------------------------------------------------------
    -- Matches multiple conditions with the provided object.
    -- @param conditionList A list of condition tables, which contains the property path, operator and
    --  property value to search for.
    -- @param obj Object which contains the property to check.
    -- @return boolen whether one of the condition matches.
    -----------------------------------------------------------------------------
    matchConditions = function(self, conditionList, obj)
        for _, condition in ipairs(conditionList) do
            local result = self:matchCondition(condition, obj)
            if result == true then
                return true
            end
        end
        return false
    end
}

----------------------------------------------------------------------------
-- Inline if statement
-- @param expression The boolean condition to evaluate.
-- @param truePart The consequent statement (then) to execute when the
--      expression evaluates to true.
-- @return falsePart The alternative statement (else) to execute when the
--  expression evaluates to false.
-----------------------------------------------------------------------------
function conditionLib.iif(expression, truePart, falsePart)
    if expression then return truePart else return falsePart end
end

return conditionLib