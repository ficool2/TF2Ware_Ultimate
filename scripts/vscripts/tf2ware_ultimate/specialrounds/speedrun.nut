special_round <- Ware_SpecialRoundData
({
	name = "Speedrun"
	author = "ficool2"
	description = "The round is 3x faster!!"
	categories = ["timescale"]
	max_players = 40
})

function OnStart()
{
	Ware_SetTimeScale(3.0)
}

function OnBeginIntermission(is_boss)
{
	if (is_boss)
		Ware_SetTimeScale(3.0)
}