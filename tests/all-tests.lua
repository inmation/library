
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