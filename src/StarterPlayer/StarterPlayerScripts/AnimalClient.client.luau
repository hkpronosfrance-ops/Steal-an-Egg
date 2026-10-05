local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Rig = require(RS:WaitForChild("AnimalRig"))
local Cfg = require(RS:WaitForChild("EggConfig"))

local plr = Players.LocalPlayer
local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens", 120)
local folder = map:WaitForChild("PlacedAnimals", 30)
if not folder then warn("[PETS] PlacedAnimals folder missing") return end

local INSET = 7
local NEAR = 70
local FAR = 150
local STRIDE = 2.2
local FAR_STEP = 16
local TURN_OK = math.rad(35)

local rects = {}
local function measure(pen)
    local sign = pen:FindFirstChild("Sign")
    local lo = Vector3.new(1e9, 1e9, 1e9)
    local hi = Vector3.new(-1e9, -1e9, -1e9)
    for _, p in ipairs(pen:GetDescendants()) do
        if p:IsA("BasePart") and not (sign and p:IsDescendantOf(sign)) then
            lo = lo:Min(p.Position - p.Size / 2)
            hi = hi:Max(p.Position + p.Size / 2)
        end
    end
    rects[pen.Name] = {
        minX = lo.X + INSET, maxX = hi.X - INSET,
        minZ = lo.Z + INSET, maxZ = hi.Z - INSET,
    }
end
for _, pen in ipairs(pens:GetChildren()) do measure(pen) end

for _, pen in ipairs(pens:GetChildren()) do
    pen:GetAttributeChangedSignal("PlotLevel"):Connect(function()
        task.wait(0.3)
        measure(pen)
        task.wait(0.7)
        measure(pen)
    end)
end

local PLATE_W, PLATE_H = 150, 66
local PLATE_REF = 22
local PLATE_MIN = 0.22

local TIER_INK = {
    [1] = Color3.fromRGB(236, 232, 214),
    [2] = Color3.fromRGB(150, 214, 158),
    [3] = Color3.fromRGB(126, 178, 246),
    [4] = Color3.fromRGB(248, 196,  92),
}

local function line(parent, tune, order, text, colour, size)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size = UDim2.fromScale(1, (size + 6) / PLATE_H)
    l.LayoutOrder = order
    l.Font = Enum.Font.FredokaOne
    l.Text = text
    l.TextColor3 = colour
    l.TextScaled = true
    l.Parent = parent
    local cap = Instance.new("UITextSizeConstraint")
    cap.MaxTextSize = size
    cap.Parent = l
    local edge = Instance.new("UIStroke")
    edge.Color = Color3.fromRGB(18, 16, 20)
    edge.Thickness = math.max(2, size * 0.13)
    edge.Parent = l

    tune[#tune + 1] = { cap, "MaxTextSize", cap.MaxTextSize }
    tune[#tune + 1] = { edge, "Thickness", edge.Thickness }
    return l
end

local function plate(model, root, height)
    local old = root:FindFirstChild("AnimalTag")
    if old then old:Destroy() end

    local tier = tonumber(model:GetAttribute("AnimalTier")) or 1
    local income = tonumber(model:GetAttribute("Income")) or 0
    local species = model:GetAttribute("Species") or model.Name
    local rarity = model:GetAttribute("Rarity")
        or (Cfg.TIERS[tier] and Cfg.TIERS[tier].name) or "Common"

    local tune = {}

    local bb = Instance.new("BillboardGui")
    bb.Name = "AnimalTag"
    bb.AlwaysOnTop = false
    bb.LightInfluence = 0
    local boxCF, box = model:GetBoundingBox()
    local top = boxCF.Position.Y + box.Y / 2 - root.Position.Y
    local grow = math.clamp(box.Y / 3.5, 1, 3.5)
    bb.Size = UDim2.fromOffset(PLATE_W, PLATE_H)
    bb.SizeOffset = Vector2.new(0, 0.5)
    bb.StudsOffsetWorldSpace = Vector3.new(0, top + 0.3 + box.Y * 0.04, 0)
    bb.MaxDistance = 160 + 60 * (grow - 1)
    bb.Adornee = root
    bb.Parent = root

    local col = Instance.new("UIListLayout")
    col.FillDirection = Enum.FillDirection.Vertical
    col.SortOrder = Enum.SortOrder.LayoutOrder
    col.HorizontalAlignment = Enum.HorizontalAlignment.Center
    col.VerticalAlignment = Enum.VerticalAlignment.Bottom
    col.Parent = bb

    line(bb, tune, 1, rarity, TIER_INK[tier] or TIER_INK[1], 15)
    line(bb, tune, 2, species, Color3.fromRGB(255, 255, 255), 17)
    line(bb, tune, 3, "$" .. Cfg.fmtSpeed(income) .. "/s", Color3.fromRGB(126, 246, 118), 16)
    return { bb = bb, tune = tune, f = 1, grow = grow }
end

local function fitPlate(tag, dist)
    local grow = tag.grow or 1
    local f = math.clamp(PLATE_REF * grow / math.max(dist, 1), PLATE_MIN, math.max(1, grow * 0.4))
    if math.abs(f - tag.f) < 0.01 then return end
    tag.f = f
    tag.bb.Size = UDim2.fromOffset(PLATE_W * f, PLATE_H * f)
    for _, t in ipairs(tag.tune) do
        t[1][t[2]] = math.max(1, t[3] * f)
    end
end

local function legOf(seed, n, rect, speed, from)
    local rnd = Random.new(seed * 7919 + n * 104729)
    local to = Vector3.new(
        rnd:NextNumber(rect.minX, rect.maxX), from.Y,
        rnd:NextNumber(rect.minZ, rect.maxZ))
    local dist = (to - from).Magnitude
    return to, dist / speed, rnd:NextNumber(2.5, 7.0)
end

local function roomOf(rect, pad)
    return {
        minX = math.min(rect.minX + pad, (rect.minX + rect.maxX) / 2),
        maxX = math.max(rect.maxX - pad, (rect.minX + rect.maxX) / 2),
        minZ = math.min(rect.minZ + pad, (rect.minZ + rect.maxZ) / 2),
        maxZ = math.max(rect.maxZ - pad, (rect.minZ + rect.maxZ) / 2),
    }
end

local function turnOf(was, dir)
    was = Vector3.new(was.X, 0, was.Z)
    dir = Vector3.new(dir.X, 0, dir.Z)
    if was.Magnitude < 0.01 or dir.Magnitude < 0.01 then return 0 end
    local ang = math.acos(math.clamp(was.Unit:Dot(dir.Unit), -1, 1))
    if ang <= TURN_OK then return 0 end
    return math.min(math.log(math.tan(math.min(ang, 3.1) / 2) / math.tan(TURN_OK / 2)) / 6, 0.9)
end

local live = {}

local function adopt(model)
    if live[model] then return end

    local penName
    for _ = 1, 40 do
        penName = model:GetAttribute("Pen")
        if penName and rects[penName] then break end
        task.wait(0.1)
        if not model.Parent then return end
    end
    local rect = penName and rects[penName]
    if not rect then
        warn(("[PETS] %s has no pen (Pen=%s)"):format(model.Name, tostring(penName)))
        return
    end

    local ok, rig = pcall(Rig.build, model)
    if not (ok and rig) then
        warn(("[PETS] rig for %s failed: %s"):format(model.Name, tostring(rig)))
        return
    end

    local start = model:GetPivot().Position

    local _, box = model:GetBoundingBox()
    local length = math.max(box.X, box.Z)
    local speed = math.clamp(1.6 + length * 0.25, 1.8, 9)
    local stride = math.max(1.2, length * 0.7)

    local pad = length / 2
    local room = roomOf(rect, pad)

    local rootName = model:GetAttribute("RootPart")
    local rootPart = rootName and model:FindFirstChild(rootName)
    local tag
    if rootPart then
        local _, tall = model:GetBoundingBox()
        local made, out = pcall(plate, model, rootPart, tall.Y)
        if made then tag = out end
    end

    live[model] = {
        rig = rig,
        tag = tag,
        rect = room,
        penName = penName,
        pad = pad,
        seed = model:GetAttribute("Seed") or 1,
        spawnAt = model:GetAttribute("SpawnAt") or workspace:GetServerTimeNow(),
        groundY = model:GetAttribute("GroundY") or start.Y,
        speed = speed,
        stride = stride,
        n = 0,
        legStart = 0,
        from = start,
        to = start,
        walk = 0,
        idle = 2,
        turn = 0,
        slot = math.random(0, FAR_STEP - 1),
        phase = 0,
        facing = model:GetPivot().LookVector,
    }
    local s = live[model]
    s.to, s.walk, s.idle = legOf(s.seed, 1, room, speed, start)
    s.turn = turnOf(s.facing, s.to - start)
end

for _, m in ipairs(folder:GetChildren()) do adopt(m) end
folder.ChildAdded:Connect(function(m) task.wait(0.15) adopt(m) end)
folder.ChildRemoved:Connect(function(m) live[m] = nil end)

local frame = 0

RunService.Heartbeat:Connect(function(dt)
    frame += 1
    local now = workspace:GetServerTimeNow()

    local cam = workspace.CurrentCamera
    local eye = cam and cam.CFrame.Position
    local ch = plr.Character
    local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
    local here = hrp and hrp.Position

    for model, s in pairs(live) do
        if not model.Parent then
            live[model] = nil
        elseif s.rig.parts[1] and not s.rig.parts[1].part:IsDescendantOf(model) then

            live[model] = nil
            task.spawn(adopt, model)
        else
            local t = now - s.spawnAt

            local guard = 0
            while t > s.legStart + s.walk + s.idle and guard < 4000 do
                s.legStart += s.walk + s.idle
                s.n += 1
                local was = s.to - s.from
                s.from = s.to
                local rect = rects[s.penName]
                if rect then s.rect = roomOf(rect, s.pad) end
                s.to, s.walk, s.idle = legOf(s.seed, s.n + 1, s.rect, s.speed, s.from)
                s.turn = turnOf(was, s.to - s.from)
                guard += 1
            end

            local into = t - s.legStart
            local moving = into < s.turn + s.walk and s.walk > 0.05
            local pos, dir

            if moving then
                local u = math.max(into - s.turn, 0) / s.walk

                local e = u * u * (3 - 2 * u)
                pos = s.from:Lerp(s.to, e)
                local d = s.to - s.from
                d = Vector3.new(d.X, 0, d.Z)
                if d.Magnitude > 0.01 then dir = d.Unit end
                s.phase += (s.speed * dt) / s.stride * math.pi * 2
            else
                pos = s.to
            end

            if dir then

                if s.facing:Dot(dir) < -0.98 then dir = (dir + s.facing:Cross(Vector3.yAxis) * 0.3).Unit end
                s.facing = s.facing:Lerp(dir, math.clamp(dt * 6, 0, 1))
                if s.facing.Magnitude > 0.01 then s.facing = s.facing.Unit end
            end

            local d = math.min(
                eye and (pos - eye).Magnitude or math.huge,
                here and (pos - here).Magnitude or math.huge)
            if d == math.huge then d = 0 end

            if s.tag and eye then fitPlate(s.tag, (pos - eye).Magnitude) end

            local step = (d < NEAR) and 1 or ((d < FAR) and 2 or FAR_STEP)
            if (frame + s.slot) % step == 0 then
                local ground = Vector3.new(pos.X, s.groundY, pos.Z)
                local cf = CFrame.lookAt(ground, ground + s.facing)
                Rig.pose(s.rig, cf, s.phase, now, moving)
            end
        end
    end
end)