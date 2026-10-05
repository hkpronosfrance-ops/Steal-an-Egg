local Players = game:GetService("Players")

local EVERY = 1

local function ensure(plr)
    local ls = plr:FindFirstChild("leaderstats")
    if not ls then
        ls = Instance.new("Folder")
        ls.Name = "leaderstats"
        ls.Parent = plr
    end
    local rate = ls:FindFirstChild("$/s")
    if not rate then
        rate = Instance.new("NumberValue")
        rate.Name = "$/s"
        rate.Parent = ls
    end
    local speed = ls:FindFirstChild("Speed")
    if not speed then
        speed = Instance.new("NumberValue")
        speed.Name = "Speed"
        speed.Parent = ls
    end
    return rate, speed
end

local function incomeByUser()
    local sum = {}
    local map = workspace:FindFirstChild("GameWorld")
    local folder = map and map:FindFirstChild("PlacedAnimals")
    for _, a in ipairs(folder and folder:GetChildren() or {}) do
        local id = a:GetAttribute("OwnerUserId")
        local inc = tonumber(a:GetAttribute("Income")) or 0
        if id and id ~= 0 and inc > 0 then
            sum[id] = (sum[id] or 0) + inc
        end
    end
    return sum
end

Players.PlayerAdded:Connect(ensure)
for _, plr in ipairs(Players:GetPlayers()) do ensure(plr) end

task.spawn(function()
    while true do
        local sum = incomeByUser()
        local boost = (_G.GlobalBoost and _G.GlobalBoost.value and _G.GlobalBoost.value("money")) or 1
        for _, plr in ipairs(Players:GetPlayers()) do
            local rate, speed = ensure(plr)
            local mult = math.max(1, tonumber(plr:GetAttribute("MoneyMult")) or 1) * boost
            rate.Value = math.floor((sum[plr.UserId] or 0) * mult)
            speed.Value = math.floor(tonumber(plr:GetAttribute("Speed")) or 0)
        end
        task.wait(EVERY)
    end
end)