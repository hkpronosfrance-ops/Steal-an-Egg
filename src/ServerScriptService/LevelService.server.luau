local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens")
local mills = map:WaitForChild("Treadmills")

local UpgradeCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("UpgradeConfig"))
local MAX_LEVEL = UpgradeCfg.MAX_LEVEL
local SIZE_LEVELS = 6
local SPAN = 9.6

local FENCE_COLOURS = {
    [7]  = { post = Color3.fromRGB(104, 132, 196), rail = Color3.fromRGB(146, 182, 244) },
    [8]  = { post = Color3.fromRGB( 92, 168, 118), rail = Color3.fromRGB(136, 226, 158) },
    [9]  = { post = Color3.fromRGB(158, 108, 200), rail = Color3.fromRGB(206, 152, 250) },
    [10] = { post = Color3.fromRGB(206, 116,  64), rail = Color3.fromRGB(252, 168,  92) },
    [11] = { post = Color3.fromRGB(190,  58,  74), rail = Color3.fromRGB(248, 104, 118) },
    [12] = { post = Color3.fromRGB(168, 132,  30), rail = Color3.fromRGB(255, 214,  76),
             neon = true },
}

local MILL_COLOURS = {
    Color3.fromRGB( 72, 208, 240), Color3.fromRGB( 74, 162, 250),
    Color3.fromRGB(120, 130, 252), Color3.fromRGB(176, 110, 248),
    Color3.fromRGB(232, 100, 224), Color3.fromRGB(250, 88, 150),
    Color3.fromRGB(252, 96, 84),   Color3.fromRGB(254, 148, 52),
    Color3.fromRGB(252, 204, 48),  Color3.fromRGB(178, 230, 56),
    Color3.fromRGB( 68, 220, 122), Color3.fromRGB(255, 214, 76),
}

local function fenceParts(pen)
    local sign = pen:FindFirstChild("Sign")
    local list = {}
    for _, p in ipairs(pen:GetDescendants()) do
        if p:IsA("BasePart") and not (sign and p:IsDescendantOf(sign)) then
            list[#list + 1] = p
        end
    end
    return list
end

local function bounds(parts)
    local lo = Vector3.new(1e9, 1e9, 1e9)
    local hi = Vector3.new(-1e9, -1e9, -1e9)
    for _, p in ipairs(parts) do
        lo = lo:Min(p.Position - p.Size / 2)
        hi = hi:Max(p.Position + p.Size / 2)
    end
    return lo, hi
end

local function sideOf(p, lo, hi)
    local midX, midZ = (lo.X + hi.X) / 2, (lo.Z + hi.Z) / 2
    local nx = math.abs(p.Position.X - midX) / math.max(0.01, (hi.X - lo.X) / 2)
    local nz = math.abs(p.Position.Z - midZ) / math.max(0.01, (hi.Z - lo.Z) / 2)
    if nx > nz then
        return p.Position.X < midX and "W" or "E"
    end
    return p.Position.Z < midZ and "S" or "N"
end

local function findEntrance(parts, lo, hi)
    local bySide = { W = {}, E = {}, S = {}, N = {} }
    for _, p in ipairs(parts) do
        table.insert(bySide[sideOf(p, lo, hi)], p)
    end
    local best, bestGap = nil, 0
    for key, list in pairs(bySide) do
        local along = (key == "S" or key == "N") and "X" or "Z"
        local coords = {}
        for _, p in ipairs(list) do coords[#coords + 1] = p.Position[along] end
        table.sort(coords)
        for i = 2, #coords do
            local d = coords[i] - coords[i - 1]
            if d > bestGap then bestGap = d best = key end
        end
    end
    return best
end

local plots = {}

local function describe(pen)
    local parts = fenceParts(pen)
    if #parts == 0 then return end
    local lo, hi = bounds(parts)
    local front = findEntrance(parts, lo, hi) or "S"

    local axis = (front == "S" or front == "N") and "Z" or "X"
    local dir = (front == "S" or front == "W") and 1 or -1

    local base = {}
    for _, p in ipairs(parts) do
        base[p] = { cf = p.CFrame, colour = p.Color, material = p.Material }
    end

    plots[pen] = {
        pen = pen, axis = axis, dir = dir, front = front,
        base = base, grown = 0, tinted = false,
    }
    pen:SetAttribute("GrowAxis", axis)
    pen:SetAttribute("Entrance", front)
end

local function alongOf(rec, p)
    return p.Position[rec.axis] * rec.dir
end

local function backRow(rec, parts)
    local back
    for _, p in ipairs(parts) do
        if p.Size.Y > 4 then
            local c = alongOf(rec, p)
            if not back or c > back then back = c end
        end
    end
    return back
end

local function grow(rec)
    local parts = fenceParts(rec.pen)
    local back = backRow(rec, parts)
    if not back then return false end

    local shift = (rec.axis == "Z") and Vector3.new(0, 0, SPAN * rec.dir)
                                     or Vector3.new(SPAN * rec.dir, 0, 0)
    local edge = back - SPAN / 2 + 0.05

    local toClone = {}
    for _, p in ipairs(parts) do
        local c = alongOf(rec, p)
        if c > edge then
            p.CFrame = p.CFrame + shift
        elseif c >= back - SPAN - 0.05 then
            toClone[#toClone + 1] = p
        end
    end

    rec.grown += 1
    for _, p in ipairs(toClone) do
        local c = p:Clone()
        c.CFrame = p.CFrame + shift
        c:SetAttribute("GrownStep", rec.grown)
        c.Parent = p.Parent
    end
    return true
end

local function shrink(rec)
    if rec.grown <= 0 then return false end
    local step = rec.grown
    for _, p in ipairs(fenceParts(rec.pen)) do
        if p:GetAttribute("GrownStep") == step then p:Destroy() end
    end

    local parts = fenceParts(rec.pen)
    local back = backRow(rec, parts)
    if not back then return false end
    local shift = (rec.axis == "Z") and Vector3.new(0, 0, -SPAN * rec.dir)
                                     or Vector3.new(-SPAN * rec.dir, 0, 0)
    local edge = back - SPAN / 2 + 0.05
    for _, p in ipairs(parts) do
        if alongOf(rec, p) > edge then p.CFrame = p.CFrame + shift end
    end
    rec.grown -= 1
    return true
end

local function tint(rec, level)
    local scheme = FENCE_COLOURS[level]
    for _, p in ipairs(fenceParts(rec.pen)) do
        local isPost = p.Size.Y > 4
        if scheme then
            p.Color = isPost and scheme.post or scheme.rail
            p.Material = scheme.neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
        else
            local b = rec.base[p]

            if b then
                p.Color = b.colour
                p.Material = b.material
            end
        end
    end
    rec.tinted = scheme ~= nil
end

local function applyPlot(pen)
    local rec = plots[pen]
    if not rec then return end
    local level = math.clamp(math.floor(tonumber(pen:GetAttribute("PlotLevel")) or 1), 1, MAX_LEVEL)
    local wantGrown = math.min(level, SIZE_LEVELS) - 1
    while rec.grown < wantGrown do
        if not grow(rec) then break end
    end
    while rec.grown > wantGrown do
        if not shrink(rec) then break end
    end
    tint(rec, level)
    pen:SetAttribute("AnimalCap", UpgradeCfg.petCap(level))
end

local function showSurfaces(part, visible)
    for _, t in ipairs(part:GetChildren()) do
        if t:IsA("Texture") or t:IsA("Decal") then
            local base = t:GetAttribute("MillTextureTransparency")
            if base == nil then base = t.Transparency t:SetAttribute("MillTextureTransparency", base) end
            t.Transparency = visible and base or 1
        end
    end
end

local function applyMill(mill)
    local level = math.clamp(math.floor(tonumber(mill:GetAttribute("MillLevel")) or 1), 1, MAX_LEVEL)
    local colour = MILL_COLOURS[level] or MILL_COLOURS[1]
    local sign = mill:FindFirstChild("Sign")
    local wood = mill:FindFirstChild("WoodLevelOne")
    for _, p in ipairs(mill:GetDescendants()) do
        if p:IsA("BasePart") and not (sign and p:IsDescendantOf(sign)) then

            if wood and p:IsDescendantOf(wood) then
                p.Transparency = level == 1 and 0 or 1
                showSurfaces(p, level == 1)
                continue
            end
            local original = p:GetAttribute("MillOriginalTransparency")
            if original ~= nil then p.Transparency = level == 1 and 1 or original end
            showSurfaces(p, p.Transparency < 1)
            local keep = p.Name == "belt" or p.Name == "ArrowPad" or p.Name:find("belt")
            if not keep then p.Color = colour end
        end
    end
end

for _, pen in ipairs(pens:GetChildren()) do
    describe(pen)
    applyPlot(pen)
    pen:GetAttributeChangedSignal("PlotLevel"):Connect(function() applyPlot(pen) end)
end

for _, mill in ipairs(mills:GetChildren()) do
    applyMill(mill)
    mill:GetAttributeChangedSignal("MillLevel"):Connect(function() applyMill(mill) end)
end

_G.Levels = {
    MAX = MAX_LEVEL,
    SIZE_LEVELS = SIZE_LEVELS,
    animalCap = UpgradeCfg.petCap,
}

print(("[Level] %d pens, %d treadmills, %d levels (size grows until %d)")
    :format(#pens:GetChildren(), #mills:GetChildren(), MAX_LEVEL, SIZE_LEVELS))