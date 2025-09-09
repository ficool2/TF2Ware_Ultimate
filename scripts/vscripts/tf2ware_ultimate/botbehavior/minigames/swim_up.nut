function OnUpdate(bot)
{
	local prop

	local arr = Shuffle(Ware_MinigamePlayers)
	foreach (prop in arr)
	{
		if (prop && prop.IsPlayer() && prop.IsAlive())
		{
			local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 1000)

			BotLookAt(bot, prop.GetCenter(), 350.0, 600.0)
        	local loco = bot.GetLocomotionInterface()
        	loco.FaceTowards(prop.GetCenter())
        	loco.Approach(dest, 999.0)
			//if (RandomInt(0,4) == 0)
				bot.PressFireButton(-1)
        	//if (RandomInt(0,1) == 0)
        		loco.Jump()

			break
		}
	}
}
