local RS=game:GetService("ReplicatedStorage")
local Run=game:GetService("RunService")
local player=game.Players.LocalPlayer
local exit=RS:WaitForChild("Remotes"):WaitForChild("AdminTreadmillExit")
local last=0
game:GetService("UserInputService").JumpRequest:Connect(function()
 if player:GetAttribute("AdminTreadmillRunning") and os.clock()-last>.3 then last=os.clock() exit:FireServer() end
end)
local current,belt,rows,textures=nil,nil,{},{}
local offset=0
local function setup(m)
 current=m belt=m:FindFirstChild("Belt") rows={} textures={} offset=0
 if not belt then return end
 local folder=Instance.new("SurfaceGui")
 folder.Name="BeltArrowDecals" folder.Face=Enum.NormalId.Top
 folder.CanvasSize=Vector2.new(960,660) folder.LightInfluence=1 folder.Brightness=1
 folder.AlwaysOnTop=false folder.ZOffset=.03 folder.ClipsDescendants=true folder.Parent=belt
 for i=1,4 do
  local arrow=Instance.new("ImageLabel")
  arrow.Name="ChevronDecal"..i arrow.BackgroundTransparency=1
  arrow.Image="rbxassetid://111060587869326"
  arrow.AnchorPoint=Vector2.new(.5,.5) arrow.Size=UDim2.fromOffset(360,240) arrow.Rotation=90
  arrow.Parent=folder rows[i]=arrow
 end
 for _,v in m:GetDescendants() do if v:IsA("Texture") and v.Name=="AdminBeltTexture" then table.insert(textures,v) end end
end
Run.Heartbeat:Connect(function(dt)
 local world=workspace:FindFirstChild("GameWorld")
 local m=world and world:FindFirstChild("AdminTreadmill")
 if not m then current=nil return end
 if m~=current then setup(m) end
 if not belt then return end
 local span=belt.Size.Z local step=span/4
 offset=(offset+3.2*(tonumber(m:GetAttribute("BeltRate")) or 1)*dt)%span
 for i,row in rows do
  local z=((i-1)*step+offset)%span-span/2
  row.Position=UDim2.fromScale(z/span+.5,.5)
  row.ImageTransparency=math.clamp((math.abs(z)-(span/2-2))/1.2,0,1)
 end
 for _,t in textures do t.OffsetStudsV=-offset end
end)