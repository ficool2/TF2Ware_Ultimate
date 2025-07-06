function OnUpdate(bot)
{
    local prop = Ware_MinigameScope.barrel

	if (prop && prop.IsValid())
	{
        Ware_BotShootTarget(bot, prop.GetOrigin(), true, true)
		if(RandomInt(0,50) == 0)
			EntityEntFire(bot, "SpeakResponseConcept", "TLK_PLAYER_NICESHOT")
	}
}
