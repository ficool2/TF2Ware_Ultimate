//todo survive first jump
//todo leave arena ??
function OnUpdate(bot)
{
    bot.SetAutoJump(99999,99999)
    local prop = FindByName(null, "jumprope_door")
    bot.RemoveBotAttribute(AUTO_JUMP)
    if (prop)
    {
        local pcen = prop.GetCenter()
        local porg = prop.GetOrigin()
        BotLookAt(bot, pcen, 350.0, 600.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(pcen)
        local vec = Vector(120, -1000, -4900)
        if(VectorDistance(bot.GetOrigin(), vec) > 100)
            loco.Approach(vec, 999.0)
        //Ware_ChatPrint(null, "{int}", pcen)
        local speed = GetPropFloat(prop, "m_flSpeed")
        local dist = 200 + (speed/1.8)
        //Ware_ChatPrint(null, "{int}", dist)
        //Ware_ChatPrint(null, "{int}", VectorDistance(bot.GetOrigin(), pcen))
        if (VectorDistance(bot.GetOrigin(), pcen) < dist)
            if(pcen.z < -4770 + (speed / 4))
            {
               loco.Jump()
            }

        if(bot.GetFlags() & FL_ONGROUND)
        {
            bot.RemoveFlag(FL_DUCKING)
        }
        else
        {
            bot.AddFlag(FL_DUCKING)
        }
        
            
    }
}


function OnEnd(bot)
{
	bot.RemoveFlag(FL_DUCKING)
}