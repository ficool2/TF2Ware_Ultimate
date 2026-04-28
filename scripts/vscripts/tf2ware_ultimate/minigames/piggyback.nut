minigame <- Ware_MinigameData
({
	name           = "Piggyback Heavy"
	author         = ["TonyBaretta", "ficool2"]
	description    = 
	[
		"Piggyback the Heavy before he reaches the end!"
		"Reach the end without all players on your back!"
	]
	duration       = 27.7
	min_players    = 5
	location       = "pinball"
	music          = "makemegroove"
	collisions     = true
	custom_overlay = 
	[
		"piggyback_end"
		"piggyback_heavy"
	]
	convars        =
	{
		mp_teams_unbalance_limit = 0
		tf_allow_sliding_taunt   = 1
	}
})

piggybacker <- null
piggybacker_dummy <- null
piggybacked_count <- 0
piggybacker_max_count <- 0
piggybacker_killed <- false

dummy_model <- "models/tf2ware_ultimate/dummy_sphere.mdl"

function OnPrecache()
{
	PrecacheModel(dummy_model)
}

function OnTeleport(players)
{
	piggybacker = RemoveRandomElement(players)
	piggybacker_max_count = players.len()

	Ware_TeleportPlayer(piggybacker, Ware_MinigameLocation.center_top + Vector(0, 2912, -777), QAngle(0, 90, 0), vec3_zero)
	
	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center_top,
		QAngle(0, 90, 0),
		2100.0,
		-64.0, 60.0)
}

function OnStart()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player == piggybacker)
		{
			Ware_SetPlayerMission(player, 1)
			Ware_SetPlayerClass(player, TF_CLASS_HEAVYWEAPONS)
			Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
			player.SetForcedTauntCam(1)
			
			// parented players will be invisible, workaround this by parenting to a dummy
			// not using Ware_SpawnEntity because the kill must be delayed when minigame ends
			piggybacker_dummy = SpawnEntityFromTableSafe("prop_dynamic",
			{
				model           = dummy_model
				origin          = player.GetOrigin()
				disableshadows  = true
				rendermode      = kRenderTransColor
				renderamt       = 0
			})
			SetEntityParent(piggybacker_dummy, player, "flag")	
		}
		else
		{
			Ware_SetPlayerMission(player, 0)
			Ware_SetPlayerClass(player, TF_CLASS_PYRO)
			Ware_SetPlayerTeam(player, TF_TEAM_RED)
			player.AddCond(TF_COND_SPEED_BOOST)
		}
	}
	
	Ware_ShowAnnotation(piggybacker, "Jump on my back!")
}

function PiggybackUnparent(player, invis_hack)
{
	if (player.GetMoveParent())
	{
		SetPlayerParentPlayer(player, null)
		
		if (invis_hack)
		{
			// hack: need to fake reparent for a bit so the player re-appears if the parent disconnected
			Ware_CreateTimer(function() { SetPropInt(player, "m_iParentAttachment", 1); SetPropEntity(player, "moveparent", World); }, 0.0)
			Ware_CreateTimer(function() { SetPropInt(player, "m_iParentAttachment", 0); SetPropEntity(player, "moveparent", null); }, 0.2)
		}
	}

	player.SetCollisionGroup(COLLISION_GROUP_PLAYER)
	player.SetForcedTauntCam(0)
	player.SetMoveType(MOVETYPE_WALK, 0)
	player.SetModelScale(1.0, 0.0)
}

function PiggybackKilled(disconnect)
{
	Ware_ChatPrint(null, "Heavy {str}, so Pyros win!", disconnect ? "disconnected" : "died")
	Ware_CreateTimer(function(){piggybacker_killed <- true}, 2.0)
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (player == piggybacker)
			continue
			
		Ware_PassPlayer(player, true)
		PiggybackUnparent(player, disconnect)
	}
}

function OnPlayerDeath(player, attacker, params)
{
	if (player == piggybacker)
		PiggybackKilled(false)
}

function OnPlayerDisconnect(player)
{
	if (player == piggybacker)
		PiggybackKilled(true)
}

function OnUpdate()
{
	local can_piggyback = false
	
	if (piggybacker.IsValid() && piggybacker.IsAlive())
	{
		local win_y = Ware_MinigameLocation.center_bottom.y - 400.0
		if (piggybacker.GetOrigin().y > win_y)
		{
			if (piggybacked_count < piggybacker_max_count)
				Ware_PassPlayer(piggybacker, true)
		}
		else
		{
			can_piggyback = !Ware_IsPlayerPassed(piggybacker)
		}
	}
	
	local piggybacker_origin
	if (can_piggyback)
		piggybacker_origin = piggybacker.GetOrigin()
		
	foreach (player in Ware_MinigamePlayers)
	{
		if (player == piggybacker)
			continue
			
		if (player.GetMoveParent())
		{
			// allow taunting on his back!
			SetPropEntity(player, "m_hGroundEntity", World)
			continue
		}
			
		if (!can_piggyback)
			continue
		
		if (VectorDistance(piggybacker_origin, player.GetOrigin()) < 96.0)
		{
			Ware_PassPlayer(player, true)
			player.SetForcedTauntCam(1)
			player.SetMoveType(MOVETYPE_NONE, 0)
			player.SetAbsVelocity(Vector())
			player.RemoveCond(TF_COND_SPEED_BOOST)
			player.SetModelScale(0.25, 0.0)
			player.SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
			SetPlayerParentPlayer(player, piggybacker_dummy, "static_prop")
			piggybacked_count++
		}
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
	{
		PiggybackUnparent(player, false)
		player.RemoveCond(TF_COND_SPEED_BOOST)
	}
	
	// must delay this or unparented players will go invisible
	if (piggybacker_dummy.IsValid())
		EntityEntFire(piggybacker_dummy, "Kill", "", 0.5)
}

function OnCheckEnd()
{
	return piggybacker_killed
}