local WHITE = Color3.new(1, 1, 1)
local GRADIENT = "HoloGradient"

local function pair(c)
	local h, s, v = c:ToHSV()
	if s < 0.15 then
		return Color3.fromRGB(255, 255, 255), Color3.fromRGB(176, 204, 255)
	end
	if h > 0.45 and h < 0.75 then
		return Color3.fromHSV(0.53, 0.30, 1), Color3.fromHSV(0.61, 0.85, 0.95)
	end
	local top = Color3.fromHSV((h + 0.045) % 1, s * 0.8, math.min(1, v * 1.1 + 0.12))
	local bottom = Color3.fromHSV((h - 0.06) % 1, math.min(1, s * 1.1 + 0.08), v * 0.86)
	return top, bottom
end

local function paint(label, g)
	local base = label.TextColor3
	if base == WHITE and label:GetAttribute("HoloBase") then
		return
	end
	label:SetAttribute("HoloBase", base)
	local top, bottom = pair(base)
	g.Color = ColorSequence.new(top, bottom)
	label.TextColor3 = WHITE
end

local dressed = setmetatable({}, { __mode = "k" })

local function wanted(label)
	if label:FindFirstAncestorWhichIsA("BillboardGui") then return true end
	local sg = label:FindFirstAncestorWhichIsA("SurfaceGui")
	if not sg then return false end
	return sg.Name == "SafeZoneSign"
		or label:FindFirstAncestor("Leaderboards") ~= nil
		or label:FindFirstAncestor("ZoneSign") ~= nil
end

local function dress(label)
	if dressed[label] or not label.Parent then return end
	if not wanted(label) then return end
	local g = label:FindFirstChildOfClass("UIGradient")
	if g and g.Name ~= GRADIENT then return end
	if not g then
		g = Instance.new("UIGradient")
		g.Name = GRADIENT
		g.Rotation = 90
		g.Parent = label
	end
	local was = label:GetAttribute("HoloBase")
	if typeof(was) == "Color3" and label.TextColor3 == WHITE then
		label.TextColor3 = was
	end
	dressed[label] = true
	paint(label, g)
	label:GetPropertyChangedSignal("TextColor3"):Connect(function()
		if label.TextColor3 ~= WHITE then paint(label, g) end
	end)
end

workspace.DescendantAdded:Connect(function(d)
	if d:IsA("TextLabel") or d:IsA("TextButton") then
		task.defer(dress, d)
	end
end)
for _, d in ipairs(workspace:GetDescendants()) do
	if d:IsA("TextLabel") or d:IsA("TextButton") then dress(d) end
end