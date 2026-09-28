special_round <- Ware_SpecialRoundData
({
	name		= "Magnetic Field"
	author		= "Kimmy"
	description	= "Nearby players are being pulled towards each other."
	min_players	= 2
	category	= ""
	convars		=
	{
		tf_avoidteammates_pushaway = 0
	}
})

function OnUpdate()
{
	local dt = FrameTime()
	local players = Ware_GetAlivePlayers()

	local maxDist = 250.0 // pull distance between players
	local strength = 1000.0 // pull strength

	foreach (player in players)
	{
		if (!player.IsValid())
			continue

		local origin = player.GetOrigin()
		local avgDir = Vector(0, 0, 0)
		local totalWeight = 0.0

		foreach (other in players)
		{
			if (other == player || !other.IsValid())
				continue

			local offset = other.GetOrigin() - origin
			local dist = offset.Length()

			if (dist > maxDist || dist <= 5.0)
				continue

			offset.z = 0
			offset.Norm()

			local weight = pow(1.0 - (dist / maxDist), 1.2) // pull strength based on distance to a player

			avgDir += offset * weight
			totalWeight += weight
		}

		if (totalWeight > 0.0)
		{
			local invWeight = 1.0 / totalWeight
			avgDir *= invWeight
			avgDir.Norm()

			player.ApplyAbsVelocityImpulse(avgDir * strength * dt)
		}
	}
}