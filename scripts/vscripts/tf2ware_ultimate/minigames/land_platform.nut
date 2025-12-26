// 0: Iron Bomber
// 1: Thermal Thruster

minigame <- Ware_MinigameData
({
	name          = "Land the Platform"
	author        = ["Gemidyne", "ficool2"]
	description   = "Land on the platform!"
	modes         = 2
	duration      = Ware_MinigameMode == 0 ? 6.0 : 5.0
	location      = "factoryplatform"
	music         = Ware_MinigameMode == 0 ? "sweetdays" : "surfin"
	max_scale     = 1.0
	start_freeze  = 0.4
})

function OnPrecache()
{
	Ware_PrecacheMinigameMusic("sweetdays", false)
	Ware_PrecacheMinigameMusic("surfin", false)
}

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
	if (Ware_MinigameMode == 0)
	{
		Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Iron Bomber")
	}
	else
	{
		Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Thermal Thruster")
		foreach (player in Ware_MinigamePlayers)
			SetPropFloatArray(player, "m_Shared.m_flItemChargeMeter", 50.0, 1)
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