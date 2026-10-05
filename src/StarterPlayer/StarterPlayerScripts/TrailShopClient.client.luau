local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Cfg = require(RS:WaitForChild("EggConfig"))
local Trails = require(RS:WaitForChild("TrailConfig"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("Trails")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local PANEL_INK = Color3.fromRGB(43, 23, 64)
local PANEL_MARK = Color3.fromRGB(255, 240, 224)

local ICON = {
    shoe  = "rbxassetid://126213576980021",
    robux = "rbxassetid://102382554203100",
    glow  = "rbxassetid://110083852572719",
}

local W, H = 1010, 560
local CARD_W = 300
local CARD_GAP = 16

local function block(props)
    local face = UIKit.block(props)
    if props.clickable and props.react ~= false then UIKit.reactToCursor(face) end
    return face
end

local function bold(parent, props)
    props.parent = parent
    return UIKit.boldLabel(props)
end

local function art(parent, props)
    local i = Instance.new("ImageLabel")
    i.Name = props.name or "Icon"
    i.BackgroundTransparency = 1
    i.Image = props.image
    i.Size = props.size
    i.Position = props.position or UDim2.new()
    i.AnchorPoint = props.anchor or Vector2.new()
    i.ScaleType = Enum.ScaleType.Fit
    i.ZIndex = props.zindex or 20
    if props.tint then i.ImageColor3 = props.tint end
    if props.transparency then i.ImageTransparency = props.transparency end
    i.Parent = parent
    return i
end

local function toneOf(c)
    return {
        hi = c:Lerp(WHITE, 0.22),
        base = c,
        sh = c:Lerp(Color3.new(0, 0, 0), 0.34),
    }
end

local money = Cfg.fmtMoney

local gui = Instance.new("ScreenGui")
gui.Name = "TrailShopGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 60
gui.Parent = plr:WaitForChild("PlayerGui")

local dim = Instance.new("TextButton")
dim.Name = "Dim"
dim.Text = ""
dim.AutoButtonColor = false
dim.BackgroundColor3 = Color3.fromRGB(6, 4, 12)
dim.BackgroundTransparency = 0.42
dim.BorderSizePixel = 0
dim.Size = UDim2.fromScale(1, 1)
dim.ZIndex = 1
dim.Visible = false
dim.Parent = gui

local shell = Instance.new("Frame")
shell.Name = "TrailShop"
shell.AnchorPoint = Vector2.new(0.5, 0.5)
shell.Position = UDim2.fromScale(0.5, 0.5)
shell.Size = UDim2.fromOffset(W, H)
shell.BackgroundTransparency = 1
shell.Visible = false
shell.ZIndex = 10
shell.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = shell

local function fit()
    local cam = workspace.CurrentCamera
    if not cam then return 1 end
    local small = math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
    local room = cam.ViewportSize.Y - (small and 8 or (GuiService:GetGuiInset().Y + 28))
    local s = math.clamp(math.min(room / H, (cam.ViewportSize.X - 32) / W), small and 0.3 or 0.40, 1)
    scale.Scale = s
    shell.Position = UDim2.fromScale(0.5, 0.5)
    return s
end
fit()
do
    local function track(cam)
        if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit) end
    end
    track(workspace.CurrentCamera)
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        track(workspace.CurrentCamera)
        fit()
    end)
end

local frame = block({
    parent = shell, name = "Frame", tone = K.panel, size = UDim2.fromOffset(W, H),
    radius = 15, outline = 3, shadowY = 8, bevel = false, stud = 15, studAlpha = 0.55, zindex = 10,
})

frame.BackgroundTransparency = 0.15
do
    local under = frame:FindFirstChild("Underside")
    if under then under.BackgroundTransparency = 0.15 end
end

local headH = UIKit.headHeight(W)
local header = block({
    parent = frame, name = "Header", tone = K.bar,
    size = UDim2.new(1, 0, 0, headH), position = UDim2.new(),
    radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 14,
})
do
    local iconH = headH - 16
    local iconY = math.floor((headH - iconH) / 2)
    art(header, { name = "IconShadow", image = ICON.shoe, size = UDim2.fromOffset(iconH, iconH),
        position = UDim2.fromOffset(14, iconY + 4), zindex = 20, tint = Color3.new(0, 0, 0), transparency = 0.55 })
    art(header, { name = "Icon", image = ICON.shoe, size = UDim2.fromOffset(iconH, iconH),
        position = UDim2.fromOffset(14, iconY), zindex = 21 })
end
bold(header, {
    name = "Title", size = UDim2.fromScale(1, 1), text = "TRAIL SHOP",
    strokeW = 4, strokeColour = PANEL_INK, zindex = 22, textSize = math.floor(headH * 0.62),
})
local shutSide = headH - 24
local closeBtn = block({
    parent = header, name = "Close", tone = K.close, clickable = true, react = false,
    size = UDim2.fromOffset(shutSide, shutSide),
    position = UDim2.new(1, -(shutSide + 14), 0.5, 0), anchor = Vector2.new(0, 0.5),
    radius = math.floor(headH * 0.16), outline = 2, stud = 9, studAlpha = 0.70, shadowY = 4, zindex = 22,
})
UIKit.tintOnHover(closeBtn, K.close)
UIKit.cross(closeBtn, shutSide, PANEL_MARK)

local TOP = headH + 14
local BODY_H = H - TOP - 14
local CARD_H = BODY_H - 28

local body = Instance.new("ScrollingFrame")
body.Name = "Cards"
body.BackgroundTransparency = 1
body.BorderSizePixel = 0
body.Position = UDim2.fromOffset(16, TOP)
body.Size = UDim2.fromOffset(W - 32, BODY_H)
body.CanvasSize = UDim2.new()
body.AutomaticCanvasSize = Enum.AutomaticSize.X
body.ScrollingDirection = Enum.ScrollingDirection.X
body.ScrollBarThickness = 8
body.ScrollBarImageColor3 = K.slab.hi
body.ZIndex = 14
body.Parent = frame
do
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Horizontal
    list.VerticalAlignment = Enum.VerticalAlignment.Top
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, CARD_GAP)
    list.Parent = body
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 4)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingTop = UDim.new(0, 4)
    pad.Parent = body
end

local toast = UIKit.boldLabel({
    parent = gui, name = "Toast", size = UDim2.fromOffset(760, 46),
    position = UDim2.fromScale(0.5, 0.14), anchor = Vector2.new(0.5, 0.5),
    text = "", colour = K.bar.hi, strokeW = 4, textSize = 30, zindex = 60,
})
toast.Visible = false
local toastToken = 0
local function say(text, colour)
    toastToken += 1
    local mine = toastToken
    toast.Text = text
    toast.TextColor3 = colour or K.bar.hi
    toast.Visible = true
    task.delay(2.6, function()
        if toastToken == mine then toast.Visible = false end
    end)
end

local state = { owned = {}, equipped = "" }

local function robuxButton(parent, def, props)
    local b = UIKit.button({
        parent = parent, name = "Robux", tone = K.prize, text = "", textSize = 24,
        size = props.size, position = props.position, zindex = 20,
        onClick = function() remote:FireServer("robux", def.id) end,
    })
    local row = Instance.new("Frame")
    row.Name = "Row"
    row.BackgroundTransparency = 1
    row.Size = UDim2.fromScale(1, 1)
    row.ZIndex = 24
    row.Parent = b
    local layout = Instance.new("UIListLayout")
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    layout.Parent = row
    local mark = Instance.new("Frame")
    mark.Name = "Mark"
    mark.BackgroundTransparency = 1
    mark.Size = UDim2.fromOffset(28, 28)
    mark.LayoutOrder = 1
    mark.ZIndex = 24
    mark.Parent = row
    art(mark, { name = "Glyph", image = ICON.robux, size = UDim2.fromScale(1, 1), zindex = 25 })
    local value = bold(row, {
        name = "Value", size = UDim2.fromOffset(0, 30),
        text = tostring(def.robux), zindex = 25, textSize = 25, strokeW = 3,
    })
    value.AutomaticSize = Enum.AutomaticSize.X
    value.LayoutOrder = 2
    return b
end

local function card(def, order)
    local owned = state.owned[def.id] == true
    local equipped = state.equipped == def.id
    local tone = toneOf(def.card)

    local holder = Instance.new("Frame")
    holder.Name = def.id
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(CARD_W, CARD_H + 8)
    holder.LayoutOrder = order
    holder.ZIndex = 14
    holder.Parent = body

    local c = block({
        parent = holder, name = "Card", tone = tone, size = UDim2.fromOffset(CARD_W, CARD_H),
        radius = 14, outline = equipped and 5 or 4, edge = equipped and WHITE or nil,
        stud = 12, studAlpha = 0.72, bevel = false, zindex = 14,
    })

    art(c, {
        name = "Glow", image = ICON.glow, size = UDim2.fromOffset(CARD_W - 30, CARD_W - 30),
        position = UDim2.new(0.5, 0, 0, 176), anchor = Vector2.new(0.5, 0.5),
        tint = WHITE, transparency = 0.5, zindex = 16,
    })

    bold(c, {
        name = "Name", size = UDim2.new(1, -16, 0, 38), position = UDim2.fromOffset(8, 10),
        text = def.name, textSize = 31, strokeW = 4, zindex = 22,
    })

    local rarityW = TextService:GetTextSize(def.rarity, 21, Enum.Font.FredokaOne, Vector2.new(400, 40)).X + 26
    local pill = Instance.new("Frame")
    pill.Name = "RarityPill"
    pill.AnchorPoint = Vector2.new(0.5, 0)
    pill.Position = UDim2.new(0.5, 0, 0, 46)
    pill.Size = UDim2.fromOffset(rarityW, 26)
    pill.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    pill.BackgroundTransparency = 0.35
    pill.BorderSizePixel = 0
    pill.ZIndex = 20
    pill.Parent = c
    UIKit.corner(pill, 13)
    bold(pill, {
        name = "Rarity", size = UDim2.fromScale(1, 1),
        text = def.rarity, textSize = 21, strokeW = 3, zindex = 22,
        colour = Trails.RARITY and Trails.RARITY[def.rarity] or WHITE,
    })

    art(c, {
        name = "Picture", image = def.image, size = UDim2.fromOffset(CARD_W - 24, 216),
        position = UDim2.new(0.5, 0, 0, 72), anchor = Vector2.new(0.5, 0), zindex = 18,
    })

    local BTN_H = 52
    local btnY = CARD_H - 16 - BTN_H
    local plateY = btnY - 10 - 46

    local plate = Instance.new("Frame")
    plate.Name = "Mult"
    plate.BackgroundColor3 = Color3.fromRGB(18, 16, 28)
    plate.BackgroundTransparency = 0.45
    plate.BorderSizePixel = 0
    plate.Size = UDim2.fromOffset(CARD_W - 40, 46)
    plate.Position = UDim2.fromOffset(20, plateY)
    plate.ZIndex = 20
    plate.Parent = c
    UIKit.corner(plate, 8)
    UIKit.stroke(plate, K.outline, 2, 0.35)
    local multText = bold(plate, {
        name = "Text", size = UDim2.fromScale(1, 1),
        text = ('<font color="#47FF48">%s</font> Speed'):format(Trails.fmtMult(def.mult)),
        textSize = 31, strokeW = 3, zindex = 22,
    })
    multText.RichText = true

    if owned then
        UIKit.button({
            parent = c, name = "Equip", tone = K.ready,
            text = equipped and "Unequip" or "Equip", textSize = 30,
            size = UDim2.fromOffset(CARD_W - 40, BTN_H), position = UDim2.fromOffset(20, btnY), zindex = 20,
            onClick = function()
                remote:FireServer(equipped and "unequip" or "equip", def.id)
            end,
        })
    else
        local inner = CARD_W - 40
        local cashW = math.floor(inner * 0.56)
        UIKit.button({

            parent = c, name = "Price", tone = K.ready,
            text = money(def.price), textSize = 27,
            size = UDim2.fromOffset(cashW, BTN_H), position = UDim2.fromOffset(20, btnY), zindex = 20,
            onClick = function() remote:FireServer("buy", def.id) end,
        })
        robuxButton(c, def, {
            size = UDim2.fromOffset(inner - cashW - 8, BTN_H),
            position = UDim2.fromOffset(20 + cashW + 8, btnY),
        })
    end
    return c
end

local function render()
    local keep = body.CanvasPosition
    for _, ch in ipairs(body:GetChildren()) do
        if ch:IsA("GuiObject") then ch:Destroy() end
    end
    for i, def in ipairs(Trails.LIST) do
        card(def, i)
    end
    task.defer(function() body.CanvasPosition = keep end)
end
render()

remote.OnClientEvent:Connect(function(action, data)
    if action == "state" and type(data) == "table" then
        state.owned = type(data.owned) == "table" and data.owned or {}
        state.equipped = tostring(data.equipped or "")
        render()
    elseif action == "deny" then
        say(tostring(data), K.close.hi)
    elseif action == "noProduct" then
        say(tostring(data) .. " - not available right now", K.close.hi)
    elseif action == "bought" then
        say(tostring(data) .. " unlocked!", K.ready.hi)
    end
end)

task.spawn(function()
    local list = {}
    for _, def in ipairs(Trails.LIST) do
        local img = Instance.new("ImageLabel")
        img.Image = def.image
        table.insert(list, img)
    end
    pcall(function() ContentProvider:PreloadAsync(list) end)
end)

local isOpen = false
local blurHeld = false
local openedByRing = false

local function open()
    if isOpen then return end
    isOpen = true
    remote:FireServer("state")
    dim.Visible = true
    shell.Visible = true
    if not blurHeld then
        blurHeld = true
        UIKit.blurHold(true)
    end
    UIKit.popOpen(scale, fit())
end

local function shut()
    isOpen = false
    openedByRing = false
    dim.Visible = false
    shell.Visible = false
    if blurHeld then
        blurHeld = false
        UIKit.blurHold(false)
    end
end

closeBtn.MouseButton1Click:Connect(shut)
dim.Activated:Connect(function(input)
    local pos = input and input.Position
    if pos then
        local playerGui = game:GetService("Players").LocalPlayer:FindFirstChildOfClass("PlayerGui")
        for _, hit in ipairs(playerGui and playerGui:GetGuiObjectsAtPosition(pos.X, pos.Y) or {}) do
            if hit ~= dim and hit.Visible and hit:IsDescendantOf(dim.Parent) then return end
        end
    end
    shut()
end)

local bus = RS.Remotes:FindFirstChild("OpenPanel")
if bus then
    bus.Event:Connect(function(id)
        if id == "TrailShop" then
            open()
        elseif isOpen then
            shut()
        end
    end)
end

task.spawn(function()
    local map = workspace:WaitForChild("GameWorld")
    local shops = map:WaitForChild("Shops", 60)
    local ring = shops and shops:WaitForChild("ShopRightRing", 60)
    if not ring then
        warn("[TRAILS] no ShopRightRing - the Trail Shop only opens from code")
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
                if not isOpen then
                    if bus then bus:Fire("TrailShop") else open() end
                    openedByRing = true
                end
            elseif inside and (flat > radius + 3 or not level) then
                inside = false
                if isOpen and openedByRing then shut() end
            end
        end
    end
end)

_G.OpenTrailShop = open