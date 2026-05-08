minigame <- Ware_MinigameData
({
	name         = "Stun an Enemy"
	author       = ["Gemidyne", "pokemonPasta"]
	duration     = 4.0
	music        = "bigjazzfinish"
	description  = "Stun an Enemy!"
	allow_damage = true
	min_players  = 2
	max_players  = 64
})

proj_times <- {}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Sandman")
	foreach (player in Ware_MinigamePlayers)
		Ware_SetPlayerAmmo(player, TF_AMMO_GRENADES1, 3)
}

function OnUpdate()
{
	local id = ITEM_MAP.Sandman.id
	local classname = ITEM_PROJECTILE_MAP[id]
	
	local projs = []
	for (local proj; proj = FindByClassname(proj, classname);)
		projs.append(proj)

	local time = Time()
	foreach (proj in projs)
	{
		// delete after 2 seconds to prevent edict overflows
		if (!(proj in proj_times))
			proj_times[proj] <- time + 1.5
		
		if (proj_times[proj] < time)
			proj.Kill()
		else
			proj.SetTeam(TEAM_SPECTATOR)
	}
}

function OnTakeDamage(params)
{
	if (params.damage_stats == TF_DMG_CUSTOM_BASEBALL)
	{
		local victim = params.const_entity
		local attacker = params.attacker
	
		params.damage = 0.0
	
		victim.StunPlayer(Ware_GetMinigameRemainingTime(), 0.6, TF_STUN_SPECIAL_SOUND|TF_STUN_MOVEMENT, null)
		
		local particle = Ware_SpawnEntity("info_particle_system",
		{
			origin = victim.GetOrigin(),
			effect_name = "conc_stars",
			start_active = true
		})
		SetEntityParent(particle, victim, "head")
		
		if (attacker)
			Ware_PassPlayer(attacker, true)
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
		player.RemoveCond(TF_COND_STUNNED)
}
