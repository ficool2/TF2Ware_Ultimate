//todo better distance check
function OnUpdate(bot)
{
    //bot.SetAutoJump(99999,99999)
    local prop = FindByClassnameNearest("env_beam", bot.GetOrigin(), 1500)
    //bot.RemoveBotAttribute(AUTO_JUMP)
    if (prop)
    {
        local pcen = prop.GetCenter()
        BotLookAt(bot, pcen, 350.0, 600.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(pcen)
        loco.Approach(pcen, 999.0)

        if (VectorDistance2D(bot.GetOrigin(), pcen) < 500)
            loco.Jump()

        if(pcen.z > -790)
        {
            bot.AddFlag(FL_DUCKING)
        }
        else
        {
            bot.RemoveFlag(FL_DUCKING)
        }
    }
}


function OnEnd(bot)
{
	bot.RemoveFlag(FL_DUCKING)
}