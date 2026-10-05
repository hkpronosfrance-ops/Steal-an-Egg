local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Cycle = require(RS:WaitForChild("DayNightConfig"))

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("DayNight")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "DayNight"
    remote.Parent = Remotes
end

local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")

local DAY_LOOK = {
    clock = Cycle.DAY_CLOCK,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    atmoColor = atmosphere and atmosphere.Color,
    atmoDecay = atmosphere and atmosphere.Decay,
}
local NIGHT_LOOK = {
    clock = Cycle.NIGHT_CLOCK,
    Brightness = Cycle.NIGHT_BRIGHTNESS,
    Ambient = Cycle.NIGHT_AMBIENT,
    OutdoorAmbient = Cycle.NIGHT_OUTDOOR,
    atmoColor = Cycle.NIGHT_ATMOS_COLOR,
    atmoDecay = Cycle.NIGHT_ATMOS_DECAY,
}

local clockValue = Instance.new("NumberValue")
clockValue.Value = Lighting.ClockTime
clockValue.Changed:Connect(function(v)
    Lighting.ClockTime = v % 24
end)

local function applyLook(look, seconds)
    local now = clockValue.Value % 24
    clockValue.Value = now

    local goal = now + (look.clock - now) % 24
    if seconds <= 0 then
        clockValue.Value = goal
        Lighting.Brightness = look.Brightness
        Lighting.Ambient = look.Ambient
        Lighting.OutdoorAmbient = look.OutdoorAmbient
        if atmosphere and look.atmoColor then
            atmosphere.Color = look.atmoColor
            atmosphere.Decay = look.atmoDecay
        end
        return
    end
    local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
    TweenService:Create(clockValue, info, { Value = goal }):Play()
    TweenService:Create(Lighting, info, {
        Brightness = look.Brightness,
        Ambient = look.Ambient,
        OutdoorAmbient = look.OutdoorAmbient,
    }):Play()

    if atmosphere and look.atmoColor then
        TweenService:Create(atmosphere, info, { Color = look.atmoColor, Decay = look.atmoDecay }):Play()
    end
end

local Players = game:GetService("Players")
local EggCfg = require(RS:WaitForChild("EggConfig"))
local map = workspace:WaitForChild("GameWorld")

local function findGap()
    local walls = map:FindFirstChild("Walls")
    local spawnPart = map:FindFirstChild("MainSpawn")
    local midX = spawnPart and spawnPart.Position.X or 1500
    local left, right
    for _, w in ipairs(walls and walls:GetChildren() or {}) do
        if w:IsA("BasePart") and w.Name == "WallSegment" and w.Size.X > w.Size.Z
            and math.abs(w.Position.Z - EggCfg.SAFE_Z) < 15 then
            if w.Position.X < midX then left = w else right = w end
        end
    end
    if not (left and right) then
        warn("[DAYNIGHT] no gap in the wall found - the map will not close at night")
        return nil
    end
    return {
        x0 = left.Position.X + left.Size.X / 2,
        x1 = right.Position.X - right.Size.X / 2,
        z = left.Position.Z,
        y0 = left.Position.Y - left.Size.Y / 2,
        y1 = left.Position.Y + left.Size.Y / 2,
        thick = left.Size.Z,
    }
end
local GAP = findGap()
local gate

local GATE_Z = EggCfg.SAFE_Z - 0.5

local function buildGate()
    local g = GAP
    local width, height = g.x1 - g.x0, g.y1 - g.y0
    local cx = (g.x0 + g.x1) / 2

    local model = Instance.new("Model")
    model.Name = "NightGate"
    model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent

    local walls = map:FindFirstChild("Walls")
    local wallTop = g.y1
    for _, w in ipairs(walls and walls:GetChildren() or {}) do
        if w:IsA("BasePart") and math.abs(w.Position.Z - g.z) < 10 then
            wallTop = math.max(wallTop, w.Position.Y + w.Size.Y / 2)
        end
    end
    local wallH = wallTop - g.y0

    local function white(part, face)
        local sg = Instance.new("SurfaceGui")
        sg.Name = "White"
        sg.Face = face
        sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
        sg.PixelsPerStud = 1
        sg.LightInfluence = 0
        sg.Parent = part
        local f = Instance.new("Frame")
        f.BorderSizePixel = 0
        f.BackgroundColor3 = Cycle.GATE_COLOR
        f.Size = UDim2.fromScale(1, 1)
        f.Parent = sg
    end

    local wall = Instance.new("Part")
    wall.Name = "Gate"
    wall.Anchored = true
    wall.CastShadow = false
    wall.Material = Enum.Material.SmoothPlastic
    wall.Color = Cycle.GATE_COLOR
    wall.Size = Vector3.new(width, wallH, 2)
    wall.CFrame = CFrame.new(cx, g.y0 + wallH / 2, GATE_Z)
    wall.Parent = model
    white(wall, Enum.NormalId.Back)
    white(wall, Enum.NormalId.Top)

    local _, roofEnd = EggCfg.bounds(Cycle.ROOF_ZONES)
    local x0, x1 = math.huge, -math.huge
    for _, w in ipairs(walls and walls:GetChildren() or {}) do
        if w:IsA("BasePart") and w.Position.Z < g.z - 2 and w.Position.Z > roofEnd then
            x0 = math.min(x0, w.Position.X - w.Size.X / 2)
            x1 = math.max(x1, w.Position.X + w.Size.X / 2)
        end
    end
    if x0 > x1 then x0, x1 = g.x0 - g.thick, g.x1 + g.thick end
    local roofLen = (GATE_Z + 1) - roofEnd
    local roof = Instance.new("Part")
    roof.Name = "Roof"
    roof.Anchored = true
    roof.CastShadow = false
    roof.Material = Enum.Material.SmoothPlastic
    roof.Color = Cycle.GATE_COLOR
    roof.Size = Vector3.new(x1 - x0, 2, roofLen)
    roof.CFrame = CFrame.new((x0 + x1) / 2, wallTop + 1, (GATE_Z + 1) - roofLen / 2)
    roof.Parent = model
    white(roof, Enum.NormalId.Top)
    white(roof, Enum.NormalId.Back)

    local top = Instance.new("Part")
    top.Name = "GateBarrier"
    top.Anchored = true
    top.CastShadow = false
    top.Transparency = 1
    top.Size = Vector3.new(width, 400, 2)
    top.CFrame = CFrame.new(cx, wallTop + 200, GATE_Z)
    top.Parent = model

    return model
end

local function fadeOut(model)
    local info = TweenInfo.new(Cycle.GATE_FADE, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            d.CanCollide = false
            if d.Transparency < 1 then TweenService:Create(d, info, { Transparency = 1 }):Play() end
        elseif d:IsA("Frame") then
            TweenService:Create(d, info, { BackgroundTransparency = 1 }):Play()
        end
    end
    task.delay(Cycle.GATE_FADE + 0.2, function() model:Destroy() end)
end

local function setGate(closed)
    if not GAP then return end
    if closed then
        if not (gate and gate.Parent) then
            gate = buildGate()
            gate.Parent = map
        end
    elseif gate then
        fadeOut(gate)
        gate = nil
    end
end

local function sendHome(plr)
    if _G.EggAdmin and _G.EggAdmin.drop then pcall(_G.EggAdmin.drop, plr) end
    local spawnPart = map:FindFirstChild("MainSpawn")
    local base = spawnPart and spawnPart.Position or Vector3.new(1500, 0, -20)
    local offset = Vector3.new(math.random(-4, 4), 4, math.random(-4, 4))
    if plr.Character then plr.Character:PivotTo(CFrame.new(base + offset)) end
    remote:FireClient(plr, "mapClosed")
end

local function sweepMap(deep)
    local limit = deep and (GATE_Z - 3) or EggCfg.SAFE_Z
    for _, plr in ipairs(Players:GetPlayers()) do
        local ch = plr.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if root and hum and hum.Health > 0 and root.Position.Z < limit then
            sendHome(plr)
        end
    end
end

local state = { phase = "day", endsAt = 0, resetDone = false, dusk = false, dawn = false }

local function setPhase(phase, seconds, instant)
    state.phase = phase
    state.endsAt = workspace:GetServerTimeNow()
        + (seconds or ((phase == "day") and Cycle.DAY_SECONDS or Cycle.NIGHT_SECONDS))
    state.resetDone = false
    workspace:SetAttribute("CyclePhase", phase)
    workspace:SetAttribute("CycleEndsAt", state.endsAt)

    if phase == "night" then
        if not state.dusk then applyLook(NIGHT_LOOK, instant and 0 or Cycle.NIGHT_FADE) end
    else

        if not state.dawn then applyLook(DAY_LOOK, instant and 0 or Cycle.TRANSITION_SECONDS) end
    end
    state.dusk = false
    state.dawn = false
    setGate(phase == "night")
    if phase == "night" then sweepMap() end
end

local function resetEggs()
    local made = {}
    if _G.EggAdmin and _G.EggAdmin.resetAll then
        local ok, res = pcall(_G.EggAdmin.resetAll)
        if ok and type(res) == "table" then
            made = res
        elseif not ok then
            warn("[DAYNIGHT] egg reset failed: " .. tostring(res))
        end
    end
    local legendary = {}
    for _, e in ipairs(made) do
        if e.tier == Cycle.ANNOUNCE_TIER then table.insert(legendary, e.zone) end
    end
    remote:FireAllClients("reset", { count = #made, legendary = legendary })
    return #made, legendary
end

_G.DayNight = {
    setPhase = setPhase,
    resetEggs = resetEggs,
    state = function() return state.phase, state.endsAt end,
    sweepMap = sweepMap,
}

task.spawn(function()
    for _ = 1, 100 do
        if _G.EggAdmin then break end
        task.wait(0.2)
    end
    setPhase("day", nil, true)
    while true do
        task.wait(0.2)
        if state.phase == "night" then sweepMap(true) end
        local left = state.endsAt - workspace:GetServerTimeNow()
        if state.phase == "day" and not state.dusk and left <= Cycle.TRANSITION_SECONDS then
            state.dusk = true
            applyLook(NIGHT_LOOK, math.max(left, 0.3))
        end
        if state.phase == "night" and not state.dawn and left <= Cycle.DAWN_SECONDS then
            state.dawn = true
            applyLook(DAY_LOOK, math.max(left, 0.3))
        end
        if state.phase == "night" and not state.resetDone and left <= Cycle.RESET_AT then
            state.resetDone = true
            resetEggs()
        end
        if left <= 0 then
            setPhase((state.phase == "day") and "night" or "day")
        end
    end
end)