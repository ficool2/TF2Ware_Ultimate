local arrow_speed = 1800    // hammer units/s

function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_dynamic", bot.GetOrigin(), 1500)
    local loco = bot.GetLocomotionInterface()

    //loco.Approach(Ware_MinigameLocation.center, 999.0)
    loco.FaceTowards(Ware_MinigameLocation.center)
	if (prop)
	{
        local dest = BotCalculateAimPosition(GetWeaponShootPosition(bot), prop.GetCenter(), prop.GetAbsVelocity(), 1980, 0.0)
        
    	loco.FaceTowards(dest)
		BotLookAt(bot, dest, 99999.0, 99999.0)
    	loco.Approach(prop.GetCenter(), 999.0)
		//if (RandomInt(0,4) == 0)
			bot.PressFireButton(-1)
    	//if (RandomInt(0,50) == 0)
    	//    loco.Jump()
	}
}
