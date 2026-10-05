local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local BLEND_SPEED = 10
local GRIP_GAP = 0.05
local GRIP_BACK = 0.35
local GRIP_DOWN = 0.15
local POLE = Vector3.new(0.7, -1, 0.8)
local DOWN = Vector3.new(0, -1, 0)
local FORWARD = Vector3.new(0, 0, -1)

local blend = setmetatable({}, { __mode = "k" })
local lastTarget = setmetatable({}, { __mode = "k" })
local rigs = setmetatable({}, { __mode = "k" })

local function rotBetween(a, b)
	local dot = math.clamp(a:Dot(b), -1, 1)
	local axis = a:Cross(b)
	if axis.Magnitude < 1e-6 then
		return dot > 0 and CFrame.identity or CFrame.fromAxisAngle(Vector3.xAxis, math.pi)
	end
	return CFrame.fromAxisAngle(axis.Unit, math.acos(dot))
end

local function basis(up, hint, fallback)
	local look = hint - up * hint:Dot(up)
	if look.Magnitude < 1e-3 then
		look = fallback - up * fallback:Dot(up)
	end
	look = look.Unit
	return CFrame.fromMatrix(Vector3.zero, look:Cross(up), up, -look)
end

local function isJoint(j)
	return j ~= nil and (j:IsA("Motor6D") or j:IsA("AnimationConstraint"))
end

local function frames(j)
	if j:IsA("Motor6D") then return j.C0, j.C1 end
	local a0, a1 = j.Attachment0, j.Attachment1
	return a0 and a0.CFrame or CFrame.identity, a1 and a1.CFrame or CFrame.identity
end

local function armOf(char, side)
	local upper = char:FindFirstChild(side .. "UpperArm")
	local lower = char:FindFirstChild(side .. "LowerArm")
	local hand = char:FindFirstChild(side .. "Hand")
	local sh = upper and upper:FindFirstChild(side .. "Shoulder")
	local el = lower and lower:FindFirstChild(side .. "Elbow")
	local wr = hand and hand:FindFirstChild(side .. "Wrist")
	if isJoint(sh) and isJoint(el) and isJoint(wr) then
		return { sh = sh, el = el, wr = wr, hand = hand, sign = (side == "Right") and 1 or -1 }
	end
	return nil
end

local function rigOf(char)
	local rig = rigs[char]
	if rig and rig.torso.Parent == char and rig.arms[1].sh.Parent and rig.arms[2].sh.Parent then
		return rig
	end
	local torso = char:FindFirstChild("UpperTorso")
	local right, left = armOf(char, "Right"), armOf(char, "Left")
	if not (torso and right and left) then
		rigs[char] = nil
		return nil
	end
	rig = { torso = torso, arms = { right, left } }
	rigs[char] = rig
	return rig
end

local function solve(arm, target, w)
	local sh, el, wr = arm.sh, arm.el, arm.wr
	local s0, s1 = frames(sh)
	local e0, e1 = frames(el)
	local w0, w1 = frames(wr)
	local S = s0.Position
	local v1 = e0.Position - s1.Position
	local v2 = w0.Position - e1.Position
	local L1 = v1.Magnitude
	local L2 = v2.Magnitude + w1.Position.Magnitude
	if L1 < 1e-3 or L2 < 1e-3 then return end

	local toT = target - S
	local dist = toT.Magnitude
	local dir = dist > 1e-4 and toT / dist or DOWN
	local d = math.clamp(dist, math.abs(L1 - L2) + 0.02, L1 + L2 - 0.02)
	local pole = Vector3.new(POLE.X * arm.sign, POLE.Y, POLE.Z)
	local perp = pole - dir * pole:Dot(dir)
	perp = perp.Magnitude > 1e-4 and perp.Unit or Vector3.zAxis
	local cosA = math.clamp((L1 * L1 + d * d - L2 * L2) / (2 * L1 * d), -1, 1)
	local sinA = math.sqrt(1 - cosA * cosA)
	local E = S + dir * (cosA * L1) + perp * (sinA * L1)
	local T = S + dir * d

	local upperRot = basis((S - E).Unit, T - E, FORWARD) * rotBetween(DOWN, v1.Unit):Inverse()
	local upperCF = CFrame.new(S - upperRot * s1.Position) * upperRot
	sh.Transform = sh.Transform:Lerp(s0:Inverse() * upperCF * s1, w)

	local elbow = upperCF * e0.Position
	local lowerUp = elbow - T
	lowerUp = lowerUp.Magnitude > 1e-4 and lowerUp.Unit or -DOWN
	local lowerRot = basis(lowerUp, lowerUp:Cross(upperCF.RightVector), upperCF.LookVector)
		* rotBetween(DOWN, v2.Unit):Inverse()
	local lowerCF = CFrame.new(elbow - lowerRot * e1.Position) * lowerRot
	el.Transform = el.Transform:Lerp(e0:Inverse() * upperCF:Inverse() * lowerCF * e1, w)
	wr.Transform = wr.Transform:Lerp(CFrame.identity, w)
end

RunService.Stepped:Connect(function(_, dt)
	for _, p in ipairs(Players:GetPlayers()) do
		local char = p.Character
		if char then
			local center = p:GetAttribute("CarryCenter")
			local size = p:GetAttribute("CarrySize")
			local on = p:GetAttribute("CarryingEgg") == true
				and typeof(center) == "Vector3" and typeof(size) == "Vector3"
			if on then lastTarget[char] = { center, size } end

			local w = math.clamp((blend[char] or 0) + (on and dt or -dt) * BLEND_SPEED, 0, 1)
			blend[char] = w > 0 and w or nil

			local target = lastTarget[char]
			if w > 0 and target then
				local rig = rigOf(char)
				if rig then
					local c, half = target[1], target[2] / 2
					local k = w * w * (3 - 2 * w)
					for _, arm in ipairs(rig.arms) do
						local grip = c + Vector3.new(
							arm.sign * (half.X * 0.94 + GRIP_GAP + arm.hand.Size.X / 2),
							-half.Y * GRIP_DOWN,
							half.Z * GRIP_BACK)
						solve(arm, grip, k)
					end
				end
			elseif not on then
				lastTarget[char] = nil
			end
		end
	end
end)