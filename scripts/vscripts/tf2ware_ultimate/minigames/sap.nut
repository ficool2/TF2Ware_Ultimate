minigame <- Ware_MinigameData
({
	name           = "Sap a Building"
	author         = ["Gemidyne", "pokemonPasta"]
	description    = 
	[
		"Sap a Building!"
		"Get a Building Sapped!"
	]
	duration       = 4.0
	music          = "funkymoves"
	custom_overlay = 
	[
		"sap_spy"
		"sap_engi"
	]
	min_players    = 2
	// allow damage so sappers work, but prevent player damage
	allow_damage   = true
	allow_building = true
	friendly_fire  = false
})

function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnStart()
{
	local engi_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
	foreach (player in Ware_MinigamePlayers)
	{				
		if (player.GetTeam() == engi_team)
		{
			Ware_SetPlayerMission(player, 1)
			Ware_SetPlayerClass(player, TF_CLASS_ENGINEER)
			Ware_GivePlayerWeapon(player, "Toolbox")
			Ware_GivePlayerWeapon(player, "Construction PDA", {}, false)
		}
		else
		{
			Ware_SetPlayerMission(player, 0)
			Ware_SetPlayerClass(player, TF_CLASS_SPY)
			Ware_GivePlayerWeapon(player, "Sapper")
		}
	}
}

function OnTakeDamage(params)
{
	if (params.const_entity.IsPlayer())
		return false
}

function OnGameEvent_player_sapped_object(params)
{
	local spy = GetPlayerFromUserID(params.userid)
	local engi = GetPlayerFromUserID(params.ownerid)
	
	if (spy)
		Ware_PassPlayer(spy, true)
	if (engi)
		Ware_PassPlayer(engi, true)
}
