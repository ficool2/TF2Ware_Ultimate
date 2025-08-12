minigame <- Ware_MinigameData
({
	name          = "Stay on the Ground"
	author        = ["Gemidyne", "ficool2"]
	description   = "Stay on the ground!"
	duration      = 4.0
	music         = "falling"
	start_pass    = true
	fail_on_death = true
	modes         = 2
	allow_damage  = Ware_MinigameMode == 1 ? true : false
	friendly_fire = Ware_MinigameMode == 1 ? true : false
})

function OnStart()
{
	if (Ware_MinigameMode == 0)
	{
		Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Rocket Launcher")
	}
	else
	{
		Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Direct Hit", {"Projectile speed decreased": 0.06, "deploy time increased": 2.25, "fire rate penalty": 99})
		foreach (player in Ware_MinigamePlayers)
		{
			local weapon = player.GetActiveWeapon()
			if (weapon == null)
				continue

			weapon.SetClip1(1)
			Ware_SetPlayerAmmo(player, TF_AMMO_PRIMARY, 0)
		}
	}
}

function OnTakeDamage(params)
{
	if (params.damage_type & DMG_BLAST)
	{
		if (params.const_entity.IsPlayer())
		{
			Ware_SlapEntity(params.const_entity, 300.0)
			params.damage = 20
		}
	}
}

function OnUpdate()
{
	if (Ware_GetMinigameTime() < 2.0)
		return

	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		if (Ware_GetPlayerHeight(player) > 48.0)
			Ware_SuicidePlayer(player)
	}
}