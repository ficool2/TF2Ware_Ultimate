special_round <- Ware_SpecialRoundData
({
	name = "Slow-Mo"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "Everything slows down!"
	categories = ["timescale"]
	boss_threshold = 10
})

function OnMultipleSpecialRounds(file_names, parent_special) {
	parent_special.boss_threshold = special_round.boss_threshold
}

function OnSpeedup()
{
	CreateTimer(@() Ware_BeginIntermission(false), 0.0)
	return true
}

function OnMinigameEnd()
{
	Ware_SetTimeScale(Ware_GetTimeScale() - 0.05)
}

function OnBeginIntermission(is_boss)
{
	if (is_boss)
		Ware_SetTimeScale(0.75)
}