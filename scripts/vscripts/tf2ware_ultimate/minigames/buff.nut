minigame <- Ware_MinigameData
({
	name           = "Buff"
	author         = ["tilderain"]
	description    = "Activate buff!"
	duration       = 15
	music          = "woody"
	min_players    = 2
	allow_damage   = true
	modes          = 3
	collisions 	   = true
	location       = "boxingring"
})

local buffs = ["Buff Banner", "Concheror", "Battalion's Backup"]

function OnStart()
{
	local gun =	RandomInt(0,1)
	local buff = RandomElement(buffs)
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveHudHideFlags(HIDEHUD_CLOAK_AND_FEIGN)
		//Makes the flag apply if already soldier
		player.Regenerate(true)
		Ware_StripPlayer(player, false)
		if (Ware_MinigameMode == 0)
		{
			Ware_SetPlayerClass(player, TF_CLASS_SOLDIER)
			Ware_GivePlayerWeapon(player, buff, {"deploy time increased": 1, "increase buff duration" : 0.1})
			local weapon = null
			if (gun == 0)
			{
				weapon = Ware_GivePlayerWeapon(player, "Rocket Launcher", {"clip size bonus" : 100, "deploy time increased": 1, "damage bonus": 1.25})
				weapon.SetClip1(69)
			}
			else
			{
				weapon = Ware_GivePlayerWeapon(player, "Beggar's Bazooka", {"clip size bonus" : 100, "reload time decreased": 0.5, "deploy time increased": 1, "damage bonus": 1.25})
			}
		}
		else if (Ware_MinigameMode == 1)
		{
			Ware_SetPlayerClass(player, TF_CLASS_PYRO)
			Ware_GivePlayerWeapon(player, "Phlogistinator")
		}
		else if (Ware_MinigameMode == 2)
		{
			Ware_SetPlayerClass(player, TF_CLASS_SNIPER)
			Ware_GivePlayerWeapon(player, "Cleaner's Carbine")
		}
		player.SetRageMeter(0)
		player.SetHealth(1250)
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsRageDraining() && player.IsAlive() || player.InCond(TF_COND_ENERGY_BUFF))
			Ware_PassPlayer(player, true)
	}
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.SetRageMeter(0)
		SetPropBool(player, "m_Shared.m_bRageDraining", false)
		player.AddHudHideFlags(HIDEHUD_CLOAK_AND_FEIGN)
	}
}