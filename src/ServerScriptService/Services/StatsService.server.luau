local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)
local Cfg = require(game.ReplicatedStorage:WaitForChild("EggConfig"))

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStores.Profile)
	end)
	store = ok and result or nil
end

local LEADER = { Coins = Cfg.COINS_START or 0 }
local STATS = { RobuxSpent = 0, Playtime = 0, Rebirths = 0 }
local DEFAULT_SETTINGS = Config.DefaultSettings
local SESSION_TTL = 90
local AUTOSAVE_EVERY = 60
local PLAYTIME_TICK = 15

local profiles = {}

local Profile = {}
_G.Profile = Profile

function Profile.get(player)
	return profiles[player]
end

function Profile.value(player, folder, key)
	local f = player:FindFirstChild(folder)
	local v = f and f:FindFirstChild(key)
	return v and v.Value or 0
end

function Profile.set(player, key, amount)
	for _, folder in ipairs({ "wallet", "stats" }) do
		local f = player:FindFirstChild(folder)
		local v = f and f:FindFirstChild(key)
		if v then
			amount = tonumber(amount) or 0
			if amount ~= amount then amount = 0 end
			v.Value = math.clamp(math.floor(amount), 0, 9e18)
			return v.Value
		end
	end
	return nil
end

local function build(player, saved)
	local wallet = player:FindFirstChild("wallet")
	if not wallet then
		wallet = Instance.new("Folder")
		wallet.Name = "wallet"
		wallet.Parent = player
	end
	for key, fallback in pairs(LEADER) do
		local v = wallet:FindFirstChild(key)
		if not v then
			v = Instance.new("IntValue")
			v.Name = key
			v.Parent = wallet
		end
		v.Value = tonumber(saved[key]) or fallback
	end

	local stats = player:FindFirstChild("stats")
	if not stats then
		stats = Instance.new("Folder")
		stats.Name = "stats"
		stats.Parent = player
	end
	for key, fallback in pairs(STATS) do
		local v = stats:FindFirstChild(key)
		if not v then
			v = Instance.new("IntValue")
			v.Name = key
			v.Parent = stats
		end
		v.Value = tonumber(saved[key]) or fallback
	end

	player:SetAttribute("Speed", math.max(tonumber(saved.Speed) or Cfg.SPEED_START or 1, 1))
end

local function snapshot(player)
	local out = {}
	for key in pairs(LEADER) do out[key] = Profile.value(player, "wallet", key) end
	for key in pairs(STATS) do out[key] = Profile.value(player, "stats", key) end
	local profile = profiles[player]
	if profile then
		out.Settings = profile.Settings
		out.FreeRewardClaimed = profile.FreeRewardClaimed
		out.Eggs = profile.Eggs
		out.SpeedMult = profile.SpeedMult
		out.Speed = tonumber(player:GetAttribute("Speed")) or Cfg.SPEED_START or 1
		out.PetIndex = profile.PetIndex
		out.IndexClaimed = profile.IndexClaimed
        out.BatEquipped = profile.BatEquipped or 0
		out.BatForced = profile.BatForced
		out.IndexBackup = profile.IndexBackup
		out.NestEggs = profile.NestEggs
		out.NestAnimals = profile.NestAnimals
		out.TrailsOwned = profile.TrailsOwned
		out.TrailEquipped = profile.TrailEquipped
		out.PetInventory = profile.PetInventory
		out.PlotLevel = profile.PlotLevel
		out.MillLevel = profile.MillLevel
		out.BagState = profile.BagState
		out.Receipts = profile.Receipts
		out.GiftedPasses = profile.GiftedPasses
	end
	return out
end

local function lockedByOther(old)
	return type(old) == "table" and type(old.SessionJob) == "string"
		and old.SessionJob ~= game.JobId
		and os.time() - (tonumber(old.SessionAt) or 0) < SESSION_TTL
end

local saveSeq = {}
local leaving = {}

function Profile.save(player, release)
	if not store then return false end
	if not profiles[player] then return false end
	if leaving[player] and not release then return false end
	local data = snapshot(player)
	local key = "p_" .. player.UserId
	local seq = (saveSeq[player] or 0) + 1
	saveSeq[player] = seq
	for attempt = 1, 3 do
		if saveSeq[player] ~= seq then return false end
		local wrote, stale = false, false
		local ok, err = pcall(function()
			store:UpdateAsync(key, function(old)
				if saveSeq[player] ~= seq then
					wrote, stale = false, true
					return nil
				end
				if lockedByOther(old) then
					wrote = false
					return nil
				end
				data.SessionJob = (not release) and game.JobId or nil
				data.SessionAt = os.time()
				wrote = true
				return data
			end)
		end)
		if ok then
			if not wrote and not stale then
				warn(("[Profile] save skipped for %s: session locked by another server"):format(player.Name))
			end
			return wrote
		end
		warn(("[Profile] save %d/3 failed for %s: %s"):format(attempt, player.Name, tostring(err)))
		if attempt < 3 then task.wait(attempt * 2) end
	end
	return false
end

local loaded = Instance.new("BindableEvent")
loaded.Name = "ProfileLoaded"
Profile.Loaded = loaded.Event

local function load(player)
	local saved = {}
	if store then
		local key = "p_" .. player.UserId
		local loadedOk = false
		for attempt = 1, 32 do
			local busy = false
			local ok, result = pcall(function()
				return store:UpdateAsync(key, function(old)
					if lockedByOther(old) then
						busy = true
						return nil
					end
					old = type(old) == "table" and old or {}
					old.SessionJob = game.JobId
					old.SessionAt = os.time()
					return old
				end)
			end)
			if ok and not busy then
				if type(result) == "table" then saved = result end
				loadedOk = true
				break
			end
			if not ok then
				warn("[Profile] load failed for " .. player.Name .. ": " .. tostring(result))
				if RunService:IsStudio() and tostring(result):find("403", 1, true) then break end
			end
			if not player.Parent then return end
			task.wait(3)
		end
		if not loadedOk and RunService:IsStudio() then
			warn("[Profile] DataStores unavailable in Studio (Game Settings > Security > Enable Studio Access to API Services). Using a fresh profile that will not be saved.")
			store = nil
			loadedOk = true
		end
		if not loadedOk then
			player:Kick("Could not load your data. Please rejoin in a minute.")
			return
		end
		if not player.Parent then
			pcall(function()
				store:UpdateAsync(key, function(old)
					if type(old) == "table" and old.SessionJob == game.JobId then
						old.SessionJob = nil
						return old
					end
					return nil
				end)
			end)
			return
		end
	end

	local settings = {}
	for key, value in pairs(DEFAULT_SETTINGS) do settings[key] = value end
	if type(saved.Settings) == "table" then
		for key, value in pairs(saved.Settings) do
			if settings[key] ~= nil and type(value) == type(settings[key]) then
				settings[key] = value
			end
		end
	end

	profiles[player] = {
		Settings = settings,
		FreeRewardClaimed = saved.FreeRewardClaimed == true,
		Eggs = type(saved.Eggs) == "table" and saved.Eggs or {},
		SpeedMult = tonumber(saved.SpeedMult) or 1,
		NestEggs = type(saved.NestEggs) == "table" and saved.NestEggs or {},
		NestAnimals = type(saved.NestAnimals) == "table" and saved.NestAnimals or {},
		PetIndex = type(saved.PetIndex) == "table" and saved.PetIndex or {},
		IndexClaimed = type(saved.IndexClaimed) == "table" and saved.IndexClaimed or {},
        BatEquipped = tonumber(saved.BatEquipped) or 0,
		BatForced = tonumber(saved.BatForced),
		IndexBackup = type(saved.IndexBackup) == "table" and saved.IndexBackup or nil,
		TrailsOwned = type(saved.TrailsOwned) == "table" and saved.TrailsOwned or {},
		TrailEquipped = type(saved.TrailEquipped) == "string" and saved.TrailEquipped or "",
		PetInventory = type(saved.PetInventory) == "table" and saved.PetInventory or {},
		PlotLevel = tonumber(saved.PlotLevel) or 1,
		MillLevel = tonumber(saved.MillLevel) or 1,
		BagState = type(saved.BagState) == "table" and saved.BagState or nil,
		Receipts = type(saved.Receipts) == "table" and saved.Receipts or {},
		GiftedPasses = type(saved.GiftedPasses) == "table" and saved.GiftedPasses or {},
	}
	build(player, saved)
	loaded:Fire(player)
end

task.spawn(function()
	while true do
		task.wait(PLAYTIME_TICK)
		for _, player in ipairs(Players:GetPlayers()) do
			if profiles[player] then
				Profile.set(player, "Playtime", (Profile.value(player, "stats", "Playtime") or 0) + PLAYTIME_TICK)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(player)
	load(player)
end)
Players.PlayerRemoving:Connect(function(player)
	leaving[player] = true
	Profile.save(player, true)
	profiles[player] = nil
	saveSeq[player] = nil
	leaving[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(load, player)
end

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_EVERY)
		for player in pairs(profiles) do
			if player.Parent and not leaving[player] then
				task.spawn(Profile.save, player)
			end
		end
	end
end)

game:BindToClose(function()
	if RunService:IsStudio() then return end
	local pending = 0
	for player in pairs(profiles) do
		if not leaving[player] then
			pending += 1
			task.spawn(function()
				Profile.save(player, true)
				pending -= 1
			end)
		end
	end
	local deadline = os.clock() + 25
	while (pending > 0 or next(leaving)) and os.clock() < deadline do
		task.wait(0.25)
	end
end)