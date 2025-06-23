function OnStart(bot)
{
	local delay = 0.016

	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local loco = bot.GetLocomotionInterface()
		loco.Jump()
		return delay
	}, 0)
}
