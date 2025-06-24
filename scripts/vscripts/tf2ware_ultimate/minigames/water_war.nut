minigame <- Ware_MinigameData
({
	name           = "Water War"
	author         = ["TonyBaretta", "ficool2"]
	description    = "Kill a Player!"
	duration       = 11.5
	end_delay      = 0.5
	music          = "adventuretime"
	min_players    = 2
	max_scale      = 1.5
	allow_damage   = true
	collisions     = true
	custom_overlay = "kill_player"
	convars =
	{
		tf_avoidteammates = 0
	}
})

function OnTeleport(players)
{
	local radius = ((Ware_MinigameLocation.maxs.x - Ware_MinigameLocation.mins.x) * 0.5) - 76.0
	local height = 1024.0
	local circles = Clamp(ceil(players.len() / 24.0).tointeger(), 1, 4)
	for (local c = 0; c < circles; c++)
	{
		local targets = players.filter(@(i, player) i % circles == c)
		Ware_TeleportPlayersCircle(targets, Ware_MinigameLocation.center + Vector(0, 0, height), radius)
		height += 384.0
	}
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Neon Annihilator")
	foreach (player in Ware_MinigamePlayers)
		player.AddCond(TF_COND_SWIMMING_CURSE)
}

function OnTakeDamage(params)
{
	params.damage = 950.0
}

function OnPlayerDeath(player, attacker, params)
{
	if (attacker && player != attacker)
		Ware_PassPlayer(attacker, true)
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveCond(TF_COND_SWIMMING_CURSE)
		player.RemoveCond(TF_COND_URINE)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() <= 1
}