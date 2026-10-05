local Players = game:GetService("Players")

local Cfg = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))

local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens")
local mills = map:WaitForChild("Treadmills")

local RUN_ANIM = "rbxassetid://913376220"
local RUN_REFERENCE = 20

local UpgradeCfg = require(game:GetService("ReplicatedStorage"):WaitForChild("UpgradeConfig"))
local AWARD_BASE = UpgradeCfg.MILL.awardBase or 4
local AWARD_EVERY = UpgradeCfg.MILL.awardEvery or 0.5
local AWARD_GROWTH = UpgradeCfg.MILL.awardGrowth or 2

local TICK = 0.1

local ENTRY_ACROSS = 0.95
local ENTRY_ALONG = 0.95
local ENTRY_BELOW = 1.0
local ENTRY_ABOVE = 5

local EXIT_COOLDOWN = 1.0

local BELT_BELOW = 5
local BELT_HEIGHT = 10

local STAY_RADIUS = 1.0
local STAY_BELOW = 1.5
local STAY_ABOVE = 6

local ENTRY_GRACE = 0.45

local plots = {}

local function buildArrows(mill)
    local oldPad = mill:FindFirstChild("ArrowPad")
    if oldPad then oldPad:Destroy() end
    local oldBelt = mill:FindFirstChild("belt", true)
    local oldEmitter = oldBelt and oldBelt:FindFirstChild("RunArrows")
    if oldEmitter then oldEmitter:Destroy() end
    return nil
end

for _, pen in ipairs(pens:GetChildren()) do
    local mill = mills:FindFirstChild("Mill_" .. pen.Name)
    if mill then
        local sign = pen:FindFirstChild("Sign")
        local cf = pen:GetBoundingBox()
        plots[#plots + 1] = {
            name = pen.Name,
            pen = pen,
            mill = mill,
            penSign = sign,
            millSign = mill:FindFirstChild("Sign"),
            centre = Vector3.new(cf.Position.X, 0, cf.Position.Z),
            arrows = buildArrows(mill),
            owner = nil,
        }
    end
end
table.sort(plots, function(a, b) return a.name < b.name end)

for index, plot in ipairs(plots) do
    plot.index = index
    plot.pen:SetAttribute("PlotIndex", index)
    plot.pen:SetAttribute("OwnerUserId", 0)
    plot.pen:SetAttribute("OwnerName", "")
    plot.pen:SetAttribute("PlotLevel", 1)
    plot.mill:SetAttribute("PlotIndex", index)
    plot.mill:SetAttribute("OwnerUserId", 0)
    plot.mill:SetAttribute("MillLevel", 1)
    plot.mill:SetAttribute("Running", false)
end

print(("[Plots] %d plots ready"):format(#plots))

local byPlayer = {}

local function release(plr)
    local plot = byPlayer[plr]
    if not plot then return end
    byPlayer[plr] = nil
    plot.owner = nil
    plot.pen:SetAttribute("OwnerUserId", 0)
    plot.pen:SetAttribute("OwnerName", "")
    plot.mill:SetAttribute("OwnerUserId", 0)
    plot.mill:SetAttribute("Running", false)
    plot.pen:SetAttribute("PlotLevel", 1)
    plot.mill:SetAttribute("MillLevel", 1)
end

local function assign(plr)
    for _, plot in ipairs(plots) do
        if not plot.owner then
            plot.owner = plr
            byPlayer[plr] = plot
            plot.pen:SetAttribute("OwnerUserId", plr.UserId)
            plot.pen:SetAttribute("OwnerName", plr.DisplayName)
            plot.mill:SetAttribute("OwnerUserId", plr.UserId)
            plr:SetAttribute("PlotIndex", plot.index)
            return plot
        end
    end
    return nil
end

local function noPlot(plr)
    local ok = pcall(function()
        game:GetService("TeleportService"):TeleportAsync(game.PlaceId, { plr })
    end)
    if not ok then
        plr:Kick("This server is full (all plots are taken). Please rejoin to get another server.")
    end
end

game:GetService("TeleportService").TeleportInitFailed:Connect(function(plr)
    if plr.Parent and not byPlayer[plr] then
        plr:Kick("This server is full (all plots are taken). Please rejoin to get another server.")
    end
end)

Players.PlayerAdded:Connect(function(plr)
    if not assign(plr) then
        noPlot(plr)
    end
end)

Players.PlayerRemoving:Connect(release)

for _, plr in ipairs(Players:GetPlayers()) do
    if not byPlayer[plr] then
        if not assign(plr) then
            noPlot(plr)
        end
    end
end

local function rootOf(plr)
    local ch = plr.Character
    return ch and ch:FindFirstChild("HumanoidRootPart") or nil
end

local beltOf = {}
for _, plot in ipairs(plots) do
    local belt = plot.mill:FindFirstChild("belt", true)
    local sign = plot.mill:FindFirstChild("Sign")

    local pivot = plot.mill:GetPivot()
    local lo = Vector3.new(1e9, 1e9, 1e9)
    local hi = Vector3.new(-1e9, -1e9, -1e9)
    for _, p in ipairs(plot.mill:GetDescendants()) do
        if p:IsA("BasePart") and not (sign and p:IsDescendantOf(sign)) and p.Name ~= "ArrowPad" then
            local rel = pivot:PointToObjectSpace(p.Position)
            local half = p.Size / 2
            lo = Vector3.new(math.min(lo.X, rel.X - half.X), math.min(lo.Y, rel.Y - half.Y), math.min(lo.Z, rel.Z - half.Z))
            hi = Vector3.new(math.max(hi.X, rel.X + half.X), math.max(hi.Y, rel.Y + half.Y), math.max(hi.Z, rel.Z + half.Z))
        end
    end
    local mid = (lo + hi) / 2

    beltOf[plot.index] = {
        cf = pivot * CFrame.new(mid.X, belt and pivot:PointToObjectSpace(belt.Position).Y or mid.Y, mid.Z),
        size = hi - lo,

        beltCf = belt and belt.CFrame or nil,
        beltSize = belt and belt.Size or nil,
    }
end

local function onEntryPad(root, belt)
    if not belt.beltCf then return false end
    local p = belt.beltCf:PointToObjectSpace(root.Position)
    return math.abs(p.X) <= belt.beltSize.X / 2 * ENTRY_ACROSS
       and math.abs(p.Z) <= belt.beltSize.Z / 2 * ENTRY_ALONG
       and p.Y > -ENTRY_BELOW and p.Y <= ENTRY_ABOVE
end

local function onBeltAny(root, belt)
    if not belt.beltCf then return false end
    local p = belt.beltCf:PointToObjectSpace(root.Position)
    return math.abs(p.X) <= belt.beltSize.X / 2 + 1
       and math.abs(p.Z) <= belt.beltSize.Z / 2 + 1
       and p.Y > -BELT_BELOW and p.Y <= BELT_HEIGHT
end

local function atCentre(root, belt)
    if not belt.beltCf then return false end
    local p = belt.beltCf:PointToObjectSpace(root.Position)
    return math.abs(p.X) <= STAY_RADIUS
       and math.abs(p.Z) <= STAY_RADIUS
       and p.Y > -STAY_BELOW and p.Y <= STAY_ABOVE
end

local function beltState(root, belt, wasRunning, armed, since, offAt)
    if wasRunning then

        if since and os.clock() - since < ENTRY_GRACE then
            return onBeltAny(root, belt), true
        end

        return atCentre(root, belt), true
    end

    local cooled = (not offAt) or (os.clock() - offAt >= EXIT_COOLDOWN)

    if not armed then
        armed = (not onBeltAny(root, belt)) or cooled
        if not armed then return false, false end
    end

    if not cooled then return false, true end

    return onEntryPad(root, belt), true
end

local tracks = {}

local function rateFor(plr)
    local walk = Cfg.walkForSpeed(plr:GetAttribute("Speed") or Cfg.SPEED_START)
    return math.clamp(walk / RUN_REFERENCE, 0.7, 3.5)
end

function pace(plot)
    local plr = plot.owner
    if not plr then return end
    local rate = rateFor(plr)
    local entry = tracks[plr]
    if entry and entry.track.IsPlaying then entry.track:AdjustSpeed(rate) end

    plot.mill:SetAttribute("BeltRate", rate)
end

local function standCF(plot, root, hum)
    local belt = plot.mill:FindFirstChild("belt", true)
    if not (root and hum and belt) then return nil end
    local pivot = plot.mill:GetPivot()
    local face = Vector3.new(-pivot.LookVector.X, 0, -pivot.LookVector.Z)
    face = (face.Magnitude > 0.01) and face.Unit or Vector3.new(0, 0, 1)
    local stand = Vector3.new(belt.Position.X,
        belt.Position.Y + belt.Size.Y / 2 + (hum.HipHeight or 2) + root.Size.Y / 2,
        belt.Position.Z)
    return CFrame.lookAt(stand, stand + face)
end

local PIN_SLACK = 0.25

function pin(plot, root, hum, force)
    local cf = standCF(plot, root, hum)
    if not cf then return end
    if force or (root.Position - cf.Position).Magnitude > PIN_SLACK then
        root.CFrame = cf
        root.AssemblyLinearVelocity = Vector3.zero
    end
end

function setRunning(plot, running)
    local plr = plot.owner

    if not running then plot.mill:SetAttribute("BeltRate", 1) end
    if not plr then return end
    plr:SetAttribute("OnTreadmill", running)

    if not running then
        local entry = tracks[plr]
        if entry then entry.track:Stop(0.2) end
        return
    end

    local ch = plr.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return end

    local root = ch:FindFirstChild("HumanoidRootPart")
    pin(plot, root, hum, true)

    local entry = tracks[plr]
    if not (entry and entry.animator == animator) then
        local anim = Instance.new("Animation")
        anim.AnimationId = RUN_ANIM
        local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
        if not (ok and track) then return end
        track.Priority = Enum.AnimationPriority.Action
        track.Looped = true
        entry = { animator = animator, track = track }
        tracks[plr] = entry
    end
    if not entry.track.IsPlaying then
        entry.track:Play(0.15, 1, rateFor(plr))
    end
end

Players.PlayerRemoving:Connect(function(plr) tracks[plr] = nil end)

task.spawn(function()
    while true do
        task.wait(TICK)
        for _, plot in ipairs(plots) do
            local running = false
            if plot.owner then
                local root = rootOf(plot.owner)
                if root then

                    local was = plot.mill:GetAttribute("Running")
                    local now, armed = beltState(root, beltOf[plot.index], was,
                        plot.armed ~= false, plot.runSince, plot.offAt)
                    plot.armed = armed

                    if now and was then
                        local hum = plot.owner.Character
                            and plot.owner.Character:FindFirstChildOfClass("Humanoid")
                        local moving = hum and hum.MoveDirection.Magnitude > 0.1

                        local settled = plot.runSince
                            and (os.clock() - plot.runSince) >= ENTRY_GRACE
                        if not moving or settled then plot.moveArmed = true end
                        if plot.moveArmed and moving then now = false end

                        if now and hum then pin(plot, root, hum, false) end
                    end
                    if now then
                        running = true
                        plot.owed = (plot.owed or 0) + TICK
                        if plot.owed >= AWARD_EVERY then
                            plot.owed = plot.owed - AWARD_EVERY
                            local level = plot.mill:GetAttribute("MillLevel") or 1
                            local trail = tonumber(plot.owner:GetAttribute("TrailMult")) or 1
                            local award = AWARD_BASE * AWARD_GROWTH ^ (level - 1) * trail * (_G.SpeedMult and _G.SpeedMult(plot.owner) or 1) * (_G.GlobalBoost and _G.GlobalBoost.value("speed") or 1) * (_G.RebirthMult and _G.RebirthMult(plot.owner) or 1)
                            local speed = plot.owner:GetAttribute("Speed") or 1
                            plot.owner:SetAttribute("Speed", math.min(speed + award, Cfg.SPEED_MAX))
                        end
                    end
                end
            end
            if plot.mill:GetAttribute("Running") ~= running then
                plot.mill:SetAttribute("Running", running)
                plot.runSince = running and os.clock() or nil

                plot.moveArmed = false
                setRunning(plot, running)

                if not running then
                    plot.owed = 0
                    plot.armed = false
                    plot.offAt = os.clock()
                end
            end

            if running then pace(plot) end
        end
    end
end)

_G.Plots = {
    of = function(plr) return byPlayer[plr] end,
    list = plots,
    setPlotLevel = function(plr, level)
        local plot = byPlayer[plr]
        if plot then plot.pen:SetAttribute("PlotLevel", math.max(1, math.floor(level))) end
    end,
    setMillLevel = function(plr, level)
        local plot = byPlayer[plr]
        if plot then plot.mill:SetAttribute("MillLevel", math.max(1, math.floor(level))) end
    end,
}