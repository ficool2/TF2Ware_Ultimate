minigame <- Ware_MinigameData
({
	name           = "Grapple a Player"
	author         = ["ficool2"]
	description    = Ware_MinigameMode == 2 ? "Grapple nobody!" : "Grapple a player!"
	duration       = 4.0
	min_players    = 2
	music          = "ridealong"
	custom_overlay = Ware_MinigameMode == 2 ? "grapple_nobody" : "grapple_player"
	modes          = 3
	start_pass     = Ware_MinigameMode == 2
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
		{
			if (Ware_MinigameMode == 0 || Ware_MinigameMode == 1)
				Ware_PassPlayer(player, true)
			else if (Ware_MinigameMode == 2)
				Ware_PassPlayer(player, false)
		}
	}
}