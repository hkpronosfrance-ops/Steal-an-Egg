local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local RS            = game:GetService("ReplicatedStorage")

local Cfg     = require(RS:WaitForChild("EggConfig"))
local BossAnim = require(RS:WaitForChild("BossAnim"))
local function releaseHeld(model)
    if not model then return end
    game:GetService("CollectionService"):RemoveTag(model, "BossHeldEgg")
    model:SetAttribute("HeldBy", nil)
    model:SetAttribute("HeldYaw", nil)
end
local Ragdoll  = require(ServerStorage:WaitForChild("Ragdoll"))
local Remote  = RS.Remotes:WaitForChild("Egg")

local map        = workspace:WaitForChild("GameWorld")
local spawnsRoot = map:WaitForChild("EggSpawns")
local assets     = ServerStorage:WaitForChild("EggAssets")
local AnimalEggs = require(script.Parent:WaitForChild("AnimalEggs"))

local rng = Random.new(os.clock() * 1e6 % 2^31)

local looseFolder = workspace:FindFirstChild("LooseEggs")
if looseFolder then looseFolder:Destroy() end
looseFolder = Instance.new("Folder"); looseFolder.Name = "LooseEggs"; looseFolder.Parent = workspace

local eggs     = {}
local carriers = {}
local bosses   = {}

local function inSafeZone(z) return z > Cfg.SAFE_Z end
local function rootOf(plr)
    local ch = plr.Character
    return ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
end

local function speedOf(plr)

    if plr:GetAttribute("SlowMode") or plr:GetAttribute("HoldingCaptureEgg") then return Cfg.SPEED_START end
    local base = plr:GetAttribute("Speed") or Cfg.SPEED_START

    return base
end

local function setSpeed(plr, mult)
    local _, hum = rootOf(plr)
    if hum then hum.WalkSpeed = Cfg.walkForSpeed(speedOf(plr)) * (mult or 1) end
end

local attachPrompt, takeEgg, attachToHands, detachFromHands

local carryGuard = {}

local function unequipAll(plr)
    local ch = plr.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if hum then hum:UnequipTools() end
end

local function setCarrying(plr, on)
    if not plr then return end
    plr:SetAttribute("CarryingEgg", on and true or false)

    local old = carryGuard[plr]
    if old then old:Disconnect() carryGuard[plr] = nil end
    if not on then return end

    unequipAll(plr)
    local ch = plr.Character
    if not ch then return end
    carryGuard[plr] = ch.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        if not carriers[plr] then return end

        task.defer(function()
            if carriers[plr] and child.Parent == ch then
                local bag = plr:FindFirstChildOfClass("Backpack")
                if bag then child.Parent = bag end
            end
        end)
    end)
end

Players.PlayerRemoving:Connect(function(plr)
    local c = carryGuard[plr]
    if c then c:Disconnect() carryGuard[plr] = nil end
end)

local eggSet = assets:FindFirstChild("Eggs")
local function eggTemplate(zone)
    return eggSet and (eggSet:FindFirstChild("Zone" .. zone) or eggSet:FindFirstChild("Default"))
end

local FLOAT_Y = 0.35

local function lowestY(model)
    local lo = math.huge
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            local cf, sz = d.CFrame, d.Size
            local ey = math.abs(cf.RightVector.Y)*sz.X/2
                     + math.abs(cf.UpVector.Y)*sz.Y/2
                     + math.abs(cf.LookVector.Y)*sz.Z/2
            lo = math.min(lo, cf.Position.Y - ey)
        end
    end
    return lo
end

local function standAt(model, x, y, z, yaw)
    model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw or 0, 0))
    local lo = lowestY(model)
    if lo < math.huge then
        model:PivotTo(model:GetPivot() + Vector3.new(0, y - lo, 0))
    end
end

local function pickSizeUpTo(maxIdx)
    local pool = {}
    for i = 1, math.min(maxIdx or #Cfg.SIZES, #Cfg.SIZES) do
        pool[i] = Cfg.SIZES[i]
    end
    if #pool == 0 then return Cfg.SIZES[1], 1 end
    local def, idx = Cfg.pickWeighted(pool, rng)
    return def, idx
end

local function fitNest(anchor, eggScale)
    local folder = map:FindFirstChild("EggNests")
    if not folder then return end
    local nest = folder:FindFirstChild(string.format("Nest_Z%d_%d",
        anchor:GetAttribute("Zone"), anchor:GetAttribute("Slot")))
    if not nest then return end
    local base = nest:GetAttribute("BaseScale")
    if not base then
        base = nest:GetScale()
        nest:SetAttribute("BaseScale", base)
    end
    nest:ScaleTo(base * Cfg.nestScaleFor(eggScale))
    standAt(nest, anchor.Position.X, 0, anchor.Position.Z,
        nest:GetAttribute("Yaw") or 0)
end

local function makeEgg(anchor, forceTier, forceSize)
    local zone = anchor:GetAttribute("Zone")

    local tier = forceTier or Cfg.rollTier(nil, _G.GlobalBoost and _G.GlobalBoost.value("eggluck") or 1)
    anchor:SetAttribute("Tier", tier)
    local sizeDef, sizeIdx
    if forceSize and Cfg.SIZES[forceSize] then
        sizeDef, sizeIdx = Cfg.SIZES[forceSize], forceSize
    else
        sizeDef, sizeIdx = pickSizeUpTo(anchor:GetAttribute("MaxSize"))
    end
    local tierDef = Cfg.TIERS[tier]

    local species = AnimalEggs.pick(zone, tier)
    local speciesTpl = AnimalEggs.template(species)
    local model = (speciesTpl or eggTemplate(zone)):Clone()
    model.Name = string.format("Egg_Z%d_%d", zone, anchor:GetAttribute("Slot"))
    model:ScaleTo(model:GetScale() * sizeDef.scale)

    local c = Cfg.eggColor(zone, tier)
    local accent = Color3.new(c.R * 0.68, c.G * 0.68, c.B * 0.68)
    local glow = Cfg.GLOW[tier] or Cfg.GLOW[1]
    local shellPart
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local isShell = p.Name:lower():match("^shell") ~= nil
            if isShell then shellPart = shellPart or p end
            if not speciesTpl then
                if isShell then
                    p.Color = c
                    p.Material = glow.shell and Enum.Material.Neon or Enum.Material.SmoothPlastic
                else
                    p.Color = accent

                    if glow.deco then
                        p.Color = c
                        p.Material = Enum.Material.Neon
                    else
                        p.Material = Enum.Material.SmoothPlastic
                    end
                end
            end
            p.Anchored = true
            p.CanCollide = false
            p.CastShadow = false
        end
    end

    if shellPart and glow.light > 0 and not speciesTpl then
        local lamp = Instance.new("PointLight")
        lamp.Name = "TierGlow"
        lamp.Color = c
        lamp.Brightness = glow.light
        lamp.Range = glow.range * math.clamp(sizeDef.scale, 0.6, 2.2)
        lamp.Shadows = false
        lamp.Parent = shellPart
    end
    model:SetAttribute("Zone", zone)
    model:SetAttribute("Tier", tier)
    model:SetAttribute("SizeIdx", sizeIdx)
    if species then model:SetAttribute("Species", species) end

    eggs[model] = {
        anchor = anchor, zone = zone, tier = tier, size = sizeIdx, species = species,
        value = Cfg.eggValue(zone, tier, sizeIdx), state = "anchor",
        bob = rng:NextNumber(0, math.pi*2), floatY = FLOAT_Y,
        yaw = rng:NextNumber(0, math.pi * 2),
        half = 0,
    }
    model.Parent = anchor
    fitNest(anchor, sizeDef.scale)
    standAt(model, anchor.Position.X, FLOAT_Y, anchor.Position.Z, eggs[model].yaw)
    do
        local mnx, mxx, lo, hi = math.huge, -math.huge, math.huge, -math.huge
        local mnz, mxz = math.huge, -math.huge
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                local c, sz = d.CFrame, d.Size
                local ex = math.abs(c.RightVector.X)*sz.X/2 + math.abs(c.UpVector.X)*sz.Y/2 + math.abs(c.LookVector.X)*sz.Z/2
                local ey = math.abs(c.RightVector.Y)*sz.X/2 + math.abs(c.UpVector.Y)*sz.Y/2 + math.abs(c.LookVector.Y)*sz.Z/2
                local ez = math.abs(c.RightVector.Z)*sz.X/2 + math.abs(c.UpVector.Z)*sz.Y/2 + math.abs(c.LookVector.Z)*sz.Z/2
                mnx = math.min(mnx, c.Position.X - ex); mxx = math.max(mxx, c.Position.X + ex)
                lo  = math.min(lo,  c.Position.Y - ey); hi  = math.max(hi,  c.Position.Y + ey)
                mnz = math.min(mnz, c.Position.Z - ez); mxz = math.max(mxz, c.Position.Z + ez)
            end
        end
        eggs[model].half = (mxx - mnx) / 2
        eggs[model].halfH = (hi - lo) / 2
        eggs[model].halfD = (mxz - mnz) / 2
    end
    attachPrompt(model)
    return model
end

local function detachPrompt(model)
    local pp = model and model.PrimaryPart
    local pr = pp and pp:FindFirstChildOfClass("ProximityPrompt")
    if pr then pr:Destroy() end
end

function takeEgg(plr, model)
    if carriers[plr] then
        Remote:FireClient(plr, "Msg", "You're already carrying an egg!")
        return false, "already carrying"
    end
    local ee = eggs[model]
    if not ee then return false, "unknown egg" end
    if ee.state ~= "anchor" and ee.state ~= "loose" then return false, "state: " .. ee.state end
    local _, hum = rootOf(plr)
    if not hum or hum.Health <= 0 or plr:GetAttribute("HoldingCaptureEgg") or plr:GetAttribute("Stunned")
        or not (_G.Profile and _G.Profile.get(plr)) or not model.PrimaryPart then
        return false, "cannot carry now"
    end
    detachPrompt(model)
    ee.state = "player"
    ee.carrier = plr
    local pickRoot = rootOf(plr)
    ee.pickT = os.clock()
    ee.pickPos = pickRoot and pickRoot.Position or model:GetPivot().Position
    carriers[plr] = model
    setCarrying(plr, true)
    model.Parent = looseFolder
    attachToHands(model, plr, ee)
    setSpeed(plr, Cfg.SIZES[ee.size].carry)
    Remote:FireClient(plr, "Pickup", {
        tier = Cfg.TIERS[ee.tier].name, size = Cfg.SIZES[ee.size].name,
        zone = ee.zone, value = ee.value, species = ee.species,
        speedMult = Cfg.SIZES[ee.size].carry,
    })
    return true
end

function attachPrompt(model)
    detachPrompt(model)
    local e = eggs[model]
    if not e then return end
    local pr = Instance.new("ProximityPrompt")
    pr.ActionText = (e.state == "loose") and "Pick up" or "Steal"
    pr.ObjectText = e.species and (e.species .. " Egg") or ""
    pr.HoldDuration = 0.45
    pr.MaxActivationDistance = 14 + (Cfg.SIZES[e.size].scale or 1) * 3
    pr.RequiresLineOfSight = false

    pr.Style = Enum.ProximityPromptStyle.Custom
    pr:SetAttribute("EggPrompt", true)
    game:GetService("CollectionService"):AddTag(pr, "StealPrompt")
    pr.Parent = model.PrimaryPart

    pr.Triggered:Connect(function(plr) takeEgg(plr, model) end)
end

local function setArmsCarrying(plr, on)
    if on then return end
    plr:SetAttribute("CarryCenter", nil)
    plr:SetAttribute("CarrySize", nil)
end

local CARRY_MIN_SCALE = 0.3
local CARRY_GRIP_GAP = 0.05

local function isArmJoint(j)
    return j ~= nil and (j:IsA("Motor6D") or j:IsA("AnimationConstraint"))
end

local function jointFrames(j)
    if j:IsA("Motor6D") then return j.C0, j.C1 end
    local a0, a1 = j.Attachment0, j.Attachment1
    return a0 and a0.CFrame or CFrame.identity, a1 and a1.CFrame or CFrame.identity
end

local function hugLayout(ch, torso, model)
    local upper = ch:FindFirstChild("RightUpperArm")
    local lower = ch:FindFirstChild("RightLowerArm")
    local hand = ch:FindFirstChild("RightHand")
    local sh = upper and upper:FindFirstChild("RightShoulder")
    local el = lower and lower:FindFirstChild("RightElbow")
    local wr = hand and hand:FindFirstChild("RightWrist")
    if not (isArmJoint(sh) and isArmJoint(el) and isArmJoint(wr)) then
        return nil
    end
    local s0, s1 = jointFrames(sh)
    local e0, e1 = jointFrames(el)
    local w0, w1 = jointFrames(wr)
    local S = s0.Position
    S = Vector3.new(math.abs(S.X), S.Y, S.Z)
    local reach = ((e0.Position - s1.Position).Magnitude
        + (w0.Position - e1.Position).Magnitude
        + w1.Position.Magnitude) * 0.95
    local boxCF, size = model:GetBoundingBox()
    local pivotToCenter = model:GetPivot():PointToObjectSpace(boxCF.Position)
    local half0 = size / 2
    local tz = torso.Size.Z / 2
    local handHalf = hand.Size.X / 2

    local best
    for step = 0, 14 do
        local scale = math.max(CARRY_MIN_SCALE, 1 - step * 0.05)
        local half = half0 * scale
        local yc = S.Y - 0.35 - half.Y * 0.2
        for _, sink in ipairs({ 0, 0.5, 1 }) do
            local zc = -(tz + half.Z + 0.05) + sink * (tz * 0.4 + half.Z * 0.3)
            local grip = Vector3.new(half.X * 0.94 + CARRY_GRIP_GAP + handHalf, yc - half.Y * 0.15, zc + half.Z * 0.35)
            local d = (grip - S).Magnitude
            if not best or d - reach < best.miss then
                best = { scale = scale, center = Vector3.new(0, yc, zc), pivotToCenter = pivotToCenter, miss = d - reach }
            end
            if d <= reach then return best end
        end
        if scale <= CARRY_MIN_SCALE then break end
    end
    return best
end

function attachToHands(model, plr, e)
    local ch = plr.Character
    local root = rootOf(plr)
    if not root or not ch then return false end
    local shell = model.PrimaryPart
    if not shell then return false end

    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("WeldConstraint") then d:Destroy() end
    end
    local base = model:GetAttribute("CarryBaseScale") or model:GetScale()
    if math.abs(model:GetScale() - base) > 1e-4 then model:ScaleTo(base) end

    local anchorPart = ch:FindFirstChild("UpperTorso") or root
    local layout = (anchorPart.Name == "UpperTorso") and hugLayout(ch, anchorPart, model) or nil
    if layout then
        model:SetAttribute("CarryBaseScale", base)
        if layout.scale < 0.999 then model:ScaleTo(base * layout.scale) end
        model:PivotTo(anchorPart.CFrame * CFrame.new(layout.center - layout.pivotToCenter * layout.scale))
        local placedCF = model:GetBoundingBox()
        local drift = layout.center - anchorPart.CFrame:PointToObjectSpace(placedCF.Position)
        model:PivotTo(model:GetPivot() + anchorPart.CFrame:VectorToWorldSpace(drift))
    else
        local halfH = e.halfH or 1.6
        local half  = e.half  or 1.3
        local holdY = math.max(0.6, (0.3 + halfH) - anchorPart.Position.Y)
        local halfD = e.halfD or half
        local holdZ = -(anchorPart.Size.Z / 2 + halfD + 0.35)
        model:PivotTo(anchorPart.CFrame * CFrame.new(0, holdY, holdZ))

        local hum = ch:FindFirstChildOfClass("Humanoid")
        local groundY = root.Position.Y - root.Size.Y / 2 - (hum and hum.HipHeight or 2)
        local lowest = math.huge
        for _, p in ipairs(model:GetDescendants()) do
            if p:IsA("BasePart") then
                local cf, sz = p.CFrame, p.Size
                local ext = math.abs(cf.RightVector.Y)  * sz.X / 2
                          + math.abs(cf.UpVector.Y)     * sz.Y / 2
                          + math.abs(cf.LookVector.Y)   * sz.Z / 2
                lowest = math.min(lowest, cf.Position.Y - ext)
            end
        end
        local lift = (groundY + 0.45) - lowest
        if lift > 0 then
            model:PivotTo(anchorPart.CFrame * CFrame.new(0, holdY + lift, holdZ))
        end
    end

    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = false
            p.CanCollide = false
            p.Massless = true
            if p ~= shell then
                local w = Instance.new("WeldConstraint")
                w.Name = "EggWeld"; w.Part0 = shell; w.Part1 = p; w.Parent = shell
            end
        end
    end
    local hw = Instance.new("WeldConstraint")
    hw.Name = "HandWeld"; hw.Part0 = anchorPart; hw.Part1 = shell; hw.Parent = shell
    local boxCF, boxSize = model:GetBoundingBox()
    plr:SetAttribute("CarryCenter", anchorPart.CFrame:PointToObjectSpace(boxCF.Position))
    plr:SetAttribute("CarrySize", boxSize)
    return true
end
function detachFromHands(model, plr)
    if plr then setArmsCarrying(plr, false) end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("WeldConstraint") then d:Destroy() end
    end
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = true
            p.Massless = false
        end
    end
    local base = model:GetAttribute("CarryBaseScale")
    if base then
        model:SetAttribute("CarryBaseScale", nil)
        if math.abs(model:GetScale() - base) > 1e-4 then model:ScaleTo(base) end
    end
end

local function makeLoose(model, pos)
    local e = eggs[model]
    if not e then return end
    detachFromHands(model, e.carrier)
    if e.carrier then
        setSpeed(e.carrier, 1)
        carriers[e.carrier] = nil
        setCarrying(e.carrier, false)
        e.carrier = nil
    end
    e.state = "loose"
    e.wasAtAnchor = false
    model.Parent = looseFolder
    standAt(model, pos.X, e.floatY, pos.Z, e.yaw)
    attachPrompt(model)
end

local function placeAtAnchor(model)
    local e = eggs[model]
    if not e then return end
    releaseHeld(model)
    for _, other in ipairs(e.anchor:GetChildren()) do
        if other ~= model and eggs[other] then
            eggs[model] = nil
            model:Destroy()
            return
        end
    end
    e.state = "anchor"
    e.carrier = nil
    model.Parent = e.anchor
    standAt(model, e.anchor.Position.X, e.floatY, e.anchor.Position.Z, e.yaw)
    attachPrompt(model)
end

local function bankEgg(plr)
    local model = carriers[plr]
    if not model then return end
    local e = eggs[model]
    carriers[plr] = nil
    setCarrying(plr, false)
    detachFromHands(model, plr)
    setSpeed(plr, 1)
    eggs[model] = nil
    local anchor = e.anchor
    model:Destroy()

    local profile = _G.Profile and _G.Profile.get(plr)
    if profile then
        profile.Eggs = profile.Eggs or {}
        table.insert(profile.Eggs, { z = e.zone, t = e.tier, s = e.size, sp = e.species })
    end
    if _G.EggGiveTool then _G.EggGiveTool(plr, e.zone, e.tier, e.size, e.species) end

    Remote:FireClient(plr, "Banked", {
        tier = Cfg.TIERS[e.tier].name, size = Cfg.SIZES[e.size].name, species = e.species,
        zone = e.zone, value = e.value,
    })

    if not _G.DayNight then
        task.delay(Cfg.RESPAWN_DELAY, function()
            if anchor and anchor.Parent and #anchor:GetChildren() == 0 then makeEgg(anchor) end
        end)
    end
end

local SLEEP_TEX = "rbxassetid://119912840081124"
local WAKE_TIME = 1.35
local ATTACK_TIME = 0.65
local STRIKE_K = {
    SwanV2 = 0.45, FarmerChicken = 0.45, DesertScorpion = 0.42, FarmerTiger = 0.55,
    FrostYeti = 0.55, VolcanicHydra = 0.45, Tidebud = 0.50, JungleRex = 0.50,
    ShadowKing = 0.50, BlossomWolf = 0.42, Sandwatcher = 0.40, VoidGuardian = 0.40,
}
local function strikeTime(b)
    return ATTACK_TIME * (STRIKE_K[b.model:GetAttribute("Design")] or 0.45)
end

local function bossSpot(n) return Cfg.bossSpot(n) end

local function partNamed(m, name)
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") and d.Name == name then return d end
    end
    return nil
end

local function modelBox(m)
    local mn = Vector3.new(math.huge, math.huge, math.huge); local mx = -mn
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("BasePart") then
            local cf, sz = d.CFrame, d.Size
            local e = Vector3.new(
                math.abs(cf.RightVector.X)*sz.X/2 + math.abs(cf.UpVector.X)*sz.Y/2 + math.abs(cf.LookVector.X)*sz.Z/2,
                math.abs(cf.RightVector.Y)*sz.X/2 + math.abs(cf.UpVector.Y)*sz.Y/2 + math.abs(cf.LookVector.Y)*sz.Z/2,
                math.abs(cf.RightVector.Z)*sz.X/2 + math.abs(cf.UpVector.Z)*sz.Y/2 + math.abs(cf.LookVector.Z)*sz.Z/2)
            mn = Vector3.new(math.min(mn.X,cf.Position.X-e.X), math.min(mn.Y,cf.Position.Y-e.Y), math.min(mn.Z,cf.Position.Z-e.Z))
            mx = Vector3.new(math.max(mx.X,cf.Position.X+e.X), math.max(mx.Y,cf.Position.Y+e.Y), math.max(mx.Z,cf.Position.Z+e.Z))
        end
    end
    return mn, mx
end

local function setEyesOpen(b, open)
    for _, e in ipairs(b.eyes) do
        if open then
            e.part.Color = e.openColor
            e.part.Transparency = e.openAlpha
        elseif e.isPupil then
            e.part.Transparency = 1
        else
            e.part.Color = e.lid
            e.part.Transparency = e.openAlpha
        end
        if e.light then e.light.Enabled = open end

        if e.lash then e.lash.Transparency = open and 1 or 0 end
    end
end

local PATH_MID_X = 1500
local function homeYaw(b)
    return (b.homeXZ.X < PATH_MID_X) and -math.pi / 2 or math.pi / 2
end

local function spawnBosses()
    local folder = workspace:FindFirstChild("Bosses")
    if folder then folder:Destroy() end
    folder = Instance.new("Folder"); folder.Name = "Bosses"; folder.Parent = workspace
    folder:SetAttribute("WakeTime", WAKE_TIME)
    folder:SetAttribute("AttackTime", ATTACK_TIME)

    local bossSet = assets:FindFirstChild("Bosses")
    for n = 1, Cfg.ZONES do
        local tpl = bossSet and bossSet:FindFirstChild("Zone" .. n)
        if not tpl then
            warn(("[EggBoss] no boss model ServerStorage.EggAssets.Bosses.Zone%d - zone %d has no boss"):format(n, n))
            continue
        end
        local tplName = tpl.Name
        local model = tpl:Clone()
        model.Name = string.format("Boss%d_%s", n, Cfg.NAMES[n])

        local targetH = Cfg.BOSS.baseHeight * (Cfg.BOSS.growth ^ (n - 1))
        local mn, mx = modelBox(model)
        local h = mx.Y - mn.Y
        if h > 0.0001 then model:ScaleTo(model:GetScale() * (targetH / h)) end

        mn, mx = modelBox(model)
        local wide = math.max(mx.X - mn.X, mx.Z - mn.Z)
        if wide > Cfg.BOSS.maxWidth then
            model:ScaleTo(model:GetScale() * (Cfg.BOSS.maxWidth / wide))
        end
        mn, mx = modelBox(model)
        local H = mx.Y - mn.Y
        model:SetAttribute("AnimScale", model:GetScale() / math.max(tpl:GetScale(), 1e-4))

        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BillboardGui") then d:Destroy() end
        end
        model.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
        model.Parent = folder

        local skinPart = partNamed(model, "head")
            or partNamed(model, "body")
            or model:FindFirstChildWhichIsA("BasePart", true)
        local skin = skinPart and skinPart.Color or Color3.fromRGB(200, 200, 200)

        local eyes = {}
        local animated = BossAnim.animated(model)
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("BasePart") then
                local nm = d.Name:lower()

                local isGlint = nm:find("glint", 1, true) or nm:find("highlight", 1, true)
                    or nm:find("shine", 1, true) or nm:find("sparkle", 1, true)
                if (nm:find("eye", 1, true) or nm:find("pupil", 1, true)
                   or nm:find("oko", 1, true) or isGlint)
                   and not (nm:find("lid", 1, true) or nm:find("brow", 1, true)
                            or nm:find("socket", 1, true) or nm:find("lash", 1, true)) then

                    local under = d.Parent and d.Parent:IsA("BasePart") and d.Parent or nil
                    local lidColour = d:GetAttribute("LidColor")
                    if typeof(lidColour) ~= "Color3" then
                        lidColour = (under and under.Color or skin):Lerp(Color3.new(0, 0, 0), 0.18)
                    end
                    table.insert(eyes, {
                        part = d, openColor = d.Color, openAlpha = d.Transparency,
                        isPupil = (nm:find("pupil", 1, true) or isGlint) ~= nil,
                        lid = lidColour,
                        light = d:FindFirstChildOfClass("PointLight"),
                    })
                end
            end
        end

        for _, e in ipairs(eyes) do
            if not e.isPupil then
                local p = e.part
                local l = e.lid
                local lum = 0.2126 * l.R + 0.7152 * l.G + 0.0722 * l.B
                local lash = Instance.new("Part")
                lash.Name = p.Name .. "_lash"
                lash.Anchored = true
                lash.CanCollide = false
                lash.CanTouch = false
                lash.CanQuery = false
                lash.CastShadow = false
                lash.Material = Enum.Material.SmoothPlastic
                lash.Color = (lum > 0.28) and l:Lerp(Color3.new(0, 0, 0), 0.72)
                                          or l:Lerp(Color3.new(1, 1, 1), 0.55)
                lash.Size = Vector3.new(p.Size.X * 0.86, math.max(p.Size.Y * 0.16, 0.05), p.Size.Z)

                lash.CFrame = p.CFrame * CFrame.new(0, -p.Size.Y * 0.06, -(p.Size.Z * 0.5 + 0.02))
                local headPart, best = nil, math.huge
                for _, hp in ipairs(model:GetDescendants()) do
                    if hp:IsA("BasePart") then
                        local hn = hp.Name:lower()
                        if hn:find("head", 1, true) and not (hn:find("eye", 1, true) or hn:find("pupil", 1, true)
                            or hn:find("lash", 1, true) or hn:find("glint", 1, true) or hn:find("horn", 1, true)
                            or hn:find("brow", 1, true)) then
                            local dd = (hp.Position - p.Position).Magnitude
                            if dd < best then headPart, best = hp, dd end
                        end
                    end
                end
                local out = headPart and (p.Position - headPart.Position)
                local front = model:GetPivot().LookVector
                local dir
                if out and out.Magnitude > 0.05 then
                    dir = out.Unit
                else
                    local centre = model:GetBoundingBox().Position
                    dir = ((p.Position - centre):Dot(front) < 0) and -front or front
                end
                do
                    local cf0 = p.CFrame
                    local reach = math.abs(cf0.RightVector:Dot(dir)) * p.Size.X / 2
                        + math.abs(cf0.UpVector:Dot(dir)) * p.Size.Y / 2
                        + math.abs(cf0.LookVector:Dot(dir)) * p.Size.Z / 2 + 0.03
                    local side = Vector3.yAxis:Cross(dir)
                    local across = math.abs(cf0.RightVector:Dot(side)) * p.Size.X
                        + math.abs(cf0.UpVector:Dot(side)) * p.Size.Y
                        + math.abs(cf0.LookVector:Dot(side)) * p.Size.Z
                    local thinnest = math.min(p.Size.X, p.Size.Y, p.Size.Z)
                    lash.Size = Vector3.new(math.max(math.min(across, thinnest) * 0.9, 0.05), lash.Size.Y, 0.08)
                    lash.CFrame = CFrame.lookAt(p.Position, p.Position + dir)
                        * CFrame.new(0, -p.Size.Y * 0.06, -reach)
                end
                lash.Transparency = 1
                lash.Parent = p.Parent
                if animated then
                    lash.Anchored = false
                    lash.Massless = true
                    local weld = Instance.new("WeldConstraint")
                    weld.Part0 = p
                    weld.Part1 = lash
                    weld.Parent = lash
                end
                e.lash = lash
            end
        end

        local host = partNamed(model, "head") or skinPart
        local att = Instance.new("Attachment")
        att.Name = "SleepFx"
        local _, topNow = modelBox(model)
        local up = math.max(H * 0.35, (topNow.Y - host.Position.Y) + H * 0.04)
        att.Position = host.CFrame:VectorToObjectSpace(Vector3.new(0, up, 0))
        att.Parent = host
        local pe = Instance.new("ParticleEmitter")
        pe.Name = "Zzz"
        pe.Texture = SLEEP_TEX
        pe.Rate = 1.1
        pe.Lifetime = NumberRange.new(2.6, 3.4)
        pe.Speed = NumberRange.new(H * 0.10, H * 0.16)
        pe.SpreadAngle = Vector2.new(12, 12)
        pe.Rotation = NumberRange.new(-14, 14)
        pe.RotSpeed = NumberRange.new(-16, 16)
        pe.Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0),
            NumberSequenceKeypoint.new(0.25, H * 0.20),
            NumberSequenceKeypoint.new(1.00, H * 0.30),
        })
        pe.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 1),
            NumberSequenceKeypoint.new(0.18, 0.15),
            NumberSequenceKeypoint.new(0.75, 0.30),
            NumberSequenceKeypoint.new(1.00, 1),
        })
        pe.Acceleration = Vector3.new(0.4, 1.2, 0)
        pe.LightEmission = 0.35
        pe.Parent = att

        local warn = Instance.new("BillboardGui")
        warn.Name = "Danger"
        warn.Size = UDim2.fromScale(H * 0.38, H * 0.38)
        warn.StudsOffsetWorldSpace = Vector3.new(0, H * 0.26, 0)
        warn.AlwaysOnTop = true
        warn.MaxDistance = 500
        warn.Adornee = host
        warn.Enabled = false
        warn.Parent = host
        local wi = Instance.new("ImageLabel")
        wi.Name = "Icon"
        wi.Size = UDim2.fromScale(1, 1)
        wi.BackgroundTransparency = 1
        wi.Image = "rbxassetid://88282714087162"
        wi.Parent = warn

        local spot = bossSpot(n)
        local zTop, zBot = Cfg.bounds(n)
        local rec = {
            model = model, zoneIndex = n, H = H,
            homeXZ = Vector2.new(spot.X, spot.Z),
            sleepY = H / 2,
            awakeY = H / 2,
            zTop = zTop, zBot = zBot,
            state = "sleep", hold = nil, wakeT = 0, atkT = 0, afterAttack = nil,
            phase = rng:NextNumber(0, math.pi * 2),
            speed = Cfg.BOSS.speed[n] or 45,
            eyes = eyes, skin = skin, fx = pe, warn = warn, y = H / 2,
        }
        rec.home = Vector3.new(spot.X, rec.sleepY, spot.Z)
        bosses[n] = rec

        model:PivotTo(CFrame.new(rec.home) * CFrame.Angles(0, homeYaw(rec), 0))

        local bmn, bmx = modelBox(model)
        local dx = 0
        if spot.X < 1500 then
            if bmx.X + dx > Cfg.LANE_L - 2 then dx = (Cfg.LANE_L - 2) - bmx.X end
            if bmn.X + dx < Cfg.X_MIN + 1 then dx = (Cfg.X_MIN + 1) - bmn.X end
        else
            if bmn.X + dx < Cfg.LANE_R + 2 then dx = (Cfg.LANE_R + 2) - bmn.X end
            if bmx.X + dx > Cfg.X_MAX - 1 then dx = (Cfg.X_MAX - 1) - bmx.X end
        end

        local dy = -bmn.Y
        if math.abs(dx) > 0.01 or math.abs(dy) > 0.01 then
            model:PivotTo(model:GetPivot() + Vector3.new(dx, dy, 0))
            rec.homeXZ = Vector2.new(rec.homeXZ.X + dx, rec.homeXZ.Y)
            rec.sleepY = rec.sleepY + dy
            rec.awakeY = rec.awakeY + dy
            rec.home = Vector3.new(rec.homeXZ.X, rec.sleepY, rec.homeXZ.Y)
            rec.y = rec.sleepY
        end

        pcall(function()
            if animated or model:GetAttribute("Studs") ~= true then return end
            if model:GetAttribute("Design") == "SwanV2" or model:GetAttribute("Design") == "FarmerChicken" or model:GetAttribute("Design") == "DesertScorpion" or model:GetAttribute("Design") == "FarmerTiger" or model:GetAttribute("Design") == "FrostYeti" or model:GetAttribute("Design") == "VolcanicHydra" or model:GetAttribute("Design") == "Tidebud" or model:GetAttribute("Design") == "JungleRex" or model:GetAttribute("Design") == "ShadowKing" or model:GetAttribute("Design") == "BlossomWolf" or model:GetAttribute("Design") == "Sandwatcher" or model:GetAttribute("Design") == "VoidGuardian" then return end
            local Paint = require(game:GetService("ReplicatedStorage"):WaitForChild("AnimalPaint"))
            Paint.studs(model, 16, function(part)
                local nm = part.Name:lower()
                return nm:find("lash", 1, true) or nm:find("oko", 1, true)
                    or nm:find("lid", 1, true) or nm:find("pupil", 1, true)
            end)
        end)

        rec.cf = model:GetPivot()
        model:SetAttribute("BossRig", tplName)
        model:SetAttribute("BossIndex", n)
        model:SetAttribute("BossH", H)
        model:SetAttribute("BossCF", rec.cf)
        model:SetAttribute("BossVel", Vector3.zero)
        model:SetAttribute("BossStamp", workspace:GetServerTimeNow())
        setEyesOpen(rec, false)
    end
end

local function pickTarget(b)
    local best, bestVal = nil, -1
    for plr, model in pairs(carriers) do
        local e = eggs[model]
        local root, hum = rootOf(plr)
        if e and root and hum and hum.Health > 0 and not inSafeZone(root.Position.Z) then
            local pz = root.Position.Z
            local mineEgg = (e.zone == b.zoneIndex)
            local inMine  = (pz <= b.zTop and pz >= b.zBot)
            local chase = mineEgg or (Cfg.FOREIGN_BOSS_CHASES and inMine)
            if chase and e.value > bestVal then best, bestVal = plr, e.value end
        end
    end
    return best
end

local function findLoose(b)
    local best, bestD = nil, math.huge
    for model, e in pairs(eggs) do
        if e.state == "loose" and e.zone == b.zoneIndex then
            local p = model:GetPivot().Position
            if p.Z <= b.zTop and p.Z >= b.zBot then
                local d = (p - b.cf.Position).Magnitude
                if d < bestD then best, bestD = model, d end
            end
        end
    end
    return best
end

local function setBossCF(b, cf)
    b.cf = cf
end

local function moveBoss(b, goal, speed, dt, faceGoal)
    local pos = b.cf.Position
    local dir = goal - pos
    local dist = dir.Magnitude
    if dist < 0.05 then return 0 end
    local step = dir.Unit * math.min(speed * dt, dist)
    local np   = pos + step
    local look = faceGoal and Vector3.new(goal.X, np.Y, goal.Z) or (np + dir)

    if (look - np).Magnitude > 0.05 then
        setBossCF(b, CFrame.new(np, look))
    else
        local cf = b.cf
        setBossCF(b, CFrame.new(np) * (cf - cf.Position))
    end
    return dist
end

local function sleepDown(b)
    b.state = "sleep"
    b.fx.Enabled = true
    if b.warn then b.warn.Enabled = false end
    b.model:SetAttribute("Angry", false)
    setEyesOpen(b, false)
end
local function wakeUp(b)
    b.state = "waking"
    b.wakeT = 0
    b.fx.Enabled = false
    b.model:SetAttribute("Angry", true)
    setEyesOpen(b, true)
end

local function bossStrike(n, b, target, root, hum, model, e)
    local away = (root.Position - b.cf.Position)
    away = (away.Magnitude > 0.1) and away.Unit or Vector3.new(0, 0, 1)

    local hit = Cfg.hitFor(speedOf(target), e.zone, e.size)

    Remote:FireClient(target, "BossHit", { zone = e.zone, stun = hit.stun })
    local push = away * hit.back + Vector3.new(0, hit.up, 0)

    pcall(function() root:SetNetworkOwner(nil) end)

    if hum then Ragdoll.on(hum.Parent) end
    root.AssemblyLinearVelocity = push

    local spin = away:Cross(Vector3.yAxis)
    spin = (spin.Magnitude > 0.01) and spin.Unit * 7 or Vector3.new(7, 0, 0)
    root.AssemblyAngularVelocity = spin

    task.delay(0.06, function()
        if root.Parent then
            root.AssemblyLinearVelocity = push
            root.AssemblyAngularVelocity = spin
        end
    end)

    task.delay(hit.stun, function()
        if hum and hum.Parent then Ragdoll.off(hum.Parent) end
        pcall(function()
            if root.Parent and target.Parent then
                root:SetNetworkOwner(target)
            end
        end)
    end)

    local pz = root.Position.Z
    local inMyZone = (pz <= b.zTop and pz >= b.zBot)
    local takeBack = (e.zone == n) and inMyZone
    makeLoose(model, root.Position)

    if takeBack then
        detachPrompt(model)
        e.state = "boss"
        b.hold = model
        game:GetService("CollectionService"):AddTag(model, "BossHeldEgg")
        model:SetAttribute("HeldBy", n)
        model:SetAttribute("HeldYaw", e.yaw or 0)
        b.afterAttack = "carryback"
    else
        b.afterAttack = "returning"
    end
    Remote:FireClient(target, "Caught", {
        boss = Cfg.NAMES[n],
        kept = takeBack,
    })
end

local function stepBossCore(n, b, dt)
    local pos = b.cf.Position

    if pos.X ~= pos.X or pos.Y ~= pos.Y or pos.Z ~= pos.Z
       or math.abs(pos.Y) > 5000 then
        warn(("[EggBoss] boss %d had an invalid position - returned to its lair"):format(n))
        setBossCF(b, CFrame.new(b.homeXZ.X, b.awakeY, b.homeXZ.Y))
        b.state = "returning"
        if b.hold then releaseHeld(b.hold) end
        b.hold = nil
        pos = b.cf.Position
    end

    if b.state == "carryback" and b.hold and eggs[b.hold] then
        local e = eggs[b.hold]
        local goal = Vector3.new(e.anchor.Position.X, b.awakeY, e.anchor.Position.Z)
        local d = moveBoss(b, goal, Cfg.BOSS.carryBackSpd, dt, true)

        if d < b.H * 0.7 + 4 then
            placeAtAnchor(b.hold)
            b.hold = nil
            b.state = "returning"
        end
        return
    elseif b.state == "carryback" then
        b.hold = nil; b.state = "returning"
    end

    if b.state == "waking" then
        b.wakeT = b.wakeT + dt
        local k = math.clamp(b.wakeT / WAKE_TIME, 0, 1)
        local y = b.sleepY + (b.awakeY - b.sleepY) * (k * k * (3 - 2 * k))

        local wt = pickTarget(b)
        local wroot = wt and rootOf(wt)
        local dx, dz = 0, 0
        if wroot and k > 0.25 then
            local d = Vector3.new(wroot.Position.X - pos.X, 0, wroot.Position.Z - pos.Z)
            local m = d.Magnitude
            if m > 0.001 then
                local wcar = carriers[wt]
                local we = wcar and eggs[wcar]
                local pace = we
                    and Cfg.bossSpeedFor(speedOf(wt), we.zone, we.size)
                    or Cfg.walkForSpeed(speedOf(wt)) * 0.9
                local step = math.min(pace * ((k - 0.25) / 0.75) * dt, m)
                dx, dz = d.X / m * step, d.Z / m * step
            end
        end

        if wroot and k > 0.25 then
            local np   = Vector3.new(pos.X + dx, y, pos.Z + dz)
            local look = Vector3.new(wroot.Position.X, y, wroot.Position.Z)

            if (look - np).Magnitude > 0.05 then
                setBossCF(b, CFrame.new(np, look))
            else
                local cf = b.cf
                setBossCF(b, CFrame.new(np) * (cf - cf.Position))
            end
        else
            setBossCF(b, CFrame.new(pos.X, y, pos.Z)
                * CFrame.Angles(0, homeYaw(b), 0))
        end
        if k >= 1 then b.state = "chase" end
        return    end

    if b.state == "attack" then
        b.atkT = b.atkT + dt
        if not b.struck then
            local target = b.atkTarget
            local root, hum
            if target and target.Parent then root, hum = rootOf(target) end
            local model = target and carriers[target]
            local e = model and eggs[model]
            if not (root and e) or inSafeZone(root.Position.Z) then
                b.state, b.atkTarget = "chase", nil
                return
            end
            local goal = Vector3.new(root.Position.X, b.awakeY, root.Position.Z)
            local reach = Cfg.BOSS.catchRadius + b.H * 0.35
            local dist = (goal - pos).Magnitude
            if dist > reach * 0.8 then
                moveBoss(b, goal, Cfg.bossSpeedFor(speedOf(target), e.zone, e.size), dt, true)
            end
            if b.atkT >= strikeTime(b) then
                if dist <= reach * 1.3 + 2 then
                    b.struck = true
                    bossStrike(n, b, target, root, hum, model, e)
                else
                    b.state, b.atkTarget = "chase", nil
                end
            end
            return
        end
        if b.atkT >= ATTACK_TIME then
            b.state = b.afterAttack or "returning"
            b.afterAttack, b.atkTarget = nil, nil
        end
        return
    end

    local target = pickTarget(b)

    if target and b.state == "sleep" then
        wakeUp(b)
        return
    end

    if target then
        b.state = "chase"
        local root, hum = rootOf(target)
        if root then
            local goal = Vector3.new(root.Position.X, b.awakeY, root.Position.Z)
            local dist = (goal - pos).Magnitude
            local reach = Cfg.BOSS.catchRadius + b.H * 0.35
            local toward = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
            local runAway = toward.Magnitude > 0.1
                and root.AssemblyLinearVelocity:Dot(toward.Unit) or 0
            local cc = carriers[target]
            local ee = cc and eggs[cc]
            local bossPace = ee and Cfg.bossSpeedFor(speedOf(target), ee.zone, ee.size) or 0
            local lead = math.clamp((bossPace - runAway) * strikeTime(b), 0, reach)
            if dist <= reach + lead then
                if ee then
                    b.state = "attack"
                    b.atkT = 0
                    b.struck = false
                    b.atkTarget = target
                end
                return
            end

            local carried = carriers[target]
            local ce = carried and eggs[carried]
            local pace = ce
                and Cfg.bossSpeedFor(speedOf(target), ce.zone, ce.size)
                or Cfg.walkForSpeed(speedOf(target)) * 0.9
            local sp = (dist > Cfg.BOSS.closeRange)
                and (pace * Cfg.BOSS.closeSpeed) or pace
            moveBoss(b, goal, sp, dt, true)
            return
        end
    end

    if b.state ~= "sleep" then
        local loose = findLoose(b)
        if loose then
            b.state = "fetch"
            local goal = loose:GetPivot().Position + Vector3.new(0, b.awakeY, 0)
            local d = moveBoss(b, goal, Cfg.BOSS.fetchSpeed, dt, true)
            if d <= Cfg.BOSS.grabRadius + b.H * 0.5 then
                detachPrompt(loose)
                eggs[loose].state = "boss"
                b.hold = loose
                game:GetService("CollectionService"):AddTag(loose, "BossHeldEgg")
                loose:SetAttribute("HeldBy", n)
                loose:SetAttribute("HeldYaw", eggs[loose].yaw or 0)
                b.state = "carryback"
            end
            return
        end
    end

    local homeAwake = Vector3.new(b.homeXZ.X, b.awakeY, b.homeXZ.Y)
    local flat = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(b.homeXZ.X, 0, b.homeXZ.Y)).Magnitude
    if flat > 2.5 then
        b.state = "returning"
        local back = math.clamp(flat * 0.7, Cfg.BOSS.returnSpeed, 420)
        moveBoss(b, homeAwake, back, dt, false)
        return
    end

    if b.state ~= "sleep" then

        local y = pos.Y - (b.awakeY - b.sleepY) * dt * 1.6
        if y <= b.sleepY + 0.05 then
            y = b.sleepY
            sleepDown(b)
        end
        setBossCF(b, CFrame.new(b.homeXZ.X, y, b.homeXZ.Y)
            * CFrame.Angles(0, homeYaw(b), 0))
        return
    end

    b.phase = b.phase + dt
    setBossCF(b, CFrame.new(b.homeXZ.X,
        b.sleepY,
        b.homeXZ.Y) * CFrame.Angles(0, homeYaw(b) + math.sin(b.phase * 0.22) * 0.10, 0))
end

local SLEEP_STEP = 0.1
local PUBLISH_EVERY = 1 / 30

local function publishBoss(b, force)
    local now = workspace:GetServerTimeNow()
    if not force and b.lastPub and now - b.lastPub < PUBLISH_EVERY then return end
    local pos = b.cf.Position
    local vel = Vector3.zero
    local gap = b.lastPub and (now - b.lastPub) or 0
    if b.state ~= "sleep" and not (b.state == "attack" and b.struck) then
        if b.pubPos and gap > 0.01 then
            local raw = (pos - b.pubPos) / gap
            vel = (b.pubVel or raw):Lerp(raw, 0.5)
        else
            vel = b.pubVel or Vector3.zero
        end
    end
    b.pubVel = vel
    b.model:SetAttribute("BossCF", b.cf)
    b.model:SetAttribute("BossVel", vel)
    b.model:SetAttribute("BossStamp", now)
    b.pubPos, b.lastPub = pos, now
end

local function stepBoss(n, b, dt)
    if b.state == "sleep" and next(carriers) == nil and b.pubState == "sleep" then
        b.idleAcc = (b.idleAcc or 0) + dt
        if b.idleAcc < SLEEP_STEP then return end
        dt, b.idleAcc = b.idleAcc, 0
    end
    stepBossCore(n, b, dt)
    if b.pubState ~= b.state then
        b.pubState = b.state
        b.model:SetAttribute("BossState", b.state)
        b.model:SetAttribute("BossStateAt", workspace:GetServerTimeNow())
        publishBoss(b, true)
    elseif b.state ~= "sleep" then
        publishBoss(b, false)
    end
end

local function stepEggs(dt)
    local t = os.clock()
    for model, e in pairs(eggs) do
        if not model.Parent then
            eggs[model] = nil
        elseif not model.PrimaryPart then
            local plr = e.carrier
            if plr and carriers[plr] == model then
                carriers[plr] = nil
                pcall(setCarrying, plr, false)
                setSpeed(plr, 1)
            end
            eggs[model] = nil
            model:Destroy()
        elseif e.state == "player" then
            local plr = e.carrier
            local root = plr and rootOf(plr)
            if not root then

                makeLoose(model, model:GetPivot().Position)
            else

                if model.PrimaryPart and not model.PrimaryPart:FindFirstChild("HandWeld") then
                    attachToHands(model, plr, e)
                end
                if inSafeZone(root.Position.Z) then
                    local dist = Cfg.SAFE_Z - (e.pickPos and e.pickPos.Z or Cfg.SAFE_Z)
                    local reach = (Cfg.WALK_BASE + Cfg.WALK_RANGE) * 1.5 * (os.clock() - (e.pickT or 0)) + 60
                    if dist > reach and e.pickPos then
                        makeLoose(model, e.pickPos)
                        Remote:FireClient(plr, "Drop", "hit")
                    else
                        bankEgg(plr)
                    end
                end
            end
        end

    end
end

local nestFolder = map:FindFirstChild("EggNests")
if nestFolder then nestFolder:Destroy() end
nestFolder = Instance.new("Folder"); nestFolder.Name = "EggNests"; nestFolder.Parent = map

local nestTemplate = assets:FindFirstChild("Nest")

for _, zf in ipairs(spawnsRoot:GetChildren()) do
    for _, anchor in ipairs(zf:GetChildren()) do
        if anchor:IsA("BasePart") then
            for _, c in ipairs(anchor:GetChildren()) do c:Destroy() end
            if nestTemplate then
                local nest = nestTemplate:Clone()
                nest.Name = string.format("Nest_Z%d_%d",
                    anchor:GetAttribute("Zone"), anchor:GetAttribute("Slot"))
                nest.Parent = nestFolder
                local yaw = rng:NextNumber(0, math.pi * 2)
                nest:SetAttribute("Yaw", yaw)
                nest:SetAttribute("BaseScale", nest:GetScale())
                standAt(nest, anchor.Position.X, 0, anchor.Position.Z, yaw)
            end
            makeEgg(anchor)
        end
    end
end
spawnBosses()
for n, b in pairs(bosses) do b.zoneIndex = n end

Remote.OnServerEvent:Connect(function(plr, action)
    if action ~= "Drop" then return end
    local model = carriers[plr]
    if not model then return end
    local root = rootOf(plr)
    makeLoose(model, root and root.Position or model:GetPivot().Position)
    Remote:FireClient(plr, "Drop", "manual")
end)

Players.PlayerRemoving:Connect(function(plr)
    local model = carriers[plr]
    if model then makeLoose(model, model:GetPivot().Position) end
end)

local function refreshSpeed(plr)
    local model = carriers[plr]
    local e = model and eggs[model]
    setSpeed(plr, e and Cfg.SIZES[e.size].carry or 1)
end

local function hookSpeed(plr)
    plr:GetAttributeChangedSignal("Speed"):Connect(function() refreshSpeed(plr) end)
    plr:GetAttributeChangedSignal("SlowMode"):Connect(function() refreshSpeed(plr) end)
    plr:GetAttributeChangedSignal("HoldingCaptureEgg"):Connect(function() refreshSpeed(plr) end)
    plr:GetAttributeChangedSignal("SpeedMult"):Connect(function() refreshSpeed(plr) end)
    if plr:GetAttribute("SlowMode") == nil then plr:SetAttribute("SlowMode", false) end
end
for _, plr in ipairs(Players:GetPlayers()) do hookSpeed(plr) end
Players.PlayerAdded:Connect(hookSpeed)

Remote.OnServerEvent:Connect(function(plr, action, value)
    if action ~= "SlowMode" then return end
    plr:SetAttribute("SlowMode", value == true)
    refreshSpeed(plr)
end)

local BAG_LIMIT = 500
local bagCalls = {}
Players.PlayerRemoving:Connect(function(plr) bagCalls[plr] = nil end)
Remote.OnServerEvent:Connect(function(plr, action, data)
    if action ~= "BagState" and action ~= "BagSet" then return end
    local now = os.clock()
    local c = bagCalls[plr]
    if not c or now - c.at >= 1 then
        c = { at = now, n = 0 }
        bagCalls[plr] = c
    end
    c.n += 1
    if c.n > 20 then return end
    local profile = _G.Profile and _G.Profile.get(plr)
    if not profile then return end
    local bag = type(profile.BagState) == "table" and profile.BagState or {}
    bag.pets = type(bag.pets) == "table" and bag.pets or {}
    bag.eggs = type(bag.eggs) == "table" and bag.eggs or {}
    profile.BagState = bag
    if action == "BagSet" then
        if type(data) ~= "table" then return end
        if type(data.key) == "string" and #data.key > 0 and #data.key <= 64 then
            if data.on == true then
                local count = 0
                for _ in pairs(bag.pets) do count += 1 end
                if count < BAG_LIMIT then bag.pets[data.key] = true end
            else
                bag.pets[data.key] = nil
            end
        elseif type(data.sig) == "string" and #data.sig <= 12 and data.sig:match("^z%d+_t%d+_s%d+$") then
            local n = math.clamp(math.floor(tonumber(data.count) or 0), 0, BAG_LIMIT)
            if n > 0 and bag.eggs[data.sig] == nil then
                local kinds = 0
                for _ in pairs(bag.eggs) do kinds += 1 end
                if kinds >= 288 then return end
            end
            bag.eggs[data.sig] = (n > 0) and n or nil
        end
        return
    end
    Remote:FireClient(plr, "BagState", bag)
end)

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(ch)
        local hum = ch:WaitForChild("Humanoid", 5)
        if hum then hum.WalkSpeed = Cfg.walkForSpeed(speedOf(plr)) end
        local model = carriers[plr]
        if model then makeLoose(model, model:GetPivot().Position) end
    end)
end)

local TOOL_HEIGHT = 2.2

local function buildEggTool(zone, tier, size, species, luck)
    local speciesTpl = AnimalEggs.template(species)
    local tpl = speciesTpl or eggTemplate(zone)
    if not tpl then return nil end

    local m = tpl:Clone()
    local _, box = m:GetBoundingBox()
    if box.Y > 0.001 then m:ScaleTo(m:GetScale() * (TOOL_HEIGHT / box.Y)) end

    local colour = Cfg.eggColor(zone, tier)
    local accent = Color3.new(colour.R * 0.68, colour.G * 0.68, colour.B * 0.68)
    local glow = Cfg.GLOW[tier] or Cfg.GLOW[1]

    local parts, shell = {}, nil
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            table.insert(parts, p)
            if not shell and p.Name:lower():match("^shell") then shell = p end
        end
    end
    if not shell then m:Destroy() return nil end

    local tool = Instance.new("Tool")

    tool.Name = string.format("%s %s %s Egg",
        species or Cfg.NAMES[zone] or ("Zone" .. zone),
        Cfg.TIERS[tier].name, Cfg.SIZES[size].name)
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("EggZone", zone)
    tool:SetAttribute("EggTier", tier)
    tool:SetAttribute("EggSize", size)
    if species then tool:SetAttribute("EggSpecies", species) end
    if luck then tool:SetAttribute("EggLuck", luck) end

    for _, p in ipairs(parts) do
        local isShell = (p == shell)
        if not speciesTpl then
            p.Color = isShell and colour or (glow.deco and colour or accent)
            p.Material = ((isShell and glow.shell) or (not isShell and glow.deco))
                and Enum.Material.Neon or Enum.Material.SmoothPlastic
        end
        p.Anchored = false
        p.CanCollide = false
        p.CanQuery = false
        p.CanTouch = false
        p.Massless = true
        p.CastShadow = false
    end

    shell.Name = "Handle"

    shell:SetAttribute("RestOffset", CFrame.new())
    shell.Parent = tool
    for _, p in ipairs(parts) do
        if p ~= shell then
            p:SetAttribute("RestOffset", shell.CFrame:ToObjectSpace(p.CFrame))
            p.Parent = tool
            local w = Instance.new("WeldConstraint")
            w.Name = "EggWeld"; w.Part0 = shell; w.Part1 = p; w.Parent = shell
        end
    end
    m:Destroy()
    return tool
end

local function eggsOf(plr)
    local profile = _G.Profile and _G.Profile.get(plr)
    return profile and profile.Eggs or nil
end

local function rebuildBackpack(plr)
    local inv = eggsOf(plr)
    if not inv then return end
    local bag = plr:FindFirstChildOfClass("Backpack")
    if not bag then return end

    for _, t in ipairs(bag:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("EggZone") then t:Destroy() end
    end
    local ch = plr.Character
    if ch then
        for _, t in ipairs(ch:GetChildren()) do
            if t:IsA("Tool") and t:GetAttribute("EggZone") then t:Destroy() end
        end
    end

    if inv[1] == nil and next(inv) ~= nil then
        local list = {}
        for key, count in pairs(inv) do
            local z, ti, sz = tostring(key):match("^z(%d+)_t(%d+)_s(%d+)$")
            if z then
                for _ = 1, math.min(tonumber(count) or 0, 200) do
                    table.insert(list, { z = tonumber(z), t = tonumber(ti), s = tonumber(sz) })
                end
            end
        end
        local profile = _G.Profile and _G.Profile.get(plr)
        if profile then profile.Eggs = list end
        inv = list
    end

    for _, entry in ipairs(inv) do
        if entry.sp == nil then entry.sp = AnimalEggs.legacy(entry.z, entry.t, entry.s) end
        local tool = buildEggTool(entry.z, entry.t, entry.s, entry.sp, entry.lk)
        if tool then tool.Parent = bag end
    end
end

local function giveEggTool(plr, zone, tier, size, species, luck)
    local bag = plr:FindFirstChildOfClass("Backpack")
    if not bag then return end
    local tool = buildEggTool(zone, tier, size, species, luck)
    if tool then tool.Parent = bag end
    return tool
end
_G.EggGiveTool = giveEggTool

_G.EggGrant = function(plr, zone, tier, size, species, luck)
    local profile = _G.Profile and _G.Profile.get(plr)
    if not profile then return nil end
    species = species or AnimalEggs.pick(zone, tier)
    profile.Eggs = profile.Eggs or {}
    table.insert(profile.Eggs, { z = zone, t = tier, s = size, sp = species, lk = luck })
    return giveEggTool(plr, zone, tier, size, species, luck)
end

_G.EggAdmin = {
    give = function(plr, zone, tier, size) return _G.EggGrant(plr, zone, tier, size) end,

    spawn = function(zone, tier, size, howMany)
        local made = 0
        local want = howMany or 1
        for _, zf in ipairs(spawnsRoot:GetChildren()) do
            for _, anchor in ipairs(zf:GetChildren()) do
                if anchor:IsA("BasePart") and (not zone or anchor:GetAttribute("Zone") == zone) then
                    if made < want then
                        for _, m in ipairs(anchor:GetChildren()) do
                            if eggs[m] then eggs[m] = nil end
                            m:Destroy()
                        end
                        if makeEgg(anchor, tier, size) then made += 1 end
                    end
                end
            end
        end
        return made
    end,

    drop = function(plr)
        local model = carriers[plr]
        if not model then return false end
        local root = rootOf(plr)
        makeLoose(model, root and root.Position or model:GetPivot().Position)
        Remote:FireClient(plr, "Drop", "manual")
        return true
    end,

    resetAll = function()
        for model, e in pairs(eggs) do
            if e.state == "anchor" or e.state == "loose" then
                eggs[model] = nil
                if model.Parent then model:Destroy() end
            end
        end
        local made = {}
        for _, zf in ipairs(spawnsRoot:GetChildren()) do
            for _, anchor in ipairs(zf:GetChildren()) do
                if anchor:IsA("BasePart") then
                    for _, m in ipairs(anchor:GetChildren()) do
                        if eggs[m] then eggs[m] = nil end
                        m:Destroy()
                    end
                    makeEgg(anchor)
                    for _, m in ipairs(anchor:GetChildren()) do
                        local e = eggs[m]
                        if e then
                            table.insert(made, { zone = e.zone, tier = e.tier, size = e.size })
                        end
                    end
                end
            end
        end
        return made
    end,
}

local function hookEggBackpack(plr)
    task.spawn(function()
        for _ = 1, 300 do
            if not plr.Parent then return end
            if _G.Profile and _G.Profile.get(plr) and plr:FindFirstChildOfClass("Backpack") then break end
            task.wait(0.2)
        end
        if plr.Parent then rebuildBackpack(plr) end
    end)
    plr.CharacterAdded:Connect(function()
        task.delay(1, function() if plr.Parent then rebuildBackpack(plr) end end)
    end)
end
Players.PlayerAdded:Connect(hookEggBackpack)
for _, plr in ipairs(Players:GetPlayers()) do hookEggBackpack(plr) end

local GEAR = Cfg.GEAR

local STICK_TILT = CFrame.Angles(math.rad(-18), 0, math.rad(6))
local STICK_GRIP = CFrame.new(0, -1.45, 0) * STICK_TILT

local function gripFor(tool)
    local handle = tool:FindFirstChild("Handle")
    local tape = tool:FindFirstChild("grip_tape_wrap", true)
    if handle and tape then
        return CFrame.new(0, tape.Position.Y - handle.Position.Y, 0) * STICK_TILT
    end
    return STICK_GRIP
end
local trapsFolder = workspace:FindFirstChild("BearTraps")
if trapsFolder then trapsFolder:Destroy() end
trapsFolder = Instance.new("Folder")
trapsFolder.Name = "BearTraps"
trapsFolder.Parent = workspace

local stunToken, stunUntil = {}, {}
local gearReady = {}
local traps = {}

local function isStunned(plr)
    return (stunUntil[plr] or 0) > os.clock()
end

local function dropCarried(plr)
    local model = carriers[plr]
    if not model then return end
    local root = rootOf(plr)
    makeLoose(model, root and root.Position or model:GetPivot().Position)
    Remote:FireClient(plr, "Drop", "hit")
end

local function freeze(plr, seconds)
    local ch = plr.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    stunUntil[plr] = math.max(stunUntil[plr] or 0, os.clock() + seconds)
    stunToken[plr] = (stunToken[plr] or 0) + 1
    local mine = stunToken[plr]

    plr:SetAttribute("Stunned", true)

    plr:SetAttribute("StunEnds", workspace:GetServerTimeNow() + seconds)
    hum:UnequipTools()
    hum.WalkSpeed = 0
    hum.JumpPower = 0
    hum.JumpHeight = 0

    task.delay(seconds, function()
        if stunToken[plr] ~= mine then return end
        if not plr.Parent then return end
        plr:SetAttribute("Stunned", false)
        plr:SetAttribute("StunEnds", 0)
        local ch2 = plr.Character
        local h2 = ch2 and ch2:FindFirstChildOfClass("Humanoid")
        if h2 then
            local SP = game:GetService("StarterPlayer")
            h2.JumpPower = SP.CharacterJumpPower
            h2.JumpHeight = SP.CharacterJumpHeight
        end
        refreshSpeed(plr)
    end)
end

local function readyIn(plr, key, cd)
    gearReady[plr] = gearReady[plr] or {}
    local at = gearReady[plr][key] or 0
    if os.clock() < at then return false end
    gearReady[plr][key] = os.clock() + cd
    return true
end

local function gearTemplate(name)
    local set = assets:FindFirstChild("Gear")
    return set and set:FindFirstChild(name) or nil
end

local function buildStick()
    local tpl = gearTemplate("Stick")
    local tool
    if tpl then
        tool = tpl:Clone()
    else

        tool = Instance.new("Tool")
        local h = Instance.new("Part")
        h.Name = "Handle"
        h.Size = Vector3.new(0.32, 3.4, 0.32)
        h.Color = Color3.fromRGB(146, 96, 52)
        h.Material = Enum.Material.Wood
        h.TopSurface, h.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
        h.Parent = tool
    end
    tool.Name = "Stick"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("Gear", "Stick")
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            p.CanCollide = false
            p.Massless = true
            p.CanQuery = false
        end
    end
    tool.Grip = gripFor(tool)
    return tool
end

local SWING_ANIM_ID = "rbxassetid://522635514"
local SWING_TIME = 0.46
local SWING_SPEED = 1.1
local swinging = {}
local swingTracks = {}

local function swingTrackFor(plr)
    local ch = plr.Character
    local hum = ch and ch:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if not animator then return nil end

    local cached = swingTracks[plr]

    if cached and cached.animator == animator then return cached.track end

    local anim = Instance.new("Animation")
    anim.AnimationId = SWING_ANIM_ID
    local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
    if not ok or not track then return nil end
    track.Priority = Enum.AnimationPriority.Action
    swingTracks[plr] = { animator = animator, track = track }
    return track
end

local function swingGripOnly(plr)
    if swinging[plr] then return end
    local ch = plr.Character
    local tool = ch and ch:FindFirstChild("Stick")
    if not (tool and tool:IsA("Tool")) then return end

    swinging[plr] = true
    task.spawn(function()
        local t0 = os.clock()
        while true do
            local k = (os.clock() - t0) / SWING_TIME
            if k >= 1 then break end
            if not (tool.Parent and tool.Parent == plr.Character) then break end

            local pitch, yaw, roll, out, up
            if k < 0.30 then

                local u = k / 0.30
                local e = u * u
                pitch = math.rad(-105) * e
                yaw   = math.rad(-40) * e
                roll  = math.rad(18) * e
                out   = -0.35 * e
                up    =  0.30 * e
            elseif k < 0.62 then

                local u = (k - 0.30) / 0.32
                local e = 1 - (1 - u) ^ 3
                pitch = math.rad(-105) + math.rad(190) * e
                yaw   = math.rad(-40)  + math.rad(75)  * e
                roll  = math.rad(18)   - math.rad(40)  * e
                out   = -0.35 + 1.25 * e
                up    =  0.30 - 0.75 * e
            else

                local u = (k - 0.62) / 0.38
                local e = u * u * (3 - 2 * u)
                pitch = math.rad(85) * (1 - e)
                yaw   = math.rad(35) * (1 - e)
                roll  = math.rad(-22) * (1 - e)
                out   = 0.90 * (1 - e)
                up    = -0.45 * (1 - e)
            end

            tool.Grip = gripFor(tool)
                * CFrame.new(0, up, out)
                * CFrame.Angles(pitch, yaw, roll)
            task.wait()
        end
        if tool.Parent then tool.Grip = gripFor(tool) end
        swinging[plr] = nil
    end)
end

local function swingAnim(plr)
    local ch = plr.Character
    local tool = ch and ch:FindFirstChild("Stick")
    if not (tool and tool:IsA("Tool")) then return end

    tool.Grip = gripFor(tool)

    local track = swingTrackFor(plr)
    if not track then
        swingGripOnly(plr)
        return
    end
    if track.IsPlaying then track:Stop(0) end
    track:Play(0.05, 1, SWING_SPEED)
end

Players.PlayerRemoving:Connect(function(plr)
    swingTracks[plr] = nil
end)

local function swing(plr)
    if isStunned(plr) then return end
    if carriers[plr] then
        Remote:FireClient(plr, "Gear", { kind = "Stick", ok = false, why = "carry" })
        return
    end
    local root = rootOf(plr)
    if not root then return end
    if inSafeZone(root.Position.Z) then
        Remote:FireClient(plr, "Gear", { kind = "Stick", ok = false, why = "safe" })
        return
    end
    if not readyIn(plr, "stick", GEAR.stickCd) then return end

    local look = root.CFrame.LookVector
    local best, bestDist
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= plr then
            local oroot = rootOf(other)
            if oroot and not inSafeZone(oroot.Position.Z) and not isStunned(other) then
                local delta = oroot.Position - root.Position
                local dist = delta.Magnitude
                if dist <= GEAR.stickRange and dist > 0.01 then
                    if look:Dot(delta.Unit) >= GEAR.stickArc then
                        if not bestDist or dist < bestDist then best, bestDist = other, dist end
                    end
                end
            end
        end
    end

    Remote:FireClient(plr, "Gear", { kind = "Stick", ok = true, hit = best ~= nil })
    swingAnim(plr)
    if not best then return end

    local oroot = rootOf(best)
    local away = (oroot.Position - root.Position)
    away = (away.Magnitude > 0.1) and away.Unit or look
    local batMult = require(game.ServerScriptService.BatService).knockback(plr)
    local push = (away * GEAR.stickBack + Vector3.new(0, GEAR.stickUp, 0)) * batMult

    dropCarried(best)
    if _G.CaptureEgg then pcall(_G.CaptureEgg.onHit, best, plr) end
    pcall(function() oroot:SetNetworkOwner(nil) end)
    local hum = best.Character and best.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum.PlatformStand = true end
    oroot.AssemblyLinearVelocity = push
    task.delay(0.06, function()
        if oroot.Parent then oroot.AssemblyLinearVelocity = push end
    end)
    freeze(best, GEAR.stickStun)
    task.delay(GEAR.stickStun, function()
        local h = best.Character and best.Character:FindFirstChildOfClass("Humanoid")
        if h and not best.Character:GetAttribute("Ragdoll") then h.PlatformStand = false end
        pcall(function()
            if oroot.Parent and best.Parent then oroot:SetNetworkOwner(best) end
        end)
    end)
    Remote:FireClient(best, "Gear", { kind = "Hit", by = plr.Name })
end

local function buildTrapModel()
    local tpl = gearTemplate("Trap")
    if tpl then return tpl:Clone() end

    local m = Instance.new("Model")
    m.Name = "BearTrap"
    local base = Instance.new("Part")
    base.Name = "Plate"
    base.Shape = Enum.PartType.Cylinder
    base.Size = Vector3.new(0.35, 4.4, 4.4)
    base.CFrame = CFrame.Angles(0, 0, math.pi / 2)
    base.Color = Color3.fromRGB(74, 78, 84)
    base.Material = Enum.Material.Metal
    base.Anchored = true
    base.CanCollide = false
    base.Parent = m
    m.PrimaryPart = base
    for k = 1, 10 do
        local a = (k / 10) * math.pi * 2
        local tooth = Instance.new("WedgePart")
        tooth.Name = "Tooth" .. k
        tooth.Size = Vector3.new(0.28, 1.1, 0.7)
        tooth.Color = Color3.fromRGB(196, 200, 206)
        tooth.Material = Enum.Material.Metal
        tooth.Anchored = true
        tooth.CanCollide = false
        tooth.CFrame = base.CFrame
            * CFrame.new(0, math.cos(a) * 1.9, math.sin(a) * 1.9)
            * CFrame.Angles(0, 0, -a)
            * CFrame.new(0, 0.5, 0)
        tooth.Parent = m
    end
    return m
end

local function trapToolOf(plr)
    for _, where in ipairs({ plr:FindFirstChildOfClass("Backpack"), plr.Character }) do
        for _, t in ipairs(where and where:GetChildren() or {}) do
            if t:IsA("Tool") and t:GetAttribute("Gear") == "Trap" then return t end
        end
    end
    return nil
end

local function syncTrapCount(plr)
    if not (plr and plr.Parent) then return end
    local tool = trapToolOf(plr)
    if not tool then return end
    local used = 0
    for _, t in ipairs(traps) do if t.owner == plr then used = used + 1 end end
    local left = math.max(0, GEAR.maxTraps - used)
    if tool:GetAttribute("Count") ~= left then tool:SetAttribute("Count", left) end
end

local function placeTrap(plr)
    if isStunned(plr) then return end
    local root = rootOf(plr)
    if not root then return end
    if inSafeZone(root.Position.Z) then
        Remote:FireClient(plr, "Gear", { kind = "Trap", ok = false, why = "safe" })
        return
    end

    local mine = 0
    for _, t in ipairs(traps) do if t.owner == plr then mine = mine + 1 end end
    if mine >= GEAR.maxTraps then
        Remote:FireClient(plr, "Gear", { kind = "Trap", ok = false, why = "limit" })
        return
    end
    if not readyIn(plr, "trap", GEAR.trapCd) then return end

    local m = buildTrapModel()
    m:ScaleTo(m:GetScale() * 0.65)
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = false
        end
    end

    local ahead = root.CFrame.LookVector
    local flat = Vector3.new(ahead.X, 0, ahead.Z)
    flat = (flat.Magnitude > 0.01) and flat.Unit or Vector3.new(0, 0, -1)
    local spot = root.Position + flat * GEAR.trapAhead
    spot = Vector3.new(
        math.clamp(spot.X, Cfg.X_MIN + 4, Cfg.X_MAX - 4),
        0,
        spot.Z)

    standAt(m, spot.X, 0.05, spot.Z, math.atan2(flat.X, flat.Z))
    m.Parent = trapsFolder

    local rec = {
        model = m, owner = plr,
        pos = Vector3.new(spot.X, 0, spot.Z),
        armedAt = os.clock() + GEAR.trapArm,

        ownerSafeUntil = os.clock() + GEAR.trapOwnerGrace,
        diesAt = os.clock() + GEAR.trapLife,
    }
    table.insert(traps, rec)
    syncTrapCount(plr)
    Remote:FireClient(plr, "Gear", { kind = "Trap", ok = true })
end

local function stepTraps()
    local now = os.clock()
    for index = #traps, 1, -1 do
        local t = traps[index]
        if not t.model.Parent or now >= t.diesAt then
            t.model:Destroy()
            table.remove(traps, index)
            syncTrapCount(t.owner)
        elseif now >= t.armedAt then
            for _, plr in ipairs(Players:GetPlayers()) do
                local root = rootOf(plr)
                local ownerSafe = (plr == t.owner) and (os.clock() < (t.ownerSafeUntil or 0))
                if root and not ownerSafe and not isStunned(plr)
                   and not inSafeZone(root.Position.Z) then
                    local flat = Vector3.new(root.Position.X, 0, root.Position.Z)
                    if (flat - t.pos).Magnitude <= GEAR.trapRadius then
                        dropCarried(plr)
                        if _G.CaptureEgg then pcall(_G.CaptureEgg.onHit, plr) end
                        freeze(plr, GEAR.trapStun)
                        Remote:FireClient(plr, "Gear",
                            { kind = "Trapped", seconds = GEAR.trapStun })
                        t.model:Destroy()
                        table.remove(traps, index)
                        syncTrapCount(t.owner)
                        break
                    end
                end
            end
        end
    end
end

local TRAP_HELD_SIZE = 1.7

local function buildTrapTool()
    local tool = Instance.new("Tool")
    tool.Name = "Bear Trap"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("Gear", "Trap")

    local tpl = gearTemplate("TrapHeld") or gearTemplate("Trap")
    if tpl then
        local m = tpl:Clone()
        local _, box = m:GetBoundingBox()
        local widest = math.max(box.X, box.Z)
        if widest > 0.01 then m:ScaleTo(m:GetScale() * (TRAP_HELD_SIZE / widest)) end

        local parts, handle = {}, nil
        for _, d in ipairs(m:GetDescendants()) do
            if d:IsA("BasePart") then
                table.insert(parts, d)
                if d.Name == "Handle" or d.Name == "Plate" then handle = handle or d end
            end
        end
        handle = handle or parts[1]
        if handle then
            handle.Name = "Handle"
            for _, p in ipairs(parts) do p.Anchored = false end
            handle.Parent = tool
            for _, p in ipairs(parts) do
                if p ~= handle then
                    p.Parent = tool
                    local w = Instance.new("WeldConstraint")
                    w.Name = "GearWeld"; w.Part0 = handle; w.Part1 = p; w.Parent = handle
                end
            end
        end
        m:Destroy()
    end

    if not tool:FindFirstChild("Handle") then
        local h = Instance.new("Part")
        h.Name = "Handle"
        h.Shape = Enum.PartType.Cylinder
        h.Size = Vector3.new(0.5, 1.7, 1.7)
        h.Color = Color3.fromRGB(84, 88, 94)
        h.Material = Enum.Material.Metal
        h.Parent = tool
    end

    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = false
            p.CanCollide = false
            p.CanQuery = false
            p.CanTouch = false
            p.Massless = true
            p.CastShadow = false
        end
    end

    tool.Grip = CFrame.Angles(math.rad(-12), 0, 0)
    return toolend

local function giveGear(plr)
    local bag = plr:FindFirstChildOfClass("Backpack")
    if not bag then return end
    local have = {}
    for _, where in ipairs({ bag, plr.Character }) do
        for _, t in ipairs(where and where:GetChildren() or {}) do
            if t:IsA("Tool") and t:GetAttribute("Gear") then have[t:GetAttribute("Gear")] = true end
        end
    end
    if not have.Stick then
        local st = buildStick()
        st.Activated:Connect(function() swing(plr) end)
        st.Parent = bag
    end
    if not have.Trap then
        local tr = buildTrapTool()
        tr.Activated:Connect(function() placeTrap(plr) end)
        tr.Parent = bag
    end
    syncTrapCount(plr)
end

local function hookGear(plr)

    task.spawn(function()
        for _ = 1, 6 do
            if not plr.Parent then return end
            giveGear(plr)
            task.wait(1)
        end
        while plr.Parent do
            giveGear(plr)
            task.wait(5)
        end
    end)
    plr.CharacterAdded:Connect(function()
        task.delay(1.2, function() if plr.Parent then giveGear(plr) end end)
    end)
end
Players.PlayerAdded:Connect(hookGear)
for _, plr in ipairs(Players:GetPlayers()) do hookGear(plr) end

Players.PlayerRemoving:Connect(function(plr)
    stunUntil[plr], stunToken[plr], gearReady[plr] = nil, nil, nil
    for index = #traps, 1, -1 do
        if traps[index].owner == plr then
            traps[index].model:Destroy()
            table.remove(traps, index)
        end
    end
end)

RunService.Heartbeat:Connect(function(dt)
    dt = math.min(dt, 0.1)
    local ok, err = pcall(stepEggs, dt)
    if not ok then warn("[EggBoss] eggs: " .. tostring(err)) end
    for n, b in pairs(bosses) do
        local good, why = pcall(stepBoss, n, b, dt)
        if not good then
            warn("[EggBoss] boss " .. tostring(n) .. ": " .. tostring(why))
            if b.hold then pcall(releaseHeld, b.hold) end
            b.hold = nil
            b.state = "returning"
        end
    end
    local fine, msg = pcall(stepTraps)
    if not fine then warn("[EggBoss] traps: " .. tostring(msg)) end
end)

local n = 0; for _ in pairs(eggs) do n = n + 1 end
print(string.format("[EggBoss] %d eggs, %d bosses", n, Cfg.ZONES))