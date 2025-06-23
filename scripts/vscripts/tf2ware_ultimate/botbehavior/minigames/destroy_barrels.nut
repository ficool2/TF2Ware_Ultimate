function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics_multiplayer", bot.GetOrigin(), 2000)

	if (prop)
    	Ware_BotShootTarget(bot, prop.GetCenter(), true, false)
}
