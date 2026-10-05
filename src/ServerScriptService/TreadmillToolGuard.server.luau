local Players = game:GetService("Players")

local FLAGS = { "OnTreadmill", "AdminTreadmillRunning" }

local function running(p)
	for _, name in ipairs(FLAGS) do
		if p:GetAttribute(name) == true then return true end
	end
	return false
end

local function stow(p)
	local ch = p.Character
	local hum = ch and ch:FindFirstChildOfClass("Humanoid")
	if hum and ch:FindFirstChildOfClass("Tool") then hum:UnequipTools() end
end

local function bindCharacter(p, ch)
	ch.ChildAdded:Connect(function(c)
		if c:IsA("Tool") and running(p) then task.defer(stow, p) end
	end)
end

local function bind(p)
	for _, name in ipairs(FLAGS) do
		p:GetAttributeChangedSignal(name):Connect(function()
			if running(p) then stow(p) end
		end)
	end
	if p.Character then bindCharacter(p, p.Character) end
	p.CharacterAdded:Connect(function(ch)
		p:SetAttribute("OnTreadmill", false)
		bindCharacter(p, ch)
	end)
end

Players.PlayerAdded:Connect(bind)
for _, p in ipairs(Players:GetPlayers()) do bind(p) end