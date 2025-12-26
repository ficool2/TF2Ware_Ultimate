minigame <- Ware_MinigameData
({
	name           = "Intel"
	author         = ["tilderain", "ficool2"]
	description    = "Capture the Intel!"
	duration       = 22.0
	location       = "pinball"
	music          = "betusblues"
	thirdperson    = true
	allow_damage   = true
})

spinner_model <- "models/empty.mdl"
beam_model <- "sprites/laserbeam.vmt"
fence_model <- "models/props_gameplay/security_fence_section01.mdl"
screen_model <- "models/props_spytech/computer_screen_01.mdl"
sawblade_model <- "models/props_forest/sawblade_moving.mdl"
cow_model <- "models/props_2fort/cow001_reference.mdl"

intel_pos <- null
goal_pos <- null

beam <- null

lasers <- []
laser_count <- 0

show_anno <- false

first <- true

function OnPrecache()
{
	PrecacheModel(spinner_model)
	PrecacheSprite(beam_model)
	PrecacheModel(fence_model)
	PrecacheModel(screen_model)
	PrecacheModel(sawblade_model)
	PrecacheSound("SawMill.BladeImpact")
	PrecacheModel(cow_model)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersRow(players, 
		Ware_MinigameLocation.center_bottom + Vector(-1100, 110, 0), 
		QAngle(0, 0, 0), 
		700.0, 
		30.0, 45.0)
}

x_range <- [-750, 750]
y_range <- [-300, 375]
z_range <- [0, 200]

function OnUpdate() 
{
    local location = Ware_MinigameLocation.center_bottom
    foreach (prop in lasers) 
	{
        local vel = prop.GetAbsVelocity()
        local pos = prop.GetOrigin()

        if (pos.x - location.x > x_range[1]) 
            vel.x = -fabs(vel.x)
		else if (pos.x - location.x < x_range[0]) 
            vel.x = fabs(vel.x)

        if (pos.y - location.y > y_range[1]) 
            vel.y = -fabs(vel.y)
		else if (pos.y - location.y < y_range[0]) 
            vel.y = fabs(vel.y)
			
        if (pos.z - location.z > z_range[1]) 
            vel.z = -fabs(vel.z)
		else if (pos.z - location.z < z_range[0]) 
            vel.z = fabs(vel.z)

        prop.SetAbsVelocity(vel)
    }
}

function OnCapture1()
{
	if (activator && activator.IsPlayer())
	{
		Ware_PassPlayer(activator, true)
		if (Ware_MinigameScope.first)
		{
			Ware_ChatPrint(null, "{player} {color}capped the intel first!", activator, TF_COLOR_DEFAULT)
			Ware_GiveBonusPoints(activator)
			Ware_MinigameScope.first = false
		}
	}

	foreach (mgr in TeamMgrs)
		SetPropInt(mgr, "m_nFlagCaptures", 0)
}

function OnPickup1()
{
	if (!Ware_MinigameScope.show_anno)
	{
		Ware_MinigameScope.show_anno = true	
		Ware_ShowAnnotation(Ware_MinigameScope.goal_pos, "Goal!")
	}
	
	if (activator && activator.IsPlayer())
	{
		local minidata = Ware_GetPlayerMiniData(activator)
		if (!("picked" in minidata))
		{
			Ware_MinigameScope.SpawnIntel()
			minidata.picked <- true
		}
	}
}

function OnStart()
{
	goal_pos = Ware_MinigameLocation.center_bottom + Vector(-1210, 100, 0)
	intel_pos = Ware_MinigameLocation.center_bottom + Vector(900, 100, 45)
	
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT)
	SetPropInt(GameRules, "m_nHudType", 1)

	SpawnIntel()

	local order = [0, 1, 1]
	local poses = [500, 0, -500]
	Shuffle(order)
	Shuffle(poses)

	for (local i = 0; i < order.len(); i++)
	{
		if (order[i] == 0)
		{
			SpawnSpinner(Ware_MinigameLocation.center_bottom + Vector(poses[i], 300, 100))
			SpawnSpinner(Ware_MinigameLocation.center_bottom + Vector(poses[i], -100, 100))
		}
		else
		{
			SpawnLaser(Ware_MinigameLocation.center_bottom + Vector(poses[i], -265, RandomBool() ? 40 : 80), RandomInt(0, 1))
			SpawnLaser(Ware_MinigameLocation.center_bottom + Vector(poses[i], -265, RandomBool() ? 40 : 80), RandomInt(0, 1))
			SpawnSawblade(Ware_MinigameLocation.center_bottom + Vector(poses[i], 0, 40))
		}
	}

	local zone = Ware_SpawnEntity("func_capturezone",
	{
		origin = goal_pos
	})
	zone.SetSolid(SOLID_BBOX)
	zone.SetSize(Vector(-16, -400, 0), Vector(16, 400, 64))
	
	local screen = Ware_SpawnEntity("prop_dynamic",
	{
		origin = goal_pos + Vector(-100, 0, 32)
		angles = QAngle(0, -90, 0)
		model  = screen_model
	})
	screen.SetModelScale(3, 0)

	local cow = Ware_SpawnEntity("prop_dynamic",
	{
		origin = intel_pos + Vector(-64, 0, -44)
		angles = QAngle(0, 180, 0)
		model  = cow_model
	})

	for (local i = -2; i <= 2; i++)
	{
		Ware_SpawnEntity("prop_dynamic",
		{
			origin = Ware_MinigameLocation.center_bottom + Vector(i * 256.0, -290.0, 0)
			model  = fence_model
			solid  = SOLID_VPHYSICS
		})	
	}
}

function SpawnIntel()
{
	local flag = Ware_SpawnEntity("item_teamflag",
	{
		origin  = Ware_MinigameScope.intel_pos
		TeamNum = TEAM_UNASSIGNED
	})

	flag.ValidateScriptScope()
	flag.GetScriptScope().OnCapture1 <- Ware_MinigameScope.OnCapture1
	flag.ConnectOutput("OnCapture1", "OnCapture1")
	flag.GetScriptScope().OnPickup1 <- Ware_MinigameScope.OnPickup1
	flag.ConnectOutput("OnPickup1", "OnPickup1")
}

function SpawnSawblade(pos)
{
	local beam = Ware_SpawnEntity("prop_dynamic",
	{
		origin          = pos
		model           = sawblade_model
		damage          = 3000
		defaultanim     = "idle"
		angles          = QAngle(0, 90, 0)
		spawnflags      = SF_PHYSPROP_TOUCH
		disableshadows  = true		
		minhealthdmg    = 9999999 // don't destroy on touch			
	})

	local speed = RandomFloat(100, 400)
	if (RandomBool())
		speed = -speed
	beam.SetMoveType(MOVETYPE_NOCLIP, 0)
	
	local vel = beam.GetAbsVelocity()
	vel = Vector(vel.x * 0, speed, vel.z * 0)
	beam.SetAbsVelocity(vel)

	lasers.append(beam)
	local hurt = Ware_SpawnEntity("trigger_multiple",
	{
		origin     = pos
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_OBB)
	hurt.SetSize(Vector(-10,-55,-55), Vector(10,55,55))
	SetEntityParent(hurt, beam)
}

function SpawnLaser(pos, type)
{
	local beam_height = 100.0
	local add_vec = Vector(0, 3000, 0)
	if (type == 1)
	{
		pos.z = -7550
		add_vec = Vector(500, 0, 0)
	}

	local beam = Ware_SpawnEntity("func_tracktrain",
	{
		targetname = "ware_laser_" + laser_count
		origin     = pos + add_vec
		target     = "dummytarget"
	})
	beam.SetMoveType(MOVETYPE_NOCLIP, 0)

	local speed = RandomFloat(30, 90)
	if (type == 1)
		speed = RandomFloat(100, 200)
	if (RandomBool())
		speed = -speed
	local vel = beam.GetAbsVelocity()
	if (type == 0)
		vel = Vector(vel.x * 0, vel.y * 0, speed)
	else
		vel = Vector(vel.x * 0, speed, vel.z * 0)
	beam.SetAbsVelocity(vel)

	lasers.append(beam)

	local beam = Ware_SpawnEntity("env_laser",
	{
		origin        = pos
		texture       = beam_model
		TextureScroll = 35
		width         = 6
		spawnflags    = 48
		rendercolor   = "255 0 25"
		damage        = 75
		dissolvetype  = 1
		LaserTarget   = "ware_laser_" + laser_count
	})

	local beam2 = Ware_SpawnEntity("env_laser",
	{
		origin        = pos
		texture       = beam_model
		TextureScroll = 35
		width         = 3
		spawnflags    = 48
		rendercolor   = "255 255 255"
		damage        = 0
		dissolvetype  = 1
		LaserTarget   = "ware_laser_" + laser_count
	})
	
	laser_count++

	if (type == 0)
		speed = RandomFloat(30, 50)
	else if (type == 1)
		speed = RandomFloat(100, 200)
	if (RandomBool())
		speed = -speed
	beam.SetMoveType(MOVETYPE_NOCLIP, 0)

	vel = beam.GetAbsVelocity()
	if (type == 0)
		vel = Vector(vel.x * 0, vel.y * 0, speed)
	else
		vel = Vector(vel.x * 0, speed, vel.z * 0)
	beam.SetAbsVelocity(vel)

	lasers.append(beam)

	beam2.SetMoveType(MOVETYPE_NOCLIP, 0)

	vel = beam2.GetAbsVelocity()
	if (type == 0)
		vel = Vector(vel.x * 0, vel.y * 0, speed)
	else
		vel = Vector(vel.x * 0, speed, vel.z * 0)
	beam2.SetAbsVelocity(vel)

	lasers.append(beam2)
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer() && attacker != victim)
			return false
		
		local inflictor = params.inflictor
		if (inflictor && inflictor.GetClassname() == "env_laser")
		{
			victim.TakeDamageCustom(victim, victim, null, Vector(), Vector(), 6.0, DMG_GENERIC, TF_DMG_CUSTOM_PLASMA)
			// fix weapons being dissolved after respawn
			params.damage_type = params.damage_type & ~(DMG_DISSOLVE)	
			params.damage_stats = TF_DMG_CUSTOM_PLASMA
		}
		else if (params.damage_type & DMG_SLASH) // prop touch
		{
			// the attacker is the player, so recover the true attacker from the damage position
			local attacker = FindByClassnameNearest("prop_dynamic", params.damage_position, 0.0)
			if (attacker)
			{
				victim.TakeDamageEx(
					attacker, 
					attacker,
					null, 
					Vector(RandomFloat(19999, -19999), RandomFloat(19999, -19999), -999999),
					attacker.GetOrigin(), 
					75, 
					DMG_SAWBLADE
				)
				
				victim.EmitSound("SawMill.BladeImpact")
				
				local ragdoll = GetPropEntity(victim, "m_hRagdoll")
				if (ragdoll)
				{
					MarkForPurge(ragdoll)
					SetPropFloat(victim, "m_flTorsoScale", -1)
					SetPropFloat(ragdoll, "m_flTorsoScale", -1)
				}
				DispatchParticleEffect("env_sawblood", victim.GetCenter(), Vector())
				attacker.SetSkin(1)

				return false
			}
		}
	}
}

function SpinnerTouch()
{
	if (activator)
	{
		BurnPlayer(activator, 1.0, 7.5)
		activator.TakeDamage(DMG_BURN, 50, self)
	}
}

function SpawnSpinner(pos)
{
	local spin = RandomBool() ? -70.0 : 70.0
	local spinner = Ware_SpawnEntity("prop_dynamic",
	{
		origin = pos
		model  = spinner_model
	})
	spinner.SetMoveType(MOVETYPE_NOCLIP, 0)
	spinner.SetAngularVelocity(0, 0, spin)
	
	local hurt_size = 2.0
	local hurt_width = 300.0
	
	local hurt = Ware_SpawnEntity("trigger_multiple",
	{
		origin     = pos
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_OBB)
	hurt.SetSize(Vector(-hurt_size, -hurt_width, -hurt_size), Vector(hurt_size, hurt_width, hurt_size))
	hurt.ValidateScriptScope()
	hurt.GetScriptScope().SpinnerTouch <- SpinnerTouch
	hurt.ConnectOutput("OnStartTouch", "SpinnerTouch")
	SetEntityParent(hurt, spinner)
	
	hurt = Ware_SpawnEntity("trigger_multiple",
	{
		origin     = pos
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_OBB)
	hurt.SetSize(Vector(-hurt_size, -hurt_size, -hurt_width), Vector(hurt_size, hurt_size, hurt_width))
	hurt.ValidateScriptScope()
	hurt.GetScriptScope().SpinnerTouch <- SpinnerTouch
	hurt.ConnectOutput("OnStartTouch", "SpinnerTouch")
	SetEntityParent(hurt, spinner)
	
	for (local i = -5; i <= 5; i++)
	{
		local offset = i * 45.0
		
		local particle = Ware_SpawnEntity("info_particle_system",
		{
			origin       = pos + Vector(0, offset)
			effect_name  = "buildingdamage_dispenser_fire1"
			start_active = true
		})
		SetEntityParent(particle, spinner)
		
		local particle = Ware_SpawnEntity("info_particle_system",
		{
			origin       = pos + Vector(0, 0. offset)
			effect_name  = "buildingdamage_dispenser_fire1"
			start_active = true
		})
		SetEntityParent(particle, spinner)		
	}
}

function OnCleanup()
{
	SetPropInt(GameRules, "m_nHudType", 0)
	
	foreach (player in Ware_Players)
	{
		player.RemoveCond(TF_COND_CRITBOOSTED)
		SetPropBool(player, "m_bGlowEnabled", false)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}