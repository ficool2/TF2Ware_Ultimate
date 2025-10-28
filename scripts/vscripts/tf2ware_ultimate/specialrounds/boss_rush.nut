
special_round <- Ware_SpecialRoundData
({
	name = "Boss Rush"
	author = "pokemonPasta"
	description = "Five bosses will be played back to back!"
	categories = ["bosses", "load_last"]
	boss_threshold = 0
	boss_count = 5
})

// this just cancels the first minigame
started <- false
function OnBeginIntermission(is_boss)
{
	if (!started)
	{
		Ware_BeginBoss()
		started = true
		return true
	}
}