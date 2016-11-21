require('inmation.string-extension')


tests = {
    test_split1 = function(self)
        local tbl = string.split('one.two.three', '.')
        assert(#tbl == 3, string.format("Expecting array with length of three, got: %s", #tbl))
    end,

    execute = function(self)
        print('Begin string-extension_tests')
        self:test_split1()
        
        print('End string-extension_tests')
    end
}

return tests
