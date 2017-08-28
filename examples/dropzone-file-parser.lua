require('inmation.string-extension')
require('inmation.table-extension')
local objsLib = require('inmation.objects')
local pathLib = require('inmation.path')
local DropzoneFileParser = require('inmation.dropzone-file-parser')

local parser = DropzoneFileParser.new()

local selfPath = inmation.getself():path()
local headerCells = {}

parser:onAction('Line', function(args)
	if string.isEmpty(args.line) then return end
	local cells = string.split(args.line, ',')
    if args.lineNumber == 0 then
		-- Header
		headerCells = cells

		table.imap(cells, function(cell, idx)
			-- Skip timestamp
            if idx > 1 then
                local propertyList = {
                    ObjectName = cell,
					ModelClass = 'MODEL_CLASS_HOLDERITEM',
                    ["ArchiveOptions.StorageStrategy"] = "STORE_RAW_HISTORY"
                }
                objsLib:ensureObject(selfPath, propertyList)
            end
		end)
	else
		-- Content
		if #headerCells ~= #cells then error('Number of cell mismatch')	end

		local timestamp = inmation.currenttime()
		table.imap(cells, function(cell, idx)
			if idx == 1 then
				timestamp = inmation.gettime(cell)
				return
			end
			local itemPath = pathLib.join(selfPath, headerCells[idx])
			inmation.setvalue(itemPath, cell, 0, timestamp)
		end)
	end
end)

return function(filename, filetime)
	parser:process(filename)
	return true
end
