local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Rebirth = require(RS:WaitForChild("RebirthConfig"))
local Money = require(RS:WaitForChild("MonetizationConfig"))

local plr = Players.LocalPlayer
local K = UIKit.Palette
local remotes = RS:WaitForChild("Remotes")
local remote = remotes:WaitForChild("Rebirth")

local ICON = "rbxassetid://102581215383481"
local ARROW = "rbxassetid://71395997585045"
local SKIP = Money.REBIRTH_SKIP or { productId = 0, price = 0 }

local stats = plr:WaitForChild("stats")
local wallet = plr:WaitForChild("wallet")

local W, H = 560, 390
local PINK = { hi = Color3.fromRGB(255, 120, 220), base = Color3.fromRGB(240, 60, 190), sh = Color3.fromRGB(170, 20, 130) }

local short = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig")).fmtShort

local function multText(m)
	local text = ("%.2f"):format(math.floor(m * 100 + 0.5) / 100):gsub("0+$", ""):gsub("%.$", "")
	return "x" .. text .. " Speed"
end

local screen = UIKit.screen("RebirthPanel", plr:WaitForChild("PlayerGui"), 9)
screen.IgnoreGuiInset = true

local root, panel = UIKit.window({
	parent = screen, name = "Rebirth", title = "REBIRTH", icon = ICON, width = W, height = H,
})

local function plate(name, tone, size, position, text)
	local b = UIKit.block({
		parent = root, name = name, tone = tone, size = size, position = position,
		radius = 10, outline = 3, stud = 11, zindex = 14,
	})
	local label = UIKit.boldLabel({
		parent = b, name = "Label", size = UDim2.fromScale(1, 1),
		text = text, textSize = 30, zindex = 18,
	})
	return b, label
end

local _, levelLabel = plate("Level", K.ready, UDim2.fromOffset(240, 52), UDim2.fromOffset((W - 240) / 2, 90), "Level 1")
local _, nowLabel = plate("Now", K.claimed, UDim2.fromOffset(200, 56), UDim2.fromOffset(50, 160), "x1 Speed")
local _, nextLabel = plate("Next", K.claimed, UDim2.fromOffset(200, 56), UDim2.fromOffset(W - 250, 160), "x1.1 Speed")

local arrow = Instance.new("ImageLabel")
arrow.Name = "Arrow"
arrow.BackgroundTransparency = 1
arrow.Image = ARROW
arrow.ScaleType = Enum.ScaleType.Fit
arrow.Rotation = -90
arrow.AnchorPoint = Vector2.new(0.5, 0.5)
arrow.Position = UDim2.fromOffset(W / 2, 188)
arrow.Size = UDim2.fromOffset(52, 52)
arrow.ZIndex = 16
arrow.Parent = root

local track = Instance.new("Frame")
track.Name = "Progress"
track.BackgroundColor3 = Color3.fromRGB(38, 41, 47)
track.BorderSizePixel = 0
track.Position = UDim2.fromOffset(40, 240)
track.Size = UDim2.fromOffset(W - 80, 42)
track.ZIndex = 15
track.ClipsDescendants = true
track.Parent = root
do
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(14, 14, 18)
	s.Thickness = 3
	s.LineJoinMode = Enum.LineJoinMode.Miter
	s.Parent = track
end
local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.BackgroundColor3 = Color3.new(1, 1, 1)
fill.BorderSizePixel = 0
fill.Size = UDim2.fromScale(0, 1)
fill.ZIndex = 16
fill.Parent = track
do
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromRGB(255, 236, 70), Color3.fromRGB(255, 170, 20))
	g.Parent = fill
	local studs = Instance.new("ImageLabel")
	studs.Name = "Studs"
	studs.BackgroundTransparency = 1
	studs.Image = UIKit.ICON.studs
	studs.ScaleType = Enum.ScaleType.Tile
	studs.TileSize = UDim2.fromOffset(12, 12)
	studs.ImageTransparency = 0.45
	studs.Size = UDim2.fromScale(1, 1)
	studs.ZIndex = 17
	studs.Parent = fill
end
local progressLabel = UIKit.boldLabel({
	parent = track, name = "Text", size = UDim2.fromScale(1, 1),
	text = "$0 / $0", textSize = 26, zindex = 19,
})

local note = UIKit.boldLabel({
	parent = root, name = "Note", size = UDim2.new(1, 0, 0, 30), position = UDim2.new(0, 0, 1, 10),
	text = "", textSize = 24, colour = Color3.fromRGB(255, 90, 90), zindex = 20,
})
note.Visible = false
local noteToken = 0
local function say(text)
	noteToken += 1
	local mine = noteToken
	note.Text = text
	note.Visible = true
	task.delay(2.2, function()
		if noteToken == mine then
			note.Visible = false
		end
	end)
end

local rebirthBtn, setRebirthEnabled = UIKit.button({
	parent = root, name = "RebirthButton", tone = K.ready, text = "Rebirth", textSize = 30,
	size = UDim2.fromOffset(220, 62), position = UDim2.fromOffset(50, 305), zindex = 14,
	onClick = function()
		remote:FireServer("rebirth")
	end,
})
UIKit.button({
	parent = root, name = "SkipButton", tone = PINK, text = "Skip Rebirth", textSize = 30,
	size = UDim2.fromOffset(220, 62), position = UDim2.fromOffset(W - 270, 305), zindex = 14,
	onClick = function()
		local id = tonumber(SKIP.productId) or 0
		local done = (stats:FindFirstChild("Rebirths") and stats.Rebirths.Value) or 0
		if Rebirth.maxed(done) then
			say("Max rebirth reached!")
		elseif id > 0 then
			MarketplaceService:PromptProductPurchase(plr, id)
		elseif RunService:IsStudio() and Money.STUDIO_TEST then
			remote:FireServer("skipTest")
		else
			say("Skip Rebirth - not available right now")
		end
	end,
})

local function refresh()
	local rebirths = (stats:FindFirstChild("Rebirths") and stats.Rebirths.Value) or 0
	local coins = (wallet:FindFirstChild("Coins") and wallet.Coins.Value) or 0
	local cost = Rebirth.cost(rebirths)
	local maxed = Rebirth.maxed(rebirths)
	levelLabel.Text = "Level " .. (rebirths + 1)
	nowLabel.Text = multText(Rebirth.mult(rebirths))
	nextLabel.Text = maxed and "MAX" or multText(Rebirth.mult(rebirths + 1))
	fill.Size = UDim2.fromScale(maxed and 1 or math.clamp(coins / math.max(cost, 1), 0, 1), 1)
	progressLabel.Text = maxed and "MAX" or ("$%s / $%s"):format(short(coins), short(cost))
	setRebirthEnabled(not maxed and coins >= cost)
end

local function watch(folder, name)
	local v = folder:FindFirstChild(name) or folder:WaitForChild(name, 30)
	if v then
		v.Changed:Connect(refresh)
	end
end
task.spawn(watch, stats, "Rebirths")
task.spawn(watch, wallet, "Coins")
refresh()

remote.OnClientEvent:Connect(function(kind, value)
	if kind == "fail" then
		say(tostring(value or "Not enough cash!"))
	elseif kind == "done" then
		refresh()
	end
end)

local bus = remotes:WaitForChild("OpenPanel")
bus.Event:Connect(function(id)
	if id == "Rebirth" then
		refresh()
		panel.open()
	elseif panel.isOpen() then
		panel.close()
	end
end)