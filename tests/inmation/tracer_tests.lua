
local tests = {
    test_traceToFile = function()
        traceAgent:traceVerbose('Verbose message')
        traceAgent:traceInfo('Info message')
        traceAgent:traceWarning('Warning message')
        traceAgent:traceError('Error message')
    end
}

return tests
