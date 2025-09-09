

function OnUpdate(bot)
{
    local prop1 = FindByName(null, "boss4_goal")
    local prop2 = FindByName(null, "boss4_goal2")

    local y = bot.GetOrigin().y

    local dist1 = fabs(prop1.GetOrigin().y - y)
    local dist2 = fabs(prop2.GetOrigin().y - y)


    local prop
    prop = dist1 < dist2 ? prop1 : prop2
    if (prop)
    {
        local demomanPos = bot.EyePosition()
        local hoopPos = prop.GetOrigin() + Vector(0,0,90)
        local hoopVelocity = prop.GetAbsVelocity()  // Adjust based on actual hoop movement

        local dest = BotCalculateAimPosition(GetWeaponShootPosition(bot), hoopPos, hoopVelocity, 1216.0, 0.5)
        //local z = VectorDistance(prop.GetCenter(), bot.EyePosition())
        //local dest = prop.GetCenter() + Vector((prop.GetAbsVelocity().x * 1.1), 0, z/5.4)

        BotLookAt(bot, dest, 2000, 99999)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)
        loco.Approach(dest, 999.0)
        bot.PressFireButton(-1)

        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
    }
}