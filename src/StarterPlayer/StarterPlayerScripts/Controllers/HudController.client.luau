local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local UIKit = require(game:GetService("ReplicatedStorage").Shared.UIKit)
local UK = UIKit.Palette

local K = {
	outline = UK.outline,
	text    = UIKit.WHITE,
	gold    = UK.bar,
	green   = UK.ready,
	blue    = UK.claimed,
	purple  = UK.prize,
	red     = UK.close,
	orange  = UK.inProgress,
	navy    = UK.bg,
}

local ICON = {
	crateGold = "rbxassetid://78249705152730",
	shop      = "rbxassetid://101996791620923",
	inventory = "rbxassetid://135534251950969",
	money     = "rbxassetid://105247853965760",
	studs     = "rbxassetid://138926013267839",
	rays      = "rbxassetid://75235337881072",
	glowSoft  = "rbxassetid://110083852572719",
	settings  = "rbxassetid://120353597392384",
	admin     = "rbxassetid://107453728750635",}

local GLOW_RAYS = Color3.fromRGB(255, 72, 72)
local GLOW_SOFT = Color3.fromRGB(255, 128, 118)

local screen = Instance.new("ScreenGui")
screen.Name = "GameHUD"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = PlayerGui

local function block(props)
	local holder = Instance.new("Frame")
	holder.Name = (props.name or "Block") .. "Holder"
	holder.BackgroundTransparency = 1
	holder.Size = props.size
	holder.Position = props.position or UDim2.new()
	holder.AnchorPoint = props.anchor or Vector2.new()
	holder.LayoutOrder = props.order or 0
	holder.ZIndex = props.zindex or 2
	holder.Parent = props.parent

	local radius = props.radius or 16
	local tone = props.tone or K.blue

	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.BackgroundColor3 = K.outline
	shadow.BorderSizePixel = 0
	shadow.Size = UDim2.fromScale(1, 1)
	shadow.Position = UDim2.fromOffset(0, props.shadowY or 5)
	shadow.ZIndex = holder.ZIndex
	shadow.Parent = holder
	Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, radius)

	local face = Instance.new(props.clickable and "TextButton" or "Frame")
	face.Name = props.name or "Face"
	face.BackgroundColor3 = tone.base
	face.BorderSizePixel = 0
	face.Size = UDim2.fromScale(1, 1)
	face.ZIndex = holder.ZIndex + 1
	if props.clickable then
		face.Text = ""
		face.AutoButtonColor = false
	end
	face.Parent = holder
	Instance.new("UICorner", face).CornerRadius = UDim.new(0, radius)

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = props.stroke or 3
	stroke.Color = K.outline
	stroke.Parent = face

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tone.hi),
		ColorSequenceKeypoint.new(0.55, tone.base),
		ColorSequenceKeypoint.new(1, tone.sh),
	})
	grad.Parent = face

	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.Size = UDim2.fromScale(1, 1)
	studs.Image = ICON.studs
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(props.stud or 13, props.stud or 13)
	studs.ImageTransparency = 0.86
	studs.ZIndex = face.ZIndex + 1
	studs.Parent = face
	Instance.new("UICorner", studs).CornerRadius = UDim.new(0, radius)

	return face, holder
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.Name = props.name or "Label"
	l.BackgroundTransparency = 1
	l.Size = props.size
	l.Position = props.position or UDim2.new()
	l.AnchorPoint = props.anchor or Vector2.new()
	l.Font = Enum.Font.FredokaOne
	l.Text = props.text or ""
	l.TextScaled = true
	l.TextColor3 = props.colour or K.text
	l.TextXAlignment = props.align or Enum.TextXAlignment.Center
	l.ZIndex = props.zindex or 12
	l.Parent = parent

	local s = Instance.new("UIStroke")
	s.Thickness = props.strokeW or 3
	s.Color = props.strokeColour or K.outline
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = l
	return l
end

local toastHolder, toastLabel
local function toast(message)
	if not toastLabel then
		local face, holder = block({
			parent = screen, name = "Toast", tone = K.navy, radius = 14,
			size = UDim2.fromOffset(430, 62),
			position = UDim2.new(0.5, 0, 0, 250), anchor = Vector2.new(0.5, 0), zindex = 40,
		})
		toastLabel = label(face, { name = "Text", size = UDim2.fromScale(1, 1), zindex = 43 })
		toastHolder = holder
		holder.Visible = false
	end
	toastLabel.Text = message
	toastHolder.Visible = true
	task.delay(2.4, function()
		if toastLabel.Text == message then
			toastHolder.Visible = false
		end
	end)
end

local CORNER_MARGIN = 18
local CORNER_BASE = 58

local refreshBoost

local function fitChrome()
	if refreshBoost then refreshBoost() end
end
fitChrome()

do
	local function track(cam)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitChrome) end
	end
	track(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		track(workspace.CurrentCamera)
		fitChrome()
	end)
	game:GetService("GuiService"):GetPropertyChangedSignal("TopbarInset"):Connect(fitChrome)
end

local lobbyHidden = false

local boostState = {}

local BOOST = {
	{ kind = "eggluck", image = "rbxassetid://86912083530579" },
	{ kind = "hatch",   image = "rbxassetid://124077178421900" },
	{ kind = "money",   image = "rbxassetid://80150641333749" },
	{ kind = "luck",    image = "rbxassetid://74489658413376" },
	{ kind = "speed",   image = "rbxassetid://129798509906580" },
 { kind = "treadmill", image = "rbxassetid://83769600890897" },
}

local SLOT_W, SLOT_H, ICON_SIDE, SLOT_GAP = 70, 76, 58, 2
local CARD_H = SLOT_H
local MULT_COLOUR = Color3.fromRGB(96, 255, 84)
local CLOCK_COLOUR = UIKit.WHITE
local ENDING_COLOUR = UK.close.hi
local BOOST_INK = Color3.fromRGB(12, 16, 24)

local boostRow = Instance.new("Frame")
boostRow.Name = "Boosts"
boostRow.BackgroundTransparency = 1
boostRow.AnchorPoint = Vector2.new(1, 1)
boostRow.Position = UDim2.new(1, -CORNER_MARGIN, 1, -(CORNER_MARGIN + CORNER_BASE + 10))
boostRow.AutomaticSize = Enum.AutomaticSize.X
boostRow.Size = UDim2.fromOffset(0, SLOT_H)
boostRow.ZIndex = 12
boostRow.Visible = false
boostRow.Parent = screen

local boostScale = Instance.new("UIScale")
boostScale.Parent = boostRow

do
	local row = Instance.new("UIListLayout")
	row.FillDirection = Enum.FillDirection.Horizontal
	row.HorizontalAlignment = Enum.HorizontalAlignment.Right
	row.VerticalAlignment = Enum.VerticalAlignment.Center
	row.SortOrder = Enum.SortOrder.LayoutOrder
	row.Padding = UDim.new(0, SLOT_GAP)
	row.Parent = boostRow
end

local function boostText(parent, props)
	local t = Instance.new("TextLabel")
	t.Name = props.name
	t.BackgroundTransparency = 1
	t.Size = props.size
	t.Position = props.position
	t.AnchorPoint = props.anchor or Vector2.new()
	t.Font = Enum.Font.FredokaOne
	t.TextSize = props.textSize
	t.TextColor3 = props.colour
	t.TextXAlignment = props.align or Enum.TextXAlignment.Center
	t.Text = ""
	t.ZIndex = 16
	t.Parent = parent
	local s = Instance.new("UIStroke")
	s.Color = BOOST_INK
	s.Thickness = props.strokeW or 3
	s.LineJoinMode = Enum.LineJoinMode.Round
	s.Parent = t
	return t
end

local function boostLeft(s)
	s = math.max(0, math.floor(s))
	if s >= 3600 then return ("%dh %02dm"):format(s // 3600, (s % 3600) // 60) end
	if s >= 60 then return ("%dm %02ds"):format(s // 60, s % 60) end
	return s .. "s"
end

local boostCards = {}

for order, def in ipairs(BOOST) do
	local holder = Instance.new("Frame")
	holder.Name = def.kind
	holder.BackgroundTransparency = 1
	holder.Size = UDim2.fromOffset(SLOT_W, SLOT_H)
	holder.LayoutOrder = order
	holder.ZIndex = 12
	holder.Visible = false
	holder.Parent = boostRow

	local scale = Instance.new("UIScale")
	scale.Parent = holder

	local art = Instance.new("ImageLabel")
	art.Name = "Art"
	art.BackgroundTransparency = 1
	art.Image = def.image
	art.ScaleType = Enum.ScaleType.Fit
	art.AnchorPoint = Vector2.new(0.5, 0)
	art.Position = UDim2.new(0.5, 0, 0, 4)
	art.Size = UDim2.fromOffset(ICON_SIDE, ICON_SIDE)
	art.ZIndex = 14
	art.Parent = holder

	local mult = boostText(holder, {
		name = "Mult", size = UDim2.fromOffset(44, 24),
		position = UDim2.new(1, 4, 0, -2), anchor = Vector2.new(1, 0),
		textSize = 21, colour = MULT_COLOUR, align = Enum.TextXAlignment.Right,
	})

	local clock = boostText(holder, {
		name = "Clock", size = UDim2.new(1, 6, 0, 22),
		position = UDim2.new(0.5, 0, 0, ICON_SIDE - 12), anchor = Vector2.new(0.5, 0),
		textSize = 17, colour = CLOCK_COLOUR,
	})

	boostCards[def.kind] = { def = def, holder = holder, scale = scale, mult = mult, clock = clock }
end

function refreshBoost()
	local now = workspace:GetServerTimeNow()
	local shown = 0

	for _, def in ipairs(BOOST) do
		local card = boostCards[def.kind]
		local entry = boostState[def.kind]

		local live = entry ~= nil and entry.mult > 1
			and (entry.endsAt == 0 or entry.endsAt > now)
			and not lobbyHidden

		if live then
			shown += 1
			card.mult.Text = ("x%g"):format(entry.mult)
			if entry.endsAt > 0 then
				local left = entry.endsAt - now
				card.clock.Text = boostLeft(left)
				card.clock.TextColor3 = (left <= 30) and ENDING_COLOUR or CLOCK_COLOUR
			else
				card.clock.Text = ""
			end

			if not card.holder.Visible then
				card.holder.Visible = true
				card.scale.Scale = 0.6
				TweenService:Create(card.scale,
					TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Scale = 1 }):Play()
			end
		else
			card.holder.Visible = false
		end
	end

	boostRow.Visible = shown > 0
	if shown == 0 then return end

	local rightInset = CORNER_MARGIN
	local bottomInset = CORNER_MARGIN + CORNER_BASE + 10
	boostRow.Position = UDim2.new(1, -rightInset, 1, -bottomInset)

	local natural = shown * SLOT_W + (shown - 1) * SLOT_GAP
	local cam = workspace.CurrentCamera
	local fit = 1
	if cam then
		fit = cam.ViewportSize.X * 0.86 / natural

		local emotes = PlayerGui:FindFirstChild("EmoteHud")
		local face = emotes and emotes:FindFirstChild("EmoteButton")
		if face and face.AbsoluteSize.Y > 0 then
			local canvas = cam.ViewportSize.Y - game:GetService("GuiService"):GetGuiInset().Y
			local ceiling = face.AbsolutePosition.Y + face.AbsoluteSize.Y + 14
			fit = math.min(fit, (canvas - bottomInset - ceiling - 8) / CARD_H)
		end
	end
	boostScale.Scale = math.clamp(fit, 0.5, 1)
end

do
	local function watch(cam)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(refreshBoost) end
	end
	watch(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watch(workspace.CurrentCamera)
		refreshBoost()
	end)
end

task.spawn(function()
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 20)
	local remote = remotes and remotes:WaitForChild("GlobalBoost", 10)
	if not remote then return end

	remote.OnClientEvent:Connect(function(state)
		if type(state) ~= "table" then return end
		boostState = {}
		for kind, entry in pairs(state) do
			if type(entry) == "table" then
				local endsAt = tonumber(entry.endsAt) or 0
				local startedAt = tonumber(entry.startedAt) or 0
				boostState[kind] = {
					mult = tonumber(entry.mult) or 1,
					endsAt = endsAt,

					span = (endsAt > 0 and startedAt > 0)
						and math.max(endsAt - startedAt, 1) or 0,
				}
			end
		end
		refreshBoost()
	end)

	while true do
		task.wait(1)
		if next(boostState) then refreshBoost() end
	end
end)

local BUILT = {
	FreeRewards = true,
	Settings = true, Admin = true,
	EggBag = true,
}

local function openPanel(id, label)

	local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
	local bus = remotes and remotes:FindFirstChild("OpenPanel")
	if bus and BUILT[id] then
		bus:Fire(id)
	else
		toast((label or id) .. " - coming soon")
	end
end

local adminHolder
local bagHolder
local settingsHolder

fitChrome()

PlayerGui.ChildAdded:Connect(function(child)
	if child.Name == "TouchGui" then
		task.defer(fitChrome)
	end
end)

local adminAuthorized = false
local function refreshCorner()
	if adminHolder then
		adminHolder.Visible = adminAuthorized and not lobbyHidden
	end
	if bagHolder then
		bagHolder.Visible = not lobbyHidden
	end
	if settingsHolder then
		settingsHolder.Visible = not lobbyHidden
	end
end

task.spawn(function()
	local adminGui = PlayerGui:WaitForChild("AdminPanel", 30)
	if not adminGui then return end
	local function refresh()
		adminAuthorized = (adminGui:GetAttribute("Authorized") == true)
		refreshCorner()
	end
	adminGui:GetAttributeChangedSignal("Authorized"):Connect(refresh)
	refresh()
end)

local GuiService = game:GetService("GuiService")

local TOPBAR_TOP = 12
local TOPBAR_BUTTON_H = 46
local TOPBAR_GAP = 7
local TOPBAR_EDGE = 8
local topbarPills = {}

local topbarScreen = Instance.new("ScreenGui")
topbarScreen.Name = "GameTopbar"
topbarScreen.ResetOnSpawn = false
topbarScreen.IgnoreGuiInset = true
topbarScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
topbarScreen.DisplayOrder = 6
topbarScreen.Parent = PlayerGui

local topbar = Instance.new("Frame")
topbar.Name = "Topbar"
topbar.BackgroundTransparency = 1
topbar.ZIndex = 18
topbar.Parent = topbarScreen

_G.SetLobbyChromeHidden = function(hidden)
	lobbyHidden = hidden == true

	topbarScreen.Enabled = not lobbyHidden
	refreshCorner()
	refreshBoost()
	if lobbyHidden and _G.ClosePanels then
		_G.ClosePanels()
	end
end

local function topbarHeight()
	return TOPBAR_BUTTON_H
end

local function fitTopbar()
	local rect = GuiService.TopbarInset
	if rect and rect.Height > 0 then
		topbar.Position = UDim2.fromOffset(rect.Min.X, rect.Min.Y)

		topbar.Size = UDim2.fromOffset(rect.Width, rect.Height + 40)
	else
		local inset = GuiService:GetGuiInset().Y
		topbar.Position = UDim2.fromOffset(0, 0)
		topbar.Size = UDim2.new(1, 0, 0, inset > 0 and inset or 36)
	end

	local height = topbarHeight()
	for _, row in ipairs(topbar:GetChildren()) do
		if row:IsA("Frame") then
			row.Position = UDim2.new(row.Position.X.Scale, 0, 0, TOPBAR_TOP)
			row.Size = UDim2.new(0.5, 0, 0, height)
		end
	end
end
fitTopbar()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(fitTopbar)

do
	local function watch(cam)
		if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fitTopbar) end
	end
	watch(workspace.CurrentCamera)
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		watch(workspace.CurrentCamera)
		fitTopbar()
	end)
end

local BAR = {
	body    = Color3.fromHex("063B4C"),
	top     = Color3.fromHex("084B5F"),
	bottom  = Color3.fromHex("063545"),
	outline = Color3.fromHex("0B1C2A"),

	hover       = Color3.fromHex("0C6C88"),
	hoverTop    = Color3.fromHex("0F86A6"),
	hoverBottom = Color3.fromHex("095B73"),
	press       = Color3.fromHex("042835"),
	pressBottom = Color3.fromHex("031E28"),
}
local BAR_ICON = 24
local BAR_PAD = 14
local BAR_INNER_GAP = 9

local function sideRow(name, alignment)
	local row = Instance.new("Frame")
	row.Name = name
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(0.5, 0, 0, TOPBAR_BUTTON_H)
	row.Position = (alignment == Enum.HorizontalAlignment.Right)
		and UDim2.new(0.5, 0, 0, TOPBAR_TOP) or UDim2.new(0, 0, 0, TOPBAR_TOP)
	row.ZIndex = 18
	row.Parent = topbar

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = alignment
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, TOPBAR_GAP)
	layout.Parent = row

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, TOPBAR_EDGE)
	pad.PaddingRight = UDim.new(0, TOPBAR_EDGE)
	pad.Parent = row
	return row
end

local leftRow = sideRow("Left", Enum.HorizontalAlignment.Left)
local rightRow = sideRow("Right", Enum.HorizontalAlignment.Right)

local function pill(def, row, order)
	local face = Instance.new("TextButton")
	face.Name = def.id
	face.AutoButtonColor = false
	face.Text = ""
	face.BackgroundColor3 = BAR.body

	face.BackgroundTransparency = 0.18
	face.BorderSizePixel = 0

	face.AutomaticSize = Enum.AutomaticSize.X
	face.Size = UDim2.new(0, 0, 1, 0)
	face.LayoutOrder = order
	face.ZIndex = 19
	face.Parent = row

	Instance.new("UICorner", face).CornerRadius = UDim.new(1, 0)
	topbarPills[#topbarPills + 1] = face

	local grad = Instance.new("UIGradient")
	grad.Rotation = 90
	grad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, BAR.top),
		ColorSequenceKeypoint.new(1, BAR.bottom),
	})
	grad.Parent = face

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Transparency = 0.35
	stroke.Color = BAR.outline
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = face

	local inner = Instance.new("UIListLayout")
	inner.FillDirection = Enum.FillDirection.Horizontal
	inner.HorizontalAlignment = Enum.HorizontalAlignment.Center
	inner.VerticalAlignment = Enum.VerticalAlignment.Center
	inner.SortOrder = Enum.SortOrder.LayoutOrder
	inner.Padding = UDim.new(0, BAR_INNER_GAP)
	inner.Parent = face

	local innerPad = Instance.new("UIPadding")
	innerPad.PaddingLeft = UDim.new(0, BAR_PAD)
	innerPad.PaddingRight = UDim.new(0, BAR_PAD)
	innerPad.Parent = face

	local badge = Instance.new("ImageLabel")
	badge.Name = "Icon"
	badge.BackgroundTransparency = 1
	badge.Image = def.image
	badge.ScaleType = Enum.ScaleType.Fit
	badge.Size = UDim2.fromOffset(BAR_ICON, BAR_ICON)
	badge.LayoutOrder = 1
	badge.ZIndex = 21
	badge.Parent = face

	local text = Instance.new("TextLabel")
	text.Name = "Label"
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBold
	text.Text = def.label
	text.TextColor3 = Color3.fromRGB(255, 255, 255)
	text.AutomaticSize = Enum.AutomaticSize.X
	text.Size = UDim2.fromOffset(0, BAR_ICON)
	text.LayoutOrder = 2
	text.ZIndex = 21
	text.Parent = face
	text.TextScaled = false
	text.TextSize = 17

	local QUICK = TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	local function tint(body, top, bottom, clarity)
		TweenService:Create(face, QUICK,
			{ BackgroundColor3 = body, BackgroundTransparency = clarity or 0.18 }):Play()
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, top),
			ColorSequenceKeypoint.new(1, bottom),
		})
	end
	face.MouseEnter:Connect(function() tint(BAR.hover, BAR.hoverTop, BAR.hoverBottom, 0.04) end)
	face.MouseLeave:Connect(function() tint(BAR.body, BAR.top, BAR.bottom, 0.18) end)
	face.MouseButton1Down:Connect(function() tint(BAR.press, BAR.press, BAR.pressBottom, 0.04) end)
	face.MouseButton1Up:Connect(function() tint(BAR.hover, BAR.hoverTop, BAR.hoverBottom, 0.04) end)
	face.MouseButton1Click:Connect(function()
		openPanel(def.id, def.label)
	end)

	return face
end

do

	settingsHolder = pill({ id = "Settings", label = "", image = ICON.settings },
		leftRow, 1)
	local setLabel = settingsHolder:FindFirstChild("Label")
	if setLabel then setLabel:Destroy() end

	bagHolder = pill({ id = "EggBag", label = "", image = "rbxassetid://110629665052805" },
		leftRow, 2)
	local bagLabel = bagHolder:FindFirstChild("Label")
	if bagLabel then bagLabel:Destroy() end

	adminHolder = pill({ id = "Admin", label = "", image = ICON.admin }, rightRow, 1)
	local adminLabel = adminHolder:FindFirstChild("Label")
	if adminLabel then adminLabel:Destroy() end
	adminHolder.Visible = false
	refreshCorner()
end

local TextService = game:GetService("TextService")

local annGui = Instance.new("ScreenGui")
annGui.Name = "AnnouncementLine"
annGui.ResetOnSpawn = false
annGui.IgnoreGuiInset = true
annGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
annGui.DisplayOrder = 60
annGui.Parent = PlayerGui

local ANN_FONT = Enum.Font.FredokaOne
local ANN_TEXT = 36
local ANN_HEAD = 64
local ANN_GAP = 14
local ANN_MAX_W = 980
local ANN_NICK_HEX = "#56B2FF"
local ANN_EDGE = Color3.fromRGB(14, 16, 26)

local annRow = Instance.new("Frame")
annRow.Name = "Announcement"
annRow.BackgroundTransparency = 1
annRow.AnchorPoint = Vector2.new(0.5, 0.5)
annRow.Position = UDim2.fromScale(0.5, 0.24)
annRow.Size = UDim2.fromOffset(400, ANN_HEAD)
annRow.Visible = false
annRow.Parent = annGui

local annScale = Instance.new("UIScale")
annScale.Parent = annRow

local annAvatar = Instance.new("ImageLabel")
annAvatar.Name = "Avatar"
annAvatar.BackgroundColor3 = Color3.fromRGB(46, 52, 72)
annAvatar.BorderSizePixel = 0
annAvatar.AnchorPoint = Vector2.new(0, 0.5)
annAvatar.Position = UDim2.new(0, 0, 0.5, 0)
annAvatar.Size = UDim2.fromOffset(ANN_HEAD, ANN_HEAD)
annAvatar.Parent = annRow
Instance.new("UICorner", annAvatar).CornerRadius = UDim.new(0.5, 0)
local annRing = Instance.new("UIStroke")
annRing.Color = Color3.new(1, 1, 1)
annRing.Thickness = 3
annRing.Parent = annAvatar

local annText = Instance.new("TextLabel")
annText.Name = "Text"
annText.BackgroundTransparency = 1
annText.AnchorPoint = Vector2.new(0, 0.5)
annText.Position = UDim2.new(0, ANN_HEAD + ANN_GAP, 0.5, 0)
annText.Font = ANN_FONT
annText.TextSize = ANN_TEXT
annText.TextColor3 = Color3.new(1, 1, 1)
annText.TextXAlignment = Enum.TextXAlignment.Left
annText.TextWrapped = true
annText.RichText = true
annText.Text = ""
annText.Parent = annRow
local annEdge = Instance.new("UIStroke")
annEdge.Color = ANN_EDGE
annEdge.Thickness = 3.5
annEdge.LineJoinMode = Enum.LineJoinMode.Round
annEdge.Parent = annText

local function annEscape(s)
	return (tostring(s):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function annFade(alpha)
	annText.TextTransparency = alpha
	annEdge.Transparency = alpha
	annAvatar.ImageTransparency = alpha
	annAvatar.BackgroundTransparency = alpha
	annRing.Transparency = alpha
end

local annCounter = 0
local function showAnnouncement(data)
	local body = type(data) == "table" and tostring(data.text or "") or tostring(data or "")
	if body == "" then return end
	local nick = tostring((type(data) == "table" and data.fromName) or "ADMIN")

	annText.Text = ('<font color="%s">%s</font>: %s'):format(ANN_NICK_HEX, annEscape(nick), annEscape(body))

	local bounds = TextService:GetTextSize(nick .. ": " .. body, ANN_TEXT, ANN_FONT, Vector2.new(ANN_MAX_W, 4000))
	local w = math.ceil(bounds.X) + 10
	local h = math.ceil(bounds.Y) + 6
	annText.Size = UDim2.fromOffset(w, h)
	local rowW = ANN_HEAD + ANN_GAP + w
	annRow.Size = UDim2.fromOffset(rowW, math.max(h, ANN_HEAD))

	local fit = 1
	local cam = workspace.CurrentCamera
	if cam and cam.ViewportSize.X > 0 then
		fit = math.min(1, cam.ViewportSize.X * 0.92 / rowW)
	end

	local userId = type(data) == "table" and tonumber(data.fromUserId) or nil
	annAvatar.Image = ""
	if userId and userId > 0 then
		task.spawn(function()
			local ok, url = pcall(function()
				return Players:GetUserThumbnailAsync(userId,
					Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			end)
			if ok then annAvatar.Image = url end
		end)
	end

	annFade(0)
	annRow.Visible = true
	annScale.Scale = fit * 0.8
	TweenService:Create(annScale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Scale = fit }):Play()

	annCounter += 1
	local mine = annCounter
	task.delay(7, function()
		if annCounter ~= mine then return end
		local t0 = os.clock()
		while os.clock() - t0 < 0.45 do
			if annCounter ~= mine then return end
			annFade((os.clock() - t0) / 0.45)
			RunService.Heartbeat:Wait()
		end
		if annCounter == mine then annRow.Visible = false end
	end)
end

task.spawn(function()
	local remotes = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 20)
	local adminRemote = remotes and remotes:WaitForChild("Admin", 20)
	if not adminRemote then return end
	adminRemote.OnClientEvent:Connect(function(kind, data)
		if kind == "announce" then showAnnouncement(data) end
	end)
end)