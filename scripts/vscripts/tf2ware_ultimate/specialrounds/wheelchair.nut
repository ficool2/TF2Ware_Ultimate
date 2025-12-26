special_round <- Ware_SpecialRoundData
({
	name         = "Wheelchair"
	author       = ["ficool2", "AlreadyADemon"] // https://gamebanana.com/mods/299091
	description  = "Everyone is confined to a wheelchair!"
	category     = ""
})

wheelchair_model <- "models/tf2ware_ultimate/heavy_wheelchair.mdl"

function OnPrecache()
{
	PrecacheModel(wheelchair_model)
}

function ApplyWheelchair(player)
{
	player.SetCustomModelWithClassAnimations(wheelchair_model)
	player.AddCustomAttribute("no_jump", 1, -1)
	player.AddCustomAttribute("no_duck", 1, -1)
}

function OnStart()
{
	foreach (player in Ware_Players)
	{
		if (player.IsAlive())
			ApplyWheelchair(player)
	}
}

function OnPlayerPostSpawn(player)
{
	ApplyWheelchair(player)
}

function OnPlayerInventory(player)
{
	ApplyWheelchair(player)
}

function OnMinigameCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsAlive())
			ApplyWheelchair(player)
	}
}

function OnEnd()
{
	foreach (player in Ware_Players)
	{
		player.SetCustomModel("")
		player.RemoveCustomAttribute("no_jump")
		player.RemoveCustomAttribute("no_duck")
	}
}