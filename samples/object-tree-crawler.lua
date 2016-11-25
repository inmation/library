local Crawler = require("inmation.object-tree-crawler")

local crawler = Crawler.new()

local totalcount = 0
local statistics = {
	actionitems = 0,
	connectors = 0,
	cores = 0,
	datasources = 0,
	genfolders = 0,
	genitems = 0,
	holderitems = 0,
	ioitems = 0,
	ionodes = 0,
	
	reset = function(self)
		self.actionitems = 0
		self.connectors = 0
		self.cores = 0
		self.datasources = 0
		self.genfolders = 0
		self.genitems = 0
		self.holderitems = 0
		self.ioitems = 0
		self.ionodes = 0
	end,
	
	sum = function(self)
		return self.actionitems + self.connectors + self.cores + self.datasources + self.genfolders + self.genitems + self.holderitems + self.ioitems + self.ionodes
	end,
	
	tostring = function(self)
		return string.format("actionitems: %d, connectors: %d, cores: %d, datasources: %d, genfolders: %d, genitems: %d, holderitems: %d, ioitems: %d, ionodes: %d", self.actionitems, self.connectors, self.cores, self.datasources, self.genfolders, self.genitems, self.holderitems, self.ioitems, self.ionodes)
	end
}

crawler:on(function(obj)
	totalcount = totalcount + 1
end)

crawler:onType("MODEL_CLASS_ACTIONITEM", function(obj)
	statistics.actionitems = statistics.actionitems + 1
end)

crawler:onType("MODEL_CLASS_CONNECTOR", function(obj)
	statistics.connectors = statistics.connectors + 1
end)

crawler:onType("MODEL_CLASS_CORE", function(obj)
	statistics.cores = statistics.cores + 1
end)

crawler:onType("MODEL_CLASS_DATASOURCE", function(obj)
	statistics.datasources = statistics.datasources + 1
end)

crawler:onType("MODEL_CLASS_GENFOLDER", function(obj)
	statistics.genfolders = statistics.genfolders + 1
end)

crawler:onType("MODEL_CLASS_GENITEM", function(obj)
	statistics.genitems = statistics.genitems + 1
end)

crawler:onType("MODEL_CLASS_HOLDERITEM", function(obj)
	statistics.holderitems = statistics.holderitems + 1
end)

crawler:onType("MODEL_CLASS_IOITEM", function(obj)
	statistics.ioitems = statistics.ioitems + 1
end)

crawler:onType("MODEL_CLASS_IONODE", function(obj)
	statistics.ionodes = statistics.ionodes + 1
end)

return function()
	local starttime = inmation.now()
	
	totalcount = 0
	statistics:reset()
	local node = inmation.getobject("/System")	
	crawler:start(node)		
	
	local total_time = inmation.now() - starttime
	return string.format("Took %03d msec for %d object, sum: %d, %s", total_time, totalcount, statistics:sum(), statistics:tostring())
end