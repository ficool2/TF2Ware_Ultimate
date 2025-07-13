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
 
ship_model <- "models/marioragdoll/super mario galaxy/bj ship/bjship.mdl"

red_ship  <- null
blue_ship <- null

ships <- []

function OnPrecache()
{
	PrecacheModel(ship_model)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Stickybomb Jumper")
	
	local mission = RandomInt(0,1)
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerMission(player, mission)
	}

	local x_off = 100

	red_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = Ware_MinigameLocation.center + Vector(2200 + (mission == 0 ? x_off : 0), RandomFloat(-300,300), -136),
		model       = ship_model
		rendercolor = "255 0 0",
	})
	blue_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = Ware_MinigameLocation.center + Vector(2200 + (mission == 1 ? x_off : 0), RandomFloat(-300,300), -136),
		model       = ship_model
		rendercolor = "0 255 255",
	})

	ships <- [red_ship, blue_ship]
	foreach (ship in ships)
	{
		ship.ValidateScriptScope()
		local scope = ship.GetScriptScope()

		scope.speed <- RandomFloat(-20, 20)
		if (abs(scope.speed) < 5) scope.speed = RandomBool() ? 10 : -10
		scope.start_y <- ship.GetOrigin().y
	}

}

function OnUpdate()
{

	foreach (ship in ships)
	{
		local scope = ship.GetScriptScope()
		local origin = ship.GetOrigin()

		if (origin.y > scope.start_y)
			scope.speed -= 0.2
		else
			scope.speed += 0.2

		ship.KeyValueFromVector("origin", origin + Vector(0, scope.speed, 0))
	}

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
		local mission = Ware_GetPlayerMission(player)
		if (mission == 0)
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
		else if (mission == 1)
		{
			if (origin.z > blue_point.z && VectorDistance2D(origin, blue_point) < 150.0)
			{
				Ware_ShowScreenOverlay(player, null);	
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