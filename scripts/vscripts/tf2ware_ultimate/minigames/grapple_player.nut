mode_nobody <- RandomInt(0, 3) == 0

minigame <- Ware_MinigameData
({
	name           = "Grapple a Player"
	author         = "ficool2"
	description    = mode_nobody ? "Grapple nobody!" : "Grapple a player!"
	duration       = 4.0
	min_players    = 2
	music          = "ridealong"
	custom_overlay = mode_nobody ? "grapple_nobody" : "grapple_player"
	start_pass     = mode_nobody
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_UNDEFINED, "Grappling Hook")
}

function OnUpdate()
{
	local id = ITEM_MAP["Grappling Hook"].id
	local classname = ITEM_PROJECTILE_MAP[id]
	for (local proj; proj = FindByClassname(proj, classname);)
		proj.SetTeam(proj.GetTeam() == TEAM_SPECTATOR ? TF_TEAM_RED : TEAM_SPECTATOR)

	foreach (player in Ware_MinigamePlayers)
	{
		local target = player.GetGrapplingHookTarget()
		if (target && target.IsPlayer())
			Ware_PassPlayer(player, !mode_nobody)
	}
}