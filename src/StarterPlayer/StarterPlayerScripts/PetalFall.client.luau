local RunService = game:GetService("RunService")

local map = workspace:WaitForChild("GameWorld")
local zone = map:WaitForChild("Zones"):WaitForChild("Zone10_CherryBlossom")

local TOP, BOTTOM = 44, 0.4
local rng = Random.new(tick() * 1000 % 2^31)

local homes = setmetatable({}, { __mode = "k" })
local petals = {}
local byPart = {}
local decor, model
local decorConns, modelConns = {}, {}

local function disconnect(list)
	for _, c in ipairs(list) do c:Disconnect() end
	table.clear(list)
end

local function addPetal(p)
	if not p:IsA("BasePart") or byPart[p] then return end
	local home = homes[p]
	if not home then
		home = p.Position
		homes[p] = home
	end
	local e = {
		part  = p,
		x0    = home.X,
		z0    = home.Z,
		x     = home.X,
		z     = home.Z,
		y     = p.Position.Y,
		fall  = rng:NextNumber(1.6, 4.2),
		swayA = rng:NextNumber(0.8, 2.6),
		swayF = rng:NextNumber(0.5, 1.4),
		phase = rng:NextNumber(0, math.pi * 2),
		spinX = rng:NextNumber(-1.4, 1.4),
		spinY = rng:NextNumber(-2.2, 2.2),
		drift = rng:NextNumber(-0.5, 0.5),
	}
	byPart[p] = e
	table.insert(petals, e)
end

local function removePetal(p)
	local e = byPart[p]
	if not e then return end
	byPart[p] = nil
	local i = table.find(petals, e)
	if i then table.remove(petals, i) end
end

local function unbindModel()
	disconnect(modelConns)
	model = nil
	table.clear(petals)
	table.clear(byPart)
end

local function bindModel(m)
	if m == model then return end
	unbindModel()
	model = m
	for _, p in ipairs(m:GetChildren()) do addPetal(p) end
	table.insert(modelConns, m.ChildAdded:Connect(addPetal))
	table.insert(modelConns, m.ChildRemoved:Connect(removePetal))
end

local function unbindDecor()
	disconnect(decorConns)
	decor = nil
	unbindModel()
end

local function bindDecor(d)
	if d == decor then return end
	unbindDecor()
	decor = d
	table.insert(decorConns, d.ChildAdded:Connect(function(c)
		if c.Name == "FallingPetals" then bindModel(c) end
	end))
	table.insert(decorConns, d.ChildRemoved:Connect(function(c)
		if c ~= model then return end
		unbindModel()
		local other = d:FindFirstChild("FallingPetals")
		if other then bindModel(other) end
	end))
	local m = d:FindFirstChild("FallingPetals")
	if m then bindModel(m) end
end

zone.ChildAdded:Connect(function(c)
	if c.Name == "Decor" then bindDecor(c) end
end)
zone.ChildRemoved:Connect(function(c)
	if c ~= decor then return end
	unbindDecor()
	local other = zone:FindFirstChild("Decor")
	if other then bindDecor(other) end
end)
local current = zone:FindFirstChild("Decor")
if current then bindDecor(current) end

local t = 0
RunService.Heartbeat:Connect(function(dt)
	t += dt
	if not model then return end
	for _, e in ipairs(petals) do
		e.y -= e.fall * dt
		e.z += e.drift * dt
		if e.y <= BOTTOM then
			e.y = TOP + rng:NextNumber(0, 8)
			e.x = e.x0 + rng:NextNumber(-3, 3)
			e.z = e.z0
			e.fall = rng:NextNumber(1.6, 4.2)
		end
		local sway = math.sin(t * e.swayF + e.phase) * e.swayA
		e.part.CFrame = CFrame.new(e.x + sway, e.y, e.z)
			* CFrame.Angles(t * e.spinX, t * e.spinY, sway * 0.35)
	end
end)