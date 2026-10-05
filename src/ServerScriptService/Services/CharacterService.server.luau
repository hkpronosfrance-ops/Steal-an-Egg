local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")

local GROUP = "Characters"
local SPREAD = 2.4

pcall(function()
	PhysicsService:RegisterCollisionGroup(GROUP)
end)
PhysicsService:CollisionGroupSetCollidable(GROUP, GROUP, false)

local function claim(part)
	if part:IsA("BasePart") then
		part.CollisionGroup = GROUP
	end
end

local function onCharacter(character)
	for _, d in ipairs(character:GetDescendants()) do
		claim(d)
	end

	character.DescendantAdded:Connect(claim)

	local root = character:FindFirstChild("HumanoidRootPart")
		or character:WaitForChild("HumanoidRootPart", 5)
	if root then
		local angle = math.random() * math.pi * 2
		local distance = math.sqrt(math.random()) * SPREAD
		root.CFrame = root.CFrame + Vector3.new(
			math.cos(angle) * distance, 0, math.sin(angle) * distance)
	end
end

local function onPlayer(player)
	player.CharacterAdded:Connect(onCharacter)
	if player.Character then
		onCharacter(player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayer(player)
end