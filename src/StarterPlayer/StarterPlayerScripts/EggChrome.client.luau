local Players    = game:GetService("Players")
local RS         = game:GetService("ReplicatedStorage")
local GuiService  = game:GetService("GuiService")
local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local plr    = Players.LocalPlayer
local Remote = RS:WaitForChild("Remotes"):WaitForChild("Egg")

local ICON = {
    cart  = "rbxassetid://116327285896545",
    index = "rbxassetid://137317555173832",
    shoe  = "rbxassetid://126213576980021",
    cash  = "rbxassetid://77975477107065",
    bolt  = "rbxassetid://108812048400524",
    robux = "rbxasset://textures/ui/common/robux.png",
    egg   = "rbxassetid://70957092077967",
    pets  = "rbxassetid://115427788914202",
    day   = "rbxassetid://115886624796323",
    night = "rbxassetid://107281819028334",
    studs = "rbxassetid://138926013267839",

    rays     = "rbxassetid://75235337881072",
    glowSoft = "rbxassetid://110083852572719",
    rebirth  = "rbxassetid://102581215383481",
}

local REF_H = 1005

local M = {
    edgeX      = 16,

    btnW       = 240,
    btnH       = 84,
    btnGap     = 20,

    btnTextSize = 54,
    btnTextPadX = 20,
    btnTextPadY = 14,

    btnIconBig = 106,

    togGap     = 8,
    togW       = 111,
    togH       = 44,
    togRadius  = 10,
    knobW      = 55,
    knobH      = 36,
    knobRadius = 7,
    knobPad    = 4,
    togLabelGap = 14,
    togTextSize = 26,

    statIcon   = 80,
    statGap    = 14,
    statRowGap = -8,
    statBottom = 14,
    statTextH  = 64,
    statTextSize = 54,

    plusSide   = 28,

    cycleIcon  = 62,
    cycleGap   = 10,
    cycleText  = 40,
    cycleRight = 18,
    cycleBottom = 16,

    tileSide   = 100,
    tileGap    = 14,

    speedGap   = 20,
    speedW     = 240,
    speedH     = 84,
    speedText  = 54,
    speedPrice = 26,

    speedBolt  = 118,

    speedGlow  = 168,
    speedRays  = 142,
    togAfterSpeed = 8,
}

local SPEED_Y = M.btnH * 3 + M.btnGap * 2 + M.speedGap

local TOG_Y   = SPEED_Y + M.speedH + M.speedPrice + M.togAfterSpeed
local STACK_H = TOG_Y + M.togH

local LOOK = {
    rebirth = { top = Color3.fromRGB(255, 226,  70), bottom = Color3.fromRGB(255, 150,   0) },
    shop  = { top = Color3.fromRGB(106, 240,  76), bottom = Color3.fromRGB( 36, 182,  44) },
    index = { top = Color3.fromRGB( 66, 178, 255), bottom = Color3.fromRGB( 22, 102, 230) },
    speed = { top = Color3.fromRGB(188, 102, 255), bottom = Color3.fromRGB(122,  42, 222) },
    eggs  = { rim = Color3.fromRGB(150,  20,  24), top = Color3.fromRGB(255, 150, 130), bottom = Color3.fromRGB(235,  40,  40) },
    pets  = { rim = Color3.fromRGB(170,  70,   0), top = Color3.fromRGB(255, 214, 110), bottom = Color3.fromRGB(255, 128,  20) },
    off   = { top = Color3.fromRGB(150, 158, 146), bottom = Color3.fromRGB(104, 112, 100) },
}
local TILE_INK = Color3.fromRGB(20, 16, 28)

local C = {

    track       = Color3.fromRGB( 34,  51,  31),
    trackEdge   = Color3.fromRGB( 14,  24,  12),
    knobOn      = Color3.fromRGB( 88, 210,  75),
    knobOff     = Color3.fromRGB(122, 134, 118),

    ink         = Color3.fromRGB(255, 255, 255),
    outline     = Color3.fromRGB(  0,   0,   0),

    cashInk     = Color3.fromRGB( 74, 214,  66),

    auraInk     = Color3.fromRGB(255, 255, 255),
}

local gui = Instance.new("ScreenGui")
gui.Name = "EggChrome"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 4
gui.Parent = plr:WaitForChild("PlayerGui")

local function corner(o, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = o
    return c
end

local function stroke(o, colour, thickness)
    local s = Instance.new("UIStroke")
    s.Color = colour
    s.Thickness = thickness
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = o
    return s
end

local function shout(parent, props)
    local l = Instance.new("TextLabel")
    l.Name = props.name or "Text"
    l.BackgroundTransparency = 1
    l.Size = props.size
    l.Position = props.position
    l.AnchorPoint = props.anchor or Vector2.new(0, 0)
    l.Font = Enum.Font.FredokaOne
    l.Text = props.text or ""
    l.TextSize = props.textSize
    l.TextColor3 = props.colour or C.ink
    l.TextXAlignment = props.align or Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.ZIndex = props.zindex or 6
    l.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = C.outline
    s.Thickness = props.strokeW or 3
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = l

    if props.fill then
        l.TextScaled = true
        local c = Instance.new("UITextSizeConstraint")
        c.MinTextSize = 8
        c.MaxTextSize = props.textSize
        c.Parent = l
    end
    return l
end

local function inkedIcon(parent, image, side, edgeW, z)
    local holder = Instance.new("Frame")
    holder.Name = "Icon"
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(side, side)
    holder.ZIndex = z
    holder.Parent = parent

    local function glyph(nm, colour, dx, dy, zz)
        local i = Instance.new("ImageLabel")
        i.Name = nm
        i.BackgroundTransparency = 1
        i.Image = image
        i.ImageColor3 = colour
        i.ScaleType = Enum.ScaleType.Fit
        i.Size = UDim2.fromScale(1, 1)
        i.Position = UDim2.fromOffset(dx, dy)
        i.ZIndex = zz
        i.Parent = holder
    end
    for _, o in ipairs({
        Vector2.new(-1, -1), Vector2.new(0, -1), Vector2.new(1, -1),
        Vector2.new(-1,  0),                     Vector2.new(1,  0),
        Vector2.new(-1,  1), Vector2.new(0,  1), Vector2.new(1,  1),
    }) do
        glyph("Edge", C.outline, o.X * edgeW, o.Y * edgeW, z)
    end
    glyph("Face", Color3.new(1, 1, 1), 0, 0, z + 1)
    return holder
end

local function lum(c)
    return 0.299 * c.R + 0.587 * c.G + 0.114 * c.B
end

local function layer(parent, name, inset, colour, radius, z)
    local f = Instance.new("Frame")
    f.Name = name
    f.AnchorPoint = Vector2.new(0.5, 0.5)
    f.Position = UDim2.fromScale(0.5, 0.5)
    f.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
    f.BackgroundColor3 = colour
    f.BorderSizePixel = 0
    f.Active = false
    f.ZIndex = z
    f.Parent = parent
    corner(f, radius)
    return f
end

local function paintTile(face, look)
    local rimColour = look.rim or look.bottom:Lerp(Color3.new(0, 0, 0), 0.45)
    if lum(rimColour) > lum(look.bottom) * 0.72 then
        rimColour = look.bottom:Lerp(Color3.new(0, 0, 0), 0.4)
    end
    local border = face:FindFirstChild("TileBorder")
    if not border then
        border = layer(face, "TileBorder", 0, TILE_INK, 14, 6)
        local rimLayer = layer(border, "TileRim", 2, rimColour, 12, 6)
        local fill = layer(rimLayer, "TileFill", 2, Color3.new(1, 1, 1), 10, 6)
        local grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Parent = fill
        local studs = Instance.new("ImageLabel")
        studs.Name = "Studs"
        studs.BackgroundTransparency = 1
        studs.Active = false
        studs.Image = ICON.studs
        studs.ScaleType = Enum.ScaleType.Tile
        studs.TileSize = UDim2.fromOffset(13, 13)
        studs.ImageTransparency = 0.3
        studs.Size = UDim2.fromScale(1, 1)
        studs.ZIndex = 7
        studs.Parent = fill
        corner(studs, 10)
    end
    local rimLayer = border.TileRim
    rimLayer.BackgroundColor3 = rimColour
    rimLayer.TileFill.UIGradient.Color = ColorSequence.new(look.top, look.bottom)
    return rimLayer.TileFill
end

local function shadeTile(face, top, bottom)
    face.TileBorder.TileRim.TileFill.UIGradient.Color = ColorSequence.new(top, bottom)
end

local function hudTile(holder, name, look, text)
    local face = Instance.new("TextButton")
    face.Name = name
    face.AutoButtonColor = false
    face.Text = ""
    face.BackgroundTransparency = 1
    face.BorderSizePixel = 0
    face.Size = UDim2.fromScale(1, 1)
    face.ZIndex = 6
    face.Parent = holder
    local fill = paintTile(face, look)
    local caption = shout(face, {
        name = "Caption", text = text,
        size = UDim2.new(1, 16, 0, 30), position = UDim2.new(0.5, 0, 1, 7),
        anchor = Vector2.new(0.5, 1), align = Enum.TextXAlignment.Center,
        textSize = 30, strokeW = 3, zindex = 12, fill = true,
    })
    caption.Active = false
    return face, fill, caption
end

local function tileIcon(fill, image, k)
    local ic = Instance.new("ImageLabel")
    ic.BackgroundTransparency = 1
    ic.Image = image
    ic.ScaleType = Enum.ScaleType.Fit
    ic.Active = false
    ic.ZIndex = 9
    ic.Parent = fill
    ic.Name = "TileIcon"
    ic.AnchorPoint = Vector2.new(0.5, 0.5)
    ic.Position = UDim2.fromScale(0.5, 0.5)
    ic.Size = UDim2.new(k or 1, -6, k or 1, -6)
    return ic
end

local POP = TweenInfo.new(0.14, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local function react(face, holder, scale, allowed)
    local over = false
    local function to(k)
        TweenService:Create(scale, POP, { Scale = k }):Play()
    end
    face.MouseEnter:Connect(function()
        over = true
        if allowed and not allowed() then return end
        holder.ZIndex = 7
        to(1.08)
    end)
    face.MouseLeave:Connect(function()
        over = false
        holder.ZIndex = 5
        to(1)
    end)
    face.MouseButton1Down:Connect(function()
        if allowed and not allowed() then return end
        to(0.94)
    end)
    face.MouseButton1Up:Connect(function()
        if allowed and not allowed() then return end
        to(over and 1.08 or 1)
    end)
end

local stack = Instance.new("Frame")
stack.Name = "LeftStack"
stack.BackgroundTransparency = 1
stack.AnchorPoint = Vector2.new(0, 0.5)
stack.Size = UDim2.fromOffset(M.btnW, STACK_H)
stack.ZIndex = 5
stack.Parent = gui

local stackScale = Instance.new("UIScale")
stackScale.Parent = stack

local function group(name, y, w, h)
    local holder = Instance.new("Frame")
    holder.Name = name .. "Group"
    holder.BackgroundTransparency = 1
    holder.AnchorPoint = Vector2.new(0.5, 0.5)
    holder.Position = UDim2.fromOffset(math.floor(w / 2), y + math.floor(h / 2))
    holder.Size = UDim2.fromOffset(w, h)
    holder.ZIndex = 5
    holder.Parent = stack
    local scale = Instance.new("UIScale")
    scale.Parent = holder
    return holder, scale
end

local function wideFace(holder, name, look)
    local face = Instance.new("TextButton")
    face.Name = name
    face.AutoButtonColor = false
    face.Text = ""
    face.BackgroundTransparency = 1
    face.BorderSizePixel = 0
    face.Size = UDim2.fromScale(1, 1)
    face.ZIndex = 6
    face.Parent = holder
    paintTile(face, look)
    return face
end

local function bigButton(name, y, text, image, look, onClick, iconTurn, textSize)
    local holder, holderScale = group(name, y, M.btnW, M.btnH)
    local face = wideFace(holder, name, look)
    local top, bottom = look.top, look.bottom

    local ic
    if name == "Shop" then

        ic = inkedIcon(holder, image, M.btnIconBig, 1, 10)
        ic.Name = name .. "Icon"
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
    else
        ic = Instance.new("ImageLabel")
        ic.Name = name .. "Icon"
        ic.BackgroundTransparency = 1
        ic.Image = image
        ic.ScaleType = Enum.ScaleType.Fit
        ic.AnchorPoint = Vector2.new(0.5, 0.5)
        ic.Position = UDim2.fromScale(0.5, 0.5)
        ic.Size = UDim2.fromOffset(M.btnIconBig, M.btnIconBig)
        ic.Rotation = iconTurn or 0
        ic.Active = false
        ic.ZIndex = 10
        ic.Parent = holder
    end

    local label = shout(holder, {
        name = name .. "Label", text = text,
        size = UDim2.fromOffset(M.btnW - M.btnTextPadX, M.btnH - M.btnTextPadY),
        position = UDim2.fromScale(0.5, 0.5),
        anchor = Vector2.new(0.5, 0.5),
        align = Enum.TextXAlignment.Center,
        textSize = textSize or M.btnTextSize, strokeW = 4, zindex = 14,
        fill = true,
    })
    label.Active = false

    local QUICK = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function tint(t, b, lift)
        shadeTile(face, t, b)
        TweenService:Create(holderScale, QUICK, { Scale = lift }):Play()
    end
    face.MouseEnter:Connect(function() tint(top:Lerp(Color3.new(1,1,1), 0.18), bottom:Lerp(Color3.new(1,1,1), 0.10), 1.04) end)
    face.MouseLeave:Connect(function() tint(top, bottom, 1.00) end)
    face.MouseButton1Down:Connect(function() tint(bottom, bottom, 0.97) end)
    face.MouseButton1Up:Connect(function() tint(top, bottom, 1.00) end)
    face.MouseButton1Click:Connect(onClick)
    return face
end

local note = shout(gui, {
    name = "Note", text = "",
    size = UDim2.fromOffset(720, 54),
    position = UDim2.fromScale(0.5, 0.24),
    anchor = Vector2.new(0.5, 0.5),
    align = Enum.TextXAlignment.Center,
    textSize = 32, strokeW = 4, zindex = 30,
})
note.Visible = false

local noteToken = 0
local NOTE_INK
local function say(text, colour)
    NOTE_INK = NOTE_INK or note.TextColor3
    note.Text = text
    note.TextColor3 = colour or NOTE_INK
    note.Visible = true
    noteToken = noteToken + 1
    local mine = noteToken
    task.delay(2.0, function()
        if noteToken == mine then note.Visible = false end
    end)
end

local BUILT = { RobuxShop = true, Index = true, Rebirth = true }

local function openPanel(id, human, where)
    local bus = RS:FindFirstChild("Remotes")
    bus = bus and bus:FindFirstChild("OpenPanel")
    if bus and BUILT[id] then
        bus:Fire(id, where)
    else
        say(human .. " - coming soon")
    end
end

bigButton("Rebirth", 0, "Rebirth", ICON.rebirth, LOOK.rebirth,
    function() openPanel("Rebirth", "Rebirth") end, 45, 44)

bigButton("Shop", M.btnH + M.btnGap, "Shop", ICON.cart, LOOK.shop,
    function() openPanel("RobuxShop", "Shop") end)

bigButton("Index", (M.btnH + M.btnGap) * 2, "Index", ICON.index, LOOK.index,
    function() openPanel("Index", "Index") end)

local track = Instance.new("TextButton")
track.Name = "SlowMode"
track.AutoButtonColor = false
track.Text = ""
track.BackgroundColor3 = Color3.fromRGB(78,116,39)
track.BorderSizePixel = 0
track.Size = UDim2.fromOffset(128, M.togH)
track.Position = UDim2.fromOffset(0, TOG_Y)
track.ZIndex = 6
track.Parent = stack
corner(track, 7)
local trackEdge = stroke(track, Color3.fromRGB(18,30,12), 4)
local rim = Instance.new("Frame")
rim.Name = "InnerRim"
rim.BackgroundTransparency = 1
rim.Position = UDim2.fromOffset(3,3)
rim.Size = UDim2.new(1,-6,1,-6)
rim.ZIndex = 7
rim.Parent = track
corner(rim,4)
local rimEdge = stroke(rim,Color3.fromRGB(136,174,57),1)
local knob = Instance.new("Frame")
knob.Name = "Knob"
knob.Size = UDim2.fromOffset(40, M.togH-10)
knob.AnchorPoint = Vector2.new(0,.5)
knob.Position = UDim2.new(0,6,.5,0)
knob.BackgroundColor3 = Color3.new(1,1,1)
knob.BorderSizePixel = 0
knob.ZIndex = 9
knob.Parent = track
corner(knob,5)
stroke(knob,Color3.fromRGB(14,27,9),3)
local shine = Instance.new("UIGradient")
shine.Rotation = 90
shine.Color = ColorSequence.new(Color3.fromRGB(203,255,0),Color3.fromRGB(29,244,0))
shine.Parent = knob
local togLabel = shout(stack, {
 name="SlowModeLabel", text="Slow Mode",
 size=UDim2.fromOffset(154,M.togH),
 position=UDim2.fromOffset(144,TOG_Y),
 textSize=26, strokeW=3, zindex=7,
})
local labelHit = Instance.new("TextButton")
labelHit.Name = "SlowModeLabelHit"
labelHit.BackgroundTransparency = 1
labelHit.Text = ""
labelHit.Size = togLabel.Size
labelHit.Position = togLabel.Position
labelHit.ZIndex = 8
labelHit.Parent = stack
local slowOn = false
local SLIDE = TweenInfo.new(.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local knobTween, trackTween
local function paintToggle()
 if knobTween then knobTween:Cancel() end
 if trackTween then trackTween:Cancel() end
 track:SetAttribute("Enabled",slowOn)
 knobTween=TweenService:Create(knob,SLIDE,{Position=UDim2.new(0,slowOn and 82 or 6,.5,0)})
 trackTween=TweenService:Create(track,SLIDE,{BackgroundColor3=slowOn and Color3.fromRGB(99,145,40) or Color3.fromRGB(74,78,86)})
 trackEdge.Color=slowOn and Color3.fromRGB(18,30,12) or Color3.fromRGB(20,22,26)
 rimEdge.Color=slowOn and Color3.fromRGB(136,174,57) or Color3.fromRGB(120,126,136)
 shine.Color=slowOn and ColorSequence.new(Color3.fromRGB(203,255,0),Color3.fromRGB(29,244,0))
  or ColorSequence.new(Color3.fromRGB(215,220,228),Color3.fromRGB(140,146,156))
 knobTween:Play() trackTween:Play()
end
local function toggleSlowMode()
 slowOn=not slowOn
 paintToggle()
 Remote:FireServer("SlowMode",slowOn)
end
track.Activated:Connect(toggleSlowMode)
labelHit.Activated:Connect(toggleSlowMode)
plr:GetAttributeChangedSignal("SlowMode"):Connect(function()
 slowOn=plr:GetAttribute("SlowMode")==true
 paintToggle()
end)
slowOn=plr:GetAttribute("SlowMode")==true
paintToggle()

local SpeedPass = require(RS:WaitForChild("SpeedPassConfig"))

local speedGroup, speedScale = group("Speed", SPEED_Y, M.speedW, M.speedH)

local speedBursts = {}
for _, layer in ipairs({
    { image = ICON.glowSoft, side = M.speedGlow, transparency = 0.42,
      tint = Color3.fromRGB(255, 255, 255), spins = false },
    { image = ICON.rays, side = M.speedRays, transparency = 0.30,
      tint = Color3.fromRGB(255, 255, 255), spins = true },
}) do
    local burst = Instance.new("ImageLabel")
    burst.Name = layer.spins and "SpeedRays" or "SpeedGlow"
    burst.BackgroundTransparency = 1
    burst.Image = layer.image
    burst.ImageColor3 = layer.tint
    burst.ImageTransparency = layer.transparency
    burst.AnchorPoint = Vector2.new(0.5, 0.5)
    burst.Position = UDim2.fromScale(0.5, 0.5)
    burst.Size = UDim2.fromOffset(layer.side, layer.side)
    burst.ZIndex = 8
    burst.Active = false
    burst.Parent = speedGroup
    if layer.spins then table.insert(speedBursts, burst) end
end

do
    local spin = 0
    RunService.RenderStepped:Connect(function(dt)
        spin = (spin + dt * 14) % 360
        for _, burst in ipairs(speedBursts) do
            burst.Rotation = spin
        end
    end)
end

_G.EggHudGlow = function(on)
    for _, name in ipairs({ "SpeedGlow", "SpeedRays" }) do
        local burst = speedGroup:FindFirstChild(name)
        if burst then burst.Visible = on end
    end
end

local boost = wideFace(speedGroup, "SpeedBoost", LOOK.speed)

local boltIcon = Instance.new("ImageLabel")
boltIcon.Name = "SpeedBolt"
boltIcon.BackgroundTransparency = 1
boltIcon.Image = ICON.bolt
boltIcon.ScaleType = Enum.ScaleType.Fit
boltIcon.AnchorPoint = Vector2.new(0.5, 0.5)
boltIcon.Position = UDim2.fromScale(0.5, 0.5)
boltIcon.Size = UDim2.fromOffset(M.speedBolt, M.speedBolt)
boltIcon.Active = false
boltIcon.ZIndex = 10
boltIcon.Parent = speedGroup

local boostLabel = shout(speedGroup, {
    name = "SpeedLabel", text = "x2 Speed",
    size = UDim2.fromOffset(M.speedW - M.btnTextPadX, M.speedH - M.btnTextPadY),
    position = UDim2.fromScale(0.5, 0.5),
    anchor = Vector2.new(0.5, 0.5),
    align = Enum.TextXAlignment.Center,
    textSize = M.speedText, strokeW = 4, zindex = 14,
    fill = true,
})
boostLabel.Active = false

local priceRow = Instance.new("Frame")
priceRow.Name = "SpeedPrice"
priceRow.BackgroundTransparency = 1
priceRow.AnchorPoint = Vector2.new(0.5, 0.5)
priceRow.Position = UDim2.new(0.5, 0, 1, 0)
priceRow.Size = UDim2.fromOffset(M.speedW, M.speedPrice + 6)
priceRow.ZIndex = 16
priceRow.Parent = speedGroup
do
    local row = Instance.new("UIListLayout")
    row.FillDirection = Enum.FillDirection.Horizontal
    row.HorizontalAlignment = Enum.HorizontalAlignment.Center
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.SortOrder = Enum.SortOrder.LayoutOrder
    row.Padding = UDim.new(0, 5)
    row.Parent = priceRow
end

local priceText = shout(priceRow, {
    name = "Text", text = "ONLY 1",
    size = UDim2.fromOffset(0, M.speedPrice + 6), position = UDim2.fromOffset(0, 0),
    align = Enum.TextXAlignment.Center,
    textSize = M.speedPrice, strokeW = 3, zindex = 17,
})
priceText.AutomaticSize = Enum.AutomaticSize.X
priceText.LayoutOrder = 1

local robuxIcon = inkedIcon(priceRow, ICON.robux, M.speedPrice, 2, 17)
robuxIcon.Name = "Robux"
robuxIcon.LayoutOrder = 2

local firstTier = SpeedPass.nextAfter(1)
local speedState = {
    mult = 1,
    next = firstTier and firstTier.mult or 2,
    price = firstTier and firstTier.price or 1,
    maxed = firstTier == nil,
}

local function paintBoost()
    if speedState.maxed then

        boostLabel.Text = "MAX SPEED"
        priceText.Text = "x" .. speedState.mult
        robuxIcon.Visible = false
        paintTile(boost, SpeedPass.MAX_GREY and LOOK.off or LOOK.speed)
    else
        boostLabel.Text = "x" .. (speedState.next or 2) .. " Speed"
        priceText.Text = "ONLY " .. tostring(speedState.price or 1)
        robuxIcon.Visible = true
        paintTile(boost, LOOK.speed)
    end
end
paintBoost()

do
    local QUICK = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local function lift(scale)
        if speedState.maxed then return end
        TweenService:Create(speedScale, QUICK, { Scale = scale }):Play()
    end
    boost.MouseEnter:Connect(function() lift(1.04) end)
    boost.MouseLeave:Connect(function() lift(1.00) end)
    boost.MouseButton1Down:Connect(function() lift(0.97) end)
    boost.MouseButton1Up:Connect(function() lift(1.00) end)
end

task.spawn(function()
    local bus = RS:WaitForChild("Remotes"):WaitForChild("SpeedShop", 30)
    if not bus then return end

    boost.MouseButton1Click:Connect(function()
        if speedState.maxed then
            say("You already have the MAX speed level!", Color3.fromRGB(255, 70, 70))
            return
        end
        bus:FireServer("buy")
    end)

    bus.OnClientEvent:Connect(function(state)
        if type(state) ~= "table" then return end
        if state.noProduct then
            say(("x%d Speed pass - not available right now"):format(tonumber(state.next) or 2))
            return
        end
        speedState.mult  = state.mult or 1
        speedState.next  = state.next
        speedState.price = state.price
        speedState.maxed = state.maxed == true
        paintBoost()
    end)

    bus:FireServer("state")
end)

local tiles = Instance.new("Frame")
tiles.Name = "RightTiles"
tiles.BackgroundTransparency = 1
tiles.AnchorPoint = Vector2.new(1, 0.5)
tiles.Size = UDim2.fromOffset(M.tileSide, M.tileSide * 2 + M.tileGap)
tiles.ZIndex = 5
tiles.Parent = gui

local tileScale = Instance.new("UIScale")
tileScale.Parent = tiles

local function tile(name, y, image, look, text, onClick)
    local face, fill = hudTile(tiles, name, look, text)
    face.AnchorPoint = Vector2.new(0.5, 0.5)
    face.Size = UDim2.fromOffset(M.tileSide, M.tileSide)
    face.Position = UDim2.fromOffset(M.tileSide / 2, y + M.tileSide / 2)
    local scale = Instance.new("UIScale")
    scale.Parent = face
    tileIcon(fill, image, 0.9)
    react(face, face, scale)
    face.MouseButton1Click:Connect(onClick)
    return face
end

local eggTile=tile("Eggs", 0, ICON.egg, LOOK.eggs, "Eggs",
    function()
        local bus = RS:FindFirstChild("Remotes")
        bus = bus and bus:FindFirstChild("OpenPanel")
        if bus then bus:Fire("GrowingEggs") end
    end)

local NightCycle=require(RS:WaitForChild("DayNightConfig"))
local nightBadge=Instance.new("Frame")
nightBadge.Name="NightHatchBonus" nightBadge.BackgroundTransparency=1
nightBadge.AnchorPoint=Vector2.new(0.5,0.5)
nightBadge.Size=UDim2.new(1,70,0,56) nightBadge.Position=UDim2.new(0.5,0,0,-4)
nightBadge.ZIndex=20 nightBadge.Parent=eggTile
local nightRow=Instance.new("UIListLayout")
nightRow.FillDirection=Enum.FillDirection.Horizontal
nightRow.HorizontalAlignment=Enum.HorizontalAlignment.Center
nightRow.VerticalAlignment=Enum.VerticalAlignment.Center
nightRow.SortOrder=Enum.SortOrder.LayoutOrder
nightRow.Padding=UDim.new(0,0)
nightRow.Parent=nightBadge
local moon=inkedIcon(nightBadge,NightCycle.ICON.night,48,2,21)
moon.Name="Moon" moon.LayoutOrder=1
for _,g in ipairs(moon:GetChildren()) do
 if g.Name=="Edge" then g.ImageColor3=Color3.fromRGB(235,242,255) end
end
local mult=shout(nightBadge,{name="Multiplier",text="x"..NightCycle.NIGHT_HATCH_MULTIPLIER,
 size=UDim2.new(0,0,1,0),position=UDim2.new(),
 textSize=36,strokeW=4,zindex=23,colour=Color3.fromRGB(66,255,25)})
mult.AutomaticSize=Enum.AutomaticSize.X
mult.LayoutOrder=2
local function syncNightBadge() nightBadge.Visible=workspace:GetAttribute("CyclePhase")=="night" end
workspace:GetAttributeChangedSignal("CyclePhase"):Connect(syncNightBadge)
syncNightBadge()

tile("Pets", M.tileSide + M.tileGap, ICON.pets, LOOK.pets, "Pets",
    function()
        local bus = RS:FindFirstChild("Remotes")
        bus = bus and bus:FindFirstChild("OpenPanel")
        if bus then bus:Fire("ActivePets") end
    end)

local short = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig")).fmtShort

local stats = Instance.new("Frame")
stats.Name = "Stats"
stats.BackgroundTransparency = 1
stats.AnchorPoint = Vector2.new(0, 1)
stats.Size = UDim2.fromOffset(360, M.statIcon * 2 + M.statRowGap)
stats.ZIndex = 5
stats.Parent = gui

local statScale = Instance.new("UIScale")
statScale.Parent = stats

local function statRow(name, image, y, prefix, colour)

    local ic = inkedIcon(stats, image, M.statIcon, 3, 6)
    ic.Name = name .. "Icon"
    ic.Position = UDim2.fromOffset(0, y)

    local value = shout(stats, {
        name = name, text = prefix .. "0",
        size = UDim2.fromOffset(280, M.statTextH),
        position = UDim2.fromOffset(M.statIcon + M.statGap, y + (M.statIcon - M.statTextH) / 2),
        textSize = M.statTextSize, strokeW = 3, zindex = 7,
        colour = colour,
    })
    return value
end

local speedValue = statRow("SpeedValue", ICON.shoe, 0, "", C.auraInk)
local cashValue  = statRow("CashValue", ICON.cash, M.statIcon + M.statRowGap, "$", C.cashInk)

local TrailCfg = require(RS:WaitForChild("TrailConfig"))
local function paintAura()
    local def = TrailCfg.byId(plr:GetAttribute("Trail") or "")
    if def and def.colors and def.colors[1] then
        local head, tail = def.colors[1], def.colors[2] or def.colors[1]
        speedValue.TextColor3 = head:Lerp(tail, 0.35)
        return
    end
    local tone = plr:GetAttribute("AuraColor")
    speedValue.TextColor3 = (typeof(tone) == "Color3") and tone or C.auraInk
end
plr:GetAttributeChangedSignal("Trail"):Connect(paintAura)
plr:GetAttributeChangedSignal("AuraColor"):Connect(paintAura)
paintAura()

task.spawn(function()

    speedValue.RichText = true
    local MULT_INK = "#7CF676"

    local function refresh()
        local base = plr:GetAttribute("Speed") or 1
        local mult = math.clamp(tonumber(plr:GetAttribute("SpeedMult")) or 1, 1, SpeedPass.max())
        local text = short(base)
        if mult > 1 then
            text = ("%s <font color=\"%s\">(x%d)</font>"):format(text, MULT_INK, mult)
        end
        speedValue.Text = text
    end
    plr:GetAttributeChangedSignal("Speed"):Connect(refresh)
    plr:GetAttributeChangedSignal("SpeedMult"):Connect(refresh)
    refresh()
end)

task.spawn(function()
    local wallet = plr:WaitForChild("wallet", 30)
    local coins = wallet and wallet:WaitForChild("Coins", 15)
    if not coins then
        cashValue.Text = "$0"
        return
    end
    local function refresh() cashValue.Text = "$" .. short(coins.Value) end
    coins.Changed:Connect(refresh)
    refresh()
end)

local cycle = Instance.new("Frame")
cycle.Name = "DayNight"
cycle.BackgroundTransparency = 1
cycle.AnchorPoint = Vector2.new(1, 1)
cycle.Size = UDim2.fromOffset(320, M.cycleIcon)
cycle.ZIndex = 5
cycle.Parent = gui

local cycleScale = Instance.new("UIScale")
cycleScale.Parent = cycle

do
    local row = Instance.new("UIListLayout")
    row.FillDirection = Enum.FillDirection.Horizontal
    row.HorizontalAlignment = Enum.HorizontalAlignment.Right
    row.VerticalAlignment = Enum.VerticalAlignment.Center
    row.SortOrder = Enum.SortOrder.LayoutOrder
    row.Padding = UDim.new(0, M.cycleGap)
    row.Parent = cycle
end

local cycleIcon = inkedIcon(cycle, ICON.night, M.cycleIcon, 1, 6)
cycleIcon.LayoutOrder = 1
local function setCycleImage(image)
    for _, d in ipairs(cycleIcon:GetDescendants()) do
        if d:IsA("ImageLabel") and d.Image ~= image then d.Image = image end
    end
end

local cycleText = shout(cycle, {
    name = "Clock", text = "in 3m 30s",
    size = UDim2.fromOffset(0, M.cycleIcon), position = UDim2.fromOffset(0, 0),
    align = Enum.TextXAlignment.Left,
    textSize = M.cycleText, strokeW = 4, zindex = 7,
})
cycleText.AutomaticSize = Enum.AutomaticSize.X
cycleText.LayoutOrder = 2

local function clockText(left)
    left = math.max(0, math.floor(left + 0.5))
    local m, s = math.floor(left / 60), left % 60
    if m > 0 then return string.format("in %dm %ds", m, s) end
    return string.format("in %ds", s)
end

task.spawn(function()

    local FAKE = 300
    while true do
        local phase = workspace:GetAttribute("CyclePhase")
        local ends  = tonumber(workspace:GetAttribute("CycleEndsAt"))
        if phase and ends then

            setCycleImage((phase == "day") and ICON.night or ICON.day)
            cycleText.Text = clockText(ends - workspace:GetServerTimeNow())
        else
            local into = workspace:GetServerTimeNow() % (FAKE * 2)
            local isDay = into < FAKE
            setCycleImage(isDay and ICON.night or ICON.day)
            cycleText.Text = clockText(isDay and (FAKE - into) or (FAKE * 2 - into))
        end
        task.wait(0.5)
    end
end)

local function fit()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local vp = cam.ViewportSize
    local k = math.clamp(vp.Y / REF_H, 0.62, 1.25)
    local small = math.min(vp.X, vp.Y) < 500
    local inset = math.max(GuiService:GetGuiInset().Y, GuiService.TopbarInset.Max.Y)
    local lift = small and (math.floor(math.min(vp.X, vp.Y) * 0.15) + 14) or 0
    if small then
        local room = vp.Y - inset - 8 - lift
        local need = STACK_H + M.statIcon * 2 + M.statRowGap + M.statBottom + 16
        k = math.clamp(room / need, 0.3, 0.62)
    end

    stackScale.Scale = k
    statScale.Scale = k
    tileScale.Scale = k
    cycleScale.Scale = k

    local jumpClear = (small and game:GetService("UserInputService").TouchEnabled) and 110 or 0
    cycle.Position = UDim2.new(1, -math.floor(M.cycleRight * k) - jumpClear,
        1, -math.floor(M.cycleBottom * k) - lift)

    if small then
        stack.Position = UDim2.new(0, math.floor(M.edgeX * k), 0, math.floor(inset + 4 + STACK_H * k / 2))
    else
        stack.Position = UDim2.new(0, math.floor(M.edgeX * k), 0.507, 0)
    end
    tiles.Position = UDim2.new(1, -math.floor(M.edgeX * k), 0.507, 0)
    stats.Position = UDim2.new(0, math.floor(M.edgeX * k),
        1, -math.floor(M.statBottom * k) - lift)

    note.TextSize = math.floor(32 * k)
end

fit()
do
    local function watch(cam)
        if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
    end
    watch(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        watch(workspace.CurrentCamera)
        fit()
    end)
    GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fit)
    task.delay(1, fit)
    task.delay(3, fit)
end

task.delay(4, function()
    local previousHide = _G.SetLobbyChromeHidden
    _G.SetLobbyChromeHidden = function(hidden)
        gui.Enabled = not hidden
        if previousHide then previousHide(hidden) end
    end
end)

do
    local Lighting = game:GetService("Lighting")
    local lastHide = nil
    local function sidePanelOpen()
        local pg = plr:FindFirstChild("PlayerGui")
        for _, pair in ipairs({ { "GrowingEggsGui", "GrowingEggs" }, { "ActivePetsGui", "ActivePets" } }) do
            local g = pg and pg:FindFirstChild(pair[1])
            local s = g and g:FindFirstChild(pair[2])
            if s and s.Visible then return true end
        end
        return false
    end
    local function apply(blur)
        local cam = workspace.CurrentCamera
        local small = cam and math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
        local hide = (small and blur and blur.Enabled) and true or false
        if hide == lastHide then return end
        lastHide = hide
        stack.Visible = not hide
        tiles.Visible = not hide and not sidePanelOpen()
        stats.Visible = not hide
        cycle.Visible = not hide
        local bag = plr:FindFirstChild("PlayerGui") and plr.PlayerGui:FindFirstChild("EggBag")
        if bag then bag.Enabled = not hide end
    end
    local function hook(blur)
        blur:GetPropertyChangedSignal("Enabled"):Connect(function() apply(blur) end)
        local cam = workspace.CurrentCamera
        if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(function() apply(blur) end) end
        apply(blur)
    end
    local existing = Lighting:FindFirstChild("PanelBlur")
    if existing then hook(existing) end
    Lighting.ChildAdded:Connect(function(c)
        if c.Name == "PanelBlur" then hook(c) end
    end)
end