minigame <- Ware_MinigameData
({
	name           = "Pirate Attack"
	author         = ["TonyBaretta", "ficool2"]
	description    = 
	[
		"Jump over the RED ship!"
		"Jump over the BLUE ship!"
	]
	duration       = 12.0
	max_scale      = 1.0
	music          = "piper"
	location       = "beach"
	custom_overlay = 
	[
		"pirate_red"
		"pirate_blue"
	]	
})
 
ship_model <-  "models/tf2ware_ultimate/pirate_ship.mdl"

red_ship  <- null
blue_ship <- null

function OnPrecache()
{
	PrecacheModel(ship_model)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Stickybomb Jumper")
	
	foreach (player in Ware_MinigamePlayers)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			Ware_SetPlayerMission(player, 0)
		else if (team == TF_TEAM_BLUE)
			Ware_SetPlayerMission(player, 1)	
	}
	
	local swap = RandomBool()
	red_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = Ware_MinigameLocation.center + Vector(2200, swap ? -500 : 300, -136),
		model       = ship_model
		skin		= 0
		modelscale  = 0.3
	})
	blue_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = Ware_MinigameLocation.center + Vector(2200, swap ? 300 : -500, -136),
		model       = ship_model
		skin		= 1
		modelscale  = 0.3
	})
}

function OnUpdate()
{
	local offset = Vector(0, 0, 300)
	local red_point = red_ship.GetOrigin() + offset
	local blue_point = blue_ship.GetOrigin() + offset
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		if (player.GetFlags() & FL_INWATER)
		{
			Ware_TeleportPlayer(player, Ware_MinigameLocation.center, ang_zero, vec3_zero)
			continue
		}
		
		local target = player // squirrel needs this to be happy
		local origin = player.GetOrigin()
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
		{
			if (origin.z > red_point.z && VectorDistance2D(origin, red_point) < 150.0)
			{
				Ware_ShowScreenOverlay(player, null)
				Ware_CreateTimer(function()
				{
					if (target.IsValid())
						Ware_PassPlayer(target, true)
				}, 0.1)
				Ware_TeleportPlayer(player, Ware_MinigameLocation.center, ang_zero, vec3_zero)
			}
			else if (origin.z > blue_point.z && VectorDistance2D(origin, blue_point) < 150.0)
			{
				Ware_ShowScreenOverlay(player, null)
				Ware_SuicidePlayer(player)
				Ware_ChatPrint(player, "You pirated the wrong ship!")
			}
		}
		else if (team == TF_TEAM_BLUE)
		{
			if (origin.z > blue_point.z && VectorDistance2D(origin, blue_point) < 150.0)
			{
				Ware_ShowScreenOverlay(player, null)
				Ware_CreateTimer(function()
				{
					if (target.IsValid())
						Ware_PassPlayer(target, true)
				}, 0.1)
				Ware_TeleportPlayer(player, Ware_MinigameLocation.center, ang_zero, vec3_zero)
			}	
			else if (origin.z > red_point.z && VectorDistance2D(origin, red_point) < 150.0)
			{
				Ware_ShowScreenOverlay(player, null)
				Ware_SuicidePlayer(player)
				Ware_ChatPrint(player, "You pirated the wrong ship!")
			}			
		}
	}
}