
//TODO

function OnUpdate(bot)
{
	local dest = Ware_MinigameLocation.center + Vector(0, 0, -700)

	BotLookAt(bot, dest, 9999.0, 9999.0)
    local loco = bot.GetLocomotionInterface()
    loco.FaceTowards(dest)
    loco.Approach(dest, 999.0)
    if (RandomInt(0,2) == 0)
		bot.PressSpecialFireButton(-1)
	if (RandomInt(0,4) == 0)
		bot.PressFireButton(-1)
    if (RandomInt(0,4) == 0)
        loco.Jump()
}

