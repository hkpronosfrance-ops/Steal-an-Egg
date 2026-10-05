local ServerStorage = game:GetService("ServerStorage")
local BossAnim = require(game:GetService("ReplicatedStorage"):WaitForChild("BossAnim"))

local T = {}

local RARITY_NAMES = { "Common", "Uncommon", "Rare", "Legendary" }
local RARITY_WANT = { 4, 2, 1, 1 }
local BY_NAME = { common = 1, uncommon = 2, rare = 3, legendary = 4 }

local function say(...)
	print("[ZoneTools]", ...)
end

local function rarityOf(m)
	local v = m:GetAttribute("Rarity")
	if type(v) == "number" then return math.clamp(math.floor(v), 1, 4) end
	if type(v) == "string" then return BY_NAME[v:lower()] end
	return nil
end

local function hasPart(inst)
	return inst:IsA("BasePart") or inst:FindFirstChildWhichIsA("BasePart", true) ~= nil
end

function T.Check()
	local problems = {}
	local function bad(msg) table.insert(problems, msg) end
	local loader = require(ServerStorage.ZoneLoader:Clone())
	local sources, nextFree = loader.sources(bad)
	local speciesZone = {}

	for n, src in ipairs(sources) do
		local label = ("World %d (%s)"):format(n, src.Name)
		local boss = src:FindFirstChild("Boss")
		if not (boss and hasPart(boss)) then
			bad(label .. ": no Boss model yet - the previous world's boss will be used")
		else
			local anims = BossAnim.animations(boss) or {}
			local embedded = BossAnim.embedded(boss) or {}
			for name, k in pairs(embedded) do anims[name] = anims[name] or k end
			if next(anims) == nil then
				bad(label .. ": the Boss has no animations - save Idle, Run, Attack, Sleep, Wake in Animation Editor or add their ids as attributes")
			else
				for _, name in ipairs({ "Idle", "Run", "Attack", "Sleep", "Wake" }) do
					if not anims[name] then bad(label .. ": the Boss has no " .. name .. " animation") end
				end
				if not boss:FindFirstChildWhichIsA("Motor6D", true) then
					bad(label .. ": the Boss has animations but no Motor6D joints - rig it first")
				else
					local root = BossAnim.animRoot(boss)
					if boss.PrimaryPart and boss.PrimaryPart ~= root then
						bad(label .. ": the Boss PrimaryPart should be its root part (" .. tostring(root and root.Name) .. ")")
					end
					local links = {}
					local function link(a, b)
						if a and b then
							links[a] = links[a] or {}
							links[b] = links[b] or {}
							table.insert(links[a], b)
							table.insert(links[b], a)
						end
					end
					for _, j in ipairs(boss:GetDescendants()) do
						if j:IsA("JointInstance") then link(j.Part0, j.Part1)
						elseif j:IsA("WeldConstraint") then link(j.Part0, j.Part1) end
					end
					local seen, queue = { [root] = true }, { root }
					while #queue > 0 do
						local p = table.remove(queue)
						for _, q in ipairs(links[p] or {}) do
							if not seen[q] then seen[q] = true table.insert(queue, q) end
						end
					end
					local loose = 0
					for _, p in ipairs(boss:GetDescendants()) do
						if p:IsA("BasePart") and not seen[p] then loose += 1 end
					end
					if loose > 0 then
						bad(("%s: %d Boss parts are not joined to the skeleton - weld them, or they fall through the map"):format(label, loose))
					end
				end
			end
		end
		local animals = src:FindFirstChild("Animals")
		local list = animals and animals:GetChildren() or {}
		local count = { 0, 0, 0, 0 }
		for _, m in ipairs(list) do
			if speciesZone[m.Name] then
				bad(("%s: animal name \"%s\" is also used in world %d - every animal needs its own name"):format(label, m.Name, speciesZone[m.Name]))
			end
			speciesZone[m.Name] = n
			if not hasPart(m) then bad(label .. ": " .. m.Name .. " has no parts") end
			local t = rarityOf(m)
			if t then count[t] += 1 else bad(label .. ": " .. m.Name .. " has no Rarity attribute (Common / Uncommon / Rare / Legendary)") end
		end
		if #list == 0 then
			bad(label .. ": no animals in the Animals folder")
		elseif #list ~= 8 then
			bad(("%s: %d animals - the index and the world's bat need exactly 8"):format(label, #list))
		end
		for t = 1, 4 do
			if #list > 0 and count[t] ~= RARITY_WANT[t] then
				bad(("%s: %d %s animals (recommended %d)"):format(label, count[t], RARITY_NAMES[t], RARITY_WANT[t]))
			end
		end
		local eggs = src:FindFirstChild("Eggs")
		for _, e in ipairs(eggs and eggs:GetChildren() or {}) do
			if not (animals and animals:FindFirstChild(e.Name)) then
				bad(label .. ": egg \"" .. e.Name .. "\" has no animal with the same name")
			elseif not hasPart(e) then
				bad(label .. ": egg \"" .. e.Name .. "\" has no parts")
			end
		end
	end

	say(("%d worlds found. A new world gets Zone = %d."):format(#sources, nextFree or (#sources + 1)))
	if #problems == 0 then
		say("Everything looks good.")
	else
		for _, p in ipairs(problems) do warn("[ZoneTools] " .. p) end
		say(("%d thing(s) to fix, see the warnings above."):format(#problems))
	end
	return #problems == 0
end

return T