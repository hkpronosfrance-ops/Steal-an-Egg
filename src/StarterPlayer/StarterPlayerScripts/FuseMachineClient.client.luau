local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

local UIKit = require(RS:WaitForChild("Shared"):WaitForChild("UIKit"))
local AssetQueue = require(RS:WaitForChild("Shared"):WaitForChild("AssetQueue"))
local Cfg = require(RS:WaitForChild("EggConfig"))
local Fuse = require(RS:WaitForChild("FuseConfig"))
local PetPaint = require(RS:WaitForChild("AnimalPaint"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("Fuse")

local K = UIKit.Palette
local WHITE = UIKit.WHITE
local ICON_EGG = "rbxassetid://103180943014941"
local PIPE = Color3.fromRGB(30, 30, 36)
local GREEN = Color3.fromRGB(107, 255, 74)

local W, H = 700, 650
local SLOT_W, SLOT_H = 196, 118
local BOX_W, BOX_H = 196, 150

local money = Cfg.fmtMoney

local function coins()
    local w = plr:FindFirstChild("wallet")
    local c = w and w:FindFirstChild("Coins")
    return c and c.Value or 0
end

local function tierColour(tier)
    return (Cfg.TIERS[tier or 1] or Cfg.TIERS[1]).color
end

local function petPreview(vp, tool)
    vp:ClearAllChildren()
    local holder = Instance.new("Model")
    local handle = tool:FindFirstChild("Handle")
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            local c = p:Clone()
            c:ClearAllChildren()
            c.Anchored = true
            local rest = p:GetAttribute("RestOffset")
            if handle and typeof(rest) == "CFrame" then c.CFrame = handle.CFrame * rest end
            c.Parent = holder
        end
    end
    if #holder:GetChildren() == 0 then holder:Destroy() return end
    holder.Parent = vp
    AssetQueue.want(holder)
    local cf, size = holder:GetBoundingBox()
    local eye, up = PetPaint.viewDir(holder:GetChildren(), tool)
    eye = eye or Vector3.new(0.6, 0.35, 1).Unit
    up = up or Vector3.yAxis
    local cam = Instance.new("Camera")
    cam.FieldOfView = 32
    local radius = size.Magnitude * 0.5
    cam.CFrame = CFrame.lookAt(cf.Position + eye * (radius / math.tan(math.rad(16)) * 1.05), cf.Position, up)
    cam.Parent = vp
    vp.CurrentCamera = cam
    vp.Ambient = Color3.fromRGB(196, 196, 206)
    vp.LightDirection = Vector3.new(-0.35, -1, -0.55)
end

local gui = Instance.new("ScreenGui")
gui.Name = "FuseMachineGui"
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
shell.Name = "FuseMachine"
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

local frame = UIKit.block({
    parent = shell, name = "Frame", tone = K.panel, size = UDim2.fromOffset(W, H),
    radius = 15, outline = 3, shadowY = 8, bevel = false, stud = 15, studAlpha = 0.55, zindex = 10,
})
frame.BackgroundTransparency = 0.15
do
    local under = frame:FindFirstChild("Underside")
    if under then under.BackgroundTransparency = 0.15 end
end

local headH = UIKit.headHeight(W)
local header = UIKit.block({
    parent = frame, name = "Header", tone = K.claimed,
    size = UDim2.new(1, 0, 0, headH),
    radius = 12, outline = 3, stud = 10, studAlpha = 0.58, shadow = false, zindex = 14,
})
UIKit.boldLabel({
    parent = header, name = "Title", size = UDim2.new(1, -198, 1, 0), position = UDim2.fromOffset(98, 0),
    text = "Fuse Machine", align = Enum.TextXAlignment.Left, strokeW = 4, zindex = 22,
    textSize = math.floor(headH * 0.6),
})
local fuseIcon = Instance.new("ImageLabel")
fuseIcon.Name = "FuseIcon"
fuseIcon.BackgroundTransparency = 1
fuseIcon.Image = "rbxassetid://83291582290127"
fuseIcon.ScaleType = Enum.ScaleType.Fit
fuseIcon.Size = UDim2.fromOffset(84,84)
fuseIcon.AnchorPoint = Vector2.new(0,.5)
fuseIcon.Position = UDim2.new(0,8,.5,0)
fuseIcon.ZIndex = 22
fuseIcon.Parent = header

local shutSide = headH - 24
local closeBtn = UIKit.block({
    parent = header, name = "Close", tone = K.close, clickable = true,
    size = UDim2.fromOffset(shutSide, shutSide),
    position = UDim2.new(1, -(shutSide + 14), 0.5, 0), anchor = Vector2.new(0, 0.5),
    radius = math.floor(headH * 0.16), outline = 2, stud = 9, studAlpha = 0.70, shadowY = 4, zindex = 22,
})
UIKit.tintOnHover(closeBtn, K.close)
UIKit.cross(closeBtn, shutSide, Color3.fromRGB(255, 240, 224))

local line1 = UIKit.boldLabel({
    parent = frame, name = "Line1", size = UDim2.new(1, -40, 0, 40), position = UDim2.fromOffset(20, headH + 12),
    text = 'Bring <font color="#FF4B4B">3</font> of the same pet to fuse', strokeW = 4, zindex = 20, textSize = 32,
})
line1.RichText = true
local line2 = UIKit.boldLabel({
    parent = frame, name = "Line2", size = UDim2.new(1, -40, 0, 30), position = UDim2.fromOffset(20, headH + 50),
    text = '<font color="#6BFF4A">Better pets</font> give more <font color="#6BFF4A">Luck</font> \u{1F340}!',
    strokeW = 3, zindex = 20, textSize = 26,
})
line2.RichText = true

local SLOT_Y = headH + 96
local BOX_Y = SLOT_Y + SLOT_H + 48
local function slotX(i) return 24 + (i - 1) * (SLOT_W + 32) end

local function bar(x, y, w, h, colour)
    local f = Instance.new("Frame")
    f.BorderSizePixel = 0
    f.BackgroundColor3 = colour
    f.Position = UDim2.fromOffset(x, y)
    f.Size = UDim2.fromOffset(w, h)
    f.ZIndex = 15
    f.Parent = frame
    UIKit.corner(f, 4)
    return f
end
do
    local slotBottom = SLOT_Y + SLOT_H
    local boxLeft, boxRight = (W - BOX_W) / 2, (W + BOX_W) / 2
    local boxMid = BOX_Y + BOX_H / 2
    local c1, c2, c3 = slotX(1) + SLOT_W / 2, W / 2, slotX(3) + SLOT_W / 2
    bar(c2 - 9, slotBottom, 18, BOX_Y - slotBottom, PIPE)
    bar(c1 - 9, slotBottom, 18, boxMid - slotBottom + 9, PIPE)
    bar(c1 - 9, boxMid - 9, boxLeft - (c1 - 9), 18, PIPE)
    bar(c3 - 9, slotBottom, 18, boxMid - slotBottom + 9, PIPE)
    bar(boxRight, boxMid - 9, (c3 + 9) - boxRight, 18, PIPE)
    for _, c in ipairs({ c1, c2, c3 }) do bar(c - 30, slotBottom - 2, 60, 10, K.ready.base) end
    bar(c2 - 30, BOX_Y - 8, 60, 10, K.ready.base)
    bar(boxLeft - 10, boxMid - 25, 10, 50, K.ready.base)
    bar(boxRight, boxMid - 25, 10, 50, K.ready.base)
end

local chosen = {}
local state = { cost = 0 }
local showingResult = false
local slots = {}
local openPicker
local refresh

local note = UIKit.boldLabel({
    parent = gui, name = "Note", size = UDim2.fromOffset(720, 48),
    position = UDim2.fromScale(0.5, 0.12), anchor = Vector2.new(0.5, 0.5),
    text = "", colour = K.close.hi, strokeW = 4, textSize = 30, zindex = 40,
})
note.Visible = false
local noteToken = 0
local function say(text, colour)
    noteToken += 1
    local mine = noteToken
    note.Text = text
    note.TextColor3 = colour or K.close.hi
    note.Visible = true
    task.delay(2.6, function()
        if noteToken == mine then note.Visible = false end
    end)
end

for i = 1, Fuse.SLOTS do
    local s = UIKit.block({
        parent = frame, name = "Slot" .. i, tone = K.thumb, size = UDim2.fromOffset(SLOT_W, SLOT_H),
        position = UDim2.fromOffset(slotX(i), SLOT_Y), radius = 12, outline = 3, stud = 12, zindex = 16,
        bevel = false,
    })
    s.BackgroundTransparency = 0.25
    local title = UIKit.boldLabel({

        parent = s, name = "Title", size = UDim2.new(1, -84, 0, 30), position = UDim2.fromOffset(42, 6),
        text = "Empty", strokeW = 3, zindex = 22, textSize = 24,
    })
    local view = Instance.new("ViewportFrame")
    view.Name = "Pet"
    view.BackgroundTransparency = 1
    view.Size = UDim2.fromOffset(96, 76)
    view.Position = UDim2.new(0.5, -48, 0, 38)
    view.ZIndex = 21
    view.Visible = false
    view.Parent = s
    local add = UIKit.button({
        parent = s, name = "Add", tone = K.ready, text = "", textSize = 36,
        size = UDim2.fromOffset(SLOT_W - 48, 52), position = UDim2.fromOffset(24, SLOT_H - 64), zindex = 20,
        onClick = function() openPicker(i) end,
    })
    do
        local LEN, THICK, EDGE = 28, 8, 3
        local function bar(w, h, z, colour, pad)
            local f = Instance.new("Frame")
            f.Name = "Plus"
            f.AnchorPoint = Vector2.new(0.5, 0.5)
            f.Position = UDim2.fromScale(0.5, 0.5)
            f.Size = UDim2.fromOffset(w + pad * 2, h + pad * 2)
            f.BackgroundColor3 = colour
            f.BorderSizePixel = 0
            f.ZIndex = z
            f.Active = false
            local c = Instance.new("UICorner")
            c.CornerRadius = UDim.new(0, math.floor(THICK / 2) + pad)
            c.Parent = f
            f.Parent = add
        end
        bar(LEN, THICK, 23, K.outline, EDGE)
        bar(THICK, LEN, 23, K.outline, EDGE)
        bar(LEN, THICK, 24, WHITE, 0)
        bar(THICK, LEN, 24, WHITE, 0)
    end
    local remove = UIKit.button({
        parent = s, name = "Remove", tone = K.close, text = "X", textSize = 18,
        size = UDim2.fromOffset(34, 34), position = UDim2.new(1, -42, 0, 6), zindex = 24,
        onClick = function()
            chosen[i] = nil
            refresh()
        end,
    })
    remove.Visible = false
    slots[i] = { block = s, title = title, view = view, add = add, remove = remove, shown = nil }
end

local box = UIKit.block({
    parent = frame, name = "Result", tone = K.thumb, size = UDim2.fromOffset(BOX_W, BOX_H),
    position = UDim2.fromOffset((W - BOX_W) / 2, BOX_Y), radius = 12, outline = 3, stud = 12, zindex = 16,
    bevel = false,
})
box.BackgroundTransparency = 0.25
local eggIcon = Instance.new("ImageLabel")
eggIcon.Name = "Egg"
eggIcon.BackgroundTransparency = 1
eggIcon.Image = ICON_EGG
eggIcon.ImageColor3 = Color3.new(0, 0, 0)
eggIcon.ScaleType = Enum.ScaleType.Fit
eggIcon.AnchorPoint = Vector2.new(0.5, 0.5)
eggIcon.Position = UDim2.fromScale(0.5, 0.45)
eggIcon.Size = UDim2.fromOffset(104, 104)
eggIcon.ZIndex = 22
eggIcon.Parent = box
local eggScale = Instance.new("UIScale")
eggScale.Parent = eggIcon
local resultText = UIKit.boldLabel({
    parent = box, name = "ResultText", size = UDim2.new(1, -8, 0, 44), position = UDim2.new(0, 4, 1, -48),
    text = "", strokeW = 3, zindex = 24, textSize = 18, wrapped = true,
})

local info = UIKit.boldLabel({
    parent = frame, name = "Info", size = UDim2.new(1, -40, 0, 26), position = UDim2.fromOffset(20, BOX_Y + BOX_H + 10),
    text = "", strokeW = 3, zindex = 20, textSize = 20, colour = Color3.fromRGB(210, 214, 226),
})

local doFuse
local _, _, setFuseText, setFuseTone = UIKit.button({
    parent = frame, name = "Fuse", tone = K.ready, text = "3 Pets Left", textSize = 34,
    size = UDim2.fromOffset(300, 64), position = UDim2.fromOffset((W - 300) / 2, H - 84), zindex = 20,
    onClick = function() doFuse() end,
})

local picker = Instance.new("Frame")
picker.Name = "Picker"
picker.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
picker.BackgroundTransparency = 0
picker.BorderSizePixel = 0
picker.Position = UDim2.fromOffset(12, headH + 10)
picker.Size = UDim2.fromOffset(W - 24, H - headH - 22)
picker.ZIndex = 40
picker.Visible = false
picker.Parent = frame
UIKit.corner(picker, 12)
UIKit.boldLabel({
    parent = picker, name = "Title", size = UDim2.new(1, -160, 0, 44), position = UDim2.fromOffset(16, 8),
    text = "Choose a pet", align = Enum.TextXAlignment.Left, strokeW = 3, zindex = 42, textSize = 30,
})
local function closePicker() picker.Visible = false end
UIKit.button({
    parent = picker, name = "Back", tone = K.close, text = "BACK", textSize = 22,
    size = UDim2.fromOffset(120, 44), position = UDim2.new(1, -136, 0, 8), zindex = 42,
    onClick = closePicker,
})
local grid = Instance.new("ScrollingFrame")
grid.Name = "Grid"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.Position = UDim2.fromOffset(12, 60)
grid.Size = UDim2.new(1, -24, 1, -72)
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollBarThickness = 6
grid.ZIndex = 41
grid.Parent = picker
do

    local layout = Instance.new("UIGridLayout")
    layout.CellSize = UDim2.fromOffset(148, 170)
    layout.CellPadding = UDim2.fromOffset(12, 12)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = grid
    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 6)
    pad.PaddingBottom = UDim.new(0, 6)
    pad.PaddingLeft = UDim.new(0, 6)
    pad.PaddingRight = UDim.new(0, 10)
    pad.Parent = grid
end
local emptyNote = UIKit.boldLabel({
    parent = picker, name = "Empty", size = UDim2.new(1, -40, 0, 40), position = UDim2.new(0, 20, 0.5, -20),
    text = "", strokeW = 3, zindex = 43, textSize = 24, colour = Color3.fromRGB(200, 204, 214),
})

local function petTools()
    local out = {}
    for _, holder in ipairs({ plr:FindFirstChildOfClass("Backpack"), plr.Character }) do
        for _, t in ipairs(holder and holder:GetChildren() or {}) do
            if t:IsA("Tool") and t:GetAttribute("AnimalZone") then table.insert(out, t) end
        end
    end
    table.sort(out, function(a, b)
        local ia = Cfg.petIncome(a:GetAttribute("AnimalZone"), a:GetAttribute("AnimalSize") or 1, a:GetAttribute("AnimalTier") or 1, a:GetAttribute("Luck"))
        local ib = Cfg.petIncome(b:GetAttribute("AnimalZone"), b:GetAttribute("AnimalSize") or 1, b:GetAttribute("AnimalTier") or 1, b:GetAttribute("Luck"))
        if ia ~= ib then return ia > ib end
        return a.Name < b.Name
    end)
    return out
end

local function owned(t)
    return t and (t.Parent == plr:FindFirstChildOfClass("Backpack") or (plr.Character ~= nil and t.Parent == plr.Character))
end

local function sameAs(t, ref)
    return not ref or (t:GetAttribute("AnimalZone") == ref:GetAttribute("AnimalZone")
        and (t:GetAttribute("AnimalTier") or 1) == (ref:GetAttribute("AnimalTier") or 1)
        and t:GetAttribute("Species") == ref:GetAttribute("Species"))
end

local function isChosen(t)
    for i = 1, Fuse.SLOTS do
        if chosen[i] == t then return true end
    end
    return false
end

local function resetResult()
    if showingResult then
        showingResult = false
        eggIcon.ImageColor3 = Color3.new(0, 0, 0)
        resultText.Text = ""
    end
end

openPicker = function(slot)
    for _, c in ipairs(grid:GetChildren()) do
        if c:IsA("GuiObject") then c:Destroy() end
    end
    local ref
    for i = 1, Fuse.SLOTS do
        if chosen[i] and i ~= slot then ref = chosen[i] break end
    end
    local n = 0
    for _, t in ipairs(petTools()) do
        if not isChosen(t) and sameAs(t, ref) then
            n += 1
            local tier = t:GetAttribute("AnimalTier") or 1
            local card = Instance.new("TextButton")
            card.Name = "Pet" .. n
            card.AutoButtonColor = false
            card.Text = ""
            card.BackgroundColor3 = Color3.fromRGB(34, 38, 52)
            card.BorderSizePixel = 0
            card.LayoutOrder = n
            card.ZIndex = 42
            card.Parent = grid
            UIKit.corner(card, 10)
            UIKit.stroke(card, tierColour(tier), 2, 0.2)
            local vp = Instance.new("ViewportFrame")
            vp.BackgroundTransparency = 1
            vp.Size = UDim2.new(1, -16, 0, 100)
            vp.Position = UDim2.fromOffset(8, 6)
            vp.ZIndex = 43
            vp.Parent = card
            petPreview(vp, t)
            UIKit.boldLabel({
                parent = card, name = "Name", size = UDim2.new(1, -8, 0, 26), position = UDim2.fromOffset(4, 108),
                text = t:GetAttribute("Species") or t.Name, strokeW = 3, zindex = 44, textSize = 20,
                colour = tierColour(tier),
            })
            local luck = t:GetAttribute("Luck")
            local sizeName = Cfg.SIZES[t:GetAttribute("AnimalSize") or 1] and Cfg.SIZES[t:GetAttribute("AnimalSize") or 1].name or ""
            UIKit.boldLabel({
                parent = card, name = "Sub", size = UDim2.new(1, -8, 0, 22), position = UDim2.fromOffset(4, 136),
                text = luck and ("(%s) %+d%%"):format(sizeName, luck) or ("(%s)"):format(sizeName),
                strokeW = 2, zindex = 44, textSize = 16, colour = Color3.fromRGB(200, 204, 214),
            })
            card.MouseButton1Click:Connect(function()
                chosen[slot] = t
                resetResult()
                closePicker()
                refresh()
            end)
        end
    end
    emptyNote.Visible = n == 0
    emptyNote.Text = ref and "No more matching pets in your backpack" or "No pets in your backpack"
    picker.Visible = true
end

local function holoCount(count)
    local aux = workspace:FindFirstChild("FuseMachine")
    local label = aux and aux:FindFirstChild("HoloCount", true)
    if label then label.Text = ("%d/%d"):format(count, Fuse.SLOTS) end
end

refresh = function()
    for i = 1, Fuse.SLOTS do
        if chosen[i] and not owned(chosen[i]) then chosen[i] = nil end
    end
    local count, sizes, ref = 0, {}, nil
    for i = 1, Fuse.SLOTS do
        local s, t = slots[i], chosen[i]
        if t then
            count += 1
            ref = ref or t
            table.insert(sizes, t:GetAttribute("AnimalSize") or 1)
            s.title.Text = t:GetAttribute("Species") or t.Name
            s.title.TextColor3 = tierColour(t:GetAttribute("AnimalTier"))
            s.add.Visible = false
            s.remove.Visible = true
            s.view.Visible = true
            if s.shown ~= t then
                s.shown = t
                petPreview(s.view, t)
            end
        else
            s.title.Text = "Empty"
            s.title.TextColor3 = WHITE
            s.add.Visible = true
            s.remove.Visible = false
            s.view.Visible = false
            if s.shown then
                s.shown = nil
                s.view:ClearAllChildren()
            end
        end
    end

    holoCount(count)

    local left = Fuse.SLOTS - count
    if left > 0 then
        state.cost = 0
        setFuseText((left == 1 and "%d Pet Left" or "%d Pets Left"):format(left))
        setFuseTone(K.ready)
        info.Text = ("Egg size and Luck (%d%% to +%d%%) are random"):format(Fuse.LUCK_MIN, Fuse.LUCK_MAX)
    else
        local zone, tier = ref:GetAttribute("AnimalZone"), ref:GetAttribute("AnimalTier") or 1
        local cost = 0
        for _, sz in ipairs(sizes) do cost += Fuse.cost(zone, tier, sz) end
        cost = math.floor(cost / #sizes + 0.5)
        state.cost = cost
        setFuseText("FUSE " .. money(cost))
        setFuseTone(coins() >= cost and K.ready or K.close)
        info.Text = ("You get a %s egg - random size, Luck %d%% to +%d%%"):format(
            tostring(ref:GetAttribute("Species") or "pet"), Fuse.LUCK_MIN, Fuse.LUCK_MAX)
    end
end

local luckBoost = 1
local baseRefresh = refresh
refresh = function()
    baseRefresh()
    if luckBoost > 1 then
        info.Text = info.Text .. ("  |  FUSE LUCK x%g ACTIVE"):format(luckBoost)
    end
end
task.spawn(function()
    local boostRemote = RS:WaitForChild("Remotes"):WaitForChild("GlobalBoost", 20)
    if not boostRemote then return end
    boostRemote.OnClientEvent:Connect(function(state)
        local entry = type(state) == "table" and state.luck
        luckBoost = type(entry) == "table" and (tonumber(entry.mult) or 1) or 1
        refresh()
    end)
    boostRemote:FireServer()
end)

doFuse = function()
    local tools = {}
    for i = 1, Fuse.SLOTS do
        if not chosen[i] then
            say("Put 3 of the same pet in the machine")
            return
        end
        tools[i] = chosen[i]
    end
    if coins() < (state.cost or 0) then
        say("Not enough money")
        return
    end
    remote:FireServer("fuse", tools)
end

remote.OnClientEvent:Connect(function(action, data)
    if action == "deny" then
        say(tostring(data))
    elseif action == "fused" and type(data) == "table" then
        table.clear(chosen)
        showingResult = true
        eggIcon.ImageColor3 = Cfg.eggColor(data.zone or 1, data.tier or 1)
        local luck = tonumber(data.luck) or 0
        local sizeName = Cfg.SIZES[data.size or 1] and Cfg.SIZES[data.size or 1].name or ""
        resultText.Text = ("%s %s Egg\nLuck %+d%%"):format(sizeName, tostring(data.species or ""), luck)
        resultText.TextColor3 = luck >= 0 and GREEN or Color3.fromRGB(255, 96, 96)
        eggScale.Scale = 0.4
        game:GetService("TweenService"):Create(eggScale,
            TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
        say("Fused! The egg is in your backpack", K.ready.hi)
        refresh()
    end
end)

local isOpen, blurHeld, openedByRing = false, false, false

local function open()
    if isOpen then return end
    isOpen = true
    dim.Visible = true
    shell.Visible = true
    if not blurHeld then
        blurHeld = true
        UIKit.blurHold(true)
    end
    closePicker()
    refresh()
    UIKit.popOpen(scale, fit())
end

local function shut()
    isOpen = false
    openedByRing = false
    closePicker()
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

local bus = RS:WaitForChild("Remotes"):FindFirstChild("OpenPanel")
if bus then
    bus.Event:Connect(function(id)
        if id == "FuseMachine" then
            open()
        elseif isOpen then
            shut()
        end
    end)
end

task.spawn(function()
    local function hook(bag)
        if not bag then return end
        bag.ChildAdded:Connect(function() if isOpen then refresh() end end)
        bag.ChildRemoved:Connect(function() if isOpen then refresh() end end)
    end
    hook(plr:WaitForChild("Backpack", 30))
    plr.ChildAdded:Connect(function(c) if c:IsA("Backpack") then hook(c) end end)
    local wallet = plr:WaitForChild("wallet", 60)
    local c = wallet and wallet:WaitForChild("Coins", 30)
    if c then c.Changed:Connect(function() if isOpen then refresh() end end) end
end)

task.spawn(function()
    local aux = workspace:WaitForChild("FuseMachine", 60)
    local ring = aux and aux:WaitForChild("FuseMachineRing", 60)
    if not ring then
        warn("[FUSE] no FuseMachineRing - the Fuse Machine only opens from code")
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
                    if bus then bus:Fire("FuseMachine") else open() end
                    openedByRing = true
                end
            elseif inside and (flat > radius + 3 or not level) then
                inside = false
                if isOpen and openedByRing then shut() end
            end
        end
    end
end)

_G.OpenFuseMachine = open