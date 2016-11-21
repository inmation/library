local pathLib = require('inmation.path')

tests = {
    test_sanitize1 = function(self)
        local sanitized = pathLib.sanitize('/System/Core//LocalConnector/')
        assert(sanitized == '/System/Core/LocalConnector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize2 = function(self)
        local sanitized = pathLib.sanitize('^/System/Core//LocalConnector/')
        assert(sanitized == '^/System/Core/LocalConnector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize3 = function(self)
        local sanitized = pathLib.sanitize('^/System/Core/Local^/Connector/')
        assert(sanitized == '^/System/Core/Local^/Connector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize4 = function(self)
        local sanitized = pathLib.sanitize('^/System/Core/Local^/Connector^/')
        assert(sanitized == '^/System/Core/Local^/Connector^/', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_pathJoinSingle = function(self)
        local path = pathLib.join('part01')
        local pathTest = '/part01'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoin = function(self)
        local path = pathLib.join('part01', 'part02')
        local pathTest = '/part01/part02'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

     test_pathJoinSingleSlash = function(self)
        local path = pathLib.join('/')
        local pathTest = '/'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinDoubleSlashes = function(self)
        local path = pathLib.join('/part01', '/part02')
        local pathTest = '/part01/part02'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinNil = function(self)
        local path = pathLib.join('/System', nil)
        local pathTest = '/System'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinCarrot = function(self)
        local path = pathLib.join('^/System', 'Core')
        local pathTest = '^/System/Core'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_parentPath = function(self)
        local path = '/System/Core/Test'
        path = pathLib.parentPath(path)
        local pathTest = '/System/Core'
        assert(pathTest == path, string.format("Parent path: '%s' != '%s'", path, pathTest))
    end,

    execute = function(self)
        print('Begin path_tests')
        self:test_sanitize1()
        self:test_sanitize2()
        self:test_sanitize3()
        self:test_sanitize4()

        self:test_pathJoinSingle()
        self:test_pathJoin()
        self:test_pathJoinSingleSlash()
        self:test_pathJoinDoubleSlashes()
        self:test_pathJoinNil()
        self:test_pathJoinCarrot()

        self:test_parentPath()
        print('End path_tests')
    end
}

return tests