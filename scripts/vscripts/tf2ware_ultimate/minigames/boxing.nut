minigame <- Ware_MinigameData
({
	name           = "Boxing"
	author         = ["sasch", "ficool2"]
	description    = "Knockout your Opponents!"
	location       = "boxingring"
	duration       = 20.0
	end_delay      = 1.0
	music          = "boxfight"
	custom_overlay = "knockout"
	min_players    = 2
	start_freeze   = 0.5
	allow_damage   = true
	fail_on_death  = true
	friendly_fire  = false
	collisions     = true
	sort_teams     = true
})

start_sound <- "player/taunt_sfx_bell_single.wav"
end_sound   <- "player/taunt_bell.wav"

function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnPrecache()
{
	PrecacheSound(start_sound)
	PrecacheSound(end_sound)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_HEAVYWEAPONS, "Killing Gloves of Boxing")
	
	Ware_PlaySoundOnAllClients(start_sound)
	Ware_PlaySoundOnAllClients(start_sound)
	
	foreach (player in Ware_MinigamePlayers)
		Ware_GetPlayerMiniData(player).knockouts <- 0
}

function OnPlayerDeath(player, attacker, params)
{
	if (attacker && player != attacker)
		Ware_GetPlayerMiniData(attacker).knockouts++
}

function OnEnd()
{
	Ware_PlaySoundOnAllClients(end_sound)
	Ware_PlaySoundOnAllClients(end_sound)
	
	local red_count = Ware_GetAlivePlayers(TF_TEAM_RED).len()
	local blue_count = Ware_GetAlivePlayers(TF_TEAM_BLUE).len()
	// if one team is left, only everyone on that team wins
	if (red_count + blue_count > 0 && red_count == 0 || blue_count == 0)
	{
		if (red_count == 0)
		{
			Ware_ChatPrint(null, "{color}BLU{color} are the champions!", 
				TF_COLOR_BLUE, TF_COLOR_DEFAULT)
			foreach (player in Ware_GetTeamPlayers(TF_TEAM_BLUE))
				Ware_PassPlayer(player, true)
		}
		else if (blue_count == 0)
		{
			Ware_ChatPrint(null, "{color}RED{color} are the champions!", 
				TF_COLOR_RED, TF_COLOR_DEFAULT)	
			foreach (player in Ware_GetTeamPlayers(TF_TEAM_RED))
				Ware_PassPlayer(player, true)				
		}
	}
	else
	{
		// otherwise whoever knocked atleast 1 person out wins
		foreach (player in Ware_MinigamePlayers)
		{
			local knockouts = Ware_GetPlayerMiniData(player).knockouts
			if (knockouts > 0)
			{
				Ware_PassPlayer(player, true)
				if (knockouts >= 3)
					Ware_GiveBonusPoints(player)
			}
		}
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || Ware_GetAlivePlayers(TF_TEAM_BLUE).len() == 0
}