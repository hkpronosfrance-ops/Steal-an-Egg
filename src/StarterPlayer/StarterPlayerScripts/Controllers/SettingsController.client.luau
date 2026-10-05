local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIKit = require(ReplicatedStorage.Shared.UIKit)
local Config = require(ReplicatedStorage.Shared.Config)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local remote = ReplicatedStorage.Remotes:WaitForChild("Settings")

local K = UIKit.Palette
local S = table.clone(Config.DefaultSettings)

local baseVolume = setmetatable({}, { __mode = "k" })

local function scaleFor(sound)
	local on = S.SFX
	if sound:HasTag("Music") or sound:GetAttribute("Music") == true then on = S.Music end
	if not on then return 0 end
	return math.clamp(S.Volume, 0, 1)
end

local function applyToSound(sound)
	if baseVolume[sound] == nil then baseVolume[sound] = sound.Volume end
	sound.Volume = baseVolume[sound] * scaleFor(sound)
end

local function applyAll()
	for sound in pairs(baseVolume) do
		if sound.Parent then applyToSound(sound) end
	end
end

local function hook(inst)
	if inst:IsA("Sound") then
		applyToSound(inst)
	end
end

workspace.DescendantAdded:Connect(hook)
PlayerGui.DescendantAdded:Connect(hook)
for _, d in ipairs(PlayerGui:GetDescendants()) do hook(d) end
for _, d in ipairs(workspace:GetDescendants()) do hook(d) end

local MARGIN = 18
local BAR_H = 67
local GAP_HEADER = 14
local WINDOW_W = 640
local BODY_W = WINDOW_W - 2 * MARGIN
local ROW_H = 62
local ROW_GAP = 12
local ROW_COUNT = 5
local WINDOW_H = BAR_H + GAP_HEADER + ROW_COUNT * ROW_H + (ROW_COUNT - 1) * ROW_GAP + MARGIN
local BTN_H = 42
local CTRL_W = 200
local TOGGLE_W = 120
local CTRL_X = BODY_W - CTRL_W - 14
local NAME_W = CTRL_X - 18 - 12

local screen = UIKit.screen("SettingsPanel", PlayerGui, 9)
local root, panel = UIKit.window({
	parent = screen, name = "Settings", title = "SETTINGS", icon = UIKit.ICON.settings,
	width = WINDOW_W, height = WINDOW_H, margin = MARGIN, barHeight = BAR_H, zindex = 10,
})

root:SetAttribute("SkinSizeFactor", 0.83)

local innerBorder = root:FindFirstChild("Inner")
if innerBorder then innerBorder:Destroy() end

local controls = {}

local function row(order, name)
	local w = UIKit.block({
		parent = root, name = "Row_" .. name:gsub("%s", ""), tone = K.row,
		radius = 14, stud = 13,
		size = UDim2.fromOffset(BODY_W, ROW_H),
		position = UDim2.fromOffset(MARGIN, BAR_H + GAP_HEADER + (order - 1) * (ROW_H + ROW_GAP)),
		zindex = 12,
	})
	UIKit.darkLabel({
		parent = w, name = "Label",
		size = UDim2.fromOffset(NAME_W, ROW_H - 20), position = UDim2.fromOffset(18, 10),
		text = name, align = Enum.TextXAlignment.Left, textSize = 21,
		truncate = Enum.TextTruncate.AtEnd, zindex = 16,
	})
	return w
end

local function toggle(key, name, order, words)
	local onWord, offWord = words and words[1] or "ON", words and words[2] or "OFF"
	local w = row(order, name)
	local b = UIKit.block({
		parent = w, name = "Toggle", tone = K.ready, radius = 11, clickable = true, stud = 11,
		size = UDim2.fromOffset(TOGGLE_W, BTN_H),
		position = UDim2.fromOffset(CTRL_X + CTRL_W - TOGGLE_W, math.floor((ROW_H - BTN_H) / 2)),
		zindex = 16,
	})
	local label = UIKit.boldLabel({
		parent = b, name = "Label", size = UDim2.fromScale(1, 1),
		text = onWord, textSize = 19, zindex = 20,
	})
	UIKit.reactToCursor(b)
	b.MouseButton1Click:Connect(function()
		remote:FireServer("set", key, not S[key])
	end)
	controls[key] = function(v)
		label.Text = v and onWord or offWord
		UIKit.repaint(b, v and K.ready or K.close)
	end
end

local function volume(order)
	local w = row(order, "VOLUME")
	local SIDE = BTN_H
	local y = math.floor((ROW_H - BTN_H) / 2)
	local function step(name, sign, x, tone, delta)
		local b = UIKit.block({
			parent = w, name = name, tone = tone, radius = 11, clickable = true, stud = 11,
			size = UDim2.fromOffset(SIDE, SIDE), position = UDim2.fromOffset(x, y), zindex = 16,
		})

		local LEN, THICK, EDGE = 22, 6, 2
		local function bar(w2, h2, z, colour, pad)
			local f = Instance.new("Frame")
			f.Name = "Sign"
			f.AnchorPoint = Vector2.new(0.5, 0.5)
			f.Position = UDim2.fromScale(0.5, 0.5)
			f.Size = UDim2.fromOffset(w2 + pad * 2, h2 + pad * 2)
			f.BackgroundColor3 = colour
			f.BorderSizePixel = 0
			f.ZIndex = z
			f.Active = false
			local c = Instance.new("UICorner")
			c.CornerRadius = UDim.new(0, math.floor(THICK / 2) + pad)
			c.Parent = f
			f.Parent = b
		end
		bar(LEN, THICK, 19, K.outline, EDGE)
		bar(LEN, THICK, 20, Color3.new(1, 1, 1), 0)
		if sign == "+" then
			bar(THICK, LEN, 19, K.outline, EDGE)
			bar(THICK, LEN, 20, Color3.new(1, 1, 1), 0)
		end
		UIKit.reactToCursor(b)
		b.MouseButton1Click:Connect(function()
			remote:FireServer("set", "Volume", math.clamp(S.Volume + delta, 0, 1))
		end)
	end
	step("Minus", "-", CTRL_X + CTRL_W - 2 * SIDE - 16, K.close, -0.1)
	step("Plus", "+", CTRL_X + CTRL_W - SIDE, K.ready, 0.1)

	local value = UIKit.darkLabel({
		parent = w, name = "Value",
		size = UDim2.fromOffset(CTRL_W - 2 * SIDE - 30, BTN_H),
		position = UDim2.fromOffset(CTRL_X, y),
		text = "70%", align = Enum.TextXAlignment.Right, textSize = 21, zindex = 16,
	})
	controls.Volume = function(v)
		value.Text = ("%d%%"):format(math.floor(v * 100 + 0.5))
	end
end

toggle("Music", "MUSIC", 1)
toggle("SFX", "SOUND EFFECTS", 2)
volume(3)
toggle("HideOwnPets", "HIDE MY PETS", 4, { "YES", "NO" })
toggle("HideOtherPets", "HIDE OTHER PETS", 5, { "YES", "NO" })

local HIDEABLE = { "BillboardGui", "SurfaceGui", "ParticleEmitter", "Beam", "Trail", "Highlight", "Light" }
local petFolder

local function petHidden(model)
	local owner = tonumber(model:GetAttribute("OwnerUserId"))
	if owner == LocalPlayer.UserId then return S.HideOwnPets == true end
	return S.HideOtherPets == true
end

local function hidePart(d, hide)
	if d:IsA("BasePart") or d:IsA("Decal") then
		d.LocalTransparencyModifier = hide and 1 or 0
		return
	end
	for _, class in ipairs(HIDEABLE) do
		if d:IsA(class) then
			local was = d:GetAttribute("PetHideWas")
			if hide then
				if was == nil then d:SetAttribute("PetHideWas", d.Enabled) end
				d.Enabled = false
			elseif was ~= nil then
				d.Enabled = was
				d:SetAttribute("PetHideWas", nil)
			end
			return
		end
	end
end

local function applyPet(model, force)
	if not model:IsA("Model") then return end
	local hide = petHidden(model)
	if not force and (model:GetAttribute("PetHidden") == true) == hide then return end
	model:SetAttribute("PetHidden", hide)
	for _, d in ipairs(model:GetDescendants()) do hidePart(d, hide) end
end

local function applyPets()
	if not petFolder then return end
	for _, m in ipairs(petFolder:GetChildren()) do applyPet(m) end
end

local function watchPet(model)
	if not model:IsA("Model") then return end
	model:GetAttributeChangedSignal("OwnerUserId"):Connect(function() applyPet(model) end)
	model.DescendantAdded:Connect(function(d)
		if model:GetAttribute("PetHidden") == true then hidePart(d, true) end
	end)
	applyPet(model, true)
end

task.spawn(function()
	local map = workspace:WaitForChild("GameWorld", 60)
	petFolder = map and map:WaitForChild("PlacedAnimals", 60)
	if not petFolder then return end
	petFolder.ChildAdded:Connect(watchPet)
	for _, m in ipairs(petFolder:GetChildren()) do watchPet(m) end
end)

local function render()
	for key, fn in pairs(controls) do fn(S[key]) end
end

remote.OnClientEvent:Connect(function(kind, data)
	if kind ~= "state" or type(data) ~= "table" then return end
	for k, v in pairs(data) do S[k] = v end
	render()
	applyAll()
	applyPets()
end)

local bus = ReplicatedStorage.Remotes:WaitForChild("OpenPanel")
bus.Event:Connect(function(id)
	if id == "Settings" then
		if panel.isOpen() then panel.close() else panel.open() end
	elseif panel.isOpen() then
		panel.close()
	end
end)

render()
remote:FireServer("get")