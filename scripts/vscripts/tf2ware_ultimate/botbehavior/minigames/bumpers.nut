
//TODO: actually target players??

function OnUpdate(bot)
{
	local dest = Ware_MinigameLocation.center

	Ware_BotShootTarget(bot, dest, true, true, true)
}

