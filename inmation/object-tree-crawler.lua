-- inmation.object-tree-crawler
-- inmation Script Library Lua Script
--
-- (c) 2017 inmation
--
-- Version history:
--
-- 20170323.3   Code sanitized.
-- 20161018.2   Added Depth.
-- 20160904.1   Initial release.
--

local ObjectTreeCrawler = {
    onListeners = {}, -- Array of objects with { type, callback }
}

ObjectTreeCrawler.__index = ObjectTreeCrawler

-- Private

local function notifyListeners(self, obj, depth)
    -- Explicit set continue to false will stop the crawler going deeper into the tree.
    local continue = nil
    if #self.onListeners > 0 then
        local type = obj:type()
        for _, listener in ipairs(self.onListeners) do
            if listener.type == "" or listener.type == type then
                local cont = listener.callback(obj, depth)
                if false == cont then
                    continue = false;
                end
            end
        end
    end
    return continue
end

local function crawl(self, obj, depth)
    local continue = notifyListeners(self, obj, depth)
    if false == continue then return end
    local children = obj:children()
    if #children > 0 then
        for _, child in ipairs(children) do
            crawl(self, child, depth + 1)
        end
    end
end

-- Public

function ObjectTreeCrawler.new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, ObjectTreeCrawler)

    return o
end

function ObjectTreeCrawler:on(callback)
    self:onType("", callback)
end

-- type like MODEL_CLASS_HOLDERITEM, MODEL_CLASS_GENFOLDER
function ObjectTreeCrawler:onType(type, callback)
    local listener = {
        type = type,
        callback = callback
    }
    table.insert(self.onListeners, listener)
end

-- Start crawling through the tree by starting from one object or an object list.
-- When no argument is specified the crawling begins from System.
function ObjectTreeCrawler:start(originObjs)
    local objs = {}

    if not originObjs then
		local sysObj = inmation.getobject("/System")
		if nil ~= sysObj then
            table.insert(objs, sysObj)
		end
    else
        -- Since inmation objects and arrays are both lua tables, inspect the argument whether it implements a inmation function.
        if not originObjs.children then
            objs = originObjs
        else
            table.insert(objs, originObjs)
        end
    end

    local depth = 0
    for _, obj in ipairs(objs) do
        crawl(self, obj, depth)
    end
end

return ObjectTreeCrawler