minigame <- Ware_MinigameData
({
	name		= "Force Jump"
	author		= ["Kimmy", "ficool2"]
	description	= "Time your force jump!"
	duration	= 5.0
	custom_overlay	= "force_jump"
	music		= "falling"
	start_pass	= true
	fail_on_death	= true
	thirdperson	= true
	start_freeze	= 0.5
	convars		=
	{
		sv_gravity = RemapValClamped(Ware_TimeScale, 1.0, 2.0, 800.0, 270.0)
	}
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Force-a-Nature", {"no double jump": 1})

	foreach (player in Ware_MinigamePlayers)
	{
		player.SetHealth(1)

		local weapon = player.GetActiveWeapon()
		if (weapon == null)
			continue

		weapon.SetClip1(1)
		Ware_SetPlayerAmmo(player, TF_AMMO_PRIMARY, 0)
	}
}

function OnTeleport(players)
{
	Ware_TeleportPlayersCircle(players, Ware_MinigameLocation.center + Vector(0, 0, 2400), 250.0)

	if (Ware_MinigameLocation.name.find("big") != null)
		Ware_TeleportPlayersCircle(players, Ware_MinigameLocation.center + Vector(0, 0, 2400), 550.0)
}