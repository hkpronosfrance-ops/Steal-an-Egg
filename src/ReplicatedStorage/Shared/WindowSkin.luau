local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local S = {}

local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
local INK = Color3.fromRGB(14, 14, 18)
local BODY = Color3.fromRGB(58, 62, 69)
local BODY_RIM = Color3.fromRGB(96, 101, 110)
local CARD = Color3.fromRGB(38, 41, 47)
local CARD_EDGE = Color3.fromRGB(24, 26, 30)
local SKY = { Color3.fromRGB(70, 175, 255), Color3.fromRGB(30, 110, 225) }
local STUDS = "rbxassetid://138926013267839"
local HEAD = 78
local FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

S.WindowAlpha = 0.5
S.CardAlpha = 0.55
S.TargetHeight = 560

local GREEN = { Color3.fromRGB(70, 230, 40), Color3.fromRGB(215, 255, 50) }
local BLUE = { Color3.fromRGB(40, 140, 255), Color3.fromRGB(80, 225, 255) }
local HEADS = {
	Shop = { Color3.fromRGB(255, 150, 0), Color3.fromRGB(255, 235, 40) },
	Index = { Color3.fromRGB(150, 70, 255), Color3.fromRGB(255, 110, 230) },
	SellShop = GREEN,
	Rebirth = GREEN,
	FreeRewards = GREEN,
	GiftWindow = GREEN,
	TrailShop = BLUE,
	Settings = BLUE,
	Confirm = BLUE,
	FuseMachine = { Color3.fromRGB(20, 120, 240), Color3.fromRGB(70, 235, 255) },
	Admin = { Color3.fromRGB(230, 40, 40), Color3.fromRGB(255, 140, 50) },
	ActivePets = { Color3.fromRGB(255, 120, 20), Color3.fromRGB(255, 205, 60) },
	GrowingEggs = { Color3.fromRGB(235, 45, 45), Color3.fromRGB(255, 140, 90) },
}
local KEEP_SIZE = { GiftWindow = true, Confirm = true, ActivePets = true, GrowingEggs = true, Rebirth = true }
local SIDE = { ActivePets = true, GrowingEggs = true }
local SEE_THROUGH = { SellShop = 0.5 }
local DECOR = { Studs = true, Bevel = true, Underside = true, SkinRim = true, Header = true }

local function keyOf(panel)
	if panel.Name == "Frame" and panel.Parent then
		return panel.Parent.Name
	end
	return panel.Name
end

local function mul(a, b)
	return Color3.new(a.R * b.R, a.G * b.G, a.B * b.B)
end

local function titleCase(s)
	return (s:lower():gsub("(%a)([%w']*)", function(first, rest)
		return first:upper() .. rest
	end))
end

local function edge(o, thickness, colour, transparency)
	local s = o:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = colour or INK
	s.Transparency = transparency or 0
	s.LineJoinMode = Enum.LineJoinMode.Miter
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Enabled = true
	s.Parent = o
	return s
end

local function corner(o, radius)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius)
	c.Parent = o
	return c
end

local function hideShadow(o)
	local parent = o.Parent
	if not parent then
		return
	end
	for _, c in parent:GetChildren() do
		if c.Name == o.Name .. "_Shadow" and c:IsA("Frame") then
			c.BackgroundTransparency = 1
		end
	end
end

local function square(o)
	for _, c in o:GetChildren() do
		if c:IsA("UICorner") then
			c:Destroy()
		end
	end
	for _, n in { "Bevel", "Underside", "InnerRing" } do
		local x = o:FindFirstChild(n)
		if x then
			x.Visible = false
		end
	end
	local inner = o:FindFirstChild("Inner")
	if inner and inner:IsA("Frame") and inner.BackgroundTransparency >= 1 and inner:FindFirstChildOfClass("UIStroke") then
		inner.Visible = false
	end
	local studs = o:FindFirstChild("Studs")
	local sc = studs and studs:FindFirstChildOfClass("UICorner")
	if sc then
		sc:Destroy()
	end
	hideShadow(o)
end

local function studs(o, alpha, tile, z)
	local st = o:FindFirstChild("Studs")
	if not (st and st:IsA("ImageLabel")) then
		st = Instance.new("ImageLabel")
		st.Name = "Studs"
		st.BackgroundTransparency = 1
		st.Active = false
		st.Size = UDim2.fromScale(1, 1)
		st.Parent = o
	end
	st.Image = STUDS
	st.ScaleType = Enum.ScaleType.Tile
	st.TileSize = UDim2.fromOffset(tile, tile)
	st.ImageTransparency = alpha
	st.Visible = true
	st.ZIndex = z or o.ZIndex
	return st
end

local RIM_BARS = {
	{ UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 0, 0) },
	{ UDim2.new(1, 0, 0, 2), UDim2.new(0, 0, 1, -2) },
	{ UDim2.new(0, 2, 1, -4), UDim2.new(0, 0, 0, 2) },
	{ UDim2.new(0, 2, 1, -4), UDim2.new(1, -2, 0, 2) },
}
local function setRim(r, colour, transparency)
	for _, bar in r:GetChildren() do
		if bar:IsA("Frame") then
			bar.BackgroundColor3 = colour
			if transparency then
				bar.BackgroundTransparency = transparency
			end
		end
	end
end

local function innerRim(o, colour, transparency, z)
	local r = o:FindFirstChild("SkinRim")
	if not r then
		r = Instance.new("Frame")
		r.Name = "SkinRim"
		r.BackgroundTransparency = 1
		r.Active = false
		r.Size = UDim2.fromScale(1, 1)
		r.Parent = o
		for i, look in RIM_BARS do
			local bar = Instance.new("Frame")
			bar.Name = "Bar" .. i
			bar.BorderSizePixel = 0
			bar.Active = false
			bar.Size = look[1]
			bar.Position = look[2]
			bar.Parent = r
		end
	end
	r.ZIndex = z or o.ZIndex
	for _, bar in r:GetChildren() do
		if bar:IsA("Frame") then
			bar.ZIndex = r.ZIndex
		end
	end
	setRim(r, colour, transparency or 0)
	return r
end

local function raise(o, d)
	if d <= 0 then
		return
	end
	o.ZIndex += d
	for _, x in o:GetDescendants() do
		if x:IsA("GuiObject") then
			x.ZIndex += d
		end
	end
end

local function heightOf(o)
	local h = o:GetAttribute("BlockHeight")
	if not h or h <= 0 then
		h = (o.Size.Y.Scale == 0 and o.Size.Y.Offset > 0) and o.Size.Y.Offset or o.AbsoluteSize.Y
	end
	return math.max(h, 1)
end

function S.button(b)
	if b:GetAttribute("WindowSkinned") then
		return
	end
	b:SetAttribute("WindowSkinned", true)
	b:SetAttribute("HoverMaxGrow", 0)
	local h = math.max(heightOf(b), 20)
	local radius = math.clamp(math.floor(h * 0.22), 6, 10)
	square(b)
	local old = b:FindFirstChild("Studs")
	if old then
		old.Visible = false
	end
	local ink = b:FindFirstChildOfClass("UIStroke")
	if ink then
		ink.Enabled = false
	end
	b.BackgroundTransparency = 1
	local z = b.ZIndex
	local function layer(parent, name, inset, colour, r, zi)
		local f = Instance.new("Frame")
		f.Name = name
		f.Active = false
		f.BorderSizePixel = 0
		f.BackgroundColor3 = colour
		f.AnchorPoint = Vector2.new(0.5, 0.5)
		f.Position = UDim2.fromScale(0.5, 0.5)
		f.Size = UDim2.new(1, -inset * 2, 1, -inset * 2)
		f.ZIndex = zi
		f.Parent = parent
		corner(f, math.max(2, r))
		return f
	end
	for _, c in b:GetChildren() do
		if c:IsA("GuiObject") and c.ZIndex <= z + 5 then
			raise(c, z + 6 - c.ZIndex)
		end
	end
	local border = layer(b, "BtnBorder", 0, INK, radius, z + 1)
	local rim = layer(border, "BtnRim", 2, BLACK, radius - 2, z + 2)
	local fill = layer(rim, "BtnFill", 2, WHITE, radius - 4, z + 3)
	local fg = Instance.new("UIGradient")
	fg.Rotation = 90
	fg.Parent = fill
	local st = Instance.new("ImageLabel")
	st.Name = "BtnStuds"
	st.BackgroundTransparency = 1
	st.Active = false
	st.Image = STUDS
	st.ScaleType = Enum.ScaleType.Tile
	local tile = math.clamp(math.floor(h * 0.15), 4, 12)
	st.TileSize = UDim2.fromOffset(tile, tile)
	st.ImageTransparency = 0.3
	st.Size = UDim2.fromScale(1, 1)
	st.ZIndex = z + 4
	st.Parent = fill
	corner(st, math.max(2, radius - 4))
	local glow = layer(fill, "BtnHover", 0, WHITE, radius - 4, z + 5)
	glow.BackgroundTransparency = 1
	corner(b, radius)
	local function shade()
		local bg = b.BackgroundColor3
		local top, base = bg, bg
		local g = b:FindFirstChildOfClass("UIGradient")
		if g then
			local k = g.Color.Keypoints
			top = mul(bg, k[1].Value)
			base = mul(bg, k[math.min(2, #k)].Value)
		end
		fg.Color = ColorSequence.new(top, base)
		rim.BackgroundColor3 = base:Lerp(BLACK, 0.45)
	end
	shade()
	b:GetPropertyChangedSignal("BackgroundColor3"):Connect(shade)
	local g = b:FindFirstChildOfClass("UIGradient")
	if g then
		g:GetPropertyChangedSignal("Color"):Connect(shade)
	end
	local function light(on)
		local lit = on and b:GetAttribute("Active") ~= false
		TweenService:Create(glow, FAST, { BackgroundTransparency = lit and 0.8 or 1 }):Play()
	end
	b.MouseEnter:Connect(function()
		light(true)
	end)
	b.MouseLeave:Connect(function()
		light(false)
	end)
	for _, t in b:GetDescendants() do
		if t:IsA("TextLabel") then
			local s = t:FindFirstChildOfClass("UIStroke")
			if s then
				s.Color = INK
			end
		end
	end
	local label = b:FindFirstChild("Label")
	local sym = label and label:IsA("TextLabel") and (label.Text == "+" or label.Text == "-") and label.Text
	if sym then
		label.TextTransparency = 1
		local ls = label:FindFirstChildOfClass("UIStroke")
		if ls then
			ls.Enabled = false
		end
	end
	local signs = {}
	for _, c in b:GetChildren() do
		if c.Name == "Sign" and c:IsA("Frame") then
			table.insert(signs, c)
		end
	end
	if not sym and #signs > 0 then
		sym = #signs >= 4 and "+" or "-"
		for _, c in signs do
			c.Visible = false
		end
	end
	if sym then
		local inset = math.max(3, math.floor(h * 0.1))
		local box = Instance.new("Frame")
		box.Name = "Symbol"
		box.BackgroundTransparency = 1
		box.Active = false
		box.AnchorPoint = Vector2.new(0.5, 0.5)
		box.Position = UDim2.fromScale(0.5, 0.5)
		box.Size = UDim2.fromScale(0.6, 0.6)
		box.ZIndex = z + 6
		box.Parent = b
		Instance.new("UIAspectRatioConstraint").Parent = box
		for i, look in { { INK, 0 }, { WHITE, inset } } do
			for _, angle in (sym == "+" and { 0, 90 } or { 0 }) do
				local bar = Instance.new("Frame")
				bar.Name = i == 1 and "BarOutline" or "Bar"
				bar.AnchorPoint = Vector2.new(0.5, 0.5)
				bar.Position = UDim2.fromScale(0.5, 0.5)
				bar.Size = UDim2.new(1, -look[2], 0.36, -look[2])
				bar.Rotation = angle
				bar.BackgroundColor3 = look[1]
				bar.BorderSizePixel = 0
				bar.Active = false
				bar.ZIndex = z + 6 + i
				bar.Parent = box
				corner(bar, 3)
			end
		end
	end
end

local function shownColours(o, g)
	local bg = o.BackgroundColor3
	if not g then
		return { bg }
	end
	local k = g.Color.Keypoints
	if k[1].Value == WHITE and bg ~= WHITE then
		return { bg, mul(bg, k[math.min(2, #k)].Value) }
	end
	local out = {}
	for _, p in k do
		table.insert(out, mul(bg, p.Value))
	end
	return out
end

local function vivid(colours)
	for _, c in colours do
		local _, s, v = c:ToHSV()
		if s > 0.3 and v > 0.25 then
			return true
		end
	end
	return false
end

local function sequence(colours)
	if #colours == 1 then
		return ColorSequence.new(colours[1])
	end
	local points = {}
	for i, c in colours do
		table.insert(points, ColorSequenceKeypoint.new((i - 1) / (#colours - 1), c))
	end
	return ColorSequence.new(points)
end

local function colourCard(o, g, side, alpha)
	g.Enabled = true
	local rim = innerRim(o, BLACK, 0)
	local function paint()
		local uikit = g.Color.Keypoints[1].Value == WHITE and o.BackgroundColor3 ~= WHITE
		local colours = shownColours(o, g)
		if uikit then
			local _, _, v = colours[2]:ToHSV()
			if v < 0.62 then
				colours = { SKY[1], SKY[2] }
			else
				colours = { colours[2], colours[2]:Lerp(BLACK, 0.4) }
			end
		end
		o.BackgroundColor3 = WHITE
		g.Color = sequence(colours)
		local dark = colours[#colours]:Lerp(BLACK, 0.45)
		setRim(rim, dark)
		for _, d in o:GetDescendants() do
			if d:IsA("Frame") and d.Parent ~= rim and d.Size.Y.Scale == 0 and d.Size.Y.Offset > 0
				and d.Size.Y.Offset <= 6 and d.BackgroundTransparency < 1 and not d:FindFirstAncestorWhichIsA("GuiButton") then
				d.BackgroundColor3 = dark
				d.BackgroundTransparency = 0
				for _, c in d:GetChildren() do
					if c:IsA("UICorner") or c:IsA("UIGradient") then
						c:Destroy()
					end
				end
			end
		end
	end
	paint()
	o.BackgroundTransparency = alpha or 0.1
	edge(o, 3, INK)
	studs(o, 0.6, math.clamp(math.floor(side * 0.12), 6, 14))
	o:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if o.BackgroundColor3 ~= WHITE then
			paint()
		end
	end)
end

local function whiteText(o)
	for _, t in o:GetDescendants() do
		if t:IsA("TextLabel") then
			local c = t.TextColor3
			if 0.299 * c.R + 0.587 * c.G + 0.114 * c.B < 0.3 then
				t.TextColor3 = WHITE
				t.TextStrokeTransparency = 1
				local s = t:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
				s.Color = INK
				s.Thickness = math.max(s.Thickness, 2)
				s.LineJoinMode = Enum.LineJoinMode.Round
				s.Parent = t
			end
		end
	end
end

function S.card(o, key)
	if o:GetAttribute("WindowSkinned") then
		return
	end
	o:SetAttribute("WindowSkinned", true)
	local normal = o.BackgroundColor3
	square(o)
	local size = o.AbsoluteSize
	local side = (size.X > 0 and size.Y > 0) and math.min(size.X, size.Y) or heightOf(o)
	local g = o:FindFirstChild("Gradient") or o:FindFirstChildOfClass("UIGradient")
	if g and vivid(shownColours(o, g)) then
		colourCard(o, g, side, key and SEE_THROUGH[key])
		whiteText(o)
		return
	end
	if g then
		g.Enabled = false
	end
	o.BackgroundColor3 = CARD
	o.BackgroundTransparency = S.CardAlpha
	local line = edge(o, 2, CARD_EDGE)
	studs(o, 0.62, math.clamp(math.floor(side * 0.15), 6, 16))
	whiteText(o)
	o:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		local c = o.BackgroundColor3
		if c == CARD then
			return
		end
		local marked = c ~= normal
		line.Color = marked and c or CARD_EDGE
		line.Thickness = marked and 3 or 2
		o.BackgroundColor3 = CARD
	end)
end

function S.close(close)
	if close:GetAttribute("WindowSkinned") then
		return
	end
	close:SetAttribute("WindowSkinned", true)
	close:SetAttribute("HoverMaxGrow", 0)
	square(close)
	close.BackgroundTransparency = 1
	if close:IsA("TextButton") then
		close.TextTransparency = 1
	end
	local ink = close:FindFirstChildOfClass("UIStroke")
	if ink then
		ink.Enabled = false
	end
	for _, c in close:GetChildren() do
		if c:IsA("GuiObject") then
			c.Visible = false
		end
	end
	local z = close.ZIndex
	local side = HEAD - 16
	local face = Instance.new("Frame")
	face.Name = "SkinFace"
	face.Active = false
	face.BorderSizePixel = 0
	face.BackgroundColor3 = WHITE
	face.AnchorPoint = Vector2.new(0.5, 0.5)
	face.Position = UDim2.fromScale(0.5, 0.5)
	face.Size = UDim2.fromOffset(side, side)
	face.ZIndex = z + 1
	face.Parent = close
	edge(face, 3, INK)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromRGB(245, 60, 50), Color3.fromRGB(190, 20, 20))
	g.Parent = face
	studs(face, 0.4, 9, z + 2)
	innerRim(face, Color3.fromRGB(120, 10, 10), 0.1, z + 2)
	local glow = Instance.new("Frame")
	glow.Name = "SkinGlow"
	glow.Active = false
	glow.BorderSizePixel = 0
	glow.BackgroundColor3 = WHITE
	glow.BackgroundTransparency = 1
	glow.Size = UDim2.fromScale(1, 1)
	glow.ZIndex = z + 3
	glow.Parent = face
	local x = Instance.new("Frame")
	x.Name = "SkinX"
	x.BackgroundTransparency = 1
	x.Active = false
	x.AnchorPoint = Vector2.new(0.5, 0.5)
	x.Position = UDim2.fromScale(0.5, 0.5)
	x.Size = UDim2.fromScale(0.62, 0.62)
	x.ZIndex = z + 4
	x.Parent = face
	Instance.new("UIAspectRatioConstraint").Parent = x
	for i, look in { { INK, 0 }, { WHITE, 6 } } do
		for _, angle in { 45, -45 } do
			local arm = Instance.new("Frame")
			arm.Name = i == 1 and "ArmOutline" or "Arm"
			arm.AnchorPoint = Vector2.new(0.5, 0.5)
			arm.Position = UDim2.fromScale(0.5, 0.5)
			arm.Size = UDim2.new(1.2, -look[2], 0.3, -look[2])
			arm.Rotation = angle
			arm.BackgroundColor3 = look[1]
			arm.BorderSizePixel = 0
			arm.Active = false
			arm.ZIndex = z + 4 + i
			arm.Parent = x
			corner(arm, 999)
		end
	end
	close.MouseEnter:Connect(function()
		TweenService:Create(glow, FAST, { BackgroundTransparency = 0.8 }):Play()
	end)
	close.MouseLeave:Connect(function()
		TweenService:Create(glow, FAST, { BackgroundTransparency = 1 }):Play()
	end)
end

local function insideSkinned(o, stop)
	local a = o.Parent
	while a and a ~= stop do
		if a:IsA("GuiButton") and a:GetAttribute("WindowSkinned") then
			return true
		end
		a = a.Parent
	end
	return false
end

local function inHeader(o, stop)
	local a = o
	while a and a ~= stop do
		if a.Name == "Header" then
			return true
		end
		a = a.Parent
	end
	return false
end

function S.content(panel)
	local root = panel
	if panel.Name == "Frame" and panel.Parent and panel.Parent:IsA("GuiObject") then
		root = panel.Parent
	end
	for _, o in root:GetDescendants() do
		if o:IsA("GuiObject") and o:GetAttribute("BlockHeight") and not o:GetAttribute("WindowSkinned")
			and not o:FindFirstChild("Header") and not inHeader(o, root) and not insideSkinned(o, root) then
			local c = o.BackgroundColor3
			local light = 0.299 * c.R + 0.587 * c.G + 0.114 * c.B > 0.85
			local label = o:FindFirstChild("Label") or o:FindFirstChild("Text")
			local buttonLike = o:GetAttribute("SkinButtonLook")
				or (label and label:IsA("TextLabel") and label.Size == UDim2.fromScale(1, 1) and heightOf(o) < 100)
			if o:IsA("GuiButton") or buttonLike then
				S.button(o)
			elseif heightOf(o) >= 50 or (light and heightOf(o) >= 30) then
				S.card(o, keyOf(panel))
			end
		end
	end
end

local function movable(c, head)
	if not c:IsA("GuiObject") or c == head or DECOR[c.Name] or c.Position.Y.Scale ~= 0 then
		return false
	end
	return not (c.Size.Y.Scale >= 1 and c.Position.Y.Offset <= 0)
end

local function shiftUp(c, delta)
	if c:GetAttribute("SkinShifted") then
		return
	end
	c:SetAttribute("SkinShifted", true)
	c.Position -= UDim2.fromOffset(0, delta)
	c:SetAttribute("MovedBy", UDim2.fromOffset(0, -delta))
	if c.Size.Y.Scale ~= 0 then
		c.Size += UDim2.fromOffset(0, math.floor(c.Size.Y.Scale * delta + 0.5))
	end
end

local function straddle(panel, head)
	local list = {}
	local top = math.huge
	for _, c in panel:GetChildren() do
		if movable(c, head) then
			table.insert(list, c)
			local h = c.Size.Y.Scale == 0 and c.Size.Y.Offset or 0
			top = math.min(top, c.Position.Y.Offset - c.AnchorPoint.Y * h)
		end
	end
	local delta = top - (HEAD / 2 + 14)
	if top == math.huge or delta <= 0 then
		return 0
	end
	for _, c in list do
		shiftUp(c, delta)
	end
	panel.Size -= UDim2.fromOffset(0, delta)
	panel.ChildAdded:Connect(function(c)
		task.defer(function()
			if c.Parent == panel and movable(c, head) then
				shiftUp(c, delta)
			end
		end)
	end)
	return delta
end

function S.window(panel)
	local head = panel:FindFirstChild("Header")
	if not head or panel:GetAttribute("SkinWindow") then
		return
	end
	panel:SetAttribute("SkinWindow", true)
	local key = keyOf(panel)
	local pal = HEADS[key] or BLUE

	square(panel)
	panel.ClipsDescendants = false
	local pg = panel:FindFirstChild("Gradient") or panel:FindFirstChildOfClass("UIGradient")
	if pg then
		pg.Enabled = false
	end
	panel.BackgroundColor3 = BODY
	panel.BackgroundTransparency = S.WindowAlpha
	edge(panel, 4, INK)
	studs(panel, 0.82, 24)
	innerRim(panel, BODY_RIM, 0.3)

	square(head)
	head.ClipsDescendants = false
	for _, c in head:GetChildren() do
		if c:IsA("CanvasGroup") then
			c.Visible = false
		end
	end
	local hg = head:FindFirstChild("Gradient") or head:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
	local headColours = ColorSequence.new(pal[1], pal[2])
	hg.Enabled = true
	hg.Rotation = 0
	hg.Color = headColours
	hg.Parent = head
	head.BackgroundColor3 = WHITE
	head.BackgroundTransparency = 0
	head:GetPropertyChangedSignal("BackgroundColor3"):Connect(function()
		if head.BackgroundColor3 ~= WHITE then
			head.BackgroundColor3 = WHITE
		end
	end)
	hg:GetPropertyChangedSignal("Color"):Connect(function()
		if hg.Color ~= headColours then
			hg.Color = headColours
		end
	end)
	hg:GetPropertyChangedSignal("Rotation"):Connect(function()
		if hg.Rotation ~= 0 then
			hg.Rotation = 0
		end
	end)
	edge(head, 4, INK)
	studs(head, 0.72, 20)
	innerRim(head, pal[1]:Lerp(BLACK, 0.4), 0)
	local oldHead = head.Size.Y.Offset
	head.AnchorPoint = Vector2.zero
	head.Position = UDim2.fromOffset(-10, -HEAD / 2)
	head.Size = UDim2.new(1, 20, 0, HEAD)

	local titleX = 24
	local icon = head:FindFirstChild("Icon")
	for _, c in head:GetChildren() do
		if c:IsA("ImageLabel") and c.Name ~= "Studs" then
			if c.Name:match("Shadow$") then
				c.Visible = false
			elseif not (icon and icon:IsA("ImageLabel")) then
				icon = c
			end
		end
	end
	if icon and icon:IsA("ImageLabel") then
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, -8, 0.5, -4)
		icon.Size = UDim2.fromOffset(HEAD + 34, HEAD + 34)
		titleX = HEAD + 32
	end
	local extra = 0
	for _, c in head:GetChildren() do
		if c:IsA("GuiButton") and c.Name ~= "Close" and c:GetAttribute("BlockHeight") then
			extra = math.max(extra, c.Size.X.Offset + 14)
			S.button(c)
		end
	end
	local title = head:FindFirstChild("Title")
	if title and title:IsA("TextLabel") then
		local function fix()
			local t = titleCase(title.Text)
			if title.Text ~= t then
				title.Text = t
			end
		end
		fix()
		title:GetPropertyChangedSignal("Text"):Connect(fix)
		local right = (head:FindFirstChild("Close") and HEAD or 16) + extra + 8
		title.AnchorPoint = Vector2.new(0, 0.5)
		title.Position = UDim2.new(0, titleX, 0.5, 0)
		title.Size = UDim2.new(1, -(titleX + right), 0.8, 0)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextScaled = true
		title.TextTruncate = Enum.TextTruncate.None
		local lim = title:FindFirstChildOfClass("UITextSizeConstraint") or Instance.new("UITextSizeConstraint")
		lim.MinTextSize = 14
		lim.MaxTextSize = 64
		lim.Parent = title
		local ts = title:FindFirstChildOfClass("UIStroke")
		if ts then
			ts.Thickness = 2.5
			ts.Color = INK
		end
		local ghost = head:FindFirstChild("Title_Shadow")
		if ghost then
			ghost.Visible = false
		end
	end
	local close = head:FindFirstChild("Close")
	if close then
		S.close(close)
		local face = close:FindFirstChild("SkinFace")
		local p, s, a = close.Position, close.Size, close.AnchorPoint
		if face and p.X.Scale == 1 and s.X.Scale == 0 and s.Y.Scale == 0 then
			local side = face.Size.X.Offset
			local cx = p.X.Offset + (0.5 - a.X) * s.X.Offset
			local cy = p.Y.Scale * HEAD + p.Y.Offset + (0.5 - a.Y) * s.Y.Offset
			face.Position = UDim2.new(0.5, math.floor(-(12 + side / 2) - cx), 0.5, math.floor(HEAD / 2 - cy))
		end
	end

	local sg = panel:FindFirstAncestorWhichIsA("ScreenGui")
	local global = sg and sg.ZIndexBehavior == Enum.ZIndexBehavior.Global
	local topZ = 0
	for _, c in (global and panel:GetDescendants() or panel:GetChildren()) do
		if c:IsA("GuiObject") and c ~= head and not c:IsDescendantOf(head) then
			topZ = math.max(topZ, c.ZIndex)
		end
	end
	raise(head, topZ + 1 - head.ZIndex)

	local delta = straddle(panel, head)
	panel:SetAttribute("SkinShift", delta)
	if SIDE[key] then
		panel.Position -= UDim2.fromOffset(14, 0)
		local shell = panel.Parent
		if shell and shell:IsA("GuiObject") then
			local groups = {}
			local function frameFor(name, dy)
				if not groups[name] then
					local f = Instance.new("Frame")
					f.Name = name
					f.BackgroundTransparency = 1
					f.Active = false
					f.Size = UDim2.fromScale(1, 1)
					f.Position = UDim2.fromOffset(-14, dy)
					f.ZIndex = panel.ZIndex + 1
					f.Parent = shell
					groups[name] = f
				end
				return groups[name]
			end
			local h = shell.Size.Y.Offset
			local below, belowTop = {}, math.huge
			for _, c in shell:GetChildren() do
				if c:IsA("GuiObject") and c ~= panel and c.Name ~= panel.Name .. "_Shadow" then
					local y = c.Position.Y
					if y.Scale == 0.5 then
						c.Parent = frameFor("SkinSideMiddle", -math.floor((HEAD / 2 + delta) / 2))
					elseif y.Scale == 1 or (y.Scale == 0 and y.Offset > h / 2) then
						table.insert(below, c)
						if not c.Name:match("_Shadow$") then
							local sh = c.Size.Y.Scale == 0 and c.Size.Y.Offset or 0
							belowTop = math.min(belowTop, y.Scale * h + y.Offset - c.AnchorPoint.Y * sh)
						end
					else
						c.Parent = frameFor("SkinSideTop", 0)
					end
				end
			end
			if #below > 0 and belowTop < math.huge then
				local bottom = panel.Position.Y.Scale * h + panel.Position.Y.Offset
					+ (1 - panel.AnchorPoint.Y) * panel.Size.Y.Offset
				local f = frameFor("SkinSideBelow", math.floor(bottom + 10 - belowTop))
				for _, c in below do
					c.Parent = f
				end
			end
		end
	end
	panel:SetAttribute("SkinOldHead", oldHead)
	S.content(panel)
end

local function available()
	local cam = workspace.CurrentCamera
	if not cam then
		return S.TargetHeight, 1000
	end
	local vp = cam.ViewportSize
	local small = math.min(vp.X, vp.Y) < 500
	local room = vp.Y - (small and 16 or (GuiService:GetGuiInset().Y + 110))
	return math.min(S.TargetHeight, room), vp.X - 24
end

function S.normalize(panel)
	if KEEP_SIZE[keyOf(panel)] or panel:GetAttribute("SkinNormalized") then
		return
	end
	local holder = panel
	local sc
	while holder and holder:IsA("GuiObject") do
		sc = holder:FindFirstChildOfClass("UIScale")
		if sc then
			break
		end
		holder = holder.Parent
	end
	if not sc then
		return
	end
	panel:SetAttribute("SkinNormalized", true)
	local function wanted()
		local h, w = available()
		local visualH = panel.Size.Y.Offset + HEAD / 2
		local visualW = panel.Size.X.Offset + 20
		return math.min(h / math.max(visualH, 1), w / math.max(visualW, 1))
	end
	if holder ~= panel then
		local own = Instance.new("UIScale")
		own.Name = "SkinScale"
		own.Parent = panel
		local shift = panel:GetAttribute("SkinShift") or 0
		if panel.Position.X.Scale == 0 and panel.Position.Y.Scale == 0 and panel.AnchorPoint == Vector2.zero then
			local size = panel.Size
			panel.AnchorPoint = Vector2.new(0.5, 0.5)
			panel.Position = UDim2.new(0, size.X.Offset / 2, 0, (size.Y.Offset + shift + HEAD / 2) / 2)
		end
		local steady = sc.Scale
		local shelf
		local function place()
			if shelf then
				local w = panel.Size.X.Offset
				local extra = panel.Position.X.Offset + (w / 2 + 10) * own.Scale - holder.Size.X.Offset
				shelf.Position = UDim2.fromOffset(math.max(0, math.ceil(extra)), 0)
			end
		end
		local function apply()
			own.Scale = wanted() / math.max(steady, 0.05)
			place()
		end
		local function consider(c)
			if c:IsA("GuiObject") and c ~= panel and c ~= shelf and c.Position.X.Scale == 1
				and c.Size.X.Scale == 0 and c.Size.X.Offset > 0 then
				if not shelf then
					shelf = Instance.new("Frame")
					shelf.Name = "SkinOutside"
					shelf.BackgroundTransparency = 1
					shelf.Active = false
					shelf.Size = UDim2.fromScale(1, 1)
					shelf.ZIndex = panel.ZIndex + 2
					shelf.Parent = holder
				end
				c.Parent = shelf
				place()
			end
		end
		for _, c in holder:GetChildren() do
			consider(c)
		end
		holder.ChildAdded:Connect(function(c)
			task.defer(consider, c)
		end)
		local stamp = 0
		sc:GetPropertyChangedSignal("Scale"):Connect(function()
			stamp += 1
			local mine = stamp
			task.delay(0.4, function()
				if mine == stamp then
					steady = sc.Scale
					apply()
				end
			end)
		end)
		local cam = workspace.CurrentCamera
		if cam then
			cam:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
		end
		apply()
	else
		panel:SetAttribute("FitHeadRoom", HEAD / 2)
		panel:SetAttribute("FitTargetHeight", S.TargetHeight * (panel:GetAttribute("SkinSizeFactor") or 1))
	end
end

function S.watch(panel)
	if panel:GetAttribute("SkinWatched") then
		return
	end
	panel:SetAttribute("SkinWatched", true)
	task.wait(0.1)
	S.window(panel)
	local queued = false
	local function queue()
		if queued then
			return
		end
		queued = true
		task.defer(function()
			queued = false
			S.content(panel)
		end)
	end
	local root = (panel.Name == "Frame" and panel.Parent and panel.Parent:IsA("GuiObject")) and panel.Parent or panel
	root.DescendantAdded:Connect(queue)
	local o = panel
	while o and o:IsA("GuiObject") do
		o:GetPropertyChangedSignal("Visible"):Connect(queue)
		o = o.Parent
	end
	S.normalize(panel)
end

return S