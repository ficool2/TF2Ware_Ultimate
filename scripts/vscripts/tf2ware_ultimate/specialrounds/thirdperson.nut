
special_round <- Ware_SpecialRoundData
({
	name = "Thirdperson"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "See the game from a new perspective."
	categories = []
})


function OnStart()
{
	foreach (player in Ware_Players)
		player.SetForcedTauntCam(1)
}

function OnMinigameStart()
{
	foreach (player in Ware_Players)
		player.SetForcedTauntCam(1)
}

function OnMinigameEnd()
{
	foreach (player in Ware_Players)
		player.SetForcedTauntCam(1)
}

function OnEnd()
{
	foreach (player in Ware_Players)
		player.SetForcedTauntCam(0)
}
