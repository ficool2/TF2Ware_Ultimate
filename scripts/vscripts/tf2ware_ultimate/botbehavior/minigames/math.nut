function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.15
	local delay = RandomFloat(1.5, 3.5)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local count = Ware_MinigameScope.answer
		if(RandomFloat(0, 1) < chance)
		{
			count += RandomInt(-5,5)
		}
		local word = Ware_BotTryWordTypo(bot, count.tostring(), chance)		
		Say(bot, word, false)
	}, delay)
}