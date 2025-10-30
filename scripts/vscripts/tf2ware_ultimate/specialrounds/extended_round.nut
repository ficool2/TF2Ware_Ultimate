threshold_multiplier <- 1.5
threshold <- ceil(Ware_BossThreshold * threshold_multiplier)

special_round <- Ware_SpecialRoundData
({
	name = "Extended Round"
	author = ["Gemidyne", "pokemonPasta"]
	description = format("%d minigames will be played before the boss.", threshold)
	categories = []
	boss_threshold = threshold
	priority = 50
})

function OnMultipleSpecialRounds(file_names, parent_special) {
	parent_special.boss_threshold = ceil(parent_special.boss_threshold * threshold_multiplier)

	if (file_names.find("boss_rush") != null)
	{
		special_round.description = "Additional boss games will be played in Boss Rush!"
	} else {
		special_round.description = format("%d minigames will be played before the boss.", parent_special.boss_threshold)
	}
}
