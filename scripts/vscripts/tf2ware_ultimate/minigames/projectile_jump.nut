mode_infos <- 
[
	[ "Needle jump!",       "needle_jump",        700.0],
	[ "Rocket jump!",       "rocket_jump",        384.0],
	[ "Sticky jump!",       "sticky_jump",        384.0],
	[ "Sentry jump!",       "sentry_jump",        384.0],
	[ "Flare jump!",        "flare_jump",         400.0],
	[ "Short Circuit jump!", "shortcircuit_jump", 384.0],
]
// needle jump generates crazy amount of entities
local min_mode = Ware_Players.len() > 40 ? 1 : 0
mode <- RandomInt(min_mode, 5)

minigame <- Ware_MinigameData
({
	name           = "Projectile Jump"
	author         = ["Mecha the Slag", "TonyBaretta", "ficool2"]
	description    = mode_infos[mode][0]
	duration       = mode == 3 ? 6.0 : 4.0
	end_delay      = mode == 3 ? 0.0 : 1.0
	music          = "goodtimes"
	custom_overlay = mode_infos[mode][1]
	allow_damage   = mode == 0 // original ware allowed it, for fun
	convars        = 
	{
		tf_damageforcescale_self_soldier_badrj = 10
		tf_damageforcescale_self_soldier_rj    = 20
		tf_damageforcescale_pyro_jump          = 20
		tf_fastbuild                           = 1
	}
})

function OnPrecache()
{
	foreach (mode in mode_infos)
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/" + mode[1])
}

function OnStart()
{
	local player_class, weapon
	if (mode == 0)
	{
		player_class = TF_CLASS_MEDIC
		weapon = "Syringe Gun"
	}
	else if (mode == 1)
	{
		player_class = TF_CLASS_SOLDIER
		weapon = "Rocket Launcher"
	}
	else if (mode == 2)
	{
		player_class = TF_CLASS_DEMOMAN
		weapon = "Stickybomb Launcher"
	}
	else if (mode == 3)
	{
		player_class = TF_CLASS_ENGINEER
		weapon = [ "Construction PDA", "Toolbox", "Wrangler"]
		Ware_SetGlobalAttribute("build rate bonus", 0, -1)
		foreach (player in Ware_MinigamePlayers)
			Ware_GetPlayerMiniData(player).took_dmgtype <- 0
	}
	else if (mode == 4)
	{
		player_class = TF_CLASS_PYRO
		weapon = "Detonator"
	}
	else if (mode == 5)
	{
		player_class = TF_CLASS_ENGINEER
		weapon = "Short Circuit"
		orbs <- {}
	}
	
	Ware_SetGlobalLoadout(player_class, weapon)
}

function OnUpdate()
{
	local height = mode_infos[mode][2]
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		if (Ware_GetPlayerHeight(player) > height)
			Ware_PassPlayer(player, true)
	}
	
	if (mode == 5)
	{
		local dead_orbs = {}
		foreach (orb, data in orbs)
		{
			if (orb.IsValid())
				data.origin = orb.GetOrigin()
			else
				dead_orbs[orb] <- data
		}
		
		for (local orb; orb = Entities.FindByClassname(orb, "tf_projectile_mechanicalarmorb");)
		{
			if (!(orb in orbs) && !orb.IsEFlagSet(EFL_KILLME))
				orbs[orb] <- { origin = orb.GetOrigin(), owner = orb.GetOwner() }
		}
		
		foreach (orb, data in dead_orbs)
		{
			delete orbs[orb]
			
			local player = data.owner
			local origin = data.origin
			
			local radius = 100.0
			
			// copied from Ware_RadiusDamagePlayers
			local dist = VectorDistance(player.GetOrigin(), origin)
			if (dist > radius)
				continue
			
			dist += DIST_EPSILON
			local falloff = 1.0 - dist / radius
			if (falloff <= 0.0)
				continue
			
			local dir = player.EyeAngles().Forward()
			dir.Norm()
			
			local dot = dir.Dot(Vector(0, 0, -1.0))
			if (dot > 0.707) // cos(45)
				player.SetAbsVelocity(player.GetAbsVelocity() - dir * 2000.0 * dot * falloff)
		}
	}
}

function OnEnd()
{
	if (mode == 3)
	{
		foreach (player in Ware_MinigamePlayers)
		{
			local dmgtype = Ware_GetPlayerMiniData(player).took_dmgtype
			// bonus point if player passed by bullet knockback only
			if (!(dmgtype & DMG_BLAST) && (dmgtype & DMG_BULLET) && Ware_IsPlayerPassed(player))
				Ware_GiveBonusPoints(player)
		}
	}
}

if (mode == 0)
{
	function OnPlayerAttack(player)
	{
		local dir = player.EyeAngles().Forward()
		dir.Norm()
		
		local dot = dir.Dot(Vector(0, 0, -1.0))
		if (dot > 0.707) // cos(45)
			player.SetAbsVelocity(player.GetAbsVelocity() - dir * 88.0 * dot)
	}
}
else if (mode == 3)
{
	function OnTakeDamage(params)
	{
		if (params.const_entity.IsPlayer())
		{
			local minidata = Ware_GetPlayerMiniData(params.const_entity)
			minidata.took_dmgtype = minidata.took_dmgtype | params.damage_type
		}
	}
	
	function OnGameEvent_player_builtobject(params)
	{
		local building = EntIndexToHScript(params.index)
		if (!building)
			return
			
		SetPropInt(building, "m_nDefaultUpgradeLevel", 2)
	}	
}
else if (mode == 5)
{
	function OnTakeDamage(params)
	{
		local weapon = params.weapon
		if (weapon && weapon.GetName() == "tf_weapon_mechanical_arm")
			params.damage = 0.0
	}
}