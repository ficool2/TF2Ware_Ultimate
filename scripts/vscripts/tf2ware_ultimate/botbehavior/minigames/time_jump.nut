
function OnStart(bot)
{
	local delay = 0.4

	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local loco = bot.GetLocomotionInterface()
		loco.Jump()
		return delay
	}, delay)
}
