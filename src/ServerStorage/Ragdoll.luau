local Ragdoll = {}

local SWING, TWIST = 42, 26

local function attach(part, cf, name)
    local a = Instance.new("Attachment")
    a.Name = name
    a.CFrame = cf
    a.Parent = part
    return a
end

local function limpLimbs(char, on)
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            if on then
                p:SetAttribute("RagdollWasCollide", p.CanCollide)
                p.CanCollide = true
            else
                local was = p:GetAttribute("RagdollWasCollide")
                if was ~= nil then p.CanCollide = was end
                p:SetAttribute("RagdollWasCollide", nil)
            end
        end
    end
end

function Ragdoll.on(char)
    if not char or char:GetAttribute("Ragdoll") then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    char:SetAttribute("Ragdoll", true)

    hum.AutoRotate = false
    hum.PlatformStand = true

    local sockets = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") then sockets[d.Name] = true end
    end

    local modern = 0
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("AnimationConstraint") and d.Enabled and sockets[d.Name .. "BallSocket"] then
            d.Enabled = false
            d:SetAttribute("RagdollOff", true)
            modern += 1
        end
    end

    if modern == 0 then
        for _, m in ipairs(char:GetDescendants()) do
            if m:IsA("Motor6D") and m.Part0 and m.Part1 and m.Name ~= "RootJoint" then
                local a0 = attach(m.Part0, m.C0, "RagdollA0")
                local a1 = attach(m.Part1, m.C1, "RagdollA1")
                local joint = Instance.new("BallSocketConstraint")
                joint.Name = "RagdollJoint"
                joint.Attachment0 = a0
                joint.Attachment1 = a1
                joint.LimitsEnabled = true
                joint.UpperAngle = SWING
                joint.TwistLimitsEnabled = true
                joint.TwistLowerAngle = -TWIST
                joint.TwistUpperAngle = TWIST
                joint.Parent = m.Part1
                local tag = Instance.new("ObjectValue")
                tag.Name = "RagdollMotor"
                tag.Value = m
                tag.Parent = joint
                m.Enabled = false
            end
        end
    end

    limpLimbs(char, true)
end

function Ragdoll.off(char)
    if not char or not char:GetAttribute("Ragdoll") then return end
    char:SetAttribute("Ragdoll", false)

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("AnimationConstraint") and d:GetAttribute("RagdollOff") then
            d.Enabled = true
            d:SetAttribute("RagdollOff", nil)
        end
    end

    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BallSocketConstraint") and d.Name == "RagdollJoint" then
            local tag = d:FindFirstChild("RagdollMotor")
            if tag and tag.Value then tag.Value.Enabled = true end
            d:Destroy()
        end
    end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("Attachment") and (d.Name == "RagdollA0" or d.Name == "RagdollA1") then
            d:Destroy()
        end
    end

    limpLimbs(char, false)

    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Parent then
        hum.PlatformStand = false
        hum.AutoRotate = true
        hum:ChangeState(Enum.HumanoidStateType.GettingUp)
    end
end

return Ragdoll