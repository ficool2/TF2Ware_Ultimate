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
    if (bot.GetFlags() & FL_ONGROUND && bot.GetAbsVelocity().Length() > 200.0)
        loco.Jump()
    bot.RemoveFlag(FL_DUCKING)
    
}

function ForceTaunt(player, taunt_id)
{
  	if (player.IsTaunting()) return

	local weapon = Entities.CreateByClassname("tf_weapon_bat")
	local active_weapon = player.GetActiveWeapon()
	player.StopTaunt(true) // both are needed to fully clear the taunt
	player.RemoveCond(7)
	weapon.DispatchSpawn()
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", taunt_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bForcePurgeFixedupStrings", true)
	NetProps.SetPropEntity(player, "m_hActiveWeapon", weapon)
	NetProps.SetPropInt(player, "m_iFOV", 0) // fix sniper rifles
	player.HandleTauntCommand(0)
	NetProps.SetPropEntity(player, "m_hActiveWeapon", active_weapon)
	weapon.Kill()
}

