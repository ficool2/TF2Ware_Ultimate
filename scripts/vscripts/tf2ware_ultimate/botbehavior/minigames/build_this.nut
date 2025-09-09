

//todo better weapon switch
function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(0.5, 1)
	
	local type = Ware_MinigameScope.building_mode[2]
	if (type == null) type = 0
	if (RandomFloat(0,1) < chance)
		type = RandomInt(0,2)

	Ware_BotCreateMinigameTimer(bot, function()
	{	
		for (local i = 0; i < MAX_WEAPONS; i++)
		{
			local weapon = NetProps.GetPropEntityArray(bot, "m_hMyWeapons", i)
			if (weapon == null || weapon.IsMeleeWeapon())
				continue
			SetPropInt(weapon, "m_iObjectType", type)
			if (Ware_MinigameMode == 2)
				SetPropInt(weapon, "m_iObjectMode", 0)
			else if (Ware_MinigameMode == 3)
				SetPropInt(weapon, "m_iObjectMode", 1)

			bot.Weapon_Switch(weapon)
			bot.PressFireButton(-1)
		}
	}, delay)


}
function OnUpdate(bot)
{

	local weapon = bot.GetActiveWeapon()
	if (weapon && weapon.GetSlot() == TF_SLOT_MELEE)
	{
		KillWeapon(weapon)
	}

	local prop
    local lowest_dist = 999999
    local botOrigin = bot.GetOrigin()
    for (local other; other = FindByClassnameWithin(other, "player", bot.GetOrigin(), 1500);)
    {
        if (other != bot && other.IsValid() && other.IsAlive())
        {
            local otherOrigin = other.GetOrigin()
            local dist = VectorDistance2D(botOrigin, otherOrigin)
            //Ware_ChatPrint(null, "{int} {int}", botOrigin, escapeDir)
            if (dist < lowest_dist)
            {
                lowest_dist = dist
                prop = other
            }
        }
    }
	Ware_BotAvoidProp(bot, prop, 400, false)
	BotLookAt(bot, Ware_MinigameLocation.center, 999, 999)
}


/*
function OnUpdate(bot)
{
	local prop
	local data = Ware_GetPlayerMiniData(bot)
	for (prop; prop = Entities.FindByClassname(prop, "player");)
	{
		if (prop && prop.IsPlayer() && (prop.GetTeam() != bot.GetTeam()))
		{
			if (!("dest" in data) || data.dest == null)
			{
				local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
				data.dest <- dest
				//DebugDrawLine(bot.GetOrigin(), data.dest,	255, 0, 0, true, 1)
			}
			BotLookAt(bot, prop.GetCenter(), 9999.0, 9999.0)
        	local loco = bot.GetLocomotionInterface()
        	loco.FaceTowards(prop.GetCenter())
        	loco.Approach(data.dest, 999.0)
			if (RandomInt(0,4) == 0)
				bot.PressFireButton(-1)
        	//if (RandomInt(0,50) == 0)
        	//    loco.Jump()
			local dist = VectorDistance(data.dest, bot.GetCenter())
			local dist2 = VectorDistance(prop.GetCenter(), data.dest)
			//Ware_ChatPrint(null, "{int}", dist2)
			if (dist < 50 || dist2 > 200)
				data.dest = null
			break
		}
	}
}*/
