
special_round <- Ware_SpecialRoundData
({
	name = "Bonus Points"
	author = "pokemonPasta"
	description = "Extra points will be awarded in some minigames!"
	category = ""
	bonus_points = true
})

function OnPick()
{
	return !Ware_BonusPoints
}

// TODO: probably make this work during config bonus points too
function OnMinigameEnd()
{
	if(Ware_MinigamePlayers.len() > 1)
	{
		local passed_players = Ware_GetPassedPlayers()
		if(passed_players.len() == 1)
		{
			local player = passed_players[0]
			Ware_ChatPrint(null, "{color}{player} {color}was the only winner.", player.GetTeam() == TF_TEAM_BLUE ? TF_COLOR_BLUE : TF_COLOR_RED, player, TF_COLOR_DEFAULT)
			Ware_GiveBonusPoints(player)
		}
	}
}
