local pathLib = require('inmation.path')

local tests = {
    test_sanitize1 = function()
        local sanitized = pathLib.sanitize('/System/Core//LocalConnector/')
        assert(sanitized == '/System/Core/LocalConnector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize2 = function()
        local sanitized = pathLib.sanitize('^/System/Core//LocalConnector/')
        assert(sanitized == '^/System/Core/LocalConnector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize3 = function()
        local sanitized = pathLib.sanitize('^/System/Core/Local^/Connector/')
        assert(sanitized == '^/System/Core/Local^/Connector', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_sanitize4 = function()
        local sanitized = pathLib.sanitize('^/System/Core/Local^/Connector^/')
        assert(sanitized == '^/System/Core/Local^/Connector^/', string.format("Failed to sanitize path: %s", sanitized))
    end,

    test_pathJoinSingle = function()
        local path = pathLib.join('part01')
        local pathTest = '/part01'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoin = function()
        local path = pathLib.join('part01', 'part02')
        local pathTest = '/part01/part02'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

     test_pathJoinSingleSlash = function()
        local path = pathLib.join('/')
        local pathTest = '/'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinDoubleSlashes = function()
        local path = pathLib.join('/part01', '/part02')
        local pathTest = '/part01/part02'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinNil = function()
        local path = pathLib.join('/System', nil)
        local pathTest = '/System'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_pathJoinCarrot = function()
        local path = pathLib.join('^/System', 'Core')
        local pathTest = '^/System/Core'
        assert(pathTest == path, string.format("Path join: '%s' != '%s'", path, pathTest))
    end,

    test_parentPath = function()
        local path = '/System/Core/Test'
        path = pathLib.parentPath(path)
        local pathTest = '/System/Core'
        assert(pathTest == path, string.format("Parent path: '%s' != '%s'", path, pathTest))
    end,

    test_parentPathRoot = function()
        local path = '/KPIGroup'
        path = pathLib.parentPath(path)
        local pathTest = '/'
        assert(pathTest == path, string.format("Parent path: '%s' != '%s'", path, pathTest))
    end
}

return tests