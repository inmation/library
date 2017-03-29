require('inmation.string-extension')


local tests = {
    test_split1 = function()
        local tbl = string.split('one.two.three', '.')
        assert(#tbl == 3, string.format("Expecting array with length of three, got: %s", #tbl))
    end,

    test_DecodeFromBase64String = function()
        local msg = 'SGVsbG8gV29ybGQh'
        local testStr = string.decodeBase64String(msg)
        assert(testStr == 'Hello World!', string.format("Expecting 'Hello World!', got: %s", testStr))
    end,

    test_EncodeToBase64String = function()
        local msg = 'Hello World!'
        local testStr = string.encodeBase64String(msg)
        assert(testStr == 'SGVsbG8gV29ybGQh', string.format("Expecting 'SGVsbG8gV29ybGQh', got: %s", testStr))
    end,

    execute = function(self)
        print('Begin string-extension_tests')
        self:test_split1()
        self:test_DecodeFromBase64String()
        self:test_EncodeToBase64String()
        print('End string-extension_tests')
    end
}

return tests
