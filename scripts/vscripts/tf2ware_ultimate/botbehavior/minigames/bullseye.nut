function OnUpdate(bot)
{
    local prop = FindByName(null, "bullseye")
	if (prop)
	{
    	local loco = bot.GetLocomotionInterface()
        local dest = prop.GetCenter()
    	loco.FaceTowards(dest)
		BotLookAt(bot, dest, 9999.0, 9999.0)
		if (RandomInt(0,4) == 0)
			bot.PressFireButton(-1)
    	//if (RandomInt(0,50) == 0)
    	//    loco.Jump()
	}
}
