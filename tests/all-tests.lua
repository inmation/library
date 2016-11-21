local FileTracer = require('inmation.tracer')
local pathLib = require('inmation.path')

function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end

local filepath = get_script_path()
print(filepath)
filepath = pathLib.parentPath(filepath)
print(filepath)
filepath = pathLib.join(filepath, 'tmp', 'tests')
print(filepath)
local fileTracer = FileTracer.new(filepath)
traceAgent:addTracer(fileTracer)

allTests = {

    execute = function()
        -- mocks
        require('tests/mock/inmation_tests'):execute()

        -- extensions
        require('tests/inmation.string-extension_tests'):execute()

        -- inmation
        require('tests/inmation.condition_tests'):execute()
        require('tests/inmation.object_tests'):execute()
        require('tests/inmation.objects_tests'):execute()
        require('tests/inmation.path_tests'):execute()
        require('tests/inmation.table-extension_tests'):execute()
        require('tests/inmation.tracer_tests'):execute()
    end
}

return allTests