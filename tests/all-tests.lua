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

local function test(libname)
    print(string.format("Start testing %s...", libname))
    local tests = require(libname)
    for k, v in pairs(tests) do
        if string.match(k, 'test_') and type(v) == 'function' then
            v()
        end
    end
    print(string.format("Done testing %s", libname))
end

local allTests = {

    execute = function()
        -- mocks
        test('tests/mock/inmation_tests')

        -- extensions
        test('tests/inmation.string-extension_tests')

        -- inmation
        test('tests/inmation.condition_tests')
        test('tests/inmation.data-structures_tests')
        test('tests/inmation.object_tests')
        test('tests/inmation.objects_tests')
        test('tests/inmation.path_tests')
        test('tests/inmation.table-extension_tests')
        test('tests/inmation.tracer_tests')
    end
}

return allTests