
special_round <- Ware_SpecialRoundData
({
	name = "All In"
	author = ["Gemidyne", "pokemonPasta"]
	description = "If you lose one minigame, you lose ALL your points."
	categories = ["scores"]
})

function OnCalculateScore(data)
{
	if (data.passed)
		data.score += Ware_Minigame.boss ? Ware_PointsBossgame : Ware_PointsMinigame
	else
		data.score = 0
}