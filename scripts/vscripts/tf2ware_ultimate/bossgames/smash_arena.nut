// TODO: Adjust knockback as needed
alive_players <- []

minigame <- Ware_MinigameData
({
	name           = "Smash Arena"
	author         = ["Gemidyne", "pokemonPasta"]
	description    = "Survive!"
	custom_overlay = "survive"
	duration       = 90.0
	min_players    = 2
	end_delay      = 1.0
	location       = "smasharena"
	music          = "smasharena"
	allow_damage   = true
	start_pass     = true
	fail_on_death  = true
	start_freeze   = 0.2
	max_scale      = 1.0
})

function OnPick()
{
	return !Ware_IsSpecialRoundSet("collisions")
}

function OnStart()
{
	alive_players = clone(Ware_MinigamePlayers)
	
	foreach (player in alive_players)
	{
		Ware_GetPlayerMiniData(player).sum_damage <- 175.0
	}
}

function RemovePlayer(player)
{
	local idx = alive_players.find(player)
	if (idx != null)
		alive_players.remove(idx)
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if(victim.IsPlayer())
	{
		local attacker = params.attacker
		local inflictor = params.inflictor
		if (attacker && attacker.IsPlayer())
		{
			local data = Ware_GetPlayerMiniData(victim)
			data.sum_damage += params.damage
			
			local kb_scale = 0.5
			local kb = Min(data.sum_damage * kb_scale, 1000.0)
			
			Ware_SlapEntity(victim, kb)
			params.damage = 1.0
		}
		else if (params.damage_type & DMG_FALL)
		{
			if (!inflictor || inflictor.GetClassname() != "trigger_hurt")
				params.damage = 0.0
		}
	}
}

function OnPlayerDeath(player, attacker, params)
{
	RemovePlayer(player)
	
	Ware_CreateTimer(function()
	{
		if (player.IsValid())
		{
			player.ForceRegenerateAndRespawn()
			Ware_TeleportPlayer(player, RandomElement(Ware_MinigameLocation.respawns), null, vec3_zero)
		}
	}, 3.0)
}

function OnPlayerDisconnect(player)
{
	RemovePlayer(player)
}

function OnCheckEnd()
{
	return alive_players.len() <= 1
}