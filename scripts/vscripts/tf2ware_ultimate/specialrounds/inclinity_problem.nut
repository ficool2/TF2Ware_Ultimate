special_round <- Ware_SpecialRoundData
({
	name = "Inclinity Problem"
	author = "ficool2"
	description = "The world tilts more after every minigame!"
	category = ""
})

roll <- 0
direction <- 1

function OnStart()
{
	roll = 0
	direction = RandomInt(0, 1) ? 1 : -1
}

function OnUpdate()
{
	foreach (player in Ware_Players)
	{
		if (!player.IsAlive())
			continue

		local eye_angles = player.EyeAngles()
		if (fabs(eye_angles.z - (roll * direction)) > 0.1)
		{
			eye_angles.z = roll * direction
			player.SnapEyeAngles(eye_angles)
		}
	}
}

function OnMinigameEnd()
{
	roll += 1.0
}