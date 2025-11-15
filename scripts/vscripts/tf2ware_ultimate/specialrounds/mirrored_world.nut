overlay <- "shaders/tf2ware_ultimate/mirror"

special_round <- Ware_SpecialRoundData
({
	name = "Mirrored World"
	author = "ficool2"
	description = "The world is mirrored!"
	categories = ["overlay"]
})

function GetOverlay2()
{
	return overlay
}

function OnStart()
{
	Ware_ShowScreenOverlay2(Ware_Players, overlay)
}

function OnMinigameStart()
{
	Ware_ShowScreenOverlay2(Ware_Players, overlay)
}

function OnEnd()
{
	Ware_ShowScreenOverlay2(Ware_Players, null)
}