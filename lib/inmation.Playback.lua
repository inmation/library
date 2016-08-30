-- inmation.Playback
-- History Playback
-- (c) 2016, inmation Software GmbH
-- timo.klingenmeier@inmation.com

pbLib = {
	tim = require"inmation.Time",
	startt = math.huge,
	endt = 0,
	current = 0,
	cache = {},
	intervals = 0,
	contor = math.huge,
	agg_tab = {},
	obj_tab = {},

	next = function (objects, aggregates, period, start_time, end_time)
		local iso = pbLib.tim.isofromposix
		if pbLib.endt == 0 then
			--check if start and end are provided
			if start_time ~= nil and end_time ~= nil then
				pbLib.startt = start_time
				pbLib.endt = end_time
			--otherwise, compute them
			else
				for i=1, #objects do
					local so, eo = inmation.gethistoryframe(objects[i])
					if nil == so then error("Object " .. objects[i] .. " has no start time in history") end
					if nil == eo then error("Object " .. objects[i] .. " has no end time in history") end
					
					--error("Object " .. objects[i] .. " Start=" .. iso(so) .. " End=" .. iso(eo))
					if nil ~= so and so < pbLib.startt then
						pbLib.startt = so
					end
					if nil ~= eo and eo > pbLib.endt then
						pbLib.endt = eo
					end
				end
			end
			
			if math.huge == pbLib.startt then
				return nil
			end
			--error("Start = " .. pbLib.tim.isofromposix(pbLib.startt) .. ", End= " .. pbLib.tim.isofromposix(pbLib.endt))
			
			--compute the objects and aggregates tables so that each object is queried for each aggregate
			for i = 1, #objects do
				for j = 1, #aggregates do
					table.insert(pbLib.agg_tab, aggregates[j])
					table.insert(pbLib.obj_tab, objects[i])
				end
			end
		end
		
		if pbLib.current == 0 then
			local y,m,d,h,min = pbLib.tim.parts(pbLib.startt)
			local actual_start = 0
			if period == 24*60*60*1000 then --day
				actual_start = pbLib.tim.posixfromstr(pbLib.tim.isotimestr(y,m,d))
				pbLib.intervals = 7
			elseif period == 60*60*1000 then --hour
				actual_start = pbLib.tim.posixfromstr(pbLib.tim.isotimestr(y,m,d,h))
				pbLib.intervals = 7*24
			elseif period == 10*60*1000 then --10-min
				actual_start = pbLib.tim.posixfromstr(pbLib.tim.isotimestr(y,m,d,h,(min % 10) * 10))
				pbLib.intervals = 7*24*6
			elseif period == 60*1000 then --minute
				actual_start = pbLib.tim.posixfromstr(pbLib.tim.isotimestr(y,m,d,h,min))
				pbLib.intervals = 7*24*60
			else
				return nil
			end
			
			pbLib.current = actual_start
		end
	
		
		if pbLib.current <= pbLib.endt then		
			pbLib.contor = pbLib.contor + 1
		
			if pbLib.contor > pbLib.intervals then
				pbLib.cache = inmation.gethistory(pbLib.obj_tab, pbLib.current, pbLib.current + 7*24*60*60*1000, pbLib.intervals, pbLib.agg_tab)
				pbLib.contor = 1
			end
			
			local set = {}
			for i = 1, #pbLib.obj_tab do			
				local obj = pbLib.obj_tab[i]
				local agg = pbLib.agg_tab[i]
				
				if set[obj] == nil then
					set[obj] = {}
				end
				set[obj][agg] = pbLib.cache[i][pbLib.contor]
			end
			
			pbLib.current = pbLib.current + period
			return set
		else
			return nil
		end
	end,
	
	clear = function()
		startt = math.huge
		endt = 0
		current = 0
		cache = {}
		intervals = 0
		contor = math.huge
		agg_tab = {}
		obj_tab = {}
	end
}

return pbLib