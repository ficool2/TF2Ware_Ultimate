minigame <- Ware_MinigameData
({
	name           = "Street Fighter"
	author         = ["TonyBaretta", "ficool2"]
	description    = "Taunt kill!"
	duration       = 21.5
	end_delay      = 1.0
	location       = "boxarena"
	music          = "streetfighter"
	allow_damage   = true
	friendly_fire  = false
	collisions     = true
	min_players    = 2
})

fire_sound <- "TF2Ware_Ultimate.Hadoken"

function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnPrecache()
{
	PrecacheScriptSound(fire_sound)
}

function OnTeleport(players)
{
	local red_players = []
	local blue_players = []
	foreach (player in players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			red_players.append(player)
		else if (team == TF_TEAM_BLUE)
			blue_players.append(player)
			
		ForceRemovePlayerTaunt(player)
	}
	
	Ware_TeleportPlayersRow(red_players,
		Ware_MinigameLocation.center + Vector(0, 500.0, 0),
		QAngle(0, 270, 0),
		1300.0,
		65.0, 65.0)
	Ware_TeleportPlayersRow(blue_players,
		Ware_MinigameLocation.center + Vector(0, -500.0, 0),
		QAngle(0, 90, 0),
		1300.0,
		65.0, 65.0)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Panic Attack")
	Ware_SetGlobalAttribute("no_attack", 1, -1)
}

function SpawnFireball(player)
{
	local fireball = Ware_CreateEntity("tf_projectile_spellfireball")
	fireball.Teleport(
		true, player.EyePosition(), 
		true, player.EyeAngles(), 
		true, player.EyeAngles().Forward() * 650.0)
	fireball.SetTeam(player.GetTeam())
	fireball.SetOwner(player)
	fireball.SetModelScale(3.0, 0.0)
	SetPropBool(fireball, "m_bCritical", true)
	fireball.DispatchSpawn()
	
	player.EmitSound(fire_sound)
}

function OnUpdate()
{
	local time = Time()
	foreach (player in Ware_MinigamePlayers)
	{
		local attack_time = player.GetTauntAttackTime()
		if (attack_time >= time)
		{
			local target = player // squirrel needs this to be happy
			Ware_CreateTimer(function() 
			{
				if (target.IsAlive())
					SpawnFireball(target)
			}, attack_time - time)
			player.ClearTauntAttack()
		}

	}
}

function OnTakeDamage(params)
{
	if (params.inflictor.GetClassname() == "tf_projectile_spellfireball")
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer())
			Ware_PassPlayer(attacker, true)
		
		params.damage = 800.0
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0
}