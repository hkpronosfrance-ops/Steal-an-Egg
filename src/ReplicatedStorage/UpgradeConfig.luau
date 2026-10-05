local Money = require(script.Parent:WaitForChild("MonetizationConfig"))
local U = {}

U.MAX_LEVEL = 12

U.PEN = {
    name = "Pen", title = "Upgrade Pen",
    icon = "rbxassetid://87422007868226",
    base = 1e5, growth = 8,
    petsBase = 3, petsPerLevel = 1,
    robux = Money.UPGRADES.PEN.prices,
    productIds = Money.UPGRADES.PEN.productIds,
}

U.MILL = {
    name = "Treadmill", title = "Upgrade Treadmill",
    icon = "rbxassetid://83769600890897",
    base = 2.5e5, growth = 9,
    awardBase = 4, awardEvery = 0.5, awardGrowth = 2,
    robux = Money.UPGRADES.MILL.prices,
    productIds = Money.UPGRADES.MILL.productIds,
}

function U.price(kind, level)
    local d = U[kind]
    if not d then return math.huge end
    return math.floor(d.base * d.growth ^ (math.max(1, level) - 1))
end

function U.petCap(level)
    local lv = math.clamp(math.floor(tonumber(level) or 1), 1, U.MAX_LEVEL)
    return U.PEN.petsBase + (lv - 1) * U.PEN.petsPerLevel
end

function U.robux(kind, level)
    local d = U[kind]
    if not d then return 0 end
    return d.robux[level] or d.robux[#d.robux]
end

function U.productId(kind, level)
    local d = U[kind]
    return d and tonumber(d.productIds[level]) or 0
end

return U