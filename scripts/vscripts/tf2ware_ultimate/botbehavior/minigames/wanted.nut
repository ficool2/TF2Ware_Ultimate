function OnUpdate(bot)
{
    local prop = Ware_MinigameScope.last_prop

	if (prop)
    	Ware_BotShootTarget(bot, prop.GetCenter())
	
}
