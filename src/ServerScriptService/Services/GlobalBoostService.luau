local DataStoreService = game:GetService("DataStoreService")
local MessagingService = game:GetService("MessagingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local TOPIC = "GlobalBoost"
local KEY = "current"

local KINDS = { "eggluck", "hatch", "money", "luck", "speed", "treadmill" }
local IS_KIND = {}
for _, kind in ipairs(KINDS) do IS_KIND[kind] = true end

local MAX_MULT = 1000

local store
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStores.Boost)
	end)
	store = ok and result or nil
end

local remotes = ReplicatedStorage:WaitForChild("Remotes", 20)
local remote = remotes and remotes:WaitForChild("GlobalBoost", 10)

local GlobalBoost = {}

_G.GlobalBoost = GlobalBoost

local function blank()
	local out = {}
	for _, kind in ipairs(KINDS) do
		out[kind] = { mult = 1, endsAt = 0, setBy = "", setAt = 0 }
	end
	return out
end

local shared = blank()
local here = blank()

local function liveIn(where, kind)
	local entry = where[kind]
	if not entry or entry.mult <= 1 then return false end
	if entry.endsAt > 0 and os.time() >= entry.endsAt then return false end
	return true
end

local function multIn(where, kind)
	return liveIn(where, kind) and where[kind].mult or 1
end

function GlobalBoost.value(kind)
	if not IS_KIND[kind] then return 1 end
	if kind=="treadmill" then return math.max(multIn(shared, kind),multIn(here, kind)) end
 return multIn(shared, kind) * multIn(here, kind)
end

function GlobalBoost.state()
	local out = {}
	for _, kind in ipairs(KINDS) do
		local mult = GlobalBoost.value(kind)
		if mult > 1 then

			local ends, began = 0, 0
			for _, where in ipairs({ shared, here }) do
				local entry = where[kind]
				if liveIn(where, kind) and entry.endsAt > 0 then
					if ends == 0 or entry.endsAt < ends then
						ends = entry.endsAt

						began = math.floor((tonumber(entry.setAt) or 0) / 1000)
					end
				end
			end
			if kind=="treadmill" then
 local chosen = multIn(here,kind)>=multIn(shared,kind) and here[kind] or shared[kind]
 ends=chosen.endsAt began=math.floor((chosen.setAt or 0)/1000)
 end
 out[kind] = { mult = mult, endsAt = ends, startedAt = began }
		end
	end
	return out
end

function GlobalBoost.kinds()
	return KINDS
end

local function tellClients()
	if not remote then return end
	remote:FireAllClients(GlobalBoost.state())
end

local function adoptKind(kind, data)
	if not IS_KIND[kind] or type(data) ~= "table" then return false end

	local setAt = tonumber(data.setAt) or 0
	if setAt < (shared[kind].setAt or 0) then return false end

	shared[kind] = {
		mult = math.clamp(tonumber(data.mult) or 1, 1, kind=="treadmill" and 1000 or MAX_MULT),
		endsAt = tonumber(data.endsAt) or 0,
		setBy = tostring(data.setBy or ""),
		setAt = setAt,
	}
	return true
end

local function adopt(data)
	if type(data) ~= "table" then return false end
	local changed = false
	for _, kind in ipairs(KINDS) do
		if adoptKind(kind, data[kind]) then changed = true end
	end
	if changed then tellClients() end
	return changed
end

function GlobalBoost.set(kind, mult, minutes, everywhere, byName)
	if not IS_KIND[kind] then return nil, "unknown kind" end

	local raw, duration = tonumber(mult), tonumber(minutes)
 if not raw or raw ~= raw or math.abs(raw)==math.huge then return nil, "invalid multiplier" end
 if kind=="treadmill" and raw>1 and (not duration or duration~=duration or duration<0.1 or duration>1440) then return nil, "treadmill duration must be 0.1 to 1440 minutes" end
 local value = math.clamp(raw, 1, kind=="treadmill" and 1000 or MAX_MULT)
	local mins = math.max(tonumber(minutes) or 0, 0)
	local endsAt = (value > 1 and mins > 0) and (os.time() + math.floor(mins * 60)) or 0

	local entry = {
		mult = value,
		endsAt = endsAt,
		setBy = tostring(byName or ""),
		setAt = DateTime.now().UnixTimestampMillis,
	}

	if not everywhere then
		here[kind] = entry
		tellClients()
		return GlobalBoost.value(kind)
	end

	adoptKind(kind, entry)
	tellClients()

	if store then

		local ok, err = pcall(function() store:SetAsync(KEY, shared) end)
		if not ok then
			warn("[Boost] boost not saved: " .. tostring(err))
		end
	end

	local ok, err = pcall(function()
		MessagingService:PublishAsync(TOPIC, { [kind] = entry })
	end)
	if not ok then
		warn("[Boost] boost not published to other servers: " .. tostring(err))
	end

	return GlobalBoost.value(kind)
end

function GlobalBoost.clear(byName)
	local stamp = DateTime.now().UnixTimestampMillis
	local payload = {}
	for _, kind in ipairs(KINDS) do
		here[kind] = { mult = 1, endsAt = 0, setBy = "", setAt = 0 }
		local entry = { mult = 1, endsAt = 0, setBy = tostring(byName or ""), setAt = stamp }
		adoptKind(kind, entry)
		payload[kind] = entry
	end
	tellClients()
	if store then
		local ok, err = pcall(function() store:SetAsync(KEY, shared) end)
		if not ok then warn("[Boost] boost not saved: " .. tostring(err)) end
	end
	local ok, err = pcall(function() MessagingService:PublishAsync(TOPIC, payload) end)
	if not ok then warn("[Boost] boost not published to other servers: " .. tostring(err)) end
	return true
end

function GlobalBoost.Init()
	if GlobalBoost._started then return end
	GlobalBoost._started = true
	if not remote then
		warn("[Boost] no Remotes.GlobalBoost; the boost will pay but stay invisible")
	end

	if store then
		local ok, data = pcall(function() return store:GetAsync(KEY) end)
		if ok then adopt(data) end
	else
		warn("[Boost] no DataStore; the boost will not survive a restart")
	end

	task.spawn(function()
		local ok, err = pcall(function()
			MessagingService:SubscribeAsync(TOPIC, function(message)
				adopt(message and message.Data)
			end)
		end)
		if not ok then
			warn("[Boost] global boost: no live updates from other servers (" .. tostring(err) .. ")")
		end
	end)

	local function greet(player)
		if remote then remote:FireClient(player, GlobalBoost.state()) end
	end

	if remote then
		local asked = {}
		remote.OnServerEvent:Connect(function(player)
			local t = os.clock()
			if (asked[player] or 0) + 1 > t then return end
			asked[player] = t
			greet(player)
		end)
		Players.PlayerRemoving:Connect(function(player) asked[player] = nil end)
	end
	Players.PlayerAdded:Connect(greet)
	for _, player in ipairs(Players:GetPlayers()) do greet(player) end

	local function signature()
		local parts = {}
		for _, kind in ipairs(KINDS) do
			parts[#parts + 1] = ("%s=%.2f"):format(kind, GlobalBoost.value(kind))
		end
		return table.concat(parts, ",")
	end

	task.spawn(function()
		local was = signature()
		while true do
			task.wait(5)
			local now = signature()
			if now ~= was then
				was = now
				tellClients()
			end
		end
	end)

	print(("[Boost] GlobalBoostService ready (%s)"):format(signature()))
end

return GlobalBoost