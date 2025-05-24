minigame <- Ware_MinigameData
({
	name           = "Break the Boxes"
	author         = "ficool2"	
	description    = "Find the Australium!"
	duration       = 18.0
	location       = "warehouse"
	music          = "digging"
	custom_overlay = "find_australium"
	min_players    = 3
	max_scale      = 1.5
})

box_model <- "models/props_hydro/barrel_crate_half.mdl"
box_size  <- 80.0

break_particle <- "target_break"
break_sounds <-
[
	"Wood_Box.Break"
	"Wood_Crate.Break"
	"Wood_Furniture.Break"
	"Wood_Panel.Break"
	"Wood_Plank.Break"
	"Wood_Solid.Break"
]

gold_model <- "models/props_mining/ingot001.mdl"
gold_sound <- "ui.cratesmash_ultrarare_short"
gold_particle <- "australium_bar_glow"

function OnPrecache()
{
	PrecacheModel(box_model)
	
	PrecacheParticle(break_particle)
	foreach (sound in break_sounds)
		PrecacheScriptSound(sound)
		
	PrecacheModel(gold_model)
	PrecacheScriptSound(gold_sound)
	PrecacheParticle(gold_particle)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_HEAVYWEAPONS)
	Ware_SetGlobalAttribute("increased jump height", 1.25, -1)
	
	local mins = Ware_MinigameLocation.mins
	local maxs = Ware_MinigameLocation.maxs
	
	local gold_count = Ware_MinigamePlayers.len() > 24 ? 1 : 2
	local shrink = 0.0
	if (Ware_MinigamePlayers.len() < 6)
		shrink = box_size * 3.1
	else if (Ware_MinigamePlayers.len() < 12)
		shrink = box_size * 2.1
	
	local box_size_half = box_size * 0.5
	local mins_x = mins.x + (box_size_half) + shrink
	local maxs_x = maxs.x - (box_size + box_size_half) - shrink
	local mins_y = mins.y + (box_size_half) + shrink
	local maxs_y = maxs.y - (box_size_half) - shrink
	local mins_z = mins.z + 0.1
	local add_z = box_size - 10.0
	
	local box_mins = Vector(-box_size_half, -box_size_half, 0.0)
	local box_maxs = Vector(box_size_half, box_size_half, box_size_half)
	
	local lighting_origin = Ware_SpawnEntity("info_teleport_destination", 
	{ 
		origin = Ware_MinigameLocation.center + Vector(0, -200, 256)
	})
	
	local box_angles = 
	[
		QAngle(0, 0, 0)
		QAngle(0, 90, 0)
		QAngle(0, 180, 0)
		QAngle(0, 270, 0)
	]
	
	local boxes = []
	for (local x = mins_x; x <= maxs_x; x += box_size)
	{
		for (local y = mins_y; y <= maxs_y; y += box_size)
		{
			local z_count = RandomInt(1, 3)
			local z = mins_z
			for (local i = 0; i < z_count; i++)
			{
				local origin = Vector(x, y, z)
				local trace = 
				{
					start   = origin
					end     = origin
					hullmin = box_mins
					hullmax = box_maxs
					mask    = CONTENTS_SOLID
				}
				TraceHull(trace)
				if (trace.hit)
					break
				
				local box = Ware_SpawnEntity("prop_dynamic_override", 
				{
					origin = origin
					angles = RandomElement(box_angles)
					model  = box_model
					health = 10
					solid  = SOLID_VPHYSICS
					disableshadows = true
				})			
				SetPropEntity(box, "m_hLightingOrigin", lighting_origin)
				boxes.append(box)
			
				z += add_z
			}
		}		
	}
	
	for (local i = 0; i < gold_count; i++)
		RemoveRandomElement(boxes).AddEFlags(EFL_USER)
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	local attacker = params.attacker
	if (victim.IsPlayer())
	{
		if (params.damage_type & DMG_SLASH) // prop touch
		{
			Ware_PassPlayer(victim, true)
			return false
		}
	}
	else if (victim.GetClassname() == "prop_dynamic" 
			&& victim.GetModelName() == box_model)
	{
		if (attacker != null 
			&& attacker.IsPlayer())
		{
			if (victim.IsEFlagSet(EFL_USER))
			{			
				Ware_GiveBonusPoints(attacker)
				
				DispatchParticleEffect(break_particle, victim.GetOrigin(), Vector(90, 0, 0))
				victim.EmitSound(gold_sound)
				
				local gold_origin = victim.GetOrigin() + Vector(0, 0, 10)
				local gold = Ware_SpawnEntity("prop_physics_override", 
				{
					origin = gold_origin
					model  = gold_model
					disableshadows = true
					spawnflags   = SF_PHYSPROP_TOUCH
					minhealthdmg = INT_MAX // don't destroy on touch
				})		
				local particle_gold = Ware_SpawnEntity("info_particle_system",
				{
					origin       = gold_origin
					effect_name  = gold_particle
					start_active = true
				})
				SetEntityParent(particle_gold, gold)
				gold.SetModelScale(1.5, 0.0)
				
				//local glow = Ware_SpawnEntity("tf_glow",
				//{
				//	target    = "bignet" // don't get deleted
				//	GlowColor = "255 204 0 255"
				//})
				//SetPropEntity(glow, "m_hTarget", gold)
			}
			else
			{
				DispatchParticleEffect(break_particle, victim.GetOrigin(), Vector(90, 0, 0))
				victim.EmitSound(RandomElement(break_sounds))
			}
			
			victim.Kill()	
			return false
		}
	}
}