local RS = game:GetService("ReplicatedStorage")
local Cfg = require(RS:WaitForChild("EggConfig"))

local F = {}

F.SLOTS = 3

F.COST_SECONDS = 600

F.SIZE_WEIGHTS = { 30, 30, 22, 11, 5, 2 }

F.SIZE_BIAS = 1.35

F.LUCK_MIN = -50
F.LUCK_MAX = 50

F.LUCK_PER_TIER = 6
F.LUCK_PER_SIZE = 3

F.LUCK_BOOST_MAX_ROLLS = 10

function F.cost(zone, tier, size)
    return math.floor(Cfg.animalIncome(zone, size, tier) * F.COST_SECONDS + 0.5)
end

local function avg(list)
    local s = 0
    for _, v in ipairs(list) do s += v end
    return #list > 0 and s / #list or 1
end

function F.rollSize(sizes, rng)
    rng = rng or Random.new()
    local shift = math.max(0, avg(sizes) - 1)
    local total, weights = 0, {}
    for i, w in ipairs(F.SIZE_WEIGHTS) do
        weights[i] = w * (F.SIZE_BIAS ^ ((i - 1) * shift / (#F.SIZE_WEIGHTS - 1) * 2))
        total += weights[i]
    end
    local roll = rng:NextNumber() * total
    for i, w in ipairs(weights) do
        roll -= w
        if roll <= 0 then return i end
    end
    return #weights
end

function F.rollLuck(tier, sizes, boost, rng)
    rng = rng or Random.new()
    local bonus = (math.max(1, tier or 1) - 1) * F.LUCK_PER_TIER
        + math.max(0, avg(sizes) - 1) * F.LUCK_PER_SIZE
    local rolls = math.clamp(math.floor(tonumber(boost) or 1), 1, F.LUCK_BOOST_MAX_ROLLS)
    local best = -math.huge
    for _ = 1, rolls do
        best = math.max(best, rng:NextInteger(F.LUCK_MIN, F.LUCK_MAX))
    end
    return math.clamp(math.floor(best + bonus + 0.5), F.LUCK_MIN, F.LUCK_MAX)
end

function F.incomeMult(luck)
    return 1 + (tonumber(luck) or 0) / 100
end

return F