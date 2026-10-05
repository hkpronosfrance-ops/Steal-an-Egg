local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Cfg = require(RS:WaitForChild("EggConfig"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("Nest")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local SECOND = UIKit.SECOND
local PANEL_INK = Color3.fromRGB(43, 23, 64)
local INCOME_COLOUR = Color3.fromRGB(126, 246, 118)
local ICON_GLOW = "rbxassetid://110083852572719"

local W, H = 470, 400
local HEAD_H = 66
local ROW_H = 78
local GAP_TO_TILES = 16

local money = Cfg.fmtMoney

local gui = Instance.new("ScreenGui")
gui.Name = "ActivePetsGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 45
gui.Parent = plr:WaitForChild("PlayerGui")

local shell = Instance.new("Frame")
shell.Name = "ActivePets"
shell.AnchorPoint = Vector2.new(1, 0.5)
shell.Position = UDim2.new(1, -120, 0.5, 0)
shell.Size = UDim2.fromOffset(W, H)
shell.BackgroundTransparency = 1
shell.Visible = false
shell.ZIndex = 10
shell.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = shell

local PANEL_TONE = {
    hi = Color3.fromRGB(64, 70, 88),
    base = Color3.fromRGB(38, 42, 56),
    sh = Color3.fromRGB(22, 24, 34),
}
local PANEL_ALPHA = 0.22
local frame = UIKit.block({
    parent = shell, name = "Frame", tone = PANEL_TONE, size = UDim2.fromOffset(W, H),
    radius = 15, outline = 3, shadowY = 7, bevel = false, stud = 15, studAlpha = 0.8, zindex = 10,
})
frame.BackgroundTransparency = PANEL_ALPHA
local underside = frame:FindFirstChild("Underside")
if underside then underside.BackgroundTransparency = PANEL_ALPHA end

local header = UIKit.block({
    parent = frame, name = "Header", tone = K.bar,
    size = UDim2.new(1, 0, 0, HEAD_H), radius = 12, outline = 3, stud = 10, studAlpha = 0.58,
    shadow = false, zindex = 14,
})

local title = UIKit.boldLabel({
    parent = header, name = "Title", size = UDim2.new(1, -270, 1, 0), position = UDim2.fromOffset(18, 0),
    text = "0/3 ACTIVE", align = Enum.TextXAlignment.Left,
    textSize = 30, strokeW = 4, strokeColour = PANEL_INK, zindex = 22,
})

local UP_W, UP_H = 240, 46
local upgradeBtn, upgradeEnabled, upgradeText, upgradeTone = UIKit.button({
    parent = header, name = "Upgrade", tone = K.ready, text = "+1 EQUIP", textSize = 19,
    size = UDim2.fromOffset(UP_W, UP_H),
    position = UDim2.new(1, -(UP_W + 12), 0.5, -UP_H / 2), zindex = 20,
    onClick = function() remote:FireServer("upgradePlot") end,
})

local shut
UIKit.button({
    parent = shell, name = "Hide", tone = K.close, text = ">", textSize = 36,
    size = UDim2.fromOffset(54, 58), position = UDim2.new(0, -68, 0.5, -29), zindex = 12,
    onClick = function() if shut then shut() end end,
})

local BEST_W, BEST_H = 250, 58
UIKit.button({
    parent = shell, name = "EquipBest", tone = K.ready, text = "EQUIP BEST", textSize = 28,
    size = UDim2.fromOffset(BEST_W, BEST_H), position = UDim2.new(1, -BEST_W, 1, 16), zindex = 12,
    onClick = function() remote:FireServer("equipBest") end,
})

local body = Instance.new("ScrollingFrame")
body.Name = "List"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(14, HEAD_H + 12)
body.Size = UDim2.new(1, -28, 1, -(HEAD_H + 26))
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.Y
body.ScrollingDirection = Enum.ScrollingDirection.Y
body.ScrollBarThickness = 6
body.ScrollBarImageColor3 = K.slab.hi
body.ZIndex = 14
body.Parent = frame
do
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 8)
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Parent = body
    local pad = Instance.new("UIPadding")

    pad.PaddingLeft = UDim.new(0, 5)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = body
end

local empty = UIKit.boldLabel({
    parent = frame, name = "Empty", size = UDim2.new(1, -40, 0, 70),
    position = UDim2.new(0.5, 0, 0, HEAD_H + 90), anchor = Vector2.new(0.5, 0),
    text = "No pets on your plot\nPress EQUIP BEST or place pets", textSize = 24, strokeW = 3,
    colour = SECOND, wrapped = true, zindex = 20,
})

local state = { count = 0, cap = 3, level = 1, maxLevel = 12, price = 0 }

local function paintHeader()
    title.Text = ("%d/%d ACTIVE"):format(state.count, state.cap)
    if state.level >= state.maxLevel then
        upgradeText("MAX LEVEL")
        upgradeTone(K.lock)
    else
        upgradeText(("+1 EQUIP [%s]"):format(money(state.price)))
        upgradeTone(K.ready)
    end
end
paintHeader()

local function tilesFrame()
    for _, g in ipairs(plr.PlayerGui:GetChildren()) do
        if g:IsA("ScreenGui") and g ~= gui then
            local t = g:FindFirstChild("RightTiles")
            if t then return t, g end
        end
    end
end

local function place()
    local tiles, tilesGui = tilesFrame()
    if tiles then
        gui.IgnoreGuiInset = tilesGui.IgnoreGuiInset
        local ts = tiles:FindFirstChildOfClass("UIScale")
        scale.Scale = math.clamp(ts and ts.Scale or 1, 0.55, 1)

        shell.Position = UDim2.new(0, tiles.AbsolutePosition.X + tiles.AbsoluteSize.X,
            0.5, -37 * scale.Scale)
    end
end

local function sidePanelOpen()
    for _, pair in ipairs({ { "GrowingEggsGui", "GrowingEggs" }, { "ActivePetsGui", "ActivePets" } }) do
        local g = plr.PlayerGui:FindFirstChild(pair[1])
        local s = g and g:FindFirstChild(pair[2])
        if s and s.Visible then return true end
    end
    return false
end

local function setTiles(on)
    local tiles = tilesFrame()
    if tiles then tiles.Visible = on end
end

local function restoreTiles()
    if not sidePanelOpen() then setTiles(true) end
end

local ids = setmetatable({}, { __mode = "k" })
local nextId = 0
local function idOf(model)
    if not ids[model] then
        nextId += 1
        ids[model] = nextId
    end
    return ids[model]
end

local function myPets()
    local out = {}
    local map = workspace:FindFirstChild("GameWorld")
    local folder = map and map:FindFirstChild("PlacedAnimals")
    if not folder then return out end
    for _, m in ipairs(folder:GetChildren()) do
        if m:GetAttribute("OwnerUserId") == plr.UserId then table.insert(out, m) end
    end
    table.sort(out, function(a, b)
        local ia, ib = tonumber(a:GetAttribute("Income")) or 0, tonumber(b:GetAttribute("Income")) or 0
        if ia ~= ib then return ia > ib end
        return idOf(a) < idOf(b)
    end)
    return out
end

local function preview(parent, model)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = ICON_GLOW
    glow.ImageTransparency = 0.55
    glow.Size = UDim2.fromOffset(80, 80)
    glow.Position = UDim2.fromOffset(-2, -1)
    glow.ZIndex = 17
    glow.Parent = parent

    local vp = Instance.new("ViewportFrame")
    vp.Name = "Pet"
    vp.BackgroundTransparency = 1
    vp.Size = UDim2.fromOffset(66, 66)
    vp.Position = UDim2.fromOffset(6, 6)
    vp.Ambient = Color3.fromRGB(200, 200, 200)
    vp.LightColor = WHITE
    vp.LightDirection = Vector3.new(-1, -1.5, -1)
    vp.ZIndex = 18
    vp.Parent = parent

    pcall(function()

        local pivot = model:GetPivot()
        local root = model:FindFirstChild(model:GetAttribute("RootPart") or "", true)
        local tip
        for _, name in ipairs({ "nose", "snout", "muzzle", "beak", "head" }) do
            for _, p in ipairs(model:GetDescendants()) do
                if p:IsA("BasePart") and p ~= root and p.Name:lower() == name then tip = p break end
            end
            if tip then break end
        end
        if root and root:IsA("BasePart") then
            local front = root.CFrame.LookVector
            if tip then front = tip.Position - root.Position end
            front = Vector3.new(front.X, 0, front.Z)
            if front.Magnitude > 1e-3 then
                pivot = CFrame.lookAt(root.Position, root.Position + front.Unit)
            end
        end
        local copy = Instance.new("Model")
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                local c = p:Clone()
                c:ClearAllChildren()
                c.Anchored = true
                c.CFrame = pivot:ToObjectSpace(p.CFrame)
                c.Parent = copy
            end
        end
        if #copy:GetChildren() == 0 then error("no parts streamed in") end

        require(game:GetService("ReplicatedStorage").Shared.AssetQueue).want(copy)
        copy.Parent = vp
        local cf, size = copy:GetBoundingBox()
        local dist = math.max(size.X, size.Y, size.Z) * 1.45 + 0.4
        local cam = Instance.new("Camera")
        cam.FieldOfView = 40

        local eye = Vector3.new(0.55, 0.3, -1).Unit
        cam.CFrame = CFrame.lookAt(cf.Position + eye * dist, cf.Position)
        cam.Parent = vp
        vp.CurrentCamera = cam
    end)
end

local function buildRow(model, order)
    local holder = Instance.new("Frame")
    holder.Name = "Pet_" .. idOf(model)
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.new(1, 0, 0, ROW_H + 5)
    holder.LayoutOrder = order
    holder.ZIndex = 14
    holder.Parent = body

    local row = UIKit.block({
        parent = holder, name = "Row", tone = K.thumb, size = UDim2.new(1, 0, 0, ROW_H),
        radius = 12, outline = 3, stud = 11, studAlpha = 0.7, bevel = false, zindex = 14,
    })
    preview(row, model)

    local tier = tonumber(model:GetAttribute("AnimalTier")) or 1
    local nameColour = (Cfg.TIERS[tier] and Cfg.TIERS[tier].color) or WHITE
    local UNEQ_W = 134
    UIKit.boldLabel({
        parent = row, name = "PetName", size = UDim2.new(1, -(84 + UNEQ_W + 24), 0, 28),
        position = UDim2.fromOffset(84, 10), align = Enum.TextXAlignment.Left,
        text = tostring(model:GetAttribute("Species") or model.Name), textSize = 22, strokeW = 3,
        colour = nameColour, truncate = Enum.TextTruncate.AtEnd, zindex = 20,
    })
    UIKit.boldLabel({
        parent = row, name = "Income", size = UDim2.new(1, -(84 + UNEQ_W + 24), 0, 24),
        position = UDim2.fromOffset(84, 40), align = Enum.TextXAlignment.Left,
        text = ("(%s/s)"):format(money(tonumber(model:GetAttribute("Income")) or 0)),
        textSize = 20, strokeW = 3, colour = INCOME_COLOUR, zindex = 20,
    })
    UIKit.button({
        parent = row, name = "Unequip", tone = K.close, text = "UNEQUIP", textSize = 22,
        size = UDim2.fromOffset(UNEQ_W, 50), position = UDim2.new(1, -(UNEQ_W + 12), 0.5, -25),
        zindex = 18,
        onClick = function() remote:FireServer("unequipPet", model) end,
    })
end

local lastSig = ""

local function refresh(force)
    local list = myPets()
    local parts = {}
    for _, m in ipairs(list) do table.insert(parts, idOf(m)) end
    local sig = table.concat(parts, ",")
    if force or sig ~= lastSig then
        local changed = sig ~= lastSig
        lastSig = sig
        for _, c in ipairs(body:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        for i, m in ipairs(list) do buildRow(m, i) end
        empty.Visible = #list == 0

        state.count = #list
        paintHeader()
        if changed then remote:FireServer("petsState") end
    end
end

remote.OnClientEvent:Connect(function(action, data)
    if action == "pets" and type(data) == "table" then
        state.count = tonumber(data.count) or state.count
        state.cap = tonumber(data.cap) or state.cap
        state.level = tonumber(data.level) or state.level
        state.maxLevel = tonumber(data.maxLevel) or state.maxLevel
        state.price = tonumber(data.price) or 0
        paintHeader()
    end
end)

local isOpen = false

local function open()
    isOpen = true
    place()
    refresh(true)
    remote:FireServer("petsState")
    shell.Visible = true
    setTiles(false)
    local target = scale.Scale
    scale.Scale = target * 0.85
    TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = target }):Play()
end

function shut()
    isOpen = false
    shell.Visible = false
    task.defer(restoreTiles)
end

local bus = RS.Remotes:WaitForChild("OpenPanel", 20)
if bus then
    bus.Event:Connect(function(id)
        if id == "ActivePets" then
            if isOpen then shut() else open() end
        elseif id == "GrowingEggs" and isOpen then
            shut()
        end
    end)
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
    if not isOpen then return end
    acc += dt
    if acc < 0.3 then return end
    acc = 0
    place()
    refresh(false)
end)

_G.OpenActivePets = open