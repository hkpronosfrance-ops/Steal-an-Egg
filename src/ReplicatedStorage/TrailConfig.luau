local T = {}

local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

T.LIST = {
    { id = "White",  name = "White Trail",  rarity = "Common",    mult = 1.5, price = 5e3,
      image = "rbxassetid://95792408360324",
      colors = { rgb(255, 255, 255), rgb(190, 202, 224) }, card = rgb(206, 214, 230) },

    { id = "Green",  name = "Green Trail",  rarity = "Uncommon",  mult = 2,   price = 75e3,
      image = "rbxassetid://117573494630490",
      colors = { rgb(120, 255, 120), rgb(20, 190, 60) }, card = rgb(38, 206, 64) },

    { id = "Blue",   name = "Blue Trail",   rarity = "Rare",      mult = 2.5, price = 2e6,
      image = "rbxassetid://101853909396981",
      colors = { rgb(110, 214, 255), rgb(24, 110, 255) }, card = rgb(36, 140, 250) },

    { id = "Purple", name = "Purple Trail", rarity = "Epic",      mult = 3,   price = 150e6,
      image = "rbxassetid://97867270071868",
      colors = { rgb(222, 140, 255), rgb(130, 40, 230) }, card = rgb(154, 66, 238) },

    { id = "Golden", name = "Golden Trail", rarity = "Legendary", mult = 3.5, price = 20e9,
      image = "rbxassetid://127572461156203",
      colors = { rgb(255, 240, 130), rgb(255, 176, 20) }, card = rgb(250, 190, 24) },

    { id = "Orange", name = "Orange Trail", rarity = "Mythic",    mult = 4,   price = 3e12,
      image = "rbxassetid://77313313562002",
      colors = { rgb(255, 196, 100), rgb(255, 104, 16) }, card = rgb(252, 124, 26) },

    { id = "Red",    name = "Red Trail",    rarity = "Divine",    mult = 5,   price = 300e12,
      image = "rbxassetid://91183899041921",
      colors = { rgb(255, 120, 120), rgb(214, 18, 30) }, card = rgb(222, 38, 46) },
}

T.RARITY = {
    Common    = rgb(196, 204, 218),
    Uncommon  = rgb(112, 255, 104),
    Rare      = rgb(92, 196, 255),
    Epic      = rgb(214, 132, 255),
    Legendary = rgb(255, 216, 64),
    Mythic    = rgb(255, 150, 48),
    Divine    = rgb(255, 78, 88),
}

T.VISUAL = {
    top = 1.9,
    bottom = -2.7,
    back = 0.45,
    lifetime = 0.6,
    lightEmission = 0.25,
}

local Money = require(script.Parent:WaitForChild("MonetizationConfig"))
local byId = {}
for i, t in ipairs(T.LIST) do
    t.order = i
    local m = Money.TRAILS[t.id] or {}
    t.productId = tonumber(m.productId) or 0
    t.robux = tonumber(m.price) or 0
    byId[t.id] = t
end

function T.byId(id)
    return byId[id]
end

function T.fmtMult(m)
    return ("x%g"):format(m)
end

return T