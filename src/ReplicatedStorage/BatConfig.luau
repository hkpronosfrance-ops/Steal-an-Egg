local B = {
 [1]={Name="Forest Bat",Icon="rbxassetid://78627901538510",Texture="rbxassetid://99023366608962",Particle="rbxassetid://133399689676988",Color=Color3.fromRGB(109,232,72),KnockbackMultiplier=1},
 [2]={Name="Lake Bat",Icon="rbxassetid://128942760086040",Texture="rbxassetid://113312414381082",Particle="rbxassetid://103551030328708",Color=Color3.fromRGB(81,218,255),KnockbackMultiplier=1},
 [3]={Name="Desert Bat",Icon="rbxassetid://78140675026956",Texture="rbxassetid://124813926602983",Particle="rbxassetid://110980639547832",Color=Color3.fromRGB(255,205,87),KnockbackMultiplier=1},
 [4]={Name="Jungle Bat",Icon="rbxassetid://97647392106621",Texture="rbxassetid://78386202196551",Particle="rbxassetid://90667002214761",Color=Color3.fromRGB(42,231,135),KnockbackMultiplier=1},
 [5]={Name="Snow Bat",Icon="rbxassetid://74708834785435",Texture="rbxassetid://115059336607903",Particle="rbxassetid://107348064657097",Color=Color3.fromRGB(186,241,255),KnockbackMultiplier=1},
 [6]={Name="Volcano Bat",Icon="rbxassetid://81159744142004",Texture="rbxassetid://97710820267323",Particle="rbxassetid://90458453852326",Color=Color3.fromRGB(255,126,47),KnockbackMultiplier=1},
 [7]={Name="Abyss Ocean Bat",Icon="rbxassetid://87213052631010",Texture="rbxassetid://105106556574021",Particle="rbxassetid://93703428762925",Color=Color3.fromRGB(46,208,249),KnockbackMultiplier=1},
 [8]={Name="Prehistoric Bat",Icon="rbxassetid://138937455667236",Texture="rbxassetid://75246579797894",Particle="rbxassetid://135165109321177",Color=Color3.fromRGB(237,186,117),KnockbackMultiplier=1},
 [9]={Name="Cosmic Bat",Icon="rbxassetid://82557247095751",Texture="rbxassetid://118786626401575",Particle="rbxassetid://126239827074398",Color=Color3.fromRGB(200,125,255),KnockbackMultiplier=1},
 [10]={Name="Cherry Blossom Bat",Icon="rbxassetid://125630767448863",Texture="rbxassetid://139714160238622",Particle="rbxassetid://131341438034561",Color=Color3.fromRGB(255,164,213),KnockbackMultiplier=1},
 [11]={Name="Titan Temple Bat",Icon="rbxassetid://106678233822648",Texture="rbxassetid://103125227018421",Particle="rbxassetid://125583923099311",Color=Color3.fromRGB(255,223,133),KnockbackMultiplier=1},
 [12]={Name="Monster Lair Bat",Icon="rbxassetid://133865734758806",Texture="rbxassetid://102155032844699",Particle="rbxassetid://87856699750624",Color=Color3.fromRGB(236,85,166),KnockbackMultiplier=1},
}

local Cfg = require(game:GetService("ReplicatedStorage"):WaitForChild("EggConfig"))
for zone = #B + 1, Cfg.ZONES do
	local last = B[zone - 1]
	B[zone] = {
		Name = Cfg.NAMES[zone] .. " Bat",
		Icon = last.Icon, Texture = last.Texture, Particle = last.Particle,
		Color = Cfg.COLORS[zone] or last.Color,
		KnockbackMultiplier = last.KnockbackMultiplier or 1,
	}
end

return B