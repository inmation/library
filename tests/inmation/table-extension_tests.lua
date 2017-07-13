require('inmation.table-extension')


local tests = {
    test_ifind1 = function()
        local tbl = { }
        local result, idx = table.ifind(tbl, function(name)
            return name == 'something'
        end)
        assert(result == nil and idx == nil, string.format("Item should not be found: %s, %s", result, idx))
    end,

    test_ifind2 = function()
        local tbl = { 'hello', 'world' }
        local result, idx = table.ifind(tbl, function(name)
            return name == 'world'
        end)
        assert(result == 'world' and idx == 2, string.format("Proper item not found: %s, %s", result, idx))
    end,

    test_ifind3 = function()
        local tbl = { }
        local item = { Name = 'Test'}
        local result, idx = table.ifind(tbl, function(storedItem)
            return item.Name == storedItem.Name
        end)
        assert(result == nil and idx == nil, string.format("Item should not be found: %s, %s", result, idx))
    end,

    test_find = function()
        local tbl = { }
        tbl.Item01 = 10
        tbl.Item02 = 20

        local testKey = 'Item02'
        local testValue = tbl[testKey]

        local v, k = table.find(tbl, function(key, _)
            return key == 'Item02'
        end)
        assert(v == testValue, string.format("Value %d expected got %d", testValue, v))
        assert(k == testKey, string.format("Value %s expected got %s", testKey, k))
    end,

    test_imap_01 = function()
        local numbers = { 1, 4, 9 }
        local roots = table.imap(numbers, function(number)
            return math.sqrt(number)
        end)
        local testValue = { 1, 2, 3 }
        for i in ipairs(testValue) do
            local tv = tostring(testValue[i])
            local m = tostring(roots[i])
            assert(roots[i] == testValue[i], string.format("At index %d, value %s expected got %s", i, tv, m))
        end
    end,

    test_imerge = function()
        local tbl1 = { 1, 2, 3 }
        local tbl2 = { 'A', 'B', 'C' }
        local merged = table.imerge(tbl1, tbl2)
        local testValue = { 1, 2, 3, 'A', 'B', 'C' }
        for i in ipairs(testValue) do
            local tv = tostring(testValue[i])
            local m = tostring(merged[i])
            assert(merged[i] == testValue[i], string.format("At index %d, value %s expected got %s", i, tv, m))
        end
    end,

    test_ireduce_01 = function()
        local total = table.ireduce({ 0, 1, 2, 3 }, function(sum, value)
            return sum + value;
        end, 0)
        local testValue = 6
        assert(total == testValue, string.format("Value %s expected got %s", testValue, total))
    end,

    test_ireduce_02 = function()
        local flattened = table.ireduce({ {0, 1}, {2, 3}, {4, 5} }, function(a, b)
            return table.imerge(a, b)
        end, {})
        local testValue = { 0, 1, 2, 3, 4, 5 }
        for i in ipairs(testValue) do
            local tv = tostring(testValue[i])
            local fl = tostring(flattened[i])
            assert(flattened[i] == testValue[i], string.format("At index %d, value %s expected got %s", i, tv, fl))
        end
    end,

    test_ireduce_03 = function()
        local result = table.ireduce({ 0, 1, 2, 3, 4 }, function(acc, cur)
            return acc + cur
        end, 10)
        local testValue = 20
        assert(result == testValue, string.format("Value %s expected got %s", testValue, result))
    end,

    test_ireduce_04 = function()
        local events = {
            {
                ["Source"] = "/A",
                ["Severity"] = 500,
                ["Message"] = "script event",
                ["Timestamp"] = 1470663220365,
                ["equipmentid"] = "A"
            },
            {
                ["Source"] = "/B",
                ["Severity"] = 1000,
                ["Message"] = "script event",
                ["Timestamp"] = 1470663220365,
                ["equipmentid"] = "A"
            },
            {
                ["Source"] = "/C",
                ["Severity"] = 500,
                ["Message"] = "script event",
                ["Timestamp"] = 1470663220365,
                ["equipmentid"] = "B"
            },
            {
                ["Source"] = "/D",
                ["Severity"] = 1000,
                ["Message"] = "script event",
                ["Timestamp"] = 1470663220365,
                ["equipmentid"] = "B"
            }
        }
        local result = table.ireduce(events, function(acc, cur)
            if cur.Severity == 500 then
                table.insert(acc, cur)
            end
            return acc
        end, {})
        local testValue = 2
        assert(#result == testValue, string.format("Table length %d expected got %d", testValue, #result))

        local event1 = result[1]
        testValue = '/A'
        assert(event1.Source == testValue, string.format("Value %s expected got %s", testValue, event1.Source))

        local event2 = result[2]
        testValue = '/C'
        assert(event2.Source == testValue, string.format("Value %s expected got %s", testValue, event2.Source))
    end,

    test_ireduce_no_initialvalue01 = function()
        local result = table.ireduce({ { x = 22}, { x = 42} }, function(acc, cur)
            return math.max(acc.x, cur.x)
        end)
        local testValue = 42
        assert(result == testValue, string.format("Value %d expected got %d", testValue, result))
    end,

    test_ireduce_no_initialvalue02 = function()
        local result = table.ireduce({ { x = 22} }, function(acc, cur)
            return math.max(acc.x, cur.x)
        end)
        local testValue = 22
        assert(result.x == testValue, string.format("Object with key 'x', value %d expected got %d", testValue, result.x))
    end,

    test_ireduce_map_reduce = function()
        local result = table.imap({ { x = 22}, { x = 42}  }, function(cur)
            return cur.x
        end):ireduce(function(max, cur)
            return math.max(max, cur)
        end, -math.huge)
        local testValue = 42
        assert(result == testValue, string.format("Value %d expected got %d", testValue, result))
    end
}

return tests
