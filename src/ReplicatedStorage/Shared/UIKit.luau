local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

local Sfx = require(script.Parent.Sfx)

local UIKit = {}

local WHITE = Color3.fromRGB(255, 255, 255)

UIKit.WHITE = WHITE
UIKit.SECOND = Color3.fromRGB(201, 220, 255)

local K = {
	outline      = Color3.fromHex("081020"),
	innerOutline = Color3.fromHex("4C7BE0"),
	darkLabel    = Color3.fromHex("081020"),
	bg           = { hi = Color3.fromRGB(58, 102, 204),  base = Color3.fromRGB(30, 63, 158),   sh = Color3.fromRGB(20, 44, 110) },
	bar          = { hi = Color3.fromRGB(255, 229, 54),  base = Color3.fromRGB(255, 205, 0),   sh = Color3.fromRGB(221, 157, 0) },
	ready        = { hi = Color3.fromRGB(71, 255, 72),   base = Color3.fromRGB(25, 220, 45),   sh = Color3.fromRGB(0, 151, 23) },
	claimed      = { hi = Color3.fromRGB(56, 196, 255),  base = Color3.fromRGB(31, 137, 235),  sh = Color3.fromRGB(12, 80, 181) },
	close        = { hi = Color3.fromRGB(255, 93, 93),   base = Color3.fromRGB(226, 41, 41),   sh = Color3.fromRGB(145, 12, 12) },
	row          = { hi = Color3.fromRGB(247, 249, 252), base = Color3.fromRGB(232, 237, 245), sh = Color3.fromRGB(200, 208, 221) },
	thumb        = { hi = Color3.fromRGB(50, 80, 143),   base = Color3.fromRGB(27, 46, 99),    sh = Color3.fromRGB(18, 32, 69) },
	lock         = { hi = Color3.fromRGB(150, 166, 200), base = Color3.fromRGB(110, 128, 168), sh = Color3.fromRGB(78, 94, 128) },
	prize        = { hi = Color3.fromRGB(196, 137, 255), base = Color3.fromRGB(162, 75, 255),  sh = Color3.fromRGB(110, 31, 204) },
	inProgress   = { hi = Color3.fromRGB(255, 186, 77),  base = Color3.fromRGB(255, 138, 0),   sh = Color3.fromRGB(184, 90, 0) },
	slab         = { hi = Color3.fromRGB(94, 147, 240),  base = Color3.fromRGB(62, 111, 214),  sh = Color3.fromRGB(42, 76, 158) },
}

K.panel = { hi = Color3.fromRGB(64, 70, 88), base = Color3.fromRGB(38, 42, 56), sh = Color3.fromRGB(22, 24, 34) }

UIKit.Palette = K

UIKit.ICON = {
	money    = "rbxassetid://105247853965760",
	settings = "rbxassetid://120353597392384",
	admin    = "rbxassetid://107453728750635",
	robux    = "rbxasset://textures/ui/common/robux.png",
	studs    = "rbxassetid://138926013267839",
}

local STUD_TILE = 15

UIKit.Tween = {
	fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	pop  = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

function UIKit.tint(colour, amount)
	return colour:Lerp(WHITE, amount)
end
local tint = UIKit.tint

function UIKit.corner(inst, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = inst
	return c
end
local corner = UIKit.corner

function UIKit.stroke(inst, colour, thickness, transparency)
	local s = Instance.new("UIStroke")
	s.Color = colour or K.outline
	s.Thickness = thickness or 3
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = inst
	return s
end

function UIKit.screen(name, parent, displayOrder)
	local sg = Instance.new("ScreenGui")
	sg.Name = name
	sg.ResetOnSpawn = false
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	sg.DisplayOrder = displayOrder or 5
	sg.Parent = parent
	return sg
end

function UIKit.repaint(face, tone)
	face.BackgroundColor3 = tone.hi
	local grad = face:FindFirstChild("Gradient")
	if grad then
		local function share(c)
			return Color3.new(
				tone.hi.R > 0 and math.clamp(c.R / tone.hi.R, 0, 1) or 0,
				tone.hi.G > 0 and math.clamp(c.G / tone.hi.G, 0, 1) or 0,
				tone.hi.B > 0 and math.clamp(c.B / tone.hi.B, 0, 1) or 0)
		end
		local height = face:GetAttribute("BlockHeight") or math.max(face.AbsoluteSize.Y, 1)
		local breakAt = math.clamp(28 / height, 0.12, 0.50)
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, WHITE),
			ColorSequenceKeypoint.new(breakAt, share(tone.base)),
			ColorSequenceKeypoint.new(1, share(tone.sh)),
		})
	end
	local bevel = face:FindFirstChild("Bevel")
	if bevel then bevel.BackgroundColor3 = tint(tone.hi, 0.30) end
end

function UIKit.block(props)
	local tone = props.tone or K.row
	local height = props.size.Y.Offset
	local radius = props.radius or math.max(6, math.floor(height * 0.26))
	local anchor = props.anchor or Vector2.new()
	local z = props.zindex or 1

	local shadow
	if props.shadow ~= false then
		shadow = Instance.new("Frame")
		shadow.Name = (props.name or "Block") .. "_Shadow"
		shadow.BackgroundColor3 = K.outline
		shadow.BackgroundTransparency = 0.55
		shadow.BorderSizePixel = 0
		shadow.AnchorPoint = anchor
		shadow.Size = props.size
		shadow.Position = (props.position or UDim2.new()) + UDim2.fromOffset(0, props.shadowY or 5)
		shadow.ZIndex = z
		shadow.Active = false
		shadow.Parent = props.parent
		corner(shadow, radius)
	end

	local face = Instance.new(props.clickable and "TextButton" or "Frame")
	face.Name = props.name or "Block"
	face.AnchorPoint = anchor
	face.Size = props.size
	face.Position = props.position or UDim2.new()
	face.BorderSizePixel = 0
	face.ZIndex = z + 1
	if face:IsA("TextButton") then
		face.Text = ""
		face.AutoButtonColor = false
	end
	face.Parent = props.parent
	corner(face, radius)

	local edgeStroke = Instance.new("UIStroke")
	edgeStroke.Thickness = props.outline or 4
	edgeStroke.Color = props.edge or K.outline

	edgeStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	edgeStroke.Parent = face

	if shadow then
		face:GetPropertyChangedSignal("Visible"):Connect(function()
			shadow.Visible = face.Visible
		end)
	end

	local grad = Instance.new("UIGradient")
	grad.Name = "Gradient"
	grad.Rotation = 90
	grad.Parent = face
	face:SetAttribute("BlockHeight", height)
	UIKit.repaint(face, tone)

	if props.finish ~= false then
		local tile = props.stud or STUD_TILE
		local studs = Instance.new("ImageLabel")
		studs.Name = "Studs"
		studs.BackgroundTransparency = 1
		studs.Image = UIKit.ICON.studs
		studs.ScaleType = Enum.ScaleType.Tile
		studs.TileSize = UDim2.fromOffset(tile, tile)

		studs.ImageTransparency = props.studAlpha or 0.55
		studs.Size = UDim2.fromScale(1, 1)
		studs.ZIndex = face.ZIndex
		studs.Active = false
		studs.Parent = face

		corner(studs, radius)
	end

	if props.bevel ~= false then
		local bevelH = math.max(3, math.floor(height * 0.08))
		local bevel = Instance.new("Frame")
		bevel.Name = "Bevel"
		bevel.BackgroundColor3 = tint(tone.hi, 0.30)
		bevel.BackgroundTransparency = 0.35
		bevel.BorderSizePixel = 0
		bevel.Size = UDim2.new(1, -math.floor(radius * 1.6), 0, bevelH)
		bevel.Position = UDim2.new(0, math.floor(radius * 0.8), 0, math.max(2, math.floor(height * 0.045)))
		bevel.ZIndex = face.ZIndex
		bevel.Active = false
		bevel.Parent = face
		corner(bevel, math.floor(bevelH / 2))
		local bg = Instance.new("UIGradient")
		bg.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.18, 0),
			NumberSequenceKeypoint.new(0.82, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		bg.Parent = bevel
	end

	local underH = math.min(26, math.max(4, math.floor(height * 0.16)))
	local underside = Instance.new("Frame")
	underside.Name = "Underside"
	underside.BackgroundColor3 = K.outline
	underside.BorderSizePixel = 0
	underside.Size = UDim2.new(1, 0, 0, underH)
	underside.Position = UDim2.new(0, 0, 1, -underH)
	underside.ZIndex = face.ZIndex
	underside.Active = false
	underside.Parent = face
	local ug = Instance.new("UIGradient")
	ug.Rotation = 90
	ug.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(1, 0.82),
	})
	ug.Parent = underside

	if props.inner then
		local inset = Instance.new("Frame")
		inset.Name = "Inner"
		inset.BackgroundTransparency = 1
		inset.BorderSizePixel = 0
		inset.Position = UDim2.fromOffset(props.inner, props.inner)
		inset.Size = UDim2.new(1, -2 * props.inner, 1, -2 * props.inner)
		inset.ZIndex = face.ZIndex
		inset.Active = false
		inset.Parent = face
		corner(inset, math.max(2, radius - props.inner))
		UIKit.stroke(inset, K.innerOutline, 2, 0.35)
	end

	return face
end

local GROW_ACTIVE, GROW_IDLE = 0.06, 0.025

function UIKit.reactToCursor(face)
	local baseSize, basePos = face.Size, face.Position
	local shadow = face.Parent and face.Parent:FindFirstChild(face.Name .. "_Shadow")
	local shadowPos = shadow and shadow.Position
	local tweens = {}
	local function animate(k)
		for _, t in ipairs(tweens) do t:Cancel() end
		tweens = {}
		local cap = face:GetAttribute("HoverMaxGrow")
		if cap then
			local width = baseSize.X.Offset > 0 and baseSize.X.Scale == 0 and baseSize.X.Offset or face.AbsoluteSize.X
			if width > 0 then
				local limit = cap / width
				k = 1 + math.clamp(k - 1, -limit, limit)
			end
		end
		local dw = math.floor(baseSize.X.Offset * (k - 1) + 0.5)
		local dh = math.floor(baseSize.Y.Offset * (k - 1) + 0.5)
		local dws, dhs = baseSize.X.Scale * (k - 1), baseSize.Y.Scale * (k - 1)
		local size = UDim2.new(baseSize.X.Scale + dws, baseSize.X.Offset + dw,
			baseSize.Y.Scale + dhs, baseSize.Y.Offset + dh)
		local shiftBy = UDim2.new(-dws / 2, -math.floor(dw / 2), -dhs / 2, -math.floor(dh / 2))
		local moved = face:GetAttribute("MovedBy") or UDim2.new()
		table.insert(tweens, TweenService:Create(face, UIKit.Tween.fast,
			{ Size = size, Position = basePos + moved + shiftBy }))
		if shadow then
			table.insert(tweens, TweenService:Create(shadow, UIKit.Tween.fast,
				{ Size = size, Position = shadowPos + moved + shiftBy }))
		end
		for _, t in ipairs(tweens) do t:Play() end
	end
	local function force()
		return face:GetAttribute("Active") ~= false and GROW_ACTIVE or GROW_IDLE
	end
	face.MouseEnter:Connect(function() animate(1 + force()) end)
	face.MouseLeave:Connect(function() animate(1) end)
	face.MouseButton1Down:Connect(function()
		if face:GetAttribute("Active") ~= false then animate(1 - GROW_ACTIVE * 0.6) end
	end)
	face.MouseButton1Up:Connect(function() animate(game:GetService("UserInputService").TouchEnabled and 1 or (1 + force())) end)
end

local function rawLabel(props)
	local l = Instance.new("TextLabel")
	l.Name = props.name or "Label"
	l.BackgroundTransparency = 1
	l.Size = props.size or UDim2.fromScale(1, 1)
	l.Position = props.position or UDim2.new()
	l.AnchorPoint = props.anchor or Vector2.new()
	l.Font = Enum.Font.FredokaOne
	l.Text = props.text or ""
	l.TextXAlignment = props.align or Enum.TextXAlignment.Center
	l.TextWrapped = props.wrapped or false
	l.ZIndex = props.zindex or 2
	if props.truncate then l.TextTruncate = props.truncate end
	l.Parent = props.parent

	l.TextScaled = false
	l.TextSize = props.textSize or 20
	return l
end

function UIKit.tintOnHover(face, tone)
	local lit = UIKit.tint(tone.hi, 0.26)
	local function to(colour)
		TweenService:Create(face, UIKit.Tween.fast, { BackgroundColor3 = colour }):Play()
	end
	face.MouseEnter:Connect(function() to(lit) end)
	face.MouseLeave:Connect(function() to(tone.hi) end)
	face.MouseButton1Down:Connect(function() to(tone.base) end)
	face.MouseButton1Up:Connect(function() to(game:GetService("UserInputService").TouchEnabled and tone.hi or lit) end)
end

UIKit.HEAD_RATIO = 0.105
UIKit.HEAD_MIN, UIKit.HEAD_MAX = 68, 84
function UIKit.headHeight(width)
	return math.clamp(math.floor(width * UIKit.HEAD_RATIO), UIKit.HEAD_MIN, UIKit.HEAD_MAX)
end

function UIKit.boldLabel(props)
	local under
	if props.shadow then
		local shiftBy = math.max(1, math.floor((props.textSize or 20) * 0.09 + 0.5))
		under = rawLabel({
			parent = props.parent, name = (props.name or "Label") .. "_Shadow",
			size = props.size, position = (props.position or UDim2.new()) + UDim2.fromOffset(0, shiftBy),
			text = props.text, textSize = props.textSize, align = props.align,
			truncate = props.truncate, wrapped = props.wrapped, anchor = props.anchor,
			zindex = props.zindex or 2,
		})
		under.TextColor3 = K.outline
		under.TextTransparency = 0.55
		under.TextStrokeTransparency = 1
		props = table.clone(props)
		props.zindex = (props.zindex or 2) + 1
	end

	local l = rawLabel(props)
	l.TextColor3 = props.colour or WHITE
	l.TextStrokeTransparency = 1
	local s = Instance.new("UIStroke")
	s.Color = props.strokeColour or K.outline
	s.Thickness = props.strokeW or math.max(2, (props.textSize or 20) * 0.11)
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	if under then
		l:GetPropertyChangedSignal("Text"):Connect(function() under.Text = l.Text end)
	end
	return l
end

function UIKit.darkLabel(props)
	local l = rawLabel(props)
	l.TextColor3 = props.colour or K.darkLabel
	l.TextStrokeColor3 = WHITE
	l.TextStrokeTransparency = 0.45
	return l
end

function UIKit.cross(owner, side, colour)
	local LENGTH = math.floor(side * 0.50)
	local THICKNESS = math.max(4, math.floor(side * 0.13))
	local STROKE = math.max(2, math.floor(side * 0.05))
	local function beam(angle, long, thick, beamColour, z)
		local b = Instance.new("Frame")
		b.Name = "Beam"
		b.AnchorPoint = Vector2.new(0.5, 0.5)
		b.Position = UDim2.fromScale(0.5, 0.5)
		b.Size = UDim2.fromScale(long / side, thick / side)
		b.Rotation = angle
		b.BackgroundColor3 = beamColour
		b.BorderSizePixel = 0
		b.ZIndex = z
		b.Active = false
		b.Parent = owner
		corner(b, 999)
	end
	for _, angle in ipairs({ 45, -45 }) do
		beam(angle, LENGTH + 2 * STROKE, THICKNESS + 2 * STROKE, K.outline, owner.ZIndex + 2)
	end
	for _, angle in ipairs({ 45, -45 }) do
		beam(angle, LENGTH, THICKNESS, colour or WHITE, owner.ZIndex + 3)
	end
end

function UIKit.icon(props)
	local i = Instance.new("ImageLabel")
	i.Name = props.name or "Icon"
	i.BackgroundTransparency = 1
	i.Image = props.image
	i.Size = props.size
	i.Position = props.position or UDim2.new()
	i.AnchorPoint = props.anchor or Vector2.new()
	i.ScaleType = Enum.ScaleType.Fit
	i.ZIndex = props.zindex or 2
	i.Parent = props.parent
	if props.tint then i.ImageColor3 = props.tint end
	if props.transparency then i.ImageTransparency = props.transparency end
	return i
end

function UIKit.iconWithShadow(props)
	local shiftBy = props.shadowY or math.max(2, math.floor((props.size.Y.Offset or 40) * 0.08))
	local pos = props.position or UDim2.new()
	local shadow = UIKit.icon({
		parent = props.parent, name = (props.name or "Icon") .. "Shadow",
		image = props.image, size = props.size,
		position = pos + UDim2.fromOffset(0, shiftBy),
		zindex = props.zindex or 2,
	})
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.55
	return UIKit.icon({
		parent = props.parent, name = props.name or "Icon",
		image = props.image, size = props.size, position = pos,
		zindex = (props.zindex or 2) + 1,
	})
end

function UIKit.button(props)

	local tone = props.tone or K.claimed
	local b = UIKit.block({
		parent = props.parent, name = props.name or "Button", tone = tone,
		radius = props.radius or 11, clickable = true, stud = props.stud or 11,
		size = props.size, position = props.position or UDim2.new(),
		anchor = props.anchor, zindex = props.zindex or 2, outline = props.outline or 3,
	})
	if props.layoutOrder then b.LayoutOrder = props.layoutOrder end
	local label = UIKit.boldLabel({
		parent = b, name = "Label", size = UDim2.fromScale(1, 1),
		text = props.text or "", textSize = props.textSize or 18,
		zindex = (props.zindex or 2) + 3,
	})
	UIKit.reactToCursor(b)
	b:SetAttribute("Active", true)

	if props.onClick then
		b.MouseButton1Click:Connect(function()
			if b:GetAttribute("Active") ~= false then
				if props.silent ~= true then
					Sfx.play("click")
				end
				props.onClick()
			end
		end)
	end
	local function setEnabled(v)
		b:SetAttribute("Active", v)
		UIKit.repaint(b, v and tone or K.lock)
	end
	local function setText(t) label.Text = t end
	local function setTone(t) tone = t UIKit.repaint(b, t) end
	return b, setEnabled, setText, setTone
end

function UIKit.field(props)
	local box = Instance.new("TextBox")
	box.Name = props.name or "Field"
	box.Size = props.size or UDim2.fromOffset(120, 38)
	box.Position = props.position or UDim2.new()
	box.BackgroundColor3 = K.outline
	box.BorderSizePixel = 0
	box.Font = Enum.Font.FredokaOne
	box.TextColor3 = WHITE
	box.PlaceholderColor3 = tint(K.outline, 0.55)
	box.Text = props.text or ""
	box.PlaceholderText = props.placeholder or ""
	box.TextScaled = false
	box.TextSize = props.textSize or 18
	box.ClearTextOnFocus = false
	box.ZIndex = props.zindex or 3
	box.Parent = props.parent
	corner(box, props.radius or 9)
	UIKit.stroke(box, K.innerOutline, 2, 0)
	return box
end

local FALLBACK_TOP = 44
local HUD_GAP = 12
local BOTTOM_MARGIN = 76
local SIDE_MARGIN = 16
local SHADOW_FADE = 5

local function playerGui()
	local player = Players.LocalPlayer
	return player and player:FindFirstChildOfClass("PlayerGui")
end

local function visibleBar(guiName, barName)
	local pg = playerGui()
	local sg = pg and pg:FindFirstChild(guiName)
	local bar = sg and sg:FindFirstChild(barName)
	if bar and bar:IsA("GuiObject") and bar.Visible and sg.Enabled then
		return bar
	end
	return nil
end

local function topReserve()
	local bar = visibleBar("GameTopbar", "Topbar")
	if bar then
		return bar.AbsolutePosition.Y + bar.AbsoluteSize.Y
	end
	return FALLBACK_TOP
end

local function bottomReserve(screen)
	return math.min(BOTTOM_MARGIN, screen * 0.1)
end

function UIKit.fitWindow(root, scale, opts)
	opts = opts or {}
	local function recompute()
		local cam = workspace.CurrentCamera
		if not cam then return scale.Scale end
		local inset = GuiService:GetGuiInset().Y
		local screen = cam.ViewportSize.Y - inset
		local headroom = root:GetAttribute("FitHeadRoom") or 0
		local height = math.max(root.Size.Y.Offset, 1) + headroom
		local small = math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
		local top = opts.topReserve or (small and 4 or (topReserve() + HUD_GAP))
		local bottom = opts.bottomReserve or (small and 4 or bottomReserve(screen))

		local width = math.max(root.Size.X.Offset, 1)
		local byHeight = (screen - top - bottom) / height
		local byWidth = (cam.ViewportSize.X - SIDE_MARGIN * 2) / width

		local target = root:GetAttribute("FitTargetHeight")
		local s = math.min(byHeight, byWidth, target and target / height or 1)
		s = math.max(s, small and 0.3 or 0.43)
		scale.Scale = s

		local half = height * s / 2
		local highest, lowest = top + half, screen - bottom - half

		local centre = (lowest < highest) and (screen / 2)
			or math.clamp(screen / 2, highest, lowest)

		local sg = root:FindFirstAncestorWhichIsA("ScreenGui")
		local shift = (sg and sg.IgnoreGuiInset) and inset or 0
		root.AnchorPoint = Vector2.new(0.5, 0.5)
		root.Position = UDim2.new(0.5, 0, 0, math.floor(centre + shift + headroom * s / 2))

		local shadow = root.Parent and root.Parent:FindFirstChild(root.Name .. "_Shadow")
		if shadow then
			shadow.AnchorPoint = root.AnchorPoint
			shadow.Position = root.Position + UDim2.fromOffset(0, SHADOW_FADE)
			local sc = shadow:FindFirstChildWhichIsA("UIScale")
			if not sc then
				sc = Instance.new("UIScale")
				sc.Parent = shadow
			end
			sc.Scale = s
		end
		return s
	end
	recompute()

	local function track(cam)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(recompute) end
	end
	track(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		track(workspace.CurrentCamera)
		recompute()
	end)

	return recompute
end

function UIKit.popOpen(scale, target)
	scale.Scale = target * 0.82
	TweenService:Create(scale, UIKit.Tween.pop, { Scale = target }):Play()
end

local blurHolders = 0
function UIKit.blurHold(on)
	local Lighting = game:GetService("Lighting")
	local b = Lighting:FindFirstChild("PanelBlur")
	if not b then
		b = Instance.new("BlurEffect")
		b.Name = "PanelBlur"
		b.Parent = Lighting
	end
	b.Size = 28
	blurHolders = math.max(0, blurHolders + (on and 1 or -1))
	b.Enabled = blurHolders > 0
end

function UIKit.window(props)
	local MARGIN = props.margin or 18
	local width, height = props.width, props.height
	local bodyW = width - 2 * MARGIN
	local z = props.zindex or 10
	local BAR_H = props.barHeight or UIKit.headHeight(width)

	local root = UIKit.block({
		parent = props.parent, name = props.name, tone = K.panel,

		outline = 3, radius = 15, shadowY = 8,
		stud = 15, studAlpha = 0.55,
		size = UDim2.fromOffset(width, height),
		position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5),
		zindex = z,
	})
	root.Visible = false
	root.BackgroundTransparency = 0.35
	root.ClipsDescendants = false

	local scale = Instance.new("UIScale")
	scale.Parent = root
	local fit = UIKit.fitWindow(root, scale)

	local bar = UIKit.block({
		parent = root, name = "Header", tone = K.bar, radius = 12,
		stud = 10, studAlpha = 0.58, outline = 3, shadow = false,
		size = UDim2.new(1, 0, 0, BAR_H), position = UDim2.new(),
		zindex = z + 4,
	})

	if props.icon then
		local iconH = BAR_H - 14
		UIKit.iconWithShadow({
			parent = bar, name = "Icon", image = props.icon,
			size = UDim2.fromOffset(iconH, iconH),
			position = UDim2.fromOffset(12, math.floor((BAR_H - iconH) / 2)),
			zindex = z + 6,
		})
	end

	UIKit.boldLabel({
		parent = bar, name = "Title", size = UDim2.fromScale(1, 1),
		text = props.title, textSize = math.floor(BAR_H * 0.68),
		truncate = Enum.TextTruncate.AtEnd,
		strokeColour = Color3.fromRGB(43, 23, 64), strokeW = 4, zindex = z + 8,
	})

	local closeSide = BAR_H - 24
	local close = UIKit.block({
		parent = bar, name = "Close", tone = K.close, clickable = true,
		radius = 11, outline = 2, stud = 9, studAlpha = 0.70, shadowY = 4,
		size = UDim2.fromOffset(closeSide, closeSide),
		position = UDim2.new(1, -(closeSide + 14), 0.5, 0), anchor = Vector2.new(0, 0.5),
		zindex = z + 8,
	})
	UIKit.cross(close, closeSide)
	UIKit.tintOnHover(close, K.close)

	local panel = {}
	local holdsBlur = false
	function panel.isOpen() return root.Visible end
	function panel.open()
		root.Visible = true
		if not holdsBlur then
			holdsBlur = true
			UIKit.blurHold(true)
		end
		UIKit.popOpen(scale, fit())
	end
	function panel.close()
		root.Visible = false
		if holdsBlur then
			holdsBlur = false
			UIKit.blurHold(false)
		end
	end
	close.MouseButton1Click:Connect(panel.close)

	return root, panel, bodyW, BAR_H + 12
end
return UIKit