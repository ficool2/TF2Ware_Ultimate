mode_nobody  <- RandomInt(0, 3) == 0
player_class <- RandomInt(TF_CLASS_FIRST, TF_CLASS_LAST)

minigame <- Ware_MinigameData
({
	name           = "Hit a Player"
	author         = ["Mecha the Slag", "ficool2"]
	description    = mode_nobody ? "Hit nobody!" : "Hit a player!"
	duration       = 4.5
	end_delay      = 0.5
	music          = "heat"
	custom_overlay = mode_nobody ? "hit_nobody" : "hit_player"
	min_players    = 2
	start_pass     = mode_nobody
	allow_damage   = true
})

loadouts <-
{
	[TF_CLASS_SCOUT]        = RandomElement(["Boston Basher", "Scattergun"]),
	[TF_CLASS_SOLDIER]      = "Direct Hit",
	[TF_CLASS_PYRO]         = "Dragon's Fury",
	[TF_CLASS_DEMOMAN]      = "Loch-n-Load",
	[TF_CLASS_HEAVYWEAPONS] = "Minigun",
	[TF_CLASS_ENGINEER]     = "Shotgun",
	[TF_CLASS_MEDIC]        = "Syringe Gun",
	[TF_CLASS_SNIPER]       = "Huntsman",
	[TF_CLASS_SPY]          = "Revolver",
}

function OnPrecache()
{
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/hit_nobody")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/hit_player")
}

function OnStart()
{
	Ware_SetGlobalLoadout(player_class, loadouts[player_class], { "deploy time increased" : 2.0 })
}

function OnUpdate()
{
	local id = ITEM_MAP[loadouts[player_class]].id
	if (id in ITEM_PROJECTILE_MAP)
	{
		local classname = ITEM_PROJECTILE_MAP[id]
		for (local proj; proj = FindByClassname(proj, classname);)
		{
			// alternating like this to fix rockets specifically
			// TODO: fix dragon's fury
			proj.SetTeam(proj.GetTeam() == TEAM_SPECTATOR ? TF_TEAM_RED : TEAM_SPECTATOR)
		}
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	local attacker = params.attacker
	if (victim.IsPlayer()
		&& attacker && attacker != victim && attacker.IsPlayer())
	{
		params.damage *= 100.0
	}
}

function OnPlayerDeath(player, attacker, params)
{
	if (attacker && player != attacker)
		Ware_PassPlayer(attacker, !mode_nobody)
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
		player.RemoveCond(TF_COND_BLEEDING)
}
