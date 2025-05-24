minigame <- Ware_MinigameData
({
	name           = "Floppy Scout"
	author         = "tilderain"
	description    = "Get to the end!"
	duration       = 11.0
	end_delay      = 0.6
	location       = "boxarena"
	music          = "restnpeace"
	thirdperson    = true
	custom_overlay = "get_end"
})

goal_vectors <- null

pipe_model <- "models/props_mining/generator_pipe01.mdl"
kill_sound <- "Halloween.skeleton_break"

function OnPrecache()
{
	PrecacheSprite(pipe_model)
	PrecacheModel(pipe_model)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersRow(players, 
		Ware_MinigameLocation.center + Vector(0, -830, 600), 
		QAngle(0, 90, 0), 
		1600.0, 
		60.0, 120.0)
}

function SpawnPipewall(org, skip)
{
	local add = RandomInt(-50, 50)
	for (local i = 0; i < 15; i++)
    {
        for (local j = -3; j <= 2; j++)
        {
			if(j==skip) continue
            local angles = QAngle(0,0,0)

			local distance = abs(j - skip);
			local col = (255 / distance);
			
            local beam = Ware_SpawnEntity("prop_physics_override", 
            {
                origin       = org + Vector(-880,0,add + 230) + Vector(i*120, 0, 300 + j*180)
                model        = pipe_model
                spawnflags   = SF_PHYSPROP_TOUCH
                minhealthdmg = 999999 // Don't destroy on touch    
                health       = INT_MAX
                modelscale   = 1
                angles       = angles
				rendercolor  = "0 " + col.tostring() + " 0"
				disableshadows = true
            })
            beam.SetMoveType(MOVETYPE_NONE, 0)
            beam.SetCollisionGroup(TFCOLLISION_GROUP_RESPAWNROOMS)
        }
    }
}

function OnStart()
{
    local highest_scale = 1.0
	
    Ware_SetGlobalLoadout(TF_CLASS_SCOUT, null, { "air dash count" : 9999 })    	
	
    foreach (player in Ware_MinigamePlayers)
	{
		player.SetMoveType(MOVETYPE_NONE, 0)
        if (player.GetModelScale() > highest_scale)
            highest_scale = player.GetModelScale()
	}

    local beam_height = 100.0 * highest_scale
	local skip = RandomInt(-2, 0)

	SpawnPipewall(Ware_MinigameLocation.center + Vector(0,300,0), skip)
	//SpawnPipewall(Ware_MinigameLocation.center + Vector(0,10,0))

	skip = RandomInt(-2, 1)
	SpawnPipewall(Ware_MinigameLocation.center + Vector(0,-300,0), skip)

	goal_vectors = Ware_MinigameLocation.center + Vector(0,400,0)

	Ware_CreateTimer(function()
	{
		// when hits 0, unfreeze players
		foreach (player in Ware_MinigamePlayers)
		{
			player.SetMoveType(MOVETYPE_WALK, 0)
			player.SetAbsVelocity((Vector(0,160,0)))
		}
	}, 2.0)
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{	
		player.AddFlag(FL_ATCONTROLS)
		
		local vel = player.GetAbsVelocity()
		vel.y = 160
		player.SetAbsVelocity(vel)
		
		player.RemoveFlag(FL_DUCKING)
		if(player.GetFlags() & FL_ONGROUND && Ware_GetMinigameTime() > 1.0)
			Ware_SuicidePlayer(player)
		if (player.GetOrigin().y > goal_vectors.y && player.IsAlive())
			Ware_PassPlayer(player, true)

		local org = player.GetOrigin()
		if(org.z > -6300)
		{
			org.z = -6301
			player.KeyValueFromVector("origin", org)
		}
	}
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
				victim.TakeDamageEx(
					attacker, 
					attacker,
					null, 
					Vector(RandomFloat(19999, -19999), RandomFloat(19999, -19999), -999999),
					attacker.GetOrigin(), 
					999.9, 
					(DMG_CRUSH|DMG_CRIT)
				)
				
				victim.EmitSound(Ware_MinigameScope.kill_sound)
				
				local ragdoll = GetPropEntity(victim, "m_hRagdoll")
				if (ragdoll)
				{
					MarkForPurge(ragdoll)
					SetPropFloat(victim, "m_flTorsoScale", -1)
					SetPropFloat(ragdoll, "m_flTorsoScale", -1)
				}
				
				return false
			}
		}
	}
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{	
		player.RemoveFlag(FL_ATCONTROLS)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}