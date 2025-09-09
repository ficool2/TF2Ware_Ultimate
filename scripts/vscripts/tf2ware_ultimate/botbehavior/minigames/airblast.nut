
//TODO: actually target players??

function OnUpdate(bot)
{
	local dest = Ware_MinigameLocation.center

	Ware_BotShootTarget(bot, dest, false, true)
	if (RandomInt(0,2) == 0)
		bot.PressSpecialFireButton(-1)
}

