special_round <- Ware_SpecialRoundData
({
	name		= "Double Vision"
	author		= ["TonyBaretta", "ficool2"]
	description	= "Zoom in and zoom out."
	category	= ""
})

function OnStart()
{
	local roll = RandomInt(1, 2)
	local fov = 50
	if (roll == 2) fov = 130

	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", fov)
}

function OnMinigameEnd()
{
	local roll = RandomInt(1, 2)
	local fov = 50
	if (roll == 2) fov = 130

	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", fov)
}

function OnEnd()
{
	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", 0)
}
