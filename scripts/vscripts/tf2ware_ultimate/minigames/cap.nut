minigame <- Ware_MinigameData
({
	name          = "Cap the Point"
	author        = ["tilderain"]
	description   = "Cap the Point!"
	duration      = 12.5
	music         = "bloober"
	allow_damage  = true
	friendly_fire = true
	convars = 
	{
		tf_avoidteammates = 1
		tf_avoidteammates_pushaway = 1
		tf_scout_air_dash_count = 0 
		mp_teams_unbalance_limit = 0
	}
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Shortstop")
	SetPropInt(GameRules, "m_nHudType", 2)

	local origin = Vector(
		RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
		RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
		Ware_MinigameLocation.center.z)

	SpawnCap(origin)

	local team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerTeam(player, team)
		local minidata = Ware_GetPlayerMiniData(player)
		
		local weapon = player.GetActiveWeapon()
		minidata.last_attack <- weapon ? GetPropFloat(weapon, "m_flNextSecondaryAttack") : 0.0
		
		if (VectorDistance(player.GetOrigin(), origin) < 200)
			player.SetOrigin(player.GetOrigin() + Vector(0,0,25))
			
		minidata.in_cap <- false
	}
}

function PushClosestTarget(player, radius)
{
	local start = player.EyePosition()
	local forward = player.EyeAngles().Forward()

	local closest_dist = radius
	local closest_player
	local closest_forward
	
	foreach (other in Ware_MinigamePlayers)
	{
		if (other == player)
			continue
		
		local other_origin = other.GetOrigin() 
		local mins = other_origin + other.GetPlayerMins()
		local maxs = other_origin + other.GetPlayerMaxs()
		
		//DebugDrawLine(start, start + forward * closest_dist, 255, 0, 0, false, 5.0)
		//DebugDrawBox(vec3_zero, mins, maxs, 255, 0, 0, 20, 5.0)

		local dist = IntersectRayWithBox(start, forward, mins, maxs, 0.0, closest_dist)
		if (dist < 0.0)
			continue
			
		if (dist <= closest_dist)
		{
			closest_dist = dist
			closest_player = other
		
			// inside
			if (closest_dist < 0.00001)
				break
		}
	}
	
	if (closest_player)
	{
		closest_player.EmitSound( "Weapon_Hands.PushImpact" )	
		// using DMG_CLUB here caused pain voiceline scenes to take 5-10 ms to load.. WTF
		closest_player.TakeDamage(5, DMG_GENERIC, player)
		
		forward.Norm()
		forward.z = 1.5
		closest_player.ApplyAbsVelocityImpulse(forward * 360.0)
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		
		Ware_DisablePlayerPrimaryFire(player)

		local weapon = player.GetActiveWeapon()
		local next_attack = weapon ? GetPropFloat(weapon, "m_flNextSecondaryAttack") : 0.0
		if (next_attack > minidata.last_attack)
		{
			minidata.last_attack = next_attack
			
			local target = player // squirrel needs this to be happy
			Ware_CreateTimer(@() target.IsValid() ? PushClosestTarget(target, 128.0) : null, 0.2)
		}
	}
}

//from https://github.com/potato-tf/OOAssets/blob/main/scripts/vscripts/rev_spacepost_pea.nut#L2891
function SpawnCap(origin)
{
	obj_control_blucapture_rate <- RemapValClamped(Ware_MinigamePlayers.len().tofloat(), 0.0, 13.0, 7.0, 12.0)

	local control_point_3 = Ware_SpawnEntity("team_control_point",
	{
		origin                    = origin
		targetname                = "control_point_3"
		team_timedpoints_3        = 0
		team_timedpoints_2        = 0
		team_previouspoint_3_0    = "control_point_3"
		team_previouspoint_3_1    = "control_point_3"
		team_previouspoint_3_2    = "control_point_3"
		team_previouspoint_2_0    = "control_point_3"
		team_previouspoint_2_1    = "control_point_3"
		team_previouspoint_2_2    = "control_point_3"
		team_overlay_3            = "sprites/obj_icons/icon_obj_c"
		team_overlay_2            = "sprites/obj_icons/icon_obj_c"
		team_overlay_0            = "sprites/obj_icons/icon_obj_c"
		team_model_3              = "models/effects/cappoint_hologram.mdl"
		team_model_2              = "models/effects/cappoint_hologram.mdl"
		team_model_0              = "models/effects/cappoint_hologram.mdl"
		team_icon_3               = "sprites/obj_icons/icon_obj_blu_mannhattan"
		team_icon_2               = "sprites/obj_icons/icon_obj_red"
		team_icon_0               = "sprites/obj_icons/icon_obj_neutral"
		team_bodygroup_3          = 0
		team_bodygroup_2          = 1
		team_bodygroup_0          = 3
		spawnflags                = 4
		point_warn_sound          = "ControlPoint.CaptureWarn"
		point_warn_on_cap         = 2
		point_printname           = "the freaking point"
		point_index               = 0
		point_group               = 0
		point_default_owner       = 0
		point_start_locked        = 0
	})
	
	local control_point_3_trigger = Ware_SpawnEntity("trigger_capture_area",
	{
		targetname         = "control_point_3_trigger"
		origin             = origin
		team_startcap_3    = 1
		team_startcap_2    = 1
		team_numcap_3      = 1
		team_numcap_2      = 1
		team_cancap_3      = 1
		team_cancap_2      = 1
		area_time_to_cap   = obj_control_blucapture_rate
		area_cap_point     = "control_point_3"
		// this hack is needed for help voicelines to work
		model         	   = "*2"
	})
	
	local control_point_3_base = Ware_SpawnEntity("prop_dynamic",
	{
		origin	= origin
		model	= "models/props_gameplay/cap_point_base.mdl"
		solid	= SOLID_VPHYSICS
	})
	
	control_point_3_trigger.AcceptInput("SetControlPoint", "control_point_3", null, null)
	
	EntityAcceptInput(control_point_3_trigger, "SetControlPoint", "control_point_3")
	
	control_point_3_trigger.KeyValueFromFloat("area_time_to_cap", obj_control_blucapture_rate)
	SetPropFloat(control_point_3_trigger, "m_flCapTime", obj_control_blucapture_rate)
	
	control_point_3_trigger.SetSize(Vector(-150, -150, -100), Vector(150, 150, 250))
	control_point_3_trigger.SetSolid(SOLID_BBOX)
	// this hack is needed for help voicelines to work
	control_point_3_trigger.KeyValueFromInt("solid", SOLID_BSP)
	
	control_point_3_trigger.ValidateScriptScope()
	control_point_3_trigger.GetScriptScope().OnStartTouch <- OnTriggerStartTouch
	control_point_3_trigger.GetScriptScope().OnEndTouch <- OnTriggerEndTouch
	control_point_3_trigger.ConnectOutput("OnStartTouch", "OnStartTouch")
	control_point_3_trigger.ConnectOutput("OnEndTouch", "OnEndTouch")

	control_point_3_trigger.GetScriptScope().OnEndCap <- OnTriggerEndCap
	control_point_3_trigger.ConnectOutput("OnEndCap", "OnEndCap")

	Ware_SpawnEntity("team_control_point_master",
	{
		team_base_icon_3             = "sprites/obj_icons/icon_base_blu"
		team_base_icon_2             = "sprites/obj_icons/icon_base_red"
		switch_teams                 = 0
		score_style                  = 1
		custom_position_y            = -1
		custom_position_x            = 0.475
		cpm_restrict_team_cap_win    = 1
		caplayout                    = "0, 1 2"
	})
	
	control_point_3.AcceptInput("SetLocked", "0", null, null)
}

function OnTriggerStartTouch()
{
	if (activator && activator.IsPlayer())
		Ware_GetPlayerMiniData(activator).in_cap = true
}

function OnTriggerEndTouch()
{
	if (activator && activator.IsPlayer())
		Ware_GetPlayerMiniData(activator).in_cap = false
}

function OnTriggerEndCap()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (Ware_GetPlayerMiniData(player).in_cap)
			Ware_PassPlayer(player, true)
	}
}

function OnCleanup()
{
	SetPropInt(GameRules, "m_nHudType", 0)
	//Prevent capture tooltip from staying forever
	foreach(pl in Ware_MinigamePlayers)
	{
		SendGlobalGameEvent("intro_finish", { player = pl.entindex() })
	}
}