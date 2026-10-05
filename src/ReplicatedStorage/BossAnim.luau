local A = {}

local ANIM_NAMES = { "Idle", "Run", "Attack", "Sleep", "Wake" }

function A.animations(model)
	local found, any = {}, false
	for _, name in ipairs(ANIM_NAMES) do
		local id
		for _, c in ipairs(model:GetChildren()) do
			if c:IsA("Animation") and c.Name:lower() == name:lower() and c.AnimationId ~= "" then id = c.AnimationId break end
		end
		if not id then
			local v = model:GetAttribute(name) or model:GetAttribute(name .. "Animation")
			local digits = type(v) == "number" and v > 0 and tostring(math.floor(v))
				or type(v) == "string" and v:match("%d+")
			if digits and tonumber(digits) and tonumber(digits) > 0 then id = "rbxassetid://" .. digits end
		end
		if id then found[name] = id any = true end
	end
	return any and found or nil
end

function A.embedded(model)
	local folder = model:FindFirstChild("Animations")
	if not folder then return nil end
	local found, any = {}, false
	for _, name in ipairs(ANIM_NAMES) do
		local k = folder:FindFirstChild(name)
		if k and k:IsA("KeyframeSequence") then found[name] = k any = true end
	end
	return any and found or nil
end

function A.animated(model)
	return A.animations(model) ~= nil or A.embedded(model) ~= nil
end

function A.animRoot(model)
	local root = model:FindFirstChild("HumanoidRootPart", true)
	if root and root:IsA("BasePart") then return root end
	if model.PrimaryPart then return model.PrimaryPart end
	local isChild, candidates = {}, {}
	for _, j in ipairs(model:GetDescendants()) do
		if j:IsA("Motor6D") and j.Part0 and j.Part1 then
			isChild[j.Part1] = true
			candidates[j.Part0] = true
		end
	end
	for p in pairs(candidates) do
		if not isChild[p] then return p end
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

return A