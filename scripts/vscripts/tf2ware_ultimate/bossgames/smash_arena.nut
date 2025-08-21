
// TODO: Adjust knockback as needed

center <- Ware_MinigameLocation.center * 1.0
respawn_vectors <- [
	Vector(4365, 2630, -11400)
	Vector(2865, 2630, -11400)
	Vector(3615, 3380, -11400)
	Vector(3615, 1880, -11400)
]
alive_players <- clone(Ware_MinigamePlayers)

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
	foreach(player in Ware_MinigamePlayers)
	{
		Ware_GetPlayerMiniData(player).sum_damage <- 175.0
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if(victim.IsPlayer())
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer())
		{
			local data = Ware_GetPlayerMiniData(victim)
			data.sum_damage += params.damage
			
			local kb_scale = 0.5
			local kb = Min(data.sum_damage * kb_scale, 1000.0)
			
			Ware_SlapEntity(victim, kb)
			params.damage = 0.0
		}
		else if ((params.damage_type & DMG_FALL) && params.inflictor.GetClassname() != "trigger_hurt")
			params.damage = 0.0
	}
}

function OnPlayerDeath(player, attacker, params)
{
	local idx = alive_players.find(player)
	if(idx != null)
		alive_players.remove(idx)
	
	Ware_CreateTimer(function(){
		player.ForceRegenerateAndRespawn()
		Ware_TeleportPlayer(player, RandomElement(respawn_vectors), null, vec3_zero)
	}, 3.0)
}

function OnCheckEnd()
{
	return alive_players.len() < 2
}