local Content=game:GetService("ContentProvider")
local Players=game:GetService("Players")
local Config=require(game.ReplicatedStorage:WaitForChild("BatConfig"))
local queued={}
local queue={}
local cursor=1
local function enqueue(id)
 if type(id)=="string" and id~="" and not queued[id] then
  queued[id]=true table.insert(queue,id)
 end
end
for _,cfg in ipairs(Config) do enqueue(cfg.Texture) end
for _,cfg in ipairs(Config) do enqueue(cfg.Icon) enqueue(cfg.Particle) end
local function inspect(instance)
 if instance:IsA("MeshPart") then enqueue(instance.MeshId) enqueue(instance.TextureID) end
end
local urgent={}
local function now(id)
 if type(id)~="string" or id=="" or urgent[id] then return end
 urgent[id]=true
 task.spawn(function() pcall(function() Content:PreloadAsync({id}) end) end)
end
local function skinOf(zone)
 local cfg=Config[tonumber(zone) or 0]
 if cfg then now(cfg.Texture) now(cfg.Icon) end
end
local me=Players.LocalPlayer
skinOf(me:GetAttribute("BatEquipped"))
me:GetAttributeChangedSignal("BatEquipped"):Connect(function() skinOf(me:GetAttribute("BatEquipped")) end)
local RunService=game:GetService("RunService")
local kicking=setmetatable({},{__mode="k"})
local function kick(part)
 if kicking[part] then return end
 local id=part.TextureID
 if id=="" then return end
 kicking[part]=true
 task.spawn(function()
  pcall(function() Content:PreloadAsync({id}) end)
  if part.Parent and part.TextureID==id then
   part.TextureID=""
   RunService.Heartbeat:Wait()
   if part.Parent and part.TextureID=="" then part.TextureID=id end
  end
  kicking[part]=nil
 end)
end
local function kickTool(tool)
 for _,v in tool:GetDescendants() do if v:IsA("MeshPart") then kick(v) end end
end
local WARM_TIME=6
local function warm(tool)
 local ch=me.Character
 local hand=ch and (ch:FindFirstChild("RightHand") or ch:FindFirstChild("Right Arm") or ch:FindFirstChild("HumanoidRootPart"))
 if not hand then return end
 local cam=workspace.CurrentCamera
 local old=cam and cam:FindFirstChild("BatWarm") if old then old:Destroy() end
 if not cam then return end
 local holder=Instance.new("Folder") holder.Name="BatWarm"
 for _,v in tool:GetDescendants() do
  if v:IsA("MeshPart") and v.TextureID~="" then
   local c=v:Clone()
   c:ClearAllChildren()
   c.Anchored=false c.CanCollide=false c.CanQuery=false c.CanTouch=false c.Massless=true c.CastShadow=false
   c.Transparency=.97
   c.CFrame=hand.CFrame
   local w=Instance.new("WeldConstraint") w.Part0=hand w.Part1=c w.Parent=c
   c.Parent=holder
  end
 end
 holder.Parent=cam
 task.delay(WARM_TIME,function() if holder.Parent then holder:Destroy() end end)
 local con con=tool.AncestryChanged:Connect(function()
  if tool.Parent==ch then con:Disconnect() if holder.Parent then holder:Destroy() end end
 end)
end
local watched=setmetatable({},{__mode="k"})
local function watchTool(tool)
 if not tool:IsA("Tool") or tool.Name~="Stick" or watched[tool] then return end
 watched[tool]=true
 for _,v in tool:GetDescendants() do inspect(v) end
 tool.DescendantAdded:Connect(inspect)
 skinOf(tool:GetAttribute("BatZone"))
 tool:GetAttributeChangedSignal("BatZone"):Connect(function()
  local cfg=Config[tool:GetAttribute("BatZone")]
  if cfg then enqueue(cfg.Texture) enqueue(cfg.Particle) end
  skinOf(tool:GetAttribute("BatZone"))
  kickTool(tool)
  if tool.Parent and tool.Parent:IsA("Backpack") and tool:IsDescendantOf(me) then warm(tool) end
 end)
 if tool.Parent and tool.Parent:IsA("Backpack") and tool:IsDescendantOf(me) then task.defer(warm,tool) end
 tool.AncestryChanged:Connect(function()
  if tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid") then kickTool(tool) end
 end)
 if tool.Parent and tool.Parent:FindFirstChildOfClass("Humanoid") then kickTool(tool) end
end
local function watch(root)
 for _,v in root:GetChildren() do watchTool(v) end
 root.ChildAdded:Connect(watchTool)
end
local function bind(p)
 if p.Character then watch(p.Character) end
 p.CharacterAdded:Connect(watch)
end
Players.PlayerAdded:Connect(bind)
for _,p in Players:GetPlayers() do bind(p) end
task.spawn(function() watch(Players.LocalPlayer:WaitForChild("Backpack")) end)
Players.LocalPlayer.ChildAdded:Connect(function(c) if c:IsA("Backpack") then watch(c) end end)
for _=1,4 do
 task.spawn(function()
  while true do
   local id=queue[cursor]
   if id then
    cursor+=1
    pcall(function() Content:PreloadAsync({id}) end)
   else task.wait(.5) end
  end
 end)
end