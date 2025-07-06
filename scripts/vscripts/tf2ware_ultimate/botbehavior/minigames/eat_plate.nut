//todo better pathing
function OnUpdate(bot)
{
    local prop
    local data = Ware_GetPlayerMiniData(bot)
    local doves = []
    if (!("dove" in data) || data.dove == null || !data.dove.IsValid())
	{
        for (local trig; trig = FindByClassname(trig, "trigger_multiple");)
        {
            trig.ValidateScriptScope
            local scope = trig.GetScriptScope()
            local chance = 0.1
            if("item_idx" in scope && (scope.item_idx == Ware_GetPlayerMission(bot) || RandomFloat(0, 1) < chance))
                data.dove <- trig
                prop = trig
                data.reached_front <- false
        }
    }
    else
        prop = data.dove

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
			dest = prop.GetCenter() + Vector(300, 0, 0)
		}

		if(VectorDistance(bot.GetOrigin(), dest) < 150)
			data.reached_front = true
    	loco.Approach(dest, 999.0)
    	//if (RandomInt(0,50) == 0)
    	//    loco.Jump()
	}
}
