overlay <- "shaders/tf2ware_ultimate/nostalgia"

special_round <- Ware_SpecialRoundData
({
	name = "Nostalgia"
	author = "ficool2"
	description = "Taking you back to the past!"
	categories = ["overlay"]
})

function GetOverlay2()
{
	return overlay
}

function OnStart()
{
	Ware_ShowScreenOverlay2(Ware_Players, overlay)
	Ware_RunClientCommand(Ware_Players, "dsp_player 59")
}

function OnMinigameStart()
{
	Ware_ShowScreenOverlay2(Ware_Players, overlay)
}

function OnMinigameEnd()
{
	Ware_RunClientCommand(Ware_Players, "dsp_player 59")
}

function OnEnd()
{
	Ware_RunClientCommand(Ware_Players, "dsp_player 0")
	Ware_ShowScreenOverlay2(Ware_Players, null)
}