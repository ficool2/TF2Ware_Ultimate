
function OnUpdate(bot)
{

    local location_name = Ware_MinigameLocation.name
	local platform_name = format("%s_platform_%d", location_name, Ware_MinigameScope.platform_index)	
	local prop = FindByName(null, platform_name)

    if (prop)
    {
        local propOrigin = prop.GetOrigin()

		local dest = prop.GetOrigin()
        //Ware_ChatPrint(null, "{int} {int}", botOrigin, escapeDir)

        BotLookAt(bot, dest, 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)

		DebugDrawLine(bot.GetOrigin(), dest, 0, 0, 255, true, 0.125)

        loco.Approach(dest, 999.0)

        if (RandomInt(0,4) == 0)
            bot.PressFireButton(-1)

        if (RandomInt(0,50) == 0)
            loco.Jump()
    }
}