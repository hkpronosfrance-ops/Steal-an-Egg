local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Cfg = require(RS:WaitForChild("EggConfig"))
local U = require(RS:WaitForChild("UpgradeConfig"))

local plr = Players.LocalPlayer
local pg = plr:WaitForChild("PlayerGui")
local remote = RS:WaitForChild("Remotes"):WaitForChild("PlotUpgrade")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local INK = Color3.fromRGB(10, 12, 24)
local LEVEL_GREEN = Color3.fromRGB(120, 255, 100)
local ICON_ROBUX = "rbxassetid://102382554203100"
local ICON_ALERT = "rbxassetid://88282714087162"

local PPS = 100

local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens", 120)
local mills = map:WaitForChild("Treadmills", 120)

local money = Cfg.fmtMoney

local function robuxText(n)
    n = tonumber(n) or 0
    if n >= 1000 then
        return (("%.1fK"):format(n / 1000):gsub("%.0K", "K"))
    end
    return tostring(n)
end

local function label(parent, props)
    local t = Instance.new("TextLabel")
    t.Name = props.name
    t.BackgroundTransparency = 1
    t.Size = props.size
    t.Position = props.position
    t.Font = Enum.Font.FredokaOne
    t.TextSize = props.textSize
    t.TextColor3 = props.colour or WHITE
    t.TextXAlignment = props.align or Enum.TextXAlignment.Center
    t.Text = props.text or ""
    t.ZIndex = props.zindex or 5
    t.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = INK
    s.Thickness = props.strokeW or 4
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = t
    return t
end

local function icon(parent, image, size, x)
    local i = Instance.new("ImageLabel")
    i.Name = "Icon"
    i.BackgroundTransparency = 1
    i.Image = image
    i.ScaleType = Enum.ScaleType.Fit
    i.AnchorPoint = Vector2.new(0, 0.5)
    i.Position = UDim2.new(0, x, 0.5, 0)
    i.Size = UDim2.fromOffset(size, size)
    i.ZIndex = 12
    i.Parent = parent
    return i
end

local noteGui = Instance.new("ScreenGui")
noteGui.Name = "UpgradeNotice"
noteGui.ResetOnSpawn = false
noteGui.IgnoreGuiInset = true
noteGui.DisplayOrder = 42
noteGui.Parent = pg
local note = label(noteGui, {
    name = "Note", size = UDim2.fromOffset(820, 56), position = UDim2.new(0.5, -410, 0.26, 0),
    textSize = 34, colour = K.close.hi,
})
note.Visible = false
local noteToken = 0
local function say(text, colour)
    noteToken += 1
    local mine = noteToken
    note.Text = text
    note.TextColor3 = colour or K.close.hi
    note.Visible = true
    task.delay(2.4, function()
        if noteToken == mine then note.Visible = false end
    end)
end

remote.OnClientEvent:Connect(function(action, data)
    if action == "deny" then
        say(tostring(data))
    elseif action == "noProduct" then
        say(tostring(data) .. " - not available right now")
    elseif action == "upgraded" and type(data) == "table" then
        local def = U[data.kind]
        say(("%s upgraded to Level %d!"):format(def and def.name or "Plot", tonumber(data.level) or 0), K.ready.hi)
    end
end)

local signs = {}

local function destroySign(kind)
    local s = signs[kind]
    if not s then return end
    for _, f in ipairs(s.faces) do
        if f.gui then f.gui:Destroy() end
    end
    if s.alert then s.alert:Destroy() end
    signs[kind] = nil
end

local function buildFace(kind, board, face)
    local def = U[kind]
    local W = math.floor(board.Size.X * PPS)
    local H = math.floor(board.Size.Y * PPS)

    local gui = Instance.new("SurfaceGui")
    gui.Name = ("UpgradeSign_%s_%s"):format(kind, face.Name)
    gui.Adornee = board
    gui.Face = face
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = PPS
    gui.LightInfluence = 0
    gui.MaxDistance = 160
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ClipsDescendants = true
    gui.Parent = pg

    label(gui, {
        name = "Title", size = UDim2.fromOffset(W - 20, 58), position = UDim2.fromOffset(10, 8),
        text = def.title, textSize = 50,
    })
    local levels = label(gui, {
        name = "Levels", size = UDim2.fromOffset(W - 20, 46), position = UDim2.fromOffset(10, 66),
        text = "", textSize = 40, colour = LEVEL_GREEN,
    })

    local BTN_Y, BTN_H = 128, math.max(90, H - 128 - 16)
    local ROBUX_W = math.floor((W - 40) * 0.36)
    local CASH_W = W - 40 - ROBUX_W - 12

    local cash, _, _, setCashTone = UIKit.button({
        parent = gui, name = "CashPrice", tone = K.ready, text = "", textSize = 20,
        size = UDim2.fromOffset(CASH_W, BTN_H), position = UDim2.fromOffset(20, BTN_Y), zindex = 8,
        onClick = function() remote:FireServer("buy", kind) end,
    })
    icon(cash, def.icon, BTN_H - 20, 12)
    local cashText = label(cash, {
        name = "Value", size = UDim2.new(1, -(BTN_H + 4), 1, 0), position = UDim2.fromOffset(BTN_H - 4, 0),
        textSize = 50, zindex = 12,
    })

    local robux = UIKit.button({
        parent = gui, name = "Robux", tone = K.prize, text = "", textSize = 20,
        size = UDim2.fromOffset(ROBUX_W, BTN_H), position = UDim2.fromOffset(20 + CASH_W + 12, BTN_Y), zindex = 8,
        onClick = function() remote:FireServer("robux", kind) end,
    })
    icon(robux, ICON_ROBUX, math.floor(BTN_H * 0.5), 12)
    local robuxLabel = label(robux, {
        name = "Value", size = UDim2.new(1, -(math.floor(BTN_H * 0.5) + 18), 1, 0),
        position = UDim2.fromOffset(math.floor(BTN_H * 0.5) + 14, 0), textSize = 36, zindex = 12,
    })

    return {
        gui = gui, levels = levels,
        cash = cash, cashText = cashText, setCashTone = setCashTone,
        robux = robux, robuxLabel = robuxLabel,
    }
end

local SIGN_FACE = {
    MILL = Enum.NormalId.Front,
    PEN = Enum.NormalId.Back,
}

local function buildSign(kind, board)
    local faces = {
        buildFace(kind, board, SIGN_FACE[kind] or Enum.NormalId.Front),
    }

    local alert = Instance.new("BillboardGui")
    alert.Name = "UpgradeAlert_" .. kind
    alert.Adornee = board
    alert.Size = UDim2.fromScale(2.4, 2.4)
    alert.StudsOffsetWorldSpace = Vector3.new(0, board.Size.Y / 2 + 2.2, 0)
    alert.LightInfluence = 0
    alert.MaxDistance = 200
    alert.ResetOnSpawn = false
    alert.Enabled = false
    alert.Parent = pg
    local img = Instance.new("ImageLabel")
    img.Name = "Icon"
    img.BackgroundTransparency = 1
    img.Image = ICON_ALERT
    img.ScaleType = Enum.ScaleType.Fit
    img.Size = UDim2.fromScale(1, 1)
    img.Parent = alert

    signs[kind] = { board = board, faces = faces, alert = alert, img = img, affordable = nil }
    return signs[kind]
end

local function coins()
    local ls = plr:FindFirstChild("wallet")
    local c = ls and ls:FindFirstChild("Coins")
    return c and c.Value or 0
end

local function update(kind, holder, attr)
    local sign = holder and holder:FindFirstChild("Sign")
    local board = sign and sign:FindFirstChild("Board")
    local s = signs[kind]
    if not board then
        destroySign(kind)
        return
    end
    if s and s.board ~= board then
        destroySign(kind)
        s = nil
    end
    s = s or buildSign(kind, board)

    local level = math.clamp(math.floor(tonumber(holder:GetAttribute(attr)) or 1), 1, U.MAX_LEVEL)
    if level >= U.MAX_LEVEL then
        for _, f in ipairs(s.faces) do
            f.levels.Text = ("Level %d - Max"):format(level)
            f.cash.Visible = false
            f.robux.Visible = false
        end
        s.alert.Enabled = false
        return
    end
    local price = U.price(kind, level)
    local canPay = coins() >= price
    local toneChanged = s.affordable ~= canPay
    s.affordable = canPay
    for _, f in ipairs(s.faces) do
        f.cash.Visible = true
        f.robux.Visible = true
        f.levels.Text = ("Level %d > Level %d"):format(level, level + 1)
        f.cashText.Text = money(price)
        f.robuxLabel.Text = robuxText(U.robux(kind, level))
        if toneChanged then f.setCashTone(canPay and K.ready or K.close) end
    end
    s.alert.Enabled = canPay
end

local function myPlot()
    for _, pen in ipairs(pens:GetChildren()) do
        if pen:GetAttribute("OwnerUserId") == plr.UserId then
            return pen, mills:FindFirstChild("Mill_" .. pen.Name)
        end
    end
    return nil, nil
end

task.spawn(function()
    while true do
        local pen, mill = myPlot()
        update("PEN", pen, "PlotLevel")
        update("MILL", mill, "MillLevel")
        task.wait(0.25)
    end
end)

RunService.Heartbeat:Connect(function()
    local t = os.clock()
    for _, s in pairs(signs) do
        if s.alert.Enabled then
            s.img.Position = UDim2.fromScale(0, -math.abs(math.sin(t * 4)) * 0.25)
        end
    end
end)