smpLib =
{	
	-- Sampler	
	-- this is a simple in-memory sampler to produce a set of timely means, totals etc.	
	-- using the autosampler feature you may create a bulk sampler working on any number of references	
	-- The default format of such references should be Inn-Shortname, where nn is a number, e.g. I01-DEMO	
	-- in this case a script program using the Sampler can query the data with either then index (1) or the symbol ("DEMO")
	Sampler = {	
		tab = {},
		refmask = "[iI][%d]*[-_]?[%g]*",
		nummask = "[%d]+",
		numids = true,
		keepone = true,	
		strict = true,	
		lerr = "",	
		except = false,	
		trange = 1 * 60 * 60 * 1000,
		-- sample: sample a given value for a given id
		sample = function(self, id, v, q, t)
			if self.tab[id] == nil then
				self.tab[id] = {}
			end
			if self.strict then
				if not essLib.goodquality(q) then
					self.lerr = "bad quality value cannot be sampled in strict mode"
					if self.except then
						error(self.lerr)
					end	
					return false
				end
			end
			local x = tonumber(v)
			if "number" ~= type(x) then
				self.lerr = "only numeric equivalents can be sampled"
				if self.except then
					error(self.lerr)
				end
				return false
			end
			self.tab[id][t] = x
			return true	
		end,
		-- autosample: sample
		autosample = function(self)	
			local c = 0
			local r = inmation.ref()
			for n = 1, #r do
				local ref = r[n]
				local m = string.match(ref, self.refmask)
				if essLib.hascontent(m) then
					if self.numids then
						local num = tonumber(string.match(ref, self.nummask))
						if essLib.nonzero(num) then
							self.sample(self, num, inmation.get(ref))
							c = c + 1
							end
						end
					end
				end
			return c
		end,
		-- Internal: testspan: determines whether the requested span can be handled by the sampler 	
		testspan = function(self, span, funcname)
			if span > self.trange then
				self.lerr = "Sampler:" .. funcname .. ": given span of " .. span .. "ms is larger than sampler setup (" .. self.trange .. "ms)"
				if self.except then
					error(self.lerr)
				end	
				return false
			end
			return true	
		end,
		-- Internal: cleanup: deletes old samples
		cleanup = function(self, id, time_limit)
			local preserve_key = nil
			local preserve_value = nil
			if nil == self.tab[id] then return end
			for key, value in pairs(self.tab[id]) do
				if key < time_limit then
					if keepone then
						preserve_key = key
						preserve_value = value
					end
					self.tab[id][key] = nil
				end
			end
			if keepone and nil ~= preserve_key then
				self.tab[id][preserve_key] = preserve_value
			end
		end,
		-- mean: returns the mean value (or average) for a given id	
		mean = function(self, id, span, tlimit, reftime)
			self.lerr = ""
			if not self.testspan(self, span, "mean") then
				return nil
			end
			self.cleanup(self, id, tlimit)
			local sum = .0
			local c = 0
			local older = nil
			local oldest
			if nil == reftime then
				oldest = inmation.now() - span
			else
				oldest = reftime - span
			end
			if nil == self.tab[id] then return nil end
			for key, value in pairs(self.tab[id]) do
				if key < oldest then	
					older = value
				else
					sum = sum + value
					c = c + 1
				end
			end
			if nil ~= older then
				if self.keepone then
					sum = sum + older
					c = c + 1
				end
			end
			if 0 == c then
				return nil
			else
				return sum / c
			end	
		end,
		-- total: returns the sample total 
		total = function(self, id, span, tlimit, reftime)
			self.lerr = ""
			if not self.testspan(self, span, "total") then
				return nil
			end
			self.cleanup(self, id, tlimit)
			local sum = .0
			local c = 0
			local older = nil
			local oldest
			if nil == reftime then
				oldest = inmation.now() - span
			else
				oldest = reftime - span
			end
			if nil == self.tab[id] then return nil end
			for key, value in pairs(self.tab[id]) do
				if key < oldest then	
					older = value
				else
					sum = sum + value
					c = c + 1
				end
			end
			if nil ~= older then
				sum = sum + older
				c = c + 1
			end
			if 0 == c then
				return nil
			else
				return sum
			end	
		end,
		max = function(self, id, span, tlimit, reftime)
			local vmax = nil
			self.lerr = ""
			if not self.testspan(self, span, "count") then
				return nil
			end
			self.cleanup(self, id, tlimit)
			local cnt = 0
			local oldest
			if nil == reftime then
				oldest = inmation.now() - span
			else
				oldest = reftime - span
			end
			if nil == self.tab[id] then return nil end
			for key, value in pairs(self.tab[id]) do
				if key >= oldest then
					if nil == vmax or value > vmax then
						vmax = value
					end
				end
			end
			return vmax
		end,
		count = function(self, id, span, tlimit, reftime)
			self.lerr = ""
			if not self.testspan(self, span, "count") then
				return nil
			end
			self.cleanup(self, id, tlimit)
			local cnt = 0
			local oldest
			if nil == reftime then
				oldest = inmation.now() - span
			else
				oldest = reftime - span
			end
			if nil == self.tab[id] then return nil end
			for key, value in pairs(self.tab[id]) do
				if key >= oldest then	
					cnt = cnt + 1
				end
			end
			return cnt
		end,
		data = function(self, id, span, tlimit, reftime, relative)
			local dt = {}
			self.lerr = ""
			if not self.testspan(self, span, "data") then
				return nil
			end
			self.cleanup(self, id, tlimit)
			local cnt = 0
			local oldest
			if nil == reftime then
				oldest = inmation.now() - span
			else
				oldest = reftime - span
			end
			if nil == self.tab[id] then return nil end
			for key, value in pairs(self.tab[id]) do
				if key >= oldest then	
					local tkey = key
					if relative then tkey = tkey - oldest end
					cnt = cnt + 1
					local dtl = {}
					dtl["t"] = tkey
					dtl["v"] = value
					table.insert(dt, dtl)
				end
			end
			return dt
		end,
		reset = function(self)
			self.lerr = ""
			self.tab = {}
		end
	}
}

return smpLib
