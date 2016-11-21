local FileTracer = require('inmation.tracer')
local pathLib = require('inmation.path')

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  --print(script_path)
  return script_path
end

tests = {
    test_traceToFile = function(self)
        local filepath = get_script_path()
        print(filepath)
        filepath = pathLib.parentPath(filepath)
        print(filepath)
        filepath = pathLib.parentPath(filepath)
        print(filepath)
        filepath = pathLib.join(filepath, 'tmp', 'tracer_tests')
        print(filepath)
        local fileTracer = FileTracer.new(filepath)
        traceAgent:addTracer(fileTracer)
        traceAgent:traceVerbose('Verbose message')
        traceAgent:traceInfo('Verbose message')
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
