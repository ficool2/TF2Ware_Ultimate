function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(1.5, 5.0)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local count = Ware_MinigameScope.count
		if(RandomFloat(0, 1) < chance)
		{
			count += RandomInt(-3,3)
		}
		local word = Ware_BotTryWordTypo(bot, count.tostring(), chance)		
		Say(bot, word, false)
	}, delay)
}