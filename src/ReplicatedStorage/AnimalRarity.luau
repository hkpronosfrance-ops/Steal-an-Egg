local C, U, R, L = 1, 2, 3, 4
local LIST = {
	["Rabbit"] = C, ["Squirrel"] = C, ["Hedgehog"] = C, ["Fawn"] = C, ["Fox"] = U, ["Badger"] = U, ["Owl"] = R, ["Wild Boar"] = L,
	["Duck"] = C, ["Frog"] = C, ["Dragonfly"] = C, ["Beaver"] = C, ["Heron"] = U, ["Otter"] = U, ["Turtle"] = R, ["Koi Carp"] = L,
	["Jerboa"] = C, ["Meerkat"] = C, ["Horned Lizard"] = C, ["Fennec Fox"] = C, ["Scorpion"] = U, ["Rattlesnake"] = U, ["Vulture"] = R, ["Camel"] = L,
	["Tree Frog"] = C, ["Monkey"] = C, ["Parrot"] = C, ["Toucan"] = C, ["Chameleon"] = U, ["Sloth"] = U, ["Gorilla"] = R, ["Panther"] = L,
	["Arctic Hare"] = C, ["Penguin"] = C, ["Seal Pup"] = C, ["Arctic Fox"] = C, ["Snowy Owl"] = U, ["Reindeer"] = U, ["Walrus"] = R, ["Polar Bear Cub"] = L,
	["Ash Crow"] = C, ["Ember Bat"] = C, ["Lava Toad"] = C, ["Magma Slug"] = C, ["Flame Lizard"] = U, ["Fire Salamander"] = U, ["Cinder Ram"] = R, ["Obsidian Beetle"] = L,
	["Lanternfish"] = C, ["Jellyfish"] = C, ["Deep Sea Crab"] = C, ["Moray Eel"] = C, ["Nautilus"] = U, ["Anglerfish"] = U, ["Manta Ray"] = R, ["Octopus"] = L,
	["Pterodactyl"] = C, ["Raptor"] = C, ["Stegosaurus"] = C, ["Ankylosaurus"] = C, ["Triceratops"] = U, ["Sabertooth Cat"] = U, ["Mammoth"] = R, ["Brontosaurus"] = L,
	["Meteor Beetle"] = C, ["Alien Blob"] = C, ["Moon Rabbit"] = C, ["Star Cat"] = C, ["Satellite Owl"] = U, ["Nebula Jellyfish"] = U, ["Galaxy Fox"] = R, ["Comet Whale"] = L,
	["Butterfly"] = C, ["Songbird"] = C, ["Sakura Koi"] = C, ["Crane"] = C, ["Red Panda"] = U, ["Tanuki"] = U, ["Blossom Cat"] = R, ["Sakura Deer"] = L,
	["Bronze Scarab"] = C, ["Obelisk Beetle"] = C, ["Clay Serpent"] = C, ["Marble Owl"] = C, ["Jade Tortoise"] = U, ["Granite Ape"] = U, ["Guardian Lion"] = R, ["Stone Golem"] = L,
	["One Eyed Blob"] = C, ["Slime Cube"] = C, ["Horned Imp"] = C, ["Ghost Wisp"] = C, ["Bat Demon"] = U, ["Spike Worm"] = U, ["Shadow Hound"] = R, ["Tentacle Beast"] = L,
}

local BY_NAME = { common = C, uncommon = U, rare = R, legendary = L }

local function fromModel(m)
	local v = m:GetAttribute("Rarity")
	if type(v) == "number" then return math.clamp(math.floor(v), 1, 4) end
	if type(v) == "string" then return BY_NAME[v:lower()] end
	return nil
end

local function lookup(species)
	local lib = workspace:FindFirstChild("AnimalLibrary")
	if lib then
		for _, zone in ipairs(lib:GetChildren()) do
			local m = zone:FindFirstChild(species)
			if m then
				local t = fromModel(m)
				if t then return t end
			end
		end
	end
	local zones = game:GetService("ServerStorage"):FindFirstChild("Zones")
	if zones then
		for _, zone in ipairs(zones:GetChildren()) do
			local animals = zone:FindFirstChild("Animals")
			local m = animals and animals:FindFirstChild(species)
			if m then
				local t = fromModel(m)
				if t then return t end
			end
		end
	end
	return LIST[species]
end

return setmetatable({}, {
	__index = function(_, species)
		if type(species) ~= "string" then return nil end
		return lookup(species)
	end,
})