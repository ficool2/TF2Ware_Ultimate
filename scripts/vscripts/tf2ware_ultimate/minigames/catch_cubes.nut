minigame <- Ware_MinigameData
({
	name        = "Catch the Cubes"
	author      = ["TonyBaretta", "ficool2"]
	description = "Catch the cubes!"
	duration    = 14.0
	location    = "boxarena"
	music       = "cozy"
})

cube_model  <- "models/props/metal_box.mdl"
touch_sound <- "Player.HitSoundSpace"

spawn_rate <- RemapValClamped(Ware_MinigamePlayers.len().tofloat(), 0.0, 32.0, 0.5, 0.05)

function OnPrecache()
{
	PrecacheModel(cube_model)
	PrecacheScriptSound(touch_sound)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, RandomBool() ? "Sun-on-a-Stick" : "Candy Cane")
	Ware_SetGlobalCondition(TF_COND_SPEED_BOOST)
	
	foreach (player in Ware_MinigamePlayers)
		Ware_GetPlayerMiniData(player).points <- 0
		
	Ware_CreateTimer(@() CreateCube(), 0.5)
}

function CreateCube()
{
	local origin = Vector(
		RandomFloat(Ware_MinigameLocation.mins.x + 200.0, Ware_MinigameLocation.maxs.x - 200.0),
		RandomFloat(Ware_MinigameLocation.mins.y + 200.0, Ware_MinigameLocation.maxs.y - 200.0),
		Ware_MinigameLocation.center.z + 300.0)
	
	local cube = Ware_SpawnEntity("prop_physics", 
	{
		origin       = origin,
		model        = cube_model
		spawnflags   = SF_PHYSPROP_TOUCH
		minhealthdmg = INT_MAX // don't destroy on touch				
	})
	return spawn_rate
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		if (params.damage_type & DMG_SLASH) // prop touch
		{
			// the attacker is the player, so recover the true attacker from the damage position
			local attacker = FindByClassnameNearest("prop_physics", params.damage_position, 0.0)
			if (attacker)
			{
				if (!attacker.IsEFlagSet(EFL_USER))
				{
					victim.EmitSound(Ware_MinigameScope.touch_sound)

					if (++Ware_GetPlayerMiniData(victim).points >= 3)	
						Ware_PassPlayer(victim, true)
						
					EntityEntFire(attacker, "Kill")
					attacker.AddEFlags(EFL_USER) // prevent multiple touches on same frame
				}
				
				return false			
			}
		}
	}
}