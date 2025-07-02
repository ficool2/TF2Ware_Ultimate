function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(1.5, 5.0)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local clas = Ware_MinigameScope.desired_class
		if(RandomFloat(0, 1) < chance)
		{
			clas = RandomInt(TF_CLASS_FIRST, TF_CLASS_LAST)
		}
		Ware_SuicidePlayer(bot)
		Ware_SetPlayerClass(bot, clas)
	}, delay)
}