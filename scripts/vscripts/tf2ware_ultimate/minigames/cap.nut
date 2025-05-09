minigame <- Ware_MinigameData
({
	name        = "Cap the Point"
	author      = ["tilderain"]
	description = "Help me cap!"
	duration    = 12.5
	music       = "bloober"
	allow_damage = true
	friendly_fire = true
	convars = 
	{
		tf_avoidteammates = 1
		tf_avoidteammates_pushaway = 1
		tf_scout_air_dash_count = 0 
		mp_teams_unbalance_limit = 0
	}
})

control_point_controller <- null
control_point_3 <- null
control_point_3_trigger <- null

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Shortstop")
	SetPropInt(GameRules, "m_nHudType", 2)

	local origin = Vector(
		RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
		RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
		Ware_MinigameLocation.center.z)

	SpawnCap(origin)

	local heavy_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerTeam(player, heavy_team)
		local minidata = Ware_GetPlayerMiniData(player)
		local atk = 0.0
		local weapon = player.GetActiveWeapon()
		if (weapon)
			atk = GetPropFloat(weapon, "m_flNextSecondaryAttack")
		minidata.lastAtk <- atk
		if(VectorDistance(player.GetOrigin(), origin) < 200)
			player.SetOrigin(player.GetOrigin() + Vector(0,0,25))
		minidata.inCap <- false
	}

	EntFire("control_point_3", "SetLocked", "0")
	
	//Prevent ui lingering
	CreateTimer(@() MovePoint(), 11.75)
}

function PushLine(self, radius)
{
	local player_origin = self.GetOrigin()
	local player_team = self.GetTeam()
	local start = self.GetCenter()
	local forward = self.EyeAngles().Forward()
	foreach (other in Ware_MinigamePlayers)
	{
		if(other == self)
			continue
		forward.z = 0.0
		forward.Norm()
		
		local otherOrg = other.GetOrigin() 
		local mins = otherOrg + other.GetPlayerMins()
		local maxs = otherOrg + other.GetPlayerMaxs()
		
		//DebugDrawLine(start, start + forward * radius, 255, 0, 0, false, 5.0)
		//DebugDrawBox(vec3_zero, mins, maxs, 255, 0, 0, 20, 5.0)

		local t = IntersectRayWithBox(start, forward, mins, maxs, 0.0, radius)
		if (t >= 0.0)
		{
			other.EmitSound( "Weapon_Hands.PushImpact" )
			forward.z = 2.0
			other.TakeDamage(5, DMG_CLUB, self)
			other.ApplyAbsVelocityImpulse(forward*360)
		}
	}
}

function MovePoint()
{
	if(control_point_3_trigger)
		control_point_3_trigger.SetOrigin(Vector(0,0,0))
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		Ware_DisablePlayerPrimaryFire(player)

		local weapon = player.GetActiveWeapon()
		local atk = 0.0
		if (weapon)
			atk = GetPropFloat(weapon, "m_flNextSecondaryAttack")
		if("lastAtk" in minidata && minidata.lastAtk != atk)
		{
			local target = player // squirrel needs this to be happy
			Ware_CreateTimer(@() PushLine(target, 128.0), 0.2)
			minidata.lastAtk = atk
		}

	}

}

//from https://github.com/potato-tf/OOAssets/blob/main/scripts/vscripts/rev_spacepost_pea.nut#L2891
function SpawnCap(org)
{
	obj_control_blucapture_rate <- RemapValClamped(Ware_MinigamePlayers.len().tofloat(), 0.0, 13.0, 7.0, 12.0)

	control_point_3 = Ware_SpawnEntity("team_control_point",
	{
		origin                    = org
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
		point_printname           = "The freaking point"
		point_index               = 0
		point_group               = 0
		point_default_owner       = 0
		point_start_locked        = 0
	})
	
	control_point_3_trigger = SpawnEntityFromTableSafe("trigger_capture_area",
	{
		targetname         = "control_point_3_trigger"
		origin             = org
		mins               = Vector(-150, -150, -100)
		maxs               = Vector(150, 150, 250)
		solid              = SOLID_BSP
		team_startcap_3    = 1
		team_startcap_2    = 1
		team_numcap_3      = 1
		team_numcap_2      = 1
		team_cancap_3      = 1
		team_cancap_2      = 1
		area_time_to_cap   = obj_control_blucapture_rate
		area_cap_point     = "control_point_3"
		model         = "*1" //Use a random brush model because valve really wants you to have a brush model so scout can be a cocksucker
	})
	
	local control_point_3_base = Ware_SpawnEntity("prop_dynamic",
	{
		origin        = org
		model         = "models/props_gameplay/cap_point_base.mdl"
		solid = SOLID_VPHYSICS
	})
	
	EntFire("control_point_3_trigger", "SetControlPoint", "control_point_3")
	control_point_3_trigger.KeyValueFromFloat("area_time_to_cap", obj_control_blucapture_rate)
	SetPropFloat(control_point_3_trigger, "m_flCapTime", obj_control_blucapture_rate)
	
	control_point_3_trigger.KeyValueFromString("mins", "-150 -150 -100")
	control_point_3_trigger.KeyValueFromString("maxs", "150 150 250")
	control_point_3_trigger.KeyValueFromInt("solid", SOLID_BSP)

	control_point_3_trigger.ValidateScriptScope()
	control_point_3_trigger.GetScriptScope().OnStartTouch <- OnTriggerStartTouch
	control_point_3_trigger.GetScriptScope().OnEndTouch <- OnTriggerEndTouch
	control_point_3_trigger.ConnectOutput("OnStartTouch", "OnStartTouch")
	control_point_3_trigger.ConnectOutput("OnEndTouch", "OnEndTouch")

	control_point_3_trigger.GetScriptScope().OnEndCap <- OnTriggerEndCap
	control_point_3_trigger.ConnectOutput("OnEndCap", "OnEndCap")

	EntFire("control_point_3", "SetLocked", "0")

	control_point_controller = Ware_SpawnEntity("team_control_point_master",
	{
		targetname                   = "control_point_controller"
		team_base_icon_3             = "sprites/obj_icons/icon_base_blu"
		team_base_icon_2             = "sprites/obj_icons/icon_base_red"
		switch_teams                 = 0
		score_style                  = 1
		custom_position_y            = -1
		custom_position_x            = 0.475
		cpm_restrict_team_cap_win    = 1
		caplayout                    = "0, 1 2"
	})
}

function OnTriggerStartTouch()
{
	if (activator && activator.IsPlayer())
	{
		local minidata = Ware_GetPlayerMiniData(activator)
		minidata.inCap = true
	}
}

function OnTriggerEndTouch()
{
	if (activator && activator.IsPlayer())
	{
		local minidata = Ware_GetPlayerMiniData(activator)
		minidata.inCap = false
	}
}
function OnTriggerEndCap()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		if(minidata.inCap)
			Ware_PassPlayer(player, true)
	}
}

function OnCleanup()
{
	SetPropInt(GameRules, "m_nHudType", 0)
}