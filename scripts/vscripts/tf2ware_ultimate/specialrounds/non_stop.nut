
special_round <- Ware_SpecialRoundData
({
	name = "Non-Stop"
	author = ["Gemidyne", "pokemonPasta"]
	description = "You get no breaks between minigames!"
	category = "timescale"
})

function OnBeginIntermission(is_boss)
{
	foreach (player in Ware_Players)
	{
		Ware_ShowScreenOverlay(player, null)
		Ware_ShowScreenOverlay2(player, null)
	}
	
	CreateTimer(@() Ware_StartMinigame(is_boss), 0.0)
	return true
}