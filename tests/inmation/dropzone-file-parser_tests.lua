local DropzoneFileParser = require('../lib/inmation-dropzone-file-parser')

local parser = DropzoneFileParser:new()

local actionFileOpening = nil

parser:onAction('FileOpening', function(args)
    actionFileOpening = true
end)

assert(actionFileOpening, 'Should have been invoked')