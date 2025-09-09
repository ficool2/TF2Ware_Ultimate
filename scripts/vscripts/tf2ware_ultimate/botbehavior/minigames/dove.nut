local arrow_speed = 1800    // hammer units/s

function OnUpdate(bot)
{
    local prop
    local data = Ware_GetPlayerMiniData(bot)
    local doves = []
    if (!("dove" in data) || data.dove == null || !data.dove.IsValid())
	{
        for (prop; prop = FindByName(prop, "dovehuntdove");)
            doves.append(prop)
        if(!doves.len()) return
        prop = RandomElement(doves)
        data.dove <- prop
    }
    else
        prop = data.dove

	if (prop)
	{
    	local loco = bot.GetLocomotionInterface()
        local dest = BotCalculateAimPosition(GetWeaponShootPosition(bot), prop.GetCenter(), prop.GetAbsVelocity(), 1800, 0.5)
        
    	loco.FaceTowards(dest)
		BotLookAt(bot, dest, 99999.0, 99999.0)
        
    	loco.Approach(prop.GetCenter(), 999.0)
		if (RandomInt(0,4) == 0)
			bot.PressFireButton(-1)
    	//if (RandomInt(0,50) == 0)
    	//    loco.Jump()
	}
}
