mode <- 0

minigame <- Ware_MinigameData
({
	name           = "Buff"
	author         = ["tilderain"]
	description    = "Activate buff!"
	duration       = 15
	music          = "woody"
	min_players    = 2
	allow_damage   = true
	fail_on_death  = true
})

function OnStart()
{
	local gun =	RandomInt(0,1)
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveHudHideFlags(HIDEHUD_CLOAK_AND_FEIGN)
		//Makes the flag apply if already soldier
		player.Regenerate(true)
		Ware_StripPlayer(player, false)
		if (mode == 0)
		{
			Ware_SetPlayerClass(player, TF_CLASS_SOLDIER)
			Ware_GivePlayerWeapon(player, "Buff Banner", {"deploy time increased": 1, "increase buff duration" : 0})
			local weapon = null
			if (gun == 0)
			{
				weapon = Ware_GivePlayerWeapon(player, "Rocket Launcher", {"clip size bonus" : 100, "deploy time increased": 1})
				weapon.SetClip1(69)
			}
			else
			{
				weapon = Ware_GivePlayerWeapon(player, "Beggar's Bazooka", {"clip size bonus" : 100, "reload time decreased": 0.5, "deploy time increased": 1})
			}
		}
		player.SetHealth(1100)
		player.SetRageMeter(0)
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsRageDraining() && player.IsAlive())
			Ware_PassPlayer(player, true)
	}
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		SetPropBool(player, "m_Shared.m_bRageDraining", false)
		player.AddHudHideFlags(HIDEHUD_CLOAK_AND_FEIGN)
	}
}