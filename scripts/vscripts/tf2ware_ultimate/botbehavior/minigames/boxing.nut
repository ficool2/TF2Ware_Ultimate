
//TODO: takedamage switch prop

function OnUpdate(bot)
{
	local prop
	local data = Ware_GetPlayerMiniData(bot)

	local arr = Shuffle(Ware_MinigamePlayers)
	if (!("dest" in data) || data.dest == null)
	{
		if (!("prop" in data) || data.prop == null || !data.prop.IsValid() || !data.prop.IsAlive())
		{
			foreach (prop in arr)
			{
				if (prop && prop.IsPlayer() && (prop.GetTeam() != bot.GetTeam()))
				{

					local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
					data.dest <- dest
					data.prop <- prop
					//DebugDrawLine(bot.GetOrigin(), data.dest,	255, 0, 0, true, 1)
					break
				}
			}
		}
		else
		{
			local dest = data.prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
			data.dest <- dest
		}
	}
	if (data.prop)
	{
		BotLookAt(bot, data.prop.GetCenter(), 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(data.prop.GetCenter())
        loco.Approach(data.prop.GetCenter(), 999.0)
		if (RandomInt(0,4) == 0)
			bot.PressFireButton(-1)
        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
		local dist = VectorDistance(data.dest, bot.GetCenter())
		local dist2 = VectorDistance(data.prop.GetCenter(), data.dest)
		//Ware_ChatPrint(null, "{int}", dist2)
		if (dist < 50 || dist2 > 200)
			data.dest = null
	}

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
