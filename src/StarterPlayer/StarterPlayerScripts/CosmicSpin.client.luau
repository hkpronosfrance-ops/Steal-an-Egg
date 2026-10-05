local RunService = game:GetService("RunService")

local RING_SPEED   = 0.35
local PLANET_SPEED = 0.16
local PORTAL_SPEED = 0.22

local rigs = {}
local dirty = {}
local base = setmetatable({}, { __mode = "k" })
local clock = 0

local function baseOf(p)
	local cf = base[p]
	if not cf then
		cf = p.CFrame
		base[p] = cf
	end
	return cf
end

local function centroid(parts)
	local sum = Vector3.zero
	for _, p in ipairs(parts) do sum += baseOf(p).Position end
	return sum / #parts
end

local function planeNormal(parts, c)
	local v1 = (baseOf(parts[1]).Position - c)
	if v1.Magnitude < 1e-4 then v1 = Vector3.new(1, 0, 0) end
	v1 = v1.Unit
	local best, bestMag = nil, 0
	for i = 2, #parts do
		local v = baseOf(parts[i]).Position - c
		if v.Magnitude > 1e-4 then
			local cr = v1:Cross(v.Unit)
			if cr.Magnitude > bestMag then best, bestMag = cr, cr.Magnitude end
		end
	end
	if not best or bestMag < 1e-3 then return Vector3.yAxis end
	return best.Unit
end

local function snapshot(parts)
	local t = {}
	for _, p in ipairs(parts) do table.insert(t, {part = p, cf = baseOf(p)}) end
	return t
end

local function collect(model, ringMatch, bodyMatch, ringSpeed, bodySpeed)
	local ring, body = {}, {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			local n = d.Name:lower()
			if n:find(ringMatch, 1, true) then table.insert(ring, d)
			elseif bodyMatch and n:find(bodyMatch, 1, true) then table.insert(body, d) end
		end
	end
	if #ring < 3 then return end
	local c = centroid(ring)
	local axis = planeNormal(ring, c)
	local rig = {
		ringPivot = c, axis = axis, ring = snapshot(ring),
		ringSpeed = ringSpeed, bodySpeed = bodySpeed,
	}
	if #body > 0 then
		rig.bodyPivot = centroid(body)
		rig.body = snapshot(body)
	end
	return rig
end

local function build(m)
	rigs[m] = nil
	if not m:IsDescendantOf(workspace) then return end
	if m.Name == "RingedPlanet" then
		rigs[m] = collect(m, "ring_block", "planet", RING_SPEED, PLANET_SPEED)
	elseif m.Name == "Portal" then
		rigs[m] = collect(m, "ring_segment", nil, PORTAL_SPEED, 0)
	end
end

local function isRig(m)
	return m and m:IsA("Model") and (m.Name == "RingedPlanet" or m.Name == "Portal")
end

local function mark(d)
	if isRig(d) then
		dirty[d] = true
	elseif d:IsA("BasePart") then
		local m = d:FindFirstAncestor("RingedPlanet") or d:FindFirstAncestor("Portal")
		if isRig(m) then dirty[m] = true end
	end
end

local zones = workspace:WaitForChild("GameWorld"):WaitForChild("Zones")
for _, d in ipairs(zones:GetDescendants()) do mark(d) end
zones.DescendantAdded:Connect(mark)
zones.DescendantRemoving:Connect(mark)

local function spin(parts, pivot, axis, angle)
	local r = CFrame.fromAxisAngle(axis, angle)
	local toWorld = CFrame.new(pivot) * r * CFrame.new(-pivot)
	local stale = false
	for _, e in ipairs(parts) do
		if e.part.Parent then
			e.part.CFrame = toWorld * e.cf
		else
			stale = true
		end
	end
	return stale
end

RunService.Heartbeat:Connect(function(dt)
	clock += dt
	for m in pairs(dirty) do
		dirty[m] = nil
		build(m)
	end
	for m, rig in pairs(rigs) do
		if m:IsDescendantOf(workspace) then
			local stale = spin(rig.ring, rig.ringPivot, rig.axis, clock * rig.ringSpeed)
			if rig.body and spin(rig.body, rig.bodyPivot, rig.axis, clock * rig.bodySpeed) then
				stale = true
			end
			if stale then dirty[m] = true end
		else
			rigs[m] = nil
		end
	end
end)