local R = {}

R.ENABLED = true

R.LEVELS = {
	{ cost = 250e3, speed = 1.1 },
	{ cost = 750e3, speed = 1.2 },
	{ cost = 2.5e6, speed = 1.3 },
	{ cost = 7.5e6, speed = 1.4 },
	{ cost = 25e6, speed = 1.5 },
	{ cost = 75e6, speed = 1.6 },
	{ cost = 250e6, speed = 1.7 },
	{ cost = 750e6, speed = 1.8 },
	{ cost = 2.5e9, speed = 1.9 },
	{ cost = 7.5e9, speed = 2.0 },
	{ cost = 25e9, speed = 2.1 },
	{ cost = 75e9, speed = 2.2 },
	{ cost = 250e9, speed = 2.3 },
	{ cost = 750e9, speed = 2.4 },
	{ cost = 2.5e12, speed = 2.5 },
	{ cost = 7.5e12, speed = 2.6 },
	{ cost = 25e12, speed = 2.7 },
	{ cost = 75e12, speed = 2.8 },
	{ cost = 250e12, speed = 2.9 },
	{ cost = 750e12, speed = 3.0 },
	{ cost = 2.5e15, speed = 3.1 },
	{ cost = 7.5e15, speed = 3.2 },
	{ cost = 25e15, speed = 3.3 },
	{ cost = 75e15, speed = 3.4 },
	{ cost = 250e15, speed = 3.5 },
}

function R.cost(rebirths)
	local level = R.LEVELS[math.clamp((rebirths or 0) + 1, 1, #R.LEVELS)]
	return math.floor(level and level.cost or 0)
end

function R.mult(rebirths)
	rebirths = rebirths or 0
	if rebirths <= 0 then
		return 1
	end
	local level = R.LEVELS[math.min(rebirths, #R.LEVELS)]
	return level and level.speed or 1
end

function R.maxed(rebirths)
	return (rebirths or 0) >= #R.LEVELS
end

return R