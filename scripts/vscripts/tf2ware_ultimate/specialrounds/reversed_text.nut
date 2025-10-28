special_round <- Ware_SpecialRoundData
({
	name = "Reversed Text"
	author =  ["Gemidyne", "ficool2"]
	description = "All text is reversed!"
	categories = ["text"]
	reverse_text = true
})

function OnStart()
{
	Ware_UpdateGlobalMaterialState()
}

function OnEnd()
{
	Ware_UpdateGlobalMaterialState()
}