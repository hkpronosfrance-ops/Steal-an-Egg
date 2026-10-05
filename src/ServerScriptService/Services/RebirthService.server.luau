local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Cfg = require(RS:WaitForChild("EggConfig"))
local Rebirth = require(RS:WaitForChild("RebirthConfig"))
local Money = require(RS:WaitForChild("MonetizationConfig"))

local remotes = RS:WaitForChild("Remotes")
local remote = remotes:FindFirstChild("Rebirth")
if not remote then
	remote = Instance.new("RemoteEvent")
	remote.Name = "Rebirth"
	remote.Parent = remotes
end

local SKIP = Money.REBIRTH_SKIP or { productId = 0 }

local function count(player)
	local Profile = _G.Profile
	return Profile and Profile.value(player, "stats", "Rebirths") or 0
end

_G.RebirthMult = function(player)
	return Rebirth.mult(count(player))
end

local lastTry = {}

local function doRebirth(player, paid)
	local Profile = _G.Profile
	if not (Rebirth.ENABLED and Profile and Profile.get(player)) then
		return false, "Not ready yet"
	end
	local n = count(player)
	if Rebirth.maxed(n) then
		return false, "Max rebirth reached!"
	end
	if paid and Profile.value(player, "wallet", "Coins") < Rebirth.cost(n) then
		return false, "Not enough cash!"
	end
	Profile.set(player, "Coins", Cfg.COINS_START or 0)
	player:SetAttribute("Speed", Cfg.SPEED_START or 1)
	Profile.set(player, "Rebirths", n + 1)
	task.spawn(Profile.save, player)
	remote:FireClient(player, "done", n + 1)
	return true
end

remote.OnServerEvent:Connect(function(player, action)
	local now = os.clock()
	if lastTry[player] and now - lastTry[player] < 1 then
		return
	end
	lastTry[player] = now
	if action == "rebirth" then
		local ok, why = doRebirth(player, true)
		if not ok then
			remote:FireClient(player, "fail", why)
		end
	elseif action == "skipTest" then
		if RunService:IsStudio() and Money.STUDIO_TEST and (tonumber(SKIP.productId) or 0) <= 0 then
			doRebirth(player, false)
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastTry[player] = nil
end)

task.spawn(function()
	while not _G.Purchases do
		task.wait(0.25)
	end
	_G.Purchases.register("RebirthSkip", SKIP.productId, function(player)
		local Profile = _G.Profile
		if not (Profile and Profile.get(player)) then
			return false
		end
		if doRebirth(player, false) then
			return true
		end
		local n = count(player)
		Profile.set(player, "Coins", Profile.value(player, "wallet", "Coins") + Rebirth.cost(n))
		remote:FireClient(player, "fail", "Max rebirth reached - you got cash instead")
		return true
	end)
end)