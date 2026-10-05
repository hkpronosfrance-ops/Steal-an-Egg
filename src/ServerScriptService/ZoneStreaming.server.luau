local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")

local EggCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))

local SharedConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
local ST = SharedConfig.Streaming or {}
local AHEAD = ST.Ahead or 3
local BEHIND = ST.Behind or 2
local EVERY = ST.Every or 0.7

local map = workspace:WaitForChild("GameWorld")
local zonesFolder = map:WaitForChild("Zones")

local ALWAYS = {}
for _, n in ipairs(ST.AlwaysLoaded or { 1, 2 }) do ALWAYS[n] = true end

local decor = {}
local bounds = {}

for n = 1, EggCfg.ZONES do
	local folder
	for _, z in ipairs(zonesFolder:GetChildren()) do
		if z.Name:match("^Zone" .. n .. "_") then folder = z break end
	end
	local d = folder and folder:FindFirstChild("Decor")
	if d and d:IsA("Model") then
		if ALWAYS[n] then
			d.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		else
			d.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
			decor[n] = d
		end
	end
	local top, bot = EggCfg.bounds(n)
	bounds[n] = { top = top, bot = bot }
end

local function zoneAt(z)
	for n = 1, EggCfg.ZONES do
		local b = bounds[n]
		if b and z <= b.top and z >= b.bot then return n end
	end
	if z > bounds[1].top then return 0 end
	return EggCfg.ZONES
end

local held = {}

local function apply(plr, centre)
	local mine = held[plr]
	if not mine then mine = {} held[plr] = mine end
	for n, model in pairs(decor) do
		local want = (n >= centre - BEHIND) and (n <= centre + AHEAD)
		if want ~= (mine[n] == true) then
			local ok = pcall(function()
				if want then
					model:AddPersistentPlayer(plr)
				else
					model:RemovePersistentPlayer(plr)
				end
			end)
			if ok then mine[n] = want or nil end
		end
	end
end

local function rootOf(plr)
	local ch = plr.Character
	return ch and ch:FindFirstChild("HumanoidRootPart")
end

Players.PlayerRemoving:Connect(function(plr) held[plr] = nil end)

local LIBRARY_DELAY = ST.LibraryDelay or 3
local library = workspace:FindFirstChild("AnimalLibrary")

local function onJoin(plr)
	task.spawn(function()
		local placed = false
		for _ = 1, 60 do
			local root = rootOf(plr)
			if root then apply(plr, zoneAt(root.Position.Z)) placed = true break end
			task.wait(0.25)
		end
		if not placed then apply(plr, 0) end

		task.wait(LIBRARY_DELAY)
		if library and plr.Parent then
			pcall(function() library:AddPersistentPlayer(plr) end)
		end
	end)
end
Players.PlayerAdded:Connect(onJoin)
for _, plr in ipairs(Players:GetPlayers()) do onJoin(plr) end

local last = {}
Players.PlayerRemoving:Connect(function(plr) last[plr] = nil end)
task.spawn(function()
	while true do
		task.wait(EVERY)
		for _, plr in ipairs(Players:GetPlayers()) do
			local root = rootOf(plr)
			if root then
				local n = zoneAt(root.Position.Z)
				if last[plr] ~= n then
					last[plr] = n
					apply(plr, n)
				end
			end
		end
	end
end)

local count = 0
for _ in pairs(decor) do count += 1 end
print(("[Streaming] %d decor zones, window -%d/+%d")
	:format(count, BEHIND, AHEAD))