mode <- RandomInt(0,1)
minigame <- Ware_MinigameData
({
	name        = "Time Jumps"
	author      = ["tilderain"]
	description = "Time your jumps to the top!"
	duration    = mode == 0 ? 6.5 : 8.5
	end_delay   = 0.2
	music       = "starlift"
})

target_height  <- 500.0

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, null, { "air dash count" : 10 })
	if(mode == 1)
	{
		target_height = 570.0
		foreach(player in Ware_MinigamePlayers)
			Ware_GivePlayerWeapon(player, "Force-a-Nature", { "air dash count" : 10 })
	}
	Ware_ShowAnnotation(Ware_MinigameLocation.center + Vector(0, 0, target_height), "Goal!")
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		local height = Ware_GetPlayerHeight(player)
		
		if (height > target_height)
			Ware_PassPlayer(player, true)
	}
}