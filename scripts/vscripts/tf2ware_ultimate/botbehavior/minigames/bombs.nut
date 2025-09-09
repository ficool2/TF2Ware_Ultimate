
//TODO: actually target players??

function OnUpdate(bot)
{
	local dest = Ware_MinigameLocation.center + Vector(0, 0, -700)

    local loco = bot.GetLocomotionInterface()
	Ware_BotShootTarget(bot, dest, false, true)
	if (RandomInt(0,2) == 0)
		bot.PressSpecialFireButton(-1)
    if (RandomInt(0,4) == 0)
        loco.Jump()
}

