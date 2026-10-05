local Bats=require(game.ServerScriptService:WaitForChild("BatService"))
Bats.init()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("EggConfig"))

local ZONES = Cfg.ZONES
local PER_ZONE = 8

local remotes = RS:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("PetIndex")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "PetIndex"
	remote.Parent = remotes
end

local function speciesNames(zone)
	local lib = workspace:FindFirstChild("AnimalLibrary")
	local folder = lib and lib:FindFirstChild("Zone" .. zone)
	local names = {}
	if folder then
		local kids = folder:GetChildren()
		table.sort(kids, function(a, b) return a.Name < b.Name end)
		for i, m in ipairs(kids) do
			if i > PER_ZONE then break end
			names[i] = m.Name
		end
	end
	return names
end

local RARITY = require(RS:WaitForChild("AnimalRarity"))

local function tierFor(zone, slot)
	local name = speciesNames(zone)[slot]
	return (name and RARITY[name]) or ((slot == 8) and 4 or (slot == 7) and 3 or 1)
end

local function slotInfo(zone, slot)
	local name = speciesNames(zone)[slot]
	local tier = tierFor(zone, slot)
	local tierName = Cfg.TIERS[tier] and Cfg.TIERS[tier].name or "Common"
	return {
		tier = tier,
		rarity = tierName,
		source = (name or tierName) .. " eggs",
		income = Cfg.animalIncome(zone, 3, tier),
	}
end

local IDX = Cfg.INDEX or {}

local function rewardFor(zone)
	local money = math.floor(Cfg.animalIncome(zone, IDX.MONEY_SIZE or 3, IDX.MONEY_TIER or 2) * (IDX.MONEY_SECONDS or 120))
	local nextNeed = Cfg.POWER_N and Cfg.POWER_N[zone + 1]
	local speed
	if nextNeed then
		speed = nextNeed * (IDX.SPEED_NEXT_ZONE_SHARE or 0.5)
	else
		speed = ((Cfg.POWER_N and Cfg.POWER_N[zone]) or 1) * (IDX.SPEED_LAST_ZONE_MULT or 2)
	end
	speed = math.floor(math.min(math.max(speed, 1), Cfg.SPEED_MAX))
	return money, speed
end

local function slotReward(zone, slot)
	local money, speed = rewardFor(zone)
	local TIER_MULT = { 1, 1.5, 3, 5 }
	local k = (TIER_MULT[tierFor(zone, slot)] or 1) / (IDX.SLOT_DIVISOR or 4)
	return math.max(1, math.floor(money * k)), math.max(1, math.floor(speed * k))
end

local function profileOf(plr)
	local P = _G.Profile
	local prof = P and P.get(plr)
	if not prof then return nil end
	if type(prof.PetIndex) ~= "table" then prof.PetIndex = {} end
	if type(prof.IndexClaimed) ~= "table" then prof.IndexClaimed = {} end
	return prof
end

local function key(zone, slot) return zone .. "_" .. slot end

local function listHas(list, value)
	for _, v in ipairs(list) do
		if v == value then return true end
	end
	return false
end

local function buildState(plr)
	local prof = profileOf(plr)
	if not prof then return nil end
	local found = {}
	for _, k in ipairs(prof.PetIndex) do found[k] = true end
	local took = {}
	for _, k in ipairs(prof.IndexClaimed) do
		if type(k) == "string" then took[k] = true end
	end

	local zones, total, readyAll = {}, 0, 0
	for zone = 1, ZONES do
		local names = speciesNames(zone)
		local slots, count, ready = {}, 0, 0
		for slot = 1, PER_ZONE do
			local info = slotInfo(zone, slot)
			local got = found[key(zone, slot)] == true
			local claimed = took[key(zone, slot)] == true
			if got then count += 1 end
			if got and not claimed then ready += 1 end
			local money, speed = slotReward(zone, slot)
			slots[slot] = {
				name = names[slot] or "?",
				found = got,
				claimed = claimed,
				tier = info.tier,
				rarity = info.rarity,
				source = info.source,
				income = info.income,
				money = money,
				speed = speed,
			}
		end
		total += count
		readyAll += ready
		zones[zone] = {
			name = Cfg.NAMES[zone] or ("Zone " .. zone),
			slots = slots,
			count = count,
			ready = ready,
		}
	end
	return { zones = zones, total = total, max = ZONES * PER_ZONE, ready = readyAll, equippedBat = Bats.equipped(plr) }
end

local function push(plr)
	local s = buildState(plr)
	if s then remote:FireClient(plr, "state", s) end
end

local function discover(plr, zone, slot, silent)
	zone, slot = tonumber(zone), tonumber(slot)
	if not zone or not slot then return false end
	if zone < 1 or zone > ZONES or slot < 1 or slot > PER_ZONE then return false end
	local prof = profileOf(plr)
	if not prof then return false end
	local k = key(zone, slot)
	if listHas(prof.PetIndex, k) then return false end
	table.insert(prof.PetIndex, k)
	if not silent then
		local names = speciesNames(zone)
		remote:FireClient(plr, "found", {
			zone = zone, slot = slot, name = names[slot] or "?",
			complete = (function()
				for s = 1, PER_ZONE do
					if not listHas(prof.PetIndex, key(zone, s)) then return false end
				end
				return true
			end)(),
		})
		push(plr)
	end
	return true
end

local ANIMAL_SLOT = function(size, tier)
	if (tier or 1) >= 3 then return 6 + ((tier or 3) - 2) end
	return math.clamp(size or 1, 1, 6)
end

local function slotOfSpecies(zone, sp)
	if type(sp) ~= "string" then return nil end
	for i, n in ipairs(speciesNames(zone)) do
		if n == sp then return i end
	end
	return nil
end

local function backfill(plr)
	local prof
	for _ = 1, 120 do
		prof = profileOf(plr)
		if prof or not plr.Parent then break end
		task.wait(0.5)
	end
	if not prof then return end
	local added = 0
	if type(prof.NestAnimals) == "table" then
		for _, e in ipairs(prof.NestAnimals) do
			local zone = tonumber(e.zone)
			if zone and discover(plr, zone, slotOfSpecies(zone, e.species) or ANIMAL_SLOT(tonumber(e.size), tonumber(e.tier)), true) then
				added += 1
			end
		end
	end
	task.wait(6)
	local bag = plr:FindFirstChildOfClass("Backpack")
	if bag then
		for _, t in ipairs(bag:GetChildren()) do
			local zone = tonumber(t:GetAttribute("AnimalZone"))
			if zone and discover(plr, zone, slotOfSpecies(zone, t:GetAttribute("Species")) or
				ANIMAL_SLOT(tonumber(t:GetAttribute("AnimalSize")), tonumber(t:GetAttribute("AnimalTier"))), true) then
				added += 1
			end
		end
	end
	if added > 0 then push(plr) end
end

local busy = {}

local function claim(plr, zone, slot)
	zone, slot = tonumber(zone), tonumber(slot)
	if not zone or zone < 1 or zone > ZONES then return end
	if not slot or slot < 1 or slot > PER_ZONE then return end
	if busy[plr] then return end
	busy[plr] = true

	local prof = profileOf(plr)
	local k = key(zone, slot)
	local ok, why = false, nil
	if not prof then
		why = "Profile not loaded yet"
	elseif listHas(prof.IndexClaimed, k) then
		why = "Already claimed"
	elseif not listHas(prof.PetIndex, k) then
		why = "Hatch this pet first"
	else
		local money, speed = slotReward(zone, slot)
		local P = _G.Profile
		local have = P.value(plr, "wallet", "Coins") or 0
		P.set(plr, "Coins", have + money)
		local cur = tonumber(plr:GetAttribute("Speed")) or Cfg.SPEED_START
		plr:SetAttribute("Speed", math.min(cur + speed, Cfg.SPEED_MAX))
		table.insert(prof.IndexClaimed, k)
		local names = speciesNames(zone)
		remote:FireClient(plr, "claimed", {
			zone = zone, slot = slot, name = names[slot] or "?", money = money, speed = speed,
		})
		ok = true
	end
	if not ok and why then remote:FireClient(plr, "deny", why) end
	push(plr)
	task.delay(0.4, function() busy[plr] = nil end)
end

local function claimAll(plr)
	if busy[plr] then return end
	busy[plr] = true
	local prof = profileOf(plr)
	if not prof then
		remote:FireClient(plr, "deny", "Profile not loaded yet")
		task.delay(0.4, function() busy[plr] = nil end)
		return
	end

	local took = {}
	for _, k in ipairs(prof.IndexClaimed) do took[k] = true end
	local money, speed, n = 0, 0, 0
	for _, k in ipairs(prof.PetIndex) do
		if type(k) == "string" and not took[k] then
			local z, s = k:match("^(%d+)_(%d+)$")
			z, s = tonumber(z), tonumber(s)
			if z and s and z >= 1 and z <= ZONES and s >= 1 and s <= PER_ZONE then
				local m, sp = slotReward(z, s)
				money += m
				speed += sp
				n += 1
				table.insert(prof.IndexClaimed, k)
				took[k] = true
			end
		end
	end

	if n > 0 then
		local P = _G.Profile
		local have = P.value(plr, "wallet", "Coins") or 0
		P.set(plr, "Coins", have + money)
		local cur = tonumber(plr:GetAttribute("Speed")) or Cfg.SPEED_START
		plr:SetAttribute("Speed", math.min(cur + speed, Cfg.SPEED_MAX))
		remote:FireClient(plr, "claimedAll", { count = n, money = money, speed = speed })
	else
		remote:FireClient(plr, "deny", "Nothing to claim")
	end
	push(plr)
	task.delay(0.4, function() busy[plr] = nil end)
end

remote.OnServerEvent:Connect(function(plr, action, arg, arg2)
	if action == "equipBat" then
        if not Bats.equip(plr, arg) then remote:FireClient(plr,"deny","Collect all 8 pets in this zone to unlock its bat") end
        push(plr)
    elseif action == "state" then
		if busy[plr] then return end
		busy[plr] = true
		push(plr)
		task.delay(0.4, function() busy[plr] = nil end)
	elseif action == "claim" then
		claim(plr, arg, arg2)
	elseif action == "claimAll" then
		claimAll(plr)
	end
end)

Players.PlayerAdded:Connect(function(plr) task.spawn(backfill, plr) end)
for _, plr in ipairs(Players:GetPlayers()) do task.spawn(backfill, plr) end
Players.PlayerRemoving:Connect(function(plr) busy[plr] = nil end)

_G.PetIndex = {
	discover = discover,
	slotOf = ANIMAL_SLOT,
	rewardFor = rewardFor,
	slotReward = slotReward,
}

local m1, s1 = slotReward(1, 1)
local m12, s12 = slotReward(ZONES, 8)
print(("[Index] %d zones x %d species, reward for each | zone 1 Tiny: $%s + %s speed | zone %d Legendary: $%s + %s speed")
	:format(ZONES, PER_ZONE, Cfg.fmtSpeed(m1), Cfg.fmtSpeed(s1), ZONES, Cfg.fmtSpeed(m12), Cfg.fmtSpeed(s12)))