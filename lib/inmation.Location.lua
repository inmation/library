-- inmation.Location
-- Functions dealing with location data
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

locLib = {
	locationequal = function(name, oname, lat, olat, lng, olng, alt, oalt, strat, ostrat)
		local acc = .00001
		local b = strat == ostrat
		b = b and name == oname
		b = b and "number" == type(lng) and "number" == type(olng) and acc > math.abs(lng - olng)
		b = b and "number" == type(lat) and "number" == type(olat) and acc > math.abs(lat - olat)
		b = b and "number" == type(alt) and "number" == type(oalt) and acc > math.abs(alt - oalt)
		return b
	end,
	LocationObject = {
		obj = nil,
		setobject = function(self, obj)
			self.obj = obj
		end,
		-- sets location data
		setlocation = function(self, strat, lat, lng, alt, name)
			if nil == self.obj then return false, false end
			local p = self.obj:path()
			if "string" ~= type(p) or 0 == #p then return false, false end
			p = p .. ".Location."
			local olat = inmation.get(p .. "Latitude")
			local olng = inmation.get(p .. "Longitude")
			local oalt = inmation.get(p .. "Altitude")
			local onam = inmation.get(p .. "LocationName")
			local ostrat = inmation.get(p .. "LocationStrategy")
			if not locLib.locationequal(name, onam, lat, olat, lng, olng, alt, oalt, strat, ostrat) then
				inmation.set(p .. "Latitude", lat)
				inmation.set(p .. "Longitude", lng)
				inmation.set(p .. "Altitude", alt)
				inmation.set(p .. "LocationName", name)
				inmation.set(p .. "LocationStrategy", strat)
				return true, true
			else
				return false, true
			end
		end,
		-- populates location data down the tree
		downpopulate = function(self)
			local mtch = 0
			local chngd = 0
			if nil == self.obj then return mtch, chngd end
			
		end
	}
}

return locLib
	