require('inmation.table-extension')


tests = {
    test_ifind1 = function(self)
        local tbl = { }
        local result, idx = table.ifind(tbl, function(name) 
            return name == 'something'
        end)
        assert(result == nil and idx == nil, string.format("Item should not be found: %s, %s", result, idx))
    end,

    test_ifind2 = function(self)
        local tbl = { 'hello', 'world' }
        local result, idx = table.ifind(tbl, function(name) 
            return name == 'world'
        end)
        assert(result == 'world' and idx == 2, string.format("Proper item not found: %s, %s", result, idx))
    end,

    test_ifind3 = function(self)
        local tbl = { }
        local item = { Name = 'Test'}
        local result, idx = table.ifind(tbl, function(storedItem) 
            return item.Name == storedItem.Name
        end)
        assert(result == nil and idx == nil, string.format("Item should not be found: %s, %s", result, idx))
    end,

    execute = function(self)
        print('Begin table-extension_tests')
        self:test_ifind1()
        self:test_ifind2()
        self:test_ifind3()
        print('End table-extension_tests')
    end
}

return tests
