
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("trigger_hurt", bot.GetOrigin(), 3000)
    Ware_BotAvoidProp(bot, prop, 1000)
}