
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("prop_physics", bot.GetOrigin(), 1000)
    if (prop)
    {
        BotLookAt(bot, prop.GetOrigin(), 350.0, 600.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(prop.GetOrigin())
        loco.Approach(prop.GetOrigin(), 999.0)
        if (RandomInt(0,50) == 0)
            loco.Jump()
    }
}
