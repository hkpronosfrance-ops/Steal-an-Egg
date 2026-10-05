local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")

local world = workspace:WaitForChild("GameWorld")
local template = game.ServerStorage:WaitForChild("AdminTreadmillTemplate")
local U = require(RS.UpgradeConfig)
local Cfg = require(RS.EggConfig)

local remote = Instance.new("RemoteEvent")
remote.Name = "AdminTreadmillExit"
remote.Parent = RS.Remotes

local REENTER_COOLDOWN = 1.5
local STAND_HEIGHT = 7
local RUN_REFERENCE = 20

local function rateFor(p)
	local walk = Cfg.walkForSpeed(p:GetAttribute("Speed") or Cfg.SPEED_START)
	return math.clamp(walk / RUN_REFERENCE, 0.7, 3.5)
end

local sessions = {}
local lanes = {}
local cooldown = {}
local activeModel, belt
local multiplier = 1

local function stop(p, move)
	local s = sessions[p]
	if not s then return end
	sessions[p] = nil
	cooldown[p] = os.clock() + REENTER_COOLDOWN
	if s.track then s.track:Stop(0.15) s.track:Destroy() end
	if s.root and s.root.Parent then
		s.root.Anchored = s.anchored
		if move and s.hum.Health > 0 then s.root.CFrame = s.lane.exit end
	end
	if s.hum and s.hum.Parent then s.hum.AutoRotate = s.auto end
	if s.lane then s.lane.occupant = nil end
	p:SetAttribute("AdminTreadmillRunning", false)
end

local function start(p, lane, root, hum)
	if sessions[p] or lane.occupant then return end
	if not (_G.Profile and _G.Profile.get(p)) then return end
	local stand = lane.stand * CFrame.new(0, hum.HipHeight + root.Size.Y / 2, 0)
	sessions[p] = { root = root, hum = hum, anchored = root.Anchored, auto = hum.AutoRotate, lane = lane, owed = 0 }
	lane.occupant = p
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = stand
	root.Anchored = true
	hum.AutoRotate = false
	p:SetAttribute("AdminTreadmillRunning", true)
	local animator = hum:FindFirstChildOfClass("Animator")
	if animator then
		local anim = Instance.new("Animation")
		anim.AnimationId = hum.RigType == Enum.HumanoidRigType.R6 and "rbxassetid://180426354" or "rbxassetid://913376220"
		local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
		anim:Destroy()
		if ok then
			sessions[p].track = track
			track.Priority = Enum.AnimationPriority.Action
			track.Looped = true
			track:Play(0.15, 1, rateFor(p))
		end
	end
end

local function disable()
	for p in pairs(sessions) do stop(p, true) end
	if activeModel then activeModel:Destroy() end
	activeModel, belt = nil, nil
	table.clear(lanes)
end

local function enable()
	activeModel = template:Clone()
	activeModel.Name = "AdminTreadmill"
	activeModel.Parent = world
	belt = activeModel:WaitForChild("Belt")
	local slots = activeModel:WaitForChild("Slots")
	for i = 1, 7 do
		local marker = slots:WaitForChild("Slot" .. i)
		local exitPos = (belt.CFrame * CFrame.new(0, 3, belt.Size.Z / 2 + 7.5)).Position
		lanes[i] = {index = i, stand = marker.CFrame, exit = CFrame.lookAt(exitPos, exitPos - belt.CFrame.LookVector)}
	end
end

local function laneFor(_localX)
	for _, lane in ipairs(lanes) do
		if not lane.occupant then return lane end
	end
end

local function tryEnter()
	local half = belt.Size / 2
	local now = os.clock()
	for _, p in ipairs(Players:GetPlayers()) do
		if not sessions[p] and (cooldown[p] or 0) < now then
			local char = p.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 and not root.Anchored and not hum.Sit then
				local rel = belt.CFrame:PointToObjectSpace(root.Position)
				if math.abs(rel.X) < half.X and math.abs(rel.Z) < half.Z and rel.Y > 0 and rel.Y < STAND_HEIGHT then
					local lane = laneFor(rel.X)
					if lane then start(p, lane, root, hum) end
				end
			end
		end
	end
end

local function clock(sec)
	sec = math.max(0, math.floor(sec))
	if sec >= 3600 then
		return ("%d:%02d:%02d"):format(sec // 3600, sec % 3600 // 60, sec % 60)
	end
	return ("%d:%02d"):format(sec // 60, sec % 60)
end

remote.OnServerEvent:Connect(function(p) stop(p, true) end)
Players.PlayerRemoving:Connect(function(p)
	stop(p, false)
	cooldown[p] = nil
end)
local function bind(p) p.CharacterRemoving:Connect(function() stop(p, false) end) end
Players.PlayerAdded:Connect(bind)
for _, p in ipairs(Players:GetPlayers()) do bind(p) end

local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.1 then return end
	local step = math.min(elapsed, 0.25)
	elapsed = 0

	local boost = _G.GlobalBoost
	multiplier = boost and boost.value("treadmill") or 1
	if multiplier <= 1 then
		if activeModel then disable() end
		return
	end
	if not activeModel then enable() end

	local state = boost.state().treadmill
	local endsAt = state and state.endsAt or 0
	activeModel:SetAttribute("Multiplier", multiplier)
	activeModel:SetAttribute("EndsAt", endsAt)
	local holo = activeModel:FindFirstChild("Hologram", true)
	if holo then
		local mult = holo:FindFirstChild("Mult")
		local info = holo:FindFirstChild("Info")
		if mult then mult.Text = ("x%g SPEED"):format(multiplier) end
		if info then
			local left = endsAt > 0 and ("  •  " .. clock(endsAt - os.time())) or ""
			info.Text = ("YOUR TREADMILL x%g%s"):format(multiplier, left)
		end
	end

	tryEnter()

	local beltRate = 1
	for p, s in pairs(sessions) do
		local rate = rateFor(p)
		beltRate = math.max(beltRate, rate)
		if s.track and s.track.IsPlaying then s.track:AdjustSpeed(rate) end
	end
	activeModel:SetAttribute("BeltRate", beltRate)

	for p, s in pairs(sessions) do
		if not s.root.Parent or s.hum.Health <= 0 or (s.root.Position - s.lane.stand.Position).Magnitude > 12 then
			stop(p, false)
		else
			s.owed += step
			local every = U.MILL.awardEvery or 0.5
			if s.owed >= every then
				s.owed -= every
				local plot = _G.Plots and _G.Plots.of(p)
				local level = plot and plot.mill:GetAttribute("MillLevel") or 1
				local award = U.MILL.awardBase * U.MILL.awardGrowth ^ (math.clamp(level, 1, U.MAX_LEVEL) - 1)
				award *= (p:GetAttribute("TrailMult") or 1) * (_G.SpeedMult and _G.SpeedMult(p) or 1)
					* boost.value("speed") * multiplier * (_G.RebirthMult and _G.RebirthMult(p) or 1)
				local speed = p:GetAttribute("Speed") or Cfg.SPEED_START
				if award == award and award < math.huge then p:SetAttribute("Speed", math.min(speed + award, Cfg.SPEED_MAX)) end
			end
		end
	end
end)