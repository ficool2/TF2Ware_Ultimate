
special_round <- Ware_SpecialRoundData
({
	name = "Opposite Day"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "Do the opposite of what the minigame tells you."
	categories = ["scores"]
	opposite_win = true
})

function OnCalculateScore(data)
{
	if (!data.passed)
		data.score += Ware_Minigame.boss ? Ware_PointsBossgame : Ware_PointsMinigame
}