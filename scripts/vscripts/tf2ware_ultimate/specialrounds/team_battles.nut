// TODO minigames such melee arena need to end when one team remains alive

special_round <- Ware_SpecialRoundData
({
	name = "Team Battles"
	author = ["Gemidyne", "pokemonPasta"]
	description = "Your score goes towards your team's score. The team with the highest score at the end wins!"
	categories = ["scores", "winners"]
	min_players = 4 // 2 on each team minimum seems fair, could do min_players = 3 either maybe. minimum players of 2 is pointless.
	friendly_fire = false

})

red_score <- 0
blu_score <- 0

top_team <- null

function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnCalculateScore(data)
{
	if (data.passed)
	{
		local team = data.player.GetTeam()
		local score = Ware_Minigame.boss ? Ware_PointsBossgame : Ware_PointsMinigame
		data.score += score
		if (team == TF_TEAM_RED)
			red_score += score
		else if (team == TF_TEAM_BLUE)
			blu_score += score
	}
}

function OnCalculateTopScorers(top_players)
{
	top_team = Max(red_score, blu_score) == red_score ? TF_TEAM_RED : TF_TEAM_BLUE

	foreach (data in Ware_MinigamePlayersData)
	{
		local player = data.player
		if (red_score == blu_score || player.GetTeam() == top_team)
			top_players.append(player)
	}

	foreach (mgr in TeamMgrs)
	{
		local team = GetPropInt(mgr, "m_iTeamNum")
		if (team == TF_TEAM_RED)
			SetPropInt(mgr, "m_iScore", red_score)
		else if (team == TF_TEAM_BLUE)
			SetPropInt(mgr, "m_iScore", blu_score)
	}
}

function OnDeclareWinners(top_players, top_score, winner_count)
{
	if (red_score == blu_score)
		Ware_ChatPrint(null, "The teams are tied at {int} points.", red_score)
	else
	{
		local red_won = top_team == TF_TEAM_RED

		local team   = red_won ? "RED TEAM" : "BLUE TEAM"
		local colour = red_won ? TF_COLOR_RED : TF_COLOR_BLUE
		local points = red_won ? red_score : blu_score

		Ware_ChatPrint(null, "{color}{str} {color}won with {int} points!", colour, team, TF_COLOR_DEFAULT, points)
	}
}

function OnEnd()
{
	foreach (mgr in TeamMgrs)
		SetPropInt(mgr, "m_iScore", 0)
}