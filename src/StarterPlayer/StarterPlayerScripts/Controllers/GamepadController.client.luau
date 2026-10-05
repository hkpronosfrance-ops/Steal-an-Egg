local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local Gui = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

local SKIP = { Backdrop = true, Shade = true, Dim = true }
local PREFERRED = { "Buy", "Claim", "Confirm", "Next" }
local ENTRY = { "DropButton", "Card", "GrowAll", "EquipBest", "Shop" }
local DPAD = {
	[Enum.KeyCode.DPadUp] = true, [Enum.KeyCode.DPadDown] = true,
	[Enum.KeyCode.DPadLeft] = true, [Enum.KeyCode.DPadRight] = true,
}

local group = nil
local padUI = false

local function pad()
	return UIS.GamepadEnabled and UIS:GetLastInputType().Name:find("Gamepad") ~= nil
end

local function shown(o)
	local a = o
	while a and a ~= pg do
		if a:IsA("GuiObject") and not a.Visible then return false end
		if a:IsA("LayerCollector") and not a.Enabled then return false end
		a = a.Parent
	end
	return a == pg
end

local function usable(o)
	return o:IsA("GuiButton") and o.Active and o.Selectable
		and o.AbsoluteSize.X > 4 and o.AbsoluteSize.Y > 4 and shown(o)
end

local function menuOpen()
	local blur = Lighting:FindFirstChild("PanelBlur")
	if blur and blur.Enabled then return true end
	for _, screen in pg:GetChildren() do
		if screen:IsA("ScreenGui") and screen:GetAttribute("Open") == true then return true end
	end
	return false
end

local function panel()
	local camera = workspace.CurrentCamera
	local view = camera and camera.ViewportSize.X * camera.ViewportSize.Y or 1
	local pick, order, size = nil, nil, nil
	for _, screen in pg:GetChildren() do
		if screen:IsA("ScreenGui") and screen.Enabled then
			local top, area = nil, 0
			for _, d in screen:GetDescendants() do
				if d:IsA("GuiObject") and not SKIP[d.Name] and d.Visible then
					local a = d.AbsoluteSize.X * d.AbsoluteSize.Y
					if a > area and shown(d) then
						for _, c in d:GetDescendants() do
							if usable(c) then top, area = d, a break end
						end
					end
				end
			end
			if top and (screen:GetAttribute("Open") == true or area >= view * 0.35) then
				if not pick or screen.DisplayOrder > order or (screen.DisplayOrder == order and area > size) then
					pick, order, size = top, screen.DisplayOrder, area
				end
			end
		end
	end
	return pick
end

local function choose(root)
	for _, name in PREFERRED do
		for _, d in root:GetDescendants() do
			if d.Name == name and usable(d) then return d end
		end
	end
	local pick, score = nil, math.huge
	for _, d in root:GetDescendants() do
		if usable(d) and d.Name ~= "Close" then
			local v = d.AbsolutePosition.Y * 4 + d.AbsolutePosition.X
			if v < score then pick, score = d, v end
		end
	end
	if pick then return pick end
	local close = root:FindFirstChild("Close", true)
	return close and usable(close) and close or nil
end

local function release()
	if not group then return end
	if Gui.SelectedObject and Gui.SelectedObject:IsDescendantOf(group) then Gui.SelectedObject = nil end
	group.SelectionGroup = false
	group = nil
end

local function hudEntry()
	for _, name in ENTRY do
		for _, screen in pg:GetChildren() do
			if screen:IsA("ScreenGui") and screen.Enabled then
				for _, d in screen:GetDescendants() do
					if d.Name == name and usable(d) then return d end
				end
			end
		end
	end
	return nil
end

local function drop()
	padUI = false
	if Gui.SelectedObject then Gui.SelectedObject = nil end
end

UIS.InputBegan:Connect(function(input)
	if not DPAD[input.KeyCode] or not pad() or menuOpen() then return end
	padUI = true
	if not Gui.SelectedObject then Gui.SelectedObject = hudEntry() end
end)

UIS.InputChanged:Connect(function(input)
	if input.KeyCode ~= Enum.KeyCode.Thumbstick1 or input.Position.Magnitude < 0.2 then return end
	if not menuOpen() then drop() end
end)

UIS.LastInputTypeChanged:Connect(function()
	if not pad() then drop() end
end)

local elapsed = 0
Run.Heartbeat:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.15 then return end
	elapsed = 0
	if not pad() then
		release()
		drop()
		return
	end
	if not menuOpen() then
		release()
		local current = Gui.SelectedObject
		if padUI and not (current and usable(current)) then Gui.SelectedObject = hudEntry() end
		return
	end
	local current = Gui.SelectedObject
	if group and current and current:IsDescendantOf(group) and usable(current) then return end
	local root = panel()
	if not root then release() return end
	if group ~= root then
		if group then group.SelectionGroup = false end
		group = root
		root.SelectionGroup = true
		root.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
		root.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
		root.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
		root.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
		for _, screen in pg:GetChildren() do
			if screen:IsA("ScreenGui") then
				for _, d in screen:GetDescendants() do
					if SKIP[d.Name] and d:IsA("GuiButton") then d.Selectable = false end
				end
			end
		end
	end
	Gui.SelectedObject = choose(root)
end)