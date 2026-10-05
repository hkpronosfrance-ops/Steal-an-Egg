local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local RunSvc  = game:GetService("RunService")
local TextSvc = game:GetService("TextService")

local plr    = Players.LocalPlayer
local Remote = RS.Remotes:WaitForChild("Egg")
local Cfg    = require(RS:WaitForChild("EggConfig"))

local gui = Instance.new("ScreenGui")
gui.Name = "EggHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = plr:WaitForChild("PlayerGui")

local function lerp(a, b, t) return a + (b - a) * t end

local FONT_SIZE   = 36
local PAD_X, PAD_Y = 24, 13

local plate = Instance.new("Frame")
plate.Name = "BiomeBanner"
plate.AnchorPoint = Vector2.new(0.5, 0)
plate.BackgroundTransparency = 1
plate.BorderSizePixel = 0
plate.ClipsDescendants = true
plate.Size = UDim2.new(0, 240, 0, FONT_SIZE + PAD_Y * 2)
plate.Visible = false
plate.Parent = gui
local corner = Instance.new("UICorner", plate)
corner.CornerRadius = UDim.new(0, 12)

local studs = Instance.new("ImageLabel")
studs.Name = "Studs"
studs.Size = UDim2.fromScale(1, 1)
studs.BackgroundTransparency = 1
studs.Image = Cfg.STUDS
studs.ScaleType = Enum.ScaleType.Tile
studs.TileSize = UDim2.fromOffset(26, 26)
studs.ImageColor3 = Color3.fromRGB(255, 255, 255)
studs.ImageTransparency = 1
studs.ZIndex = 2
studs.Parent = plate

local pStroke = Instance.new("UIStroke", plate)
pStroke.Thickness = 4
pStroke.Transparency = 1
pStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local bLabel = Instance.new("TextLabel")
bLabel.Name = "Label"
bLabel.Size = UDim2.fromScale(1, 1)
bLabel.BackgroundTransparency = 1
bLabel.Font = Enum.Font.FredokaOne
bLabel.TextSize = FONT_SIZE
bLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
bLabel.TextStrokeColor3 = Color3.fromRGB(24, 20, 34)
bLabel.TextStrokeTransparency = 1
bLabel.TextTransparency = 1
bLabel.ZIndex = 4
bLabel.Text = ""
bLabel.Parent = plate

local bAlpha, bTarget, bHoldUntil = 0, 0, 0

local function shade(c, k)
    return Color3.new(math.clamp(c.R*k,0,1), math.clamp(c.G*k,0,1), math.clamp(c.B*k,0,1))
end

local function showBiome(zone)
    local txt = Cfg.NAMES[zone] .. " " .. (Cfg.EMOJI[zone] or "")
    local col = Cfg.COLORS[zone]
    bLabel.Text = txt

    plate.BackgroundColor3 = shade(col, 0.42)
    pStroke.Color = col
    local sz = TextSvc:GetTextSize(txt, FONT_SIZE, Enum.Font.FredokaOne, Vector2.new(1600, 400))
    plate.Size = UDim2.new(0, math.max(170, sz.X + PAD_X * 2), 0, FONT_SIZE + PAD_Y * 2)
    bAlpha = 0
    bTarget = 1
    bHoldUntil = os.clock() + 2.6
end

local lastZone = nil
task.spawn(function()
    while true do
        local ch = plr.Character
        local root = ch and ch:FindFirstChild("HumanoidRootPart")
        if root then
            local z = Cfg.zoneAt(root.Position.Z)
            if z and z ~= lastZone then

                if z >= 1 and lastZone ~= nil and z > lastZone then showBiome(z) end
                lastZone = z
            end
        end
        task.wait(0.15)
    end
end)

local runPlate = Instance.new("Frame")
runPlate.Name = "RunBanner"
runPlate.AnchorPoint = Vector2.new(0.5, 0)
runPlate.BackgroundColor3 = Color3.fromRGB(178, 26, 26)
runPlate.BackgroundTransparency = 1
runPlate.BorderSizePixel = 0
runPlate.ClipsDescendants = true
runPlate.Size = UDim2.new(0, 250, 0, 74)
runPlate.Visible = false
runPlate.ZIndex = 6
runPlate.Parent = gui
Instance.new("UICorner", runPlate).CornerRadius = UDim.new(0, 14)

local runStuds = Instance.new("ImageLabel")
runStuds.Size = UDim2.fromScale(1, 1)
runStuds.BackgroundTransparency = 1
runStuds.Image = Cfg.STUDS
runStuds.ScaleType = Enum.ScaleType.Tile
runStuds.TileSize = UDim2.fromOffset(26, 26)
runStuds.ImageTransparency = 1
runStuds.ZIndex = 7
runStuds.Parent = runPlate

local runStroke = Instance.new("UIStroke", runPlate)
runStroke.Thickness = 6
runStroke.Color = Color3.fromRGB(22, 20, 26)
runStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
runStroke.Transparency = 1

local runLabel = Instance.new("TextLabel")
runLabel.Size = UDim2.fromScale(1, 1)
runLabel.BackgroundTransparency = 1
runLabel.Font = Enum.Font.FredokaOne
runLabel.TextScaled = true
runLabel.Text = "RUN!"
runLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
runLabel.TextStrokeColor3 = Color3.fromRGB(92, 10, 10)
runLabel.TextStrokeTransparency = 1
runLabel.TextTransparency = 1
runLabel.ZIndex = 8
runLabel.Parent = runPlate

local vig = Instance.new("Frame")
vig.Name = "DangerVignette"
vig.Size = UDim2.fromScale(1, 1)
vig.BackgroundTransparency = 1
vig.BorderSizePixel = 0
vig.Visible = false
vig.ZIndex = 2
vig.Parent = gui
local edges = {}
for _, side in ipairs({"Top", "Bottom", "Left", "Right"}) do
    local f = Instance.new("Frame")
    f.Name = side
    f.BackgroundColor3 = Color3.fromRGB(190, 20, 20)
    f.BorderSizePixel = 0
    f.ZIndex = 2
    local horiz = (side == "Top" or side == "Bottom")
    f.Size = horiz and UDim2.new(1, 0, 0.24, 0) or UDim2.new(0.16, 0, 1, 0)
    f.Position = ({
        Top    = UDim2.fromScale(0, 0),
        Bottom = UDim2.fromScale(0, 0.76),
        Left   = UDim2.fromScale(0, 0),
        Right  = UDim2.fromScale(0.84, 0),
    })[side]
    local g = Instance.new("UIGradient", f)
    g.Rotation = ({Top = 90, Bottom = 270, Left = 0, Right = 180})[side]
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(1, 1),
    })
    f.Parent = vig
    table.insert(edges, f)
end

local dropBtn = Instance.new("TextButton")
dropBtn.Name = "DropButton"
dropBtn.AnchorPoint = Vector2.new(0.5, 1)
dropBtn.Size = UDim2.new(0, 300, 0, 88)
dropBtn.BackgroundColor3 = Color3.fromRGB(198, 32, 32)
dropBtn.BorderSizePixel = 0
dropBtn.AutoButtonColor = false
dropBtn.Text = ""
dropBtn.Visible = false
dropBtn.ZIndex = 6
dropBtn.Parent = gui
Instance.new("UICorner", dropBtn).CornerRadius = UDim.new(0, 14)
local dropStroke = Instance.new("UIStroke", dropBtn)
dropStroke.Thickness = 6
dropStroke.Color = Color3.fromRGB(22, 20, 26)

dropStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local dropClip = Instance.new("Frame")
dropClip.Name = "StudsClip"
dropClip.Size = UDim2.fromScale(1, 1)
dropClip.BackgroundTransparency = 1
dropClip.ClipsDescendants = true
dropClip.ZIndex = 6
dropClip.Parent = dropBtn
Instance.new("UICorner", dropClip).CornerRadius = UDim.new(0, 14)

local dropStuds = Instance.new("ImageLabel")
dropStuds.Name = "Studs"
dropStuds.Size = UDim2.fromScale(1, 1)
dropStuds.BackgroundTransparency = 1
dropStuds.Image = Cfg.STUDS
dropStuds.ScaleType = Enum.ScaleType.Tile
dropStuds.TileSize = UDim2.fromOffset(26, 26)
dropStuds.ImageTransparency = 1
dropStuds.ZIndex = 6
dropStuds.Parent = dropClip

local dropIcon = Instance.new("ImageLabel")
dropIcon.Name = "Icon"
dropIcon.AnchorPoint = Vector2.new(0, 0.5)
dropIcon.Position = UDim2.new(0, 16, 0.5, 0)
dropIcon.Size = UDim2.fromOffset(76, 76)
dropIcon.BackgroundTransparency = 1
dropIcon.Image = "rbxassetid://89522432338265"
dropIcon.ZIndex = 7
dropIcon.Parent = dropBtn

local dropText = Instance.new("TextLabel")
dropText.AnchorPoint = Vector2.new(1, 0.5)
dropText.Position = UDim2.new(1, -22, 0.5, 0)
dropText.Size = UDim2.new(1, -110, 0.62, 0)
dropText.BackgroundTransparency = 1
dropText.Font = Enum.Font.FredokaOne
dropText.TextScaled = true
dropText.Text = "Drop"
dropText.TextColor3 = Color3.fromRGB(255, 255, 255)
dropText.TextStrokeColor3 = Color3.fromRGB(92, 10, 10)
dropText.TextStrokeTransparency = 0
dropText.ZIndex = 7
dropText.Parent = dropBtn

local cardAlpha, cardTarget = 0, 0

local carrying = nil
dropBtn.MouseButton1Click:Connect(function()
    if carrying then Remote:FireServer("Drop") end
end)
plr:GetAttributeChangedSignal("CarryingEgg"):Connect(function()
    if plr:GetAttribute("CarryingEgg") ~= true then
        carrying = nil
        cardTarget = 0
    end
end)

local StarterGui = game:GetService("StarterGui")
local UIS        = game:GetService("UserInputService")

task.spawn(function()
    for _ = 1, 20 do
        local ok = pcall(function()
            StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        end)
        if ok then break end
        task.wait(0.25)
    end
end)

local SLOTS, COLS = 10, 6
local PANEL_W_SCALE, PANEL_H_SCALE = 0.343, 0.325
local SLOT_GAP, CARD_GAP = 10, 6

local INK      = Color3.fromRGB(236, 240, 232)
local OUTLINE  = Color3.fromRGB(22, 26, 20)
local PANEL_BG = Color3.fromRGB(58, 66, 50)
local SLOT_BG  = Color3.fromRGB(44, 50, 38)
local EDGE     = Color3.fromRGB(168, 184, 146)
local PICKED   = Color3.fromRGB(248, 250, 244)

local TIER_INK = {
    Color3.fromRGB(224, 228, 218),
    Color3.fromRGB(126, 226, 132),
    Color3.fromRGB(118, 176, 250),
    Color3.fromRGB(250, 206, 96),
}

local bagGui = Instance.new("ScreenGui")
bagGui.Name = "EggBag"
bagGui.ResetOnSpawn = false
bagGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
bagGui.DisplayOrder = 5
bagGui.Parent = plr:WaitForChild("PlayerGui")

local function corner(o, r) local c = Instance.new("UICorner", o) c.CornerRadius = UDim.new(0, r) return c end

local function edge(o, col, w, show)
    local st = Instance.new("UIStroke")
    st.Thickness = w or 2
    st.Color = col or EDGE
    st.Transparency = show and 0 or 1
    st.LineJoinMode = Enum.LineJoinMode.Round
    st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    st.Parent = o
    return st
end

local function shout(parent, size, pos, text, maxSize, col, align, z)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Size, l.Position = size, pos
    l.Font = Enum.Font.FredokaOne
    l.Text = text
    l.TextScaled = true
    l.TextColor3 = col or INK
    l.TextStrokeColor3 = OUTLINE
    l.TextStrokeTransparency = 0
    l.TextXAlignment = align or Enum.TextXAlignment.Center
    l.ZIndex = z or 6
    l.Parent = parent
    local c = Instance.new("UITextSizeConstraint")
    c.MinTextSize = 6
    c.MaxTextSize = maxSize
    c.Parent = l
    return l, c
end

local PetPaint = require(game:GetService("ReplicatedStorage"):WaitForChild("AnimalPaint"))
local AssetQueue = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("AssetQueue"))

local IconContent = game:GetService("ContentProvider")
local iconToken = setmetatable({}, { __mode = "k" })
local iconLoaded = setmetatable({}, { __mode = "k" })
local ICON_REFRESH = { 1.5, 4 }

local function iconAssetsOf(tool)
    local ids, seen = {}, {}
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("MeshPart") then
            for _, id in ipairs({ p.MeshId, p.TextureID }) do
                if id ~= "" and not seen[id] then
                    seen[id] = true
                    table.insert(ids, id)
                end
            end
        end
    end
    return ids
end

local batIconConnections = setmetatable({}, {__mode="k"})
local function fillIcon(view, tool, pass)
    if batIconConnections[view] then batIconConnections[view]:Disconnect() batIconConnections[view]=nil end
    view:ClearAllChildren()
    local token = (iconToken[view] or 0) + 1
    iconToken[view] = token
    pass = pass or 0
    if tool:GetAttribute("Gear") == "Stick" then
        view.CurrentCamera = nil
        local image=Instance.new("ImageLabel")
        image.Name="BatArtwork" image.BackgroundTransparency=1
        image.Size=UDim2.fromScale(1,1) image.ScaleType=Enum.ScaleType.Fit
        image.ZIndex=view.ZIndex+1 image.Parent=view
        local function update()
            image.Image=tool.TextureId~="" and tool.TextureId or "rbxassetid://128088129405176"
        end
        update()
        local connection=tool:GetPropertyChangedSignal("TextureId"):Connect(update)
        batIconConnections[view]=connection
        image.Destroying:Once(function()
            connection:Disconnect()
            if batIconConnections[view]==connection then batIconConnections[view]=nil end
        end)
        return
    end
    if not iconLoaded[tool] then
        task.spawn(function()
            local ids = iconAssetsOf(tool)
            if #ids > 0 then
                pcall(IconContent.PreloadAsync, IconContent, ids)
            end
            task.wait()
            iconLoaded[tool] = true
            if iconToken[view] == token and tool.Parent and view.Parent then
                fillIcon(view, tool, pass)
            end
        end)
        return
    end
    local nextWait = ICON_REFRESH[pass + 1]
    if nextWait then
        task.delay(nextWait, function()
            if iconToken[view] == token and tool.Parent and view.Parent then
                fillIcon(view, tool, pass + 1)
            end
        end)
    end
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
    AssetQueue.want(holder)
    holder.Parent = view
    local cf = holder:GetBoundingBox()
    local cam = Instance.new("Camera")
    cam.FieldOfView = 30

    local eye  = Vector3.new(0.86, 0.62, 1).Unit
    local roll = math.rad(30)
    local up   = Vector3.yAxis

    local viewEye, viewUp = PetPaint.viewDir(holder:GetChildren(), tool)
    if viewEye then
        eye, up = viewEye, viewUp
        roll = 0
    end
    local isTrap = tool:GetAttribute("Gear") == "Trap"
    if isTrap then
        eye = Vector3.new(0.35, 1, 0.8).Unit
        up = Vector3.yAxis
        roll = math.rad(-14)
    end
    local function aim(dist)
        return CFrame.lookAt(cf.Position + eye * dist, cf.Position, up) * CFrame.Angles(0, 0, roll)
    end

    local probe = aim(10)
    local reach = 0
    for _, p in ipairs(holder:GetChildren()) do
        if p:IsA("BasePart") then
            for dx = -1, 1, 2 do
                for dy = -1, 1, 2 do
                    for dz = -1, 1, 2 do
                        local corner = (p.CFrame
                            * CFrame.new(p.Size * Vector3.new(dx, dy, dz) / 2)).Position
                        local inCam = probe:PointToObjectSpace(corner)
                        reach = math.max(reach, math.abs(inCam.X), math.abs(inCam.Y))
                    end
                end
            end
        end
    end
    if reach <= 0 then reach = 1 end

    cam.CFrame = aim(reach / math.tan(math.rad(cam.FieldOfView / 2)) * (isTrap and 0.9 or 1.08))
    cam.Parent = view
    view.CurrentCamera = cam
    view.LightDirection = Vector3.new(-0.4, -1, -0.4)
    view.Ambient = Color3.fromRGB(180, 180, 190)
end

local GEAR_ORDER = { Stick = 1, Trap = 2 }

local stored = setmetatable({}, { __mode = "k" })
local storedKeys = {}
local markDirty

local function keyOf(tool)
    local k = tool:GetAttribute("SaveKey")
    return (type(k) == "string" and k ~= "") and k or nil
end

local function isStored(tool)
    if stored[tool] then return true end
    local k = keyOf(tool)
    return k ~= nil and storedKeys[k] == true
end

local wantedEggs = {}
local bagReadyAt = math.huge

local function eggSig(tool)
    local z, t, s = tool:GetAttribute("EggZone"), tool:GetAttribute("EggTier"), tool:GetAttribute("EggSize")
    if not (z and t and s) then return nil end
    return ("z%d_t%d_s%d"):format(z, t, s)
end

local function eggToolsBySig()
    local by = {}
    for _, holder in ipairs({ plr:FindFirstChildOfClass("Backpack"), plr.Character }) do
        for _, t in ipairs(holder and holder:GetChildren() or {}) do
            if t:IsA("Tool") and not keyOf(t) then
                local sig = eggSig(t)
                if sig then
                    by[sig] = by[sig] or {}
                    table.insert(by[sig], t)
                end
            end
        end
    end
    return by
end

local function reconcileEggs()
    local by = eggToolsBySig()
    local ready = os.clock() >= bagReadyAt
    for sig, tools in pairs(by) do
        local want = wantedEggs[sig] or 0
        local have = 0
        for _, t in ipairs(tools) do if stored[t] then have += 1 end end
        for _, t in ipairs(tools) do
            if have >= want then break end
            if not stored[t] and t.Parent ~= plr.Character then
                stored[t] = true
                have += 1
            end
        end
        if ready and have ~= want then
            wantedEggs[sig] = (have > 0) and have or nil
            Remote:FireServer("BagSet", { sig = sig, count = have })
        end
    end
    if ready then
        for sig in pairs(wantedEggs) do
            if not by[sig] then
                wantedEggs[sig] = nil
                Remote:FireServer("BagSet", { sig = sig, count = 0 })
            end
        end
    end
end

local function setStored(tool, on)
    if not tool or tool:GetAttribute("Gear") then return end
    stored[tool] = on or nil
    local k = keyOf(tool)
    if k then storedKeys[k] = on or nil end
    if on and tool.Parent == plr.Character then
        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:UnequipTools() end
    end

    if k then
        Remote:FireServer("BagSet", { key = k, on = on == true })
    else
        local sig = eggSig(tool)
        if sig then
            local n = 0
            for _, t in ipairs(eggToolsBySig()[sig] or {}) do
                if stored[t] then n += 1 end
            end
            wantedEggs[sig] = (n > 0) and n or nil
            Remote:FireServer("BagSet", { sig = sig, count = n })
        end
    end
    if markDirty then markDirty() end
end

local function toolsOfPlayer()
    local list = {}
    local function scan(parent)
        for _, t in ipairs(parent and parent:GetChildren() or {}) do
            if t:IsA("Tool") then
                local gear = t:GetAttribute("Gear")
                local zone = t:GetAttribute("EggZone")

                local pet = t:GetAttribute("AnimalZone")
                if gear or zone or pet then
                    table.insert(list, {
                        tool = t,
                        gear = gear,
                        pet = pet ~= nil,
                        zone = zone or pet,
                        tier = t:GetAttribute("EggTier") or t:GetAttribute("AnimalTier") or 1,
                        size = t:GetAttribute("EggSize") or t:GetAttribute("AnimalSize") or 1,
                        equipped = (t.Parent == plr.Character),
                        stored = isStored(t),
                    })
                end
            end
        end
    end
    scan(plr:FindFirstChildOfClass("Backpack"))
    scan(plr.Character)
    table.sort(list, function(p, q)
        if (p.gear ~= nil) ~= (q.gear ~= nil) then return p.gear ~= nil end
        if p.gear then
            return (GEAR_ORDER[p.gear] or 9) < (GEAR_ORDER[q.gear] or 9)
        end
        if p.tier ~= q.tier then return p.tier > q.tier end
        if p.size ~= q.size then return p.size > q.size end
        if p.zone ~= q.zone then return p.zone < q.zone end
        return p.tool.Name < q.tool.Name
    end)
    return list
end

local function carryingEgg()
    return plr:GetAttribute("CarryingEgg") == true
end

local function useTool(tool)
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not (hum and tool and tool.Parent) then return end
    if carryingEgg() then return end
    if plr:GetAttribute("OnTreadmill") == true or plr:GetAttribute("AdminTreadmillRunning") == true then return end
    if tool.Parent == plr.Character then hum:UnequipTools() else hum:EquipTool(tool) end
end

local barRow = Instance.new("Frame")
barRow.Name = "Hotbar"
barRow.BackgroundTransparency = 1
barRow.AnchorPoint = Vector2.new(0.5, 1)
barRow.Position = UDim2.new(0.5, 0, 1, -8)
barRow.AutomaticSize = Enum.AutomaticSize.X
barRow.ZIndex = 4
barRow.Parent = bagGui

task.spawn(function()
    local function syncBar()
        local carrying = plr:GetAttribute("CarryingEgg") == true
        barRow.Visible = not carrying
    end
    plr:GetAttributeChangedSignal("CarryingEgg"):Connect(syncBar)
    syncBar()
end)

local barLayout = Instance.new("UIListLayout")
barLayout.FillDirection = Enum.FillDirection.Horizontal
barLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
barLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
barLayout.SortOrder = Enum.SortOrder.LayoutOrder
barLayout.Padding = UDim.new(0, SLOT_GAP)
barLayout.Parent = barRow

local suppressClick = setmetatable({}, { __mode = "k" })
local pinned = setmetatable({}, { __mode = "k" })
local drag = nil
local GuiService = game:GetService("GuiService")
local slotByInstance = {}
local cardByInstance = setmetatable({}, { __mode = "k" })

local hotSlots = {}
for i = 1, SLOTS do
    local slot = Instance.new("TextButton")
    slot.Name = "Slot" .. i
    slot.AutoButtonColor = false
    slot.Text = ""
    slot.BackgroundColor3 = SLOT_BG
    slot.BackgroundTransparency = 0.25
    slot.BorderSizePixel = 0
    slot.LayoutOrder = i
    slot.ZIndex = 4
    slot.Visible = false
    slot.Parent = barRow
    corner(slot, 6)
    local st = edge(slot, EDGE, 3)

    local view = Instance.new("ViewportFrame")
    view.Name = "Icon"
    view.BackgroundTransparency = 1
    view.AnchorPoint = Vector2.new(0.5, 0.5)
    view.Position = UDim2.fromScale(0.5, 0.5)
    view.Size = UDim2.fromScale(0.84, 0.84)
    view.ZIndex = 5
    view.Parent = slot

    local num, numC = shout(slot, UDim2.fromScale(0.3, 0.24), UDim2.fromScale(0.08, 0.05),
        tostring(i == 10 and 0 or i), 13, Color3.fromRGB(198, 206, 190),
        Enum.TextXAlignment.Left, 7)
    local cnt, cntC = shout(slot, UDim2.fromScale(0.9, 0.44), UDim2.fromScale(0.05, 0.28),
        "", 22, INK, Enum.TextXAlignment.Center, 7)
    cnt.TextYAlignment = Enum.TextYAlignment.Center

    local rec = { slot = slot, view = view, count = cnt, stroke = st, tool = nil, shown = nil,
                  num = num, key = tostring(i == 10 and 0 or i), numC = numC, cntC = cntC }
    slot.MouseButton1Click:Connect(function()
        if suppressClick[slot] then suppressClick[slot] = nil return end
        if rec.tool then useTool(rec.tool) end
    end)

    slot.MouseButton2Click:Connect(function()
        if rec.tool then setStored(rec.tool, true) end
    end)
    hotSlots[i] = rec
    slotByInstance[slot] = i
end

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.BackgroundColor3 = PANEL_BG
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.AnchorPoint = Vector2.new(0.5, 1)
panel.Visible = false
panel.ZIndex = 8
panel.Parent = bagGui
corner(panel, 10)
edge(panel, Color3.fromRGB(96, 110, 84), 2, true)

local title, titleC = shout(panel, UDim2.fromScale(0.45, 0.10), UDim2.fromScale(0.025, 0.03),
    "All Items", 24, INK, Enum.TextXAlignment.Left, 10)

local search = Instance.new("TextBox")
search.Name = "Search"

search.BackgroundColor3 = Color3.fromRGB(30, 36, 26)
search.BackgroundTransparency = 0
search.BorderSizePixel = 0
search.AnchorPoint = Vector2.new(1, 0)
search.Position = UDim2.new(1, -10, 0, 8)
search.Font = Enum.Font.FredokaOne
search.TextScaled = true
search.Text = ""
search.PlaceholderText = "Search"
search.PlaceholderColor3 = Color3.fromRGB(186, 200, 168)
search.TextColor3 = INK
search.ClearTextOnFocus = false
search.ZIndex = 10
search.Parent = panel
corner(search, 6)
edge(search, Color3.fromRGB(150, 166, 130), 2, true)
local searchC = Instance.new("UITextSizeConstraint")
searchC.MinTextSize = 8; searchC.MaxTextSize = 16; searchC.Parent = search

local grid = Instance.new("ScrollingFrame")
grid.Name = "Grid"
grid.BackgroundTransparency = 1
grid.BorderSizePixel = 0
grid.CanvasSize = UDim2.new()
grid.AutomaticCanvasSize = Enum.AutomaticSize.Y
grid.ScrollBarThickness = 5
grid.ScrollBarImageColor3 = Color3.fromRGB(140, 154, 124)
grid.ZIndex = 9
grid.Parent = panel

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellPadding = UDim2.fromOffset(CARD_GAP, CARD_GAP)
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = grid

local empty = shout(panel, UDim2.fromScale(0.9, 0.12), UDim2.fromScale(0.05, 0.44), "", 18,
    Color3.fromRGB(176, 188, 164), Enum.TextXAlignment.Center, 10)

local rail = Instance.new("Frame")
rail.Name = "Tabs"
rail.BackgroundTransparency = 1
rail.AnchorPoint = Vector2.new(1, 0)
rail.Position = UDim2.new(0, -6, 0, 0)
rail.ZIndex = 9
rail.Parent = panel

local railLayout = Instance.new("UIListLayout")
railLayout.FillDirection = Enum.FillDirection.Vertical
railLayout.SortOrder = Enum.SortOrder.LayoutOrder
railLayout.Padding = UDim.new(0, 6)
railLayout.Parent = rail

local activeTab = nil
local tabButtons = {}
local renderPanel

local TAB_ICON = {
    Pets = "rbxassetid://107687993847196",
    Eggs = "rbxassetid://103180943014941",
}

for i, name in ipairs({ "Pets", "Eggs" }) do
    local b = Instance.new("TextButton")
    b.Name = name
    b.AutoButtonColor = false
    b.Text = ""
    b.BackgroundColor3 = SLOT_BG
    b.BackgroundTransparency = 0.12
    b.BorderSizePixel = 0
    b.LayoutOrder = i
    b.ZIndex = 9
    b.Parent = rail
    corner(b, 8)
    local st = edge(b, EDGE, 2)
    local _, lc = shout(b, UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0.05), name, 14, INK, nil, 11)

    local ic = Instance.new("ImageLabel")
    ic.Name = "Icon"
    ic.BackgroundTransparency = 1
    ic.Image = TAB_ICON[name]
    ic.ScaleType = Enum.ScaleType.Fit
    ic.AnchorPoint = Vector2.new(0.5, 0)
    ic.Position = UDim2.fromScale(0.5, 0.32)
    ic.Size = UDim2.fromScale(0.68, 0.62)
    ic.ZIndex = 11
    ic.Parent = b

    b.MouseButton1Click:Connect(function()
        if activeTab == name then activeTab = nil else activeTab = name end
        renderPanel()
    end)
    tabButtons[name] = { button = b, stroke = st, labelC = lc }
end

local DRAG_START = 8
local ghost = Instance.new("Frame")
ghost.Name = "DragGhost"
ghost.BackgroundColor3 = SLOT_BG
ghost.BackgroundTransparency = 0.2
ghost.BorderSizePixel = 0
ghost.Visible = false
ghost.ZIndex = 30
ghost.Parent = bagGui
corner(ghost, 6)
edge(ghost, PICKED, 2, true)
local ghostView = Instance.new("ViewportFrame")
ghostView.Name = "Icon"
ghostView.BackgroundTransparency = 1
ghostView.AnchorPoint = Vector2.new(0.5, 0.5)
ghostView.Position = UDim2.fromScale(0.5, 0.5)
ghostView.Size = UDim2.fromScale(0.84, 0.84)
ghostView.ZIndex = 31
ghostView.Parent = ghost

local function inside(obj, pos)
    if not obj.Visible then return false end
    local p, s = obj.AbsolutePosition, obj.AbsoluteSize
    return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
end

local function slotAt(pos)
    for i, e in ipairs(hotSlots) do
        if inside(e.slot, pos) then return i end
    end
end

local function paintTargets(hover)
    for i, e in ipairs(hotSlots) do
        local equipped = e.tool ~= nil and e.tool.Parent == plr.Character
        e.stroke.Transparency = (i == hover or equipped) and 0 or 1
    end
end

local function beginDrag(tool, from, fromSlot, button, input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
    suppressClick[button] = nil
    drag = { tool = tool, from = from, fromSlot = fromSlot, button = button,
             start = Vector2.new(input.Position.X, input.Position.Y), active = false }
end

local function moveDrag(pos)
    if not drag then return end
    if not drag.active then
        if (pos - drag.start).Magnitude < DRAG_START or carryingEgg() or not drag.tool.Parent then return end
        drag.active = true
        suppressClick[drag.button] = true
        grid.ScrollingEnabled = false
        local side = hotSlots[1].slot.AbsoluteSize.X
        if side <= 0 then side = 60 end
        ghost.Size = UDim2.fromOffset(side, side)
        fillIcon(ghostView, drag.tool)
        ghost.Visible = true
        markDirty()
    end
    ghost.Position = UDim2.fromOffset(pos.X - ghost.AbsoluteSize.X / 2, pos.Y - ghost.AbsoluteSize.Y / 2)
    paintTargets(slotAt(pos))
end

local function placeInSlot(tool, from, fromSlot, target)
    local other = hotSlots[target].tool
    if other and other ~= tool then
        if from == "bar" then
            pinned[other] = fromSlot
        else
            pinned[other] = nil
            if not other:GetAttribute("Gear") then setStored(other, true) end
        end
    end
    pinned[tool] = target
    if from == "card" and isStored(tool) then setStored(tool, false) end
end
local function placeInBag(tool, from)
    if from == "bar" and not tool:GetAttribute("Gear") then
        pinned[tool] = nil
        setStored(tool, true)
    end
end
local function endDrag(pos)
    local d = drag
    drag = nil
    if not (d and d.active) then return end
    ghost.Visible = false
    iconToken[ghostView] = (iconToken[ghostView] or 0) + 1
    ghostView:ClearAllChildren()
    grid.ScrollingEnabled = true
    local tool = d.tool
    if tool.Parent then
        local target = slotAt(pos)
        if target then
            placeInSlot(tool, d.from, d.fromSlot, target)
        elseif d.from == "bar" and panel.Visible and inside(panel, pos) then
            placeInBag(tool, d.from)
        end
    end
    markDirty()
end

local gamepadHeld, gamepadFrom, gamepadFromSlot = nil, nil, nil
local holdHint = shout(bagGui, UDim2.fromOffset(260, 26), UDim2.new(0.5, -130, 1, -148), "Y: place   B: cancel", 20, INK, Enum.TextXAlignment.Center, 8)
holdHint.Name = "HoldHint"
holdHint.Visible = false
local function clearGamepadHold()
    gamepadHeld, gamepadFrom, gamepadFromSlot = nil, nil, nil
    holdHint.Visible = false
    ghost.Visible = false
    iconToken[ghostView] = (iconToken[ghostView] or 0) + 1
    ghostView:ClearAllChildren()
end
local function pickUpFromSelection()
    local selected = GuiService.SelectedObject
    if not selected or carryingEgg() then return end
    local i = slotByInstance[selected]
    if i and hotSlots[i].tool then
        gamepadHeld, gamepadFrom, gamepadFromSlot = hotSlots[i].tool, "bar", i
    else
        local rec = cardByInstance[selected]
        if rec and rec.tool then gamepadHeld, gamepadFrom, gamepadFromSlot = rec.tool, "card", nil end
    end
    if gamepadHeld then
        local side = hotSlots[1].slot.AbsoluteSize.X
        if side <= 0 then side = 60 end
        side = math.floor(side * 0.8)
        ghost.Size = UDim2.fromOffset(side, side)
        fillIcon(ghostView, gamepadHeld)
        ghost.Visible = true
        holdHint.Visible = true
    end
end
local function placeAtSelection()
    local tool, from, fromSlot = gamepadHeld, gamepadFrom, gamepadFromSlot
    clearGamepadHold()
    if not (tool and tool.Parent) then return end
    local selected = GuiService.SelectedObject
    local target = selected and slotByInstance[selected]
    if target then
        placeInSlot(tool, from, fromSlot, target)
    elseif selected and cardByInstance[selected] and from == "bar" then
        placeInBag(tool, from)
    end
    markDirty()
end
local function cycleSlot(step)
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or carryingEgg() then return end
    local filled = {}
    for i, e in ipairs(hotSlots) do
        if e.tool and e.tool.Parent then table.insert(filled, i) end
    end
    if #filled == 0 then return end
    local current = 0
    for k, i in ipairs(filled) do
        if hotSlots[i].tool.Parent == plr.Character then current = k break end
    end
    local nextK = current == 0 and (step > 0 and 1 or #filled) or (current - 1 + step) % #filled + 1
    hum:EquipTool(hotSlots[filled[nextK]].tool)
end
UIS.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
    if input.KeyCode == Enum.KeyCode.ButtonY then
        if gamepadHeld then placeAtSelection() else pickUpFromSelection() end
    elseif input.KeyCode == Enum.KeyCode.ButtonB and gamepadHeld then
        clearGamepadHold()
    elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
        cycleSlot(1)
    elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
        cycleSlot(-1)
    end
end)
RunSvc.RenderStepped:Connect(function()
    if not gamepadHeld then return end
    local obj = GuiService.SelectedObject
    if not obj then clearGamepadHold() return end
    local x = obj.AbsolutePosition.X + obj.AbsoluteSize.X / 2
    ghost.Position = UDim2.fromOffset(x - ghost.AbsoluteSize.X / 2, obj.AbsolutePosition.Y - ghost.AbsoluteSize.Y * 0.8)
end)
local function slotKeys()
    local onPad = UIS:GetLastInputType().Name:find("Gamepad") ~= nil
    for _, e in ipairs(hotSlots) do e.num.Text = onPad and "Y" or e.key end
end
UIS.LastInputTypeChanged:Connect(slotKeys)
slotKeys()

for i, e in ipairs(hotSlots) do
    e.slot.InputBegan:Connect(function(input)
        if e.tool then beginDrag(e.tool, "bar", i, e.slot, input) end
    end)
end
UIS.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        moveDrag(Vector2.new(input.Position.X, input.Position.Y))
    end
end)
UIS.InputEnded:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        endDrag(Vector2.new(input.Position.X, input.Position.Y))
    end