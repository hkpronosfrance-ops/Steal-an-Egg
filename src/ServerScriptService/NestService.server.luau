local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Cfg = require(RS:WaitForChild("EggConfig"))
local Paint = require(RS:WaitForChild("AnimalPaint"))

local map = workspace:WaitForChild("GameWorld")
local pens = map:WaitForChild("SpawnPens")

local Remotes = RS:WaitForChild("Remotes")
local remote = Remotes:FindFirstChild("Nest")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Nest"
    remote.Parent = Remotes
end

local placed = map:FindFirstChild("PlacedEggs")
if not placed then
    placed = Instance.new("Folder")
    placed.Name = "PlacedEggs"
    placed.Parent = map
end

local animals = map:FindFirstChild("PlacedAnimals")
if not animals then
    animals = Instance.new("Folder")
    animals.Name = "PlacedAnimals"
    animals.Parent = map
end

local UpgradeCfg = require(RS:WaitForChild("UpgradeConfig"))
local PLOT_MAX_LEVEL = UpgradeCfg.MAX_LEVEL

local function upgradePrice(level)
    return UpgradeCfg.price("PEN", level)
end

local HttpService = game:GetService("HttpService")
local function newKey()
    return HttpService:GenerateGUID(false)
end

local function animalCap(pen)
    return UpgradeCfg.petCap(pen:GetAttribute("PlotLevel"))
end

local Money = require(RS:WaitForChild("MonetizationConfig"))
local restored = {}
local function waitRestored(plr)
    for _ = 1, 150 do
        if restored[plr] or not plr.Parent then return end
        task.wait(0.2)
    end
end
local SKIP_PRODUCT_ID = tonumber(Money.NEST.SkipGrowth.productId) or 0
local GROW_ALL_PRODUCT_ID = tonumber(Money.NEST.GrowAll.productId) or 0

local FENCE_INSET = 5
local MIN_GAP = 4
local DISPLAY_H = 2.6
local PROMPT_RANGE = 14

local rects = {}
local function measure(pen)
    local sign = pen:FindFirstChild("Sign")
    local lo = Vector3.new(1e9, 1e9, 1e9)
    local hi = Vector3.new(-1e9, -1e9, -1e9)
    for _, p in ipairs(pen:GetDescendants()) do
        if p:IsA("BasePart") and not (sign and p:IsDescendantOf(sign)) then
            lo = lo:Min(p.Position - p.Size / 2)
            hi = hi:Max(p.Position + p.Size / 2)
        end
    end
    rects[pen] = {
        minX = lo.X + FENCE_INSET, maxX = hi.X - FENCE_INSET,
        minZ = lo.Z + FENCE_INSET, maxZ = hi.Z - FENCE_INSET,
        floorY = lo.Y,
    }
end
for _, pen in ipairs(pens:GetChildren()) do
    measure(pen)
    pen:GetAttributeChangedSignal("PlotLevel"):Connect(function()
        task.defer(measure, pen)
        task.delay(0.5, measure, pen)
    end)
end

local lastMeasure = 0
local function penAt(pos)
    if os.clock() - lastMeasure > 2 then
        lastMeasure = os.clock()
        for _, pen in ipairs(pens:GetChildren()) do measure(pen) end
    end
    for pen, r in pairs(rects) do
        if pos.X >= r.minX and pos.X <= r.maxX and pos.Z >= r.minZ and pos.Z <= r.maxZ then
            return pen, r
        end
    end
    return nil
end

local function penOf(plr)
    for _, pen in ipairs(pens:GetChildren()) do
        if pen:GetAttribute("OwnerUserId") == plr.UserId then return pen end
    end
    return nil
end

local function penFrame(pen)
    local r = rects[pen]
    if not r then return nil end
    return (r.minX + r.maxX) / 2, (r.minZ + r.maxZ) / 2,
           (r.maxX - r.minX) / 2, (r.maxZ - r.minZ) / 2
end

local function eggListOf(plr)
    local Profile = _G.Profile
    local prof = Profile and Profile.get(plr)
    if not prof then return nil end
    if type(prof.NestEggs) ~= "table" then prof.NestEggs = {} end
    return prof.NestEggs
end

local function takeFromInventory(plr, zone, tier, size, species, luck)
    local Profile = _G.Profile
    local prof = Profile and Profile.get(plr)
    local inv = prof and prof.Eggs
    if type(inv) ~= "table" then return end
    for i = #inv, 1, -1 do
        local e = inv[i]

        if e.z == zone and e.t == tier and e.s == size and e.sp == species and e.lk == luck then
            table.remove(inv, i)
            return true
        end
    end
end

local function rememberEgg(plr, pen, pos, zone, tier, size, readyAt, species, luck)
    local list = eggListOf(plr)
    if not list then return end
    local cx, cz, hx, hz = penFrame(pen)
    if not cx then return end
    local key = newKey()
    list[#list + 1] = {
        key = key,
        zone = zone, tier = tier, size = size, ready = readyAt,
        species = species, luck = luck,
        u = math.clamp((pos.X - cx) / math.max(1, hx), -0.95, 0.95),
        v = math.clamp((pos.Z - cz) / math.max(1, hz), -0.95, 0.95),
    }
    return key
end

local function eggRecordOf(list, model)
    if not list or not model then return nil end
    local key = model:GetAttribute("EggKey")
    if key then
        for i, e in ipairs(list) do
            if e.key == key then return e, i end
        end
        return nil
    end
    local zone, tier, size = model:GetAttribute("EggZone"), model:GetAttribute("EggTier"), model:GetAttribute("EggSize")
    local epoch = tonumber(model:GetAttribute("ReadyEpoch")) or 0
    for i = #list, 1, -1 do
        local e = list[i]
        if e.zone == zone and e.tier == tier and e.size == size and math.abs((e.ready or 0) - epoch) < 2 then
            return e, i
        end
    end
    return nil
end

local function animalListOf(plr)
    local Profile = _G.Profile
    local prof = Profile and Profile.get(plr)
    if not prof then return nil end
    if type(prof.NestAnimals) ~= "table" then prof.NestAnimals = {} end
    return prof.NestAnimals
end

local function rememberAnimal(plr, pen, pos, zone, tier, size, species, luck)
    local list = animalListOf(plr)
    if not list then return end
    local cx, cz, hx, hz = penFrame(pen)
    if not cx then return end
    local key = newKey()
    list[#list + 1] = {
        key = key,
        zone = zone, tier = tier, size = size, species = species, luck = luck,
        u = math.clamp((pos.X - cx) / math.max(1, hx), -0.95, 0.95),
        v = math.clamp((pos.Z - cz) / math.max(1, hz), -0.95, 0.95),
    }
    return key
end

local function petInventoryOf(plr)
    local Profile = _G.Profile
    local prof = Profile and Profile.get(plr)
    if not prof then return nil end
    if type(prof.PetInventory) ~= "table" then prof.PetInventory = {} end
    return prof.PetInventory
end

local function forgetByKey(list, key)
    if not (list and key and key ~= "") then return false end
    for i = #list, 1, -1 do
        if list[i].key == key then
            table.remove(list, i)
            return true
        end
    end
    return false
end

local function forgetEgg(plr, zone, tier, size, readyAt, key)
    local list = eggListOf(plr)
    if not list then return end
    if key then
        for i = #list, 1, -1 do
            if list[i].key == key then
                table.remove(list, i)
                return
            end
        end
        return
    end
    for i = #list, 1, -1 do
        local e = list[i]
        if e.zone == zone and e.tier == tier and e.size == size
           and math.abs((e.ready or 0) - readyAt) < 2 then
            table.remove(list, i)
            return
        end
    end
end

local function deny(plr, text)
    remote:FireClient(plr, "deny", text)
end

local function heldEgg(plr)
    local ch = plr.Character
    if not ch then return nil end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("EggZone") then return t end
    end
    return nil
end

local function buildDisplay(tool, size)
    local handle = tool:FindFirstChild("Handle")
    if not handle then return nil end

    local model = Instance.new("Model")
    local root
    for _, p in ipairs(tool:GetDescendants()) do
        if p:IsA("BasePart") then
            local c = p:Clone()
            c:ClearAllChildren()
            c.Anchored = true
            c.CanCollide = false
            c.CanQuery = (p == handle)
            c.Massless = true
            c.CastShadow = false

            c.CFrame = handle.CFrame:ToObjectSpace(p.CFrame)
            c.Parent = model
            if p == handle then root = c end
        end
    end
    if not root then model:Destroy() return nil end
    model.PrimaryPart = root

    local scale = Cfg.SIZES[size] and Cfg.SIZES[size].scale or 1
    local _, box = model:GetBoundingBox()
    if box.Y > 0.001 then
        model:ScaleTo(model:GetScale() * (DISPLAY_H * math.sqrt(scale) / box.Y))
    end
    return model
end

local function tooClose(pos)
    for _, egg in ipairs(placed:GetChildren()) do
        local pp = egg.PrimaryPart
        if pp then
            local d = (Vector3.new(pp.Position.X, 0, pp.Position.Z) - Vector3.new(pos.X, 0, pos.Z)).Magnitude
            if d < MIN_GAP then return true end
        end
    end
    return false
end

local hatchPrompt

local function placeEgg(plr, pos)
    if typeof(pos) ~= "Vector3" then return end

    local tool = heldEgg(plr)
    if not tool then
        deny(plr, "Hold an egg first")
        return
    end

    local pen = penAt(pos)
    if not pen then
        deny(plr, "You can only place eggs on your own plot")
        return
    end
    if pen:GetAttribute("OwnerUserId") ~= plr.UserId then
        deny(plr, "This isn't your plot")
        return
    end
    if tooClose(pos) then
        deny(plr, "Too close to another egg")
        return
    end

    local zone = tool:GetAttribute("EggZone") or 1
    local tier = tool:GetAttribute("EggTier") or 1
    local size = tool:GetAttribute("EggSize") or 1
    local species = tool:GetAttribute("EggSpecies")
    local luck = tool:GetAttribute("EggLuck")

    local model = buildDisplay(tool, size)
    if not model then return end
    model.Name = tool.Name

    local r = rects[pen]
    local _, box = model:GetBoundingBox()
    local ground = r and r.floorY or pos.Y
    model:PivotTo(CFrame.new(pos.X, ground + box.Y / 2, pos.Z))
    model.Parent = placed

    model:SetAttribute("OwnerUserId", plr.UserId)
    model:SetAttribute("EggZone", zone)
    model:SetAttribute("EggTier", tier)
    model:SetAttribute("EggSize", size)
    if species then model:SetAttribute("EggSpecies", species) end
    if luck then model:SetAttribute("EggLuck", luck) end
    model:SetAttribute("Ready", false)

    local growth = math.max(1, tonumber(plr:GetAttribute("GrowthMult")) or 1)
        * (_G.GlobalBoost and _G.GlobalBoost.value("hatch") or 1)
    local wait = Cfg.hatchTime(zone, size, tier) / growth
    model:SetAttribute("HatchAt", workspace:GetServerTimeNow() + wait)
    model:SetAttribute("HatchTotal", wait)

    local readyAt = os.time() + wait
    model:SetAttribute("ReadyEpoch", readyAt)
    model:SetAttribute("EggKey", rememberEgg(plr, pen, pos, zone, tier, size, readyAt, species, luck))
    takeFromInventory(plr, zone, tier, size, species, luck)

    hatchPrompt(model)
    tool:Destroy()
end

local eggAssets = game:GetService("ServerStorage"):FindFirstChild("EggAssets")
local eggSet = eggAssets and eggAssets:FindFirstChild("Eggs")

local function eggTemplate(zone)
    if not eggSet then return nil end
    return eggSet:FindFirstChild("Zone" .. zone) or eggSet:FindFirstChild("Default")
end

local AnimalEggs = require(script.Parent:WaitForChild("AnimalEggs"))

local function buildFromTemplate(zone, tier, size, species)
    local speciesTpl = AnimalEggs.template(species)
    local tpl = speciesTpl or eggTemplate(zone)
    if not tpl then return nil end
    local m = tpl:Clone()

    local colour = Cfg.eggColor(zone, tier)
    local accent = Color3.new(colour.R * 0.68, colour.G * 0.68, colour.B * 0.68)
    local glow = Cfg.GLOW[tier] or Cfg.GLOW[1]
    local root
    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            local isShell = p.Name:lower():match("^shell") ~= nil
            if not speciesTpl then
                p.Color = isShell and colour or (glow.deco and colour or accent)
                p.Material = ((isShell and glow.shell) or (not isShell and glow.deco))
                    and Enum.Material.Neon or Enum.Material.SmoothPlastic
            end
            p.Anchored = true
            p.CanCollide = false
            p.CanQuery = isShell
            p.Massless = true
            p.CastShadow = false
            if isShell and not root then root = p end
        end
    end
    if not root then
        for _, p in ipairs(m:GetDescendants()) do
            if p:IsA("BasePart") then root = p break end
        end
    end
    if not root then m:Destroy() return nil end
    m.PrimaryPart = root

    local scale = Cfg.SIZES[size] and Cfg.SIZES[size].scale or 1
    local _, box = m:GetBoundingBox()
    if box.Y > 0.001 then
        m:ScaleTo(m:GetScale() * (DISPLAY_H * math.sqrt(scale) / box.Y))
    end
    return m
end

local function restoreEggs(plr)
    local list = eggListOf(plr)
    if not list or #list == 0 then return 0 end
    local pen = penOf(plr)
    if not pen then return 0 end
    local cx, cz, hx, hz = penFrame(pen)
    if not cx then return 0 end
    local r = rects[pen]
    local now = os.time()
    local built = 0

    for _, e in ipairs(list) do
        if e.species == nil then e.species = AnimalEggs.legacy(e.zone or 1, e.tier or 1, e.size or 1) end
        local m = buildFromTemplate(e.zone or 1, e.tier or 1, e.size or 1, e.species)
        if m then
            e.key = e.key or newKey()
            m:SetAttribute("EggKey", e.key)
            m.Name = ("%s %s %s Egg"):format(
                e.species or Cfg.NAMES[e.zone] or ("Zone" .. tostring(e.zone)),
                Cfg.TIERS[e.tier] and Cfg.TIERS[e.tier].name or "Common",
                Cfg.SIZES[e.size] and Cfg.SIZES[e.size].name or "Normal")
            local x = cx + (e.u or 0) * hx
            local z = cz + (e.v or 0) * hz
            local _, box = m:GetBoundingBox()
            m:PivotTo(CFrame.new(x, (r and r.floorY or 0) + box.Y / 2, z))
            m.Parent = placed

            m:SetAttribute("OwnerUserId", plr.UserId)
            m:SetAttribute("EggZone", e.zone)
            m:SetAttribute("EggTier", e.tier)
            m:SetAttribute("EggSize", e.size)
            if e.species then m:SetAttribute("EggSpecies", e.species) end
            if e.luck then m:SetAttribute("EggLuck", e.luck) end
            m:SetAttribute("ReadyEpoch", e.ready or now)

            local left = math.max(0, (e.ready or now) - now)
            m:SetAttribute("HatchAt", workspace:GetServerTimeNow() + left)
            m:SetAttribute("HatchTotal", math.max(left, Cfg.hatchTime(e.zone or 1, e.size or 1, e.tier or 1)))
            m:SetAttribute("Ready", false)
            hatchPrompt(m)
            built += 1
        end
    end
    return built
end

local function ball(parent, size, colour, cf, name)
    local p = Instance.new("Part")
    p.Name = name
    p.Shape = Enum.PartType.Ball
    p.Size = size
    p.Color = colour
    p.Material = Enum.Material.SmoothPlastic
    p.Anchored = true
    p.CanCollide = false
    p.CanQuery = false
    p.CastShadow = false
    p.CFrame = cf
    p.Parent = parent
    return p
end

local function animalIndex(size, tier)
    if tier >= 3 then return 6 + (tier - 2) end
    return math.clamp(size, 1, 6)
end

local function animalTemplate(zone, tier, size, species)
    local folder = workspace:FindFirstChild("AnimalLibrary")
    folder = folder and (folder:FindFirstChild("Zone" .. zone) or folder:FindFirstChild("Default"))
    if folder then
        local list = folder:GetChildren()
        table.sort(list, function(a, b) return a.Name < b.Name end)
        if #list > 0 then

            local pick = species and folder:FindFirstChild(species)
            pick = pick or list[((animalIndex(size or 1, tier or 1) - 1) % #list) + 1]
            local copy = pick:Clone()

            Paint.paint(copy, tier or 1)
            return copy
        end
    end

    local colour = Cfg.eggColor(zone, tier)
    local dark = Color3.new(colour.R * 0.55, colour.G * 0.55, colour.B * 0.55)
    local m = Instance.new("Model")
    local body = ball(m, Vector3.new(2.2, 1.8, 2.8), colour, CFrame.new(0, 1.0, 0), "Handle")
    body.CanQuery = true
    m.PrimaryPart = body
    ball(m, Vector3.new(1.5, 1.4, 1.4), colour, CFrame.new(0, 1.7, -1.2), "Head")
    ball(m, Vector3.new(0.32, 0.32, 0.32), Color3.new(0.05, 0.05, 0.05), CFrame.new(-0.38, 1.9, -1.75), "EyeL")
    ball(m, Vector3.new(0.32, 0.32, 0.32), Color3.new(0.05, 0.05, 0.05), CFrame.new(0.38, 1.9, -1.75), "EyeR")
    for _, dx in ipairs({ -0.7, 0.7 }) do
        for _, dz in ipairs({ -0.8, 0.9 }) do
            ball(m, Vector3.new(0.6, 0.7, 0.6), dark, CFrame.new(dx, 0.35, dz), "Leg")
        end
    end
    return m
end

local function speciesSlot(zone, species)
    local lib = workspace:FindFirstChild("AnimalLibrary")
    local folder = lib and lib:FindFirstChild("Zone" .. zone)
    if not (folder and species) then return nil end
    local list = folder:GetChildren()
    table.sort(list, function(a, b) return a.Name < b.Name end)
    for i, m in ipairs(list) do
        if m.Name == species then return i end
    end
    return nil
end

local function grantAnimal(plr, zone, tier, size, opts)
    opts = opts or {}
    local m = animalTemplate(zone, tier, size, opts.species)
    if not m then return nil end

    m:ScaleTo(m:GetScale() * ((Cfg.ANIMAL_SCALE and Cfg.ANIMAL_SCALE[size]) or 1))
    local ownPen = penOf(plr)
    local r = ownPen and rects[ownPen]
    if r then
        local _, box = m:GetBoundingBox()
        local longest = math.max(box.X, box.Z)
        local room = math.min(r.maxX - r.minX, r.maxZ - r.minZ) * (Cfg.ANIMAL_PEN_FILL or 0.8)
        if longest > room and longest > 0.01 then
            m:ScaleTo(m:GetScale() * (room / longest))
        end
    end

    if not opts.restoring and _G.PetIndex and _G.PetIndex.discover then
        pcall(_G.PetIndex.discover, plr, zone,
            speciesSlot(zone, opts.species) or animalIndex(size or 1, tier or 1))
    end

    local handle = m:FindFirstChild("Handle")
        or m:FindFirstChild(tostring(m:GetAttribute("RootPart")))
        or m:FindFirstChildWhichIsA("BasePart")
    if not handle then m:Destroy() return nil end
    local pivotOffset = handle.CFrame:ToObjectSpace(m:GetPivot())

    local tool = Instance.new("Tool")
    tool.Name = ("%s %s %s"):format(
        Cfg.NAMES[zone] or ("Zone" .. zone), Cfg.TIERS[tier].name, Cfg.SIZES[size].name)
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool:SetAttribute("AnimalZone", zone)
    tool:SetAttribute("AnimalTier", tier)
    tool:SetAttribute("AnimalSize", size)
    tool:SetAttribute("Species", m:GetAttribute("Species") or tool.Name)
    if opts.luck then tool:SetAttribute("Luck", opts.luck) end

    for _, p in ipairs(m:GetDescendants()) do
        if p:IsA("BasePart") then
            p.Anchored = false
            p.CanCollide = false
            p.Massless = true
        end
    end
    handle.Name = "Handle"

    handle:SetAttribute("RestOffset", CFrame.new())
    handle:SetAttribute("PivotOffset", pivotOffset)
    handle.Parent = tool
    for _, p in ipairs(m:GetChildren()) do
        if p:IsA("BasePart") then
            p:SetAttribute("RestOffset", handle.CFrame:ToObjectSpace(p.CFrame))
            local w = Instance.new("WeldConstraint")
            w.Part0 = handle
            w.Part1 = p
            w.Parent = handle
            p.Parent = tool
        end
    end
    m:Destroy()

    local key = opts.key or newKey()
    tool:SetAttribute("SaveKey", key)
    if not opts.restoring then
        local inv = petInventoryOf(plr)
        if inv then
            inv[#inv + 1] = { key = key, zone = zone, tier = tier, size = size,
                species = tool:GetAttribute("Species"), luck = opts.luck }
        end
    end

    tool.Parent = plr:FindFirstChildOfClass("Backpack") or plr.Backpack
    return tool
end

local function heldAnimal(plr)
    local ch = plr.Character
    if not ch then return nil end
    for _, t in ipairs(ch:GetChildren()) do
        if t:IsA("Tool") and t:GetAttribute("AnimalZone") then return t end
    end
    return nil
end

local function animalsIn(pen)
    local n = 0
    for _, a in ipairs(animals:GetChildren()) do
        if a:GetAttribute("Pen") == pen.Name then n = n + 1 end
    end
    return n
end

local pushPets

local function placeAnimal(plr, pos, forcedTool)
    if typeof(pos) ~= "Vector3" then return end
    local tool = forcedTool or heldAnimal(plr)
    if not tool then
        deny(plr, "Hold a pet first")
        return
    end
    local pen = penAt(pos)
    if not pen then
        deny(plr, "You can only place pets in your own pen")
        return
    end
    if pen:GetAttribute("OwnerUserId") ~= plr.UserId then
        deny(plr, "This isn't your plot")
        return
    end
    local cap = animalCap(pen)
    if animalsIn(pen) >= cap then
        deny(plr, ("Pen limit is %d pets"):format(cap))
        return
    end
    if tooClose(pos) then
        deny(plr, "Too close to another pet")
        return
    end

    local zone = tool:GetAttribute("AnimalZone") or 1
    local tier = tool:GetAttribute("AnimalTier") or 1
    local size = tool:GetAttribute("AnimalSize") or 1
    local species = tool:GetAttribute("Species")
    local luck = tool:GetAttribute("Luck")

    local m = animalTemplate(zone, tier, size, species)
    if not m then return end
    m.Name = tool.Name

    local scale = (Cfg.ANIMAL_SCALE and Cfg.ANIMAL_SCALE[size]) or 1
    m:ScaleTo(m:GetScale() * scale)

    local r = rects[pen]

    if r then
        local _, box = m:GetBoundingBox()
        local longest = math.max(box.X, box.Z)
        local room = math.min(r.maxX - r.minX, r.maxZ - r.minZ) * (Cfg.ANIMAL_PEN_FILL or 0.8)
        if longest > room and longest > 0.01 then
            m:ScaleTo(m:GetScale() * (room / longest))
        end
    end

    local ground = r and r.floorY or pos.Y
    m:PivotTo(CFrame.new(pos.X, ground, pos.Z))

    m:SetAttribute("OwnerUserId", plr.UserId)
    m:SetAttribute("Pen", pen.Name)
    m:SetAttribute("AnimalZone", zone)
    m:SetAttribute("AnimalTier", tier)
    m:SetAttribute("AnimalSize", size)
    m:SetAttribute("GroundY", ground)

    m:SetAttribute("Seed", math.random(1, 2 ^ 30))
    m:SetAttribute("SpawnAt", workspace:GetServerTimeNow())

    m:SetAttribute("Income", Cfg.petIncome(zone, size, tier, luck))
    if luck then m:SetAttribute("Luck", luck) end
    m:SetAttribute("Species", m:GetAttribute("Species") or m.Name)
    m:SetAttribute("Rarity", Cfg.TIERS[tier] and Cfg.TIERS[tier].name or "Common")

    m.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
    local key = rememberAnimal(plr, pen, pos, zone, tier, size, m:GetAttribute("Species"), luck)
    m:SetAttribute("SaveKey", key or "")
    m.Parent = animals
    pcall(function() m:AddPersistentPlayer(plr) end)
    forgetByKey(petInventoryOf(plr), tool:GetAttribute("SaveKey"))
    tool:Destroy()
    if pushPets then pushPets(plr) end
    return true
end

local PAYOUT_EVERY = Cfg.PET_PAYOUT_EVERY or 1.0

local owed = {}
Players.PlayerRemoving:Connect(function(plr) owed[plr] = nil end)
task.spawn(function()
    while true do
        task.wait(PAYOUT_EVERY)
        local Profile = _G.Profile
        if Profile then
            local sum = {}
            for _, a in ipairs(animals:GetChildren()) do
                local id = a:GetAttribute("OwnerUserId")
                local inc = tonumber(a:GetAttribute("Income")) or 0
                if id and id ~= 0 and inc > 0 then
                    sum[id] = (sum[id] or 0) + inc
                end
            end
            for _, plr in ipairs(Players:GetPlayers()) do
                local gain = sum[plr.UserId] and sum[plr.UserId] * PAYOUT_EVERY
                if gain then

                    gain = gain * math.max(1, tonumber(plr:GetAttribute("MoneyMult")) or 1)

                    gain = gain * (_G.GlobalBoost and _G.GlobalBoost.value("money") or 1)

                    owed[plr] = (owed[plr] or 0) + gain
                    local whole = math.floor(owed[plr])
                    if whole >= 1 then
                        owed[plr] -= whole
                        local have = Profile.value(plr, "wallet", "Coins") or 0
                        Profile.set(plr, "Coins", have + whole)
                    end
                end
            end
        end
    end
end)

local function wobble(model, seconds)
    if not model.PrimaryPart then return end
    local base = model:GetPivot()
    local t0 = os.clock()
    local last = t0
    local phase = 0
    while os.clock() - t0 < seconds do
        if not model.Parent then return end
        local now = os.clock()
        local k = (now - t0) / seconds
        local rate = 16 + 30 * k
        phase += rate * (now - last)
        last = now
        local tilt = math.sin(phase) * math.rad(5 + 18 * k)
        local hop = math.abs(math.sin(phase * 0.5)) * 0.22 * k
        model:PivotTo(base * CFrame.new(0, hop, 0) * CFrame.Angles(0, 0, tilt))
        task.wait()
    end
    if model.Parent then model:PivotTo(base) end
end

local function hatch(plr, model)
    local owner = model:GetAttribute("OwnerUserId")
    if owner ~= plr.UserId then
        deny(plr, "This isn't your egg")
        return
    end
    if not model:GetAttribute("Ready") then
        deny(plr, "This egg isn't ready yet")
        return
    end
    model:SetAttribute("Ready", false)
    local hatchZone = model:GetAttribute("EggZone") or 1
    local hatchTier = model:GetAttribute("EggTier") or 1
    local hatchSize = model:GetAttribute("EggSize") or 1
    local hatchEpoch = model:GetAttribute("ReadyEpoch") or 0
    local hatchKey = model:GetAttribute("EggKey")

    local zone = model:GetAttribute("EggZone") or 1
    local tier = model:GetAttribute("EggTier") or 1
    local size = model:GetAttribute("EggSize") or 1
    local species = model:GetAttribute("EggSpecies")
    local luck = model:GetAttribute("EggLuck")

    model:SetAttribute("Hatching", true)
    local pp = model.PrimaryPart
    local pr = pp and pp:FindFirstChild("Hatch")
    if pr then pr:Destroy() end
    local at = pp and pp.Position or Vector3.zero

    wobble(model, 1.1)
    if model.Parent then model:Destroy() end
    if not (plr.Parent and _G.Profile and _G.Profile.get(plr)) then return end
    forgetEgg(plr, hatchZone, hatchTier, hatchSize, hatchEpoch, hatchKey)

    remote:FireClient(plr, "hatched", {
        zone = zone, tier = tier, size = size, species = species,
        x = at.X, y = at.Y, z = at.Z,
    })
    grantAnimal(plr, zone, tier, size, { species = species, luck = luck })
end

local function ripenOne(plr, model)
    if not (model and model.Parent) or model:GetAttribute("Ready") or model:GetAttribute("Hatching") then
        return false
    end
    local unix = os.time()
    local list = eggListOf(plr)
    local rec = eggRecordOf(list, model)
    if rec then rec.ready = unix end
    model:SetAttribute("HatchAt", workspace:GetServerTimeNow())
    model:SetAttribute("ReadyEpoch", unix)
    return true
end

local pendingSkip = {}

local function grantSkip(plr)
    waitRestored(plr)
    local want = pendingSkip[plr]
    pendingSkip[plr] = nil
    if want and ripenOne(plr, want) then return true end
    local best, bestAt = nil, -math.huge
    for _, m in ipairs(placed:GetChildren()) do
        if m:GetAttribute("OwnerUserId") == plr.UserId and not m:GetAttribute("Ready")
           and not m:GetAttribute("Hatching") then
            local at = m:GetAttribute("HatchAt") or 0
            if at > bestAt then best, bestAt = m, at end
        end
    end
    if best then ripenOne(plr, best) end
    return true
end

local function skipGrowth(plr, model)
    if model:GetAttribute("OwnerUserId") ~= plr.UserId then
        deny(plr, "This isn't your egg")
        return
    end
    if model:GetAttribute("Ready") or model:GetAttribute("Hatching") then return end
    if SKIP_PRODUCT_ID > 0 then
        pendingSkip[plr] = model
        pcall(function()
            game:GetService("MarketplaceService"):PromptProductPurchase(plr, SKIP_PRODUCT_ID)
        end)
    elseif game:GetService("RunService"):IsStudio() and Money.STUDIO_TEST then
        ripenOne(plr, model)
        print(("[Nest] Skip Growth (Studio test) for %s"):format(plr.Name))
    else
        deny(plr, "Skip Growth - not available right now")
    end
end

local function growAllNow(plr)
    local n = 0
    for _, m in ipairs(placed:GetChildren()) do
        if m:GetAttribute("OwnerUserId") == plr.UserId and ripenOne(plr, m) then n += 1 end
    end
    return n
end

local function growAll(plr)
    local growing = 0
    for _, m in ipairs(placed:GetChildren()) do
        if m:GetAttribute("OwnerUserId") == plr.UserId and not m:GetAttribute("Ready")
           and not m:GetAttribute("Hatching") then
            growing += 1
        end
    end
    if growing == 0 then
        deny(plr, "No eggs are growing")
        return
    end
    if GROW_ALL_PRODUCT_ID > 0 then
        pcall(function()
            game:GetService("MarketplaceService"):PromptProductPurchase(plr, GROW_ALL_PRODUCT_ID)
        end)
    elseif game:GetService("RunService"):IsStudio() and Money.STUDIO_TEST then
        local n = growAllNow(plr)
        print(("[Nest] Grow All (Studio test) for %s: %d eggs"):format(plr.Name, n))
    else
        deny(plr, "Grow All - not available right now")
    end
end

task.spawn(function()
    for _ = 1, 200 do
        if _G.Purchases and _G.Purchases.register then break end
        task.wait(0.1)
    end
    if _G.Purchases and _G.Purchases.register then
        _G.Purchases.register("SkipGrowth", SKIP_PRODUCT_ID, grantSkip)
        _G.Purchases.register("GrowAll", GROW_ALL_PRODUCT_ID, function(plr)
            waitRestored(plr)
            growAllNow(plr)
            return true
        end)
    end
end)

Players.PlayerRemoving:Connect(function(plr) pendingSkip[plr] = nil restored[plr] = nil end)

local SKIP_TEXT = "Skip Growth!"

local function paintPrompt(pr, ready)
    pr.ObjectText = ready and "" or SKIP_TEXT
    pr.ActionText = ready and "Hatch" or SKIP_TEXT
end

function hatchPrompt(model)
    local pp = model.PrimaryPart
    if not pp then return end
    local pr = Instance.new("ProximityPrompt")
    pr.Name = "Hatch"
    pr.Style = Enum.ProximityPromptStyle.Custom
    pr:SetAttribute("EggPrompt", true)
    paintPrompt(pr, model:GetAttribute("Ready") == true)
    pr.KeyboardKeyCode = Enum.KeyCode.E
    pr.HoldDuration = 0
    pr.RequiresLineOfSight = false
    pr.MaxActivationDistance = PROMPT_RANGE
    pr.Enabled = true
    pr.Parent = pp
    pr.Triggered:Connect(function(plr)
        if model:GetAttribute("Ready") then
            hatch(plr, model)
        else
            skipGrowth(plr, model)
        end
    end)
end

local NightCycle=require(RS:WaitForChild("DayNightConfig"))
local nightRate=workspace:GetAttribute("CyclePhase")=="night" and NightCycle.NIGHT_HATCH_MULTIPLIER or 1
local nightTick=setmetatable({},{__mode="k"})
local function advanceNightEgg(model,now)
 local before=nightTick[model] or now
 nightTick[model]=now
 if model:GetAttribute("Ready") or model:GetAttribute("Hatching") then return end
 local at=tonumber(model:GetAttribute("HatchAt"))
 if not at or nightRate<=1 then return end
 local elapsed=math.max(0,now-before)
 local newAt=math.max(now,at-elapsed*(nightRate-1))
 if newAt==at then return end
 local oldEpoch=model:GetAttribute("ReadyEpoch")
 local newEpoch=(tonumber(oldEpoch) or os.time()+math.max(0,at-now))-(at-newAt)
 model:SetAttribute("HatchAt",newAt)
 model:SetAttribute("ReadyEpoch",newEpoch)
 local owner=Players:GetPlayerByUserId(model:GetAttribute("OwnerUserId") or 0)
 local list=owner and eggListOf(owner)
 if list then
  local record
  if model:GetAttribute("EggKey") then
   record=eggRecordOf(list,model)
  else
   for _,r in ipairs(list) do
    if r.ready==oldEpoch and r.zone==model:GetAttribute("EggZone")
     and r.size==model:GetAttribute("EggSize") and r.tier==model:GetAttribute("EggTier") then
     record=r break
    end
   end
  end
  if record then record.ready=newEpoch end
 end
end
placed.ChildAdded:Connect(function(model) nightTick[model]=workspace:GetServerTimeNow() end)
for _,model in placed:GetChildren() do nightTick[model]=workspace:GetServerTimeNow() end
workspace:GetAttributeChangedSignal("CyclePhase"):Connect(function()
 local now=workspace:GetServerTimeNow()
 for _,model in placed:GetChildren() do advanceNightEgg(model,now) end
 nightRate=workspace:GetAttribute("CyclePhase")=="night" and NightCycle.NIGHT_HATCH_MULTIPLIER or 1
end)

task.spawn(function()
    while true do
        task.wait(0.5)
        local now = workspace:GetServerTimeNow()
        for _, model in ipairs(placed:GetChildren()) do
            advanceNightEgg(model,now)
            if not model:GetAttribute("Hatching")
               and not model:GetAttribute("Ready")
               and (model:GetAttribute("HatchAt") or 0) <= now then
                model:SetAttribute("Ready", true)
                local pp = model.PrimaryPart
                local pr = pp and pp:FindFirstChild("Hatch")
                if pr then paintPrompt(pr, true) end
            end
        end
    end
end)

pushPets = function(plr)
    if not plr.Parent then return end
    local pen = penOf(plr)
    if not pen then return end
    local level = math.clamp(tonumber(pen:GetAttribute("PlotLevel")) or 1, 1, PLOT_MAX_LEVEL)
    remote:FireClient(plr, "pets", {
        count = animalsIn(pen), cap = animalCap(pen),
        level = level, maxLevel = PLOT_MAX_LEVEL,
        price = (level < PLOT_MAX_LEVEL) and upgradePrice(level) or 0,
    })
end

local function petToolsOf(plr)