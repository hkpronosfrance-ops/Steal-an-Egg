local C = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

C.ZONE_LIST = {}
local RunService = game:GetService("RunService")
if RunService:IsServer() or not RunService:IsRunning() then
    local loader = game:GetService("ServerStorage"):FindFirstChild("ZoneLoader")
    if loader then require(loader).extend(C.ZONE_LIST) end
else
    local reg = game:GetService("ReplicatedStorage"):WaitForChild("ZoneRegistry", 15)
    while not reg do
        warn("[EggConfig] still waiting for the world list from the server")
        reg = game:GetService("ReplicatedStorage"):WaitForChild("ZoneRegistry", 15)
    end
    if reg then
        local extra = reg:GetChildren()
        table.sort(extra, function(a, b) return (a:GetAttribute("Index") or 0) < (b:GetAttribute("Index") or 0) end)
        for _, z in ipairs(extra) do
            table.insert(C.ZONE_LIST, {
                name = z:GetAttribute("Name"), emoji = z:GetAttribute("Emoji"),
                color = z:GetAttribute("Color"), power = z:GetAttribute("Power"),
            })
        end
    end
end

C.ZONES  = #C.ZONE_LIST
C.SAFE_Z = -107
C.X_MIN, C.X_MAX = 1416, 1584
C.LANE_L, C.LANE_R = 1452, 1548

C.Z0, C.BASE, C.STEP = -108, 180, 48
function C.len(n) return C.BASE + (n - 1) * C.STEP end
function C.bounds(n)
    local zTop = C.Z0
    for i = 1, n - 1 do zTop = zTop - C.len(i) end
    return zTop, zTop - C.len(n)
end
function C.zoneAt(z)
    if z > C.SAFE_Z then return 0 end
    for n = 1, C.ZONES do
        local a, b = C.bounds(n)
        if z <= a and z >= b then return n end
    end
    return nil
end

function C.bossSpot(n)
    local zTop, zBot = C.bounds(n)
    local z = zTop + (zBot - zTop) * 0.75
    local side = (n % 2 == 1) and -1 or 1
    return Vector3.new(1500 + side * 64, 0, z)
end

C.STUDS = "rbxassetid://138926013267839"

local function shortPower(v)
    if v < 1 then return "" end
    local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
    local i = 1
    while v >= 1000 and i < #units do v = v / 1000; i += 1 end
    return string.format("%g", math.floor(v * 10 + 0.5) / 10) .. units[i]
end

C.NAMES, C.COLORS, C.EMOJI, C.POWER, C.POWER_N = {}, {}, {}, {}, {}
for n, z in ipairs(C.ZONE_LIST) do
    local prev, prev2 = C.POWER_N[n - 1], C.POWER_N[n - 2]
    local power = tonumber(z.power)
        or (prev and prev2 and prev2 > 0 and prev * math.clamp(prev / prev2, 4, 40))
        or (prev and prev * 10) or 1
    C.NAMES[n] = z.name or ("Zone " .. n)
    C.COLORS[n] = z.color or Color3.fromHSV((n * 0.137) % 1, 0.55, 0.92)
    C.EMOJI[n] = z.emoji or ""
    C.POWER_N[n] = power
    C.POWER[n] = shortPower(power)
end

C.RESPAWN_DELAY     = 8

C.FOREIGN_BOSS_CHASES = false

C.TIER_COLORS = {

    { rgb(232,226,206), rgb(168,200,138), rgb(111,191, 90), rgb(245,210, 74) },
    { rgb(220,233,242), rgb(159,200,224), rgb( 86,168,222), rgb(184,240,255) },
    { rgb(235,217,174), rgb(217,169,106), rgb(210,112, 60), rgb(242,194, 60) },
    { rgb(220,232,196), rgb(143,196,106), rgb( 63,163, 90), rgb(255,154, 60) },
    { rgb(242,246,248), rgb(200,226,240), rgb(140,200,232), rgb(176,242,255) },
    { rgb(224,207,194), rgb(224,138, 74), rgb(224, 69, 31), rgb(255,194, 58) },
    { rgb(198,216,224), rgb( 94,154,176), rgb( 46,127,168), rgb( 53,240,232) },
    { rgb(222,213,184), rgb(168,160, 90), rgb(122,138, 58), rgb(240,178, 58) },
    { rgb(220,212,238), rgb(168,142,224), rgb(122, 90,216), rgb(232,192,255) },
    { rgb(245,228,234), rgb(240,184,206), rgb(232,132,174), rgb(255,208,232) },
    { rgb(230,217,184), rgb(200,178,122), rgb(201,162, 39), rgb(255,224,138) },
    { rgb(220,205,224), rgb(168,104,192), rgb(122, 46,150), rgb(155,255, 74) },
}

function C.eggColor(zone, tier)
    local row = C.TIER_COLORS[zone]
    local c = row and row[tier]
    if c then return c end
    return (C.TIERS[tier] or C.TIERS[1]).color
end

C.GLOW = {
    { shell = false, deco = false, light = 0.0, range =  0 },
    { shell = false, deco = true,  light = 0.0, range =  0 },
    { shell = true,  deco = true,  light = 1.4, range = 11 },
    { shell = true,  deco = true,  light = 3.2, range = 19 },
}

C.TIERS = {
    { name = "Common", weight = 60,    color = Color3.fromRGB(238, 232, 214), value = 1.0,
      glow = false, drops = {70, 22,  7,  1} },
    { name = "Uncommon", weight = 28,  color = Color3.fromRGB(150, 214, 158), value = 2.2,
      glow = false, drops = {35, 40, 20,  5} },
    { name = "Rare", weight = 10,      color = Color3.fromRGB(126, 178, 246), value = 5.0,
      glow = true,  drops = {10, 30, 45, 15} },
    { name = "Legendary", weight = 2, color = Color3.fromRGB(248, 196,  92), value = 12.0,
      glow = true,  drops = { 2, 13, 45, 40} },
}

C.EGG_BASE_H = 3.5
C.SIZES = {
    { name = "Tiny",   weight = 30.0, scale = 0.35, income =  0.5, carry = 1.00 },
    { name = "Small",  weight = 34.0, scale = 0.60, income =  0.8, carry = 0.96 },
    { name = "Normal", weight = 24.0, scale = 1.00, income =  1.0, carry = 0.90 },
    { name = "Large",  weight =  9.0, scale = 1.70, income =  2.0, carry = 0.82 },
    { name = "Huge",   weight =  2.5, scale = 3.00, income =  5.0, carry = 0.72 },
    { name = "Giant",  weight =  0.5, scale = 6.00, income = 12.0, carry = 0.60 },
}

function C.nestScaleFor(eggScale)
    return 1 + (eggScale - 1) * 0.45
end

C.ZONE_BASE   = {1, 4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144, 1048576, 4194304}

C.SPEED_START = 1
C.COINS_START = 0
C.WALK_MAX    = 100e12
C.SPEED_MAX   = math.max(C.WALK_MAX, (C.POWER_N[C.ZONES] or 0) * 20)

C.SIZE_REQ = {1.0, 1.3, 2.0, 3.5, 7.0, 15.0}

function C.requiredSpeed(zone, sizeIdx)
    return (C.POWER_N[zone] or 1) * (C.SIZE_REQ[sizeIdx] or 1)
end

local WALK_BASE = 16
local WALK_RANGE = 174
local WALK_CURVE = 1.6
C.WALK_BASE, C.WALK_RANGE, C.WALK_CURVE = WALK_BASE, WALK_RANGE, WALK_CURVE

function C.walkForSpeed(speed)
    speed = math.clamp(speed, 0, C.SPEED_MAX)
    local t = math.min(1, math.log10(1 + speed) / math.log10(1 + C.WALK_MAX))
    return C.WALK_BASE + C.WALK_RANGE * t ^ C.WALK_CURVE
end

C.BOSS_MULT_MIN = 0.70
C.BOSS_MULT_MAX = 4.50
function C.bossMultFor(playerSpeed, zone, sizeIdx)
    local req = C.requiredSpeed(zone, sizeIdx)
    local ratio = req / math.max(playerSpeed, 0.01)
    return math.clamp(0.97 * ratio ^ 0.55, C.BOSS_MULT_MIN, C.BOSS_MULT_MAX)
end

function C.bossSpeedFor(playerSpeed, zone, sizeIdx)
    local walk  = C.walkForSpeed(playerSpeed)
    local carry = C.SIZES[sizeIdx] and C.SIZES[sizeIdx].carry or 1
    return walk * C.bossMultFor(playerSpeed, zone, sizeIdx) * carry
end

function C.hitFor(playerSpeed, zone, sizeIdx)
    local ratio = C.requiredSpeed(zone, sizeIdx) / math.max(playerSpeed, 0.01)
    local f = math.clamp(ratio ^ 0.30, 1.0, 3.0)
    return {
        back = C.BOSS.knockback * math.min(f, 2.0),
        up   = C.BOSS.knockUp   * math.min(f, 1.35),
        stun = C.BOSS.stunTime  * f,
        f    = f,
    }
end

local UNITS = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function C.fmtShort(v)
    v = tonumber(v) or 0
    if v < 0 then return "-" .. C.fmtShort(-v) end
    if v < 1000 then
        if v == math.floor(v) then return string.format("%d", v) end
        return (string.format("%.1f", math.floor(v * 10) / 10):gsub("%.0$", ""))
    end
    local big = v >= 1e5
    local step = 1
    while v >= 1000 and step < #UNITS do
        v = v / 1000
        step += 1
    end
    local d = big and 100 or 10
    local text = string.format(big and "%.2f" or "%.1f", math.floor(v * d) / d)
    text = text:gsub("%.?0+$", "")
    return text .. UNITS[step]
end

function C.fmtMoney(v)
    return "$" .. C.fmtShort(v)
end

function C.fmtSpeed(v)
    v = tonumber(v) or 0
    if v >= 1000 then return C.fmtShort(v) end
    if v >= 10 then return string.format("%d", math.floor(v)) end
    return string.format("%.2f", math.floor(v * 100) / 100)
end

C.BOSS = {

    baseHeight   = 8,

    maxWidth     = 36,
    growth       = 1.15,
    speed        = {44, 44, 45, 45, 46, 46, 47, 47, 48, 48, 49, 50},
    catchRadius  = 9,
    knockback    = 90,
    knockUp      = 45,
    stunTime     = 1.6,
    hoverY       = 4,
    returnSpeed  = 70,
    fetchSpeed   = 82,
    carryBackSpd = 80,
    idleBob      = 1.2,
    grabRadius   = 7,

    closeRange   = 60,
    closeSpeed   = 2.60,
}

C.GEAR = {
    stickRange = 13, stickArc = 0.35, stickCd = 1.2,
    stickBack = 85, stickUp = 42, stickStun = 1.4,
    trapCd = 2, trapAhead = 6.5, trapOwnerGrace = 2.5, trapArm = 1.0,
    trapLife = 120, trapStun = 6, trapRadius = 4.5,
    maxTraps = 3,
}

C.PET_PAYOUT_EVERY = 1.0

C.INDEX = {
    MONEY_SECONDS = 120, MONEY_SIZE = 3, MONEY_TIER = 2,
    SPEED_NEXT_ZONE_SHARE = 0.5, SPEED_LAST_ZONE_MULT = 2,
    SLOT_DIVISOR = 4,
}

function C.pickWeighted(list, rng)
    local total = 0
    for _, e in ipairs(list) do total = total + (e.weight or 1) end
    local r = (rng and rng:NextNumber() or math.random()) * total
    for i, e in ipairs(list) do
        r = r - (e.weight or 1)
        if r <= 0 then return e, i end
    end
    return list[#list], #list
end

function C.eggValue(zone, tierIndex, sizeIndex)
    return (C.ZONE_BASE[zone] or 1) * C.TIERS[tierIndex].value * C.SIZES[sizeIndex].income
end

C.HATCH_BASE = 20
C.HATCH_SIZE = { 1, 1.6, 2.6, 5, 9, 18 }
C.HATCH_TIER = { 1, 1.6, 3.2, 10 }
C.HATCH_ZONE = 1.2328

function C.hatchTime(zone, size, tier)
    zone = math.clamp(math.floor(tonumber(zone) or 1), 1, math.max(C.ZONES, 1))
    size = math.clamp(math.floor(tonumber(size) or 1), 1, #C.HATCH_SIZE)
    tier = math.clamp(math.floor(tonumber(tier) or 1), 1, #C.HATCH_TIER)
    local t = C.HATCH_BASE
        * C.HATCH_SIZE[size]
        * C.HATCH_TIER[tier]
        * C.HATCH_ZONE ^ (zone - 1)
    return math.floor(t + 0.5)
end

function C.fmtTime(seconds)
    seconds = math.max(0, math.floor(seconds + 0.5))
    if seconds < 60 then return seconds .. "s" end
    if seconds < 3600 then
        return ("%dm %02ds"):format(seconds // 60, seconds % 60)
    end
    return ("%dh %02dm"):format(seconds // 3600, (seconds % 3600) // 60)
end

C.ANIMAL_SCALE = { 0.75, 1.05, 1.5, 3.0, 7.0, 15.0 }

C.ANIMAL_PEN_FILL = 0.80

C.ANIMAL_INCOME_BASE = 1
C.ANIMAL_INCOME_SIZE = { 1, 2, 5, 15, 60, 300 }
C.ANIMAL_INCOME_TIER = { 1, 4, 25, 200 }
C.ANIMAL_INCOME_ZONE = 4.2570

function C.animalIncome(zone, size, tier)
    zone = math.clamp(math.floor(tonumber(zone) or 1), 1, math.max(C.ZONES, 1))
    size = math.clamp(math.floor(tonumber(size) or 1), 1, #C.ANIMAL_INCOME_SIZE)
    tier = math.clamp(math.floor(tonumber(tier) or 1), 1, #C.ANIMAL_INCOME_TIER)
    return C.ANIMAL_INCOME_BASE
        * C.ANIMAL_INCOME_SIZE[size]
        * C.ANIMAL_INCOME_TIER[tier]
        * C.ANIMAL_INCOME_ZONE ^ (zone - 1)
end

function C.petIncome(zone, size, tier, luck)
    return C.animalIncome(zone, size, tier) * (1 + (tonumber(luck) or 0) / 100)
end

function C.rollTier(rng, luck)
    luck = math.max(1, tonumber(luck) or 1)
    if luck <= 1 then
        local _, index = C.pickWeighted(C.TIERS, rng)
        return index
    end
    local boosted = {}
    for i, t in ipairs(C.TIERS) do
        boosted[i] = { weight = (t.weight or 1) * luck ^ ((i - 1) / math.max(#C.TIERS - 1, 1)) }
    end
    local _, index = C.pickWeighted(boosted, rng)
    return index
end
for n = #C.ZONE_BASE + 1, C.ZONES do C.ZONE_BASE[n] = C.ZONE_BASE[n - 1] * 4 end
for n = #C.TIER_COLORS + 1, C.ZONES do
    local c = C.COLORS[n]
    local white = Color3.new(1, 1, 1)
    C.TIER_COLORS[n] = { white:Lerp(c, 0.18), white:Lerp(c, 0.55), c, rgb(255, 214, 90) }
end
for n = #C.BOSS.speed + 1, C.ZONES do C.BOSS.speed[n] = C.BOSS.speed[n - 1] end

if RunService:IsServer() and RunService:IsRunning() then
    local loader = game:GetService("ServerStorage"):FindFirstChild("ZoneLoader")
    if loader then require(loader).build(C) end
end

return C