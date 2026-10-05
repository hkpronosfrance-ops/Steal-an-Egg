local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local remote = ReplicatedStorage.Remotes:WaitForChild("Admin")
local A = Config.Admin
local PREFIX = "/admin"

local banStore
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(Config.DataStores.Bans)
	end)
	banStore = ok and result or nil
end

local authCache = {}

local function isAdmin(player)
	if not player then return false end
	if authCache[player.UserId] ~= nil then return authCache[player.UserId] end

	local ok = false
	for _, id in ipairs(A.UserIds) do
		if player.UserId == id then ok = true break end
	end
	if not ok and (A.GroupId or 0) > 0 then
		local good, rank = pcall(function() return player:GetRankInGroup(A.GroupId) end)
		if good and type(rank) == "number" and rank >= (A.MinRank or 255) then ok = true end
	end
	if not ok and A.StudioAlwaysAdmin and RunService:IsStudio() then ok = true end

	authCache[player.UserId] = ok
	return ok
end
Players.PlayerRemoving:Connect(function(player) authCache[player.UserId] = nil end)

local function audit(admin, action, target, args, result)
	print(("[Admin] %s | %s -> %s | %s | %s"):format(
		admin and admin.Name or "SYSTEM", action, tostring(target),
		tostring(args or ""), tostring(result or "ok")))
end

local function findPlayer(name)
	if type(name) ~= "string" or name == "" then return nil, "give a player name" end
	local needle = name:lower()
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower() == needle or player.DisplayName:lower() == needle then
			return player
		end
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Name:lower():sub(1, #needle) == needle then return player end
	end
	return nil, "no such player: " .. name
end

local function num(v)
	local n = tonumber(v)
	if n and n == n and math.abs(n) ~= math.huge then return n end
	return nil
end

local function stat(player, key)
	local Profile = _G.Profile
	return Profile and Profile.value(player, "wallet", key) or 0
end

local function setStat(player, key, amount)
	local Profile = _G.Profile
	if Profile then Profile.set(player, key, amount) end
end

local handlers = {}

handlers.coins = function(admin, who, amount)
	local player, err = findPlayer(who)
	if not player then return err end
	local n = num(amount)
	if not n then return "give a number" end
	setStat(player, "Coins", stat(player, "Coins") + math.floor(n))
	audit(admin, "ADD_COINS", player.UserId, n)
	return ("%s: +%d coins"):format(player.Name, math.floor(n))
end

handlers.removecoins = function(admin, who, amount)
	local player, err = findPlayer(who)
	if not player then return err end
	local n = num(amount)
	if not n then return "give a number" end
	setStat(player, "Coins", math.max(0, stat(player, "Coins") - math.floor(n)))
	audit(admin, "REMOVE_COINS", player.UserId, n)
	return ("%s: -%d coins"):format(player.Name, math.floor(n))
end

handlers.setcoins = function(admin, who, amount)
	local player, err = findPlayer(who)
	if not player then return err end
	local n = num(amount)
	if not n then return "give a number" end
	setStat(player, "Coins", math.max(0, math.floor(n)))
	audit(admin, "SET_COINS", player.UserId, n)
	return ("%s: Coins = %d"):format(player.Name, math.floor(n))
end

handlers.boost = function(admin, kind, mult, minutes, scope)
	local Boost = _G.GlobalBoost
	if not Boost then return "GlobalBoostService is not running" end

	local kinds = table.concat(Boost.kinds(), " | ")

	if tostring(kind):lower() == "off" then
		Boost.clear(admin and admin.Name)
		audit(admin, "BOOST", 0, "off")
		return "every boost is off, on every server"
	end

	kind = tostring(kind):lower()
	local n = num(mult)
	if not n then
		return ("usage: boost <%s> <multiplier> [minutes] [here|all]   |   boost off")
			:format(kinds)
	end

	local everywhere = tostring(scope or "all"):lower() ~= "here"
	local mins = num(minutes) or 0

	local now, why = Boost.set(kind, n, mins, everywhere, admin and admin.Name)
	if not now then
		return ("%s - pick one of: %s"):format(tostring(why), kinds)
	end

	audit(admin, "BOOST", 0, ("%s x%.2f %s"):format(kind, now, everywhere and "all" or "here"))

	local where = everywhere and "on every server" or "on this server only"
	if now <= 1 then
		return ("%s boost is off %s"):format(kind, where)
	end
	if mins > 0 then
		return ("%s boost x%.2f for %d minutes, %s"):format(kind, now, mins, where)
	end
	return ("%s boost x%.2f with no time limit, %s"):format(kind, now, where)
end

handlers.kick = function(admin, who, ...)
	local player, err = findPlayer(who)
	if not player then return err end
	local reason = table.concat({ ... }, " ")
	audit(admin, "KICK", player.UserId, reason)
	player:Kick(reason ~= "" and reason or "Kicked by admin")
	return ("kicked %s"):format(player.Name)
end

handlers.ban = function(admin, who, ...)
	local player, err = findPlayer(who)
	if not player then return err end
	local reason = table.concat({ ... }, " ")
	if not banStore then return "no DataStore, cannot save the ban" end
	local ok = pcall(function()
		banStore:SetAsync("b_" .. player.UserId, { reason = reason, at = os.time() })
	end)
	audit(admin, "BAN", player.UserId, reason, ok and "ok" or "error")
	if ok then
		player:Kick(reason ~= "" and reason or "Banned by admin")
		return ("banned %s"):format(player.Name)
	end
	return "could not save the ban"
end

handlers.unban = function(admin, id)
	local userId = num(id)
	if not userId then return "give a UserId - the player is offline" end
	if not banStore then return "no DataStore" end
	local ok = pcall(function() banStore:RemoveAsync("b_" .. math.floor(userId)) end)
	audit(admin, "UNBAN", userId, "", ok and "ok" or "error")
	return ok and ("unbanned %d"):format(userId) or "failed"
end

handlers.teleport = function(admin, who)
	local player, err = findPlayer(who)
	if not player then return err end
	local from = admin.Character and admin.Character:FindFirstChild("HumanoidRootPart")
	local to = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not (from and to) then return "both players need to be spawned" end
	from.CFrame = to.CFrame * CFrame.new(0, 0, 4)
	audit(admin, "TELEPORT", player.UserId, "")
	return ("teleported to %s"):format(player.Name)
end

handlers.give = function(admin, amount)
	local n = num(amount)
	if not n then return "give a number" end
	for _, player in ipairs(Players:GetPlayers()) do
		setStat(player, "Coins", stat(player, "Coins") + math.floor(n))
	end
	remote:FireAllClients("announce", {
		text = ("Everyone got %d coins!"):format(math.floor(n)),
		fromUserId = admin and admin.UserId or 0,
		fromName = admin and admin.Name or "ADMIN",
	})
	audit(admin, "GIVE_ALL", 0, n)
	return ("+%d coins for everyone here"):format(math.floor(n))
end

handlers.freereset = function(admin, who)
	local player, err = findPlayer(who)
	if not player then return err end
	if not _G.FreeReward then return "free reward not ready" end
	local ok, why = _G.FreeReward.reset(player)
	if not ok then return tostring(why) end
	audit(admin, "FREE_RESET", player.UserId, "")
	return ("%s: free reward can be claimed again"):format(player.Name)
end

handlers.freegive = function(admin, who)
	local player, err = findPlayer(who)
	if not player then return err end
	if not _G.FreeReward then return "free reward not ready" end
	local ok, coins = _G.FreeReward.grant(player)
	if not ok then return tostring(coins) end
	audit(admin, "FREE_GRANT", player.UserId, coins)
	return ("%s: free reward paid, %d coins"):format(player.Name, coins)
end

handlers.speed = function(admin, who, amount)
    local player, err = findPlayer(who)
    if not player then return err end

    local Cfg = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))
    local n = num(amount)
    if not n then

        local txt = tostring(amount):upper()
        local base, suffix = txt:match("^([%d%.]+)([KMBT]?)$")
        local mult = ({ K = 1e3, M = 1e6, B = 1e9, T = 1e12 })[suffix] or 1
        n = base and (tonumber(base) or 0) * mult or nil
    end
    if not n then return "give a number, e.g. 1, 170K, 5T" end

    n = math.clamp(n, 0, Cfg.SPEED_MAX)
    player:SetAttribute("Speed", n)
    audit(admin, "SET_SPEED", player.UserId, n)
    return ("%s: Speed = %s (%.0f studs/s)"):format(
        player.Name, Cfg.fmtSpeed(n), Cfg.walkForSpeed(n))
end

handlers.bat = function(admin, who, zone)
	local player, err = findPlayer(who)
	if not player then return err end
	local BatCfg = require(ReplicatedStorage:WaitForChild("BatConfig"))
	local z = num(zone)
	if not z or z ~= math.floor(z) or z < 0 or (z > 0 and not BatCfg[z]) then
		return ("usage: bat <player> <0-%d>   (0 = default bat)"):format(#BatCfg)
	end
	local Bats = require(game:GetService("ServerScriptService"):WaitForChild("BatService"))
	if not Bats.adminSet(player, z) then return player.Name .. " has no profile loaded yet" end
	audit(admin, "SET_BAT", player.UserId, z)
	return ("%s: bat = %s"):format(player.Name, z == 0 and "Default Bat" or BatCfg[z].Name)
end

handlers.level = function(admin, who, kind, level)
	local player, err = findPlayer(who)
	if not player then return err end
	local U = require(ReplicatedStorage:WaitForChild("UpgradeConfig"))
	local key = ({ mill = "MILL", treadmill = "MILL", plot = "PEN", pen = "PEN" })[tostring(kind):lower()]
	local n = num(level)
	if not key or not n then
		return ("usage: level <player> <mill|plot> <1-%d>"):format(U.MAX_LEVEL)
	end
	local PU = _G.PlotUpgrade
	if not (PU and PU.setLevel) then return "upgrade service is not running" end
	if not PU.levelOf(player, key) then return player.Name .. " has no plot yet" end
	n = math.clamp(math.floor(n), 1, U.MAX_LEVEL)
	PU.setLevel(player, key, n)
	audit(admin, "SET_LEVEL", player.UserId, ("%s %d"):format(key, n))
	return ("%s: %s level = %d"):format(player.Name, key == "MILL" and "treadmill" or "plot", n)
end

local EGG_TOPIC = "EggAdmin"
local MessagingService = game:GetService("MessagingService")

local function eggCfg()
    return require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))
end

local function clampIdx(v, hi, fallback)
    local n = tonumber(v)
    if not n then return fallback end
    return math.clamp(math.floor(n), 1, hi)
end

handlers.egg = function(admin, who, zone, tier, size, count)
    local player, err = findPlayer(who)
    if not player then return err end
    if not _G.EggAdmin then return "egg service not ready" end

    local Cfg = eggCfg()
    local z = clampIdx(zone, Cfg.ZONES, 1)
    local t = clampIdx(tier, #Cfg.TIERS, 1)
    local s = clampIdx(size, #Cfg.SIZES, 3)
    local n = math.clamp(tonumber(count) or 1, 1, 10)

    for _ = 1, n do _G.EggAdmin.give(player, z, t, s) end
    audit(admin, "GIVE_EGG", player.UserId, ("z%d t%d s%d x%d"):format(z, t, s, n))
    return ("%s: %d x %s %s egg (zone %d)"):format(player.Name, n,
        Cfg.TIERS[t] and Cfg.TIERS[t].name or t,
        Cfg.SIZES[s] and Cfg.SIZES[s].name or s, z)
end

handlers.ripen = function(admin, who)
    local player, err = findPlayer(who)
    if not player then return err end
    if not (_G.Nest and _G.Nest.ripen) then return "nest service not ready" end
    local n = _G.Nest.ripen(player)
    audit(admin, "RIPEN", player.UserId, n)
    return ("%s: %d eggs ready to hatch"):format(player.Name, n)
end

local function ripenEveryone()
    if not (_G.Nest and _G.Nest.ripen) then return 0 end
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do n += _G.Nest.ripen(p) end
    return n
end

handlers.ripenall = function(admin, scope)
    local n = ripenEveryone()
    local where = "this server"
    if tostring(scope or ""):lower() == "global" then
        local ok = pcall(function()
            MessagingService:PublishAsync(EGG_TOPIC, { what = "ripen", from = game.JobId })
        end)
        where = ok and "ALL servers" or "this server (no cross-server access)"
    end
    audit(admin, "RIPEN_ALL", 0, where)
    return ("%d eggs ready - %s"):format(n, where)
end

handlers.mapegg = function(admin, zone, tier, size, count)
    if not _G.EggAdmin then return "egg service not ready" end
    local Cfg = eggCfg()
    local z = (tostring(zone or ""):lower() == "all") and nil or clampIdx(zone, Cfg.ZONES, 1)
    local t = clampIdx(tier, #Cfg.TIERS, 4)
    local s = clampIdx(size, #Cfg.SIZES, 6)
    local n = math.clamp(tonumber(count) or 4, 1, 48)

    local made = _G.EggAdmin.spawn(z, t, s, n)
    audit(admin, "MAP_EGG", 0, ("z%s t%d s%d x%d"):format(tostring(z or "all"), t, s, made))
    return ("%d eggs placed on the map (%s %s, zone %s)"):format(made,
        Cfg.TIERS[t] and Cfg.TIERS[t].name or t,
        Cfg.SIZES[s] and Cfg.SIZES[s].name or s, tostring(z or "all"))
end

task.spawn(pcall, function()
    MessagingService:SubscribeAsync(EGG_TOPIC, function(message)
        local data = message and message.Data
        if type(data) == "table" and data.what == "ripen" then
            ripenEveryone()
        end
    end)
end)

handlers.announce = function(admin, ...)
	local text = table.concat({ ... }, " ")
	if text == "" then return "nothing to announce" end
	local okFilter, filtered = pcall(function()
		return game:GetService("TextService"):FilterStringAsync(text, admin and admin.UserId or 0):GetNonChatStringForBroadcastAsync()
	end)
	if not okFilter or type(filtered) ~= "string" then return "text filter failed, try again" end
	text = filtered
	remote:FireAllClients("announce", {
		text = text,
		fromUserId = admin and admin.UserId or 0,
		fromName = admin and admin.Name or "ADMIN",
	})
	audit(admin, "ANNOUNCE", 0, text)
	return "sent"
end

handlers.capture = function(admin, action, minutes, mult, scope)
	local Capture = _G.CaptureEgg
	if not Capture then return "CaptureEggService is not running" end
	action = tostring(action or ""):lower()
	if action == "off" then
		local everywhere = tostring(minutes or "all"):lower() ~= "here"
		Capture.stop(everywhere)
		audit(admin, "CAPTURE", 0, "off " .. (everywhere and "all" or "here"))
		return "capture the egg ended, rewards handed out"
	elseif action ~= "start" then
		return "usage: capture start <minutes> [reward x] [here|all]   |   capture off [here|all]"
	end
	local everywhere = tostring(scope or "all"):lower() ~= "here"
	local ok, why = Capture.start(num(minutes), num(mult) or 1, everywhere)
	if not ok then return tostring(why) end
	local st = Capture.state()
	audit(admin, "CAPTURE", 0, ("%s min x%g %s"):format(tostring(minutes), st.mult, everywhere and "all" or "here"))
	return ("capture the egg started for %s min, rewards x%g %s"):format(tostring(minutes), st.mult, everywhere and "on every server" or "on this server only")
end

handlers.daynight = function(admin, mode)
	local DN = _G.DayNight
	if not DN then return "DayNightService is not running" end
	local Cycle = require(ReplicatedStorage:WaitForChild("DayNightConfig"))
	mode = tostring(mode or ""):lower()
	if mode == "dayend" then
		DN.setPhase("day", 10)
	elseif mode == "night" then
		DN.setPhase("night")
	elseif mode == "countdown" then
		DN.setPhase("night", Cycle.COUNTDOWN + 2)
	elseif mode == "day" then
		DN.setPhase("day")
	elseif mode == "reset" then
		local count, legendary = DN.resetEggs()
		audit(admin, "DAYNIGHT", 0, mode)
		return ("eggs reset: %d eggs, %d legendary"):format(count or 0, legendary and #legendary or 0)
	else
		return "usage: daynight <dayend|night|countdown|day|reset>"
	end
	audit(admin, "DAYNIGHT", 0, mode)
	local phase, endsAt = DN.state()
	return ("%s for %ds"):format(phase, math.floor(endsAt - workspace:GetServerTimeNow() + 0.5))
end

local function run(admin, line)
	local parts = {}
	for word in tostring(line):gmatch("%S+") do parts[#parts + 1] = word end
	if parts[1] ~= PREFIX then
		return ("commands start with %s"):format(PREFIX)
	end
	local verb = (parts[2] or ""):lower()
	local handler = handlers[verb]
	if not handler then
		local names = {}
		for key in pairs(handlers) do names[#names + 1] = key end
		table.sort(names)
		return "unknown command. try: " .. table.concat(names, ", ")
	end
	local ok, result = pcall(handler, admin, table.unpack(parts, 3))
	if not ok then return "error: " .. tostring(result) end
	return tostring(result)
end

local function roster()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		list[#list + 1] = {
			userId = player.UserId,
			name = player.Name,
			coins = stat(player, "Coins"),
		}
	end
	return list
end

remote.OnServerEvent:Connect(function(player, action, payload)
	if action == "auth" then
		local ok = isAdmin(player)
		remote:FireClient(player, "auth", ok)
		if ok then remote:FireClient(player, "state", roster()) end
		return
	end

	if not isAdmin(player) then
		remote:FireClient(player, "denied")
		return
	end

	if action == "state" then
		remote:FireClient(player, "state", roster())
	elseif action == "cmd" and type(payload) == "string" then
		remote:FireClient(player, "reply", run(player, payload))
		remote:FireClient(player, "state", roster())
	end
end)

if banStore then
	Players.PlayerAdded:Connect(function(player)
		local ok, record = pcall(function()
			return banStore:GetAsync("b_" .. player.UserId)
		end)
		if ok and type(record) == "table" then
			player:Kick(record.reason ~= "" and record.reason or "Banned")
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	task.delay(2, function()
		if player.Parent and isAdmin(player) then
			remote:FireClient(player, "auth", true)
		end
	end)
end)