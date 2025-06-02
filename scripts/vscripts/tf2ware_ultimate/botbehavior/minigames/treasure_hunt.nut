//todo pathfind grapple
function OnUpdate(bot)
{
    local prop = FindByClassnameNearest("trigger_multiple", bot.GetOrigin(), 5000)
    if (prop)
    {
        BotLookAt(bot, prop.GetOrigin(), 350.0, 600.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(prop.GetOrigin())
        loco.Approach(prop.GetOrigin(), 999.0)
        if (RandomInt(0,50) == 0)
            loco.Jump()
        if (RandomInt(0,4) == 0)
			bot.PressFireButton(1)
    }
}
