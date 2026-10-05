local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Cfg = require(RS:WaitForChild("CaptureEggConfig"))
local remote = RS:WaitForChild("Remotes"):WaitForChild("CaptureEgg")
local player = Players.LocalPlayer

local FONT = Enum.Font.FredokaOne
local INK = Color3.fromRGB(28, 16, 8)
local GOLD = Color3.fromRGB(255, 214, 64)
local RINGS = {
	Color3.fromRGB(255, 200, 40),
	Color3.fromRGB(206, 214, 226),
	Color3.fromRGB(214, 132, 70),
}
local YOU_RING = Color3.fromRGB(80, 190, 255)

local gui = Instance.new("ScreenGui")
gui.Name = "CaptureEggHud"
gui.ResetOnSpawn = false
gui.DisplayOrder = 6
gui.Enabled = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Name = "Root"
root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.new(0.5, 0, 0, 4)
root.Size = UDim2.fromOffset(460, 176)
root.BackgroundTransparency = 1
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local function stroke(parent, thickness)
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = INK
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
	s.Parent = parent
	return s
end

local function text(parent, name, props)
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.TextColor3 = props.colour or Color3.new(1, 1, 1)
	t.TextSize = props.size or 18
	t.Text = props.text or ""
	t.Size = props.box or UDim2.new(1, 0, 0, props.size or 18)
	t.Position = props.position or UDim2.new()
	t.AnchorPoint = props.anchor or Vector2.new()
	t.ZIndex = props.z or 2
	t.Parent = parent
	stroke(t, props.stroke or 2.5)
	return t
end

local title = text(root, "Title", { text = Cfg.Title, size = 40, colour = GOLD, stroke = 3.5, box = UDim2.new(1, 0, 0, 42) })
local shine = Instance.new("UIGradient")
shine.Rotation = 90
shine.Color = ColorSequence.new(Color3.fromRGB(255, 244, 150), Color3.fromRGB(255, 176, 30))
shine.Parent = title
local subtitle = text(root, "Subtitle", { text = Cfg.Subtitle, size = 18, position = UDim2.fromOffset(0, 40), box = UDim2.new(1, 0, 0, 20) })

local row = Instance.new("Frame")
row.Name = "Top"
row.BackgroundTransparency = 1
row.Position = UDim2.fromOffset(0, 68)
row.Size = UDim2.new(1, 0, 0, 104)
row.Parent = root
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 16)
layout.Parent = row

local headshots = {}
local function headshot(userId, image)
	if headshots[userId] then image.Image = headshots[userId] return end
	image.Image = ""
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
		end)
		if ok and url then
			headshots[userId] = url
			if image:GetAttribute("UserId") == userId then image.Image = url end
		end
	end)
end

local function makeSlot(order, ring, badge)
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. order
	slot.LayoutOrder = order
	slot.BackgroundTransparency = 1
	slot.Size = UDim2.fromOffset(78, 104)
	slot.Visible = false
	slot.Parent = row
	local circle = Instance.new("ImageLabel")
	circle.Name = "Avatar"
	circle.AnchorPoint = Vector2.new(0.5, 0)
	circle.Position = UDim2.new(0.5, 0, 0, 4)
	circle.Size = UDim2.fromOffset(66, 66)
	circle.BackgroundColor3 = Color3.fromRGB(62, 48, 92)
	circle.ScaleType = Enum.ScaleType.Crop
	circle.Parent = slot
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle
	local ringStroke = Instance.new("UIStroke")
	ringStroke.Thickness = 4
	ringStroke.Color = ring
	ringStroke.Parent = circle
	local tag = Instance.new("Frame")
	tag.Name = "Badge"
	tag.AnchorPoint = Vector2.new(0.5, 0.5)
	tag.Position = UDim2.new(0.5, badge == "YOU!" and 0 or -26, 0, badge == "YOU!" and 68 or 10)
	tag.Size = badge == "YOU!" and UDim2.fromOffset(52, 22) or UDim2.fromOffset(26, 26)
	tag.BackgroundColor3 = ring
	tag.ZIndex = 3
	tag.Parent = slot
	local tc = Instance.new("UICorner")
	tc.CornerRadius = UDim.new(1, 0)
	tc.Parent = tag
	local ts = Instance.new("UIStroke")
	ts.Thickness = 2.5
	ts.Color = INK
	ts.Parent = tag
	text(tag, "Text", { text = badge, size = 17, box = UDim2.fromScale(1, 1), z = 4, stroke = 2 })
	local time = text(slot, "Time", { text = "0s", size = 22, position = UDim2.fromOffset(0, 78), box = UDim2.new(1, 0, 0, 24) })
	return { frame = slot, image = circle, time = time }
end

local slots = {}
for i = 1, 3 do slots[i] = makeSlot(i, RINGS[i], tostring(i)) end
local youSlot = makeSlot(4, YOU_RING, "YOU!")

local function clock(secs)
	secs = math.floor(secs)
	if secs >= 60 then return ("%d:%02d"):format(secs // 60, secs % 60) end
	return secs .. "s"
end

local function fill(slot, entry)
	slot.frame.Visible = true
	if slot.image:GetAttribute("UserId") ~= entry.u then
		slot.image:SetAttribute("UserId", entry.u)
		headshot(entry.u, slot.image)
	end
	slot.time.Text = clock(entry.s)
end

local holderId = 0
local function render(data)
	local list = data.list or {}
	local mine
	for i, entry in ipairs(list) do
		if entry.u == player.UserId then mine = i end
	end
	for i = 1, 3 do
		if list[i] then fill(slots[i], list[i]) else slots[i].frame.Visible = false end
	end
	if mine and mine <= 3 then
		youSlot.frame.Visible = false
	else
		fill(youSlot, mine and list[mine] or { u = player.UserId, s = 0 })
	end
	holderId = tonumber(data.holder) or 0

	for i = 1, 3 do
		local held = list[i] and list[i].u == holderId
		slots[i].time.TextColor3 = held and GOLD or Color3.new(1, 1, 1)
	end
	youSlot.time.TextColor3 = (holderId == player.UserId and youSlot.frame.Visible) and GOLD or Color3.new(1, 1, 1)
end

local resultsToken = 0
local showingResults = false
local function showResults(data)
	local winners = data.winners or {}
	title.Text = "EVENT OVER!"
	subtitle.Text = winners[1] and (string.upper(winners[1].n) .. " WON!") or "NOBODY HELD THE EGG"
	for i = 1, 3 do
		if winners[i] then fill(slots[i], winners[i]) else slots[i].frame.Visible = false end
		slots[i].time.TextColor3 = Color3.new(1, 1, 1)
	end
	youSlot.frame.Visible = false
	resultsToken += 1
	local mine = resultsToken
	showingResults = true
	gui.Enabled = true
	root.Visible = true
	local size = scale.Scale
	scale.Scale = size * 0.6
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = size }):Play()
	task.delay(8, function()
		if resultsToken ~= mine or not showingResults then return end
		showingResults = false
		root.Visible = false
		gui.Enabled = false
	end)
end

local function fit()
	local cam = workspace.CurrentCamera
	local size = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local s = math.clamp(math.min(size.X / 1100, size.Y / 640), 0.55, 1)
	scale.Scale = s
end
fit()
local function watchCamera()
	local cam = workspace.CurrentCamera
	if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
	fit()
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)
watchCamera()

remote.OnClientEvent:Connect(function(kind, data)
	if type(data) ~= "table" then return end
	if kind == "state" then
		if data.active then
			showingResults = false
			title.Text = Cfg.Title
			subtitle.Text = Cfg.Subtitle
			root.Visible = true
			gui.Enabled = true
			render(data)
		elseif not showingResults then
			root.Visible = false
			gui.Enabled = false
		end
	elseif kind == "results" then
		showResults(data)
	end
end)

task.spawn(function()
	local hud = player.PlayerGui:WaitForChild("EggHud", 30)
	if not hud then return end
	local plates = {
		{ frame = hud:WaitForChild("BiomeBanner", 10), top = 0.07 },
		{ frame = hud:WaitForChild("RunBanner", 10), top = 0.05 },
	}
	local function dodge()
		local inset = GuiService:GetGuiInset().Y
		local y = 4
		for _, p in ipairs(plates) do
			if p.frame and p.frame.Visible then
				y = math.max(y, hud.AbsoluteSize.Y * p.top + p.frame.AbsoluteSize.Y + 12 - inset)
			end
		end
		TweenService:Create(root, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { Position = UDim2.new(0.5, 0, 0, y) }):Play()
	end
	for _, p in ipairs(plates) do
		if p.frame then p.frame:GetPropertyChangedSignal("Visible"):Connect(dodge) end
	end
	dodge()
end)

remote:FireServer("sync")