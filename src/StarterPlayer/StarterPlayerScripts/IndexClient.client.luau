local BatConfig=require(game.ReplicatedStorage:WaitForChild("BatConfig"))
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local Cfg = require(RS:WaitForChild("EggConfig"))
local Paint = require(RS:WaitForChild("AnimalPaint"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("PetIndex")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local SECOND = UIKit.SECOND
local PANEL_INK = Color3.fromRGB(43, 23, 64)
local PANEL_MARK = Color3.fromRGB(255, 240, 224)

local ICON = {
    book = "rbxassetid://137317555173832",
    cash = "rbxassetid://77975477107065",
    shoe = "rbxassetid://126213576980021",
    glow = "rbxassetid://110083852572719",
}

local ZONES = Cfg.ZONES
local PER_ZONE = 8

local W, H = 980, 556
local PAD = 16

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
        hi = c:Lerp(WHITE, 0.20),
        base = c,
        sh = c:Lerp(Color3.new(0, 0, 0), 0.34),
    }
end

local function dimTone(t)
    local dark = Color3.fromRGB(28, 30, 48)
    return { hi = t.hi:Lerp(dark, 0.62), base = t.base:Lerp(dark, 0.62), sh = t.sh:Lerp(dark, 0.62) }
end

local SLOT_TONE = { K.lock, K.lock, K.ready, K.ready, K.prize, K.inProgress, K.claimed, K.bar }

local function money(v) return "$" .. Cfg.fmtSpeed(v) end

local gui = Instance.new("ScreenGui")
gui.Name = "PetIndexGui"
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
shell.Name = "Index"
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
    art(header, { name = "IconShadow", image = ICON.book, size = UDim2.fromOffset(iconH, iconH),
        position = UDim2.fromOffset(14, iconY + 4), zindex = 20, tint = Color3.new(0, 0, 0), transparency = 0.55 })
    art(header, { name = "Icon", image = ICON.book, size = UDim2.fromOffset(iconH, iconH),
        position = UDim2.fromOffset(14, iconY), zindex = 21 })
end
bold(header, {
    name = "Title", size = UDim2.fromScale(1, 1), text = "PET INDEX",
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
local LEFT_W = 190
local MID_X = PAD + LEFT_W + 14
local MID_W = 470
local RIGHT_X = MID_X + MID_W + 14
local RIGHT_W = W - PAD - RIGHT_X
local CARD_W, CARD_H, CARD_GAP = 110, 128, 10

local zoneList = Instance.new("ScrollingFrame")
zoneList.Name = "Zones"
zoneList.BackgroundTransparency = 1
zoneList.BorderSizePixel = 0
zoneList.Position = UDim2.fromOffset(PAD, TOP)
zoneList.Size = UDim2.fromOffset(LEFT_W, 436)
zoneList.CanvasSize = UDim2.new()
zoneList.AutomaticCanvasSize = Enum.AutomaticSize.Y
zoneList.ScrollBarThickness = 6
zoneList.ScrollBarImageColor3 = K.slab.hi
zoneList.ZIndex = 14
zoneList.Parent = frame
do
    local l = Instance.new("UIListLayout")
    l.Padding = UDim.new(0, 8)
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Parent = zoneList
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, 4)
    p.PaddingBottom = UDim.new(0, 10)
    p.PaddingLeft = UDim.new(0, 2)
    p.Parent = zoneList
end

local mid = Instance.new("Frame")
mid.Name = "Middle"
mid.BackgroundTransparency = 1
mid.Position = UDim2.fromOffset(MID_X, TOP)
mid.Size = UDim2.fromOffset(MID_W, 436)
mid.ZIndex = 14
mid.Parent = frame

local right = Instance.new("Frame")
right.Name = "Right"
right.BackgroundTransparency = 1
right.Position = UDim2.fromOffset(RIGHT_X, TOP)
right.Size = UDim2.fromOffset(RIGHT_W, 436)
right.ZIndex = 14
right.Parent = frame

local toast = UIKit.boldLabel({
    parent = gui, name = "Toast", size = UDim2.fromOffset(760, 46),
    position = UDim2.fromScale(0.5, 0.2), anchor = Vector2.new(0.5, 0.5),
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
    task.delay(3, function()
        if toastToken == mine then toast.Visible = false end
    end)
end

local function libraryModel(zone, slot)
    local lib = (workspace:FindFirstChild("AnimalLibrary") or game:GetService("ReplicatedStorage"):FindFirstChild("AnimalLibrary"))
    local folder = lib and lib:FindFirstChild("Zone" .. zone)
    if not folder then return nil end
    local kids = folder:GetChildren()
    table.sort(kids, function(a, b) return a.Name < b.Name end)
    local m = kids[slot]
    if m and m:FindFirstChildWhichIsA("BasePart", true) then return m end
    return nil
end

local function showModel(vp, zone, slot, tier, silhouette)
    for _, c in ipairs(vp:GetChildren()) do
        if c:IsA("Model") or c:IsA("Camera") then c:Destroy() end
    end
    local src = libraryModel(zone, slot)
    if not src then return false end
    local m = src:Clone()

    pcall(function() require(game:GetService("ReplicatedStorage").Shared.AssetQueue).want(m) end)
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then d.Anchored = true d.CastShadow = false end
    end
    pcall(Paint.paint, m, tier, { preview = true })
    m.Parent = vp

    local pivot = m:GetPivot()
    local cf, size = m:GetBoundingBox()
    local cam = Instance.new("Camera")
    cam.FieldOfView = 32
    local radius = size.Magnitude * 0.5
    local dist = radius / math.tan(math.rad(cam.FieldOfView / 2)) * 1.02
    local dir = (pivot.LookVector + pivot.RightVector * 0.55 + Vector3.new(0, 0.30, 0)).Unit
    cam.CFrame = CFrame.lookAt(cf.Position + dir * dist, cf.Position)
    cam.Parent = vp
    vp.CurrentCamera = cam

    vp.Ambient = Color3.fromRGB(196, 196, 206)
    vp.LightColor = WHITE
    vp.LightDirection = Vector3.new(-0.35, -1, -0.55)
    if silhouette then
        vp.ImageColor3 = Color3.new(0, 0, 0)
        vp.ImageTransparency = 0.18
    else
        vp.ImageColor3 = WHITE
        vp.ImageTransparency = 0
    end
    return true
end

local state
local zoneSel = 1
local slotSel = 1
local zoneButtons = {}
local pendingModels = false

local render

local function pickSlot(zone)
    if not state then return 1 end
    local slots = state.zones[zone].slots
    for s = 1, PER_ZONE do
        if slots[s].found and not slots[s].claimed then return s end
    end
    for s = 1, PER_ZONE do
        if slots[s].found then return s end
    end
    return 1
end

local function clear(parent)
    for _, c in ipairs(parent:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
end

local function bar(parent, props)
    local back = Instance.new("Frame")
    back.Name = props.name or "Bar"
    back.BackgroundColor3 = Color3.fromRGB(22, 20, 40)
    back.BorderSizePixel = 0
    back.Position = props.position
    back.Size = props.size
    back.ZIndex = 16
    back.Parent = parent
    UIKit.corner(back, 12)
    UIKit.stroke(back, K.outline, 3)
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = props.colour
    fill.BorderSizePixel = 0
    fill.Size = UDim2.new(math.clamp(props.ratio, 0, 1), 0, 1, 0)
    fill.ZIndex = 17
    fill.Parent = back
    UIKit.corner(fill, 12)
    local g = Instance.new("UIGradient")
    g.Rotation = 90
    g.Color = ColorSequence.new(WHITE, Color3.fromRGB(190, 190, 190))
    g.Parent = fill
    fill.Visible = props.ratio > 0
    bold(back, { name = "Text", size = UDim2.fromScale(1, 1), text = props.text,
        strokeW = 4, textSize = props.textSize or 26, zindex = 19 })
    return back
end

local function buildZoneList()
    clear(zoneList)
    zoneButtons = {}
    for zone = 1, ZONES do
        local z = state.zones[zone]
        local h, s, v = (Cfg.COLORS[zone] or K.slab.base):ToHSV()
        local tone = toneOf(Color3.fromHSV(h, math.clamp(s, 0.55, 0.85), math.max(v, 0.92)))
        local selected = (zone == zoneSel)

        local holder = Instance.new("Frame")
        holder.Name = "Row" .. zone
        holder.BackgroundTransparency = 1
        holder.Size = UDim2.fromOffset(LEFT_W - 12, 52)
        holder.LayoutOrder = zone
        holder.ZIndex = 15
        holder.Parent = zoneList

        local shown = tone
        local b = block({
            parent = holder, name = "Zone" .. zone,
            tone = shown, react = false,
            clickable = true, size = UDim2.fromOffset(LEFT_W - 12, 48),
            radius = 10, outline = 3, stud = 10, studAlpha = 0.7, shadowY = 3, zindex = 16,
        })
        UIKit.tintOnHover(b, shown)
        if selected then
            local ring = Instance.new("UIStroke")
            ring.Name = "Selected"
            ring.Color = WHITE
            ring.Thickness = 3
            ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ring.Parent = b
        end
        local function shine(label)
            local g = Instance.new("UIGradient")
            g.Rotation = 90
            g.Color = ColorSequence.new(WHITE, Color3.fromRGB(255, 232, 140))
            g.Parent = label
            return label
        end
        local nameLabel = shine(bold(b, { name = "Name", size = UDim2.new(1, -72, 0.62, 0), position = UDim2.new(0, 12, 0.19, 0),
            align = Enum.TextXAlignment.Left, text = z.name:upper(), strokeW = 3, textSize = 17, zindex = 20 }))
        nameLabel.TextScaled = true
        local fit = Instance.new("UITextSizeConstraint")
        fit.MinTextSize = 10
        fit.MaxTextSize = 17
        fit.Parent = nameLabel

        local ready = z.ready or 0
        shine(bold(b, { name = "Count", size = UDim2.new(0, 48, 1, 0), position = UDim2.new(1, -62, 0, 0),
            align = Enum.TextXAlignment.Right,
            text = (ready > 0 and "! " or "") .. z.count .. "/" .. PER_ZONE,
            colour = (ready > 0) and K.ready.hi or ((z.count >= PER_ZONE) and K.bar.hi or WHITE),
            strokeW = 3, textSize = 16, zindex = 20 }))
        b.MouseButton1Click:Connect(function()
            if zoneSel ~= zone then
                zoneSel = zone
                slotSel = pickSlot(zone)
                render()
            end
        end)
        zoneButtons[zone] = b
    end
end

local function buildMiddle()
    clear(mid)
    local z = state.zones[zoneSel]
    local zc = Cfg.COLORS[zoneSel] or WHITE
    bold(mid, { name = "ZoneTitle", size = UDim2.fromOffset(MID_W, 40), position = UDim2.fromOffset(0, 0),
        align = Enum.TextXAlignment.Left, text = z.name:upper(), colour = zc:Lerp(WHITE, 0.25),
        strokeW = 5, textSize = 34, zindex = 18 })

    local missing = false
    for slot = 1, PER_ZONE do
        local info = z.slots[slot]
        local col = (slot - 1) % 4
        local row = math.floor((slot - 1) / 4)
        local tone = SLOT_TONE[slot] or K.lock
        local card = block({
            parent = mid, name = "Card" .. slot,
            tone = info.found and tone or dimTone(tone),
            clickable = true,
            size = UDim2.fromOffset(CARD_W, CARD_H),
            position = UDim2.fromOffset(col * (CARD_W + CARD_GAP), 48 + row * (CARD_H + CARD_GAP)),
            radius = 12, outline = 3, stud = 11, studAlpha = 0.72, shadowY = 4, zindex = 16,
            bevel = false,
        })
        if slot == slotSel then
            local ring = Instance.new("UIStroke")
            ring.Name = "Selected"
            ring.Color = WHITE
            ring.Thickness = 4
            ring.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            ring.Parent = card
            local old = card:FindFirstChildWhichIsA("UIStroke")
            if old and old ~= ring then old.Enabled = false end
        end

        local vp = Instance.new("ViewportFrame")
        vp.Name = "Model"
        vp.BackgroundTransparency = 1
        vp.Position = UDim2.fromOffset(6, 26)
        vp.Size = UDim2.fromOffset(CARD_W - 12, CARD_H - 32)
        vp.ZIndex = 19
        vp.Parent = card
        if not showModel(vp, zoneSel, slot, info.tier, not info.found) then missing = true end

        bold(card, { name = "Name", size = UDim2.fromOffset(CARD_W - 8, 24), position = UDim2.fromOffset(4, 3),
            text = info.found and info.name or "???", strokeW = 3, textSize = 15, zindex = 21,
            truncate = Enum.TextTruncate.AtEnd })

        if info.found and not info.claimed then
            local dot = Instance.new("Frame")
            dot.Name = "RewardDot"
            dot.AnchorPoint = Vector2.new(0.5, 0.5)
            dot.Position = UDim2.fromOffset(CARD_W - 8, 8)
            dot.Size = UDim2.fromOffset(26, 26)
            dot.BackgroundColor3 = K.ready.base
            dot.BorderSizePixel = 0
            dot.ZIndex = 24
            dot.Parent = card
            UIKit.corner(dot, 13)
            UIKit.stroke(dot, K.outline, 2)
            bold(dot, { name = "Mark", size = UDim2.fromScale(1, 1), text = "!",
                strokeW = 2, textSize = 18, zindex = 25 })
        end

        card.MouseButton1Click:Connect(function()
            if slotSel ~= slot then
                slotSel = slot
                render()
            end
        end)
    end

    local gridBottom = 48 + 2 * CARD_H + CARD_GAP
    local batZone=zoneSel
    local completed=z.count>=PER_ZONE
    local equipped=state.equippedBat==batZone
    local label=equipped and "Equipped" or (completed and "Equip Bat!" or (z.count.." / "..PER_ZONE))
    local reward=UIKit.button({
        parent=mid,name="EquipBat",tone=K.ready,text=label,textSize=28,
        size=UDim2.fromOffset(MID_W,44),position=UDim2.fromOffset(0,gridBottom+12),zindex=18,
        onClick=function() if completed and not equipped then remote:FireServer("equipBat",batZone) end end,
    })
    reward:SetAttribute("HoverMaxGrow", 8)
    art(reward,{name="BatIcon",image=BatConfig[batZone].Icon,size=UDim2.fromOffset(66,66),
        position=UDim2.new(1,-69,.5,-33),zindex=25})
    if completed then
        local reset=Instance.new("TextButton") reset.Name="DefaultBat" reset.BackgroundTransparency=1
        reset.Text="Default Bat" reset.Font=Enum.Font.GothamBold reset.TextSize=12
        reset.TextColor3=WHITE reset.Size=UDim2.fromOffset(80,22) reset.Position=UDim2.fromOffset(4,11)
        reset.ZIndex=25 reset.Parent=reward
        reset.Activated:Connect(function() remote:FireServer("equipBat",0) end)
    end

    local readyAll = state.ready or 0
    local total = bar(mid, {
        name = "Total",
        position = UDim2.fromOffset(34, gridBottom + 12 + 44 + 14), size = UDim2.fromOffset(MID_W - 34, 52),
        ratio = (readyAll > 0) and 1 or (state.total / state.max),
        colour = (readyAll > 0) and Color3.fromRGB(58, 168, 255) or Color3.fromRGB(70, 160, 240),
        text = (readyAll > 0) and ("CLAIM ALL (%d)!"):format(readyAll)
            or ("UNLOCKED: %d / %d"):format(state.total, state.max),
        textSize = (readyAll > 0) and 30 or 26,
    })
    if readyAll > 0 then
        local fill = total:FindFirstChild("Fill")
        local base = fill and fill.BackgroundColor3
        local hit = Instance.new("TextButton")
        hit.Name = "ClaimAll"
        hit.Text = ""
        hit.AutoButtonColor = false
        hit.BackgroundTransparency = 1
        hit.Size = UDim2.fromScale(1, 1)
        hit.ZIndex = 21
        hit.Parent = total
        hit.MouseEnter:Connect(function()
            if fill then fill.BackgroundColor3 = base:Lerp(WHITE, 0.22) end
        end)
        hit.MouseLeave:Connect(function()
            if fill then fill.BackgroundColor3 = base end
        end)
        hit.MouseButton1Click:Connect(function()
            remote:FireServer("claimAll")
        end)
    end
    art(mid, { name = "Book", image = ICON.book, size = UDim2.fromOffset(64, 64),
        position = UDim2.fromOffset(0, total.Position.Y.Offset - 6), zindex = 22 })

    return missing
end

local function buildRight()
    clear(right)
    local z = state.zones[zoneSel]
    local info = z.slots[slotSel]
    local tone = SLOT_TONE[slotSel] or K.lock

    local card = block({
        parent = right, name = "Detail", tone = K.thumb,
        size = UDim2.fromOffset(RIGHT_W, 270), position = UDim2.fromOffset(0, 0),
        radius = 14, outline = 3, stud = 12, studAlpha = 0.72, zindex = 16,
        bevel = false,
    })
    local glow = art(card, { name = "Glow", image = ICON.glow, size = UDim2.fromOffset(180, 150),
        position = UDim2.fromOffset(RIGHT_W / 2, 90), anchor = Vector2.new(0.5, 0.5),
        tint = tone.hi, transparency = info.found and 0.55 or 0.85, zindex = 18 })
    local vp = Instance.new("ViewportFrame")
    vp.Name = "Model"
    vp.BackgroundTransparency = 1
    vp.Position = UDim2.fromOffset(12, 12)
    vp.Size = UDim2.fromOffset(RIGHT_W - 24, 150)
    vp.ZIndex = 19
    vp.Parent = card
    showModel(vp, zoneSel, slotSel, info.tier, not info.found)

    bold(card, { name = "Name", size = UDim2.fromOffset(RIGHT_W - 16, 30), position = UDim2.fromOffset(8, 164),
        text = info.found and info.name or "???", strokeW = 4, textSize = 26, zindex = 21,
        truncate = Enum.TextTruncate.AtEnd })

    local badge = block({
        parent = card, name = "Rarity", tone = info.found and tone or dimTone(tone),
        size = UDim2.fromOffset(130, 26), position = UDim2.fromOffset((RIGHT_W - 130) / 2, 198),
        radius = 8, outline = 2, finish = false, bevel = false, shadow = false, zindex = 20,
    })
    bold(badge, { name = "Text", size = UDim2.fromScale(1, 1), text = info.rarity:upper(),
        strokeW = 3, textSize = 15, zindex = 23 })

    bold(card, { name = "Income", size = UDim2.fromOffset(RIGHT_W - 16, 24), position = UDim2.fromOffset(8, 226),
        text = info.found and (money(info.income) .. "/s") or "$?/s",
        colour = Color3.fromRGB(110, 240, 100), strokeW = 3, textSize = 22, zindex = 21 })
    bold(card, { name = "Source", size = UDim2.fromOffset(RIGHT_W - 16, 18), position = UDim2.fromOffset(8, 248),
        text = "HATCH FROM " .. info.source:upper(), colour = SECOND, strokeW = 2, textSize = 13, zindex = 21 })

    local box = block({
        parent = right, name = "Rewards", tone = K.thumb,
        size = UDim2.fromOffset(RIGHT_W, 154), position = UDim2.fromOffset(0, 282),
        radius = 14, outline = 3, stud = 12, studAlpha = 0.72, zindex = 16,
        bevel = false,
    })
    local ring = box:FindFirstChildWhichIsA("UIStroke")
    if ring then
        if info.found and not info.claimed then ring.Color = K.ready.base
        elseif info.claimed then ring.Color = K.ready.sh
        else ring.Color = K.outline end
    end
    bold(box, { name = "Title", size = UDim2.fromOffset(RIGHT_W - 24, 22), position = UDim2.fromOffset(12, 6),
        align = Enum.TextXAlignment.Left,
        text = (info.found and info.name:upper() or "???") .. " REWARD",
        strokeW = 3, textSize = 17, zindex = 21, truncate = Enum.TextTruncate.AtEnd })

    local function tile(x, image, text, tileTone)
        local t = block({
            parent = box, name = "Tile", tone = tileTone,
            size = UDim2.fromOffset(112, 54), position = UDim2.fromOffset(x, 32),
            radius = 10, outline = 2, stud = 9, studAlpha = 0.75, shadow = false, zindex = 18,
        })
        t:SetAttribute("SkinButtonLook", true)
        art(t, { image = image, size = UDim2.fromOffset(38, 38), position = UDim2.fromOffset(8, 8), zindex = 21 })
        bold(t, { name = "Amount", size = UDim2.fromOffset(62, 54), position = UDim2.fromOffset(48, 0),
            align = Enum.TextXAlignment.Left, text = text, strokeW = 3, textSize = 17, zindex = 22 })
    end
    tile(12, ICON.cash, money(info.money), K.ready)
    tile(RIGHT_W - 124, ICON.shoe, "+" .. Cfg.fmtSpeed(info.speed), K.bar)

    local label, btnTone, active

    local SILVER = {
        hi = Color3.fromRGB(238, 238, 242),
        base = Color3.fromRGB(196, 198, 204),
        sh = Color3.fromRGB(138, 140, 148),
    }
    if info.claimed then
        label, btnTone, active = "CLAIMED!", SILVER, false
    elseif info.found then
        label, btnTone, active = "CLAIM!", K.ready, true
    else
        label, btnTone, active = "HATCH TO UNLOCK", K.lock, false
    end
    local claimZone, claimSlot = zoneSel, slotSel
    local btn = UIKit.button({
        parent = box, name = "Claim", tone = btnTone, text = label, textSize = 20,
        size = UDim2.fromOffset(RIGHT_W - 24, 46), position = UDim2.fromOffset(12, 96), zindex = 18,
        onClick = function()
            if active then remote:FireServer("claim", claimZone, claimSlot) end
        end,
    })
    btn:SetAttribute("Active", active)
end

render = function()
    if not state then return end
    buildZoneList()
    local missing = buildMiddle()
    buildRight()

    if missing and not pendingModels and shell.Visible then
        pendingModels = true
        task.delay(2, function()
            pendingModels = false
            if shell.Visible then render() end
        end)
    end
end

local blurHeld = false
local function hudGlow(on)
    if _G.EggHudGlow then pcall(_G.EggHudGlow, on) end
end

local function pickStartZone()
    if not state then return end
    for zone = 1, ZONES do
        local z = state.zones[zone]
        if (z.ready or 0) > 0 then return zone end
    end
    for zone = 1, ZONES do
        if state.zones[zone].count < PER_ZONE then return zone end
    end
    return 1
end

local firstOpen = true
local function open()
    remote:FireServer("state")
    hudGlow(false)
    dim.Visible = true
    shell.Visible = true
    if not blurHeld then
        blurHeld = true
        UIKit.blurHold(true)
    end
    UIKit.popOpen(scale, fit())
    if state then
        if firstOpen then
            zoneSel = pickStartZone() or 1
            slotSel = pickSlot(zoneSel)
            firstOpen = false
        end
        render()
    end
end

local function shut()
    hudGlow(true)
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

remote.OnClientEvent:Connect(function(action, data)
    if action == "state" and type(data) == "table" then
        local was = state
        state = data
        if firstOpen and shell.Visible then
            zoneSel = pickStartZone() or 1
            slotSel = pickSlot(zoneSel)
            firstOpen = false
        end
        if shell.Visible then render() end
        if not was then return end
    elseif action == "found" and type(data) == "table" then
        local zoneName = Cfg.NAMES[data.zone] or ""
        say(("NEW PET: %s - claim your reward in the Index!"):format(tostring(data.name):upper()), K.bar.hi)
    elseif action == "claimed" and type(data) == "table" then
        say(("%s: +%s  +%s SPEED"):format(tostring(data.name or ""):upper(), money(data.money), Cfg.fmtSpeed(data.speed)), K.ready.hi)
    elseif action == "claimedAll" and type(data) == "table" then
        say(("CLAIMED %d: +%s  +%s SPEED"):format(data.count, money(data.money), Cfg.fmtSpeed(data.speed)), K.ready.hi)
    elseif action == "deny" then
        say(tostring(data), K.close.hi)
    end
end)

local bus = RS.Remotes:FindFirstChild("OpenPanel")
if bus then
    bus.Event:Connect(function(id)
        if id == "Index" then open()
        elseif shell.Visible then shut() end
    end)
end

_G.OpenPetIndex = open
remote:FireServer("state")