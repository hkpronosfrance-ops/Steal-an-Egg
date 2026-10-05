local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Shared.Config)

local remote = ReplicatedStorage.Remotes:WaitForChild("FreeReward")
local SETTINGS = Config.FreeReward

local function giveSpeed(player)
	local amount = tonumber(SETTINGS.Speed) or 0
	local cap = require(ReplicatedStorage:WaitForChild("EggConfig")).SPEED_MAX or 1e14
	player:SetAttribute("Speed", math.min((tonumber(player:GetAttribute("Speed")) or 1) + amount, cap))
	return amount
end

local function profileOf(player)
	local Profile = _G.Profile
	return Profile and Profile.get(player) or nil
end

local function inGroup(player)
	local id = SETTINGS.GroupId or 0
	if id <= 0 then

		return false, false
	end
	local ok, result = pcall(function() return player:IsInGroup(id) end)
	return (ok and result) == true, true
end

local function push(player)
	local profile = profileOf(player)
	if not profile then return end
	local joined, verifiable = inGroup(player)
	remote:FireClient(player, "state", {
		claimed = profile.FreeRewardClaimed == true,
		joined = joined,
		verifiable = verifiable,
		speed = SETTINGS.Speed,
	})
end

remote.OnServerEvent:Connect(function(player, action)
	local profile = profileOf(player)
	if not profile then return end

	if action == "get" then
		push(player)
		return
	end
	if action ~= "claim" then return end

	if profile.FreeRewardClaimed then
		remote:FireClient(player, "denied", "already claimed")
		return
	end

	profile.FreeRewardClaimed = true
	local joined, verifiable = inGroup(player)
	if not verifiable then
		profile.FreeRewardClaimed = false
		remote:FireClient(player, "denied", "group not set")
		return
	end
	if not joined then
		profile.FreeRewardClaimed = false
		remote:FireClient(player, "denied", "join the group first")
		push(player)
		return
	end

	remote:FireClient(player, "granted", giveSpeed(player))
	push(player)
end)

_G.FreeReward = {
	reset = function(player)
		local profile = profileOf(player)
		if not profile then return false, "profile not ready" end
		profile.FreeRewardClaimed = false
		push(player)
		return true
	end,

	grant = function(player)
		local profile = profileOf(player)
		if not profile then return false, "profile not ready" end
		if profile.FreeRewardClaimed then return false, "already claimed" end
		profile.FreeRewardClaimed = true
		local amount = giveSpeed(player)
		remote:FireClient(player, "granted", amount)
		push(player)
		return true, amount
	end,

}

task.spawn(function()
	local Profile = _G.Profile
	while not Profile do
		task.wait(0.1)
		Profile = _G.Profile
	end
	Profile.Loaded:Connect(push)
	for _, player in ipairs(Players:GetPlayers()) do
		if profileOf(player) then push(player) end
	end
end)