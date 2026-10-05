local EXTRA_H = 320
local SHOW = false

require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))

local map = workspace:WaitForChild("GameWorld")
local walls = map:WaitForChild("Walls")

local old = map:FindFirstChild("Barriers")
if old then old:Destroy() end

local folder = Instance.new("Folder")
folder.Name = "Barriers"
folder.Parent = map

local made = 0
for _, part in ipairs(walls:GetDescendants()) do
    if part:IsA("BasePart") and part.CanCollide then

        local cf, sz = part.CFrame, part.Size
        local top = cf.Position.Y
            + math.abs(cf.RightVector.Y) * sz.X / 2
            + math.abs(cf.UpVector.Y)    * sz.Y / 2
            + math.abs(cf.LookVector.Y)  * sz.Z / 2
        local spanX = math.abs(cf.RightVector.X) * sz.X
            + math.abs(cf.UpVector.X) * sz.Y + math.abs(cf.LookVector.X) * sz.Z
        local spanZ = math.abs(cf.RightVector.Z) * sz.X
            + math.abs(cf.UpVector.Z) * sz.Y + math.abs(cf.LookVector.Z) * sz.Z

        local wall = Instance.new("Part")
        wall.Name = "Barrier"
        wall.Anchored = true
        wall.CanCollide = true
        wall.CanTouch = false
        wall.CanQuery = false
        wall.CastShadow = false
        wall.Material = Enum.Material.SmoothPlastic
        wall.Color = Color3.fromRGB(120, 200, 255)
        wall.Transparency = SHOW and 0.75 or 1
        wall.Size = Vector3.new(math.max(spanX, 1), EXTRA_H, math.max(spanZ, 1))
        wall.Position = Vector3.new(cf.Position.X, top + EXTRA_H / 2, cf.Position.Z)
        wall.Parent = folder
        made += 1
    end
end

print(("[Bounds] %d barriers above walls, +%d studs"):format(made, EXTRA_H))