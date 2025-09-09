//todo forward vector and before line

function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_soccer_ball", bot.GetOrigin(), 2000)

	if (prop)
    	Ware_BotShootTarget(bot, prop.GetOrigin(), true, true)
	
}
