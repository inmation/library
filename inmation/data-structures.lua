-- inmation.data-structures
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20170706.1   Initial release.
--

--------------------------------------------------------------------------------
local Queue = {}

Queue.__index = Queue

function Queue.new(existing)
    local queue = existing or { first = 0, last = -1, values = {} }
    setmetatable(queue, Queue)
    return queue
end

function Queue:length()
    local first = self.first
    local last = self.last
    if first > last then return 0 end
    return last - first + 1
end

function Queue:peek()
    local last = self.last
    if self.first > last then return nil end
    local value = self.values[last]
    return value
end

function Queue:pop()
    local last = self.last
    if self.first > last then error("queue is empty", 2) end
    local value = self.values[last]
    self.values[last] = nil         -- to allow garbage collection
    self.last = last - 1
    return value
end

function Queue:push(value)
    local first = self.first - 1
    self.first = first
    self.values[first] = value
end
--------------------------------------------------------------------------------

return {
    Queue = Queue
}