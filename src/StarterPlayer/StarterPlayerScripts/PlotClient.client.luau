local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local plr = Players.LocalPlayer
local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens", 120)
local mills = map:WaitForChild("Treadmills")

local BADGE_LIFT = 26

local BADGE_W, BADGE_H = 240, 150
local BADGE_REF = 70
local BADGE_MIN, BADGE_MAX = 0.35, 1.25

local SHOE = "rbxassetid://126213576980021"
local ARROW = "rbxassetid://106533933580463"

local ARROWS_PER_BELT = 3
local BASE_SCROLL = 3.2

local strips = {}

local function buildStrip(mill)
    local belt = mill:FindFirstChild("belt", true)
    if not belt then return nil end
    local old = mill:FindFirstChild("BeltArrows")
    if old then old:Destroy() end

    local holder = Instance.new("Folder")
    holder.Name = "BeltArrows"
    holder.Parent = mill

    local span = belt.Size.Z
    local step = span / ARROWS_PER_BELT

    local along  = step * 0.92
    local across = belt.Size.X * 0.92

    local parts = {}
    for i = 1, ARROWS_PER_BELT do
        local p = Instance.new("Part")
        p.Name = "Arrow" .. i
        p.Size = Vector3.new(along, 0.06, across)
        p.Transparency = 1
        p.Anchored = true
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.CastShadow = false
        p.Parent = holder

        local d = Instance.new("Decal")
        d.Name = "Art"
        d.Face = Enum.NormalId.Top
        d.Texture = ARROW
        d.Color3 = Color3.fromRGB(220, 245, 255)
        d.Parent = p

        parts[i] = p
    end
    return { mill = mill, belt = belt, parts = parts, span = span, step = step, offset = 0 }
end

local function layStrip(strip)
    local belt = strip.belt
    for i, p in ipairs(strip.parts) do

        local along = ((i - 1) * strip.step + strip.offset) % strip.span - strip.span / 2

        p.CFrame = belt.CFrame
            * CFrame.new(0, belt.Size.Y / 2 + 0.04, along)
            * CFrame.Angles(0, math.rad(90), 0)
    end
end

local function buildBadge(pen)
    local anchor = Instance.new("Part")
    anchor.Name = "OwnerBadgeAnchor"
    anchor.Size = Vector3.new(0.3, 0.3, 0.3)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.CastShadow = false
    local cf = pen:GetBoundingBox()
    anchor.CFrame = CFrame.new(cf.Position.X, BADGE_LIFT, cf.Position.Z)
    anchor.Parent = pen

    local bb = Instance.new("BillboardGui")
    bb.Name = "OwnerBadge"
    bb.Adornee = anchor
    bb.AlwaysOnTop = false
    bb.Size = UDim2.fromOffset(BADGE_W, BADGE_H)
    bb.MaxDistance = 520
    bb.Parent = anchor

    local ring = Instance.new("Frame")
    ring.Name = "Ring"
    ring.BackgroundColor3 = Color3.fromRGB(28, 26, 34)
    ring.BorderSizePixel = 0
    ring.AnchorPoint = Vector2.new(0.5, 0)
    ring.Position = UDim2.fromScale(0.5, 0)
    ring.Size = UDim2.fromScale(0.72, 0.72)
    ring.SizeConstraint = Enum.SizeConstraint.RelativeYY
    ring.ZIndex = 4
    ring.Parent = bb
    local rc = Instance.new("UICorner")
    rc.CornerRadius = UDim.new(1, 0)
    rc.Parent = ring
    local rs = Instance.new("UIStroke")
    rs.Color = Color3.fromRGB(14, 12, 18)
    rs.Thickness = 5
    rs.Parent = ring

    local face = Instance.new("ImageLabel")
    face.Name = "Face"
    face.BackgroundColor3 = Color3.fromRGB(196, 214, 232)
    face.BackgroundTransparency = 0
    face.AnchorPoint = Vector2.new(0.5, 0.5)
    face.Position = UDim2.fromScale(0.5, 0.5)
    face.Size = UDim2.fromScale(1, 1)
    face.ScaleType = Enum.ScaleType.Crop
    face.ZIndex = 5
    face.Parent = ring
    local fc = Instance.new("UICorner")
    fc.CornerRadius = UDim.new(1, 0)
    fc.Parent = face

    local name = Instance.new("TextLabel")
    name.Name = "Nick"
    name.BackgroundTransparency = 1
    name.AnchorPoint = Vector2.new(0.5, 1)
    name.Position = UDim2.fromScale(0.5, 1)
    name.Size = UDim2.fromScale(1, 0.26)
    name.Font = Enum.Font.FredokaOne
    name.TextScaled = true
    name.TextColor3 = Color3.fromRGB(255, 255, 255)
    name.ZIndex = 6
    name.Parent = bb
    local ns = Instance.new("UIStroke")
    ns.Color = Color3.fromRGB(12, 10, 16)
    ns.Thickness = 4
    ns.Parent = name

    return { gui = bb, face = face, nick = name, anchor = anchor }
end

local function setVisible(model, visible)
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.LocalTransparencyModifier = visible and 0 or 1
        elseif p:IsA("SurfaceGui") or p:IsA("BillboardGui") then
            p.Enabled = visible
        end
    end
end

local short = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig")).fmtShort

local function popup(amount)
    local ch = plr.Character
    local head = ch and ch:FindFirstChild("Head")
    if not head then return end

    local anchor = Instance.new("Part")
    anchor.Size = Vector3.new(0.2, 0.2, 0.2)
    anchor.Transparency = 1
    anchor.Anchored = true
    anchor.CanCollide = false
    anchor.CanQuery = false
    anchor.CanTouch = false
    anchor.CFrame = head.CFrame * CFrame.new(math.random(-25, 25) / 10, 0.5, 0)
    anchor.Parent = workspace

    local bb = Instance.new("BillboardGui")
    bb.Adornee = anchor
    bb.AlwaysOnTop = true
    bb.Size = UDim2.fromOffset(150, 46)
    bb.Parent = anchor

    local row = Instance.new("Frame")
    row.BackgroundTransparency = 1
    row.Size = UDim2.fromScale(1, 1)
    row.Parent = bb
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.Padding = UDim.new(0, 4)
    layout.Parent = row

    local shoe = Instance.new("ImageLabel")
    shoe.BackgroundTransparency = 1
    shoe.Image = SHOE
    shoe.ScaleType = Enum.ScaleType.Fit
    shoe.Size = UDim2.fromOffset(42, 42)
    shoe.LayoutOrder = 1
    shoe.Parent = row

    local text = Instance.new("TextLabel")
    text.BackgroundTransparency = 1
    text.Size = UDim2.fromOffset(0, 42)
    text.AutomaticSize = Enum.AutomaticSize.X
    text.Font = Enum.Font.FredokaOne
    text.Text = "+" .. short(amount)
    text.TextSize = 34
    text.TextColor3 = Color3.fromRGB(255, 255, 255)
    text.LayoutOrder = 2
    text.Parent = row
    local st = Instance.new("UIStroke")
    st.Color = Color3.fromRGB(12, 10, 16)
    st.Thickness = 3
    st.Parent = text

    task.spawn(function()
        local t0 = os.clock()
        local base = anchor.CFrame
        while os.clock() - t0 < 1.1 do
            local k = (os.clock() - t0) / 1.1
            anchor.CFrame = base + Vector3.new(0, k * 4.5, 0)
            text.TextTransparency = k * k
            st.Transparency = k * k
            shoe.ImageTransparency = k * k
            RunService.Heartbeat:Wait()
        end
        anchor:Destroy()
    end)
end

task.spawn(function()
    local last = plr:GetAttribute("Speed") or 0
    plr:GetAttributeChangedSignal("Speed"):Connect(function()
        local now = plr:GetAttribute("Speed") or 0
        local delta = now - last
        last = now
        if delta > 0 then popup(delta) end
    end)
end)

task.spawn(function()
    for _, mill in ipairs(mills:GetChildren()) do
        local strip = buildStrip(mill)
        if strip then
            strips[#strips + 1] = strip
            layStrip(strip)
        end
    end
    RunService.Heartbeat:Connect(function(dt)
        for _, strip in ipairs(strips) do
            local rate = tonumber(strip.mill:GetAttribute("BeltRate")) or 1
            strip.offset = (strip.offset + BASE_SCROLL * rate * dt) % strip.span
            layStrip(strip)
        end
    end)
end)

local badges = {}

local collideOf = setmetatable({}, { __mode = "k" })

local function showMillPart(p, shown)
    if p:IsA("BasePart") or p:IsA("Decal") then
        p.LocalTransparencyModifier = shown and 0 or 1
        if p:IsA("BasePart") then
            local orig = collideOf[p]
            if not orig then
                orig = { p.CanCollide, p.CanTouch }
                collideOf[p] = orig
            end
            local coll = shown and orig[1]
            local touch = shown and orig[2]
            if p.CanCollide ~= coll then p.CanCollide = coll end
            if p.CanTouch ~= touch then p.CanTouch = touch end
        end
    elseif p:IsA("ParticleEmitter") then
        if p.Enabled ~= shown then
            p.Enabled = shown
            if not shown then p:Clear() end
        end
    end
end

local function showSignPart(p, mine)
    if p:IsA("BasePart") then
        p.LocalTransparencyModifier = mine and 0 or 1
    elseif p:IsA("SurfaceGui") or p:IsA("BillboardGui") then
        p.Enabled = mine
    end
end

local function ownedByMe(pen)
    return pen ~= nil and (pen:GetAttribute("OwnerUserId") or 0) == plr.UserId
end

local function updatePen(pen)
    local mill = mills:FindFirstChild("Mill_" .. pen.Name)
    local ownerId = pen:GetAttribute("OwnerUserId") or 0
    local mine = ownerId == plr.UserId
    local taken = ownerId ~= 0

    local badge = badges[pen]
    if taken then
        if not badge then
            badge = buildBadge(pen)
            badges[pen] = badge
        end
        badge.gui.Enabled = true
        badge.nick.Text = pen:GetAttribute("OwnerName") or ""
        local wanted = ("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(ownerId)
        if badge.face.Image ~= wanted then badge.face.Image = wanted end
    elseif badge then
        badge.gui.Enabled = false
    end

    local penSign = pen:FindFirstChild("Sign")
    if penSign then
        local oldText = penSign:FindFirstChild("LevelText", true)
        if oldText then oldText:Destroy() end
        setVisible(penSign, mine)
    end
    if mill then
        local millSign = mill:FindFirstChild("Sign")
        if millSign then
            local oldText = millSign:FindFirstChild("LevelText", true)
            if oldText then oldText:Destroy() end
            setVisible(millSign, mine)
        end

        local shown = mine or mill:GetAttribute("Running") == true
        for _, p in ipairs(mill:GetDescendants()) do
            if not (millSign and p:IsDescendantOf(millSign)) then
                showMillPart(p, shown)
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    local cam = workspace.CurrentCamera
    if not cam then return end
    for pen, badge in pairs(badges) do
        if not pen.Parent then
            badges[pen] = nil
        elseif badge.gui.Enabled and badge.anchor.Parent then
            local dist = (cam.CFrame.Position - badge.anchor.Position).Magnitude
            local k = math.clamp(BADGE_REF / math.max(dist, 1), BADGE_MIN, BADGE_MAX)
            badge.gui.Size = UDim2.fromOffset(math.floor(BADGE_W * k), math.floor(BADGE_H * k))
        end
    end
end)

mills.DescendantAdded:Connect(function(p)
    local mill = p
    while mill and mill.Parent ~= mills do mill = mill.Parent end
    if not mill then return end
    local pen = pens:FindFirstChild((mill.Name:gsub("^Mill_", "")))
    local mine = ownedByMe(pen)
    local sign = mill:FindFirstChild("Sign")
    if sign and p:IsDescendantOf(sign) then
        showSignPart(p, mine)
    else
        showMillPart(p, mine or mill:GetAttribute("Running") == true)
    end
end)
pens.DescendantAdded:Connect(function(p)
    local pen = p
    while pen and pen.Parent ~= pens do pen = pen.Parent end
    if not pen then return end
    local sign = pen:FindFirstChild("Sign")
    if sign and p:IsDescendantOf(sign) then
        showSignPart(p, ownedByMe(pen))
    end
end)

task.spawn(function()
    while true do
        for _, pen in ipairs(pens:GetChildren()) do
            local ok, err = pcall(updatePen, pen)
            if not ok then warn("[PlotClient] " .. pen.Name .. ": " .. tostring(err)) end
        end
        task.wait(0.2)
    end
end)