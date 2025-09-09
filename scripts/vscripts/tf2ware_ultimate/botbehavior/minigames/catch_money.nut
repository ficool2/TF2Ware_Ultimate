
//todo better filter
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 2000)
    local index = GetPropInt(prop, "m_nModelIndex")
    if (prop && index != Ware_MinigameScope.bomb_modelindex)
    {
        Ware_BotShootTarget(bot, prop.GetOrigin(), false, true)
    }
}
