local Players = game:GetService("Players")

local function refresh(player)
	local char = player.Character
	local head = char and char:FindFirstChild("Head")
	if not head then return end
	local hum = char:FindFirstChildWhichIsA("Humanoid")
	if hum then
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	local plate = head:FindFirstChild("Nameplate")
	if plate then plate:Destroy() end
end

local function attach(player)
	local function onSpawn()
		local char = player.Character
		if char and char:WaitForChild("Head", 10) then
			refresh(player)
		end
	end
	player.CharacterAdded:Connect(function() task.spawn(onSpawn) end)
	if player.Character then task.spawn(onSpawn) end
end

Players.PlayerAdded:Connect(attach)
for _, player in ipairs(Players:GetPlayers()) do attach(player) end