print("inmation - Executing tests...")

-- Create package aliases
package.loaded.json = require("lib.json")

local allTests = require('tests.all-tests')
allTests:execute()

print("inmation - Done testing")
