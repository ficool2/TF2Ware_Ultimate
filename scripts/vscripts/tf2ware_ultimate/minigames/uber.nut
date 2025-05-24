minigame <- Ware_MinigameData
({
	name           = "Uber"
	author         = ["tilderain"]
	description    = "Uber someone!"
	duration       = 5.5
	music          = "farm"
	min_players    = 2
	convars        =
	{
		mp_teams_unbalance_limit = 0
	}
})

function OnStart()
{
	local guns = ["Medi Gun", "Kritzkrieg"]
	local gun = RandomElement(guns)
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
		Ware_SetPlayerClass(player, TF_CLASS_MEDIC)
		Ware_GivePlayerWeapon(player, gun, {"ubercharge rate bonus" : 16})
		player.SetHealth(1)
	}
	Ware_ChatPrint(null, "{color}HINT:{color} Uber builds faster when healing someone with low health!", COLOR_GREEN, TF_COLOR_DEFAULT)
}

function OnUpdate()
{
	foreach (medic in Ware_MinigamePlayers)
	{
		if (medic.IsValid() && medic.IsAlive())
		{
			local weapon = medic.GetActiveWeapon()
			if (weapon && weapon.GetClassname() == "tf_weapon_medigun" && GetPropBool(weapon, "m_bChargeRelease"))
			{
				Ware_PassPlayer(medic, true)
			}
		}
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveCond(TF_COND_INVULNERABLE)
	}
}