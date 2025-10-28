
special_round <- Ware_SpecialRoundData
({
	name = "Slow-Mo"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "Everything slows down!"
	categories = ["timescale"]
	// TODO: boss_threshold = 0.5 * current boss threshold

})

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