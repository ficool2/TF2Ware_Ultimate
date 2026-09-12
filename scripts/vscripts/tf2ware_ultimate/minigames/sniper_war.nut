minigame <- Ware_MinigameData
({
	name           = "Sniper War"
	author         = "ficool2"
	description    = "Snipe a Player!"
	location       = "targetrange"
	duration       = 7.0
	end_delay      = 0.5
	music          = "nearend"
	min_players    = 2
	allow_damage   = true
	friendly_fire  = false
	custom_overlay = "snipe_player"
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SNIPER, "Hitman's Heatmaker")
}

function OnPlayerDeath(player, attacker, params)
{
	if (player && attacker && player != attacker)
		Ware_PassPlayer(attacker, true)
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0
}
