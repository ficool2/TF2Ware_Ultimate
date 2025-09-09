
function OnUpdate(bot)
{
	local prop
	local data = Ware_GetPlayerMiniData(bot)
	local arr = Shuffle(Ware_MinigamePlayers)
	foreach (prop in arr)
	{
		if (prop && prop.IsPlayer() && prop.IsAlive() && (prop.GetTeam() != bot.GetTeam()))
		{
			if (!("dest" in data) || data.dest == null)
			{
				local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
				data.dest <- dest
				data.prop <- prop
				//DebugDrawLine(bot.GetOrigin(), data.dest,	255, 0, 0, true, 1)
			}
			BotLookAt(bot, data.prop.GetCenter(), 9999.0, 9999.0)
        	local loco = bot.GetLocomotionInterface()
        	loco.FaceTowards(data.prop.GetCenter())
        	loco.Approach(data.dest, 999.0)
			if (RandomInt(0,4) == 0)
				bot.PressFireButton(-1)
        	//if (RandomInt(0,50) == 0)
        	//    loco.Jump()
			local dist = VectorDistance(data.dest, bot.GetCenter())
			local dist2 = VectorDistance(data.prop.GetCenter(), data.dest)
			//Ware_ChatPrint(null, "{int}", dist2)
			if (dist < 50 || dist2 > 200)
				data.dest = null
			if (VectorDistance(bot.GetCenter(), data.prop.GetCenter()) < 900)
				bot.Taunt(TAUNT_BASE_WEAPON, 0)
			break
		}
	}
}
