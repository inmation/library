print("inmation - Executing tests...")

-- Load inmation mock globally
inmation = require('mock/inmation')

-- Create package aliases
package.loaded.json = require("lib/json")

local allTests = require('tests.all-tests')
allTests:execute()

print("inmation - Done testing")