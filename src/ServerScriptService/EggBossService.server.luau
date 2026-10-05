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
        return