//todo better standoff
function OnUpdate(bot)
{
	local data = Ware_GetPlayerMiniData(bot)
	local prop = data.opponent

	if (Ware_MinigameScope.mexican_standoff)
	{
		local arr = Shuffle(Ware_MinigamePlayers)
		foreach (p in arr)
		{
			if (p && p.IsPlayer() && p.IsAlive() && p != bot)
			{
				prop = p
				break
			}
		}
	}

	local weapon = bot.GetActiveWeapon()
	if (weapon && weapon.GetSlot() == TF_SLOT_MELEE)
	{
		KillWeapon(weapon)
	}
	if (prop && bot.IsAlive())
	{
		local loco = bot.GetLocomotionInterface()
		loco.FaceTowards(prop.EyePosition())
		BotLookAt(bot, prop.EyePosition(), 9999.0, 9999.0)

        //loco.Approach(prop.EyePosition(), 999.0)

		//if (bot.GetCustomAttribute("no attack", 1) == 0)
		//{
			if(weapon && weapon.IsValid() && RandomInt(0,10) == 0)
				weapon.PrimaryAttack()
			//bot.PressFireButton(-1)
		//}

	}

}

