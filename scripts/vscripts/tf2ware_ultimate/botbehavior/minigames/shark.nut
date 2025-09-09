//todo pathfind and tend towards exit
function OnUpdate(bot)
{
	local mission = Ware_GetPlayerMission(bot)
    local botOrigin = bot.GetOrigin()

    local prop = Ware_MinigameScope.shark
    if (mission == 1)
    {
        local lowest_dist = 999999
        for (local other; other = FindByClassnameWithin(other, "player", bot.GetOrigin(), 3000);)
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
    }

    if (prop)
    {

        local escape_dist = 400
        local propOrigin = Vector()

        propOrigin = prop.GetOrigin()
        
        // Calculate direction from prop to bot and extend it further
        local escapeDir = botOrigin - propOrigin
        escapeDir.x = -fabs(escapeDir.x)
        if (escapeDir.x < -400) escapeDir.x = -400
        //Ware_ChatPrint(null, "{int}", escapeDir.x)

        escapeDir.z = 0
		escapeDir.Norm()
        local dest = botOrigin + escapeDir * escape_dist  // Move 200 units further away from prop
        //dest.x = Ware_Location.beach.center.x
        


        local loco = bot.GetLocomotionInterface()

        // Only move if too close to prop
        if (mission == 0 && VectorDistance2D(botOrigin, propOrigin) < escape_dist)
            dest = dest // Nothing
        else if (mission == 0)
        {
            dest = Vector(botOrigin.x - 5000, Ware_Location.beach.center.y, Ware_Location.beach.center.z)
        }
        else
            dest = propOrigin

        BotLookAt(bot, dest, 9999.0, 9999.0)
        loco.FaceTowards(dest)
        DebugDrawLine(botOrigin, dest, 0, 0, 255, true, 0.125)
        loco.Approach(dest, 999.0)

        if (RandomInt(0,10) == 0)
            bot.PressFireButton(-1)
    }
}