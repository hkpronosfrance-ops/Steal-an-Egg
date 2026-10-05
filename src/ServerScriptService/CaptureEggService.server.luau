local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")

local Cfg = require(RS:WaitForChild("CaptureEggConfig"))
local EggCfg = require(RS:WaitForChild("EggConfig"))

local remotes = RS:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("CaptureEgg")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "CaptureEgg"
	remote.Parent = remotes
end

local TOPIC = "CaptureEggEvent"

local state = { active = false, endsAt = 0, mult = 1, holder = nil }
local scores, names = {}, {}
local cooldown = {}
local egg, core, weld, label, timeLabel, holderLabel, hologram
local groundY = 0

local function inArena(pos)
	return pos.X >= EggCfg.X_MIN and pos.X <= EggCfg.X_MAX and pos.Z <= EggCfg.SAFE_Z
end

local function floorAt(pos)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = {}
	if egg then table.insert(ignore, egg) end
	for _, p in ipairs(Players:GetPlayers()) do if p.Character then table.insert(ignore, p.Character) end end
	params.FilterDescendantsInstances = ignore
	local hit = workspace:Raycast(Vector3.new(pos.X, pos.Y + 8, pos.Z), Vector3.new(0, -200, 0), params)
	return hit and hit.Position.Y or 0.5
end

local function buildEgg()
	local model = Instance.new("Model")
	model.Name = "CaptureEgg"
	core = Instance.new("Part")
	core.Name = "Core"
	core.Size = Vector3.new(5.2, 6.8, 5.2)
	core.Transparency = 1
	core.Anchored = true
	core.CanCollide = false
	core.CanTouch = true
	core.CanQuery = false
	core.Massless = true
	core.Parent = model
	model.PrimaryPart = core
	local BEIGE = Color3.fromRGB(204, 182, 140)
	local SHADE = Color3.fromRGB(172, 146, 104)
	local SPOT = Color3.fromRGB(106, 66, 38)
	local widths = { 2.4, 3.6, 4.4, 4.8, 4.8, 4.4, 3.8, 3.0, 1.8 }
	local h = 0.72
	local y0 = -3.2
	local function block(size, offset, colour)
		local p = Instance.new("Part")
		p.Name = "Voxel"
		p.Size = size
		p.CFrame = core.CFrame * CFrame.new(offset)
		p.Color = colour
		p.Material = Enum.Material.SmoothPlastic
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Anchored = false
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Massless = true
		p.Parent = model
		local w = Instance.new("WeldConstraint")
		w.Part0 = core
		w.Part1 = p
		w.Parent = p
		return p
	end
	for i, w in ipairs(widths) do
		local y = y0 + (i - 0.5) * h
		local tint = (i - 1) / #widths * 0.08
		block(Vector3.new(w, h, w * 0.64), Vector3.new(0, y, 0), BEIGE:Lerp(Color3.new(1, 1, 1), tint))
		block(Vector3.new(w * 0.64, h, w), Vector3.new(0, y, 0), SHADE:Lerp(Color3.new(1, 1, 1), tint))
	end
	local spots = {
		{ 3, 1, 0.3 }, { 5, 2, -0.35 }, { 4, 3, 0.1 }, { 6, 4, 0.3 }, { 2, 2, 0 }, { 7, 1, -0.2 }, { 5, 4, -0.3 }, { 3, 3, 0.4 },
		{ 4, 1, -0.4 }, { 6, 2, 0.35 }, { 2, 4, -0.1 }, { 6, 3, -0.4 }, { 8, 2, 0 }, { 4, 4, 0.45 }, { 5, 1, 0.1 }, { 7, 3, 0.2 },
	}
	for _, s in ipairs(spots) do
		local layer, face, slide = s[1], s[2], s[3]
		local w = widths[layer]
		local y = y0 + (layer - 0.5) * h
		local off, size
		if face == 1 then off, size = Vector3.new(slide * w * 0.5, y, w / 2 + 0.02), Vector3.new(0.62, 0.62, 0.08)
		elseif face == 2 then off, size = Vector3.new(w / 2 + 0.02, y, slide * w * 0.5), Vector3.new(0.08, 0.62, 0.62)
		elseif face == 3 then off, size = Vector3.new(slide * w * 0.5, y, -w / 2 - 0.02), Vector3.new(0.62, 0.62, 0.08)
		else off, size = Vector3.new(-w / 2 - 0.02, y, slide * w * 0.5), Vector3.new(0.08, 0.62, 0.62) end
		block(size, off, SPOT)
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 140)
	light.Range = 16
	light.Brightness = 1.4
	light.Parent = core
	local sparkle = Instance.new("ParticleEmitter")
	sparkle.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 226, 120))
	sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	sparkle.Lifetime = NumberRange.new(0.8, 1.4)
	sparkle.Rate = 10
	sparkle.Speed = NumberRange.new(1, 3)
	sparkle.SpreadAngle = Vector2.new(180, 180)
	sparkle.LightEmission = 0.8
	sparkle.Parent = core
	model:ScaleTo(Cfg.EggScale or 1)
	local bb = Instance.new("BillboardGui")
	bb.Name = "CaptureHologram"
	bb.Size = UDim2.fromScale(10, 3.8)
	bb.StudsOffset = Vector3.new(0, core.Size.Y / 2 + 2.4, 0)
	bb.MaxDistance = 300
	hologram = bb
	bb.LightInfluence = 0
	bb.Parent = core
	local function text(name, y, hgt, colour)
		local t = Instance.new("TextLabel")
		t.Name = name
		t.BackgroundTransparency = 1
		t.Position = UDim2.fromScale(0, y)
		t.Size = UDim2.fromScale(1, hgt)
		t.Font = Enum.Font.FredokaOne
		t.TextScaled = true
		t.TextColor3 = colour
		t.Text = ""
		t.Parent = bb
		local st = Instance.new("UIStroke")
		st.Thickness = 2.5
		st.Color = Color3.fromRGB(26, 14, 6)
		st.Parent = t
		return t
	end
	label = text("Title", 0, 0.3, Color3.fromRGB(255, 214, 64))
	label.Text = Cfg.Title
	timeLabel = text("Time", 0.3, 0.44, Color3.new(1, 1, 1))
	holderLabel = text("Holder", 0.76, 0.24, Color3.fromRGB(190, 240, 255))
	model.Parent = workspace
	return model
end

local function rootOf(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart"), c and c:FindFirstChildOfClass("Humanoid")
end

local prompt

local function rescale(k)
	if not egg or not core then return end
	local parts = {}
	for _, d in ipairs(egg:GetDescendants()) do
		if d:IsA("WeldConstraint") and d ~= weld then d:Destroy() end
		if d:IsA("BasePart") then
			d.Anchored = true
			table.insert(parts, d)
		end
	end
	egg:ScaleTo(k)
	for _, p in ipairs(parts) do
		if p ~= core then
			p.Anchored = false
			local w = Instance.new("WeldConstraint")
			w.Part0 = core
			w.Part1 = p
			w.Parent = p
		end
	end
	if hologram then
		hologram.Size = UDim2.fromScale(10, 3.8)
		hologram.StudsOffset = Vector3.new(0, core.Size.Y / 2 + (state.holder and 4.2 or 2.4), 0)
	end
end

local grab

local function addPrompt()
	if prompt then prompt:Destroy() end
	if not core then return end
	prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Pick up"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.45
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt:SetAttribute("EggPrompt", true)
	CollectionService:AddTag(prompt, "StealPrompt")
	prompt.Parent = core
	prompt.Triggered:Connect(function(p) grab(p) end)
end

local function placeIdle(pos)
	if weld then weld:Destroy() weld = nil end
	if not core then return end
	core.Anchored = true
	rescale(Cfg.EggScale or 1)
	groundY = floorAt(pos)
	core.CFrame = CFrame.new(pos.X, groundY + core.Size.Y / 2 + 1, pos.Z)
	if holderLabel then holderLabel.Text = "" end
	addPrompt()
end

local function release(p)
	p:SetAttribute("HoldingCaptureEgg", nil)
	p:SetAttribute("CarryingEgg", false)
	p:SetAttribute("CarryCenter", nil)
	p:SetAttribute("CarrySize", nil)
end

local function drop(returnHome)
	local p = state.holder
	state.holder = nil
	if p then
		cooldown[p] = os.clock() + Cfg.PickupCooldown
		release(p)
	end
	local root = p and rootOf(p)
	local pos = (not returnHome and root and inArena(root.Position)) and root.Position or Cfg.Center
	placeIdle(pos)
end

function grab(p)
	if not state.active or state.holder or not core then return end
	if (cooldown[p] or 0) > os.clock() then return end
	if p:GetAttribute("Stunned") or p:GetAttribute("CarryingEgg") then return end
	local root, hum = rootOf(p)
	if not root or not hum or hum.Health <= 0 or not inArena(root.Position) then return end
	local ch = p.Character
	local anchor = ch:FindFirstChild("UpperTorso") or root
	state.holder = p
	names[p.UserId] = p.DisplayName
	scores[p.UserId] = scores[p.UserId] or 0
	if prompt then prompt:Destroy() prompt = nil end
	hum:UnequipTools()
	core.Anchored = true
	rescale((Cfg.EggScale or 1) * (Cfg.HeldScale or 0.5))
	core.CFrame = anchor.CFrame * CFrame.new(0, 0.1, -(anchor.Size.Z / 2 + core.Size.Z / 2 + 0.3))
	core.Anchored = false
	weld = Instance.new("WeldConstraint")
	weld.Part0 = anchor
	weld.Part1 = core
	weld.Parent = core
	p:SetAttribute("HoldingCaptureEgg", true)
	p:SetAttribute("CarryingEgg", true)
	p:SetAttribute("CarryCenter", anchor.CFrame:PointToObjectSpace(core.Position))
	p:SetAttribute("CarrySize", core.Size)
	if holderLabel then holderLabel.Text = "HELD BY " .. string.upper(p.DisplayName) end
end

local function ranking()
	local list = {}
	for userId, secs in pairs(scores) do
		table.insert(list, { u = userId, n = names[userId] or "?", s = math.floor(secs * 10) / 10 })
	end
	table.sort(list, function(a, b) return a.s > b.s end)
	return list
end

local function publishState()
	workspace:SetAttribute("CaptureEggActive", state.active)
	workspace:SetAttribute("CaptureEggEndsAt", state.endsAt)
	workspace:SetAttribute("CaptureEggMult", state.mult)
	remote:FireAllClients("state", {
		active = state.active, endsAt = state.endsAt, mult = state.mult,
		holder = state.holder and state.holder.UserId or 0, list = ranking(),
	})
end

local function finish()
	if not state.active then return end
	if state.holder then drop(true) end
	local list = ranking()
	local winners = {}
	for i = 1, 3 do
		local e = list[i]
		local reward = Cfg.Rewards[i]
		if e and reward and e.s >= 1 then
			local p = Players:GetPlayerByUserId(e.u)
			local speed = math.floor((reward.Speed or 0) * state.mult)
			local money = math.floor((reward.Money or 0) * state.mult)
			if p then
				if speed > 0 then
					p:SetAttribute("Speed", math.clamp((tonumber(p:GetAttribute("Speed")) or 0) + speed, 0, EggCfg.SPEED_MAX))
				end
				if money > 0 and _G.Profile then
					_G.Profile.set(p, "Coins", _G.Profile.value(p, "wallet", "Coins") + money)
				end
			end
			table.insert(winners, { u = e.u, n = e.n, s = e.s, speed = speed, money = money, place = i })
		end
	end
	state.active = false
	state.endsAt = 0
	if egg then egg:Destroy() end
	egg, core, weld, hologram, prompt = nil, nil, nil, nil, nil
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("HoldingCaptureEgg") then release(p) end
	end
	publishState()
	remote:FireAllClients("results", { winners = winners })
end

local function startLocal(endsAt, mult)
	state.mult = math.clamp(tonumber(mult) or 1, 1, 1000)
	state.endsAt = endsAt
	if not state.active then
		state.active = true
		scores, names, cooldown = {}, {}, {}
		state.holder = nil
		if egg then egg:Destroy() end
		egg = buildEgg()
		placeIdle(Cfg.Center)
	end
	publishState()
end

local function stopLocal()
	if not state.active then return end
	state.endsAt = workspace:GetServerTimeNow()
	finish()
end

local jobId = game.JobId
local CaptureEgg = {}
_G.CaptureEgg = CaptureEgg

function CaptureEgg.start(minutes, mult, everywhere)
	local mins = tonumber(minutes)
	if not mins or mins ~= mins or mins < 0.5 or mins > 1440 then return nil, "minutes must be 0.5 to 1440" end
	local endsAt = workspace:GetServerTimeNow() + mins * 60
	startLocal(endsAt, mult)
	if everywhere then
		task.spawn(function()
			pcall(function() MessagingService:PublishAsync(TOPIC, { op = "start", endsAt = endsAt, mult = state.mult, from = jobId }) end)
		end)
	end
	return true
end

function CaptureEgg.stop(everywhere)
	stopLocal()
	if everywhere then
		task.spawn(function()
			pcall(function() MessagingService:PublishAsync(TOPIC, { op = "stop", from = jobId }) end)
		end)
	end
	return true
end

function CaptureEgg.onHit(victim)
	if state.holder == victim then drop(false) end
end

function CaptureEgg.state()
	return { active = state.active, endsAt = state.endsAt, mult = state.mult }
end

task.spawn(function()
	pcall(function()
		MessagingService:SubscribeAsync(TOPIC, function(message)
			local data = message.Data
			if type(data) ~= "table" or data.from == jobId then return end
			if data.op == "start" and tonumber(data.endsAt) then startLocal(tonumber(data.endsAt), data.mult)
			elseif data.op == "stop" then stopLocal() end
		end)
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	if state.holder == p then drop(false) end
	cooldown[p] = nil
end)

remote.OnServerEvent:Connect(function(p, action)
	if action == "sync" then
		remote:FireClient(p, "state", {
			active = state.active, endsAt = state.endsAt, mult = state.mult,
			holder = state.holder and state.holder.UserId or 0, list = ranking(),
		})
	end
end)

local sendClock, spin = 0, 0
RunService.Heartbeat:Connect(function(dt)
	if not state.active then return end
	if workspace:GetServerTimeNow() >= state.endsAt then finish() return end
	local p = state.holder
	if p then
		local root, hum = rootOf(p)
		if not root or not hum or hum.Health <= 0 or not p.Parent or not core or not core.Parent then
			drop(true)
		elseif not inArena(root.Position) then
			drop(true)
		else
			scores[p.UserId] = (scores[p.UserId] or 0) + dt
		end
	elseif core then
		spin += dt
		local pos = core.Position
		core.CFrame = CFrame.new(pos.X, groundY + core.Size.Y / 2 + 1 + math.sin(spin * 2) * 0.45, pos.Z) * CFrame.Angles(0, spin * 0.9, 0)
	end
	if holderLabel and state.holder then
		holderLabel.Text = ("%s - %ds"):format(string.upper(state.holder.DisplayName), math.floor(scores[state.holder.UserId] or 0))
	end
	if timeLabel then
		local left = math.max(0, state.endsAt - workspace:GetServerTimeNow())
		local secs = math.ceil(left)
		timeLabel.Text = ("%d:%02d"):format(secs // 60, secs % 60)
	end
	sendClock += dt
	if sendClock >= 0.5 then
		sendClock = 0
		publishState()
	end
end)