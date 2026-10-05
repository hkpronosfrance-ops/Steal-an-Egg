local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local Cfg = require(RS:WaitForChild("EggConfig"))
local remote = RS:WaitForChild("Remotes"):WaitForChild("Nest")

local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens", 120)

local FENCE_INSET = 5

local gui = Instance.new("ScreenGui")
gui.Name = "NestNotice"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 40
gui.Parent = plr:WaitForChild("PlayerGui")

local note = Instance.new("TextLabel")
note.Name = "Note"
note.BackgroundTransparency = 1
note.AnchorPoint = Vector2.new(0.5, 0.5)
note.Position = UDim2.fromScale(0.5, 0.30)
note.Size = UDim2.fromOffset(760, 56)
note.Font = Enum.Font.FredokaOne
note.TextScaled = true
note.Text = ""
note.Visible = false
note.Parent = gui

local noteSize = Instance.new("UITextSizeConstraint")
noteSize.MaxTextSize = 34
noteSize.Parent = note

local noteEdge = Instance.new("UIStroke")
noteEdge.Color = Color3.fromRGB(24, 8, 8)
noteEdge.Thickness = 4
noteEdge.Parent = note

local noteToken = 0
local function say(text, colour)
    note.Text = text
    note.TextColor3 = colour or Color3.fromRGB(255, 74, 74)
    note.Visible = true
    noteToken += 1
    local mine = noteToken
    task.delay(2.2, function()
        if noteToken == mine then note.Visible = false end
    end)
end

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
    rects[pen] = {
        minX = lo.X + FENCE_INSET, maxX = hi.X - FENCE_INSET,
        minZ = lo.Z + FENCE_INSET, maxZ = hi.Z - FENCE_INSET,
    }
end
for _, pen in ipairs(pens:GetChildren()) do measure(pen) end
pens.ChildAdded:Connect(function(pen) task.wait(0.5) measure(pen) end)

local function penAt(pos)
    for _, pen in ipairs(pens:GetChildren()) do measure(pen) end
    for pen, r in pairs(rects) do
        if pos.X >= r.minX and pos.X <= r.maxX and pos.Z >= r.minZ and pos.Z <= r.maxZ then
            return pen
        end
    end
    return nil
end

local function heldKind()
    local ch = plr.Character
    if not ch then return nil end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") then
            if t:GetAttribute("EggZone") then return "place" end
            if t:GetAttribute("AnimalZone") then return "placeAnimal" end
        end
    end
    return nil
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local function tryPlace(screenPos)
    local action = heldKind()
    if not action then return end
    local ch = plr.Character
    params.FilterDescendantsInstances = {
        ch,
        map:FindFirstChild("PlacedEggs"),
    }
    local ray = cam:ScreenPointToRay(screenPos.X, screenPos.Y)
    local hit = workspace:Raycast(ray.Origin, ray.Direction * 400, params)
    if not hit then return end

    local what = (action == "place") and "eggs" or "pets"
    local pen = penAt(hit.Position)
    if not pen then
        say("You can only place " .. what .. " on your own plot")
        return
    end
    if pen:GetAttribute("OwnerUserId") ~= plr.UserId then
        say("This isn't your plot")
        return
    end
    remote:FireServer(action, hit.Position)
end

UIS.InputBegan:Connect(function(input, busy)
    if busy then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        tryPlace(input.Position)
    end
end)
UIS.TouchTapInWorld:Connect(function(position, busy)
    if busy then return end
    tryPlace(position)
end)

local Paint = require(RS:WaitForChild("AnimalPaint"))

local function flyToMe(info)
    local zone = tonumber(info.zone) or 1

    local lib = (workspace:FindFirstChild("AnimalLibrary") or game:GetService("ReplicatedStorage"):FindFirstChild("AnimalLibrary"))
    for _ = 1, 100 do
        if lib then break end
        task.wait(0.2)
        lib = (workspace:FindFirstChild("AnimalLibrary") or game:GetService("ReplicatedStorage"):FindFirstChild("AnimalLibrary"))
    end
    local folder = lib and lib:FindFirstChild("Zone" .. zone)
    if not folder then return end
    local list = folder:GetChildren()
    table.sort(list, function(a, b) return a.Name < b.Name end)
    if #list == 0 then return end

    local tier = tonumber(info.tier) or 1
    local size = tonumber(info.size) or 1
    local idx = (tier >= 3) and (6 + (tier - 2)) or math.clamp(size, 1, 6)

    local pick = (info.species and folder:FindFirstChild(info.species)) or list[((idx - 1) % #list) + 1]
    if not pick then return end

    local m = pick:Clone()
    pcall(Paint.paint, m, tier)
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CastShadow = false
        end
    end
    local _, box = m:GetBoundingBox()
    local want = 2.2
    if math.max(box.X, box.Y, box.Z) > 0.01 then
        m:ScaleTo(m:GetScale() * (want / math.max(box.X, box.Y, box.Z)))
    end

    local from = Vector3.new(info.x or 0, (info.y or 0) + 1, info.z or 0)
    m:PivotTo(CFrame.new(from))
    m.Parent = workspace

    task.spawn(function()
        local t0 = os.clock()
        local DUR = 0.85
        while os.clock() - t0 < DUR do
            local ch = plr.Character
            local head = ch and (ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart"))
            if not (head and m.Parent) then break end
            local k = (os.clock() - t0) / DUR
            local ease = k * k * (3 - 2 * k)

            local target = head.Position + Vector3.new(0, 1.2, 0)
            local pos = from:Lerp(target, ease) + Vector3.new(0, math.sin(k * math.pi) * 2.2, 0)
            m:PivotTo(CFrame.new(pos) * CFrame.Angles(0, k * math.pi * 3, 0))
            RunService.Heartbeat:Wait()
        end
        if m.Parent then m:Destroy() end
    end)
end

remote.OnClientEvent:Connect(function(action, arg)
    if action == "deny" then
        say(tostring(arg))
    elseif action == "hatched" then

        if type(arg) == "table" then pcall(flyToMe, arg) end
    end
end)

local plates = {}

local EDGE = Color3.fromRGB(18, 18, 26)
local WHITE = Color3.new(1, 1, 1)

local TIER_GRAD = {
    { Color3.fromRGB(255, 255, 255), Color3.fromRGB(186, 198, 216) },
    { Color3.fromRGB(196, 255, 170), Color3.fromRGB( 52, 196,  84) },
    { Color3.fromRGB(150, 232, 255), Color3.fromRGB( 58, 118, 255) },
    { Color3.fromRGB(255, 242, 120), Color3.fromRGB(255, 146,  28) },
}
local READY_GRAD = { Color3.fromRGB(196, 255, 120), Color3.fromRGB( 36, 200,  84) }
local CLOCK_GRAD = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(170, 212, 255) }

local function setGrad(label, pair)
    local g = label:FindFirstChild("PlateGradient")
    if g then g.Color = ColorSequence.new(pair[1], pair[2]) end
end

local PLATE_W, PLATE_H = 240, 40
local TITLE_SIZE, CLOCK_SIZE, EDGE_W = 30, 31, 3
local PLATE_REF = 30
local PLATE_MIN = 0.45

local function fitPlate(p, dist)
    local f = math.clamp(PLATE_REF / math.max(dist, 1), PLATE_MIN, 1)
    if math.abs(f - p.f) < 0.01 then return end
    p.f = f
    p.gui.Size = UDim2.fromOffset(PLATE_W * f, PLATE_H * f)
    p.title.TextSize = math.max(1, TITLE_SIZE * f)
    p.text.TextSize = math.max(1, CLOCK_SIZE * f)
    for _, l in ipairs({ p.title, p.text }) do
        local s = l:FindFirstChildOfClass("UIStroke")
        if s then s.Thickness = math.max(1, EDGE_W * f) end
    end
end

local function plateText(parent, y, h, size)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Size = UDim2.fromScale(1, h / PLATE_H)
    t.Position = UDim2.fromScale(0, y / PLATE_H)
    t.Font = Enum.Font.FredokaOne
    t.TextSize = size
    t.TextColor3 = WHITE
    t.Text = ""
    t.Parent = parent
    local edge = Instance.new("UIStroke")
    edge.Color = EDGE
    edge.Thickness = EDGE_W
    edge.LineJoinMode = Enum.LineJoinMode.Round
    edge.Parent = t
    local g = Instance.new("UIGradient")
    g.Name = "PlateGradient"
    g.Rotation = 90
    g.Parent = t
    return t
end

local function tierTitle(model)
    local tier = tonumber(model:GetAttribute("EggTier")) or 1
    local def = Cfg.TIERS[tier] or Cfg.TIERS[1]
    return (def.name or "") .. " Egg"
end

local function plateFor(model)
    local pp = model.PrimaryPart
    if not pp then return nil end
    local bb = Instance.new("BillboardGui")
    bb.Name = "HatchClock"
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Size = UDim2.fromOffset(PLATE_W, PLATE_H)
    local boxCf, boxSize = model:GetBoundingBox()
    bb.StudsOffsetWorldSpace = Vector3.new(0, boxCf.Position.Y + boxSize.Y / 2 - pp.Position.Y + 1.6, 0)
    bb.MaxDistance = 90
    bb.Adornee = pp
    bb.Parent = pp

    local title = plateText(bb, 0, 40, TITLE_SIZE)
    title.Text = tierTitle(model)
    title.Visible = false
    local clock = plateText(bb, 0, 40, CLOCK_SIZE)

    return { gui = bb, title = title, text = clock, model = model, f = 1 }
end

local function watch(model)
    if plates[model] then return end
    local p = plateFor(model)
    if p then
        plates[model] = p
        return
    end
    local conn
    conn = model.DescendantAdded:Connect(function()
        if model.PrimaryPart then
            conn:Disconnect()
            watch(model)
        end
    end)
    model.AncestryChanged:Connect(function()
        if not model.Parent and conn.Connected then conn:Disconnect() end
    end)
end

local folder = map:WaitForChild("PlacedEggs", 30)
if folder then
    for _, m in ipairs(folder:GetChildren()) do watch(m) end
    folder.ChildAdded:Connect(function(m) task.wait(0.1) watch(m) end)
    folder.ChildRemoved:Connect(function(m) plates[m] = nil end)
end

RunService.Heartbeat:Connect(function()
    local now = workspace:GetServerTimeNow()
    local camPos = workspace.CurrentCamera.CFrame.Position
    for model, p in pairs(plates) do
        if not model.Parent then
            plates[model] = nil
        elseif not (p.gui.Parent and model.PrimaryPart) then
            plates[model] = nil
            if p.gui.Parent then p.gui:Destroy() end
            task.defer(watch, model)
        else
            p.n = (p.n or 0) + 1
            if p.n % 30 == 0 then
                local boxCf, boxSize = model:GetBoundingBox()
                p.gui.StudsOffsetWorldSpace = Vector3.new(0, boxCf.Position.Y + boxSize.Y / 2 - model.PrimaryPart.Position.Y + 1.6, 0)
            end
            local left = (model:GetAttribute("HatchAt") or 0) - now
            local ready = left <= 0
            local text = ready and "READY!" or Cfg.fmtTime(left)
            if p.text.Text ~= text then p.text.Text = text end
            if p.ready ~= ready then
                p.ready = ready
                setGrad(p.text, ready and READY_GRAD or CLOCK_GRAD)
            end
            local tier = model:GetAttribute("EggTier")
            if p.tier ~= tier then
                p.tier = tier
                p.title.Text = tierTitle(model)
                setGrad(p.title, TIER_GRAD[tonumber(tier) or 1] or TIER_GRAD[1])
            end
            local root = model.PrimaryPart
            if root then fitPlate(p, (root.Position - camPos).Magnitude) end

            local owner = model:GetAttribute("OwnerUserId")
            if owner ~= nil and owner ~= plr.UserId then
                local pp = model.PrimaryPart
                local pr = pp and pp:FindFirstChild("Hatch")
                if pr and pr.Enabled then pr.Enabled = false end
            end
        end
    end
end)

local PPS = game:GetService("ProximityPromptService")
local TweenService = game:GetService("TweenService")

local function keyText(prompt, inputType)
    if inputType == Enum.ProximityPromptInputType.Gamepad then
        return (prompt.GamepadKeyCode.Name:gsub("^Button", ""))
    elseif inputType == Enum.ProximityPromptInputType.Touch then
        return "TAP"
    end
    local ok, s = pcall(function() return UIS:GetStringForKeyCode(prompt.KeyboardKeyCode) end)
    if not ok or type(s) ~= "string" or s == "" then s = prompt.KeyboardKeyCode.Name end
    return s:upper()
end

local function promptLabel(parent, font, size, colour, strokeW, strokeAlpha)
    local t = Instance.new("TextLabel")
    t.BackgroundTransparency = 1
    t.Font = font
    t.TextSize = size
    t.TextColor3 = colour
    t.TextXAlignment = Enum.TextXAlignment.Left
    t.Text = ""
    t.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = Color3.new(0, 0, 0)
    s.Thickness = strokeW
    s.Transparency = strokeAlpha
    s.Parent = t
    return t
end

local KEY = 52
local HOLD_COLOUR = Color3.fromRGB(255, 255, 255)
local KEY_TEXT_X = KEY + 12
local PROMPT_W, PROMPT_H = 300, 60
local TextService = game:GetService("TextService")

local function buildPrompt(prompt, inputType)
    local part = prompt.Parent
    if not (part and part:IsA("BasePart")) then return nil end

    local bb = Instance.new("BillboardGui")
    bb.Name = "EggPrompt"
    bb.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    bb.AlwaysOnTop = true
    bb.LightInfluence = 0
    bb.Active = true
    bb.ResetOnSpawn = false

    bb.Size = UDim2.fromOffset(PROMPT_W, PROMPT_H)
    bb.StudsOffset = Vector3.new(0, 0, math.max(part.Size.X, part.Size.Z) * 0.6 + 0.4)
    bb.Adornee = part
    bb.Parent = plr:WaitForChild("PlayerGui")

    local root = Instance.new("Frame")
    root.BackgroundTransparency = 1
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.Position = UDim2.fromScale(0.5, 0.5)
    root.Size = UDim2.fromOffset(PROMPT_W, PROMPT_H)
    root.Parent = bb
    local scale = Instance.new("UIScale")
    scale.Parent = root

    local key = Instance.new("Frame")
    key.Name = "Key"
    key.AnchorPoint = Vector2.new(0, 0.5)
    key.Position = UDim2.new(0, 0, 0.5, 0)
    key.Size = UDim2.fromOffset(KEY, KEY)
    key.BackgroundColor3 = Color3.fromRGB(58, 60, 68)
    key.BackgroundTransparency = 0.2
    key.BorderSizePixel = 0
    key.Parent = root
    Instance.new("UICorner", key).CornerRadius = UDim.new(0.5, 0)

    local setRing = function() end
    if prompt.HoldDuration > 0 then
        key.ZIndex = 3
        key.BackgroundTransparency = 0
        local RING = KEY + 10
        local holder = Instance.new("Frame")
        holder.Name = "HoldRing"
        holder.BackgroundTransparency = 1
        holder.AnchorPoint = Vector2.new(0.5, 0.5)
        holder.Position = UDim2.new(0, KEY / 2, 0.5, 0)
        holder.Size = UDim2.fromOffset(RING, RING)
        holder.ZIndex = 1
        holder.Parent = root

        local track = Instance.new("Frame")
        track.Name = "Track"
        track.Size = UDim2.fromScale(1, 1)
        track.BackgroundColor3 = Color3.new(0, 0, 0)
        track.BackgroundTransparency = 0.55
        track.BorderSizePixel = 0
        track.ZIndex = 1
        track.Parent = holder
        Instance.new("UICorner", track).CornerRadius = UDim.new(0.5, 0)

        local function half(isRight)
            local clip = Instance.new("Frame")
            clip.Name = isRight and "Right" or "Left"
            clip.BackgroundTransparency = 1
            clip.ClipsDescendants = true
            clip.Position = UDim2.fromScale(isRight and 0.5 or 0, 0)
            clip.Size = UDim2.fromScale(0.5, 1)
            clip.ZIndex = 2
            clip.Parent = holder
            local disc = Instance.new("Frame")
            disc.BackgroundColor3 = HOLD_COLOUR
            disc.BorderSizePixel = 0
            disc.Position = UDim2.fromScale(isRight and -1 or 0, 0)
            disc.Size = UDim2.fromScale(2, 1)
            disc.ZIndex = 2
            disc.Parent = clip
            Instance.new("UICorner", disc).CornerRadius = UDim.new(0.5, 0)

            local solidLeft = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(0.501, 1), NumberSequenceKeypoint.new(1, 1),
            })
            local solidRight = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 1),
                NumberSequenceKeypoint.new(0.501, 0), NumberSequenceKeypoint.new(1, 0),
            })
            local g = Instance.new("UIGradient")
            g.Transparency = isRight and solidLeft or solidRight
            g.Parent = disc
            return g
        end
        local rightGrad, leftGrad = half(true), half(false)

        setRing = function(p)
            local deg = math.clamp(p, 0, 1) * 360
            rightGrad.Rotation = math.min(deg, 180)
            leftGrad.Rotation = math.max(deg - 180, 0)
        end
        setRing(0)
    end

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, 0.5)
    ring.Size = UDim2.new(1, -18, 1, -18)
    ring.BackgroundTransparency = 1
    ring.ZIndex = 2
    ring.Parent = key
    Instance.new("UICorner", ring).CornerRadius = UDim.new(0.3, 0)
    local ringEdge = Instance.new("UIStroke")
    ringEdge.Color = Color3.fromRGB(235, 235, 240)
    ringEdge.Thickness = 2
    ringEdge.Parent = ring

    local letter = Instance.new("TextLabel")
    letter.BackgroundTransparency = 1
    letter.Size = UDim2.fromScale(1, 1)
    letter.Font = Enum.Font.GothamBold
    letter.TextColor3 = Color3.fromRGB(235, 235, 240)
    letter.Text = keyText(prompt, inputType)
    letter.TextSize = (#letter.Text > 1) and 11 or 17
    letter.ZIndex = 3
    letter.Parent = ring

    local object = promptLabel(root, Enum.Font.GothamBold, 16, Color3.fromRGB(205, 205, 212), 1.5, 0.45)
    object.Position = UDim2.fromOffset(KEY_TEXT_X, 6)
    object.Size = UDim2.new(1, -KEY_TEXT_X, 0, 20)

    local action = promptLabel(root, Enum.Font.GothamBlack, 23, Color3.new(1, 1, 1), 2, 0.25)
    action.Size = UDim2.new(1, -KEY_TEXT_X, 0, 28)

    local function refresh()
        object.Text = prompt.ObjectText
        action.Text = prompt.ActionText
        local two = prompt.ObjectText ~= ""
        object.Visible = two
        action.Position = UDim2.fromOffset(KEY_TEXT_X, two and 26 or 16)

        local wide = TextService:GetTextSize(prompt.ActionText, 23, Enum.Font.GothamBlack, Vector2.new(1000, 100)).X
        if two then
            wide = math.max(wide, TextService:GetTextSize(prompt.ObjectText, 16, Enum.Font.GothamBold, Vector2.new(1000, 100)).X)
        end
        root.Size = UDim2.fromOffset(math.min(PROMPT_W, KEY_TEXT_X + math.ceil(wide) + 4), PROMPT_H)
    end
    refresh()

    local button = Instance.new("TextButton")
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Size = UDim2.fromScale(1, 1)
    button.ZIndex = 5
    button.Parent = root
    if prompt.HoldDuration > 0 then
        button.MouseButton1Down:Connect(function() prompt:InputHoldBegin() end)
        button.MouseButton1Up:Connect(function() prompt:InputHoldEnd() end)
        button.MouseLeave:Connect(function() prompt:InputHoldEnd() end)
    else
        button.Activated:Connect(function()
            prompt:InputHoldBegin()
            prompt:InputHoldEnd()
        end)
    end

    scale.Scale = 0.6
    TweenService:Create(scale, TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }):Play()

    local function bump()
        scale.Scale = 0.85
        TweenService:Create(scale, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }):Play()
    end
    local progress = Instance.new("NumberValue")
    progress.Changed:Connect(setRing)
    local holdTween
    local function hold(on)
        if holdTween then holdTween:Cancel() holdTween = nil end
        progress.Value = 0
        if on and prompt.HoldDuration > 0 then
            holdTween = TweenService:Create(progress,
                TweenInfo.new(prompt.HoldDuration, Enum.EasingStyle.Linear), { Value = 1 })
            holdTween:Play()
        end
    end
    local function destroy()
        if holdTween then holdTween:Cancel() holdTween = nil end
        progress:Destroy()
    end
    return { gui = bb, refresh = refresh, bump = bump, hold = hold, destroy = destroy }
end

PPS.PromptShown:Connect(function(prompt, inputType)
    if prompt.Style ~= Enum.ProximityPromptStyle.Custom or not prompt:GetAttribute("EggPrompt") then
        return
    end
    local ui = buildPrompt(prompt, inputType)
    if not ui then return end
    local conns = {}
    local function cleanup()
        for _, c in ipairs(conns) do c:Disconnect() end
        table.clear(conns)
        if ui.gui then ui.gui:Destroy() end
        if ui.destroy then ui.destroy() end
    end
    table.insert(conns, prompt:GetPropertyChangedSignal("ActionText"):Connect(ui.refresh))
    table.insert(conns, prompt:GetPropertyChangedSignal("ObjectText"):Connect(ui.refresh))
    table.insert(conns, prompt.Triggered:Connect(function()
        ui.hold(false)
        ui.bump()
    end))
    table.insert(conns, prompt.PromptButtonHoldBegan:Connect(function() ui.hold(true) end))
    table.insert(conns, prompt.PromptButtonHoldEnded:Connect(function() ui.hold(false) end))
    table.insert(conns, prompt.PromptHidden:Connect(cleanup))
    table.insert(conns, prompt.Destroying:Connect(cleanup))
end)

local CollectionService = game:GetService("CollectionService")
local STEAL_TAG = "StealPrompt"

local function carrying()
    return plr:GetAttribute("CarryingEgg") == true
end

local function syncSteal(pr)
    if pr:IsA("ProximityPrompt") then pr.Enabled = not carrying() end
end

local function syncAllSteal()
    for _, pr in ipairs(CollectionService:GetTagged(STEAL_TAG)) do syncSteal(pr) end
end

CollectionService:GetInstanceAddedSignal(STEAL_TAG):Connect(syncSteal)
plr:GetAttributeChangedSignal("CarryingEgg"):Connect(syncAllSteal)
syncAllSteal()