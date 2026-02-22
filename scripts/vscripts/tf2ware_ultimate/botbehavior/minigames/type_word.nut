function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(1.5, 5.0)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local word = Ware_BotTryWordTypo(bot, Ware_MinigameScope.word, chance)		
		Say(bot, word, false)
	}, delay)
}