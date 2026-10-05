local RS = game:GetService("ReplicatedStorage")
local Cfg = require(RS:WaitForChild("EggConfig"))

local S = {}

S.PET_SECONDS = 100
S.EGG_SECONDS = 40

S.ICON = {
    arrow = "rbxassetid://71395997585045",
    check = "rbxassetid://92741034901562",
    cross = "rbxassetid://128851784429012",
    cash  = "rbxassetid://83304389878447",
    egg   = "rbxassetid://103180943014941",
    paw   = "rbxassetid://107687993847196",
}

function S.price(kind, zone, tier, size, luck)
    local income = Cfg.petIncome(zone or 1, size or 1, tier or 1, luck)
    local seconds = (kind == "Eggs") and S.EGG_SECONDS or S.PET_SECONDS
    return math.floor(income * seconds)
end

return S