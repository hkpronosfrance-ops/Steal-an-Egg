local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Config = require(game.ReplicatedStorage.Shared.Config)

local LB = Config.Leaderboard or {}
local REFRESH = LB.Refresh or 60
local SAVE_EVERY = LB.SaveEvery or 60
local SHOWN = math.min(LB.Shown or 100, 100)

local CATEGORIES = {
	TopCash   = { folder = "wallet", key = "Coins" },
	TopRobux  = { folder = "stats", key = "RobuxSpent" },

	TopSpeed  = { attributes = { "Speed" } },

	TopPlaytime = { folder = "stats", key = "Playtime", format = "clock" },
}

local stores = {}
for name in pairs(CATEGORIES) do
	local ok, store = pcall(function()
		return DataStoreService:GetOrderedDataStore(Config.DataStores.Board .. name .. "_v1")
	end)
	stores[name] = ok and store or nil
end

local mapFolder = workspace:FindFirstChild("GameWorld")
	or workspace:WaitForChild("GameWorld", 30)
local boardsFolder = mapFolder and mapFolder:WaitForChild("Leaderboards", 30)
if not boardsFolder then
	warn("[Leaderboard] Leaderboards folder not found - boards stay empty")
	return
end

local function valueOf(player, category)
	local rule = CATEGORIES[category]
	if not rule then
		return 0
	end
	if rule.attributes then
		local product = 1
		for _, name in ipairs(rule.attributes) do
			product = product * (tonumber(player:GetAttribute(name)) or 1)
		end
		return math.floor(product)
	end
	local Profile = _G.Profile
	if not Profile then
		return 0
	end
	return math.floor(Profile.value(player, rule.folder, rule.key) or 0)
end

local nameCache = {}
local function nameOf(userId)
	if nameCache[userId] then
		return nameCache[userId]
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	name = ok and name or ("Player " .. userId)
	nameCache[userId] = name
	return name
end

local short = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig")).fmtShort

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor((seconds % 3600) / 60)
	if h > 0 then
		return ("%dh %dm"):format(h, m)
	end
	if m > 0 then
		return ("%dm"):format(m)
	end
	return ("%ds"):format(seconds)
end

local function display(category, value)
	local rule = CATEGORIES[category]
	if rule and rule.format == "clock" then
		return clock(value)
	end
	return short(value)
end

local lastSent = {}
local function save(player)
	if not player:FindFirstChild("wallet") then return end
	local sent = lastSent[player.UserId] or {}
	lastSent[player.UserId] = sent
	for name, _ in pairs(CATEGORIES) do
		local store = stores[name]
		if store then
			local value = valueOf(player, name)
			if value > 0 and sent[name] ~= value then
				local ok = pcall(function()
					store:SetAsync(tostring(player.UserId), value)
				end)
				if ok then sent[name] = value end
			end
		end
	end
end

local function fromConnected(category)
	local rows = {}
	for _, player in ipairs(Players:GetPlayers()) do
		local value = valueOf(player, category)
		if value > 0 then
			rows[#rows + 1] = { userId = player.UserId, name = player.Name, value = value }
		end
	end
	table.sort(rows, function(a, b) return a.value > b.value end)
	return rows
end

local function fromStore(category)
	local store = stores[category]
	if not store then
		return nil
	end
	local ok, page = pcall(function()
		return store:GetSortedAsync(false, SHOWN):GetCurrentPage()
	end)
	if not (ok and page) then
		return nil
	end
	local rows = {}
	for _, entry in ipairs(page) do
		local userId = tonumber(entry.key)
		if userId then
			rows[#rows + 1] = { userId = userId, name = nameOf(userId), value = entry.value }
		end
	end
	return rows
end

local function paint(board, rows, category)
	local holder = board:FindFirstChild("Rows", true)
	if not holder then
		return
	end
	local index = 0
	for _, row in ipairs(holder:GetChildren()) do
		if row:IsA("Frame") then
			index += 1
			local data = rows[index]
			local rank = row:FindFirstChild("Rank")
			local name = row:FindFirstChild("PlayerName")
			local value = row:FindFirstChild("Value")
			local avatar = row:FindFirstChild("Avatar")
			row.Visible = data ~= nil
			if data then
				if rank then rank.Text = "#" .. index end
				if name then name.Text = data.name end
				if value then value.Text = display(category, data.value) end
				if avatar then
					avatar.Image =
						("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150"):format(data.userId)
				end
			end
		end
	end
end

local function refresh()
	for _, board in ipairs(boardsFolder:GetChildren()) do
		local category = board:GetAttribute("Category")
		if category and CATEGORIES[category] then
			local rows = fromStore(category)
			if not rows or #rows == 0 then
				rows = fromConnected(category)
			end
			paint(board, rows, category)
		end
	end
end

Players.PlayerRemoving:Connect(function(player)
	save(player)
	lastSent[player.UserId] = nil
end)

task.spawn(function()
	while not _G.Profile do
		task.wait(0.25)
	end
	task.wait(2)
	for _, player in ipairs(Players:GetPlayers()) do
		save(player)
	end
	refresh()
	local nextSave, nextRefresh = os.clock() + SAVE_EVERY, os.clock() + REFRESH
	while true do
		task.wait(1)
		local now = os.clock()
		if now >= nextSave then
			nextSave = now + SAVE_EVERY
			for _, player in ipairs(Players:GetPlayers()) do
				save(player)
			end
		end
		if now >= nextRefresh then
			nextRefresh = now + REFRESH
			refresh()
		end
	end
end)

local live = 0
for _, store in pairs(stores) do
	if store then
		live += 1
	end
end