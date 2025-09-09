//TODO doesn't work

function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(0.5, 2.0)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		if (RandomFloat(0, 1) > chance)
		{
			local loco = bot.GetLocomotionInterface()
			loco.Jump()
		}
	}, delay)
}
