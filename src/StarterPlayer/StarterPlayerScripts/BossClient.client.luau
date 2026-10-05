local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local BossAnim = require(RS:WaitForChild("BossAnim"))
local folder = workspace:WaitForChild("Bosses")

local LOOPED = { Idle = true, Run = true, Sleep = true }

local POS_SMOOTH = 12
local ROT_SMOOTH = 10
local SNAP_DISTANCE = 60
local MAX_PREDICT = 0.35
local FAR = 450
local FAR_EVERY = 6
local SETTLE_TIME = 0.2

local FADE = 0.2

local function ease(style, dir, a)
	if style == Enum.PoseEasingStyle.Constant then return 0 end
	if style == Enum.PoseEasingStyle.Linear then return a end
	if dir == Enum.PoseEasingDirection.In then return a * a * a end
	if dir == Enum.PoseEasingDirection.Out then return 1 - (1 - a) ^ 3 end
	return a < 0.5 and 4 * a * a * a or 1 - (-2 * a + 2) ^ 3 / 2
end

local function readClip(kfs, name, scale)
	local joints, length = {}, 0
	local frames = kfs:GetKeyframes()
	table.sort(frames, function(a, b) return a.Time < b.Time end)
	for _, kf in ipairs(frames) do
		length = math.max(length, kf.Time)
		for _, p in ipairs(kf:GetDescendants()) do
			if p:IsA("Pose") and p.Weight > 0 then
				local j = joints[p.Name]
				if not j then
					j = { times = {}, cfs = {}, styles = {}, dirs = {} }
					joints[p.Name] = j
				end
				table.insert(j.times, kf.Time)
				table.insert(j.cfs, p.CFrame.Rotation + p.CFrame.Position * scale)
				table.insert(j.styles, p.EasingStyle)
				table.insert(j.dirs, p.EasingDirection)
			end
		end
	end
	return { joints = joints, length = length, loop = LOOPED[name] == true }
end

local function sampleJoint(j, t)
	local times = j.times
	local n = #times
	if n == 0 then return CFrame.identity end
	if t <= times[1] then return j.cfs[1] end
	if t >= times[n] then return j.cfs[n] end
	local lo, hi = 1, n
	while hi - lo > 1 do
		local mid = (lo + hi) // 2
		if times[mid] <= t then lo = mid else hi = mid end
	end
	local span = times[hi] - times[lo]
	local a = span > 0 and (t - times[lo]) / span or 0
	return j.cfs[lo]:Lerp(j.cfs[hi], ease(j.styles[lo], j.dirs[lo], a))
end

local function setupAnimations(model)
	local ids = BossAnim.animations(model) or {}
	local embedded = BossAnim.embedded(model) or {}
	if next(ids) == nil and next(embedded) == nil then return nil end
	local motors = {}
	for _, m in ipairs(model:GetDescendants()) do
		if m:IsA("Motor6D") and m.Part1 then motors[m.Part1.Name] = m end
	end
	local scale = tonumber(model:GetAttribute("AnimScale")) or 1
	local clips = {}
	for name, kfs in pairs(embedded) do clips[name] = readClip(kfs, name, scale) end
	local controller = model:FindFirstChildOfClass("Humanoid") or model:FindFirstChildOfClass("AnimationController")
	if not controller then
		controller = Instance.new("AnimationController")
		controller.Parent = model
	end
	local animator = controller:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = controller
	end
	local tracks = {}
	for name, id in pairs(ids) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local ok, track = pcall(function() return animator:LoadAnimation(a) end)
		if ok and track then
			track.Looped = LOOPED[name] == true
			track.Priority = (name == "Attack" or name == "Wake") and Enum.AnimationPriority.Action or Enum.AnimationPriority.Movement
			tracks[name] = track
		end
	end
	return { tracks = tracks, clips = clips, motors = motors, clock = 0 }
end

local function usableTrack(a, name)
	local t = a.tracks[name]
	if t and (t.Length > 0 or not a.clips[name]) then return t end
	return nil
end

local function has(a, name)
	return a.tracks[name] ~= nil or a.clips[name] ~= nil
end

local function resetJoints(a)
	for _, motor in pairs(a.motors) do motor.Transform = CFrame.identity end
end

local function playAnimation(a, name, speed, restart)
	if not has(a, name) then name = "Idle" end
	if not has(a, name) then return end
	if a.name == name and not restart then
		if speed then
			a.speed = speed
			if a.track then a.track:AdjustSpeed(speed) end
		end
		return
	end
	local track = usableTrack(a, name)
	local wasTrack = a.track ~= nil
	if a.track then a.track:Stop(track and FADE or 0) a.track = nil end
	a.prevClip, a.prevTime = a.clip, a.time
	a.fade = a.clip and 0 or 1
	a.name, a.clip, a.time, a.speed = name, nil, 0, speed or 1
	if track then
		if a.prevClip then resetJoints(a) end
		track:Play(FADE)
		track:AdjustSpeed(a.speed)
		a.track = track
		a.prevClip = nil
	else
		a.clip = a.clips[name]
		a.dirty = true
		if wasTrack then a.prevClip = nil a.fade = 1 end
	end
end

local function clipTime(clip, t)
	if clip.length <= 0 then return 0 end
	if clip.loop then return t % clip.length end
	return math.min(t, clip.length)
end

local function stepEmbedded(a, dt)
	if not a.clip then return end
	a.time += dt * (a.speed or 1)
	if a.prevClip then a.prevTime += dt end
	a.fade = math.min(1, (a.fade or 1) + dt / FADE)
	local t = clipTime(a.clip, a.time)
	local pt = a.prevClip and clipTime(a.prevClip, a.prevTime)
	local blending = a.prevClip ~= nil and a.fade < 1
	for name, motor in pairs(a.motors) do
		local j = a.clip.joints[name]
		local pj = blending and a.prevClip.joints[name]
		if j or pj or a.dirty then
			local cf = j and sampleJoint(j, t) or CFrame.identity
			if pj then cf = sampleJoint(pj, pt):Lerp(cf, a.fade) end
			motor.Transform = cf
		end
	end
	a.dirty = blending or nil
	if a.fade >= 1 then a.prevClip = nil end
end

local live = {}
local byIndex = {}
local held = {}
local settling = {}

local function adopt(model)
	if live[model] then return end
	if not model:IsA("Model") then return end
	task.spawn(function()
		for _ = 1, 200 do
			if model:GetAttribute("BossCF") then break end
			task.wait(0.1)
		end
		local cf = model:GetAttribute("BossCF")
		if not model.Parent or live[model] or not cf then return end
		local anim = setupAnimations(model)
		if not anim then
			warn(("[Boss] %s has no animations - add Idle/Run/Attack/Sleep/Wake animation ids to its Boss model"):format(model.Name))
		else
			task.delay(10, function()
				for name, t in pairs(anim.tracks) do
					if t.Length <= 0 then
						warn(("[Boss] %s: animation %s did not load - publish it for this game or set its id to 0 to use the saved one"):format(model.Name, name))
					end
				end
			end)
		end
		live[model] = {
			anim = anim,
			pos = cf.Position,
			rot = cf - cf.Position,
			shown = cf,
			phase = math.random() * math.pi * 2,
			frame = math.random(0, FAR_EVERY - 1),
		}
		local index = model:GetAttribute("BossIndex")
		if index then byIndex[index] = model end
	end)
end

for _, m in ipairs(folder:GetChildren()) do adopt(m) end
folder.ChildAdded:Connect(adopt)
folder.ChildRemoved:Connect(function(m) live[m] = nil end)

local function trackEgg(egg)
	if not egg:IsA("Model") then return end
	local cf, size = egg:GetBoundingBox()
	settling[egg] = nil
	held[egg] = { bottom = egg:GetPivot().Position.Y - (cf.Position.Y - size.Y / 2) }
end
for _, egg in ipairs(CollectionService:GetTagged("BossHeldEgg")) do trackEgg(egg) end
CollectionService:GetInstanceAddedSignal("BossHeldEgg"):Connect(trackEgg)
CollectionService:GetInstanceRemovedSignal("BossHeldEgg"):Connect(function(egg)
	if held[egg] and egg.Parent then
		settling[egg] = { from = egg:GetPivot(), t = 0, wait = 0 }
	end
	held[egg] = nil
end)

RunService.RenderStepped:Connect(function(dt)
	local now = workspace:GetServerTimeNow()
	local cam = workspace.CurrentCamera
	local eye = cam and cam.CFrame.Position
	local attackTime = folder:GetAttribute("AttackTime") or 0.65
	local posBlend = 1 - math.exp(-dt * POS_SMOOTH)
	local rotBlend = 1 - math.exp(-dt * ROT_SMOOTH)

	for model, e in pairs(live) do
		if not model.Parent then
			live[model] = nil
			continue
		end
		local stamp = model:GetAttribute("BossStamp") or 0
		if stamp >= (e.stamp or 0) then
			e.stamp = stamp
			e.cf = model:GetAttribute("BossCF") or e.cf
			e.vel = model:GetAttribute("BossVel") or Vector3.zero
		end
		local cf, vel = e.cf, e.vel
		if not cf then continue end
		local age = now - (e.stamp or now)
		local state = model:GetAttribute("BossState") or "sleep"
		local since = now - (model:GetAttribute("BossStateAt") or now)
		local wakeTime = folder:GetAttribute("WakeTime") or 1.35

		local goal = cf.Position + vel * math.clamp(age, 0, MAX_PREDICT)
		local goalRot = cf - cf.Position
		if (goal - e.pos).Magnitude > SNAP_DISTANCE then
			e.pos, e.rot = goal, goalRot
		else
			if age < MAX_PREDICT then e.pos += vel * dt end
			e.pos = e.pos:Lerp(goal, posBlend)
			e.rot = e.rot:Lerp(goalRot, rotBlend)
		end
		e.shown = CFrame.new(e.pos) * e.rot

		local offset = CFrame.identity
		if state == "sleep" then
			e.phase += dt
			offset = CFrame.Angles(0, math.sin(e.phase * 0.22) * 0.10, 0)
		elseif state == "waking" then
			local k = math.clamp(since / wakeTime, 0, 1)
			offset = CFrame.Angles(0, math.sin(since * 26) * (1 - k) * 0.30, 0)
		end

		local far = eye ~= nil and (e.pos - eye).Magnitude > FAR
		e.frame += 1
		if not far or e.frame % FAR_EVERY == 0 then
			local render = e.shown * offset
			e.posed = render
			model:PivotTo(render)
		end

		local a = e.anim
		if a then
			local flat = Vector3.new(vel.X, 0, vel.Z).Magnitude
			if state == "sleep" then
				playAnimation(a, "Sleep", 1)
			elseif state == "waking" then
				playAnimation(a, "Wake", 1)
			elseif state == "attack" then
				local at = model:GetAttribute("BossStateAt")
				if a.attackAt ~= at then
					a.attackAt = at
					local track, clip = usableTrack(a, "Attack"), a.clips.Attack
					local len = track and track.Length or clip and clip.length or 0
					playAnimation(a, "Attack", len > 0 and len / math.max(attackTime, 0.2) or 1, true)
				end
			elseif flat > 1 then
				playAnimation(a, "Run", math.clamp(flat / 45, 0.6, 2))
			else
				playAnimation(a, "Idle", 1)
			end
			if not far or e.frame % FAR_EVERY == 0 then
				a.pending = (a.pending or 0) + dt
				stepEmbedded(a, a.pending)
				a.pending = 0
			else
				a.pending = (a.pending or 0) + dt
			end
		end
	end

	for eggModel, h in pairs(held) do
		if not eggModel.Parent then
			held[eggModel] = nil
			continue
		end
		local boss = byIndex[eggModel:GetAttribute("HeldBy")]
		local e = boss and live[boss]
		if e then
			local H = boss:GetAttribute("BossH") or 10
			local base = e.posed or e.shown
			local p = base.Position + base.LookVector * (H * 0.42)
			eggModel:PivotTo(CFrame.new(p.X, H * 0.30 + h.bottom, p.Z) * CFrame.Angles(0, eggModel:GetAttribute("HeldYaw") or 0, 0))
		end
	end

	for eggModel, s in pairs(settling) do
		local current = eggModel.Parent and eggModel:GetPivot()
		local loose = eggModel.PrimaryPart and not eggModel.PrimaryPart.Anchored
		if current and not s.goal then
			s.wait += dt
			if (current.Position - s.from.Position).Magnitude > 0.05 then
				s.goal = current
			end
		end
		if not current or loose or (not s.goal and s.wait > 0.5) then
			settling[eggModel] = nil
		elseif s.goal then
			s.t += dt
			local u = math.min(s.t / SETTLE_TIME, 1)
			eggModel:PivotTo(s.from:Lerp(s.goal, u * u * (3 - 2 * u)))
			if u >= 1 then
				settling[eggModel] = nil
			end
		end
	end
end)