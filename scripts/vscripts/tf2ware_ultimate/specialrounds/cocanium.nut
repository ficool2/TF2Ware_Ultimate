overlay <- "shaders/tf2ware_ultimate/cocanium"
sky_name <- ""

special_round <- Ware_SpecialRoundData
({
	name = "Cocanium"
	author = "ficool2"
	description = "Woah.. I feel different..."
	categories = ["overlay"]
})

function GetOverlay2()
{
	return overlay
}

function OnStart()
{
	Ware_ShowScreenOverlay2(Ware_Players, overlay)
	Ware_RunClientCommand(Ware_Players, "dsp_player 47")
	sky_name = Convars.GetStr("sv_skyname")
	SetSkyboxTexture("sky_trainyard_01")
}

function OnMinigameStart()
{
	Ware_RunClientCommand(Ware_Players, "dsp_player 47")
	Ware_ShowScreenOverlay2(Ware_Players,overlay)
}

function OnEnd()
{
	Ware_RunClientCommand(Ware_Players, "dsp_player 0")
	Ware_ShowScreenOverlay2(Ware_Players, null)
	SetSkyboxTexture(sky_name)
}