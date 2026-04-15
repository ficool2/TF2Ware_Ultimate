minigame <- Ware_MinigameData
({
	name           = "Land the Platform"
	author         = ["Gemidyne", "ficool2"]
	description    = "Land on the platform!"
	duration       = 6.0
	location       = "factoryplatform"
	music          = "surfin"
	custom_overlay = "land_platform"
	max_scale      = 1.0
	start_freeze   = 0.4
})

function OnTeleport(players)
{
	local red_players = []
	local blue_players = []
	foreach (player in players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			red_players.append(player)
		else if (team == TF_TEAM_BLUE)
			blue_players.append(player)
	}
	
	local spacing_x = 58.0, spacing_y = 65.0
	if (players.len() > 40)
		spacing_y *= 0.6
	
	Ware_TeleportPlayersRow(red_players,
		Ware_MinigameLocation.center_left,
		QAngle(0, 0, 0),
		500.0,
		-spacing_x, spacing_y)

	Ware_TeleportPlayersRow(blue_players,
		Ware_MinigameLocation.center_right,
		QAngle(0, 180, 0),
		500.0,
		spacing_x, spacing_y)
}

function OnStart()
{
	local weapon = RandomInt(0, 2)

	if (weapon == 0)
	{
		Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Iron Bomber")
	}
	else if (weapon == 1)
	{
		Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Thermal Thruster")

		foreach (player in Ware_MinigamePlayers)
			SetPropFloatArray(player, "m_Shared.m_flItemChargeMeter", 50.0, 1)
	}
	else if (weapon == 2)
	{
		Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Detonator", {"self dmg push force increased" : 1.8})
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (GetPropEntity(player, "m_hGroundEntity") == null)
			continue
			
		local origin = player.GetOrigin()
		if (origin.x >= (Ware_MinigameLocation.center.x - 128.0)
			&& origin.x <= (Ware_MinigameLocation.center.x + 128.0)
			&& (origin.z - Ware_MinigameLocation.center.z) < 40.0)
		{
			Ware_PassPlayer(player, true)
		}
	}
}