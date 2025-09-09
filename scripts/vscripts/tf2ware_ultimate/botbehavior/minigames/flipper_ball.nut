//todo dodge
function OnUpdate(bot)
{
    local dest
    if (Ware_MinigameMode == 1)
        dest = Ware_MinigameLocation.center_bottom
    else
        dest = Ware_MinigameLocation.center_top
    BotLookAt(bot, dest, 350.0, 600.0)
    local loco = bot.GetLocomotionInterface()
    loco.FaceTowards(dest)
    loco.Approach(dest, 999.0)
    if (bot.GetFlags() & FL_ONGROUND && bot.GetAbsVelocity().Length() > 290.0)
        loco.Jump()
    bot.RemoveFlag(FL_DUCKING)
}
