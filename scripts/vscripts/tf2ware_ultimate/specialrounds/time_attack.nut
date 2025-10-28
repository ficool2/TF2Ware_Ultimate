last_timescale <- 1.0

special_round <- Ware_SpecialRoundData
({
	name = "Time Attack"
	author =  ["Gemidyne", "ficool2"]
	description = "The round keeps speeding up after every minigame."
	categories = ["timescale"]

	speedup_threshold = INT_MAX
})

function OnMinigameEnd()
{
	last_timescale = Ware_GetTimeScale() + 0.05
	Ware_SetTimeScale(last_timescale)
}

function OnBeginIntermission(is_boss)
{
	if (is_boss)
		Ware_SetTimeScale(last_timescale + 0.05)
}