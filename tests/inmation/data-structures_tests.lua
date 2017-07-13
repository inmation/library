local ds = require('inmation.data-structures')


local tests = {
    test_queue = function()
        local queue = ds.Queue.new()
        queue:push("Hello")
        queue:push({ ["Hello"] = "World" })

        local length = queue:length()
        local testlength = 2
        assert(length == testlength, string.format("Length should be: %d got: %d", testlength, length))

        local obj = queue:pop()
        local testValue = "Hello"
        assert(obj == testValue, string.format("Object should be: %s", testValue))

        queue:push("inmation")

        obj = queue:pop()
        local testKey = "Hello"
        testValue = "World"
        assert(obj[testKey] == testValue, string.format("Object with key %s should be: %s", testKey, testValue))

        length = queue:length()
        testlength = 1
        assert(length == testlength, string.format("Length should be: %d got: %d", testlength, length))

        obj = queue:peek()
        testValue = "inmation"
        assert(obj == testValue, string.format("Object should be: %s", testValue))

        obj = queue:pop()
        testValue = "inmation"
        assert(obj == testValue, string.format("Object should be: %s", testValue))

        local s, err = pcall(function()
            queue:pop()
        end)
        assert(s == false, string.format("Call should fail due to no more objects in list"))
        local errTest = "queue is empty$"
        assert(string.match(err, errTest), string.format("Expected error which ends with: '%s' got: '%s'", errTest, err))

        length = queue:length()
        testlength = 0
        assert(length == testlength, string.format("Length should be: %d got: %d", testlength, length))
    end
}

return tests
