//todo escape direction away from maxs

function OnUpdate(bot)
{

    local botOrigin = bot.GetOrigin()
    local prop = FindByClassnameNearest("ghost", bot.GetOrigin(), 2000)


    if (prop)
    {

        local propOrigin = prop.GetOrigin()
        local escape_dist = 800
        // Calculate direction from prop to bot and extend it further
        local escapeDir = botOrigin - propOrigin
        escapeDir.z = 0
		escapeDir.Norm()
        local dest = botOrigin + escapeDir * escape_dist  // Move 200 units further away from prop
        
        //Ware_ChatPrint(null, "{int} {int}", botOrigin, escapeDir)

        BotLookAt(bot, dest, 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)

        DebugDrawLine(botOrigin, dest, 0, 0, 255, true, 0.125)

        // Only move if too close to prop
        if(VectorDistance2D(botOrigin, propOrigin) < escape_dist)
            loco.Approach(dest, 999.0)

        if (RandomInt(0,10) == 0)
            bot.PressFireButton(-1)
    }
}