-- inmation.dropzone-file-parser
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20161017.1       Initial release.
--

local ioLib = require('io')

local DropzoneFileParser = {
    onListeners = {}, -- Array of objects with { action, callback }
}

DropzoneFileParser.__index = DropzoneFileParser

-- Private

local function notifyListeners(self, action, args)
    -- Explicit set continue to false will stop the processing of the file.
    local continue = nil
    if #self.onListeners > 0 then
        for _, listener in ipairs(self.onListeners) do
            if listener.action == "" or listener.action == action then
                args.action = action
                local cont = listener.callback(args)
                if false == cont then
                    continue = false;
                end
            end
        end
    end
    return continue
end

-- Public

function DropzoneFileParser.new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, DropzoneFileParser)

    return o
end

function DropzoneFileParser:on(callback)
    self:onAction("", callback)
end

-- action like FileOpened, Line, FileClosing, FileClosed
function DropzoneFileParser:onAction(action, callback)
    local listener = {
        action = action,
        callback = callback
    }
    table.insert(self.onListeners, listener)
end

function DropzoneFileParser:process(filename)
    local args = {
        filename = filename
    }

    -- on FileOpening
    local continue = notifyListeners(self, 'FileOpening', args)
    if false == continue then return end

    local file = ioLib:open(filename)

    if nil ~= file then
        args.file = file
        -- on FileOpened
        continue = notifyListeners(self, 'FileOpened', args)
        if false == continue then return end

        for line in file:lines() do
            args.line = line
            -- on Line
            continue = notifyListeners(self, 'Line', args)
            if false == continue then break end
        end

        -- on FileClosing
        args.line = nil
        notifyListeners(self, 'FileClosing', args)
        file:close()
        -- on FileClosed
        args.file = nil
        notifyListeners(self, 'FileClosed', args)
    end
end

return DropzoneFileParser