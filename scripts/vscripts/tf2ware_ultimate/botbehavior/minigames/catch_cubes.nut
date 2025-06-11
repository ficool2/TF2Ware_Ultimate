
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 1000)
    if (prop)
        Ware_BotShootTarget(bot, prop.GetOrigin(), false, true)
    
}
