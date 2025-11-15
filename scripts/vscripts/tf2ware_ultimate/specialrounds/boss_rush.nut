
special_round <- Ware_SpecialRoundData
({
	name = "Boss Rush"
	author = "pokemonPasta"
	description = "Five bosses will be played back to back!"
	categories = ["bosses"]
	boss_threshold = 0
	boss_count = 5
	priority = 100 // Load late so we can read boss_threshold after it's been modified by others.
})

function OnMultipleSpecialRounds(file_names, parent_special) {
	parent_special.boss_count = file_names.find("extended_round") != null
		? ceil(special_round.boss_count * 1.5)
		: special_round.boss_count
	parent_special.boss_threshold = 0
	special_round.description = format("%d bosses will be played back to back!", parent_special.boss_count)
}

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