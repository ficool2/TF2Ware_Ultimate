special_round <- Ware_SpecialRoundData
({
	name        = "Sudden Death"
	author      =  ["Gemidyne", "ficool2"]
	description = "If you lose a minigame, you are out! Last survivor wins."
	min_players = 3
	categories = ["scores"]
})

ValidPlayers <- []

function OnStart()
{
	ValidPlayers = Ware_Players.filter(@(i, player) (player.GetTeam() & TF_TEAM_MASK) != 0)
}

function OnMinigameCleanup()
{
	local knocked_out = 0
	foreach (data in Ware_PlayersData)
	{
		local player = data.player
		local idx = ValidPlayers.find(player)
		if (idx == null)
			continue

		if (!data.passed || !(player.GetTeam() & TF_TEAM_MASK))
		{
			knocked_out++
			Ware_ChatPrint(player, "You have been {color}KNOCKED OUT{color}!", COLOR_RED, TF_COLOR_DEFAULT)
			ValidPlayers.remove(idx)
			if (player.IsAlive())
				Ware_SuicidePlayer(player)
		}
	}

	if (knocked_out > 0)
	{
		Ware_ChatPrint(null, "{int} {str} been knocked out! There are {int} {str} still standing.",
			knocked_out,
			knocked_out > 1 ? "players have" : "player has",
			ValidPlayers.len(),
			ValidPlayers.len() == 1 ? "player" : "players")
	}
	else
	{
		Ware_ChatPrint(null, "No one has been knocked out! There are {int} {str} still standing.",
			ValidPlayers.len(),
			ValidPlayers.len() == 1 ? "player" : "players")
	}
}

function OnCalculateTopScorers(top_players)
{
	local top_score = 1
	foreach (player in ValidPlayers)
	{
		local data = Ware_GetPlayerData(player)
		if (data.score > top_score)
		{
			top_score = data.score
			top_players.clear()
			top_players.append(player)
		}
		else if (data.score == top_score)
		{
			top_players.append(player)
		}
	}
}

function OnCheckGameOver()
{
	return ValidPlayers.len() <= 1
}

function OnPlayerDisconnect(player)
{
	local idx = ValidPlayers.find(player)
	if (idx != null)
		ValidPlayers.remove(idx)
}

function CanPlayerRespawn(player)
{
	return ValidPlayers.find(player) != null
}

function GetValidPlayers()
{
	return ValidPlayers
}