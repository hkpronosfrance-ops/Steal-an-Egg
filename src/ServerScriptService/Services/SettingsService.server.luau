local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local remote = ReplicatedStorage.Remotes:WaitForChild("Settings")
local DEFAULTS = Config.DefaultSettings

local function profileOf(player)
	local Profile = _G.Profile
	return Profile and Profile.get(player) or nil
end

local function push(player)
	local profile = profileOf(player)
	if not profile then return end
	remote:FireClient(player, "state", profile.Settings)
end

local function sanitize(key, value)
	local default = DEFAULTS[key]
	if default == nil then return nil end
	if type(default) == "boolean" then
		if type(value) ~= "boolean" then return nil end
		return value
	elseif type(default) == "number" then
		if type(value) ~= "number" or value ~= value then return nil end
		return math.clamp(value, 0, 1)
	end
	return nil
end

remote.OnServerEvent:Connect(function(player, action, key, value)
	local profile = profileOf(player)
	if not profile then return end

	if action == "get" then
		push(player)
		return
	end
	if action ~= "set" then return end

	local clean = sanitize(key, value)
	if clean == nil then return end
	profile.Settings[key] = clean
	push(player)
end)

task.spawn(function()
	local Profile = _G.Profile
	while not Profile do
		task.wait(0.1)
		Profile = _G.Profile
	end
	Profile.Loaded:Connect(push)
	for _, player in ipairs(Players:GetPlayers()) do
		if Profile.get(player) then push(player) end
	end
end)