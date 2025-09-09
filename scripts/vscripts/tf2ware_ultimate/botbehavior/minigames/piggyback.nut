//todo path
local function MakePlayerComplain(target)
{
	local type = RandomBool() ? "TLK_PLAYER_JEERS" : "TLK_PLAYER_NEGATIVE"
	EntityEntFire(target, "SpeakResponseConcept", type)
}

function OnUpdate(bot)
{
    local dest = Vector()
    local data = Ware_GetPlayerMiniData(bot)

    if(!("troll" in data))
        data.troll <- 0

    if(bot.GetTeam() == TF_TEAM_BLUE)
    {
        dest = Ware_MinigameLocation.center_bottom
        if(Ware_IsPlayerPassed(bot))
        {
            data.troll++
            if(data.troll > 60)
                ForceTaunt(bot, 463)
        }

    }
    else
    {
        local back = Ware_MinigameScope.piggybacker
        if(back)
            dest = back.GetOrigin()

        if(Ware_IsPlayerPassed(back) && !Ware_IsPlayerPassed(bot))
        {
            data.troll++
            if(data.troll > 60 && RandomInt(0,250) == 0)
            {
                local words = ["you fucker"]
                local word = Ware_BotTryWordTypo(bot, RandomElement(words), 0.5)
                MakePlayerComplain(bot)
                Say(bot, word, false)
                bot.PressFireButton(-1)
            }

        }
    }

    BotLookAt(bot, dest, 350.0, 600.0)
    local loco = bot.GetLocomotionInterface()
    loco.FaceTowards(dest)
    loco.Approach(dest, 999.0)
    if (bot.GetFlags() & FL_ONGROUND && bot.GetAbsVelocity().Length() > 150.0)
        loco.Jump()
    bot.RemoveFlag(FL_DUCKING)
    
}

