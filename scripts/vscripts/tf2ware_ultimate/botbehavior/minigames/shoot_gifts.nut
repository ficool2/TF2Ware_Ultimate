//todo bomb
function OnUpdate(bot)
{
	local prop
	if (Ware_MinigameScope.gifts_active.len())
    	prop = RandomElement(Ware_MinigameScope.gifts_active).gift

	if (prop)
	{
        Ware_BotShootTarget(bot, prop.GetCenter(), true, true)
		if(RandomInt(0,50) == 0)
			EntityEntFire(bot, "SpeakResponseConcept", "TLK_PLAYER_NICESHOT")
	}
}
