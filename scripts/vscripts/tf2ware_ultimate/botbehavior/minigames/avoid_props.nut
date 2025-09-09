
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 1000)
    Ware_BotAvoidProp(bot, prop, 200)
}