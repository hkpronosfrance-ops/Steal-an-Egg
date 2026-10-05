local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local Cfg = require(RS:WaitForChild("EggConfig"))

local BEHIND = 4
local AHEAD = 4
local EVERY = 0.5

local plr = Players.LocalPlayer
local map = workspace:WaitForChild("GameWorld")
local zonesFolder = map:WaitForChild("Zones")

local park = Instance.new("Folder")
park.Name = "ParkedDecor"
park.Parent = RS

local homes = {}
for _, z in ipairs(zonesFolder:GetChildren()) do
	local n = tonumber(z.Name:match("^Zone(%d+)_"))
	if n then homes[n] = z end
end

local parked = {}
local lastCentre = 0

local function apply(centre)
	for n, zone in pairs(homes) do
		local want = n >= centre - BEHIND and n <= centre + AHEAD
		if want then
			local m = parked[n]
			if m then
				if m.Parent == park then m.Parent = zone end
				parked[n] = nil
			end
		else
			local m = zone:FindFirstChild("Decor")
			if m then
				parked[n] = m
				m.Parent = park
			end
		end
	end
end

local function centreOf(root)
	local ok, n = pcall(Cfg.zoneAt, root.Position.Z)
	if ok and type(n) == "number" then lastCentre = n end
	return lastCentre
end

local function parkLibrary()
	local lib = workspace:FindFirstChild("AnimalLibrary")
	if lib then lib.Parent = RS end
end
workspace.ChildAdded:Connect(function(child)
	if child.Name == "AnimalLibrary" then task.defer(parkLibrary) end
end)
parkLibrary()

while true do
	local ch = plr.Character
	local root = ch and ch:FindFirstChild("HumanoidRootPart")
	if root then
		apply(centreOf(root))
	end
	task.wait(EVERY)
end