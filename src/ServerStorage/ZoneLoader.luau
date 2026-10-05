local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

local M = {}

function M.folder()
	return ServerStorage:FindFirstChild("Zones")
end

local function mapSuffix(n)
	local map = workspace:FindFirstChild("GameWorld")
	local zones = map and map:FindFirstChild("Zones")
	for _, z in ipairs(zones and zones:GetChildren() or {}) do
		local s = z.Name:match("^Zone" .. n .. "_(.+)$")
		if s then return s end
	end
	return nil
end

function M.sources(report)
	report = report or function(msg) warn("[Zones] " .. msg) end
	local folder = M.folder()
	if not folder then return {} end
	local byZone = {}
	for _, f in ipairs(folder:GetChildren()) do
		if f:IsA("Folder") or f:IsA("Model") or f:IsA("Configuration") then
			local z = tonumber(f:GetAttribute("Zone"))
			if not z or z < 1 or z ~= math.floor(z) then
				report(("%s is skipped: give it the attribute Zone = its world number"):format(f.Name))
			else
				byZone[z] = byZone[z] or {}
				table.insert(byZone[z], f)
			end
		end
	end
	local ordered = {}
	local n = 1
	while byZone[n] do
		local list = byZone[n]
		local pick = list[1]
		if #list > 1 then
			local suffix = mapSuffix(n)
			for _, f in ipairs(list) do
				if suffix and (f.Name:gsub("[^%w]", "")):lower() == suffix:lower() then pick = f break end
			end
			for _, f in ipairs(list) do
				if f ~= pick then
					report(("%s is skipped: Zone %d is already %s - set its Zone to a free number"):format(f.Name, n, pick.Name))
				end
			end
		end
		table.insert(ordered, pick)
		byZone[n] = nil
		n += 1
	end
	for z, list in pairs(byZone) do
		for _, f in ipairs(list) do
			report(("%s is skipped: Zone %d leaves a gap - worlds must be numbered 1, 2, 3 ... without gaps (next free: %d)"):format(f.Name, z, n))
		end
	end
	return ordered, n
end

function M.extend(list)
	local rows = {}
	for _, src in ipairs(M.sources()) do
		local n = #list + 1
		local p1, p2 = tonumber(list[n - 1] and list[n - 1].power), tonumber(list[n - 2] and list[n - 2].power)
		local power = tonumber(src:GetAttribute("Power"))
		if not power or power <= 0 or (p1 and power <= p1) then
			power = p1 and p1 * math.clamp((p2 and p2 > 0) and p1 / p2 or 10, 4, 40) or 0.45
		end
		local color = src:GetAttribute("Color")
		if typeof(color) ~= "Color3" then color = Color3.fromHSV((n * 0.137) % 1, 0.55, 0.92) end
		local emoji = src:GetAttribute("Emoji")
		local row = {
			name = src.Name, emoji = type(emoji) == "string" and emoji or "",
			color = color, power = power, source = src,
		}
		list[n] = row
		table.insert(rows, { index = n, row = row })
	end
	if RunService:IsRunning() then
		local reg = ReplicatedStorage:FindFirstChild("ZoneRegistry")
		if reg then reg:Destroy() end
		reg = Instance.new("Folder")
		reg.Name = "ZoneRegistry"
		for _, e in ipairs(rows) do
			local c = Instance.new("Configuration")
			c.Name = tostring(e.index)
			c:SetAttribute("Index", e.index)
			c:SetAttribute("Name", e.row.name)
			c:SetAttribute("Emoji", e.row.emoji)
			c:SetAttribute("Color", e.row.color)
			c:SetAttribute("Power", e.row.power)
			c.Parent = reg
		end
		reg.Parent = ReplicatedStorage
	end
end

local function near(a, b, tol) return math.abs(a - b) <= (tol or 0.6) end

local function shortPower(v)
	if v < 1 then return "" end
	local units = { "", "K", "M", "B", "T", "Qa", "Qi" }
	local i = 1
	while v >= 1000 and i < #units do v = v / 1000; i += 1 end
	return string.format("%g", math.floor(v * 10 + 0.5) / 10) .. units[i]
end

local function largestPart(model)
	local best, size = nil, -1
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			local v = p.Size.X * p.Size.Y * p.Size.Z
			if v > size then best, size = p, v end
		end
	end
	return best
end

local function bodyPart(model)
	for _, name in ipairs({ "HumanoidRootPart", "Handle", "RootPart", "Torso", "Body" }) do
		local p = model:FindFirstChild(name, true)
		if p and p:IsA("BasePart") then return p end
	end
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and (p.Name:lower():find("body") or p.Name:lower():find("torso")) then return p end
	end
	return largestPart(model)
end

local function anchorAll(model, collide)
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") then
			p.Anchored = true
			if collide == false then p.CanCollide = false end
		end
	end
end

local function asModel(inst)
	if inst:IsA("Model") then return inst end
	if inst:IsA("BasePart") then
		local m = Instance.new("Model")
		m.Name = inst.Name
		local parent = inst.Parent
		inst.Parent = m
		m.PrimaryPart = inst
		m.Parent = parent
		return m
	end
	local m = Instance.new("Model")
	m.Name = inst.Name
	for _, c in ipairs(inst:GetChildren()) do c.Parent = m end
	inst:Destroy()
	return m
end

local built = false

function M.build(C)
	if built or not (RunService:IsServer() and RunService:IsRunning()) then return end
	built = true
	local map = workspace:FindFirstChild("GameWorld")
	local assets = ServerStorage:FindFirstChild("EggAssets")
	if not (map and assets) then return end
	local zones, walls, spawns = map:FindFirstChild("Zones"), map:FindFirstChild("Walls"), map:FindFirstChild("EggSpawns")
	local bosses, eggSet, animalEggs = assets:FindFirstChild("Bosses"), assets:FindFirstChild("Eggs"), assets:FindFirstChild("AnimalEggs")
	local lib = workspace:FindFirstChild("AnimalLibrary")
	if not lib then
		lib = Instance.new("Model")
		lib.Name = "AnimalLibrary"
		lib.Parent = workspace
	end

	local function byPrefix(parent, n)
		if not parent then return nil end
		for _, z in ipairs(parent:GetChildren()) do
			if z.Name:match("^Zone" .. n .. "_") then return z end
		end
		return nil
	end
	local function wallParts()
		local list = {}
		for _, p in ipairs(walls and walls:GetDescendants() or {}) do
			if p:IsA("BasePart") then table.insert(list, p) end
		end
		return list
	end

	local signTemplate
	for n = 1, C.ZONES do
		local f = byPrefix(zones, n)
		local s = f and f:FindFirstChild("Decor") and f.Decor:FindFirstChild("ZoneSign")
		if s then signTemplate = { model = s, zone = n } end
	end
	local slabTemplate = byPrefix(zones, 1)
	slabTemplate = slabTemplate and slabTemplate:FindFirstChild("Floor") and slabTemplate.Floor:FindFirstChild("FloorSlab")
	local libraryAt = lib:GetPivot().Position
	local speciesZone = {}

	local function buildWorld(n, row, src)
		local prev = n - 1
		local prevTop, prevBot = C.bounds(prev)
		local top, bot = C.bounds(n)
		local dz = top - prevTop
		local suffix = (row.name:gsub("[^%w]", ""))

		local folder = Instance.new("Folder")
		folder.Name = ("Zone%d_%s"):format(n, suffix)
		local floor = Instance.new("Model")
		floor.Name = "Floor"
		floor.Parent = folder
		local slab = slabTemplate and slabTemplate:Clone() or Instance.new("Part")
		slab.Name = "FloorSlab"
		slab.Anchored = true
		slab.Size = Vector3.new(C.X_MAX - C.X_MIN, 4, top - bot)
		slab.CFrame = CFrame.new(1500, -2, (top + bot) / 2)
		slab.Color = row.color
		slab.Parent = floor

		local decor = Instance.new("Model")
		decor.Name = "Decor"
		decor.Parent = folder
		if signTemplate then
			local sign = signTemplate.model:Clone()
			local sTop = C.bounds(signTemplate.zone)
			sign:PivotTo(sign:GetPivot() + Vector3.new(0, 0, top - sTop))
			for _, d in ipairs(sign:GetDescendants()) do
				if d:IsA("TextLabel") and d.Name == "Power" then d.Text = shortPower(row.power) end
			end
			sign.Parent = decor
		end
		local look = src:FindFirstChild("Map")
		if look and look:FindFirstChildWhichIsA("BasePart", true) then
			local m = asModel(look:Clone())
			local cf, size = m:GetBoundingBox()
			local target = Vector3.new(1500, size.Y / 2, (top + bot) / 2)
			m:PivotTo(m:GetPivot() + (target - cf.Position))
			anchorAll(m)
			m.Name = "Map"
			m.Parent = decor
		end
		folder.Parent = zones

		local dividers = zones:FindFirstChild("Dividers")
		local lastDivider = dividers and dividers:FindFirstChild(("Divider_%d_%d"):format(prev - 1, prev))
		if lastDivider then
			local d = lastDivider:Clone()
			d.Name = ("Divider_%d_%d"):format(prev, n)
			d.CFrame = d.CFrame + Vector3.new(0, 0, dz)
			d.Parent = dividers
		end

		for _, w in ipairs(wallParts()) do
			if w.Size.X > w.Size.Z and near(w.Position.Z, prevBot - w.Size.Z / 2) then
				w.CFrame = w.CFrame + Vector3.new(0, 0, bot - prevBot)
			elseif near(w.Size.Z, prevTop - prevBot) and near(w.Position.Z, (prevTop + prevBot) / 2) then
				local c = w:Clone()
				c.Size = Vector3.new(w.Size.X, w.Size.Y, top - bot)
				c.CFrame = CFrame.new(w.Position.X, w.Position.Y, (top + bot) / 2) * w.CFrame.Rotation
				c.Color = w.Name == "WallCap" and row.color or row.color:Lerp(Color3.new(0, 0, 0), 0.45)
				c.Parent = w.Parent
			end
		end

		local prevSpawns = byPrefix(spawns, prev)
		if prevSpawns then
			local s = prevSpawns:Clone()
			s.Name = ("Zone%d_%s"):format(n, suffix)
			for _, a in ipairs(s:GetChildren()) do
				if a:IsA("BasePart") then
					a.CFrame = a.CFrame + Vector3.new(0, 0, dz)
					a:SetAttribute("Zone", n)
					for _, c in ipairs(a:GetChildren()) do c:Destroy() end
				end
			end
			s.Parent = spawns
		end
	end

	local function loadAssets(n, src)
		if bosses then
			local bossSrc = src:FindFirstChild("Boss")
			local boss
			if bossSrc and (bossSrc:IsA("BasePart") or bossSrc:FindFirstChildWhichIsA("BasePart", true)) then
				boss = asModel(bossSrc)
			elseif bosses:FindFirstChild("Zone" .. (n - 1)) then
				boss = bosses["Zone" .. (n - 1)]:Clone()
			end
			if boss then
				local old = bosses:FindFirstChild("Zone" .. n)
				if old then old:Destroy() end
				boss.Name = "Zone" .. n
				local BossAnim = require(ReplicatedStorage:WaitForChild("BossAnim"))
				if BossAnim.animated(boss) then
					local root = BossAnim.animRoot(boss)
					for _, p in ipairs(boss:GetDescendants()) do
						if p:IsA("BasePart") then
							p.Anchored = p == root
							p.CanCollide = false
						end
					end
					if root and not boss.PrimaryPart then boss.PrimaryPart = root end
				else
					for _, j in ipairs(boss:GetDescendants()) do
						if j:IsA("JointInstance") or j:IsA("WeldConstraint") then j.Enabled = false end
					end
					anchorAll(boss)
				end
				boss.Parent = bosses
			end
		end

		if eggSet and not eggSet:FindFirstChild("Zone" .. n) then
			local e = eggSet:FindFirstChild("Zone" .. (n - 1)) or eggSet:FindFirstChild("Default")
			if e then
				e = e:Clone()
				e.Name = "Zone" .. n
				e.Parent = eggSet
			end
		end

		local set = lib:FindFirstChild("Zone" .. n)
		if not set then
			set = Instance.new("Folder")
			set.Name = "Zone" .. n
			set.Parent = lib
		end
		local mine = {}
		local animals = src:FindFirstChild("Animals")
		for i, a in ipairs(animals and animals:GetChildren() or {}) do
			if not (a:IsA("Model") or a:IsA("Folder") or a:IsA("BasePart")) then continue end
			if speciesZone[a.Name] then
				warn(("[Zones] %s: an animal called \"%s\" is already in zone %d - give it its own name"):format(src.Name, a.Name, speciesZone[a.Name]))
				continue
			end
			speciesZone[a.Name] = n
			mine[a.Name] = true
			local isNew = a:GetAttribute("Species") ~= a.Name or a:GetAttribute("Zone") ~= n
			local m = asModel(a)
			m:SetAttribute("Species", m.Name)
			m:SetAttribute("Zone", n)
			local root = m:GetAttribute("RootPart")
			if not (root and m:FindFirstChild(root, true)) then
				local p = m.PrimaryPart or bodyPart(m)
				if p then m:SetAttribute("RootPart", p.Name) end
			end
			if isNew then
				local _, size = m:GetBoundingBox()
				if size.Y > 6 or size.Y < 0.5 then m:ScaleTo(m:GetScale() * (2 / math.max(size.Y, 0.01))) end
				m:PivotTo(CFrame.new(libraryAt + Vector3.new(n * 30, 0, i * 8)))
			end
			anchorAll(m)
			m.Parent = set
		end

		local eggs = src:FindFirstChild("Eggs")
		if animalEggs and eggs then
			for _, e in ipairs(eggs:GetChildren()) do
				if not (e:IsA("Model") or e:IsA("Folder") or e:IsA("BasePart")) or not mine[e.Name] then continue end
				local m = asModel(e)
				local old = animalEggs:FindFirstChild(m.Name)
				if old then old:Destroy() end
				m:SetAttribute("Zone", n)
				m:SetAttribute("Species", m.Name)
				local shell = m:FindFirstChild("Shell", true)
				if not (shell and shell:IsA("BasePart")) then
					shell = m.PrimaryPart or largestPart(m)
					if shell and not shell.Name:lower():match("^shell") then shell.Name = "Shell" end
				end
				if shell and not m.PrimaryPart then m.PrimaryPart = shell end
				local _, size = m:GetBoundingBox()
				if size.Y > 0 and math.abs(size.Y - C.EGG_BASE_H) > 0.05 then m:ScaleTo(m:GetScale() * (C.EGG_BASE_H / size.Y)) end
				anchorAll(m, false)
				m.Parent = animalEggs
			end
		end
	end

	for n = 1, C.ZONES do
		local row = C.ZONE_LIST[n]
		local src = row and row.source
		if not src then continue end
		local ok, err = pcall(function()
			if zones and not byPrefix(zones, n) and n > 1 then buildWorld(n, row, src) end
			loadAssets(n, src)
		end)
		if not ok then warn(("[Zones] could not load zone %d (%s): %s"):format(n, tostring(row.name), tostring(err))) end
	end
end

return M