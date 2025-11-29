special_round <- Ware_SpecialRoundData
({
	name        = "Math Only"
	author      = ["Gemidyne", "ficool2"]
	description = "Only math questions this round!"
	categories = ["text"] // this sucks enough as is, no need to make it impossible with no_text or reversed_text
	priority   = -100 // Changes minigames, needs to be first.
})

function GetMinigameName(is_boss)
{
	return is_boss ? "typing" : "math"
}