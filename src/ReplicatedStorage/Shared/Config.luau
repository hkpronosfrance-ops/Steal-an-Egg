local Config = {}

Config.DataStores = {
	Profile = "StealAnEggProfile_v1",
	Bans    = "StealAnEggBans_v1",
	Board   = "StealAnEggBoard_",
	Boost   = "StealAnEggBoost_v1",
}

Config.DefaultSettings = {
	Music = true, SFX = true, Volume = 0.7, HideOwnPets = false, HideOtherPets = false,
}

Config.FreeReward = {
	GroupId = 0,
	Speed = 5000,
}

Config.Admin = {
	UserIds = {},
	GroupId = 0,
	MinRank = 250,
	StudioAlwaysAdmin = true,
}

Config.Leaderboard = { Refresh = 60, SaveEvery = 60, Shown = 100 }

Config.Streaming = { Ahead = 4, Behind = 4, Every = 0.7, AlwaysLoaded = { 1, 2 }, LibraryDelay = 3 }

return Config