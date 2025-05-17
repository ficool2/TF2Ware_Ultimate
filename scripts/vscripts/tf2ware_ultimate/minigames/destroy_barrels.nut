minigame <- Ware_MinigameData
({
	name          = "Explosive Barrels"
	author		  = ["ficool2", "tilderain"]
	description   = "Carefully destroy every explosive barrel!"
	duration      = 6.0
	music         = "hardsteer"
	allow_damage  = true
	fail_on_death = true
	convars       =
	{
		phys_timescale = 0.5
	}
})

barrel_model <- "models/tf2ware_ultimate/explosive_barrel.mdl"
barrels <- []

function OnPrecache()
{
	PrecacheModelGibs(barrel_model)
}

function SpawnBarrel()
{
	local barrelOrigin = Vector(
		RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
		RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
			Ware_MinigameLocation.center.z + 500.0)
		
	local prop = Ware_SpawnEntity("prop_physics_multiplayer",
	{
		origin	   = barrelOrigin
		model	   = barrel_model
		targetname = "explosive_barrel"
	})
	Ware_SlapEntity(prop, 40.0)
	barrels.append(prop)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_ENGINEER, null, {}, true)

	local player_count = Ware_MinigamePlayers.len()
	local barrel_count = Clamp(player_count, 4, 32)
	
	Ware_CreateTimer(function()
	{
		SpawnBarrel()
		if (--barrel_count > 0)
			return 0.02
	}, 0.0)
	
	Ware_CreateTimer(function()
	{
		Ware_SetGlobalLoadout(TF_CLASS_ENGINEER, "Pistol")
	}, 1.0)
}

function OnEnd()
{
	local barrels_remaining = 0
	local min_height = Ware_MinigameLocation.mins.z - 32.0
	foreach (barrel in barrels)
	{
		// failsafe in case they fall out of the map
		if (barrel.IsValid() && barrel.GetOrigin().z >= min_height)
			barrels_remaining++
	}
	
	if (barrels_remaining == 0)
	{
		foreach (player in Ware_GetAlivePlayers())
			Ware_PassPlayer(player, true)
	}
	else
	{
		Ware_ChatPrint(null, "There was {int} {color}explosive{color} {str} left standing...", 
			barrels_remaining, COLOR_RED, TF_COLOR_DEFAULT, barrels_remaining == 1 ? "barrel" : "barrels")
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		local attacker = params.attacker	
		if (attacker && attacker.IsPlayer())
		{
			if (params.damage_type & DMG_CLUB)
			{
				victim.SetAbsVelocity(victim.GetAbsVelocity() + Vector(0, 0, 300))
				Ware_PushPlayerFromOther(victim, attacker, 250.0)
			}
			
			return false
		}
	}
	else if (victim.GetName() == "explosive_barrel")
	{
		//Barrels won't do non-self inflicted damage otherwise
		params.attacker = victim
	}
}
