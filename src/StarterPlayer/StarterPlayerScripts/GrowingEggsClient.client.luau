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

local ICON_EGG = "rbxassetid://103180943014941"
local ICON_GLOW = "rbxassetid://110083852572719"

local W, H = 440, 390
local HEAD_H = 66
local ROW_H = 74
local GAP_TO_TILES = 16

local gui = Instance.new("ScreenGui")
gui.Name = "GrowingEggsGui"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 45
gui.Parent = plr:WaitForChild("PlayerGui")

local shell = Instance.new("Frame")
shell.Name = "GrowingEggs"
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

UIKit.boldLabel({
    parent = header, name = "Title", size = UDim2.new(1, -190, 1, 0), position = UDim2.fromOffset(18, 0),
    text = "GROWING EGGS", align = Enum.TextXAlignment.Left,
    textSize = 30, strokeW = 4, strokeColour = PANEL_INK, zindex = 22,
})

local GROW_W, GROW_H = 150, 44
UIKit.button({
    parent = header, name = "GrowAll", tone = K.inProgress, text = "GROW ALL", textSize = 22,
    size = UDim2.fromOffset(GROW_W, GROW_H),
    position = UDim2.new(1, -(GROW_W + 14), 0.5, -GROW_H / 2), zindex = 20,
    onClick = function() remote:FireServer("growAll") end,
})

local shut
UIKit.button({
    parent = shell, name = "Hide", tone = K.close, text = ">", textSize = 36,
    size = UDim2.fromOffset(54, 58), position = UDim2.new(0, -68, 0.5, -29), zindex = 12,
    onClick = function() if shut then shut() end end,
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
    text = "No eggs growing\nPlace eggs on your plot", textSize = 24, strokeW = 3,
    colour = SECOND, wrapped = true, zindex = 20,
})

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

        shell.Position = UDim2.new(0, tiles.AbsolutePosition.X + tiles.AbsoluteSize.X, 0.5, 0)
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

local function myEggs()
    local out = {}
    local map = workspace:FindFirstChild("GameWorld")
    local placed = map and map:FindFirstChild("PlacedEggs")
    if not placed then return out end
    for _, m in ipairs(placed:GetChildren()) do
        if m:GetAttribute("OwnerUserId") == plr.UserId and not m:GetAttribute("Hatching") then
            table.insert(out, m)
        end
    end
    table.sort(out, function(a, b)
        local ra, rb = a:GetAttribute("Ready") == true, b:GetAttribute("Ready") == true
        if ra ~= rb then return ra end
        return (a:GetAttribute("HatchAt") or 0) < (b:GetAttribute("HatchAt") or 0)
    end)
    return out
end

local function preview(parent, model)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Image = ICON_GLOW
    glow.ImageTransparency = 0.55
    glow.Size = UDim2.fromOffset(78, 78)
    glow.Position = UDim2.fromOffset(-2, -2)
    glow.ZIndex = 17
    glow.Parent = parent

    local vp = Instance.new("ViewportFrame")
    vp.Name = "Egg"
    vp.BackgroundTransparency = 1
    vp.Size = UDim2.fromOffset(62, 62)
    vp.Position = UDim2.fromOffset(6, 6)
    vp.Ambient = Color3.fromRGB(190, 190, 190)
    vp.LightColor = WHITE
    vp.LightDirection = Vector3.new(-1, -1.5, -1)
    vp.ZIndex = 18
    vp.Parent = parent

    local ok = pcall(function()
        local copy = Instance.new("Model")
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                local c = p:Clone()
                c:ClearAllChildren()
                c.Anchored = true
                c.Parent = copy
            end
        end
        if #copy:GetChildren() == 0 then error("no parts streamed in") end

        require(game:GetService("ReplicatedStorage").Shared.AssetQueue).want(copy)
        copy.Parent = vp
        local cf, size = copy:GetBoundingBox()
        local cam = Instance.new("Camera")
        cam.FieldOfView = 40
        local dist = math.max(size.X, size.Y, size.Z) * 1.9 + 0.4
        cam.CFrame = CFrame.lookAt(cf.Position + Vector3.new(dist * 0.35, size.Y * 0.2, dist), cf.Position)
        cam.Parent = vp
        vp.CurrentCamera = cam
    end)
    if not ok then
        vp:Destroy()
        local icon = Instance.new("ImageLabel")
        icon.Name = "Egg"
        icon.BackgroundTransparency = 1
        icon.Image = ICON_EGG
        icon.ScaleType = Enum.ScaleType.Fit
        icon.Size = UDim2.fromOffset(56, 56)
        icon.Position = UDim2.fromOffset(9, 9)
        icon.ZIndex = 18
        icon.Parent = parent
    end
end

local rows = {}

local function buildRow(model, order)
    local ready = model:GetAttribute("Ready") == true

    local holder = Instance.new("Frame")
    holder.Name = "Egg_" .. idOf(model)
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

    local entry = { model = model, ready = ready }

    if ready then
        UIKit.button({
            parent = row, name = "Open", tone = K.ready, text = "OPEN", textSize = 26,
            size = UDim2.fromOffset(170, 50), position = UDim2.new(0.5, 38, 0.5, 0),
            anchor = Vector2.new(0.5, 0.5), zindex = 18,
            onClick = function() remote:FireServer("hatchEgg", model) end,
        })
    else
        local SKIP_W = 52
        local track = Instance.new("Frame")
        track.Name = "Track"
        track.AnchorPoint = Vector2.new(0, 0.5)
        track.Position = UDim2.new(0, 80, 0.5, 0)
        track.Size = UDim2.new(1, -(80 + SKIP_W + 22), 0, 40)
        track.BackgroundColor3 = Color3.fromRGB(14, 12, 22)
        track.BorderSizePixel = 0
        track.ClipsDescendants = true
        track.ZIndex = 18
        track.Parent = row
        UIKit.corner(track, 8)
        UIKit.stroke(track, K.outline, 2, 0)

        local fill = Instance.new("Frame")
        fill.Name = "Fill"
        fill.BackgroundColor3 = K.ready.base
        fill.BorderSizePixel = 0
        fill.Size = UDim2.fromScale(0, 1)
        fill.ZIndex = 19
        fill.Parent = track
        UIKit.corner(fill, 8)

        local clock = UIKit.boldLabel({
            parent = track, name = "Clock", size = UDim2.fromScale(1, 1),
            text = "", textSize = 24, strokeW = 3, zindex = 21,
        })

        UIKit.button({
            parent = row, name = "Skip", tone = K.ready, text = ">>", textSize = 26,
            size = UDim2.fromOffset(SKIP_W, 48), position = UDim2.new(1, -(SKIP_W + 12), 0.5, -24),
            zindex = 18,
            onClick = function() remote:FireServer("skipEgg", model) end,
        })

        entry.fill = fill
        entry.clock = clock
    end
    return entry
end

local lastSig = ""

local function refresh(force)
    local list = myEggs()
    local parts = {}
    for _, m in ipairs(list) do
        table.insert(parts, idOf(m) .. (m:GetAttribute("Ready") and "r" or "g"))
    end
    local sig = table.concat(parts, ",")

    if force or sig ~= lastSig then
        lastSig = sig
        for _, c in ipairs(body:GetChildren()) do
            if c:IsA("GuiObject") then c:Destroy() end
        end
        rows = {}
        for i, m in ipairs(list) do
            rows[i] = buildRow(m, i)
        end
        empty.Visible = #list == 0
    end

    local now = workspace:GetServerTimeNow()
    for _, r in ipairs(rows) do
        if r.clock and r.model.Parent then
            local left = math.max(0, (r.model:GetAttribute("HatchAt") or 0) - now)
            local total = tonumber(r.model:GetAttribute("HatchTotal"))
                or Cfg.hatchTime(r.model:GetAttribute("EggZone") or 1,
                    r.model:GetAttribute("EggSize") or 1, r.model:GetAttribute("EggTier") or 1)
            local done = (total and total > 0) and (1 - left / total) or 0
            r.fill.Size = UDim2.fromScale(math.clamp(done, 0.03, 1), 1)
            r.clock.Text = Cfg.fmtTime(left)
        end
    end
end

local isOpen = false

local function open()
    isOpen = true
    place()
    refresh(true)
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
        if id == "GrowingEggs" then
            if isOpen then shut() else open() end
        elseif id == "ActivePets" and isOpen then
            shut()
        end
    end)
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
    if not isOpen then return end
    acc += dt
    if acc < 0.2 then return end
    acc = 0
    place()
    refresh(false)
end)

_G.OpenGrowingEggs = open