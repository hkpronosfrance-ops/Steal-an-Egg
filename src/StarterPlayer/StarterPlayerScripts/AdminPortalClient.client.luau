local RunService = game:GetService("RunService")
local currentGui, original, clip, swirl
local scanIn = 0

local function clear()
	if clip then clip:Destroy() end
	if original and original.Parent then original.Visible = true end
	currentGui, original, clip, swirl = nil, nil, nil, nil
end

local function bind(gui)
	clear()
	local source = gui:FindFirstChildOfClass("ImageLabel")
	if not source then return end
	currentGui, original = gui, source
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	clip = Instance.new("CanvasGroup")
	clip.Name = "AnimatedPortal"
	clip.Size = UDim2.fromScale(1, 1)
	clip.BackgroundTransparency = 1
	clip.ClipsDescendants = true
	clip.Parent = gui
	local function layer(name, transparency)
		local image = source:Clone()
		image.Name = name
		image.AnchorPoint = Vector2.new(.5, .5)
		image.Position = UDim2.fromScale(.5, .5)
		image.Size = UDim2.fromScale(1.43, 1.43)
		image.BackgroundTransparency = 1
		image.ImageTransparency = transparency
		image.Visible = true
		image.Parent = clip
		return image
	end
	swirl = layer("EnergySwirl", 0)
	original.Visible = false
end

RunService.Heartbeat:Connect(function(dt)
	scanIn -= dt
	if scanIn <= 0 then
		scanIn = .5
		local world = workspace:FindFirstChild("GameWorld")
		local model = world and world:FindFirstChild("AdminTreadmill")
		local panel = model and model:FindFirstChild("PortalTexturePanel")
		local gui = panel and panel:FindFirstChild("PortalEnergy")
		if gui ~= currentGui then
			if gui then bind(gui) else clear() end
		end
	end
	if not currentGui or not currentGui:IsDescendantOf(workspace) then return end
	local camera = workspace.CurrentCamera
	if camera and (camera.CFrame.Position - currentGui.Parent.Position).Magnitude > 180 then return end
	local t = workspace:GetServerTimeNow()
	swirl.Rotation = (t * 12) % 360
end)