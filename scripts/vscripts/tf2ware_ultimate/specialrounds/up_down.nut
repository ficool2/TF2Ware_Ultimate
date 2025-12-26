
special_round <- Ware_SpecialRoundData
({
	name = "Up and Down"
	author =  ["Gemidyne", "pokemonPasta"]
	description = "The speed will change randomly throughout the round."
	category = "timescale"
})

function OnSpeedup()
{
	CreateTimer(@() Ware_BeginIntermission(false), 0.0)
	return true
}

function OnBeginIntermission(is_boss)
{
	local timescale = RandomFloat(0.5, 2.5)
	
	if (is_boss)
	{
		// always force some kind of noticeable speed difference on bosses
		local delta = timescale - 1.0
		if (delta >= 0.0 && delta < 0.5)
			timescale += 0.5
		else if (delta < 0.0 && delta > -0.3)
			timescale -= 0.3			
	}
	
	Ware_SetTimeScale(timescale)
}
