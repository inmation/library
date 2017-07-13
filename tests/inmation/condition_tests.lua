local conditionLib = require('inmation.condition')

local tests = {
    test_iif = function()
        local result = conditionLib.iif(1 == 1, 1, 3)
        assert(result == 1, 'Value mismatch')

        result = conditionLib.iif(1 == 2, 1, 3)
        assert(result == 3, 'Value mismatch')
    end,

    test_createCondition = function()
        local prop = 'ObjectName'
        local oper = 'Contains'
        local val = 'PLI'

        local condition = conditionLib:createCondition(prop, oper, val)

        assert(condition.property == prop, 'Property error')
        assert(condition.operator == oper, 'Operator error')
        assert(condition.value == val, 'Value error')
    end,

    test_patternContains = function()
        local operator = 'Contains'
        local value = 'PLI'
        local pattern = conditionLib:pattern(operator, value)
        assert(type(pattern) == 'string', 'Pattern is not of type string')
        assert(pattern == value, 'Pattern value mismatch: ' .. pattern .. ' != ' .. value)
    end,

    test_patternEndWith = function()
        local operator = 'EndsWith'
        local value = 'PLI'
        local pattern = conditionLib:pattern(operator, value)
        assert(type(pattern) == 'string', 'Pattern is not of type string')
        local testValue = value .. '$'
        assert(pattern == testValue, 'Pattern value mismatch: ' .. pattern .. ' != ' .. testValue)
    end,

    test_patternEquals = function()
        local operator = 'Equals'
        local value = 10.0
        local pattern = conditionLib:pattern(operator, value)
        assert(type(pattern) == 'number', 'Pattern is not of type number')
        assert(pattern == value, 'Pattern value mismatch: ' .. pattern .. ' != ' .. value)
    end,

    test_patternStartsWith = function()
        local operator = 'StartsWith'
        local value = 'PLI'
        local pattern = conditionLib:pattern(operator, value)
        assert(type(pattern) == 'string', 'Pattern is not of type string')
        local testValue = '^' .. value
        assert(pattern == testValue, 'Pattern value mismatch: ' .. pattern .. ' != ' .. testValue)
    end,

    test_Condition = function()
        local objMock = {}
        objMock.ObjectName = 'xxPLIxx'
        objMock.Value = 100.0

        -- Positive Contains match
        local condition = conditionLib:createCondition('ObjectName', 'Contains', 'PLI')
        local result = conditionLib:matchCondition(condition, objMock)
        assert(result == true, 'Contains Condition mismatch')

        -- Negative Contains match
        condition = conditionLib:createCondition('ObjectName', 'Contains', 'EGU')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'Contains Condition should be a mismatch')

        -- Positive StartsWith match
        condition = conditionLib:createCondition('ObjectName', 'StartsWith', 'xxPLI')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == true, 'StartsWith Condition mismatch')

        -- Negative Contains match
        condition = conditionLib:createCondition('ObjectName', 'StartsWith', 'PLI')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'StartsWith Condition should be a mismatch')

        -- Positive EndsWith match
        condition = conditionLib:createCondition('ObjectName', 'EndsWith', 'PLIxx')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == true, 'EndsWith Condition mismatch')

        -- Negative EndsWith match
        condition = conditionLib:createCondition('ObjectName', 'EndsWith', 'PLI')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'EndsWith Condition should be a mismatch')

        -- Positive Equals match
        condition = conditionLib:createCondition('ObjectName', 'Equals', 'xxPLIxx')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == true, 'Equals Condition mismatch')

        -- Negative Equals match
        condition = conditionLib:createCondition('ObjectName', 'Equals', 'PLI')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'Equals Condition should be a mismatch')

        -- Positive Equals numeric value match
        condition = conditionLib:createCondition('Value', 'Equals', 100.0)
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == true, 'Equals Condition mismatch')

        -- Negative Equals numeric value match
        condition = conditionLib:createCondition('Value', 'Equals', '100.0')
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'Equals Condition should be a mismatch')

        -- Negative Equals numeric value match
        condition = conditionLib:createCondition('Value', 'Equals', 110.0)
        result = conditionLib:matchCondition(condition, objMock)
        assert(result == false, 'Equals Condition should be a mismatch')
    end,

    test_ConditionList = function()
        local objMock = {}
        objMock.ObjectName = 'xxPLIxx'
        objMock.Value = 100.0

        -- Positive Contains match
        local condition1 = conditionLib:createCondition('ObjectName', 'Contains', 'EGU')
        local condition2 = conditionLib:createCondition('ObjectName', 'EndsWith', 'PLIxx')
        local conditionList = { condition1, condition2 }
        local result = conditionLib:matchConditions(conditionList, objMock)
        assert(result == true, 'Contains Condition mismatch')

        -- Negative Contains match
        condition1 = conditionLib:createCondition('ObjectName', 'Contains', 'EGU')
        condition2 = conditionLib:createCondition('ObjectName', 'EndsWith', 'xxPLI')
        conditionList = { condition1, condition2 }
        result = conditionLib:matchConditions(conditionList, objMock)
        assert(result == false, 'Contains Condition should be a mismatch')
    end
}

return tests
