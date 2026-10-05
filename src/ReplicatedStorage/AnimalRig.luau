local Rig = {}

local WING = { wing = true, membrane = true, patagium = true, primary = true, secondary = true,
               covert = true, pinion = true, remige = true }
local TAIL = { tail = true, rattle = true, stinger = true }
local TAIL_END = { fluke = true }
local HEAD = { head = true, skull = true, muzzle = true, nose = true, nostril = true, bill = true, beak = true,
               snout = true, brow = true, cheek = true, chin = true, ear = true, jaw = true, mandible = true,
               mouth = true, lip = true, tongue = true, tooth = true, teeth = true, fang = true, whisker = true,
               glint = true, pupil = true, iris = true, sclera = true, eyeball = true, eyelid = true, lid = true,
               face = true, antenna = true, clypeus = true }
local HEAD_NEAR = { neck = true, nape = true, mane = true, crest = true, crown = true, tuft = true,
                    socket = true, forelock = true, stalk = true, comb = true, wattle = true, horn = true,
                    antler = true, tine = true, tusk = true, casque = true, mask = true, beard = true,
                    trunk = true, frill = true, lure = true, lantern = true }
local LEG = { leg = true, thigh = true, shin = true, knee = true, femur = true, tibia = true, tarsus = true,
              coxa = true, shank = true, haunch = true, hock = true, ankle = true, foreleg = true,
              hindleg = true, flipper = true }
local LEG_END = { foot = true, toe = true, claw = true, paw = true, talon = true, hoof = true, heel = true,
                  sole = true, spur = true, pad = true, sock = true, forefoot = true, hindfoot = true,
                  toeclaw = true }
local ARM = { arm = true, forearm = true, upperarm = true, hand = true, finger = true, wrist = true,
              elbow = true, fist = true, pincer = true, humerus = true, spar = true, knuckle = true,
              palm = true }

local SIDE_L = { l = true, left = true, fl = true, bl = true }
local SIDE_R = { r = true, right = true, fr = true, br = true }
local END_F  = { front = true, fore = true, f = true, fl = true, fr = true }
local END_B  = { rear = true, hind = true, b = true, bl = true, br = true }

local SAMPLES = {
    leg  = { CFrame.Angles(0.55, 0, 0), CFrame.Angles(-0.55, 0, 0) },
    wing = { CFrame.Angles(0, 0, 0.9), CFrame.Angles(0, 0, -0.9) },
    tail = { CFrame.Angles(0, 0.28, 0), CFrame.Angles(0, -0.28, 0) },
    head = { CFrame.Angles(0.10, 0.35, 0), CFrame.Angles(0.10, -0.35, 0),
             CFrame.Angles(-0.10, 0.35, 0), CFrame.Angles(-0.10, -0.35, 0) },
}
local AMP_STEPS = { 1, 0.7, 0.5, 0.35, 0.25, 0.15, 0.08, 0 }

local PROBE = {}
for x = -1, 1 do
    for y = -1, 1 do
        for z = -1, 1 do
            PROBE[#PROBE + 1] = Vector3.new(x, y, z) * 0.5
        end
    end
end

local cache = {}

local function tokens(name)
    local spaced = name:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
    local t = {}
    for w in spaced:lower():gmatch("%a+") do t[w] = true end
    return t
end

local function any(tok, set)
    for word in pairs(tok) do
        if set[word] then return true end
    end
    return false
end

local function startsWith(tok, prefix)
    for word in pairs(tok) do
        if word:sub(1, #prefix) == prefix then return true end
    end
    return false
end

local function classify(name)
    local tok = tokens(name)
    if any(tok, WING) or startsWith(tok, "wing") then return "wing" end
    if any(tok, TAIL) or startsWith(tok, "tail") then return "tail" end
    if any(tok, HEAD) or startsWith(tok, "eye") then return "head" end
    if tok.tentacle then return "body" end
    if any(tok, LEG) then return "leg" end
    if any(tok, ARM) then return "arm" end
    if any(tok, LEG_END) then return "legEnd" end
    if any(tok, HEAD_NEAR) then return "headNear" end
    if any(tok, TAIL_END) then return "tailEnd" end
    if (any(tok, SIDE_L) or any(tok, SIDE_R)) and (any(tok, END_F) or any(tok, END_B)) then return "leg" end
    return "body"
end

local function extents(cf, sz)
    return Vector3.new(
        math.abs(cf.RightVector.X) * sz.X / 2 + math.abs(cf.UpVector.X) * sz.Y / 2 + math.abs(cf.LookVector.X) * sz.Z / 2,
        math.abs(cf.RightVector.Y) * sz.X / 2 + math.abs(cf.UpVector.Y) * sz.Y / 2 + math.abs(cf.LookVector.Y) * sz.Z / 2,
        math.abs(cf.RightVector.Z) * sz.X / 2 + math.abs(cf.UpVector.Z) * sz.Y / 2 + math.abs(cf.LookVector.Z) * sz.Z / 2)
end

local function pointGap(cf, sz, p)
    local l = cf:PointToObjectSpace(p)
    return Vector3.new(
        math.max(math.abs(l.X) - sz.X / 2, 0),
        math.max(math.abs(l.Y) - sz.Y / 2, 0),
        math.max(math.abs(l.Z) - sz.Z / 2, 0)).Magnitude
end

local function boxGap(cfA, szA, cfB, szB)
    local best = math.huge
    for _, v in ipairs(PROBE) do
        local d = pointGap(cfB, szB, cfA * (v * szA))
        if d < best then
            best = d
            if best <= 0 then return 0 end
        end
        d = pointGap(cfA, szA, cfB * (v * szB))
        if d < best then
            best = d
            if best <= 0 then return 0 end
        end
    end
    return best
end
Rig.boxGap = boxGap

local function about(hinge, rot)
    return CFrame.new(hinge) * rot * CFrame.new(-hinge)
end

local function limbTransform(limb, phase, t, w)
    if not limb or limb.amp <= 0 then return nil end
    local amp = limb.amp
    local rot
    if limb.kind == "leg" then
        if w <= 0 then return nil end
        rot = CFrame.Angles(math.sin(phase + limb.phase) * 0.55 * amp * w, 0, 0)
    elseif limb.kind == "wing" then
        local a = math.sin(t * 24) * 0.9 * w + math.sin(t * 2) * 0.12 * (1 - w)
        rot = CFrame.Angles(0, 0, a * amp * limb.dir)
    elseif limb.kind == "tail" then
        local a = math.sin(t * 5 + limb.phase) * w + math.sin(t * 2.2 + limb.phase) * (1 - w)
        rot = CFrame.Angles(0, a * 0.28 * amp, 0)
    else
        local look = math.sin(t * 0.55) * 0.35 * (1 - w)
        local nod = math.sin(phase + 0.8) * (0.04 + 0.06 * w)
        rot = CFrame.Angles(nod * amp, look * amp, 0)
    end
    return about(limb.hinge, rot)
end

local function identity(e, len)
    local p = e.offset.Position / len
    return ("%s|%d|%d|%d"):format(e.part.Name, math.floor(p.X * 200 + 0.5),
        math.floor(p.Y * 200 + 0.5), math.floor(p.Z * 200 + 0.5))
end

local function solve(rig)
    local parts = rig.parts
    local n = #parts
    local len = math.max(rig.length, 1e-3)
    local reach = math.max(len * 0.015, 0.01)
    local far = len * 0.06
    local tol = rig.width * 0.04

    local kind0, kind, lo, hi, vol = {}, {}, {}, {}, {}
    for i, e in ipairs(parts) do
        kind0[i] = classify(e.part.Name)
        kind[i] = "body"
        local h = extents(e.offset, e.part.Size)
        lo[i], hi[i] = e.offset.Position - h, e.offset.Position + h
        vol[i] = e.part.Size.X * e.part.Size.Y * e.part.Size.Z
    end

    local function near(i, j, r)
        return lo[i].X <= hi[j].X + r and lo[j].X <= hi[i].X + r
           and lo[i].Y <= hi[j].Y + r and lo[j].Y <= hi[i].Y + r
           and lo[i].Z <= hi[j].Z + r and lo[j].Z <= hi[i].Z + r
    end
    local function gapOf(i, j)
        return boxGap(parts[i].offset, parts[i].part.Size, parts[j].offset, parts[j].part.Size)
    end

    local adj = {}
    for i = 1, n do adj[i] = {} end
    for i = 1, n do
        for j = i + 1, n do
            if near(i, j, reach) and gapOf(i, j) <= reach then
                adj[i][#adj[i] + 1] = j
                adj[j][#adj[j] + 1] = i
            end
        end
    end

    local function components(filter)
        local seen, out = {}, {}
        for i = 1, n do
            if not seen[i] and filter(i) then
                local list, stack = {}, { i }
                seen[i] = true
                while #stack > 0 do
                    local k = table.remove(stack)
                    list[#list + 1] = k
                    for _, j in ipairs(adj[k]) do
                        if not seen[j] and filter(j) then
                            seen[j] = true
                            stack[#stack + 1] = j
                        end
                    end
                end
                out[#out + 1] = list
            end
        end
        return out
    end

    local function centroidOf(list)
        local s = Vector3.zero
        for _, i in ipairs(list) do s += parts[i].offset.Position end
        return s / #list
    end

    local headParts = components(function(i) return kind0[i] == "head" end)
    local main, mainVol = nil, -1
    for _, c in ipairs(headParts) do
        local v = 0
        for _, i in ipairs(c) do v += vol[i] end
        if v > mainVol then main, mainVol = c, v end
    end
    if main then
        local mc = centroidOf(main)
        for _, c in ipairs(headParts) do
            if c == main or (centroidOf(c) - mc).Magnitude <= len * 0.3 then
                for _, i in ipairs(c) do kind[i] = "head" end
            end
        end
        local stack = {}
        for i = 1, n do
            if kind[i] == "head" then stack[#stack + 1] = i end
        end
        while #stack > 0 do
            local k = table.remove(stack)
            for _, j in ipairs(adj[k]) do
                if kind[j] == "body" and (kind0[j] == "headNear" or kind0[j] == "head")
                   and (parts[j].offset.Position - mc).Magnitude <= len * 0.35 then
                    kind[j] = "head"
                    stack[#stack + 1] = j
                end
            end
        end
    end

    for i = 1, n do
        if kind[i] == "body" and kind0[i] == "wing" then kind[i] = "wing" end
    end
    do
        local stack = {}
        for i = 1, n do
            if kind[i] == "wing" then stack[#stack + 1] = i end
        end
        while #stack > 0 do
            local k = table.remove(stack)
            for _, j in ipairs(adj[k]) do
                if kind[j] == "body" and kind0[j] == "arm" then
                    kind[j] = "wing"
                    stack[#stack + 1] = j
                end
            end
        end
    end

    for _, c in ipairs(components(function(i)
        return kind[i] == "body" and (kind0[i] == "leg" or kind0[i] == "legEnd")
    end)) do
        local core = false
        local inC = {}
        for _, i in ipairs(c) do inC[i] = true end
        for _, i in ipairs(c) do
            if kind0[i] == "leg" then core = true break end
        end
        if not core then
            for _, i in ipairs(c) do
                for _, j in ipairs(adj[i]) do
                    if not inC[j] and kind[j] == "body" and kind0[j] ~= "arm" and kind0[j] ~= "legEnd" then
                        core = true
                        break
                    end
                end
                if core then break end
            end
        end
        if core then
            for _, i in ipairs(c) do kind[i] = "leg" end
        end
    end

    for _, c in ipairs(components(function(i)
        return kind[i] == "body" and (kind0[i] == "tail" or kind0[i] == "tailEnd")
    end)) do
        local core = false
        for _, i in ipairs(c) do
            if kind0[i] == "tail" then core = true break end
        end
        if core then
            for _, i in ipairs(c) do kind[i] = "tail" end
        end
    end

    local limbs = {}
    do
        local headList = {}
        for i = 1, n do
            if kind[i] == "head" then headList[#headList + 1] = i end
        end
        if #headList > 0 then limbs[#limbs + 1] = { kind = "head", members = headList } end
    end

    for _, k in ipairs({ "wing", "leg", "tail" }) do
        for _, c in ipairs(components(function(i) return kind[i] == k end)) do
            if k == "tail" then
                limbs[#limbs + 1] = { kind = k, members = c }
            else
                local side, pos, neg = {}, false, false
                for _, i in ipairs(c) do
                    local x = parts[i].offset.Position.X
                    side[i] = (x > tol and 1) or (x < -tol and -1) or 0
                    if side[i] > 0 then pos = true elseif side[i] < 0 then neg = true end
                end
                if pos and neg then
                    for _ = 1, 4 do
                        for _, i in ipairs(c) do
                            if side[i] == 0 then
                                local votes = 0
                                for _, j in ipairs(adj[i]) do
                                    if kind[j] == k and side[j] then votes += side[j] end
                                end
                                if votes ~= 0 then side[i] = votes > 0 and 1 or -1 end
                            end
                        end
                    end
                    local inside = {}
                    for _, i in ipairs(c) do
                        if side[i] == 0 then kind[i] = "body" else inside[i] = true end
                    end
                    for _, s in ipairs({ 1, -1 }) do
                        for _, sub in ipairs(components(function(i)
                            return inside[i] and kind[i] == k and side[i] == s
                        end)) do
                            limbs[#limbs + 1] = { kind = k, members = sub }
                        end
                    end
                else
                    limbs[#limbs + 1] = { kind = k, members = c }
                end
            end
        end
    end

    local limbOf = {}
    local function index()
        table.clear(limbOf)
        for li, l in ipairs(limbs) do
            for _, i in ipairs(l.members) do limbOf[i] = li end
        end
    end
    index()

    for li = #limbs, 1, -1 do
        local l = limbs[li]
        local inL = {}
        for _, i in ipairs(l.members) do inL[i] = true end
        local touches = false
        for _, i in ipairs(l.members) do
            for _, j in ipairs(adj[i]) do
                if not inL[j] then
                    touches = true
                    break
                end
            end
            if touches then break end
        end
        if not touches then
            local target, bestGap = nil, far
            for _, i in ipairs(l.members) do
                for j = 1, n do
                    if not inL[j] and near(i, j, far) then
                        local g = gapOf(i, j)
                        if g < bestGap then bestGap, target = g, j end
                    end
                end
            end
            local into = target and limbOf[target]
            if into and into ~= li then
                for _, i in ipairs(l.members) do
                    table.insert(limbs[into].members, i)
                    kind[i] = limbs[into].kind
                end
                table.remove(limbs, li)
                index()
            end
        end
    end

    local bodyComps = components(function(i) return not limbOf[i] end)
    local core, coreVol = nil, -1
    for _, c in ipairs(bodyComps) do
        local v = 0
        for _, i in ipairs(c) do v += vol[i] end
        if v > coreVol then core, coreVol = c, v end
    end
    for _, c in ipairs(bodyComps) do
        if c ~= core then
            local count = {}
            for _, i in ipairs(c) do
                for _, j in ipairs(adj[i]) do
                    local li = limbOf[j]
                    if li then count[li] = (count[li] or 0) + 1 end
                end
            end
            local best, bestN = nil, 0
            for li, cnt in pairs(count) do
                if cnt > bestN then best, bestN = li, cnt end
            end
            if not best then
                local inC = {}
                for _, i in ipairs(c) do inC[i] = true end
                local bestGap = far
                for _, i in ipairs(c) do
                    for j = 1, n do
                        if not inC[j] and near(i, j, far) then
                            local g = gapOf(i, j)
                            if g < bestGap then
                                bestGap = g
                                best = limbOf[j]
                            end
                        end
                    end
                end
            end
            if best then
                for _, i in ipairs(c) do
                    table.insert(limbs[best].members, i)
                    kind[i] = limbs[best].kind
                end
                index()
            end
        end
    end

    local function splitAlongZ(l)
        if l.kind ~= "leg" then return { l } end
        local inL = {}
        for _, i in ipairs(l.members) do inL[i] = true end
        local roots = {}
        for _, i in ipairs(l.members) do
            for _, j in ipairs(adj[i]) do
                if not inL[j] and not limbOf[j] then
                    roots[#roots + 1] = i
                    break
                end
            end
        end
        if #roots < 2 then return { l } end
        table.sort(roots, function(x, y) return parts[x].offset.Position.Z < parts[y].offset.Position.Z end)
        local group, groups = {}, 1
        group[roots[1]] = 1
        for r = 2, #roots do
            if parts[roots[r]].offset.Position.Z - parts[roots[r - 1]].offset.Position.Z > len * 0.12 then
                groups += 1
            end
            group[roots[r]] = groups
        end
        if groups < 2 then return { l } end
        local queue, head = {}, 1
        for _, r in ipairs(roots) do queue[#queue + 1] = r end
        while head <= #queue do
            local k = queue[head]
            head += 1
            for _, j in ipairs(adj[k]) do
                if inL[j] and not group[j] then
                    group[j] = group[k]
                    queue[#queue + 1] = j
                end
            end
        end
        local split = {}
        for g = 1, groups do split[g] = { kind = l.kind, members = {} } end
        for _, i in ipairs(l.members) do
            local g = group[i]
            if not g then
                local z, bestD = parts[i].offset.Position.Z, math.huge
                for _, r in ipairs(roots) do
                    local d = math.abs(parts[r].offset.Position.Z - z)
                    if d < bestD then bestD, g = d, group[r] end
                end
            end
            table.insert(split[g].members, i)
        end
        local of = {}
        for g, c in ipairs(split) do
            for _, i in ipairs(c.members) do of[i] = g end
        end
        local parent = {}
        for g = 1, groups do parent[g] = g end
        local function find(g)
            while parent[g] ~= g do g = parent[g] end
            return g
        end
        local function slot(i)
            local name = parts[i].part.Name
            local tok = tokens(name)
            local words = {}
            for _, w in ipairs({ "front", "fore", "mid", "middle", "rear", "hind", "back" }) do
                if tok[w] then words[#words + 1] = w end
            end
            return table.concat(words, "+") .. (name:match("%d+") or "")
        end
        local links = {}
        for _, i in ipairs(l.members) do
            for _, j in ipairs(adj[i]) do
                if inL[j] and i < j and of[i] ~= of[j] then
                    local x, y = math.min(of[i], of[j]), math.max(of[i], of[j])
                    local key = x * 1000 + y
                    links[key] = (links[key] or 0) + 1
                    local si, sj = slot(i), slot(j)
                    if links[key] >= 2 or si == "" or sj == "" or si == sj then
                        parent[find(y)] = find(x)
                    end
                end
            end
        end
        local merged = {}
        for g, c in ipairs(split) do
            local r = find(g)
            merged[r] = merged[r] or { kind = l.kind, members = {} }
            for _, i in ipairs(c.members) do table.insert(merged[r].members, i) end
        end
        local result = {}
        for g = 1, groups do
            if merged[g] and #merged[g].members > 0 then result[#result + 1] = merged[g] end
        end
        return result
    end

    do
        local splitLimbs = {}
        for _, l in ipairs(limbs) do
            for _, s in ipairs(splitAlongZ(l)) do splitLimbs[#splitLimbs + 1] = s end
        end
        limbs = splitLimbs
        index()
    end

    local bodyCentre = Vector3.zero
    do
        local cnt = 0
        for i = 1, n do
            if not limbOf[i] then
                bodyCentre += parts[i].offset.Position
                cnt += 1
            end
        end
        if cnt > 0 then bodyCentre /= cnt end
    end

    for _, l in ipairs(limbs) do
        l.contacts = {}
        local sum, cnt = Vector3.zero, 0
        for _, i in ipairs(l.members) do
            for _, j in ipairs(adj[i]) do
                if not limbOf[j] then
                    sum += (lo[i]:Max(lo[j]) + hi[i]:Min(hi[j])) / 2
                    cnt += 1
                    l.contacts[#l.contacts + 1] = { i = i, j = j }
                end
            end
        end
        if cnt == 0 then
            local bi, bj, bg = nil, nil, far
            for _, i in ipairs(l.members) do
                for j = 1, n do
                    if not limbOf[j] and near(i, j, far) then
                        local g = gapOf(i, j)
                        if g < bg then bi, bj, bg = i, j, g end
                    end
                end
            end
            if bi then
                sum = (lo[bi]:Max(lo[bj]) + hi[bi]:Min(hi[bj])) / 2
                cnt = 1
                l.contacts[1] = { i = bi, j = bj }
            end
        end
        l.centroid = centroidOf(l.members)
        if cnt > 0 then
            l.hinge = sum / cnt
        else
            local mn, mx = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)
            for _, i in ipairs(l.members) do
                mn = mn:Min(lo[i])
                mx = mx:Max(hi[i])
            end
            if l.kind == "leg" then
                l.hinge = Vector3.new((mn.X + mx.X) / 2, mx.Y, (mn.Z + mx.Z) / 2)
            else
                l.hinge = Vector3.new(math.clamp(bodyCentre.X, mn.X, mx.X), math.clamp(bodyCentre.Y, mn.Y, mx.Y),
                    math.clamp(bodyCentre.Z, mn.Z, mx.Z))
            end
        end
    end

    local groundY = math.huge
    for i = 1, n do groundY = math.min(groundY, lo[i].Y) end
    local dip = rig.height * 0.03
    local allowed = math.max(len * 0.015, 0.015)
    for _, l in ipairs(limbs) do
        local rest = {}
        for k, ct in ipairs(l.contacts) do rest[k] = gapOf(ct.i, ct.j) end
        l.amp = 0
        for _, amp in ipairs(AMP_STEPS) do
            local fits = true
            if amp > 0 then
                for _, s in ipairs(SAMPLES[l.kind]) do
                    local ax, ay, az = s:ToEulerAnglesXYZ()
                    local rot = about(l.hinge, CFrame.Angles(ax * amp, ay * amp, az * amp))
                    for k, ct in ipairs(l.contacts) do
                        local a, b = parts[ct.i], parts[ct.j]
                        if boxGap(rot * a.offset, a.part.Size, b.offset, b.part.Size) - rest[k] > allowed then
                            fits = false
                            break
                        end
                    end
                    if fits and (l.kind == "wing" or l.kind == "tail") then
                        for _, i in ipairs(l.members) do
                            local cf = rot * parts[i].offset
                            if cf.Position.Y - extents(cf, parts[i].part.Size).Y < groundY - dip then
                                fits = false
                                break
                            end
                        end
                    end
                    if not fits then break end
                end
            end
            if fits then
                l.amp = amp
                break
            end
        end
    end

    local legsBySide = { [1] = {}, [-1] = {} }
    local tails = {}
    for _, l in ipairs(limbs) do
        l.dir = l.centroid.X >= 0 and 1 or -1
        l.phase = 0
        if l.kind == "leg" then
            table.insert(legsBySide[l.dir], l)
        elseif l.kind == "tail" then
            table.insert(tails, l)
        end
    end
    for s, list in pairs(legsBySide) do
        table.sort(list, function(a, b) return a.centroid.Z < b.centroid.Z end)
        for rank, l in ipairs(list) do
            l.phase = ((rank - 1) % 2) * math.pi + (s < 0 and math.pi or 0)
        end
    end
    table.sort(tails, function(a, b) return a.centroid.Z < b.centroid.Z end)
    for rank, l in ipairs(tails) do l.phase = (rank - 1) * 0.6 end

    local plan = { keys = {}, byId = {}, limbs = {}, legs = 0 }
    for i = 1, n do plan.keys[i] = "body" end
    for li, l in ipairs(limbs) do
        local key = l.kind .. "#" .. li
        for _, i in ipairs(l.members) do plan.keys[i] = key end
        plan.limbs[key] = { hinge = l.hinge / len, kind = l.kind, amp = l.amp, dir = l.dir, phase = l.phase }
        if l.kind == "leg" then plan.legs += 1 end
    end
    for i, e in ipairs(parts) do plan.byId[identity(e, len)] = plan.keys[i] end
    return plan
end

function Rig.build(model)
    local pivot = model:GetPivot()
    local rig = { model = model, parts = {}, limbs = {}, height = 0, length = 0, width = 0 }

    local _, size = model:GetBoundingBox()
    rig.height = size.Y
    rig.length = math.max(size.X, size.Z)
    rig.width = size.X

    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            rig.parts[#rig.parts + 1] = { part = p, offset = pivot:ToObjectSpace(p.CFrame), key = "body", named = false }
        end
    end

    local len = math.max(rig.length, 1e-3)
    local signature = tostring(model:GetAttribute("Species") or model.Name) .. "|" .. #rig.parts
    local plan = cache[signature]
    local keys
    if plan then
        keys = {}
        for i, e in ipairs(rig.parts) do
            local k = plan.byId[identity(e, len)]
            if not k then
                keys = nil
                break
            end
            keys[i] = k
        end
    end
    if not keys then
        plan = solve(rig)
        cache[signature] = plan
        keys = plan.keys
    end

    for i, e in ipairs(rig.parts) do
        e.key = keys[i]
        e.named = e.key ~= "body"
    end
    for key, l in pairs(plan.limbs) do
        rig.limbs[key] = { hinge = l.hinge * len, kind = l.kind, amp = l.amp, dir = l.dir, phase = l.phase }
    end
    rig.legs = plan.legs
    rig.slither = plan.legs < 2

    local restLow = math.huge
    for _, e in ipairs(rig.parts) do
        restLow = math.min(restLow, e.offset.Position.Y - extents(e.offset, e.part.Size).Y)
    end
    local lowest = restLow
    for step = 0, 7 do
        local ph = step * math.pi / 4
        local t = step * 0.0655
        local body = CFrame.Angles(0, 0, math.sin(ph) * 0.05)
        for _, e in ipairs(rig.parts) do
            local s = limbTransform(rig.limbs[e.key], ph, t, 1)
            local cf = body * (s and (s * e.offset) or e.offset)
            lowest = math.min(lowest, cf.Position.Y - extents(cf, e.part.Size).Y)
        end
    end
    rig.lift = math.min(math.max(0, restLow - lowest), rig.height * 0.04)
    rig.shift = {}
    rig.moveParts = {}
    rig.moveCFrames = {}
    return rig
end

function Rig.pose(rig, cf, phase, t, moving)
    local last = rig.lastT
    local dt = last and math.clamp(t - last, 0, 0.25) or 1
    rig.lastT = t
    local target = moving and 1 or 0
    local w = rig.walk or target
    w += (target - w) * math.min(dt * 5, 1)
    rig.walk = w

    local bobAmp = rig.height * (0.012 + 0.018 * w)
    local wave = (math.sin(phase * 2) * w + math.sin(phase + t * 1.6) * (1 - w)) * 0.5 + 0.5
    local roll = math.sin(phase) * (0.015 + 0.035 * w)
    local body = CFrame.new(0, wave * bobAmp + (rig.lift or 0), 0) * CFrame.Angles(0, 0, roll)
    if rig.slither then
        body = body * CFrame.Angles(0, math.sin(phase * 0.8) * 0.18, 0)
    end
    local base = cf * body

    local shift = rig.shift
    for key, limb in pairs(rig.limbs) do
        shift[key] = limbTransform(limb, phase, t, w) or false
    end

    local list, cfs = rig.moveParts, rig.moveCFrames
    for i, e in ipairs(rig.parts) do
        local s = shift[e.key]
        list[i] = e.part
        cfs[i] = base * (s and (s * e.offset) or e.offset)
    end
    if rig.model:IsDescendantOf(workspace) then
        workspace:BulkMoveTo(list, cfs, Enum.BulkMoveMode.FireCFrameChanged)
    else
        for i, p in ipairs(list) do p.CFrame = cfs[i] end
    end
end

return Rig