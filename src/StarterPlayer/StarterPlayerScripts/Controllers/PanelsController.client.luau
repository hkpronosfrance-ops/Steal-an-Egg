local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Sfx = require(ReplicatedStorage.Shared.Sfx)
local Config = require(ReplicatedStorage.Shared.Config)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local K = UIKit.Palette

local ICON = {

	robuxGreen = "rbxassetid://98657106137213",
	robuxWhite = "rbxassetid://102382554203100",

	rays   = "rbxassetid://75235337881072",
	glow   = "rbxassetid://110083852572719",

	gift      = "rbxassetid://112514590166782",
	arrowDown = "rbxassetid://83205092246605",}

local screen = Instance.new("ScreenGui")
screen.Name = "GamePanels"
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 5
screen.Parent = PlayerGui

local corner = UIKit.corner
local tint = UIKit.tint

local function block(props)
	local face = UIKit.block(props)
	if props.clickable and props.react ~= false then
		UIKit.reactToCursor(face)
	end
	return face
end

local reactToCursor = UIKit.reactToCursor
local tintOnHover = UIKit.tintOnHover
local headHeight = UIKit.headHeight

local function crossMark(parent, span, thick, colour, zindex)
	UIKit.cross(parent, parent.Size.X.Offset, colour)
end

local PANEL_INK = Color3.fromRGB(43, 23, 64)
local PANEL_MARK = Color3.fromRGB(255, 240, 224)

local repaintBlock = UIKit.repaint

local function boldLabel(parent, props)
	props.parent = parent
	return UIKit.boldLabel(props)
end

local function art(parent, props)
	local i = Instance.new("ImageLabel")
	i.Name = props.name or "Icon"
	i.BackgroundTransparency = 1
	i.Image = props.image
	i.Size = props.size
	i.Position = props.position or UDim2.new()
	i.AnchorPoint = props.anchor or Vector2.new()

	i.ScaleType = props.scale or Enum.ScaleType.Fit
	i.ZIndex = props.zindex or 20
	i.Parent = parent
	if props.tint then
		i.ImageColor3 = props.tint
	end
	if props.transparency then
		i.ImageTransparency = props.transparency
	end
	return i
end

local panels = {}
local bodies = {}
local scales = {}
local fits = {}

local function makePanel(id, title, width, height, iconImage, plainBody, iconAspect)
	local shell = Instance.new("Frame")
	shell.Name = id
	shell.AnchorPoint = Vector2.new(0.5, 0.5)
	shell.Position = UDim2.fromScale(0.5, 0.5)
	shell.Size = UDim2.fromOffset(width, height)
	shell.BackgroundTransparency = 1
	shell.Visible = false
	shell.ZIndex = 10
	shell.Parent = screen

	local scale = Instance.new("UIScale")
	scale.Parent = shell
	scales[id] = scale
	fits[id] = UIKit.fitWindow(shell, scale)

	local frame = block({
		parent = shell, name = "Frame", tone = K.panel, size = UDim2.fromOffset(width, height),
		radius = 15, outline = 3, shadowY = 8, bevel = false, stud = 15, studAlpha = 0.55, zindex = 10,
	})
	frame.BackgroundTransparency = 0.82
	frame.ClipsDescendants = false

	local headH = headHeight(width)

	local header = block({
		parent = frame, name = "Header", tone = K.bar,
		size = UDim2.new(1, 0, 0, headH), position = UDim2.new(),
		radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 14,
	})

	if iconImage then

		local ratio = tonumber(iconAspect) or 1
		local iconH = headH - (ratio > 1.2 and 4 or 14)
		local iconW = math.floor(iconH * ratio + 0.5)
		local iconY = math.floor((headH - iconH) / 2)
		art(header, {
			name = "IconShadow", image = iconImage,
			size = UDim2.fromOffset(iconW, iconH),
			position = UDim2.fromOffset(12, iconY + 4), zindex = 20,
			tint = Color3.new(0, 0, 0), transparency = 0.55,
		})
		art(header, {
			name = "Icon", image = iconImage,
			size = UDim2.fromOffset(iconW, iconH),
			position = UDim2.fromOffset(12, iconY), zindex = 21,
		})
	end

	boldLabel(header, {
		name = "Title", size = UDim2.fromScale(1, 1),
		text = title, strokeW = 4, strokeColour = PANEL_INK, zindex = 22,
		textSize = math.floor(headH * 0.68),
	})

	local shut = headH - 24
	local close = block({
		parent = header, name = "Close", tone = K.close, clickable = true, react = false,
		size = UDim2.fromOffset(shut, shut),
		position = UDim2.new(1, -(shut + 14), 0.5, 0), anchor = Vector2.new(0, 0.5),
		radius = math.floor(headH * 0.16), outline = 2, stud = 9, studAlpha = 0.70, shadowY = 4, zindex = 22,
	})
	tintOnHover(close, K.close)
	crossMark(close, math.floor(shut * 0.55), 6, PANEL_MARK, 30)
	close.MouseButton1Click:Connect(function()
		shell.Visible = false
	end)

	local body
	if plainBody then
		body = Instance.new("Frame")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.BorderSizePixel = 0
		body.Position = UDim2.fromOffset(0, 0)
		body.Size = UDim2.fromScale(1, 1)
		body.ClipsDescendants = false
		body.ZIndex = 12
		body.Parent = frame
	else
		body = Instance.new("ScrollingFrame")
		body.Name = "Body"
		body.BackgroundTransparency = 1
		body.BorderSizePixel = 0
		body.Position = UDim2.fromOffset(16, headH + 12)
		body.Size = UDim2.new(1, -32, 1, -(headH + 28))
		body.CanvasSize = UDim2.new()
		body.AutomaticCanvasSize = Enum.AutomaticSize.Y
		body.ScrollBarThickness = 8
		body.ScrollBarImageColor3 = K.slab.hi
		body.ZIndex = 14
		body.Parent = frame

		local list = Instance.new("UIListLayout")
		list.Padding = UDim.new(0, 14)
		list.SortOrder = Enum.SortOrder.LayoutOrder
		list.HorizontalAlignment = Enum.HorizontalAlignment.Center
		list.Parent = body

		local pad = Instance.new("UIPadding")
		pad.PaddingLeft = UDim.new(0, 8)
		pad.PaddingRight = UDim.new(0, 8)
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 14)
		pad.Parent = body
	end

	local holdsBlur = false
	shell:GetPropertyChangedSignal("Visible"):Connect(function()
		if shell.Visible ~= holdsBlur then
			holdsBlur = shell.Visible
			UIKit.blurHold(holdsBlur)
		end
	end)

	panels[id] = shell
	bodies[id] = body
	return shell, body, width - 64
end

local FLAT_TEXT = 3
local FLAT_BTN_R = 12
local FLAT_INK = Color3.fromRGB(43, 23, 64)
local FLAT_EDGE = Color3.fromRGB(0, 0, 0)

local FREE_W, FREE_H = 600, 600
local freeShell, freeBody = makePanel("FreeRewards", "FREE REWARDS", FREE_W, FREE_H, ICON.gift, true)
local BODY_W = FREE_W

do
	local freeRemote = ReplicatedStorage.Remotes:WaitForChild("FreeReward")

	local joined, verifiable, claimed = false, false, false

	local TASK_W, TASK_H = 500, 62
	local TASK_X = math.floor((BODY_W - TASK_W) / 2)

	local GROUP_ID = tonumber(Config.FreeReward and Config.FreeReward.GroupId) or 0

	local function openGroupPage()
		if GROUP_ID <= 0 then
			warn("[FreeReward] Config.FreeReward.GroupId = 0, set the group id in ReplicatedStorage.Shared.Config, otherwise there is nothing to open and nothing to verify")
			return
		end
		pcall(function() game:GetService("GroupService"):PromptJoinAsync(GROUP_ID) end)

		task.delay(3, function()
			freeRemote:FireServer("get")
		end)
	end

	local function taskButton(name, y, text, onClick)
		local tile = block({
			parent = freeBody, name = name, tone = K.claimed, clickable = onClick ~= nil,
			size = UDim2.fromOffset(TASK_W, TASK_H), position = UDim2.fromOffset(TASK_X, y),
			radius = FLAT_BTN_R, outline = 2, edge = FLAT_EDGE, stud = 12, studAlpha = 0.45, shadowY = 4, zindex = 16,
		})
		local label = boldLabel(tile, {
			name = "Label", size = UDim2.fromScale(1, 1), position = UDim2.fromOffset(0, 0),
			text = text, strokeW = FLAT_TEXT, strokeColour = FLAT_INK, zindex = 26, textSize = 34,
		})
		if onClick then
			tile.MouseButton1Click:Connect(onClick)
		end
		return tile, label
	end

	local likeTile, likeLabel = taskButton("TaskLike", 127, "Like the Game!")
	local groupTile, groupLabel = taskButton("TaskGroup", 205, "Join Our Group!", openGroupPage)

	art(freeBody, {
		name = "Arrow", image = ICON.arrowDown,
		size = UDim2.fromOffset(72, 72),
		position = UDim2.new(0.5, 0, 0, 300), anchor = Vector2.new(0.5, 0),
		zindex = 20,
	})

	local prizeRow = Instance.new("Frame")
	prizeRow.Name = "Prize"
	prizeRow.BackgroundTransparency = 1
	prizeRow.Size = UDim2.fromOffset(BODY_W, 56)
	prizeRow.Position = UDim2.fromOffset(0, 387)
	prizeRow.ZIndex = 20
	prizeRow.Parent = freeBody

	local prizeLayout = Instance.new("UIListLayout")
	prizeLayout.FillDirection = Enum.FillDirection.Horizontal
	prizeLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	prizeLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	prizeLayout.SortOrder = Enum.SortOrder.LayoutOrder
	prizeLayout.Padding = UDim.new(0, 12)
	prizeLayout.Parent = prizeRow

	local SHOE_ICON = "rbxassetid://126213576980021"
	local function speedText(v)
		v = tonumber(v) or 0
		if v >= 1e6 then return ("%gM"):format(math.floor(v / 1e5) / 10) end
		if v >= 1e3 then return ("%gK"):format(math.floor(v / 1e2) / 10) end
		return tostring(math.floor(v))
	end

	local leftCoin = art(prizeRow, { name = "CoinLeft", image = SHOE_ICON, size = UDim2.fromOffset(54, 54), zindex = 21 })
	leftCoin.LayoutOrder = 1
	leftCoin.Rotation = -16

	local prizeLabel = boldLabel(prizeRow, {
		name = "Amount", size = UDim2.fromOffset(0, 56),
		text = ("+%s Speed!"):format(speedText(Config.FreeReward and Config.FreeReward.Speed or 5000)),
		colour = Color3.fromRGB(255, 226, 64), strokeW = FLAT_TEXT, strokeColour = FLAT_INK, zindex = 22, textSize = 44,
	})
	prizeLabel.AutomaticSize = Enum.AutomaticSize.X
	prizeLabel.LayoutOrder = 2

	local rightCoin = art(prizeRow, { name = "CoinRight", image = SHOE_ICON, size = UDim2.fromOffset(54, 54), zindex = 21 })
	rightCoin.LayoutOrder = 3
	rightCoin.Rotation = 16

	local CLAIM_W, CLAIM_H = 380, 78
	local claim = block({
		parent = freeBody, name = "Claim", tone = K.ready, clickable = true,
		size = UDim2.fromOffset(CLAIM_W, CLAIM_H),
		position = UDim2.fromOffset(math.floor((BODY_W - CLAIM_W) / 2), 463),
		radius = FLAT_BTN_R, outline = 2, edge = FLAT_EDGE, stud = 13, studAlpha = 0.42, shadowY = 5, zindex = 16,
	})
	local claimMark = art(claim, {
		name = "Mark", image = ICON.gift, size = UDim2.fromOffset(90, 90),
		position = UDim2.new(0.5, 0, 0.5, 0), anchor = Vector2.new(0.5, 0.5), zindex = 26,
	})
	local claimLabel = boldLabel(claim, {
		name = "Label", size = UDim2.fromScale(1, 1), text = "Claim",
		strokeW = FLAT_TEXT, strokeColour = FLAT_INK, zindex = 28, textSize = 46,
	})

	local function refreshClaim()
		if claimed then
			claimLabel.Text = "Claimed"
			repaintBlock(claim, K.lock)
		elseif verifiable and joined then
			claimLabel.Text = "Claim"
			repaintBlock(claim, K.ready)
		else
			claimLabel.Text = "Locked"
			repaintBlock(claim, K.lock)
		end
		claimMark.Visible = true

		likeLabel.Text = "Like the Game!"
		repaintBlock(likeTile, K.claimed)

		groupLabel.Text = "Join Our Group!"
		repaintBlock(groupTile, K.claimed)
	end

	claim.MouseButton1Click:Connect(function()
		if claimed or not (verifiable and joined) then return end
		freeRemote:FireServer("claim")
	end)

	freeRemote.OnClientEvent:Connect(function(kind, data)
		if kind == "state" and type(data) == "table" then
			claimed = data.claimed == true
			verifiable = data.verifiable == true
			joined = data.joined == true
			if data.speed then
				prizeLabel.Text = ("+%s Speed!"):format(speedText(data.speed))
			end
			refreshClaim()
		elseif kind == "granted" then
			claimed = true
			claimLabel.Text = "Thank You!"
			repaintBlock(claim, K.bar)
			task.delay(1.8, function()
				freeShell.Visible = false
				refreshClaim()
			end)
		elseif kind == "denied" then
			local short = { ["already claimed"] = "Claimed", ["join the group first"] = "Join First" }
			claimLabel.Text = short[tostring(data)] or "Try Later"
			task.delay(1.6, refreshClaim)
		end
	end)

	refreshClaim()
	freeRemote:FireServer("get")

	freeShell:GetPropertyChangedSignal("Visible"):Connect(function()
		if freeShell.Visible then
			freeRemote:FireServer("get")
		end
	end)
end

local SIZES = {
	FreeRewards = Vector2.new(FREE_W, FREE_H),
}

local PANELS_ORDER, PANELS_ORDER_OPEN = 5, 7
do
	local function syncOrder()
		for _, panel in pairs(panels) do
			if panel.Visible then
				screen.DisplayOrder = PANELS_ORDER_OPEN
				return
			end
		end
		screen.DisplayOrder = PANELS_ORDER
	end
	for _, panel in pairs(panels) do
		panel:GetPropertyChangedSignal("Visible"):Connect(syncOrder)
	end
	syncOrder()
end

_G.ClosePanels = function()
	for _, panel in pairs(panels) do
		panel.Visible = false
	end
end

local function open(id)

	local current = panels[id]
	if not current then
		for _, panel in pairs(panels) do panel.Visible = false end
		return
	end
	if current.Visible then
		current.Visible = false
		Sfx.play("close")
		return
	end
	Sfx.play("open")

	for panelId, panel in pairs(panels) do
		panel.Visible = (panelId == id)
	end

	local body = bodies[id]
	if body and body:IsA("ScrollingFrame") then
		body.CanvasPosition = Vector2.new(0, 0)
	end

	local grid = body and body:FindFirstChild("Grid")
	if grid and grid:IsA("ScrollingFrame") then
		grid.CanvasPosition = Vector2.new(0, 0)
	end
	local panel = panels[id]
	local target = SIZES[id]
	if panel and target then

		panel.Size = UDim2.fromOffset(target.X, target.Y)
		local fitted = fits[id] and fits[id]() or 1
		if scales[id] then
			UIKit.popOpen(scales[id], fitted)
		end
	end
end

local bus = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("OpenPanel")
bus.Event:Connect(open)