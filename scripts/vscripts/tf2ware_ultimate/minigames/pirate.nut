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
	modes          = 2
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
	
	if (Ware_MinigameMode == 0)
	{
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
			rendercolor = "255 0 0",
		})
		blue_ship = Ware_SpawnEntity("prop_dynamic_override",
		{
			origin      = Ware_MinigameLocation.center + Vector(2200, swap ? 300 : -500, -136),
			model       = ship_model
			rendercolor = "0 255 255",
		})
	}
	else
	{
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

			scope.start_origin <- ship.GetOrigin()
			scope.start_angles <- ship.GetAngles()

			scope.bob_speed <- RandomFloat(1.5, 2.5)
			scope.bob_amplitude <- RandomFloat(4.0, 9.0)
			scope.bob_phase <- RandomFloat(0, 2 * PI)

			scope.roll_speed <- RandomFloat(0.8, 1.2)
			scope.roll_amplitude <- RandomFloat(2.5, 8.0)
			scope.roll_phase <- RandomFloat(0, 2 * PI)

			//Horizontal movement
			scope.sway_speed <- RandomFloat(1, 1.5)
			scope.sway_amplitude <- RandomFloat(0.0, 600.0) 
			scope.sway_phase <- RandomFloat(0, 2 * PI)
		}
	}
}

function OnUpdate()
{
	if (Ware_MinigameMode == 1)
	{
		local minigame_time = Ware_GetMinigameTime()
		foreach (ship in ships)
		{
			local scope = ship.GetScriptScope()

			local bob_offset = sin(minigame_time * scope.bob_speed + scope.bob_phase) * scope.bob_amplitude
			local sway_offset = sin(minigame_time * scope.sway_speed + scope.sway_phase) * scope.sway_amplitude
			local roll_angle_offset = sin(minigame_time * scope.roll_speed + scope.roll_phase) * scope.roll_amplitude

			local new_origin = scope.start_origin + Vector(0, sway_offset, bob_offset)

			local base_angles = scope.start_angles
			local new_angles = QAngle(base_angles.x, base_angles.y, base_angles.z + roll_angle_offset)

			ship.KeyValueFromVector("origin", new_origin)
			ship.SetAbsAngles(new_angles)
		}
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