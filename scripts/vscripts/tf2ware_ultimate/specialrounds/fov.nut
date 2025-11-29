fov <- 130

special_round <- Ware_SpecialRoundData
({
	name             = "Quake Pro"
	author           = ["TonyBaretta", "ficool2"]
	description      = "FOV increased to 130!"
	categories 		 = ["fov"]
})

function OnStart()
{
	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", fov)
}

function OnMinigameEnd()
{
	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", fov)
}

function OnEnd()
{
	foreach (player in Ware_Players)
		SetPropInt(player, "m_iFOV", 0)
}