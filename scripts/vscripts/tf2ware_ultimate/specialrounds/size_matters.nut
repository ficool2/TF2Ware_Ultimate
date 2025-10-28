special_round <- Ware_SpecialRoundData
({
	name = "Size Matters"
	author = "pokemonPasta"
	description = "Your size will change to reflect your score!"
	categories = []
})

max_scale <- 2.0

topscore_scale <- 1.1
scale_increase <- max_scale / Ware_BossThreshold

function OnCalculateTopScorers(top_players)
{
	topscore_scale = Min(topscore_scale + scale_increase, max_scale)

	// do everything as normal
	local top_score = 1
	foreach (data in Ware_MinigamePlayersData)
	{
		if (data.score > top_score)
		{
			top_score = data.score
			top_players.clear()
			top_players.append(data.player)
		}
		else if (data.score == top_score)
		{
			top_players.append(data.player)
		}
	}

	// also resize everyone
	foreach (data in Ware_PlayersData)
		Ware_SetPlayerScale(data.player, RemapValClamped(data.score, 0.0, top_score, 0.5, topscore_scale), 0.5)

	// since this is an expensive operation, spread it as one player per frame
	local players = clone(Ware_Players)
	CreateTimer(function()
	{
		if (players.len() > 0)
		{
			local player = players.pop()
			if (player.IsValid() && player.IsAlive())
				UnstuckPlayer(player)
			return TICKDT
		}
	}, TICKDT)
}