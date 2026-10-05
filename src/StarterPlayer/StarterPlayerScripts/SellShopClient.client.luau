local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Cfg = require(RS:WaitForChild("EggConfig"))
local Sell = require(RS:WaitForChild("SellConfig"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("Sell")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local SECOND = UIKit.SECOND
local PANEL_INK = Color3.fromRGB(43, 23, 64)
local PANEL_MARK = Color3.fromRGB(255, 240, 224)
local INCOME_GREEN = Color3.fromRGB(96, 255, 84)
local ICON = Sell.ICON

local W, H = 1000, 640
local PAD = 16
local LEFT_W = 196
local BOTTOM_H = 92
local COLS = 4
local CARD_GAP = 12
local TAB_SIDE = 124

local money = Cfg.fmtMoney

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
    i.Rotation = props.rotation or 0
    i.ZIndex = props.zindex or 20
    if props.tint then i.ImageColor3 = props.tint end
    if props.transparency then i.ImageTransparency = props.transparency end
    i.Parent = parent
    return i
end

local gui = Instance.new("ScreenGui")
gui.Name = "SellShopGui"
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
shell.Name = "SellShop"
shell.AnchorPoint = Vector2.new(0.5, 0.5)
shell.Position = UDim2.fromScale(0.5, 0.5)
shell.Size = UDim2.fromOffset(W, H)
shell.BackgroundTransparency = 1
shell.Visible = false
shell.ZIndex = 10
shell.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = shell

local FULL_W = W + 14 + TAB_SIDE
local function fit()
    local cam = workspace.CurrentCamera
    if not cam then return 1 end
    local small = math.min(cam.ViewportSize.X, cam.ViewportSize.Y) < 500
    local room = cam.ViewportSize.Y - (small and -20 or GuiService:GetGuiInset().Y)

    local SHRINK = small and 1 or 0.82
    local s = math.clamp(math.min((room - 28) / H, (cam.ViewportSize.X - 32) / FULL_W) * SHRINK, 0.40, SHRINK)
    scale.Scale = s
    shell.Position = UDim2.new(0.5, -(14 + TAB_SIDE) * s / 2, 0.5, 0)
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
    parent = frame, name = "Header", tone = K.ready,
    size = UDim2.new(1, 0, 0, headH), position = UDim2.new(),
    radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 14,
})
local headIconH = headH - 16
local headIconShadow = art(header, { name = "IconShadow", image = ICON.paw, size = UDim2.fromOffset(headIconH, headIconH),
    position = UDim2.fromOffset(14, 12), zindex = 20, tint = Color3.new(0, 0, 0), transparency = 0.55 })
local headIcon = art(header, { name = "Icon", image = ICON.paw, size = UDim2.fromOffset(headIconH, headIconH),
    position = UDim2.fromOffset(14, 8), zindex = 21 })
local titleLabel = bold(header, {
    name = "Title", size = UDim2.fromScale(1, 1), text = "SELL PETS",
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
local BODY_H = H - TOP - BOTTOM_H - 28

local left = block({
    parent = frame, name = "Left", tone = K.thumb, size = UDim2.fromOffset(LEFT_W, BODY_H),
    position = UDim2.fromOffset(PAD, TOP), radius = 12, outline = 3, stud = 11, studAlpha = 0.7,
    bevel = false, shadow = false, zindex = 14,
})
bold(left, { name = "SortBy", size = UDim2.new(1, 0, 0, 34), position = UDim2.fromOffset(0, 10),
    text = "SORT BY:", textSize = 24, strokeW = 3, zindex = 20 })

local state = { tab = nil, sort = "value", desc = true, selected = {}, items = {} }
local render

local BTN_W, BTN_H = LEFT_W - 24, 54
local sortButtons = {}

local function sortButton(key, text, y)
    local b, _, _, setTone = UIKit.button({
        parent = left, name = "Sort_" .. key, tone = K.lock, text = "", textSize = 20,
        size = UDim2.fromOffset(BTN_W, BTN_H), position = UDim2.fromOffset(12, y), zindex = 18,
        onClick = function()
            if state.sort == key then
                state.desc = not state.desc
            else
                state.sort = key
                state.desc = true
            end
            render()
        end,
    })
    local arrow = art(b, { name = "Arrow", image = ICON.arrow, size = UDim2.fromOffset(34, 34),
        position = UDim2.new(0, 12, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 24 })
    bold(b, { name = "Text", size = UDim2.new(1, -56, 1, 0), position = UDim2.fromOffset(52, 0),
        text = text, textSize = 22, strokeW = 3, zindex = 24 })
    sortButtons[key] = { button = b, setTone = setTone, arrow = arrow }
end
sortButton("size", "SIZE", 54)
sortButton("value", "VALUE", 54 + BTN_H + 12)

local sep = Instance.new("Frame")
sep.Name = "Separator"
sep.BackgroundColor3 = K.slab.hi
sep.BackgroundTransparency = 0.4
sep.BorderSizePixel = 0
sep.Size = UDim2.fromOffset(BTN_W, 4)
sep.Position = UDim2.fromOffset(12, 54 + 2 * (BTN_H + 12) + 2)
sep.ZIndex = 18
sep.Parent = left
UIKit.corner(sep, 2)

local selectY = 54 + 2 * (BTN_H + 12) + 18
local selectBtn, _, _, setSelectTone = UIKit.button({
    parent = left, name = "SelectAll", tone = K.ready, text = "", textSize = 20,
    size = UDim2.fromOffset(BTN_W, BTN_H), position = UDim2.fromOffset(12, selectY), zindex = 18,
    onClick = function()
        local all = #state.items > 0
        for _, it in ipairs(state.items) do
            if not state.selected[it.tool] then all = false break end
        end
        state.selected = {}
        if not all then
            for _, it in ipairs(state.items) do state.selected[it.tool] = true end
        end
        render()
    end,
})
local selectIcon = art(selectBtn, { name = "Mark", image = ICON.check, size = UDim2.fromOffset(34, 34),
    position = UDim2.new(0, 10, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 24 })
local selectText = bold(selectBtn, { name = "Text", size = UDim2.new(1, -54, 1, 0), position = UDim2.fromOffset(50, 0),
    text = "SELECT ALL", textSize = 20, strokeW = 3, zindex = 24 })

local GRID_X = PAD + LEFT_W + 14
local GRID_W = W - GRID_X - PAD
local grid = Instance.new("ScrollingFrame")
grid.Name = "Grid"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(GRID_X, TOP)
grid.Size = UDim2.fromOffset(GRID_W, BODY_H)
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollingDirection = Enum.ScrollingDirection.Y
grid.ScrollBarThickness = 8
grid.ScrollBarImageColor3 = K.slab.hi
grid.ZIndex = 14
grid.Parent = frame

local CARD_W = math.floor((GRID_W - 20 - (COLS - 1) * CARD_GAP) / COLS)
local CARD_H = math.floor(CARD_W * 1.08)
do
    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(CARD_W, CARD_H)
    layout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 5)
    pad.PaddingTop = UDim.new(0, 5)
    pad.PaddingRight = UDim.new(0, 12)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent = grid
end

local empty = bold(frame, { name = "Empty", size = UDim2.fromOffset(GRID_W, 60),
    position = UDim2.fromOffset(GRID_X, TOP + BODY_H / 2 - 30), text = "", textSize = 26, strokeW = 3,
    colour = SECOND, zindex = 20 })

local bottom = block({
    parent = frame, name = "Bottom", tone = K.thumb, size = UDim2.fromOffset(W - 2 * PAD, BOTTOM_H),
    position = UDim2.fromOffset(PAD, H - BOTTOM_H - 14), radius = 12, outline = 3, stud = 11, studAlpha = 0.7,
    bevel = false, shadow = false, zindex = 14,
})
bold(bottom, { name = "TotalCaption", size = UDim2.fromOffset(250, BOTTOM_H), position = UDim2.fromOffset(22, 0),
    text = "TOTAL VALUE:", align = Enum.TextXAlignment.Left, textSize = 32, strokeW = 4, zindex = 20 })

do
    local glow = Instance.new("CanvasGroup")
    glow.Name = "CashGlow"
    glow.BackgroundTransparency = 1
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0, 355, 0.5, 0)
    glow.Size = UDim2.fromOffset(260, BOTTOM_H - 18)
    glow.ZIndex = 19
    glow.Parent = bottom
    local fill = Instance.new("Frame")
    fill.BackgroundColor3 = Color3.fromRGB(95, 255, 70)
    fill.BorderSizePixel = 0
    fill.Size = UDim2.fromScale(1, 1)
    fill.ZIndex = 19
    fill.Parent = glow
    local across = Instance.new("UIGradient")
    across.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.28, 0.25),
        NumberSequenceKeypoint.new(0.62, 0.3), NumberSequenceKeypoint.new(1, 1),
    })
    across.Parent = fill
    local updown = Instance.new("UIGradient")
    updown.Rotation = 90
    updown.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.3, 0.15),
        NumberSequenceKeypoint.new(0.7, 0.15), NumberSequenceKeypoint.new(1, 1),
    })
    updown.Parent = glow
end
art(bottom, { name = "CashIcon", image = ICON.cash, size = UDim2.fromOffset(76, 76),
    position = UDim2.new(0, 270, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 20 })
local totalLabel = bold(bottom, { name = "Total", size = UDim2.fromOffset(300, BOTTOM_H), position = UDim2.fromOffset(356, 0),
    text = "$0", align = Enum.TextXAlignment.Left, textSize = 46, strokeW = 4, zindex = 20 })

local SELL_W = 230
local sellBtn, _, setSellText, setSellTone = UIKit.button({
    parent = bottom, name = "Sell", tone = K.lock, text = "SELL", textSize = 32,
    size = UDim2.fromOffset(SELL_W, BOTTOM_H - 24), position = UDim2.new(1, -(SELL_W + 14), 0, 12), zindex = 18,
    onClick = function()
        local tools, mixed, kind = {}, false, nil
        for _, it in ipairs(state.items) do
            if state.selected[it.tool] then
                table.insert(tools, it.tool)
                if kind and kind ~= it.kind then mixed = true end
                kind = kind or it.kind
            end
        end
        if #tools == 0 then return end
        remote:FireServer("sell", mixed and "All" or kind, tools)
    end,
})

local tabs = {}
local function tabButton(key, image, y)
    local b, _, _, setTone = UIKit.button({
        parent = shell, name = "Tab_" .. key, tone = K.lock, text = "", textSize = 20,
        size = UDim2.fromOffset(TAB_SIDE, TAB_SIDE), position = UDim2.new(1, 14, 0, y), zindex = 12,
        onClick = function()
            if state.tab == key then state.tab = nil else state.tab = key end
            state.selected = {}
            render()
        end,
    })
    local cap = bold(b, { name = "Caption", size = UDim2.new(1, 0, 0, 36), position = UDim2.new(0.5, 0, 0, 6),
        text = key:upper(), textSize = 26, strokeW = 3, zindex = 16 })
    cap.AnchorPoint = Vector2.new(0.5, 0)
    local pic = art(b, { name = "Pic", image = image, size = UDim2.fromOffset(TAB_SIDE - 52, TAB_SIDE - 52),
        position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), zindex = 16 })
    local capScale = Instance.new("UIScale") capScale.Parent = cap
    local picScale = Instance.new("UIScale") picScale.Parent = pic
    b:GetPropertyChangedSignal("Size"):Connect(function()
        local k = b.Size.X.Offset / TAB_SIDE
        capScale.Scale, picScale.Scale = k, k
    end)
    tabs[key] = { button = b, setTone = setTone }
end
tabButton("Eggs", ICON.egg, 60)
tabButton("Pets", ICON.paw, 60 + TAB_SIDE + 14)

local function gather(tab)
    local list = {}
    for _, holder in ipairs({ plr:FindFirstChildOfClass("Backpack"), plr.Character }) do
        if holder then
            for _, t in ipairs(holder:GetChildren()) do
                if t:IsA("Tool") then
                    local zone, tier, size, kind
                    if (tab == nil or tab == "Pets") and t:GetAttribute("AnimalZone") then
                        zone, tier, size = t:GetAttribute("AnimalZone"), t:GetAttribute("AnimalTier"), t:GetAttribute("AnimalSize")
                        kind = "Pets"
                    elseif (tab == nil or tab == "Eggs") and t:GetAttribute("EggZone") then
                        zone, tier, size = t:GetAttribute("EggZone"), t:GetAttribute("EggTier"), t:GetAttribute("EggSize")
                        kind = "Eggs"
                    end
                    if zone then
                        table.insert(list, {
                            tool = t, kind = kind, zone = zone, tier = tier or 1, size = size or 1,
                            income = Cfg.petIncome(zone, size or 1, tier or 1, t:GetAttribute("Luck") or t:GetAttribute("EggLuck")),
                            price = Sell.price(kind, zone, tier, size, t:GetAttribute("Luck") or t:GetAttribute("EggLuck")),
                        })
                    end
                end
            end
        end
    end
    table.sort(list, function(a, b)
        local ka, kb
        if state.sort == "size" then
            ka, kb = a.size * 1e18 + a.price, b.size * 1e18 + b.price
        else
            ka, kb = a.price, b.price
        end
        if ka == kb then return a.tool.Name < b.tool.Name end
        if state.desc then return ka > kb end
        return ka < kb
    end)
    return list
end

local PetPaint = require(game:GetService("ReplicatedStorage"):WaitForChild("AnimalPaint"))
local PetQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("AssetQueue"))

local function preview(view, tool)
    local holder = Instance.new("Model")

    local handle = tool:FindFirstChild("Handle")
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            local c = p:Clone()
            c:ClearAllChildren()
            c.Anchored = true
            local rest = p:GetAttribute("RestOffset")
            if handle and typeof(rest) == "CFrame" then
                c.CFrame = handle.CFrame * rest
            end
            c.Parent = holder
        end
    end
    if #holder:GetChildren() == 0 then holder:Destroy() return end
    PetQueue.want(holder)
    holder.Parent = view

    local cf = holder:GetBoundingBox()
    local cam = Instance.new("Camera")
    cam.FieldOfView = 30
    local eye = Vector3.new(0.6, 0.35, 1).Unit
    local up = Vector3.yAxis

    local viewEye, viewUp = PetPaint.viewDir(holder:GetChildren(), tool)
    if viewEye then eye, up = viewEye, viewUp end
    local probe = CFrame.lookAt(cf.Position + eye * 10, cf.Position, up)
    local reach = 0
    for _, p in ipairs(holder:GetChildren()) do
        for dx = -1, 1, 2 do
            for dy = -1, 1, 2 do
                for dz = -1, 1, 2 do
                    local corner = (p.CFrame * CFrame.new(p.Size * Vector3.new(dx, dy, dz) / 2)).Position
                    local inCam = probe:PointToObjectSpace(corner)
                    reach = math.max(reach, math.abs(inCam.X), math.abs(inCam.Y))
                end
            end
        end
    end
    if reach <= 0 then reach = 1 end
    local dist = reach / math.tan(math.rad(cam.FieldOfView / 2)) * 1.1
    cam.CFrame = CFrame.lookAt(cf.Position + eye * dist, cf.Position, up)
    cam.Parent = view
    view.CurrentCamera = cam
    view.Ambient = Color3.fromRGB(190, 190, 196)
    view.LightDirection = Vector3.new(-0.4, -1, -0.4)
end

local SIZE_KG = { 0.15, 0.6, 1.5, 4, 12, 40 }
local function weightOf(it)
    local base = SIZE_KG[it.size] or 1
    local key = tostring(it.tool:GetAttribute("SaveKey") or it.tool.Name)
    local h = 0
    for i = 1, #key do h = (h * 31 + key:byte(i)) % 1000003 end
    local kg = base * (0.85 + (h % 31) / 100)
    return (kg < 10) and ("%.2f kg"):format(kg) or ("%.1f kg"):format(kg)
end

local refreshSummary

local function buildCard(it, order)
    local picked = state.selected[it.tool] == true
    local tierDef = Cfg.TIERS[it.tier] or Cfg.TIERS[1]
    local rarity = tierDef.color or Color3.new(1, 1, 1)

    local card = Instance.new("TextButton")
    card.Name = "Card"
    card.AutoButtonColor = false
    card.Text = ""
    card.BackgroundColor3 = picked and Color3.fromRGB(38, 92, 40) or Color3.fromRGB(28, 32, 52):Lerp(rarity, 0.16)
    card.BorderSizePixel = 0
    card.LayoutOrder = order
    card.ZIndex = 16
    card.Parent = grid
    UIKit.corner(card, 10)
    local st = Instance.new("UIStroke")
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Thickness = picked and 4 or 3
    st.Color = picked and K.ready.hi or rarity
    st.Parent = card

    local sizeName = Cfg.SIZES[it.size] and Cfg.SIZES[it.size].name or ""
    local small = Instance.new("TextLabel")
    small.Name = "Size"
    small.BackgroundTransparency = 1
    small.Position = UDim2.fromOffset(8, 4)
    small.Size = UDim2.new(0.7, 0, 0, 22)
    small.Font = Enum.Font.FredokaOne
    small.TextSize = 17
    small.TextXAlignment = Enum.TextXAlignment.Left
    small.TextColor3 = rarity
    small.Text = weightOf(it)
    small.ZIndex = 20
    small.Parent = card
    local ss = Instance.new("UIStroke")
    ss.Thickness = 2
    ss.Color = K.outline
    ss.Parent = small

    local rarityLabel = Instance.new("TextLabel")
    rarityLabel.Name = "Rarity"
    rarityLabel.BackgroundTransparency = 1
    rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
    rarityLabel.Position = UDim2.new(0.5, 0, 0, 22)
    rarityLabel.Size = UDim2.new(1, -12, 0, 20)
    rarityLabel.Font = Enum.Font.FredokaOne
    rarityLabel.TextSize = 17
    rarityLabel.TextColor3 = rarity
    rarityLabel.Text = (tierDef.name or ""):upper()
    rarityLabel.ZIndex = 21
    rarityLabel.Visible = false
    rarityLabel.Parent = card
    local rs = Instance.new("UIStroke")
    rs.Thickness = 2
    rs.Color = K.outline
    rs.Parent = rarityLabel

    local view = Instance.new("ViewportFrame")
    view.Name = "Preview"
    view.BackgroundTransparency = 1
    local top = 22
    view.Position = UDim2.new(0, 10, 0, top)
    view.Size = UDim2.new(1, -20, 1, -(top + 78))
    view.ZIndex = 18
    view.Parent = card
    pcall(preview, view, it.tool)

    local line = bold(card, {
        name = "Line", size = UDim2.new(1, -8, 0, 30), position = UDim2.new(0, 4, 1, -80),
        text = (it.kind == "Pets") and (money(it.income) .. "/s") or "",
        textSize = 26, strokeW = 3, colour = (it.kind == "Pets") and INCOME_GREEN or tierDef.color, zindex = 22,
    })

    local plate = Instance.new("Frame")
    plate.Name = "Price"
    plate.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
    plate.BackgroundTransparency = 0.25
    plate.BorderSizePixel = 0
    plate.Position = UDim2.new(0, 8, 1, -46)
    plate.Size = UDim2.new(1, -16, 0, 38)
    plate.ZIndex = 20
    plate.Parent = card
    UIKit.corner(plate, 8)
    art(plate, { name = "CashIcon", image = ICON.cash, size = UDim2.fromOffset(34, 34),
        position = UDim2.new(0, 6, 0.5, 0), anchor = Vector2.new(0, 0.5), zindex = 22 })
    bold(plate, { name = "Value", size = UDim2.new(1, -48, 1, 0), position = UDim2.fromOffset(44, 0),
        text = money(it.price), textSize = 24, strokeW = 3, zindex = 22 })

    if picked then
        art(card, { name = "Check", image = ICON.check, size = UDim2.fromOffset(38, 38),
            position = UDim2.new(1, -4, 0, 4), anchor = Vector2.new(1, 0), zindex = 24 })
    end

    card.MouseButton1Click:Connect(function()
        if state.selected[it.tool] then
            state.selected[it.tool] = nil
        else
            state.selected[it.tool] = true
        end
        local now = state.selected[it.tool] == true
        card.BackgroundColor3 = now and Color3.fromRGB(38, 92, 40) or Color3.fromRGB(28, 32, 52):Lerp(rarity, 0.16)
        st.Thickness = now and 4 or 3
        st.Color = now and K.ready.hi or rarity
        local check = card:FindFirstChild("Check")
        if now and not check then
            art(card, { name = "Check", image = ICON.check, size = UDim2.fromOffset(38, 38),
                position = UDim2.new(1, -4, 0, 4), anchor = Vector2.new(1, 0), zindex = 24 })
        elseif not now and check then
            check:Destroy()
        end
        refreshSummary()
    end)
end

function refreshSummary()
    local total, picked = 0, 0
    for _, it in ipairs(state.items) do
        if state.selected[it.tool] then
            total += it.price
            picked += 1
        end
    end
    local allPicked = #state.items > 0 and picked == #state.items
    setSelectTone(allPicked and K.close or K.ready)
    selectIcon.Image = allPicked and ICON.cross or ICON.check
    selectText.Text = allPicked and "CLEAR" or "SELECT ALL"
    totalLabel.Text = money(total)
    if picked == 0 then
        setSellTone(K.lock)
        setSellText("SELL")
    else
        setSellTone(K.ready)
        setSellText(allPicked and "SELL ALL" or "SELL")
    end
end

function render()
    local keep = grid.CanvasPosition
    state.items = gather(state.tab)

    local alive = {}
    for _, it in ipairs(state.items) do alive[it.tool] = true end
    for tool in pairs(state.selected) do
        if not alive[tool] then state.selected[tool] = nil end
    end

    for _, c in ipairs(grid:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local total, picked = 0, 0
    for i, it in ipairs(state.items) do
        buildCard(it, i)
        if state.selected[it.tool] then
            total += it.price
            picked += 1
        end
    end
    task.defer(function() grid.CanvasPosition = keep end)

    local pets = state.tab == "Pets"
    local eggs = state.tab == "Eggs"
    titleLabel.Text = eggs and "SELL EGGS" or "SELL PETS"
    headIcon.Image = pets and ICON.paw or eggs and ICON.egg or ICON.cash
    headIconShadow.Image = headIcon.Image
    empty.Text = (#state.items == 0) and (pets and "No pets to sell" or eggs and "No eggs to sell"
        or "Nothing to sell yet") or ""

    for key, t in pairs(tabs) do t.setTone(key == state.tab and K.ready or K.lock) end
    for key, sb in pairs(sortButtons) do
        local active = state.sort == key
        sb.setTone(active and K.ready or K.lock)

        sb.arrow.Rotation = (active and not state.desc) and 180 or 0
    end

    local allPicked = #state.items > 0 and picked == #state.items
    setSelectTone(allPicked and K.close or K.ready)
    selectIcon.Image = allPicked and ICON.cross or ICON.check
    selectText.Text = allPicked and "CLEAR" or "SELECT ALL"

    totalLabel.Text = money(total)
    if picked == 0 then
        setSellTone(K.lock)
        setSellText("SELL")
    else
        setSellTone(K.ready)
        setSellText(allPicked and "SELL ALL" or "SELL")
    end
end

local isOpen = false
local dirty = false
local function markDirty()
    if not isOpen or dirty then return end
    dirty = true
    task.defer(function()
        dirty = false
        if isOpen then render() end
    end)
end
local function watch(parent)
    if not parent then return end
    parent.ChildAdded:Connect(markDirty)
    parent.ChildRemoved:Connect(markDirty)
end
watch(plr:FindFirstChildOfClass("Backpack"))
plr.ChildAdded:Connect(function(c) if c:IsA("Backpack") then watch(c) end end)
if plr.Character then watch(plr.Character) end
plr.CharacterAdded:Connect(watch)

local toast = UIKit.boldLabel({
    parent = gui, name = "Toast", size = UDim2.fromOffset(760, 46),
    position = UDim2.fromScale(0.5, 0.1), anchor = Vector2.new(0.5, 0.5),
    text = "", colour = K.ready.hi, strokeW = 4, textSize = 32, zindex = 60,
})
toast.Visible = false
local toastToken = 0
local function say(text, colour)
    toastToken += 1
    local mine = toastToken
    toast.Text = text
    toast.TextColor3 = colour or K.ready.hi
    toast.Visible = true
    task.delay(2.6, function()
        if toastToken == mine then toast.Visible = false end
    end)
end

local soldAcc = { count = 0, total = 0, kinds = {}, pending = false }
remote.OnClientEvent:Connect(function(action, data)
    if action == "sold" and type(data) == "table" then
        soldAcc.count += tonumber(data.count) or 0
        soldAcc.total += tonumber(data.total) or 0
        if data.kind == "All" then
            soldAcc.kinds.egg, soldAcc.kinds.pet = true, true
        else
            soldAcc.kinds[data.kind == "Eggs" and "egg" or "pet"] = true
        end
        if not soldAcc.pending then
            soldAcc.pending = true
            task.delay(0.25, function()
                local n = soldAcc.count
                local what = (soldAcc.kinds.egg and soldAcc.kinds.pet) and "item" or (soldAcc.kinds.egg and "egg" or "pet")
                say(("Sold %d %s%s for %s!"):format(n, what, n == 1 and "" or "s", money(soldAcc.total)))
                soldAcc.count, soldAcc.total, soldAcc.kinds, soldAcc.pending = 0, 0, {}, false
            end)
        end
        state.selected = {}
        if isOpen then render() end
    elseif action == "deny" then
        say(tostring(data), K.close.hi)
    end
end)

local blurHeld = false
local openedByRing = false

local function open()
    if isOpen then return end
    isOpen = true
    state.selected = {}
    state.tab = nil
    render()
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
        if id == "SellShop" then
            open()
        elseif isOpen then
            shut()
        end
    end)
end

task.spawn(function()
    local map = workspace:WaitForChild("GameWorld")
    local shops = map:WaitForChild("Shops", 60)
    local ring = shops and shops:WaitForChild("ShopLeftRing", 60)
    if not ring then
        warn("[SELL] no ShopLeftRing - the sell window only opens from code")
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
                    if bus then bus:Fire("SellShop") else open() end
                    openedByRing = true
                end
            elseif inside and (flat > radius + 3 or not level) then
                inside = false
                if isOpen and openedByRing then shut() end
            end
        end
    end
end)

_G.OpenSellShop = open