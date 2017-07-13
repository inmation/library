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
    end
}

return tests
