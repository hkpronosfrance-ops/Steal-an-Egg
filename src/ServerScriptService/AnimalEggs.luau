local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RARITY = require(ReplicatedStorage:WaitForChild("AnimalRarity"))

local M = {}
M.RARITY = RARITY

local folder = ServerStorage:WaitForChild("EggAssets"):WaitForChild("AnimalEggs")
local rng = Random.new()

function M.tierOf(species)
	return species and RARITY[species] or nil
end

function M.template(species)
	return species and folder:FindFirstChild(species) or nil
end

local function speciesOf(zone)
	local names, seen = {}, {}
	local lib = workspace:FindFirstChild("AnimalLibrary")
	local set = lib and lib:FindFirstChild("Zone" .. tostring(zone))
	if set then
		for _, m in ipairs(set:GetChildren()) do
			if not seen[m.Name] then seen[m.Name] = true table.insert(names, m.Name) end
		end
	end
	for _, t in ipairs(folder:GetChildren()) do
		if t:GetAttribute("Zone") == zone and not seen[t.Name] then
			seen[t.Name] = true
			table.insert(names, t.Name)
		end
	end
	return names
end
M.speciesOf = speciesOf

function M.pick(zone, tier)
	local all = speciesOf(zone)
	local list = {}
	for _, name in ipairs(all) do
		if RARITY[name] == tier then table.insert(list, name) end
	end
	if #list == 0 then list = all end
	if #list == 0 then return nil end
	return list[rng:NextInteger(1, #list)]
end

function M.legacy(zone, tier, size)
	local lib = workspace:FindFirstChild("AnimalLibrary")
	local set = lib and lib:FindFirstChild("Zone" .. tostring(zone))
	if not set then return nil end
	local list = set:GetChildren()
	table.sort(list, function(a, b) return a.Name < b.Name end)
	if #list == 0 then return nil end
	local slot = (tier or 1) >= 3 and 6 + ((tier or 3) - 2) or math.clamp(size or 1, 1, 6)
	return list[((slot - 1) % #list) + 1].Name
end

return M