minigame <- Ware_MinigameData
({
	name           = "Heavy vs Medic"
	author         = ["tilderain"]
	description    = 
	[
		"Heal and uber to survive!"
		"Kill a medic!"
	]
	duration       = 7
	music          = "farm"
	custom_overlay = 
	[
		"heal_survive"
		"kill_medic"
	]
	min_players   = 4
	fail_on_death = true
	allow_damage  = true
	friendly_fire = false
})


MISSION_MEDIC <- 0
MISSION_HEAVY <- 1

medics <- []

function OnStart()
{
	local heavy_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.GetTeam() == heavy_team)
		{
			Ware_SetPlayerMission(player, MISSION_HEAVY)
			Ware_SetPlayerClass(player, TF_CLASS_HEAVYWEAPONS)
			Ware_StripPlayer(player, false)
			Ware_SetPlayerTeam(player, TF_TEAM_RED)
			Ware_GivePlayerWeapon(player, "Minigun", { "deploy time increased" : 1.75 })
		}
		else
		{
			Ware_SetPlayerMission(player, MISSION_MEDIC)
			Ware_SetPlayerClass(player, TF_CLASS_MEDIC)
			Ware_StripPlayer(player, false)
			Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
			Ware_GivePlayerWeapon(player, "Medi Gun", {"heal rate bonus" : 5, "ubercharge rate bonus" : 25})
			medics.append(player)
		}
	}
	
}

function OnPlayerDeath(player, attacker, params)
{
	if (attacker && player != attacker)
		Ware_PassPlayer(attacker, true)
		
	local assister = GetPlayerFromUserID(params.assister)
	if (assister && player != assister)
		Ware_PassPlayer(assister, true)
}


function OnEnd()
{
	local alive_medics = medics.filter(@(i, player) player.IsValid() && player.IsAlive())
	
	foreach (player in alive_medics)
	{
		player.RemoveCond(TF_COND_INVULNERABLE)
		Ware_PassPlayer(player, true)
	}
	
}

