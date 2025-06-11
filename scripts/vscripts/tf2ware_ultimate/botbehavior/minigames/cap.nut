
//TODO: actually target players??

function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("trigger_capture_area", bot.GetOrigin(), 3000)
	local dest = Vector()
    if (prop)
        dest = prop.GetCenter()

	Ware_BotShootTarget(bot, dest, false, true)
    
	if (RandomInt(0,2) == 0)
		bot.PressSpecialFireButton(-1)
}

