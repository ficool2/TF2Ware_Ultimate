//todo pathfind

function OnUpdate(bot)
{
    local prop
    local data = Ware_GetPlayerMiniData(bot)
	local chance = 0.2
    if (!("prop" in data) || data.prop == null)
	{
		if(RandomFloat(0,1) < chance)
        	prop = RandomElement(Ware_MinigameScope.choices).brush
		else
			prop = Ware_MinigameScope.correct_choice.brush
        data.prop <- prop
		data.reached_front <- false
    }
    else
        prop = data.prop

	if (prop)
	{
    	local loco = bot.GetLocomotionInterface()
        
    	loco.FaceTowards(prop.GetCenter())
		BotLookAt(bot, prop.GetCenter(), 99999.0, 99999.0)
		local dest
		if(data.reached_front)
			dest = prop.GetCenter()
		else
		{
			dest = prop.GetCenter() + Vector(-400, 0, 0)
		}

		if(VectorDistance(bot.GetOrigin(), dest) < 90)
			data.reached_front = true
    	loco.Approach(dest, 999.0)
    	//if (RandomInt(0,50) == 0)
    	//    loco.Jump()
	}
}
