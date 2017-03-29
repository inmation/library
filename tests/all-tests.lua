-- Load inmation mock globally
inmation = require('mock/inmation')

local FileTracer = require('inmation.tracer')
local pathLib = require('inmation.path')
local os = require('os')

local function get_script_path()
  local info = debug.getinfo(1,'S');
  local script_path = info.source:match[[^@?(.*[\/])[^\/]-$]]
  return script_path
end


local platformIsWindows = os.getenv('HOME') == nil

local folderPath = get_script_path()
print(folderPath)
folderPath = pathLib.parentPath(folderPath)
print(folderPath)
folderPath = pathLib.join(folderPath, 'tmp')


if platformIsWindows then
   folderPath = string.gsub(folderPath, '^/','')
end
print(folderPath)
local filenamePrefix = 'tests'
local fileTracer = FileTracer.new(folderPath, filenamePrefix)
traceAgent:addTracer(fileTracer)

local allTests = {

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