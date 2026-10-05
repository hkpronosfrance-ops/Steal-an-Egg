local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")

local plr = Players.LocalPlayer
local remotes = RS:WaitForChild("Remotes")
local Remote = remotes:WaitForChild("Egg")

local ICON = {
    shoe  = "rbxassetid://126213576980021",
    studs = "rbxassetid://138926013267839",
    rays  = "rbxassetid://75235337881072",
    glow  = "rbxassetid://110083852572719",
}

local Money = require(RS:WaitForChild("MonetizationConfig"))
local PACKS = {}
for i, e in ipairs(Money.SPEED_PACKS) do
    PACKS[i] = { key = e.key, text = (tostring(e.label or e.key):gsub(" SPEED$", "")) }
end

local PACK_BY_ZONE = Money.BOSS_HIT_PACK_BY_ZONE or {}

local function packFor(zone)
    local i = PACK_BY_ZONE[tonumber(zone) or 1] or #PACKS
    return PACKS[i] or PACKS[#PACKS]
end

local REF_H = 1005
local SIZE = 1.2
local W, H = 220, 62
local INK = Color3.fromRGB(12, 60, 16)

local SHOE_SIDE, ROW_GAP, PAD_X = 50, 8, 20

local gui = Instance.new("ScreenGui")
gui.Name = "BossHitOffer"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 45
gui.Parent = plr:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.Name = "Offer"
holder.AnchorPoint = Vector2.new(0.5, 0)
holder.Position = UDim2.new(0.5, 0, 0, 62)
holder.Size = UDim2.fromOffset(W, H)
holder.BackgroundTransparency = 1
holder.Visible = false
holder.Parent = gui

local popScale = Instance.new("UIScale")
popScale.Scale = 0
popScale.Parent = holder

local function fitScale()
    local cam = workspace.CurrentCamera
    if not cam then return 1 end
    return math.clamp(cam.ViewportSize.Y / REF_H, 0.6, 1.25) * SIZE
end

local rays = Instance.new("ImageLabel")
rays.Name = "Rays"
rays.BackgroundTransparency = 1
rays.Image = ICON.rays
rays.AnchorPoint = Vector2.new(0.5, 0.5)
rays.Position = UDim2.fromScale(0.5, 0.5)
rays.Size = UDim2.fromOffset(220, 220)
rays.ImageTransparency = 0.1
rays.ZIndex = 1
rays.Parent = holder

local glow = Instance.new("ImageLabel")
glow.Name = "Glow"
glow.BackgroundTransparency = 1
glow.Image = ICON.glow
glow.AnchorPoint = Vector2.new(0.5, 0.5)
glow.Position = UDim2.fromScale(0.5, 0.5)
glow.Size = UDim2.fromOffset(190, 140)
glow.ImageTransparency = 0.3
glow.ZIndex = 2
glow.Parent = holder

local button = Instance.new("TextButton")
button.Name = "Banner"
button.Text = ""
button.AutoButtonColor = false
button.AnchorPoint = Vector2.new(0.5, 0.5)
button.Position = UDim2.fromScale(0.5, 0.5)
button.Size = UDim2.fromScale(1, 1)
button.BackgroundColor3 = Color3.new(1, 1, 1)
button.BorderSizePixel = 0
button.ZIndex = 3
button.Parent = holder

local hoverScale = Instance.new("UIScale")
hoverScale.Parent = button

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = button

    local s = Instance.new("UIStroke")
    s.Color = INK
    s.Thickness = 4
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = button

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(20, 188, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(34, 236, 124)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(20, 198, 255)),
    })
    g.Parent = button
end

local studs = Instance.new("ImageLabel")
studs.Name = "Studs"
studs.BackgroundTransparency = 1
studs.Image = ICON.studs
studs.ScaleType = Enum.ScaleType.Tile
studs.TileSize = UDim2.fromOffset(22, 22)
studs.ImageTransparency = 0.72
studs.Size = UDim2.fromScale(1, 1)
studs.ZIndex = 4
studs.Parent = button
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 5)
    c.Parent = studs
end

local rim = Instance.new("Frame")
rim.Name = "Rim"
rim.BackgroundTransparency = 1
rim.Position = UDim2.fromOffset(3, 3)
rim.Size = UDim2.new(1, -6, 1, -6)
rim.ZIndex = 5
rim.Parent = button
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = rim
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(190, 250, 255)
    s.Transparency = 0.35
    s.Thickness = 2
    s.Parent = rim
end

local gloss = Instance.new("Frame")
gloss.Name = "Gloss"
gloss.BackgroundColor3 = Color3.new(1, 1, 1)
gloss.BackgroundTransparency = 0.84
gloss.BorderSizePixel = 0
gloss.Position = UDim2.fromOffset(5, 5)
gloss.Size = UDim2.new(1, -10, 0.4, -5)
gloss.ZIndex = 5
gloss.Parent = button
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 3)
    c.Parent = gloss
end

local row = Instance.new("Frame")
row.Name = "Row"
row.BackgroundTransparency = 1
row.Size = UDim2.fromScale(1, 1)
row.ZIndex = 6
row.Parent = button
do
    local l = Instance.new("UIListLayout")
    l.FillDirection = Enum.FillDirection.Horizontal
    l.HorizontalAlignment = Enum.HorizontalAlignment.Center
    l.VerticalAlignment = Enum.VerticalAlignment.Center
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0, ROW_GAP)
    l.Parent = row
end

local shoe = Instance.new("ImageLabel")
shoe.Name = "Shoe"
shoe.BackgroundTransparency = 1
shoe.Image = ICON.shoe
shoe.ScaleType = Enum.ScaleType.Fit
shoe.Size = UDim2.fromOffset(SHOE_SIDE, SHOE_SIDE)
shoe.LayoutOrder = 1
shoe.ZIndex = 7
shoe.Parent = row

local amount = Instance.new("TextLabel")
amount.Name = "Amount"
amount.BackgroundTransparency = 1
amount.AutomaticSize = Enum.AutomaticSize.X
amount.Size = UDim2.fromOffset(0, 60)
amount.Font = Enum.Font.FredokaOne
amount.Text = "+1B"
amount.TextSize = 52
amount.TextColor3 = Color3.new(1, 1, 1)
amount.LayoutOrder = 2
amount.ZIndex = 7
amount.Parent = row
do
    local s = Instance.new("UIStroke")
    s.Color = INK
    s.Thickness = 4
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = amount
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new(Color3.fromRGB(150, 255, 120), Color3.fromRGB(46, 220, 44))
    g.Parent = amount
end

local current
local token = 0

local function fitWidth(text)
    local t = TextService:GetTextSize(text, amount.TextSize, amount.Font, Vector2.new(1000, 200))
    holder.Size = UDim2.fromOffset(PAD_X * 2 + SHOE_SIDE + ROW_GAP + t.X, H)
end

local POP = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SHUT = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local QUICK = TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local spin
local function spinRays(on)
    if on and not spin then
        spin = RunService.RenderStepped:Connect(function(dt)
            rays.Rotation = (rays.Rotation + dt * 40) % 360
        end)
    elseif not on and spin then
        spin:Disconnect()
        spin = nil
    end
end

local function hide(mine)
    if mine ~= token then return end
    local t = TweenService:Create(popScale, SHUT, { Scale = 0 })
    t:Play()
    t.Completed:Connect(function()
        if mine ~= token then return end
        holder.Visible = false
        spinRays(false)
        current = nil
    end)
end

local function show(zone, stun)
    current = packFor(zone)
    amount.Text = current.text
    fitWidth(current.text)
    token += 1
    local mine = token

    local wasVisible = holder.Visible
    holder.Visible = true
    spinRays(true)
    if not wasVisible then popScale.Scale = 0 end
    TweenService:Create(popScale, POP, { Scale = fitScale() }):Play()

    hoverScale.Scale = 1.12
    TweenService:Create(hoverScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()

    local hold = math.max(4, (tonumber(stun) or 2) + 2.5)
    task.delay(hold, function() hide(mine) end)
end

button.MouseEnter:Connect(function()
    TweenService:Create(hoverScale, QUICK, { Scale = 1.06 }):Play()
end)
button.MouseLeave:Connect(function()
    TweenService:Create(hoverScale, QUICK, { Scale = 1 }):Play()
end)
button.MouseButton1Down:Connect(function()
    TweenService:Create(hoverScale, QUICK, { Scale = 0.96 }):Play()
end)
button.MouseButton1Up:Connect(function()
    TweenService:Create(hoverScale, QUICK, { Scale = 1.06 }):Play()
end)

button.MouseButton1Click:Connect(function()
    if not current then return end
    local key = current.key
    hide(token)
    local shop = remotes:FindFirstChild("Shop")
    if shop then
        shop:FireServer("buy", key)
    elseif _G.OpenShop then
        _G.OpenShop(key)
    end
end)

Remote.OnClientEvent:Connect(function(kind, data)
    if kind ~= "BossHit" then return end
    data = type(data) == "table" and data or {}
    show(data.zone, data.stun)
end)

_G.BossHitOffer = show