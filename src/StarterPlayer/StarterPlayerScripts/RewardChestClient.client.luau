local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("FreeReward")
local openPanel = RS.Remotes:FindFirstChild("OpenPanel")

local gui = Instance.new("ScreenGui")
gui.Name = "RewardNotice"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 41
gui.Parent = plr:WaitForChild("PlayerGui")

local note = Instance.new("TextLabel")
note.Name = "Note"
note.BackgroundTransparency = 1
note.AnchorPoint = Vector2.new(0.5, 0.5)
note.Position = UDim2.fromScale(0.5, 0.26)
note.Size = UDim2.fromOffset(820, 58)
note.Font = Enum.Font.FredokaOne
note.TextScaled = true
note.Text = ""
note.Visible = false
note.Parent = gui

local cap = Instance.new("UITextSizeConstraint")
cap.MaxTextSize = 36
cap.Parent = note

local edge = Instance.new("UIStroke")
edge.Color = Color3.fromRGB(22, 10, 10)
edge.Thickness = 4
edge.Parent = note

local token = 0
local function say(text, colour)
    note.Text = text
    note.TextColor3 = colour or Color3.fromRGB(255, 78, 78)
    note.Visible = true
    token += 1
    local mine = token
    task.delay(2.6, function()
        if token == mine then note.Visible = false end
    end)
end

local state = { claimed = false, joined = false }

remote.OnClientEvent:Connect(function(action, arg)
    if action == "state" and type(arg) == "table" then
        state.claimed = arg.claimed == true
        state.joined = arg.joined == true
    elseif action == "granted" then
        state.claimed = true
        say("Reward claimed!", Color3.fromRGB(126, 255, 120))
    elseif action == "denied" then
        if arg == "already claimed" then
            say("You already claimed the group reward")
        elseif arg == "join the group first" then
            say("Join the group first")
        else
            say("Reward unavailable")
        end
    end
end)

task.spawn(function()
    task.wait(2)
    remote:FireServer("get")
end)

task.spawn(function()
    local map = workspace:WaitForChild("GameWorld")
    local rewards = map:WaitForChild("Rewards", 60)
    local ring = rewards and rewards:WaitForChild("GroupChestRing", 60)
    if not ring then
        warn("[REWARDS] no GroupChestRing - the group reward window only opens from the HUD")
        return
    end
    local cf, size = ring:GetBoundingBox()
    local centre = cf.Position
    local radius = math.max(size.X, size.Z) / 2
    local inside = false
    while true do
        task.wait(0.15)
        local ch = plr.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if root then
            local flat = Vector3.new(root.Position.X - centre.X, 0, root.Position.Z - centre.Z).Magnitude
            local level = math.abs(root.Position.Y - centre.Y) < 12
            if not inside and level and flat <= radius then
                inside = true

                remote:FireServer("get")
                if state.claimed then
                    say("You already claimed the group reward")
                end
                if openPanel then
                    openPanel:Fire("FreeRewards")
                else
                    say("The rewards window hasn't loaded yet")
                end
            elseif inside and (flat > radius + 3 or not level) then
                inside = false

                if _G.ClosePanels then pcall(_G.ClosePanels) end
            end
        end
    end
end)