special_round <- Ware_SpecialRoundData
({
	name = "Inclinity Problem"
	author = "ficool2"
	description = "The world tilts as much as your score!"
	categories = []
})

function SetGlobalPlayerRoll()
{
	foreach (player in Ware_Players)
	{
		if (player.IsAlive())
		{
			local eye_angles = player.EyeAngles()
			local roll = GetPlayerRollAngle(player)
			eye_angles.z = roll
			player.ViewPunch(QAngle(0, 0, -roll))
			player.SnapEyeAngles(eye_angles)
		}
	}
}

function OnStart()
{
	SetGlobalPlayerRoll()
}

function OnMinigameEnd()
{
	SetGlobalPlayerRoll()
}

function GetPlayerRollAngle(player)
{
	return player.GetScriptScope().ware_data.score
}
