local Paint = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

Paint.PALETTE = {

    ["Fox"]           = { base = rgb(214,110, 48), belly = rgb(245,238,228), dark = rgb( 48, 40, 40), accent = rgb(255,255,255) },
    ["Rabbit"]        = { base = rgb(168,150,136), belly = rgb(246,242,236), dark = rgb( 92, 80, 74), accent = rgb(236,168,176) },
    ["Fawn"]          = { base = rgb(176,124, 74), belly = rgb(238,224,206), dark = rgb( 58, 44, 36), accent = rgb(255,255,255) },
    ["Hedgehog"]      = { base = rgb(128,104, 84), belly = rgb(214,186,150), dark = rgb( 54, 44, 38), accent = rgb(240,220,190) },
    ["Owl"]           = { base = rgb(150,118, 86), belly = rgb(232,214,186), dark = rgb( 52, 44, 38), accent = rgb(246,196, 74) },
    ["Squirrel"]      = { base = rgb(176, 96, 52), belly = rgb(238,226,208), dark = rgb( 60, 46, 38), accent = rgb(206,140, 88) },
    ["Wild Boar"]     = { base = rgb( 96, 80, 72), belly = rgb(128,110, 98), dark = rgb( 44, 38, 34), accent = rgb(232,226,214) },
    ["Badger"]        = { base = rgb( 86, 86, 90), belly = rgb(238,236,232), dark = rgb( 32, 32, 34), accent = rgb(255,255,255) },

    ["Duck"]          = { base = rgb(238,232,220), belly = rgb(250,248,242), dark = rgb( 72, 66, 60), accent = rgb(246,178, 52) },
    ["Frog"]          = { base = rgb(104,180, 84), belly = rgb(222,232,180), dark = rgb( 44, 64, 36), accent = rgb( 72,140, 60) },
    ["Turtle"]        = { base = rgb( 96,140, 88), belly = rgb(206,190,140), dark = rgb( 52, 72, 44), accent = rgb(120, 96, 58) },
    ["Otter"]         = { base = rgb(118, 86, 62), belly = rgb(206,186,160), dark = rgb( 54, 42, 34), accent = rgb(150,120, 92) },
    ["Koi Carp"]      = { base = rgb(244,244,240), belly = rgb(250,250,248), dark = rgb( 60, 56, 54), accent = rgb(232, 96, 52) },
    ["Heron"]         = { base = rgb(196,204,212), belly = rgb(238,242,246), dark = rgb( 54, 58, 64), accent = rgb(246,196, 74) },
    ["Beaver"]        = { base = rgb(124, 88, 60), belly = rgb(168,132,100), dark = rgb( 52, 40, 30), accent = rgb( 96, 72, 52) },
    ["Dragonfly"]     = { base = rgb( 72,170,196), belly = rgb(120,204,222), dark = rgb( 36, 54, 66), accent = rgb(168,232,244) },

    ["Camel"]         = { base = rgb(206,170,116), belly = rgb(232,212,178), dark = rgb( 86, 68, 48), accent = rgb(176,138, 88) },
    ["Fennec Fox"]    = { base = rgb(226,198,150), belly = rgb(246,238,224), dark = rgb( 62, 52, 44), accent = rgb(240,220,190) },
    ["Scorpion"]      = { base = rgb(168,116, 52), belly = rgb(196,152, 88), dark = rgb( 58, 40, 24), accent = rgb(232,180, 90) },
    ["Horned Lizard"] = { base = rgb(178,140, 96), belly = rgb(222,198,160), dark = rgb( 72, 56, 40), accent = rgb(132,100, 68) },
    ["Meerkat"]       = { base = rgb(196,166,124), belly = rgb(230,212,182), dark = rgb( 58, 48, 40), accent = rgb( 92, 76, 62) },
    ["Vulture"]       = { base = rgb( 72, 66, 64), belly = rgb(108,100, 96), dark = rgb( 32, 30, 30), accent = rgb(218,168,120) },
    ["Rattlesnake"]   = { base = rgb(176,150,102), belly = rgb(222,206,170), dark = rgb( 66, 54, 38), accent = rgb(120, 98, 62) },
    ["Jerboa"]        = { base = rgb(222,196,150), belly = rgb(246,238,224), dark = rgb( 62, 52, 44), accent = rgb(240,224,196) },

    ["Monkey"]          = { base = rgb(150,104, 62), belly = rgb(222,190,150), dark = rgb( 58, 42, 30), accent = rgb(240,196,150) },
    ["Parrot"]          = { base = rgb( 60,180, 80), belly = rgb(240,230,120), dark = rgb( 46, 40, 40), accent = rgb(240, 90, 60) },
    ["Tree Frog"]       = { base = rgb( 96,206, 86), belly = rgb(238,240,180), dark = rgb( 40, 60, 34), accent = rgb(240,140, 60) },
    ["Panther"]         = { base = rgb( 44, 42, 56), belly = rgb( 66, 64, 80), dark = rgb( 22, 20, 28), accent = rgb(226,210, 90) },
    ["Toucan"]          = { base = rgb( 36, 36, 44), belly = rgb(250,248,240), dark = rgb( 20, 20, 26), accent = rgb(250,180, 40) },
    ["Sloth"]           = { base = rgb(156,138,110), belly = rgb(206,190,164), dark = rgb( 64, 56, 46), accent = rgb(232,220,196) },
    ["Gorilla"]         = { base = rgb( 58, 56, 64), belly = rgb( 92, 88, 96), dark = rgb( 28, 26, 32), accent = rgb(150,120, 96) },
    ["Chameleon"]       = { base = rgb(110,200, 90), belly = rgb(200,226,150), dark = rgb( 44, 62, 38), accent = rgb(240,200, 70) },

    ["Penguin"]         = { base = rgb( 40, 44, 58), belly = rgb(248,250,252), dark = rgb( 22, 24, 32), accent = rgb(250,186, 52) },
    ["Polar Bear Cub"]  = { base = rgb(242,246,250), belly = rgb(252,253,255), dark = rgb( 56, 60, 70), accent = rgb(216,226,236) },
    ["Arctic Fox"]      = { base = rgb(238,244,250), belly = rgb(252,253,255), dark = rgb( 58, 64, 74), accent = rgb(206,220,234) },
    ["Seal Pup"]        = { base = rgb(216,224,234), belly = rgb(244,248,252), dark = rgb( 44, 48, 58), accent = rgb(180,192,206) },
    ["Snowy Owl"]       = { base = rgb(246,248,252), belly = rgb(252,253,255), dark = rgb( 52, 56, 66), accent = rgb(250,200, 60) },
    ["Reindeer"]        = { base = rgb(150,112, 78), belly = rgb(216,196,170), dark = rgb( 56, 44, 34), accent = rgb(222,206,180) },
    ["Walrus"]          = { base = rgb(168,132,124), belly = rgb(206,178,170), dark = rgb( 58, 44, 42), accent = rgb(244,238,224) },

    ["Fire Salamander"] = { base = rgb( 44, 40, 46), belly = rgb( 72, 62, 66), dark = rgb( 24, 20, 24), accent = rgb(255,120, 40) },
    ["Magma Slug"]      = { base = rgb( 52, 46, 50), belly = rgb(255,140, 50), dark = rgb( 28, 24, 28), accent = rgb(255,196, 70) },
    ["Ash Crow"]        = { base = rgb( 56, 54, 62), belly = rgb( 86, 82, 92), dark = rgb( 28, 26, 32), accent = rgb(240,110, 50) },
    ["Obsidian Beetle"] = { base = rgb( 36, 34, 44), belly = rgb( 60, 56, 70), dark = rgb( 18, 16, 22), accent = rgb(120, 90,200) },
    ["Lava Toad"]       = { base = rgb( 60, 50, 48), belly = rgb(255,150, 60), dark = rgb( 30, 24, 24), accent = rgb(255,200, 80) },
    ["Ember Bat"]       = { base = rgb( 48, 42, 48), belly = rgb( 76, 64, 70), dark = rgb( 24, 20, 24), accent = rgb(255,130, 60) },
    ["Cinder Ram"]      = { base = rgb( 66, 58, 58), belly = rgb(100, 88, 86), dark = rgb( 32, 28, 28), accent = rgb(255,160, 60) },
    ["Flame Lizard"]    = { base = rgb(196, 72, 36), belly = rgb(240,170, 90), dark = rgb( 60, 28, 18), accent = rgb(255,214, 90) },

    ["Anglerfish"]      = { base = rgb( 44, 52, 74), belly = rgb( 70, 80,104), dark = rgb( 20, 24, 36), accent = rgb(180,255,220) },
    ["Jellyfish"]       = { base = rgb(140,120,220), belly = rgb(200,190,246), dark = rgb( 52, 44, 80), accent = rgb(230,220,255) },
    ["Octopus"]         = { base = rgb(176, 72,120), belly = rgb(226,150,180), dark = rgb( 60, 26, 44), accent = rgb(250,200,220) },
    ["Deep Sea Crab"]   = { base = rgb(196, 64, 58), belly = rgb(232,140,120), dark = rgb( 66, 22, 20), accent = rgb(250,196,150) },
    ["Moray Eel"]       = { base = rgb( 86,132, 96), belly = rgb(170,200,150), dark = rgb( 32, 50, 36), accent = rgb(222,236,180) },
    ["Manta Ray"]       = { base = rgb( 52, 68, 96), belly = rgb(216,226,238), dark = rgb( 24, 30, 44), accent = rgb(120,150,190) },
    ["Nautilus"]        = { base = rgb(232,214,180), belly = rgb(248,240,222), dark = rgb( 86, 66, 44), accent = rgb(198,120, 70) },

    ["Triceratops"]     = { base = rgb(124,146,110), belly = rgb(176,190,150), dark = rgb( 48, 56, 42), accent = rgb(222,214,190) },
    ["Stegosaurus"]     = { base = rgb(110,132,150), belly = rgb(164,182,196), dark = rgb( 42, 50, 58), accent = rgb(226,140, 70) },
    ["Raptor"]          = { base = rgb(156,120, 80), belly = rgb(208,186,150), dark = rgb( 58, 44, 30), accent = rgb(226, 96, 60) },
    ["Pterodactyl"]     = { base = rgb(140,116,140), belly = rgb(196,178,192), dark = rgb( 52, 42, 52), accent = rgb(232,180, 90) },
    ["Mammoth"]         = { base = rgb(128, 84, 58), belly = rgb(172,128, 96), dark = rgb( 48, 32, 22), accent = rgb(244,236,214) },
    ["Sabertooth Cat"]  = { base = rgb(196,152, 88), belly = rgb(232,208,170), dark = rgb( 64, 48, 30), accent = rgb(250,246,236) },
    ["Ankylosaurus"]    = { base = rgb(122,120, 96), belly = rgb(166,164,136), dark = rgb( 46, 44, 36), accent = rgb(200,190,160) },
    ["Brontosaurus"]    = { base = rgb(108,140,120), belly = rgb(158,188,164), dark = rgb( 40, 54, 46), accent = rgb(196,214,196) },

    ["Star Cat"]        = { base = rgb(108, 92,196), belly = rgb(170,158,236), dark = rgb( 36, 28, 72), accent = rgb(255,232,120) },
    ["Comet Whale"]     = { base = rgb( 72, 96,190), belly = rgb(140,170,236), dark = rgb( 24, 34, 76), accent = rgb(180,230,255) },
    ["Moon Rabbit"]     = { base = rgb(226,230,246), belly = rgb(248,250,255), dark = rgb( 60, 62, 86), accent = rgb(196,204,236) },
    ["Nebula Jellyfish"]= { base = rgb(168, 84,206), belly = rgb(222,160,246), dark = rgb( 54, 24, 72), accent = rgb(120,236,255) },
    ["Satellite Owl"]   = { base = rgb( 86,102,146), belly = rgb(150,168,206), dark = rgb( 30, 36, 56), accent = rgb(120,236,255) },
    ["Meteor Beetle"]   = { base = rgb( 96, 72, 64), belly = rgb(140,110, 96), dark = rgb( 36, 26, 22), accent = rgb(255,148, 60) },
    ["Galaxy Fox"]      = { base = rgb( 94, 66,168), belly = rgb(156,130,220), dark = rgb( 30, 20, 60), accent = rgb(255,214,120) },
    ["Alien Blob"]      = { base = rgb(110,220,140), belly = rgb(176,246,190), dark = rgb( 30, 70, 44), accent = rgb(230,255,200) },

    ["Sakura Deer"]     = { base = rgb(222,166,176), belly = rgb(250,232,236), dark = rgb( 74, 46, 52), accent = rgb(250,206,216) },
    ["Sakura Koi"]      = { base = rgb(250,246,244), belly = rgb(252,250,250), dark = rgb( 60, 52, 54), accent = rgb(240,110,120) },
    ["Crane"]           = { base = rgb(248,248,250), belly = rgb(252,252,254), dark = rgb( 48, 46, 52), accent = rgb(226, 60, 70) },
    ["Red Panda"]       = { base = rgb(198,102, 58), belly = rgb( 60, 46, 40), dark = rgb( 36, 26, 22), accent = rgb(248,240,230) },
    ["Tanuki"]          = { base = rgb(146,124,102), belly = rgb(212,196,176), dark = rgb( 52, 42, 34), accent = rgb( 60, 52, 46) },
    ["Butterfly"]       = { base = rgb(244,140,180), belly = rgb(250,200,220), dark = rgb( 56, 32, 44), accent = rgb(255,236,150) },
    ["Songbird"]        = { base = rgb(236,168, 72), belly = rgb(250,226,180), dark = rgb( 56, 40, 22), accent = rgb(226, 88, 72) },
    ["Blossom Cat"]     = { base = rgb(244,206,214), belly = rgb(252,240,244), dark = rgb( 66, 44, 50), accent = rgb(236,120,150) },

    ["Stone Golem"]     = { base = rgb(146,142,132), belly = rgb(180,176,166), dark = rgb( 56, 54, 50), accent = rgb(110,196,150) },
    ["Bronze Scarab"]   = { base = rgb(186,124, 58), belly = rgb(222,176,110), dark = rgb( 62, 40, 18), accent = rgb(240,206,120) },
    ["Marble Owl"]      = { base = rgb(238,236,230), belly = rgb(250,249,246), dark = rgb( 72, 70, 66), accent = rgb(198,194,186) },
    ["Clay Serpent"]    = { base = rgb(188,116, 78), belly = rgb(226,176,140), dark = rgb( 66, 38, 24), accent = rgb(110,196,150) },
    ["Granite Ape"]     = { base = rgb(128,126,130), belly = rgb(166,164,168), dark = rgb( 48, 46, 50), accent = rgb(196,194,198) },
    ["Jade Tortoise"]   = { base = rgb( 86,168,126), belly = rgb(150,212,180), dark = rgb( 30, 60, 44), accent = rgb(216,240,226) },
    ["Obelisk Beetle"]  = { base = rgb(108,104,120), belly = rgb(146,142,160), dark = rgb( 40, 38, 46), accent = rgb(232,196,110) },

    ["One Eyed Blob"]   = { base = rgb(140, 72,186), belly = rgb(186,126,220), dark = rgb( 44, 20, 60), accent = rgb(250,240,120) },
    ["Horned Imp"]      = { base = rgb(206, 64, 72), belly = rgb(238,140,140), dark = rgb( 66, 18, 22), accent = rgb(250,220,180) },
    ["Shadow Hound"]    = { base = rgb( 48, 44, 62), belly = rgb( 76, 70, 94), dark = rgb( 22, 20, 30), accent = rgb(196, 80,220) },
    ["Slime Cube"]      = { base = rgb(110,220,120), belly = rgb(170,244,176), dark = rgb( 32, 72, 36), accent = rgb(230,255,220) },
    ["Bat Demon"]       = { base = rgb( 78, 44, 96), belly = rgb(124, 80,146), dark = rgb( 28, 14, 36), accent = rgb(226, 80, 90) },
    ["Spike Worm"]      = { base = rgb(156, 96, 72), belly = rgb(200,146,116), dark = rgb( 52, 30, 22), accent = rgb(236,214,180) },
    ["Ghost Wisp"]      = { base = rgb(176,206,236), belly = rgb(220,236,250), dark = rgb( 52, 64, 84), accent = rgb(250,252,255) },
    ["Tentacle Beast"]  = { base = rgb( 92, 56,132), belly = rgb(140, 96,180), dark = rgb( 30, 16, 46), accent = rgb(220,120,236) },

    ["Arctic Hare"]     = { base = rgb(240,246,252), belly = rgb(252,253,255), dark = rgb( 56, 62, 72), accent = rgb(236,180,190) },
    ["Lanternfish"]     = { base = rgb( 48, 56, 80), belly = rgb( 76, 86,116), dark = rgb( 20, 24, 36), accent = rgb(200,255,230) },
    ["Guardian Lion"]   = { base = rgb(196,166,110), belly = rgb(226,204,160), dark = rgb( 72, 58, 36), accent = rgb(110,196,150) },
}

Paint.EYE_COLOR = {
    ["Owl"]              = rgb(246,196, 74),
    ["Snowy Owl"]        = rgb(250,200, 60),
    ["Marble Owl"]       = rgb(240,196, 90),
    ["Satellite Owl"]    = rgb(150,230,255),
    ["Frog"]             = rgb(236,206, 80),
    ["Tree Frog"]        = rgb(232, 70, 50),
    ["Lava Toad"]        = rgb(255,170, 60),
    ["Raptor"]           = rgb(236,196, 70),
    ["Panther"]          = rgb(226,210, 90),
    ["Horned Imp"]       = rgb(255,214, 90),
    ["Ash Crow"]         = rgb(240,110, 50),
    ["Octopus"]          = rgb(246,236,206),
    ["Nebula Jellyfish"] = rgb(200,240,255),
}

local PUPIL_COLOR = rgb(20, 18, 22)
local SCLERA_COLOR = rgb(248, 248, 244)
local GLINT_COLOR = rgb(255, 255, 255)
local DARK_BODY = 0.22

local function luminance(c)
    return 0.2126 * c.R + 0.7152 * c.G + 0.0722 * c.B
end

local EYE_WORDS = { "eye", "pupil", "iris", "sclera", "glint", "highlight" }
local NOT_EYEBALL = { "socket", "patch", "lid", "brow", "lash", "stalk", "turret", "ring", "star",
                      "glint", "spark", "shine", "highlight" }

local function hasWord(n, list)
    for _, k in ipairs(list) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

function Paint.eyeFlags(model)
    local f = { hasPupil = false, hasIris = false, hasEyePart = false, hasSclera = false }
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local n = p.Name:lower()
            if n:find("pupil", 1, true) then f.hasPupil = true end
            if n:find("iris", 1, true) then f.hasIris = true end
            if n:find("sclera", 1, true) or n:find("white", 1, true) or n:find("eyeball", 1, true) then f.hasSclera = true end
            if (n:find("eye", 1, true) or n:find("sclera", 1, true))
               and not n:find("pupil", 1, true) and not n:find("iris", 1, true)
               and not hasWord(n, NOT_EYEBALL) then
                f.hasEyePart = true
            end
        end
    end
    return f
end

function Paint.eyeRole(name, f)
    local n = name:lower()
    if not hasWord(n, EYE_WORDS) then
        if n:find("socket", 1, true) and f.hasPupil and not f.hasEyePart then return "sclera" end
        return nil
    end
    if n:find("glint", 1, true) or n:find("highlight", 1, true)
       or ((n:find("spark", 1, true) or n:find("shine", 1, true)) and n:find("eye", 1, true)) then
        return "glint"
    end
    if n:find("lid", 1, true) or n:find("brow", 1, true) or n:find("lash", 1, true) then return nil end
    if n:find("patch", 1, true) then return "patch" end
    if n:find("socket", 1, true) then
        if f.hasEyePart then return "base" end
        return f.hasPupil and "sclera" or "bead"
    end
    if n:find("stalk", 1, true) or n:find("turret", 1, true) then return "base" end
    if n:find("ring", 1, true) or n:find("star", 1, true) then return "accent" end
    if n:find("pupil", 1, true) then return "pupil" end
    if n:find("iris", 1, true) then return f.hasPupil and "iris" or "pupil" end
    if n:find("white", 1, true) or n:find("sclera", 1, true) or n:find("eyeball", 1, true) then return "sclera" end
    return (f.hasPupil or f.hasIris) and "sclera" or "bead"
end

local DEFAULT = { base = rgb(170,150,130), belly = rgb(226,216,200), dark = rgb(60, 52, 46), accent = rgb(230,200,150) }

Paint.TIER = {
    [1] = { tint = nil,                 amount = 0.00, glow = false },
    [2] = { tint = rgb(150, 230, 160),  amount = 0.14, glow = false },
    [3] = { tint = rgb(120, 180, 246),  amount = 0.20, glow = false },
    [4] = { tint = rgb(250, 205, 110),  amount = 0.24, glow = true  },
}

local function words(name)    local spaced = name:gsub("(%l)(%u)", "%1 %2"):gsub("(%u)(%u%l)", "%1 %2")
    local t = {}
    for w in spaced:lower():gmatch("%a+") do t[w] = true end
    return t
end

local function anyOf(tok, list)
    for _, k in ipairs(list) do
        if tok[k] then return true end
    end
    return false
end

local EYE    = { "eye", "pupil" }
local GLINT  = { "glint", "shine", "sparkle" }
local BEAK   = { "bill", "beak", "nose", "nostril" }
local BELLY  = { "belly", "chest", "bib", "breast", "throat", "underside", "under", "plastron" }
local FOOT   = { "foot", "paw", "hoof", "claw", "toe", "sock", "pad", "talon", "hock" }
local INNER  = { "inner", "tuft" }
local ACCENT = { "tip", "horn", "tusk", "antler", "crest", "mane", "shell", "carapace",
                 "elytra", "rattle", "stinger", "spot", "stripe",

                 "patch", "marking", "ember", "flame", "magma", "lava", "glow", "vent" }

local WHITE  = { "white", "sclera", "eyeball" }
local TOOTH  = { "tooth", "teeth", "fang", "tusk" }

local GLOW_MAX_SHARE = 0.12

local STUDS_IMAGE = "rbxassetid://138926013267839"
local STUDS_ALPHA = 0.35
local STUDS_PER_BODY = 12
local FACES = Enum.NormalId:GetEnumItems()

local STUD_FLAT_MIN = 0.8

local function clearStuds(part)
    for _, c in ipairs(part:GetChildren()) do
        if c:IsA("Texture") and c.Name == "Studs" then c:Destroy() end
    end
end

local function addStuds(part, tile)
    for _, face in ipairs(FACES) do
        local t = Instance.new("Texture")
        t.Name = "Studs"
        t.Texture = STUDS_IMAGE
        t.Face = face
        t.StudsPerTileU = tile
        t.StudsPerTileV = tile
        t.Transparency = STUDS_ALPHA
        t.Parent = part
    end
end

local COPLANAR_TOL = 0.003
local COPLANAR_GAP = 0.005
local COPLANAR_EDGE = 0.002
local COPLANAR_MAX = 0.01

local function boxFaces(p)
    local cf, s = p.CFrame, p.Size
    local ax = { { cf.RightVector, s.X / 2 }, { cf.UpVector, s.Y / 2 }, { cf.LookVector, s.Z / 2 } }
    local list = {}
    for i = 1, 3 do
        local j, k = (i % 3) + 1, ((i + 1) % 3) + 1
        for _, sg in ipairs({ 1, -1 }) do
            list[#list + 1] = {
                part = p, n = ax[i][1] * sg, c = cf.Position + ax[i][1] * (ax[i][2] * sg),
                u = ax[j][1], hu = ax[j][2], v = ax[k][1], hv = ax[k][2],
                area = ax[j][2] * ax[k][2],
            }
        end
    end
    return list
end

function Paint.separateCoplanar(model)
    local okBox, _, box = pcall(model.GetBoundingBox, model)
    if not (okBox and box) then return 0 end
    local span = math.max(box.X, box.Y, box.Z)
    local tol, gap = span * COPLANAR_TOL, span * COPLANAR_GAP
    local edge, maxMove = span * COPLANAR_EDGE, span * COPLANAR_MAX
    local faces = {}
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") and p.Transparency < 0.9 then
            for _, f in ipairs(boxFaces(p)) do faces[#faces + 1] = f end
        end
    end
    local shift = {}
    for a = 1, #faces do
        local fa = faces[a]
        for b = a + 1, #faces do
            local fb = faces[b]
            if fa.part ~= fb.part and fa.n:Dot(fb.n) > 0.999 then
                local d = fb.c - fa.c
                local off = fa.n:Dot(d)
                if math.abs(off) < tol then
                    local du, dv = d:Dot(fa.u), d:Dot(fa.v)
                    local eu = math.abs(fb.u:Dot(fa.u)) * fb.hu + math.abs(fb.v:Dot(fa.u)) * fb.hv
                    local ev = math.abs(fb.u:Dot(fa.v)) * fb.hu + math.abs(fb.v:Dot(fa.v)) * fb.hv
                    if math.abs(du) < fa.hu + eu - edge and math.abs(dv) < fa.hv + ev - edge then

                        local small, rel
                        if fb.area <= fa.area then small, rel = fb, off else small, rel = fa, -off end
                        local front = math.abs(rel) < 0.001 or rel > 0
                        local target = front and gap or -gap
                        shift[small.part] = (shift[small.part] or Vector3.zero) + small.n * (target - rel)
                    end
                end
            end
        end
    end
    local moved = 0
    for part, v in pairs(shift) do
        if v.Magnitude > maxMove then v = v.Unit * maxMove end
        part.CFrame = part.CFrame + v
        moved += 1
    end
    return moved
end

local HEAD  = { "head" }
local EYES  = { "eye", "pupil" }
local SNOUT = { "nose", "snout", "muzzle", "beak", "bill", "mouth", "jaw" }
local TAILS = { "tail" }

local function centroid(parts, list)
    local sum, n = Vector3.zero, 0
    for _, p in ipairs(parts) do
        if p:IsA("BasePart") then
            local hit = list == nil
            if not hit then
                local name = p.Name:lower()
                for _, k in ipairs(list) do
                    if name:find(k, 1, true) then hit = true break end
                end
            end
            if hit then
                sum += p.Position
                n += 1
            end
        end
    end
    return n > 0 and sum / n or nil
end

function Paint.frontDir(parts, up)
    up = up or Vector3.yAxis
    local front = centroid(parts, EYES) or centroid(parts, SNOUT) or centroid(parts, HEAD)
    local back = centroid(parts, TAILS) or centroid(parts)
    if not (front and back) then return nil end
    local d = front - back
    d -= up * d:Dot(up)
    if d.Magnitude < 1e-3 then return nil end
    return d.Unit
end

function Paint.previewEye(front, up)
    up = up or Vector3.yAxis
    return (front + front:Cross(up) * 0.55 + up * 0.3).Unit
end

function Paint.pivotOf(source)
    if typeof(source) ~= "Instance" then return nil end
    if source:IsA("Tool") then
        local handle = source:FindFirstChild("Handle")
        local offset = handle and handle:GetAttribute("PivotOffset")
        if typeof(offset) == "CFrame" then return handle.CFrame * offset end
        return nil
    end
    if source:IsA("Model") then return source:GetPivot() end
    return nil
end

function Paint.viewDir(parts, source)
    local pivot = Paint.pivotOf(source)
    if pivot then
        return Paint.previewEye(pivot.LookVector, pivot.UpVector), pivot.UpVector
    end
    local front = Paint.frontDir(parts)
    if not front then return nil end
    return Paint.previewEye(front), Vector3.yAxis
end

function Paint.studs(model, perBody, skip)
    local ok, _, box = pcall(model.GetBoundingBox, model)
    if not (ok and box) then return 0 end
    Paint.separateCoplanar(model)
    local tile = math.clamp(math.max(box.X, box.Y, box.Z) / (perBody or STUDS_PER_BODY), 0.08, 6)
    local n = 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            clearStuds(p)
            local tok = words(p.Name)
            if p.Material ~= Enum.Material.Neon and p.Transparency < 0.9
               and not anyOf(tok, EYE) and not anyOf(tok, GLINT)
               and not (skip and skip(p))
               and math.max(p.Size.X, p.Size.Y, p.Size.Z) >= tile * 0.5
               and (tonumber(p:GetAttribute("StudFlat")) or 1) >= STUD_FLAT_MIN then
                addStuds(p, tile)
                n += 1
            end
        end
    end
    return n
end

function Paint.warm(c)
    local h, s, v = c:ToHSV()
    if s < 0.18 then
        if v > 0.9 then return Color3.fromHSV(0.1, math.min(0.06, s + 0.03), v) end
        return Color3.fromHSV(0.085, math.max(s, 0.08 + (1 - v) * 0.1), math.min(1, 0.06 + v * 0.96))
    end
    if v < 0.2 then v = 0.14 + v * 0.5 end
    return Color3.fromHSV(h, math.min(0.92, s * 1.08), v)
end

function Paint.paint(model, tier, opts)
    local species = model:GetAttribute("Species") or model.Name

    if not (opts and opts.preview) then Paint.separateCoplanar(model) end

    local tile = 0
    if model:IsA("Model") then
        local ok, _, box = pcall(model.GetBoundingBox, model)
        if ok and box then
            tile = math.clamp(math.max(box.X, box.Y, box.Z) / STUDS_PER_BODY, 0.08, 4)
        end
    end
    local pal = Paint.PALETTE[species] or DEFAULT
    local rule = Paint.TIER[tier or 1] or Paint.TIER[1]

    local function shade(c)
        if rule.tint and rule.amount > 0 then
            c = c:Lerp(rule.tint, rule.amount)
        end
        return Paint.warm(c)
    end

    local eyeFlags = Paint.eyeFlags(model)
    local eyeTint = Paint.EYE_COLOR[species]
    local darkBody = luminance(pal.base) < DARK_BODY
    local totalVolume = 0
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then totalVolume += p.Size.X * p.Size.Y * p.Size.Z end
    end

    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("BasePart") then
            local tok = words(p.Name)
            local colour, neon = pal.base, false

            local role = Paint.eyeRole(p.Name, eyeFlags)
            local eyePart = role ~= nil and role ~= "base" and role ~= "accent" and role ~= "patch"

            local addedGlint = p.Name:sub(1, 6) == "glint_"
            if role == "glint" then
                colour = (darkBody and addedGlint and not eyeFlags.hasPupil) and PUPIL_COLOR or GLINT_COLOR
            elseif role == "bead" and darkBody and not eyeFlags.hasSclera then
                local hasOwnGlint = p.Parent and p.Parent:FindFirstChild("glint_" .. p.Name) ~= nil
                if hasOwnGlint then
                    colour = eyeTint or SCLERA_COLOR
                else
                    colour = luminance(pal.accent) > 0.35 and pal.accent or SCLERA_COLOR
                end
            elseif role == "pupil" or role == "bead" then
                colour = PUPIL_COLOR
            elseif role == "sclera" then
                colour = eyeTint or SCLERA_COLOR
            elseif role == "iris" then
                colour = eyeTint or pal.accent
            elseif role == "patch" then
                colour = pal.dark
            elseif role == "accent" then
                colour = pal.accent
            elseif role == "base" then
                colour = pal.base
            elseif anyOf(tok, TOOTH) then
                colour = rgb(242, 238, 226)
            elseif anyOf(tok, BEAK) then
                colour = pal.accent
            elseif anyOf(tok, FOOT) and not tok.whisker then
                colour = pal.dark
            elseif anyOf(tok, BELLY) or tok.whisker then
                colour = pal.belly
            elseif anyOf(tok, INNER) then
                colour = pal.belly
            elseif anyOf(tok, ACCENT) then
                colour = pal.accent
                neon = rule.glow and (p.Size.X * p.Size.Y * p.Size.Z) <= totalVolume * GLOW_MAX_SHARE
            end

            p.Color = eyePart and colour or shade(colour)

            p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic

            clearStuds(p)
            if tile > 0 and not neon and not (role and role ~= "base" and role ~= "accent")
               and math.max(p.Size.X, p.Size.Y, p.Size.Z) >= tile * 0.5
               and (tonumber(p:GetAttribute("StudFlat")) or 1) >= STUD_FLAT_MIN then
                addStuds(p, tile)
            end
        end
    end
end

return Paint