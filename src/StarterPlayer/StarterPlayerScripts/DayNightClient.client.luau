
local __LocalizationService = game:GetService("LocalizationService")
local __locale = string.lower(__LocalizationService.RobloxLocaleId or __LocalizationService.SystemLocaleId or "en-us")
local __isFrench = string.sub(__locale, 1, 2) == "fr"
local function __L(en, fr) return __isFrench and fr or en end
local __ZONE_FR = {
    ["Forest"]="Forêt", ["Lake"]="Lac", ["Desert"]="Désert", ["Jungle"]="Jungle",
    ["Snow"]="Neige", ["Volcano"]="Volcan", ["Abyss Ocean"]="Océan abyssal",
    ["Prehistoric"]="Préhistoire", ["Cosmic"]="Cosmique", ["Cherry Blossom"]="Fleurs de cerisier",
    ["Titan Temple"]="Temple des Titans", ["Monster Lair"]="Repaire des monstres",
}
local function __zoneName(name) return __isFrench and (__ZONE_FR[name] or name) or name end

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")

local Cycle = require(RS:WaitForChild("DayNightConfig"))
local Cfg = require(RS:WaitForChild("EggConfig"))

local plr = Players.LocalPlayer
local remote = RS:WaitForChild("Remotes"):WaitForChild("DayNight")

local INK = Color3.fromRGB(12, 14, 22)
local LEGEND_HEX = "#F8C45C"

local gui = Instance.new("ScreenGui")
gui.Name = "DayNightCountdown"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 55
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = plr:WaitForChild("PlayerGui")

local WALL_PPS = 4
local wallGui = Instance.new("SurfaceGui")
wallGui.Name = "GateCountdown"
wallGui.Face = Enum.NormalId.Back
wallGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
wallGui.PixelsPerStud = WALL_PPS
wallGui.LightInfluence = 0
wallGui.ZOffset = 2
wallGui.ResetOnSpawn = false
wallGui.Parent = plr:WaitForChild("PlayerGui")
local map = workspace:WaitForChild("GameWorld")

local function big(parent, props)
    local t = Instance.new("TextLabel")
    t.Name = props.name
    t.BackgroundTransparency = 1
    t.AnchorPoint = props.anchor or Vector2.new(0.5, 0.5)
    t.Position = props.position
    t.Size = props.size
    t.Font = Enum.Font.FredokaOne
    t.TextSize = props.textSize
    t.TextColor3 = Color3.new(1, 1, 1)
    t.TextXAlignment = props.align or Enum.TextXAlignment.Center
    t.Text = props.text or ""
    t.Visible = false
    t.Parent = parent
    local s = Instance.new("UIStroke")
    s.Color = INK
    s.Thickness = props.strokeW or 6
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Parent = t
    return t
end

local row = Instance.new("Frame")
row.Name = "MoonRow"
row.BackgroundTransparency = 1
row.AnchorPoint = Vector2.new(0.5, 0.5)
row.Position = UDim2.fromScale(0.5, 0.42)
row.Size = UDim2.fromOffset(300, 130)
row.Visible = false
row.Parent = wallGui
local rowScale = Instance.new("UIScale")
rowScale.Parent = row

local moon = Instance.new("ImageLabel")
moon.Name = "Moon"
moon.BackgroundTransparency = 1
moon.Image = Cycle.ICON.night
moon.ScaleType = Enum.ScaleType.Fit
moon.AnchorPoint = Vector2.new(0, 0.5)
moon.Position = UDim2.new(0, 0, 0.5, 0)
moon.Size = UDim2.fromOffset(130, 130)
moon.Parent = row

local secs = big(row, {
    name = "Seconds", anchor = Vector2.new(0, 0.5), position = UDim2.new(0, 140, 0.5, 0),
    size = UDim2.fromOffset(170, 130), textSize = 100, align = Enum.TextXAlignment.Left, strokeW = 6,
})
secs.Visible = true

local resetTitle = big(wallGui, {
    name = "ResetTitle", position = UDim2.fromScale(0.5, 0.16), size = UDim2.fromOffset(640, 56),
    text = "ALL EGGS RESET!", textSize = 48, strokeW = 4,
})
local digit = big(wallGui, {
    name = "Digit", position = UDim2.fromScale(0.5, 0.5), size = UDim2.fromOffset(200, 120),
    textSize = 100, strokeW = 6,
})
local digitScale = Instance.new("UIScale")
digitScale.Parent = digit

local function pop(scaleObj, from)
    scaleObj.Scale = from
    TweenService:Create(scaleObj, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        { Scale = 1 }):Play()
end

local shownMode, shownValue = nil, nil

RunService.Heartbeat:Connect(function()
    local gate = map:FindFirstChild("NightGate")
    local wall = gate and gate:FindFirstChild("Gate")
    if wallGui.Adornee ~= wall then wallGui.Adornee = wall end

    local phase = workspace:GetAttribute("CyclePhase")
    local ends = tonumber(workspace:GetAttribute("CycleEndsAt"))
    local mode, value = nil, nil
    if phase == "night" and ends then
        local left = ends - workspace:GetServerTimeNow()
        if left > 0 and left <= Cycle.COUNTDOWN then
            value = math.ceil(left)
            mode = (value > Cycle.RESET_AT) and "moon" or "digit"
        end
    end
    if mode == shownMode and value == shownValue then return end

    local newMode = mode ~= shownMode
    shownMode, shownValue = mode, value
    row.Visible = mode == "moon"
    resetTitle.Visible = mode == "digit"
    digit.Visible = mode == "digit"
    if mode == "moon" then
        secs.Text = value .. "s"
        if newMode then pop(rowScale, 0.6) end
    elseif mode == "digit" then
        digit.Text = tostring(value)
        pop(digitScale, 1.5)
    end
end)

local FEED_MAX = 5
local FEED_HOLD = 5

local feed = Instance.new("Frame")
feed.Name = "LegendFeed"
feed.BackgroundTransparency = 1
feed.AnchorPoint = Vector2.new(0.5, 0)
feed.Position = UDim2.fromScale(0.5, 0.13)
feed.Size = UDim2.fromOffset(900, 320)
feed.Parent = gui
do
    local list = Instance.new("UIListLayout")
    list.FillDirection = Enum.FillDirection.Vertical
    list.HorizontalAlignment = Enum.HorizontalAlignment.Center
    list.SortOrder = Enum.SortOrder.LayoutOrder
    list.Padding = UDim.new(0, 6)
    list.Parent = feed
end

local LEGEND_FROM = Color3.fromRGB(255, 236, 110)
local LEGEND_TO = Color3.fromRGB(255, 132, 28)
local function hexFade(text, from, to, bold)
    local chars = {}
    for _, code in utf8.codes(text) do chars[#chars + 1] = utf8.char(code) end
    local letters = 0
    for _, ch in ipairs(chars) do if ch ~= " " then letters += 1 end end
    local out, i = {}, 0
    for _, ch in ipairs(chars) do
        if ch == " " then
            out[#out + 1] = " "
        else
            local t = letters > 1 and i / (letters - 1) or 0
            i += 1
            out[#out + 1] = ('<font color="#%s">%s</font>'):format(from:Lerp(to, t):ToHex(), ch)
        end
    end
    local s = table.concat(out)
    return bold and ("<b>" .. s .. "</b>") or s
end

local function zoneFade(zone, name, bold)
    local c = Cfg.COLORS and Cfg.COLORS[zone]
    if typeof(c) ~= "Color3" then c = Color3.new(1, 1, 1) end
    local h, s, v = c:ToHSV()
    local light = Color3.fromHSV(h, s * 0.55, math.min(1, v * 1.1 + 0.15))
    local deep = Color3.fromHSV((h + 0.04) % 1, math.min(1, s * 1.1 + 0.1), v * 0.9)
    return hexFade(name, light, deep, bold)
end

local function feedLine(richText, order)
    local t = Instance.new("TextLabel")
    t.Name = "Line"
    t.BackgroundTransparency = 1
    t.Size = UDim2.fromOffset(900, 48)
    t.Font = Enum.Font.FredokaOne
    t.TextSize = 40
    t.RichText = true
    t.TextColor3 = Color3.new(1, 1, 1)
    t.Text = richText
    t.LayoutOrder = order
    t.TextTransparency = 1
    t.Parent = feed
    local s = Instance.new("UIStroke")
    s.Color = INK
    s.Thickness = 4
    s.LineJoinMode = Enum.LineJoinMode.Round
    s.Transparency = 1
    s.Parent = t
    local sc = Instance.new("UIScale")
    sc.Scale = 0.6
    sc.Parent = t

    local FADE_IN = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local POP = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    local FADE_OUT = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    task.delay((order - 1) * 0.15, function()
        TweenService:Create(t, FADE_IN, { TextTransparency = 0 }):Play()
        TweenService:Create(s, FADE_IN, { Transparency = 0 }):Play()
        TweenService:Create(sc, POP, { Scale = 1 }):Play()
        task.wait(FEED_HOLD)
        TweenService:Create(t, FADE_OUT, { TextTransparency = 1 }):Play()
        TweenService:Create(s, FADE_OUT, { Transparency = 1 }):Play()
        task.wait(0.65)
        t:Destroy()
    end)
end

local function showLegendaries(zones)
    for _, c in ipairs(feed:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    zones = zones or {}
    for i, zone in ipairs(zones) do
        if i > FEED_MAX then
            feedLine(hexFade(("+%d more Legendary eggs!"):format(#zones - FEED_MAX), LEGEND_FROM, LEGEND_TO), i)
            break
        end
        local name = __zoneName(Cfg.NAMES[zone] or ("Zone " .. tostring(zone)))
        feedLine(hexFade(__L("LEGENDARY EGG", "ŒUF LÉGENDAIRE"), LEGEND_FROM, LEGEND_TO) .. __L(" in ", " dans ") .. zoneFade(zone, name) .. "!", i)
    end
end

local closedNote = big(gui, {
    name = "MapClosed", position = UDim2.fromScale(0.5, 0.62), size = UDim2.fromOffset(900, 70),
    text = "The map is closed at night!", textSize = 48,
})
local closedToken = 0

remote.OnClientEvent:Connect(function(action, data)
    if action == "mapClosed" then
        closedToken += 1
        local mine = closedToken
        closedNote.Visible = true
        task.delay(3, function()
            if closedToken == mine then closedNote.Visible = false end
        end)
        return
    end
    if action ~= "reset" or type(data) ~= "table" then return end
    showLegendaries(data.legendary)
    local channels = TextChatService:FindFirstChild("TextChannels")
    local general = channels and channels:FindFirstChild("RBXGeneral")
    if not general then return end
    for _, zone in ipairs(data.legendary or {}) do
        local name = __zoneName(Cfg.NAMES[zone] or ("Zone " .. tostring(zone)))
        local text = hexFade(__L("A Legendary egg spawned in", "Un œuf légendaire est apparu dans"), LEGEND_FROM, LEGEND_TO, true) .. " "
            .. zoneFade(zone, name, true) .. ('<font color="%s"><b>!</b></font>'):format(LEGEND_HEX)
        pcall(function() general:DisplaySystemMessage(text) end)
    end
end)