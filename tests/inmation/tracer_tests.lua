
tests = {
    test_traceToFile = function(self)
        traceAgent:traceVerbose('Verbose message')
        traceAgent:traceInfo('Info message')
        traceAgent:traceWarning('Warning message')
        traceAgent:traceError('Error message')
    end,

    execute = function(self)
        print('Begin tracer_tests')
        self:test_traceToFile()
        print('End tracer_tests')
    end
}

return tests
