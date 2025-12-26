minigame <- Ware_MinigameData
({
	name            = "Cuddly Heavies"
	author          = ["TonyBaretta", "ficool2"]
	description     = 
	[
		"Avoid the Cuddly Heavies!"
		"Hug every Scout!"
	]
	duration        = 65.0
	end_delay       = 0.5
	music           = "cuddly"
	location        = "love"
	custom_overlay  =
	[
		"cuddly_avoid"
		"cuddly_hug"
	]
	min_players     = 6
	max_scale       = 1.5
	start_pass      = true
	allow_damage    = true
	collisions      = true
	convars         =
	{
		mp_teams_unbalance_limit = 0
	}
})

heavies <- []

heavy_model <- "models/player/geavy.mdl"
vo_love_sound <- "TF2Ware_Ultimate.GeavyLove"
vo_disgust_sound <- "TF2Ware_Ultimate.ScoutDisgust"
vo_kiss_sound <- "Heavy.Generic01"
love_particle <- "utaunt_hearts_bubbling"

function OnPrecache()
{
	PrecacheModel(heavy_model)
	PrecacheScriptSound(vo_love_sound)
	PrecacheScriptSound(vo_disgust_sound)
	PrecacheScriptSound(vo_kiss_sound)
	PrecacheParticle(love_particle)
}

function OnStart()
{
	local vo_count = 0
	local vo_scouts = []
	local vo_heavies = []
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (heavies.find(player) != null)
		{
			Ware_SetPlayerMission(player, 1)
			Ware_SetPlayerClass(player, TF_CLASS_HEAVYWEAPONS)
			Ware_PassPlayer(player, false)
			Ware_StripPlayer(player, true)
			Ware_SetPlayerTeam(player, TF_TEAM_RED)
			Ware_GivePlayerWeapon(player, "Fists")
			player.SetCustomModelWithClassAnimations(heavy_model)
			vo_heavies.append(player)
		}
		else
		{
			Ware_SetPlayerMission(player, 0)
			Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
			Ware_SetPlayerClass(player, TF_CLASS_SCOUT)
			Ware_AddPlayerAttribute(player, "no double jump", 1, -1)
			vo_scouts.append(player)
		}
	}
	
	Ware_SetGlobalAttribute("no_attack", 1, -1)
	
	foreach (wall in Ware_MinigameLocation.walls)
	{
		EntityAcceptInput(wall, "SetSpeed", "14")
		EntityEntFire(wall, "Open", "", 0.5)
	}
	
	vo_count = vo_heavies.len()
	for (local i = 0; i < vo_count; i++)
		Ware_CreateTimer(@() PlayVocalization(RemoveRandomElement(vo_heavies), vo_love_sound), RandomFloat(4.0, 8.0))
	vo_count = Min(vo_scouts.len(), 4)
	for (local i = 0; i < vo_count; i++)
		Ware_CreateTimer(@() PlayVocalization(RemoveRandomElement(vo_scouts), vo_disgust_sound), RandomFloat(1.5, 5.0))
		
	Ware_CreateTimer(function()
	{	
		foreach (heavy in heavies)
		{
			if (heavy.IsValid())
				heavy.AddCond(TF_COND_SPEED_BOOST)
		}
	}, minigame.duration - 10.0)
}

function OnTeleport(players)
{
	local max_heavy_count = 4
	if (players.len() > 32)
		max_heavy_count++
	if (players.len() >= 64)
		max_heavy_count++
		
	local heavy_count = Clamp(players.len() / 4, 2, max_heavy_count)
	for (local i = 0; i < heavy_count; i++)
		heavies.append(RemoveRandomElement(players))
		
	Ware_TeleportPlayersRow(heavies,
		Ware_MinigameLocation.center_left,
		QAngle(0, -90, 0),
		400.0,
		-50.0, 50.0)
	
	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center_right,
		QAngle(0, 90, 0),
		400.0,
		-50.0, 33.0)
}

function OnTakeDamage(params)
{
	return (params.damage_type & DMG_BULLET) != 0
}

function OnPlayerTouch(player, other_player)
{
	local hug = false
	local player_class = player.GetPlayerClass()
	local other_player_class = other_player.GetPlayerClass()
	
	if (player_class == TF_CLASS_HEAVYWEAPONS
		&& other_player_class == TF_CLASS_SCOUT)
	{
		// I'm not sure why this is necessary
		// but if this isn't done then scouts can survive sitting in a corner
		local temp = other_player
		other_player = player
		player = temp
		hug = true
	}
	else if (player_class == TF_CLASS_SCOUT
		&& other_player_class == TF_CLASS_HEAVYWEAPONS)
	{
		hug = true
	}
	
	if (hug)
	{
		EmitSoundOnClient(vo_kiss_sound, player)
		other_player.EmitSound(vo_kiss_sound)
		player.TakeDamage(300, DMG_BULLET, other_player)
	}
}

function OnPlayerDeath(player, attacker, params)
{
	if (player.GetPlayerClass() == TF_CLASS_SCOUT)
	{
		Ware_PassPlayer(player, false)
		
		if (attacker && attacker.IsPlayer())
		{
			local particle = SpawnEntityFromTableSafe("info_particle_system",
			{
				effect_name  = love_particle
				origin       = player.GetOrigin()
				angles       = player.GetAbsAngles()
				start_active = true
			})	
			EntityEntFire(particle, "Kill", "", 1.0)	
		}		
	}
}

function OnEnd()
{
	if (Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0)
	{
		foreach (heavy in heavies)
		{
			if (heavy.IsValid())
				Ware_PassPlayer(heavy, true)
		}
	}
}

function OnCleanup()
{
	foreach (wall in Ware_MinigameLocation.walls)
	{
		EntityAcceptInput(wall, "SetSpeed", "1000")
		EntityAcceptInput(wall, "Close")
	}

	foreach (player in Ware_MinigamePlayers)
		player.SetCustomModel("")
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0
}