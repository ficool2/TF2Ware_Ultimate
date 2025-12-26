minigame <- Ware_MinigameData
({
	name           = "Needle Jump"
	author         = ["Mecha the Slag", "ficool2"]
	description    = "Needle jump!"
	duration       = 4.0
	end_delay      = 1.0
	max_players    = 40 // generates crazy amount of entities
	music          = "goodtimes"
	allow_damage   = true
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_MEDIC, "Syringe Gun")
}

function OnUpdate()
{
	local height = 700.0
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		if (Ware_GetPlayerHeight(player) > height)
			Ware_PassPlayer(player, true)
	}
}

function OnPlayerAttack(player)
{
	local dir = player.EyeAngles().Forward()
	dir.Norm()
	
	local dot = dir.Dot(Vector(0, 0, -1.0))
	if (dot > 0.707) // cos(45)
		player.SetAbsVelocity(player.GetAbsVelocity() - dir * 88.0 * dot)
}