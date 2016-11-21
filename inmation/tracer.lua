-- inmation.tracer
-- inmation Script Library Lua Script
--
-- (c) 2016 inmation
--
-- Version history:
--
-- 20161103.1   Initial release.
--

local FileTracer = {}

FileTracer.__index = FileTracer

-- Public

function FileTracer.new(filepath)
    local self = setmetatable({}, FileTracer)
    self.filepath = filepath
    return self
end

function FileTracer:write(msg)
    local now = inmation.currenttime()
    -- New file per day.
	executionTimeStamp = string.format("%04d%02d%02d", inmation.gettimeparts(now))
    local filename = self.filepath .. '_' .. tostring(executionTimeStamp) .. '.txt'
    local file = io.open(filename,'a')
    file:write(msg)
    file:flush()
    io.close(file)
end

function FileTracer:writeLine(msg)
    self:write(tostring(msg) .. '\n')
end

function FileTracer:trace(timestamp, severity, msg)
    self:writeLine(tostring(timestamp) .. '\t' .. tostring(severity) .. '\t' .. tostring(msg))
end


-- Global available traceAgent
traceAgent = {

    tracers = {},

    addTracer = function(self, tracer)
        table.insert(self.tracers, tracer)
    end,

    trace = function(self, severity, msg, timestamp)
        local time = timestamp or inmation.gettime(inmation.currenttime())
        for i,listerner in ipairs(self.tracers) do
		    listerner:trace(time, severity, msg)
        end
	end,

    traceError = function(self, msg, timestamp)
       self:trace('ERRR', msg, timestamp)
	end,
	
    traceInfo = function(self, msg, timestamp)
       self:trace('INFO', msg, timestamp)
	end,

	traceVerbose = function(self, msg, timestamp)
       self:trace('VERB', msg, timestamp)
	end,

    traceWarning = function(self, msg, timestamp)
       self:trace('WARN', msg, timestamp)
	end
}

return FileTracer