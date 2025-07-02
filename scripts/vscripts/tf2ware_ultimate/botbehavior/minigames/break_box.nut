
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_dynamic", bot.GetOrigin(), 1000)
    local prop2 = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 2000)
    if(prop2)
        prop = prop2
    if (prop)
        Ware_BotShootTarget(bot, prop.GetOrigin(), true, true, true)
}
