function OnUpdate(bot)
{
    local prop
    local lowest_dist = 999999
    local botOrigin = bot.GetOrigin()
	local time = Time()
    for (local can; can = FindByClassnameWithin(can, "prop_physics", bot.GetOrigin(), 2000);)
    {
		if (can.GetOwner() == null && can.GetScriptScope().GraceHolderTime < time)
        {
            local otherOrigin = can.GetOrigin()
            local dist = VectorDistance2D(botOrigin, otherOrigin)
            //Ware_ChatPrint(null, "{int} {int}", botOrigin, escapeDir)
            if (dist < lowest_dist)
            {
                lowest_dist = dist
                prop = can
            }
        }
    }
	local minidata = Ware_GetPlayerMiniData(bot)

	local picked = (minidata.PickedProp != bot && minidata.PickedProp.IsValid())
	if (!picked && prop)
    	Ware_BotShootTarget(bot, prop.GetOrigin(), true, true)
	else if (picked)
	{
    	local trash = FindByClassnameNearest("prop_dynamic", bot.GetOrigin(), 2000)
		local drop = false
		local length = bot.GetAbsVelocity().Length()
		//Ware_ChatPrint(null, "{int}", length)
		if (length < 20)
			drop = true
		Ware_BotShootTarget(bot, trash.GetOrigin() + Vector(0, 0, 50), drop, true)
	}
	
	
}
