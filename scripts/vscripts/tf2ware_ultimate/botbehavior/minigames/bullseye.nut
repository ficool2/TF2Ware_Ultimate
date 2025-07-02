function OnUpdate(bot)
{
    local prop = FindByName(null, "bullseye")

	//todo aiming low for some reason
    if (prop)
        Ware_BotShootTarget(bot, prop.GetOrigin())
}
