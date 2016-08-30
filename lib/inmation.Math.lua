-- inmation.Math
-- Extensible math lib
-- (c) 2016, inmation Software GmbH
-- viacheslav.usov@inmation.com; timo.klingenmeier@inmation.com

mathLib = {

	-- data: an array of {v, q, t} tables
	-- return: values a, b, such that z = a + bt is the fitted linear function
	linearfit = function(data)
        local sum_xy, sum_x, sum_y, sum_xx, n = 0, 0, 0, 0, #data
        for i = 1, n do
            local v = data[i]
            local x = v.t
            local y = v.v
            
            sum_xy = sum_xy + x * y
            sum_x = sum_x + x
            sum_y = sum_y + y
            sum_xx = sum_xx + x * x
        end
        
        local b = (sum_xy - sum_x * sum_y / n) / (sum_xx - sum_x * sum_x / n)
        local a = sum_y / n - b * sum_x / n
        
        return a, b
	end,

	-- solves the equation a + bt = c for t
	-- returns t
	solvelinear = function (a, b, c)
    	return (c - a) / b
	end,

	-- approximates data with a linear function a + bt
	solvelevel = function(data, level)
    	local a, b = mathLib.linearfit(data)
    	return mathLib.solvelinear(a, b, level)
	end,

	-- returns an integer fit to x
	fitint = function(x)
    	return math.tointeger(math.ceil(x))
	end,

	solveint = function(data, target)
		return mathLib.fitint(mathLib.solvelevel(data, target))
	end
}

return mathLib