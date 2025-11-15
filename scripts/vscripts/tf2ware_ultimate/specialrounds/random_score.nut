
special_round <- Ware_SpecialRoundData
({
	name = "Randomized Scores"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "Each minigame will be worth a random amount of points."
	categories = ["scores"]
})

random_score <- 0

function OnBeginIntermission(is_boss)
{
	if (is_boss)
	{
		random_score = RandomInt(5, 100)
	}
	else
	{
		random_score = RandomInt(1, 20)
		if (RandomInt(1, 10) == 1)
			random_score *= -1
	}

	Ware_ShowText(Ware_Players, CHANNEL_MINIGAME, format("The next %s will be worth %d point%s",
		is_boss ? "boss" : "minigame", random_score, random_score == 1 ? "" : "s"), Ware_GetThemeSoundDuration("intro"))
}

function OnCalculateScore(data)
{
	if (data.passed)
		data.score += random_score
}