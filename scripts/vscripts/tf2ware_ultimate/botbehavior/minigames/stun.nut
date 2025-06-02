//todo inconsistent firing

function OnUpdate(bot)
{
	local prop
	local data = Ware_GetPlayerMiniData(bot)

	local arr = Shuffle(Ware_MinigamePlayers)

	if (!("prop" in data) || data.prop == null || !data.prop.IsValid() || !data.prop.IsAlive())
	{
		foreach (prop in arr)
		{
			if (prop && prop.IsPlayer())
			{
				local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
				data.dest <- dest
				data.prop <- prop
				break
			}
		}
	}
	if (data.prop)
	{
		BotLookAt(bot, data.prop.EyePosition(), 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(data.prop.EyePosition())
        loco.Approach(data.prop.EyePosition(), 999.0)
		if (RandomInt(0,1) == 0)
			bot.PressSpecialFireButton(-1)
        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
	}

}
