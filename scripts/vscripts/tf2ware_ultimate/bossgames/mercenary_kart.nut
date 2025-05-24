// This is salvaged code from a scrapped gamemode
// Here be dragons...

// TODO fix blooper rotation
// TODO can't reverse up slopes
// TODO fix $bbox for course model
// TODO fix EmitSoundOnClient calls to be pitched (need to check every minigame)
// TODO add pinball pass sound
// TODO convert all sounds to mp3

minigame <- Ware_MinigameData
({
	name           = "Mercenary kart"
	author         = "ficool2"
	description    = "Complete 3 laps faster than your opponents!"
	duration       = 360.0
	location       = "waluigi_pinball"
	music          = null
	custom_overlay = ""
	min_players    = 2
	max_scale      = 1.0
	convars = 
	{
		sv_maxvelocity = 5000.0
	}
})

kart_base_offset    <- Vector(0, 0, 18)
kart_mins           <- Vector(-32, -34, -kart_base_offset.z)
kart_maxs           <- Vector(60, 34, 16)
kart_acceleration   <- 12.0
kart_friction       <- 450.0
kart_speed_cap      <- 1000.0
kart_back_speed_cap <- 600.0
kart_turn_rate      <- 64.0
kart_id             <- 0

camera_base_offset  <- Vector(-140.0, 0.0, 70.0)
camera_base_rotaton <- QAngle(10, 0, 0)

race_start_time     <- 0.0
race_max_laps       <- 2
race_sequence       <- 0
race_results        <- []
race_finish_timer   <- null
race_bonus_players  <- []

itembox_respawn_time <- 0.0
item_shock_timer     <- 0.0
item_blooper_timer   <- 0.0

intro_camera         <- null
intro_camera_start   <- 0.0
intro_camera_end     <- 0.0
intro_camera_seq     <- -1
intro_skip           <- false

game_over            <- false

tick_counter         <- 0

pinball_spinners     <- []

// fast constants for karts/items
local karts                  = []
local karts_finished         = []

local map_data               = {}

local team_battle            = Ware_SpecialRound && !Ware_SpecialRound.friendly_fire

local item_map               = {}

local gravity_rate           = Convars.GetFloat("sv_gravity")

local kart_drift_pfx_index   = array(4)

local kart_touch_swap        = null
local kart_skip_tick         = 1

local BOOST_NONE			 = 0
local BOOST_DRIFT			 = 1
local BOOST_SURFACE			 = 2
local BOOST_SHROOM			 = 3

local SPINOUT_NONE			 = 0
local SPINOUT_SPIN			 = 1
local SPINOUT_SPIN_DOUBLE	 = 2
local SPINOUT_TUMBLE_FORWARD = 3
local SPINOUT_TUMBLE_LEFT	 = 4
local SPINOUT_TUMBLE_RIGHT	 = 5
local SPINOUT_LAUNCH_UP		 = 6
local SPINOUT_ENGINE_FAIL	 = 7

local ITEM_NONE				 = 0
local ITEM_BANANA_ONE		 = 1
local ITEM_SHROOM_MEGA		 = 2
local ITEM_POW				 = 3
local ITEM_SHOCK			 = 4
local ITEM_STAR				 = 5
local ITEM_SHROOM_TWO		 = 6
local ITEM_FIB				 = 7
local ITEM_BOMB				 = 8
local ITEM_SHROOM_THREE		 = 9
local ITEM_BULLET			 = 10
local ITEM_SHELL_BLUE		 = 11
local ITEM_SHROOM_ONE		 = 12
local ITEM_SHELL_RED_THREE	 = 13
local ITEM_SHELL_GREEN_ONE	 = 14
local ITEM_BANANA_THREE		 = 15
local ITEM_SHROOM_GOLD		 = 16
local ITEM_SHELL_RED_ONE	 = 17
local ITEM_BLOOPER			 = 18
local ITEM_SHELL_GREEN_THREE = 19
local ITEM_LAST				 = 20

local ITEM_TYPE_BANANA       = 0
local ITEM_TYPE_FIB          = 1
local ITEM_TYPE_BOMB         = 2
local ITEM_TYPE_STAR         = 3
local ITEM_TYPE_SHROOM       = 4
local ITEM_TYPE_SHROOM_MEGA  = 5
local ITEM_TYPE_SHROOM_GOLD  = 6
local ITEM_TYPE_SHELL_GREEN  = 7
local ITEM_TYPE_SHELL_RED    = 8
local ITEM_TYPE_SHELL_BLUE   = 9

intro_camera_keyframes <-
[
	[
		{ origin = Vector(-5404.341309, 449.267029, 11495.015625), angles = QAngle(0.330030, 162.756149, -1.0) },
		{ origin = Vector(4476.523926, -1973.590332, 10079.699219), angles = QAngle(7.260038, 159.654205, 0.0) },
	],
	[
		{ origin = Vector(6404.501953, 0.0, 8908.518555), angles = QAngle(38.279922, 0.198143, 0.0) },
		{ origin = Vector(8271.876953, 0.0, 6784.915039), angles = QAngle(-6.072084, -0.263856, 0.0) },
	],
	[
		{ origin = Vector(14699.632812, 1000.984131, 5760.234863), angles = QAngle(0.329931, 77.352219, 20.0) },
		{ origin = Vector(14809.538086, 4500.046143, 5713.182617), angles = QAngle(0.857931, 170.610474, 6.0) },
		{ origin = Vector(13039.982422, 4124.687012, 5719.630371), angles = QAngle(3.365931, -180.0, 0.0) },
	]
]

item_probability <- 
[
	[ 32.5, 17.5, 15.0, 7.50, 5.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 25.0, 25.0, 20.0, 15.0, 10.0, 5.00, 2.50, 0.00, 0.00, 0.00, 0.00 ],
	[ 37.5, 20.0, 7.50, 2.50, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 20.0, 7.50, 5.00, 2.50, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 12.5, 17.5, 22.5, 15.0, 12.5, 10.0, 0.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 0.00, 0.00, 5.00, 10.0, 15.0, 25.0, 32.5, 37.5, 30.0, 12.5, 5.00 ],
	[ 0.00, 0.00, 2.50, 5.00, 7.50, 7.50, 5.00, 0.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 0.00, 0.00, 2.50, 5.00, 7.50, 7.50, 5.00, 2.50, 0.00, 0.00, 0.00 ],
	[ 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 7.50, 20.0 ],
	[ 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 12.5, 20.0, 27.5, 27.5, 17.5 ],
	[ 0.00, 0.00, 0.00, 0.00, 0.00, 2.50, 10.0, 22.5, 27.5, 35.0, 30.0, 22.5 ],
	[ 0.00, 0.00, 0.00, 2.50, 7.50, 10.0, 7.50, 5.00, 0.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 0.00, 0.00, 0.00, 5.00, 7.50, 7.50, 5.00, 5.00, 0.00, 0.00, 0.00 ],
	[ 0.00, 0.00, 0.00, 0.00, 5.00, 5.00, 7.50, 5.00, 5.00, 0.00, 0.00, 0.00 ],
  //[ 0.00, 0.00, 2.50, 7.50, 7.50, 7.50, 5.00, 5.00, 0.00, 0.00, 0.00, 0.00 ],   thundercloud
	[ 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 2.50, 7.50, 22.5, 35.0 ],
	[ 0.00, 5.00, 10.0, 10.0, 7.50, 5.00, 2.50, 0.00, 0.00, 0.00, 0.00, 0.00 ],
  //[ 0.00, 0.00, 5.00, 10.0, 10.0, 10.0, 7.50, 5.00, 0.00, 0.00, 0.00, 0.00 ],   probability added from thundercloud
	[ 0.00, 0.00, 7.50, 17.5, 17.5, 17.5, 12.5, 10.0, 0.00, 0.00, 0.00, 0.00 ],
	[ 10.0, 12.5, 10.0, 2.50, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00, 0.00 ], 
]
item_table_to_id <- 
[	
	ITEM_SHELL_GREEN_ONE
	ITEM_SHELL_RED_ONE
	ITEM_BANANA_ONE
	ITEM_FIB
	ITEM_SHROOM_ONE
	ITEM_SHROOM_THREE
	ITEM_BOMB
	ITEM_SHELL_BLUE
	ITEM_SHOCK
	ITEM_STAR
	ITEM_SHROOM_GOLD
	ITEM_SHROOM_MEGA
	ITEM_BLOOPER
	ITEM_POW
	ITEM_BULLET
	ITEM_SHELL_GREEN_THREE
	ITEM_SHELL_RED_THREE
	ITEM_BANANA_THREE
]

function OnPrecache()
{
	PrecacheModel("effects/flagtrail_blu.vmt")
	PrecacheModel("models/mariokart/karts/mariokart.mdl")
	PrecacheModel("models/mariokart/karts/shadow.mdl")
	PrecacheModel("models/mariokart/hud.mdl")
	PrecacheModel("models/mariokart/head.mdl")
	PrecacheModel("models/mariokart/itembox.mdl")
	PrecacheModel("models/mariokart/itembox_mark.vmt")
	PrecacheModel("models/mariokart/items/fib_mark.vmt")
	PrecacheModel("models/mariokart/items/banana.mdl")
	PrecacheModel("models/mariokart/items/blooper.mdl")
	PrecacheModel("models/mariokart/items/bomb.mdl")
	PrecacheModel("models/mariokart/items/bullet.mdl")
	PrecacheModel("models/mariokart/items/fib.mdl")
	//PrecacheModel("models/mariokart/items/pow.mdl")
	PrecacheModel("models/mariokart/items/shell_blue.mdl")
	PrecacheModel("models/mariokart/items/shell_green.mdl")
	PrecacheModel("models/mariokart/items/shell_red.mdl")
	PrecacheModel("models/mariokart/items/shroom.mdl")
	PrecacheModel("models/mariokart/items/shroom_gold.mdl")
	PrecacheModel("models/mariokart/items/shroom_mega.mdl")
	PrecacheModel("models/mariokart/items/star.mdl")
	
	PrecacheSound("ui/vote_no.wav")
	PrecacheScriptSound("MK_Music_Pinball")
	PrecacheScriptSound("MK_Lap")
	PrecacheScriptSound("MK_Race_Intro")
	PrecacheScriptSound("MK_Race_Countdown")
	PrecacheScriptSound("MK_Race_Finish")
	PrecacheScriptSound("MK_Position_Gain")
	PrecacheScriptSound("MK_Position_Loss")	
	PrecacheScriptSound("MK_Cannon")
	PrecacheScriptSound("MK_Boost")
	PrecacheScriptSound("MK_Lakitu_Pickup")
	PrecacheScriptSound("MK_Kart_Drift_Boost")
	PrecacheScriptSound("MK_Kart_Hop")
	PrecacheScriptSound("MK_Kart_Land")
	PrecacheScriptSound("MK_Kart_Shrink")
	PrecacheScriptSound("MK_Kart_Grow")
	PrecacheScriptSound("MK_Kart_Spin")
	PrecacheScriptSound("MK_Kart_Burnout")
	PrecacheScriptSound("MK_Kart_Collide_Concrete")
	PrecacheScriptSound("MK_Kart_Collide_Vehicle")
	PrecacheScriptSound("MK_Kart_Engine")
	PrecacheScriptSound("MK_Kart_Engine_Idle")
	PrecacheScriptSound("MK_Kart_Drift")
	PrecacheScriptSound("MK_Kart_Drift_Sparks")
	PrecacheScriptSound("MK_Kart_Drift_Boost")
	PrecacheScriptSound("MK_Itembox_Hit")
	PrecacheScriptSound("MK_Itembox_Use")
	PrecacheScriptSound("MK_Itembox_Land")
	PrecacheScriptSound("MK_Item_Roulette")
	PrecacheScriptSound("MK_Item_Banana_Fly")
	PrecacheScriptSound("MK_Item_Banana_Land")
	PrecacheScriptSound("MK_Item_Shell_Hit")
	PrecacheScriptSound("MK_Item_Shell_Break")
	PrecacheScriptSound("MK_Item_Shell_Green_Follow")
	PrecacheScriptSound("MK_Item_Shell_Red_Follow")
	PrecacheScriptSound("MK_Item_Shell_Blue_Explode")
	PrecacheScriptSound("MK_Item_Shell_Blue_Fly")
	PrecacheScriptSound("MK_Item_Shell_Blue_Warning")
	PrecacheScriptSound("MK_Item_Bomb_Fuse")
	PrecacheScriptSound("MK_Item_Bomb_Explode")
	PrecacheScriptSound("MK_Item_Shroom_Use")
	PrecacheScriptSound("MK_Item_Shroom_Mega_Use")
	PrecacheScriptSound("MK_Item_Shroom_Mega_Music")
	PrecacheScriptSound("MK_Item_Shroom_Mega_Finish")
	PrecacheScriptSound("MK_Item_Star_Music")
	PrecacheScriptSound("MK_Item_Star_Hit")
	PrecacheScriptSound("MK_Item_Shock_Use")
	PrecacheScriptSound("MK_Item_Bullet_On")
	PrecacheScriptSound("MK_Item_Bullet_Fly")
    PrecacheScriptSound("MK_Item_Bullet_Off")
	PrecacheScriptSound("MK_Item_Blooper_Use")
	PrecacheScriptSound("MK_Item_Blooper_Attack")
	PrecacheScriptSound("MK_Bound_Hit")
	PrecacheScriptSound("MK_Pinball_Score")
	
	PrecacheParticle("bot_impact_heavy_sparks")
	PrecacheParticle("kart_impact_sparks")
	PrecacheParticle("drg_cow_explosion_sparkles")
	PrecacheParticle("drg_cow_explosioncore_charged_blue")
	PrecacheParticle("drg_cow_explosion_sparkles_charged_blue")
	PrecacheParticle("rd_robot_explosion_shockwave")
	PrecacheParticle("asplode_hoodoo_burning_debris")
	PrecacheParticle("fireSmokeExplosion_track")
	PrecacheParticle("enginefail")
	PrecacheParticle("spell_skeleton_bits_green")
	PrecacheParticle("spell_pumpkin_mirv_bits_red")
	PrecacheParticle("mk_lightning_parent")
	PrecacheParticle("sparks_blue")
	PrecacheParticle("drift_blue")
	PrecacheParticle("sparks_orange")
	PrecacheParticle("drift_orange")
	
	PrecacheMaterial("tf2ware_ultimate/grey")
}

function OnPick()
{
	// this lags large servers too hard with high timescale
	if (Ware_Players.len() > 24)
		return Ware_TimeScale <= 1.1
	return true
}

function OnTeleport(players)
{
	SetupMap()
	
	players = Ware_GetSortedScorePlayers(true)
	
	local start = Ware_MinigameLocation.start_position * 1.0
	local spacing_x = 200.0
	if (players.len() > 50)
		spacing_x *= 0.5
	Ware_TeleportPlayersRow(players, start, QAngle(0, 180, 0), 500.0, spacing_x, 150.0)
	
	foreach (player in players)
	{
		local origin = player.GetOrigin() + kart_base_offset
		local angles = player.GetAbsAngles()
		
		local kart = CreateKart(origin, angles)
		
		kart.SetupPoint()
		kart.Enter(player)
		
		karts.append(kart)
	}
	
	if (players.len() > 24)
		itembox_respawn_time = 0.75
	else if (players.len() > 12)
		itembox_respawn_time = 1.5
	else
		itembox_respawn_time = 3.0
}

function OnStart()
{
	local keyframe = intro_camera_keyframes[0][0]
	local camera = Ware_SpawnEntity("point_viewcontrol",
	{
		classname  = "mk_camera_intro"
		origin     = keyframe.origin
		angles     = keyframe.angles
		spawnflags = 8
	})
	camera.SetMoveType(MOVETYPE_NONE, 0)
	
	foreach (player in Ware_Players)
	{
		Ware_SetPlayerClass(player, RandomInt(TF_CLASS_FIRST, TF_CLASS_LAST))
		TogglePlayerViewcontrol(player, camera, true)
		player.AddHudHideFlags(HIDEHUD_MISCSTATUS|HIDEHUD_HEALTH)
	}
	
	local start_duration = 2.5
	intro_camera       = camera
	intro_camera_start = Time()
	intro_camera_end   = intro_camera_start + start_duration
	
	if (intro_skip)
		race_sequence = 2
	else
		Ware_PlaySoundOnAllClients("MK_Race_Intro")
	
	CreateTimer(function()
	{
		race_sequence++
		if (race_sequence == 1)
		{
			local duration = 3.5
			intro_camera_start += duration
			intro_camera_end   += duration
			return duration
		}
		else if (race_sequence == 2)
		{
			local duration = 4.0
			intro_camera_start += duration
			intro_camera_end   += duration
			return duration
		}
		else if (race_sequence == 3)
		{
			RacePrepare()
		}
	}, start_duration)
}

function RacePrepare()
{
	// don't hit the sound limit...
	local engine_sound_limiter = (karts.len() / 13) + 1
	foreach (i, player in Ware_Players)
	{	
		local kart = GetKart(player)
		if (kart)
		{
			player.RemoveHudHideFlags(HIDEHUD_HEALTH)
			TogglePlayerViewcontrol(player, kart.m_camera, true)
			
			kart.m_engine_noises = (i % engine_sound_limiter) == 0 || player == Ware_ListenHost
		}
		else
		{
			player.RemoveHudHideFlags(HIDEHUD_MISCSTATUS|HIDEHUD_HEALTH)
			TogglePlayerViewcontrol(player, intro_camera, false)
		}
	}
	intro_camera.Kill()
	
	CreateTimer(RaceCountdown3, 2.0)
}

function RaceCountdown3()
{
	Ware_ShowScreenOverlay(Ware_Players, "hud/tf2ware_ultimate/countdown_3")
	CreateTimer(@() Ware_PlaySoundOnAllClients("MK_Race_Countdown"), 0.5)
	CreateTimer(RaceCountdown2, 1.0)
}

function RaceCountdown2()
{
	Ware_ShowScreenOverlay(Ware_Players, "hud/tf2ware_ultimate/countdown_2")
	CreateTimer(RaceCountdown1, 1.0)
}

function RaceCountdown1()
{
	Ware_ShowScreenOverlay(Ware_Players, "hud/tf2ware_ultimate/countdown_1")
	CreateTimer(RaceCountdownGo, 1.0)
}

function RaceCountdownGo()
{
	Ware_ShowScreenOverlay(Ware_MinigamePlayers, "hud/tf2ware_ultimate/go")
	CreateTimer(function() 
	{
		Ware_ShowScreenOverlay(Ware_Players, null)
		ToggleMusic(true)
	}, 1.5)
	RaceStart()
}

function ToggleMusic(toggle)
{
	local params = 
	{
		sound_name  = "MK_Music_Pinball"
		entity      = null
		filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
	}
	
	if (!toggle)
		params.flags <- SND_STOP
	
	// must be played like this so it can be controlled per-player
	foreach (player in Ware_Players)
	{
		params.entity = player
		EmitSoundEx(params)
	}	
}

function RaceStart()
{
	local time = Time()
	
	race_sequence = 4
	race_start_time = time
	SetPropVector(World, "m_WorldMaxs", Vector(race_max_laps, race_start_time, 0))
	
	item_shock_timer   = time + 30.0
	item_blooper_timer = time + 15.0
	
	Ware_ShowScreenOverlay(Ware_MinigamePlayers, "hud/tf2ware_ultimate/go")
	CreateTimer(@() Ware_ShowScreenOverlay(Ware_Players, null), 1.5)
	
	foreach (kart in karts)	
	{
		SetPropEntity(kart.m_hud, "m_hBuilder", kart.m_driver)
		kart.m_position_timer = time + 3.0
	}
}

function RaceEnd()
{
	if (race_sequence != 4)
		return
		
	race_sequence++
	
	karts_finished.clear()
	karts_finished = clone(karts)				
	RaceCheckFinishers()
	
	CreateTimer(RaceResults, 2.0)
}

function RaceShowResult()
{
	local start = Ware_MinigameHomeLocation.mins + Vector(0, 0, 430)
	
	local padding = 32.0	
	local background_width = Ware_MinigameHomeLocation.maxs.y - Ware_MinigameHomeLocation.mins.y
	local background = Ware_SpawnEntity("vgui_screen", 
	{
		origin          = Ware_MinigameHomeLocation.mins - Vector(1, padding, 0)
		angles          = QAngle()
		panelname       = "pda_panel_spy_invis"
		overlaymaterial = "tf2ware_ultimate/grey"
		width           = background_width + padding * 2.0
		height          = 640.0
	})
	SetPropInt(background, "m_fScreenFlags", 17)
	
	Ware_SpawnEntity("point_worldtext",
	{
		message  = "RANKINGS"
		angles   = QAngle(0, 180, 0)
		origin   = start + Vector(0, 0, 90)
		font     = 8
		textsize = 130
		rainbow  = true
	})
	
	local text_size = 32
	local spacing_x = 700.0
	local spacing_y = 32.0
	local row_size = 12
	if (race_results.len() > 64)
	{
		text_size = 16
		spacing_x *= 0.5
		spacing_y *= 0.5
		row_size = 25
	}
	else if (race_results.len() > 24)
	{
		text_size = 24
		spacing_x *= 0.7
		spacing_y *= 0.75
		row_size = 24
	}

	local kv =
	{
		message      = null
		origin       = start * 1.0
		angles       = QAngle(0, 180, 0)
		font         = 8
		textsize     = text_size
		textspacingX = -18
		color        = null
	}
	
	local win_threshold
	if (Ware_MinigamePlayers.len() > 64)
		win_threshold = 10
	else if (Ware_MinigamePlayers.len() > 24)
		win_threshold = 6
	else if (Ware_MinigamePlayers.len() > 6)
		win_threshold = 3
	else
		win_threshold = 1
	
	for (local i = Ware_MinigameScope.race_results.len() - 1; i >= 0; i--)
	{
		local result = Ware_MinigameScope.race_results[i]
		if (i < win_threshold)
			kv.color = "255 255 0"
		else
			kv.color = format("%d %d %d", 255 - i, 255 - i, 255 - i)
				
		local pos = i + 1
		local prefix = "th"
		local postfix = i < 99 ? " " : ""
		local digit = pos % 10
		if (pos < 10 || pos > 20)
		{
			if (digit == 1)
				prefix = "st"
			else if (digit == 2)
				prefix = "nd"
			else if (digit == 3)
				prefix = "rd"
		}
		
		local time_format
		if (result.timeout)
		{
			time_format = "99:99:999"
		}
		else
		{
			local final_time = 0.0
			foreach (times in result.times)
				final_time += times
			time_format = FloatToTimeFormat(final_time)
		}
		
		kv.message = format("%2d%s: %24s : %s", pos, prefix + postfix, result.name, time_format)
		kv.origin.y = start.y + spacing_x * (i / row_size)
		kv.origin.z = start.z - spacing_y * (i % row_size)
		Ware_SpawnEntity("point_worldtext", kv)
		
		local player = result.player
		if (player.IsValid())
		{
			if (pos <= win_threshold)
			{
				Ware_PassPlayer(player, true)

				// bonus for getting top 3 with more than 24 racers
				// NOTE; not awarding bonus immediately because the callback breaks the generator
				if (i <= 2 && Ware_MinigamePlayers.len() > 24)
					race_bonus_players.append(player)
			}
		}
		
		local volume = 1.0
		local pitch
		if (i >= 20)
		{
			volume = 0.5
			pitch = 125
		}
		else if (i >= 10)
		{
			volume = 0.75
			pitch = 120
		}
		else if (i >= 3)
		{
			volume = 0.9
			pitch = 115
		}
		else if (i >= 1)
		{
			volume = 0.95
			pitch = 110
		}
		else
		{
			volume = 1.0
			pitch = 100
		}
		
		Ware_PlaySoundOnAllClients("ui/vote_no.wav", volume, pitch)

		if (i >= 20)
			yield 0.1
		else if (i >= 5)
			yield 0.2
		else if (i >= 3)
			yield 0.5
		else if (i >= 2)
			yield 1.0
		else
			yield 2.0
	}
}

function RaceResults()
{
	Ware_ToggleRespawnRooms(true)
	
	foreach (player in Ware_MinigamePlayers)
		player.ForceRespawn()
		
	local result = RaceShowResult()
	Ware_CreateTimer(function()
	{
		local delay = resume result
		if (delay != null)
			return delay		
		game_over = true
		foreach (player in race_bonus_players)
		{
			if (player.IsValid())
				Ware_GiveBonusPoints(player)
		}
	}, 0.5)
}

function RaceCheckFinishers()
{
	foreach (kart in karts_finished)
	{
		if (race_finish_timer == null)
		{
			race_finish_timer = Ware_CreateTimer(function()
			{
				if (race_sequence == 4)
				{
					Ware_ChatPrint(null, "The race has ended because the winner was decided more than 30 seconds ago")
					RaceEnd()
				}
			}, 30.0)
		}
		
		kart.Finish()
			
		local player = kart.m_driver
		race_results.append
		({
			player  = player
			name    = GetPlayerName(player)
			times   = clone(kart.m_lap_times)
			timeout = race_sequence > 4
		})
				
		kart.Destroy()		
		
		if (player)
			KillPlayerSilently(player)
	}	
	
	karts_finished.clear()
	
	if (race_sequence == 4 && karts.len() == 0)
		RaceEnd()
}

function RaceCleanup()
{
	race_sequence = 5
}

function UpdateIntroCamera(time)
{
	if (race_sequence != intro_camera_seq)
	{
		EntityMarkTeleport(intro_camera)
		intro_camera_seq = race_sequence
	}
	
	local keyframes = intro_camera_keyframes[race_sequence]
	local keyframe_a = keyframes[0]
	local keyframe_b = keyframes[1]
	local origin, angles
	
	local t = 1.0
	if (time <= intro_camera_end)
	{
		t = RemapVal(time, intro_camera_start, intro_camera_end, 0.0, 1.0)	
		if (race_sequence == 2) // HACK interp is going crazy
			t = 0.35 + (t * 0.65)
		t = 1.0 - pow(1.0 - t, 2.0)
	}
	
	if (keyframes.len() >= 3)
	{
		local keyframe_c = keyframes[2]

		local ab = Lerp(keyframe_a.origin, keyframe_b.origin, t)
		local bc = Lerp(keyframe_b.origin, keyframe_c.origin, t)
		origin = Lerp(ab, bc, t)
		
		local ab_quat = QuaternionBlend(keyframe_a.quat, keyframe_b.quat, t)
		local bc_quat = QuaternionBlend(keyframe_b.quat, keyframe_c.quat, t)
		angles = QuaternionBlend(ab_quat, bc_quat, t).ToQAngle()
	}
	else
	{
		origin = Lerp(keyframe_a.origin, keyframe_b.origin, t)
		angles = QuaternionBlend(keyframe_a.quat, keyframe_b.quat, t).ToQAngle()	
	}
	
	intro_camera.SetAbsOrigin(origin)
	intro_camera.SetAbsAngles(angles)
}

function OnUpdate()
{
	local time = Time()
	local frame = tick_counter++
	
	if (intro_camera && race_sequence < 3)
		UpdateIntroCamera(time)
		
	foreach (kart in karts)
		kart.m_map_point_delta = (kart.m_map_next_point - kart.m_origin).Length()
	
	karts.sort(function(a, b)
	{
		local x = b.m_lap_idx <=> a.m_lap_idx
		if (x != 0)
			return x
		x = b.m_map_point_idx <=> a.m_map_point_idx
		if (x != 0)
			return x
		return a.m_map_point_delta <=> b.m_map_point_delta
	})
	
	local position_shift = race_results.len()
		
	foreach (i, kart in karts)
	{
		kart.SetPosition(i, position_shift, time)
		kart.Update(time, frame)
	}

	RaceCheckFinishers()
	
	// TODO this makes the kart in the camera very jittery
	//if (karts.len() > 80)
	//	kart_skip_tick = 3
	//else if (karts.len() > 40)
	//	kart_skip_tick = 2
	//else
	//	kart_skip_tick = 1
}

function OnCheckEnd()
{
	return game_over
}

function OnCleanup()
{
	ToggleMusic(false)

	foreach (player in Ware_MinigamePlayers)
	{
		local kart = GetKart(player)
		if (kart)
			kart.Destroy()
	}
}

function OnPlayerDeath(player, attacker, params)
{
	player.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)

	local kart = GetKart(player)
	if (kart)
	{
		// unsure why this needs to be done again
		EntFire("tf_ammo_pack", "Kill")
		EntFire("tf_ragdoll", "Kill")
		EntityEntFire(player, "DispatchEffect", "ParticleEffectStop")
		EntityEntFire(player, "CallScriptFunction", "PlayerResetHealth")	
		player.AddCond(TF_COND_HALLOWEEN_IN_HELL)
		
		if (race_sequence == 4)
		{
			CreateTimer(function()
			{
				if (player.GetTeam() & TF_TEAM_MASK)
				{
					kart.RescueInit()
				}
				else
				{
					kart = GetKart(player)
					if (kart)
						kart.Destroy()
				}
			}, 0.0)
		}
	}
}

// saxton hale rage support
function OnGameEvent_player_stunned(params)
{
	local victim = GetPlayerFromUserID(params.victim)
	if (victim)
	{
		local kart = GetKart(victim)
		if (kart && kart.CanSpinout())
		{
			kart.Spinout(SPINOUT_SPIN)
			kart.DropItems()
		}
	}
}

function OnPlayerDisconnect(player)
{
	local kart = GetKart(player)
	if (kart)
		kart.Destroy()
}

function SetupMap()
{
	local bound_thinker = Ware_CreateEntity("logic_relay")
	local bounds = Ware_MinigameLocation.bound_spinners
	local bound_spin_pos = Ware_MinigameLocation.bound_spin_pos
	bound_thinker.ValidateScriptScope()
	bound_thinker.GetScriptScope().ThinkBound <- function()
	{
		local yaw = RemapVal(Time() % 10.0, 0.0, 10.0, -180.0, 180.0)
		local rotation_yaw = QAngle(0, yaw, 0)
		local rotation_pitch = QAngle(10, 0, 0)	
		foreach (bound in bounds)
		{
			local position = RotatePosition(vec3_zero, rotation_yaw, bound.origin_relative)
			position = RotatePosition(vec3_zero, rotation_pitch, position) + bound_spin_pos
			bound.self.SetAbsOrigin(position)
		}
		return 0.05
	}
	AddThinkToEnt(bound_thinker, "ThinkBound")

	local points = [], planes = []
	local point_start_indices = [], point_end_indices = []
	
	local group_index = 0
	foreach (point_group in Ware_MinigameLocation.point_groups)
	{
		local point_group_len = point_group.len()
		point_start_indices.append(group_index)
		point_end_indices.append(group_index + point_group_len)
		group_index += point_group_len
		
		foreach (i, point in point_group)
			points.append(point)
	}
	
	local points_len = points.len()
	foreach (i, point in points)
	{	
		local dir = points[(i + 1) % points_len] - point
		dir.Norm()
		planes.append({normal = dir, dist = point.Dot(dir)})
	}
	
	foreach (itembox_pos in Ware_MinigameLocation.itembox_positions)
		CreateItembox(itembox_pos)

	map_data =
	{
		center              = Ware_MinigameLocation.center
		head_center         = Ware_MinigameLocation.hud_head_pos
		checkpoint_last     = Ware_MinigameLocation.checkpoints.len() - 1
		points              = points
		point_count         = points_len
		point_start_indices = point_start_indices
		point_end_indices   = point_end_indices		
		planes              = planes
	}
	
	foreach (sequence in intro_camera_keyframes)
	{
		foreach (keyframe in sequence)
			keyframe.quat <- keyframe.angles.ToQuat()
	}
	
	local map_camera = Ware_SpawnEntity("point_camera",
	{
		origin = Ware_MinigameLocation.hud_camera_pos
		fov    = 8.0
	})
	map_camera.AcceptInput("SetOn", "", null, null)
	// workaround for networking bug
	SetPropInt(map_camera, "m_nTransmitStateOwnedCounter", 1)
	
	// needed for camera to get networked for everyone
	local network_dummy = Ware_SpawnEntity("handle_dummy",
	{
		origin = Ware_MinigameLocation.start_position + Vector(0, 0, 128)
	})
	local camera_link = Ware_CreateEntity("info_camera_link")
	SetPropEntity(camera_link, "m_hCamera", map_camera)
	SetPropEntity(camera_link, "m_hTargetEntity", network_dummy)
	
	// cache particle indices
	kart_drift_pfx_index[0] = PrecacheParticle("sparks_blue")
	kart_drift_pfx_index[1] = PrecacheParticle("drift_blue")
	kart_drift_pfx_index[2] = PrecacheParticle("sparks_orange")
	kart_drift_pfx_index[3] = PrecacheParticle("drift_orange")
}

function CreateItembox(origin)
{
	local itembox = Ware_SpawnEntity("prop_dynamic_override",
	{
		classname   = "mk_itembox"
		origin      = origin
		model       = "models/mariokart/itembox.mdl"
		solid       = SOLID_BBOX
		defaultanim = "idle"
	})
	itembox.SetCycle(RandomFloat(0.0, 1.0))
	local sprite = SpawnEntityFromTableSafe("env_glow",
	{
		origin     = itembox.GetOrigin() - Vector(0, 0, 2),
		model      = "models/mariokart/itembox_mark.vmt"
		scale      = 0.5
		rendermode = kRenderTransColor
	})
	SetEntityParent(sprite, itembox)
	itembox.ValidateScriptScope()
	itembox.GetScriptScope().Touch <- function(kart)
	{
		self.EmitSound("MK_Itembox_Use")
		DispatchParticleEffect("bot_impact_heavy_sparks", self.GetOrigin() - Vector(0, 0, 48), Vector(90, 0, 0))
		
		EntityAcceptInput(self, "DisableCollision")
		EntityAcceptInput(self, "Disable")
		EntityAcceptInput(sprite, "HideSprite")
		
		local delay = Ware_MinigameScope.itembox_respawn_time
		EntityEntFire(self, "Enable", "", delay)
		EntityEntFire(self, "EnableCollision", "", delay)
		EntityEntFire(sprite, "ShowSprite", "", delay)
		
		kart.RollItem()
	}
	return itembox
}

function CreateKart(origin, angles)
{
	// touches items and itemboxes
	local kart_entity = Ware_SpawnEntity("trigger_brush",
	{
		classname = "mk_kart"
		origin    = origin
		angles    = angles
	})
	kart_entity.DisableDraw()
	kart_entity.SetMoveType(MOVETYPE_PUSH, 0)
	kart_entity.SetSolid(SOLID_OBB)
	kart_entity.SetSize(kart_mins, kart_maxs)
	AddThinkToEnt(kart_entity, "ThinkDummy") // without this no touch interactions work. I don't know why...
	SetPropInt(kart_entity, "m_nNextThinkTick", INT_MAX) // don't use base train think
	SetPropFloat(kart_entity, "m_flMoveDoneTime", 1e30) // enables physics
	kart_entity.ValidateScriptScope()
	kart_entity.ConnectOutput("OnStartTouch", "Touch")	
	local kart = kart_entity.GetScriptScope()
	
	// touches triggers
	local kart_proxy = Ware_SpawnEntity("trigger_brush",
	{
		classname = "mk_kart_proxy"
		origin    = origin
		angles    = angles
	})	
	kart_proxy.DisableDraw()
	kart_proxy.SetOwner(kart_entity)
	kart_proxy.RemoveSolidFlags(FSOLID_TRIGGER)
	kart_proxy.AddFlag(FL_NPC)
	kart_proxy.SetSolid(SOLID_OBB)
	kart_proxy.SetSize(kart_mins, kart_maxs)	
	kart_proxy.ValidateScriptScope()
	SetEntityParent(kart_proxy, kart_entity)
	// HACK: chain inputs from proxy to kart
	local kart_proxy_scope = kart_proxy.GetScriptScope()
	local kart_proxy_parent = kart_proxy_scope.getdelegate()
	SetInputHook(kart_proxy, "CallScriptFunction",
		@() (kart_proxy_scope.setdelegate(kart), true), 
		@() kart_proxy_scope.setdelegate(kart_proxy_parent))

	// visuals
	local kart_model = "models/mariokart/karts/mariokart.mdl"
	local kart_prop = Ware_SpawnEntity("prop_dynamic_override",
	{
		classname      = "mk_prop"
		origin         = origin
		angles         = angles
		model          = kart_model
		teamnum        = -23 // encodes tire speed (WTF)
		disableshadows = true
	})
	kart_prop.SetOwner(kart_entity)
						
	foreach (name, func in kart_routines)
		kart[name] <- func.bindenv(kart)
	
	kart.m_id                 <- kart_id++
	kart.m_driver             <- null	
	kart.m_driver_bot         <- false
	kart.m_entity             <- kart_entity
	kart.m_prop               <- kart_prop
	kart.m_model              <- kart_model
	kart.m_proxy              <- kart_proxy
	kart.m_team               <- TF_TEAM_RED
	
	kart.m_buttons            <- 0
	kart.m_buttons_last       <- 0
	kart.m_buttons_pressed    <- 0
	kart.m_buttons_released   <- 0
	
	kart.m_bot_distance       <- RandomFloat(175.0, 220.0)
	kart.m_bot_angle          <- RandomFloat(20.0, 30.0)
							  
	kart.m_forward_move       <- 0.0
	kart.m_side_move          <- 0.0
							  
	kart.m_origin             <- origin
	kart.m_angles             <- angles
	kart.m_forward            <- Vector()
	kart.m_direction          <- Vector()
	kart.m_velocity           <- Vector()
	kart.m_last_speed         <- 0.0
	kart.m_acceleration_rate  <- kart_acceleration
	kart.m_friction_rate      <- kart_friction
	kart.m_speed_cap          <- kart_speed_cap
	kart.m_back_speed_cap     <- kart_back_speed_cap
	kart.m_base_offset        <- kart_base_offset
	kart.m_gravity_factor     <- 1.0
	kart.m_ground             <- null
	kart.m_landed             <- false
	kart.m_slope_normal       <- Vector(0, 0, 1)
	kart.m_impact_timer       <- 0.0
	kart.m_turn_rate          <- kart_turn_rate
	kart.m_touch_timer        <- 0.0
							  
	kart.m_drifting           <- false
	kart.m_drift_pfx          <- null
	kart.m_drift_pfx_index    <- 0
	kart.m_drift_pfx_restart  <- 0
	kart.m_hop_timer          <- 0.0
	kart.m_hop_height         <- 0.0
	kart.m_engine_idle        <- false
	kart.m_engine_pitch       <- 0
	kart.m_engine_noises      <- false
	kart.m_tire_timer         <- 0.0
	kart.m_cannon_end_pos     <- null
	
	kart.m_boost_stage        <- 0
	kart.m_boost_counter      <- 0
	kart.m_boost_type         <- BOOST_NONE
	kart.m_boost_timer        <- 0.0
	kart.m_boost_side_move    <- 0.0
	
	kart.m_spin_out_type      <- SPINOUT_NONE
	kart.m_spin_out_timer     <- 0.0
							  
	kart.m_item_idx           <- ITEM_NONE
	kart.m_item_scope         <- null
	kart.m_items_held         <- []
	kart.m_items_held_idx     <- ITEM_NONE
	kart.m_items_held_scope   <- null
	kart.m_cur_item_scope     <- null  
	
	kart.m_star_timer         <- 0.0
	kart.m_mega_timer         <- 0.0
	kart.m_shrink_timer       <- 0.0
	kart.m_blooper_timer      <- 0.0
	kart.m_bullet_timer       <- 0.0
	kart.m_shroom_gold_timer  <- 0.0
	
	kart.m_rescued            <- false
	kart.m_rescue_point       <- null
	kart.m_rescue_plane       <- null
	kart.m_rescue_land_buffer <- 0
	
	kart.m_checkpoint_idx     <- map_data.checkpoint_last
	kart.m_lap_idx            <- -1
	kart.m_lap_valid_idx      <- INT_MIN
	kart.m_lap_last_time      <- 0.0
	kart.m_lap_times          <- []
	kart.m_position_idx       <- 0
	kart.m_position_relative  <- 0
	kart.m_position_timer     <- 1e30
	
	kart.m_map_point          <- null
	kart.m_map_plane          <- null
	kart.m_map_point_idx      <- -1
	kart.m_map_next_point     <- null
	kart.m_map_next_plane     <- null
	kart.m_map_next_point_idx <- null
	kart.m_map_point_delta    <- null
	
	kart.m_camera             <- CreateCamera(kart)
	kart.m_camera_pitch       <- 0.0
	kart.m_camera_yaw         <- 180.0
	kart.m_camera_offset      <- camera_base_offset
	kart.m_camera_reverse     <- false
	
	kart.m_hud                <- CreateHud(kart)
	kart.m_shadow             <- CreateShadow(kart)		
	kart.m_head               <- CreateHead(kart)
	kart.m_head_offset        <- Vector()

	kart.m_pinball_score      <- true
	
	kart.HudUpdateLap()
	kart.HudUpdatePosition()
	kart.HudUpdateItem(kart.m_item_idx)

	return kart
}

function CreateCamera(kart)
{
	local camera_angles = kart.m_entity.GetAbsAngles() + camera_base_rotaton
	local camera_origin = kart.m_entity.GetOrigin() 
		+ (camera_angles.Forward() * camera_base_offset.x) 
		+ (camera_angles.Up() * camera_base_offset.z)
	local camera = Ware_SpawnEntity("point_viewcontrol",
	{
		classname  = "mk_camera" // don't preserve
		origin     = camera_origin
		angles     = camera_angles
		spawnflags = 8
	})
	camera.SetMoveType(MOVETYPE_NONE, 0)
	return camera
}

function CreateShadow(kart)
{
	// save entities
	if (MAX_CLIENTS > 64)
		return null
	
	local shadow = Ware_SpawnEntity("prop_dynamic_override",
	{
		classname      = "mk_shadow"
		origin         = kart.m_entity.GetOrigin() - kart_base_offset
		angles         = kart.m_entity.GetAbsAngles()
		model          = "models/mariokart/karts/shadow.mdl"
		disableshadows = true
	})	
	return shadow
}

function CreateHud(kart)
{
	local camera = kart.m_camera
	local hud = CreateEntitySafe("obj_teleporter")
	hud.KeyValueFromString("classname", "mk_hud")
	hud.SetAbsOrigin(camera.GetOrigin())
	hud.SetAbsAngles(camera.GetAbsAngles())
	hud.SetModel("models/mariokart/hud.mdl")
	hud.SetSolid(SOLID_NONE)
	SetPropBool(hud, "m_bForcePurgeFixedupStrings", true)
	SetPropBool(hud, "m_bClientSideAnimation", false)
	SetPropBool(hud, "m_bPlacing", true)
	SetPropInt(hud, "m_fObjectFlags", 2)
	SetPropInt(hud, "m_fEffects", EF_NOSHADOW)
	SetEntityParent(hud, camera)
	return hud
}

function CreateHead(kart)
{
	local head = SpawnEntityFromTable("prop_dynamic_override",
	{
		classname      = "mk_head"
		origin         = Ware_MinigameLocation.hud_head_pos
		model          = "models/mariokart/head.mdl"
		disableshadows = true
		teamnum        = 2
	})
	head.DisableDraw()
	return head
}

function GetKart(player)
{
	local minidata = Ware_GetPlayerMiniData(player)
	if ("kart" in minidata)
		return minidata.kart
	return null
}

local function MakePlayerComplain(target)
{
	local type = RandomBool() ? "TLK_PLAYER_JEERS" : "TLK_PLAYER_NEGATIVE"
	EntityEntFire(target, "SpeakResponseConcept", type)
}

local function MakePlayerCheer(target)
{
	local type = RandomBool() ? "TLK_PLAYER_POSITIVE" : "TLK_PLAYER_CHEERS"
	EntityEntFire(target, "SpeakResponseConcept", type)
}

local function AddKillFeedAndVoiceCommand(victim, attacker, icon)
{
	AddKillFeedMessage(victim, attacker, icon)
	MakePlayerComplain(victim)
	MakePlayerCheer(attacker)
}

kart_routines <- 
{
	Destroy = function()
	{
		local idx = karts.find(this)
		if (idx != null)
			karts.remove(idx)
			
		if (m_engine_idle)
			m_prop.StopSound("MK_Kart_Engine_Idle")
		else
			m_prop.StopSound("MK_Kart_Engine")
					
		DriftStop()
		BoostStop()
		ClearItems()
		
		Exit()
				
		m_head.Kill()
		m_camera.Kill()
		m_prop.Kill()
		if (m_shadow)
			m_shadow.Kill()
		m_entity.Kill()
	}
	
	Enter = function(player)
	{
		m_driver = player
		m_driver_bot = player.IsFakeClient()
		Ware_GetPlayerMiniData(player).kart <- this
		
		m_team = m_driver.GetTeam()
		
		m_head.SetBodygroup(0, player.GetPlayerClass() - 1)		
		m_head.EnableDraw()
		m_head_offset.x = -0.04 + player.entindex() * -0.04
		
		UpdateSkin()
		
		player.SetAbsVelocity(vec3_zero)
		SetEntityParent(player, m_prop)
		player.SetMoveType(MOVETYPE_NONE, 0)
		SetPropInt(player, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL)
		SetPropInt(player, "m_Shared.m_nAirDucked", 3)
		SetPropInt(player, "m_iFOV", 70)
		SetPropBool(player, "pl.deadflag", true)
		player.AddFlag(FL_ATCONTROLS)
		player.AddSolidFlags(FSOLID_NOT_SOLID)
		player.AddCustomAttribute("no_attack", 1, -1)
		player.AddCustomAttribute("no_jump", 1, -1)
		player.SetForceLocalDraw(true)
		// fix spec cam origin
		player.SetCustomModelWithClassAnimations(player.GetModelName())
		player.SetCustomModelOffset(Vector(0, 0, -35))
		// "disable" suicides
		player.AddCond(TF_COND_HALLOWEEN_IN_HELL)
		player.AddCond(TF_COND_GRAPPLED_TO_PLAYER)
	}
	
	Exit = function()
	{
		local player = m_driver
		if (!player)
			return
		
		local spectator = (player.GetTeam() & TF_TEAM_MASK) == 0
		
		Ware_GetPlayerMiniData(player).kart = null
		
		TogglePlayerViewcontrol(player, m_camera, false)
		SetEntityParent(player, null)	
		
		m_driver = null
		m_driver_bot = false
		
		m_head.DisableDraw()
		SetPropEntity(m_hud, "m_hBuilder", null)
		
		local effects = GetPropInt(player, "m_fEffects")
		SetPropInt(player, "m_fEffects", effects & ~(EF_BONEMERGE|EF_BONEMERGE_FASTCULL))
		SetPropInt(player, "m_iFOV", 0)
		SetPropInt(player, "m_clrRender", 0xFFFFFFFF)
		SetPropInt(player, "m_nRenderMode", kRenderNormal)		
		player.SetForceLocalDraw(false)	
		player.RemoveHudHideFlags(HIDEHUD_MISCSTATUS)
		player.SetCustomModel("")
			
		if (player.IsAlive())
		{
			player.SetMoveType(MOVETYPE_WALK, 0)
			player.RemoveFlag(FL_ATCONTROLS)
			player.RemoveSolidFlags(FSOLID_NOT_SOLID)		
			player.RemoveCustomAttribute("no_attack")
			player.RemoveCustomAttribute("no_jump")
			SetPropBool(player, "pl.deadflag", false)
			SetPropInt(player, "m_takedamage", DAMAGE_YES)
			player.RemoveCond(TF_COND_SPEED_BOOST)
			player.RemoveCond(TF_COND_INVULNERABLE)		
			player.RemoveCond(TF_COND_HALLOWEEN_IN_HELL)
			player.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)
			player.RemoveCond(TF_COND_GRAPPLED_TO_PLAYER)
		}
	}
	
	UpdateSkin = function()
	{
		local skin = m_team
		if (m_star_timer == 0.0)
			skin -= 2		
		m_prop.SetSkin(skin)
	}

	Update = function(time, tick)
	{
		//if ((m_id % kart_skip_tick) != (tick % kart_skip_tick))
		//{
		//	m_entity.SetAbsVelocity(vec3_epsilon)
		//	return
		//}
		
		local dt = kart_skip_tick * TICKDT
			
		m_origin   = m_entity.GetOrigin()
		m_origin.z -= m_hop_height
		m_angles   = m_entity.GetAbsAngles()
		m_forward  = m_angles.Forward()
		
		UpdateBot()
		UpdateInput(time)
		UpdateCamera(time)
		UpdatePoint()
		UpdateItems(time, dt)
		UpdatePhysics(time, dt)
		UpdateHead(tick)
		//UpdateDebug()
	}
	
	UpdateBot = function()
	{
		if (!m_driver_bot)
			return
		
		m_buttons = IN_FORWARD

		local target_dir = m_map_next_plane.normal
		local cross = (m_origin - m_map_next_point).Cross(target_dir)
		local dist = cross.Length()
		local angle = fabs(acos(m_forward.Dot(target_dir)) * RAD2DEG)
			
		if (dist > m_bot_distance && angle < m_bot_angle)
		{
			if (cross.z < 0.0)
				m_buttons = m_buttons | IN_MOVERIGHT
			else
				m_buttons = m_buttons | IN_MOVELEFT
		}
		else
		{	
			if (angle > 1.0)
			{
				if (m_forward.Cross(target_dir).z < 0.0)
					m_buttons = m_buttons | IN_MOVERIGHT
				else
					m_buttons = m_buttons | IN_MOVELEFT
			}
		}
		
		if (m_cur_item_scope)
		{
			if (!(m_buttons_last & IN_ATTACK) && m_boost_type == BOOST_NONE)
				m_buttons = m_buttons | IN_ATTACK
		}
	}

	UpdateInput = function(time)
	{
		local buttons = 0
		if (m_driver && Ware_MinigameScope.race_sequence == 4)
		{
			if (m_driver_bot)
				buttons = m_buttons
			else
				buttons = GetPropInt(m_driver, "m_nButtons")
				
			if (m_cannon_end_pos || m_rescue_point || m_spin_out_timer != 0.0)
				buttons = buttons & IN_DUCK
		}
		
		local buttons_changed = (m_buttons_last ^ buttons)
		m_buttons = buttons
		m_buttons_pressed = buttons_changed & buttons
		m_buttons_released = buttons_changed & (~buttons)
		m_buttons_last = buttons
		
		m_cur_item_scope = null
		if (m_items_held_idx != ITEM_NONE)
			m_cur_item_scope = m_items_held_scope
		else if (m_item_idx > ITEM_NONE)
			m_cur_item_scope = m_item_scope
		
		if (m_cur_item_scope)
		{
			if (m_buttons_pressed & IN_ATTACK)
			{
				if ("OnPressedAttack" in m_cur_item_scope)
					m_cur_item_scope.OnPressedAttack(this)
			}
			else if (m_buttons_pressed & IN_ATTACK2)
			{
				if ("OnPressedAttack2" in m_cur_item_scope)
					m_cur_item_scope.OnPressedAttack2(this)
			}
			else if (m_buttons_released & IN_ATTACK)
			{
				if ("OnReleasedAttack" in m_cur_item_scope)
					m_cur_item_scope.OnReleasedAttack(this)
			}				
			else if (m_buttons_released & IN_ATTACK2)
			{
				if ("OnReleasedAttack2" in m_cur_item_scope)
					m_cur_item_scope.OnReleasedAttack2(this)
			}
		}	
		
		if (buttons & IN_DUCK)
		{
			SetPropInt(m_driver, "m_Shared.m_nAirDucked", 3)
			m_driver.RemoveFlag(FL_DUCKING)
		}
		
		switch (buttons & (IN_MOVELEFT|IN_MOVERIGHT))
		{
			case IN_MOVELEFT:
				m_side_move = 1.0
				break
			case IN_MOVERIGHT:
				m_side_move = -1.0
				break
			default:
				m_side_move = 0.0
		}
		
		switch (buttons & (IN_FORWARD|IN_BACK))
		{
			case IN_FORWARD:
				m_forward_move = 1.0
				break
			case IN_BACK:
				m_forward_move = -1.0
				m_side_move *= -1.0
				break
			default:
				m_forward_move = 0.0
		}	
	}

	UpdateCamera = function(time)
	{
		local camera_delta_y = (m_angles.y - m_camera_yaw) % 360.0
		if (camera_delta_y > 180.0)
			camera_delta_y -= 360.0
		else if (camera_delta_y < -180.0)
			camera_delta_y += 360.0
			
		if (m_rescued)
		{
			m_camera_yaw = m_angles.y
		}
		else
		{
			local camera_speed = fabs(camera_delta_y) * 0.04
			if (camera_delta_y > camera_speed)
				m_camera_yaw = m_camera_yaw + camera_speed
			else if (camera_delta_y < -camera_speed)
				m_camera_yaw =  m_camera_yaw - camera_speed
			else
				m_camera_yaw = m_angles.y
		}

		local s = sin((m_camera_yaw - 90.0) * DEG2RAD)
		local c = cos((m_camera_yaw - 90.0) * DEG2RAD)
		
		local camera_pitch = sin(m_angles.x * DEG2RAD) * 90.0
		m_camera_pitch = Lerp(m_camera_pitch, camera_pitch, 0.05)
		
		local horizontal_offset, vertical_offset
		
		local camera_reverse = (m_buttons & IN_DUCK) != 0
		if (camera_reverse != m_camera_reverse)
			EntityMarkTeleport(m_camera)
		m_camera_reverse = camera_reverse
		
		if (camera_reverse)
		{
			horizontal_offset = -m_camera_offset.x
			vertical_offset = m_camera_offset.z - m_camera_pitch
		}
		else
		{
			horizontal_offset = m_camera_offset.x
			vertical_offset = m_camera_offset.z + m_camera_pitch
		}
		
		local new_camera_offset = Vector
		(
			-horizontal_offset * s,
			horizontal_offset * c,
			vertical_offset
		)
		
		local camera_origin
		if (m_spin_out_type == SPINOUT_LAUNCH_UP || (!m_rescued && m_rescue_point))
			camera_origin = m_camera.GetOrigin()
		else
			camera_origin = m_origin + new_camera_offset
			
		local camera_dir = m_origin - camera_origin
		
		camera_dir.z += 28.0
		camera_dir.Norm()
	
		m_camera.SetAbsOrigin(camera_origin)
		m_camera.SetForwardVector(camera_dir)
	}

	UpdatePhysics = function(time, dt)
	{
		if (m_ground && !m_ground.IsValid())
			m_ground = null
		
		if (m_rescue_point)
		{
			PhysicsRescue(dt)
		}
		else if (m_bullet_timer != 0.0)
		{
			PhysicsBullet()
		}
		else if (m_cannon_end_pos)
		{
			PhysicsCannon()		
		}
		else
		{
			PhysicsGravity(dt)
			PhysicsGroundCollision(dt)
			PhysicsMove(time, dt)
			PhysicsWallCollision(time)		
		}
		
		local velocity_dt = m_velocity * dt
		m_origin += velocity_dt
				
		if (m_shadow)
		{
			m_shadow.SetAbsOrigin(m_origin - m_base_offset + vec3_up)
			m_shadow.SetAbsAngles(m_angles)
			m_shadow.SetDrawEnabled(m_ground != null)	
		}		
		
		m_origin.z += m_hop_height
		
		m_entity.SetAbsOrigin(m_origin)
		m_entity.SetAbsVelocity(vec3_epsilon)
		m_entity.SetLocalAngles(m_angles)
		
		m_prop.SetAbsOrigin(m_origin)
		m_prop.SetAbsAngles(m_angles)
	}
	
	PhysicsMove = function(time, dt)
	{
		local inv_dt = dt / TICKDT
		local turn_amount = 0.0
		if (m_drifting)
		{
			if (m_drift_pfx_restart > 0 && --m_drift_pfx_restart == 0)
				ToggleWheelParticles(true, false)
				
			if (m_boost_side_move < 0.0)
			{
				if (m_side_move > 0.0)
					turn_amount = m_turn_rate * (m_boost_side_move * 0.0) * dt
				else if (m_side_move < 0.0)
					turn_amount = m_turn_rate * (m_boost_side_move * 1.4) * dt
				else
					turn_amount = m_turn_rate * (m_boost_side_move * 0.7) * dt
			}
			else if (m_boost_side_move > 0.0)
			{
				if (m_side_move < 0.0)
					turn_amount = m_turn_rate * (m_boost_side_move * 0.0) * dt
				else if (m_side_move > 0.0)
					turn_amount = m_turn_rate * (m_boost_side_move * 1.4) * dt
				else
					turn_amount = m_turn_rate * (m_boost_side_move * 0.7) * dt
			}
		}
		else if (m_side_move != 0.0)
		{
			local turn_rate = m_turn_rate
			if (m_ground)
			{
				if (m_last_speed < 200.0)
					turn_rate *= RemapVal(m_last_speed, 0.0, 200.0, 1.5, 1.0)	
			}
			else
			{
				turn_rate *= 0.5
			}	
			turn_amount = turn_rate * m_side_move * dt
		}
		
		if (m_boost_type > BOOST_DRIFT || m_star_timer > 0.0)
			turn_amount *= 1.3
		
		m_angles.y += turn_amount
		
		local v_forward = m_slope_normal.Cross(m_angles.Left())
		v_forward.Norm()
		local target_ang = VectorAngles2(v_forward, m_slope_normal)
		local target_quat = target_ang.ToQuat()
		local lerp_rate = m_landed ? 0.6 : 0.12
		m_angles = QuaternionBlend(m_angles.ToQuat(), target_quat, lerp_rate).ToQAngle()
		
		local forward_move = m_forward_move
		if (m_boost_timer > 0.0)
		{
			if (m_boost_timer < time)	
				BoostStop()
			else
				forward_move = 1.0
		}
		
		local hop_duration = 0.3
		if (m_drifting)
		{
			if (!(m_buttons & IN_JUMP))
			{
				m_drifting = false
			}
			else if (m_velocity.Length() < 700.0)
			{
				m_boost_stage = 0
				m_drifting = false
			}
			
			if (m_drifting)
			{
				if (m_ground)
				{
					if (m_side_move == m_boost_side_move)
						m_boost_counter += 5 * inv_dt.tointeger()
					else
						m_boost_counter += 2 * inv_dt.tointeger()
				}
				
				local old_boost_stage = m_boost_stage
				if (m_boost_counter >= 634)
					m_boost_stage = 4
				else if (m_boost_counter >= 498)
					m_boost_stage = 3	
				else if (m_boost_counter >= 300)
					m_boost_stage = 2
				else if (m_boost_counter >= 165)
					m_boost_stage = 1
				else
					m_boost_stage = 0		

				if (old_boost_stage != m_boost_stage)
				{
					EmitSoundEx
					({
						sound_name = "MK_Kart_Drift_Sparks"
						pitch      = 50 + (m_boost_stage * 9)
						flags      = SND_CHANGE_PITCH
						entity     = m_prop
					}) 

					m_drift_pfx_index = kart_drift_pfx_index[m_boost_stage - 1]
					ToggleWheelParticles(false, false)
					m_drift_pfx_restart = 5
				}
			}
			else
			{
				if (m_boost_stage >= 4)
					Boost(2.0, BOOST_DRIFT)
				else if (m_boost_stage >= 2)
					Boost(1.0, BOOST_DRIFT)
							
				m_drifting = true
				DriftStop()			
			}
		}
		else if (m_hop_timer >= time)
		{
			m_hop_height = sin(RemapVal(m_hop_timer - time, hop_duration, 0.0, 0.0, PI)) * 10.0		
		}
		else if (m_hop_height != 0.0)
		{
			if ((m_buttons & IN_JUMP) && m_side_move != 0.0)
			{
				m_boost_side_move = m_side_move
				m_boost_counter = 0
				m_drifting = true	
				m_prop.EmitSound("MK_Kart_Drift")
			}
			m_hop_height = 0.0
		}
		
		if (m_ground)
		{			
			if (m_hop_timer < time && (m_buttons_pressed & IN_JUMP))
			{
				m_hop_timer = time + hop_duration
				m_prop.EmitSound("MK_Kart_Hop")
			}
		
			local wish_direction = m_direction * forward_move
			local acceleration = m_acceleration_rate * inv_dt
			local dot = m_forward.Dot(wish_direction)
			local max_speed
			local braking
			
			if (m_boost_timer >= time)
			{
				if (m_boost_type > BOOST_DRIFT)
				{
					max_speed = m_speed_cap * 1.5
					acceleration *= 5.0
				}
				else if (m_boost_type == BOOST_DRIFT)
				{
					max_speed = m_speed_cap * 1.2
					acceleration *= 2.0
				}
				
				if (dot < 0.0)	
				{
					wish_direction *= -1.0
					dot *= -1.0
				}
			}
			else
			{
				if (dot >= 0.0)
				{
					max_speed = m_speed_cap
				}
				else
				{
					if (m_velocity.Dot(wish_direction) < 0.0)
					{
						max_speed = m_speed_cap
						braking = true
					}
					else
					{
						max_speed = m_back_speed_cap
					}
				}
			}
			
			if (m_shrink_timer > 0.0)
			{
				max_speed *= 0.75
			}
			if (m_star_timer > 0.0)
			{
				max_speed *= 1.3
				acceleration *= 2.0		
			}
			if (m_mega_timer > 0.0)
			{
				max_speed *= 1.15
			}
			
			m_velocity += wish_direction * acceleration
			
			if (m_slope_normal.z < 0.707) 
			{
				local slide_force = m_slope_normal * (800.0 * dt)
				m_velocity += slide_force
			}
			
			local friction = m_velocity * -1.0
			friction.Norm()
			friction *= m_friction_rate * dt		
			
			local speed = m_velocity.Length2D()	
			local friction_speed = friction.Length2D()
			if (friction_speed < speed)
			{
				m_velocity += friction
				speed -= friction_speed
			}
			else
			{
				m_velocity *= 0.0
				speed = 0.0
			}
			
			if (speed > 1.0)
			{				
				if (speed > max_speed) 
				{
					local crop = max_speed / speed
					speed *= crop
					m_velocity *=  crop
				}
				
				if (m_tire_timer < time)
				{
					local tire_speed
					local dot = m_forward.Dot(m_velocity)
					if (dot >= 0.0)
					{
						tire_speed = speed
						if (tire_speed > 1190.0)
							tire_speed = 1190.0
					}
					else
					{
						tire_speed = speed * -1.0
						if (tire_speed < -190.0)
							tire_speed = -190.0
					}
							
					// -190, 1190, -31, 32
					tire_speed = -31 + 63 * (tire_speed.tointeger() + 190) / 1380
					m_prop.SetTeam(tire_speed)
					m_tire_timer = time + 0.2	
					
					if (m_engine_noises)
					{
						if (m_engine_idle)
						{
							m_engine_idle = false
							m_engine_pitch = 0
							m_prop.StopSound("MK_Kart_Engine_Idle")
						}
						
						local pitch = Min(70 + (abs(speed) * 50 / 1000), 140)
						if (pitch != m_engine_pitch)
						{
							m_engine_pitch = pitch
							EmitSoundEx
							({
								sound_name = "MK_Kart_Engine"
								pitch      = pitch
								flags      = SND_CHANGE_PITCH
								entity     = m_prop
							})
						}
					}
				}
			}
			else
			{				
				if (m_engine_noises && !m_engine_idle
					&& Ware_MinigameScope.race_sequence >= 3)
				{
					m_engine_idle = true
					m_prop.StopSound("MK_Kart_Engine")			
					m_prop.EmitSound("MK_Kart_Engine_Idle")
				}
				
				m_prop.SetTeam(-23)
			}
			
			m_last_speed = speed
			
			if (m_side_move != 0.0)
				m_velocity = RotatePosition(vec3_zero, QAngle(0, turn_amount, 0), m_velocity)
		}
		else
		{
			m_velocity = RotatePosition(vec3_zero, QAngle(0, turn_amount, 0), m_velocity)
		}
		
		m_landed = false
	}
	
	PhysicsGravity = function(dt)
	{
		local gravity = gravity_rate * m_gravity_factor * dt
		if (m_velocity.z > -1000.0)
			m_velocity.z -= gravity
	}
	
	PhysicsGroundCollision = function(dt)
	{
		local down = m_ground ? -20.0 : -0.1
		local tr =
		{
			start  = m_origin
			end    = m_origin 
					- m_base_offset
					+ Vector(0, 0, down + m_velocity.z * dt)
			mask   = MASK_PLAYERSOLID_BRUSHONLY
			ignore = self
		}
		TraceLineEx(tr)
		
		if (tr.hit && tr.plane_normal.z > 0.1)
		{
			if (tr.surface_flags & SURF_SKY)
			{
				RescueInit()
				return
			}
			else if (tr.surface_props == 28) // boost panel
			{
				Boost(2.0, BOOST_SURFACE)
			}
			
			m_gravity_factor = 1.0
			
			m_origin = tr.endpos + m_base_offset
			m_entity.SetAbsOrigin(m_origin)
			
			if (!m_ground)
			{
				if (m_velocity.z < -400.0)
					m_prop.EmitSound("MK_Kart_Land")
				m_landed = true
			}
			
			if (m_rescue_land_buffer > 0)
			{
				--m_rescue_land_buffer
				if (m_buttons_pressed & IN_FORWARD)
				{
					Boost(1.0, BOOST_DRIFT)
					m_rescue_land_buffer = 0
				}
				else if (m_buttons & IN_FORWARD)
				{
					m_rescue_land_buffer = 0
				}
			}	
			
			m_ground = tr.enthit
			if (tr.plane_normal.z > 0.1)
				m_slope_normal = tr.plane_normal
			
			m_direction = m_slope_normal.Cross(m_forward)
			m_direction = m_slope_normal.Cross(m_direction) * -1.0		

			m_velocity.z = 0.0
		}
		else
		{
			m_ground = null
			
			m_direction = m_velocity * 1.0
			m_direction.Norm()
		}
	}
	
	PhysicsWallCollision = function(time)
	{
		if (m_spin_out_type == SPINOUT_LAUNCH_UP)
			return
		
		local dir = m_velocity * 1.0
		dir.Norm()
		dir.z = m_forward.z
		dir.Norm()
		
		local tr = 
		{
			start  = m_origin,
			end    = m_origin + dir * 42.0
			mask   = MASK_PLAYERSOLID_BRUSHONLY
			ignore = self
		}
		TraceLineEx(tr)
		
		if (tr.hit)
		{
			local normal = tr.plane_normal
			local dot = dir.Dot(normal)
			local speed = m_velocity.Length()			
			if (dot < -0.4)
			{				
				local reflection = dir - (normal * (dot * 2.0))
				reflection.Norm()
				m_velocity = reflection * (speed * 0.5)
				
				if (m_impact_timer < time && speed > 200.0)
				{
					m_prop.EmitSound("MK_Kart_Collide_Concrete")
					DispatchParticleEffect("kart_impact_sparks", (tr.pos + dir * -32.0) - Vector(0, 0, 32), vec3_zero)
					m_impact_timer = time + 0.5
					
					if (speed > 300.0)
					{
						m_velocity.z += 150.0
						m_ground = null
					}						
				}
			}
			else
			{
				local reflection = dir - (normal * dot)
				reflection.Norm()
				m_velocity = reflection * speed
			}	
		}
	}
	
	PhysicsCannon = function()
	{
		m_direction = m_cannon_end_pos - m_origin
		m_direction.Norm()

		local target_quat = VectorAngles(m_direction).ToQuat()
		m_angles = QuaternionBlend(m_angles.ToQuat(), target_quat, 0.1).ToQAngle()
		
		m_velocity = m_direction * 4500.0
	}
	
	StartCannon = function()
	{
		EntityEntFire(m_driver, "SpeakResponseConcept", "halloweenlongfall", RandomFloat(0.0, 0.5))
		EmitSoundOnClient("MK_Cannon", m_driver)
		m_cannon_end_pos = Ware_MinigameLocation.cannon_end_pos
		m_ground = null
	}
	
	StopCannon = function()
	{
		m_cannon_end_pos = null
		m_touch_timer = Time() + 2.0
		m_velocity *= 0.2
	}
	
	Boost = function(duration, type)
	{
		if (type == BOOST_DRIFT)
		{
			if (m_boost_type > BOOST_DRIFT)
				return
			EmitSoundOnClient("MK_Kart_Drift_Boost", m_driver)
		}
		else if (type == BOOST_SURFACE)
		{
			if (m_blooper_timer > 0.0) m_blooper_timer = 0.01 // reset
			if (m_boost_timer == 0.0)
			{
				EmitSoundOnClient("MK_Boost", m_driver)
			}
		}
		else if (type == BOOST_SHROOM)
		{
			if (m_blooper_timer > 0.0) m_blooper_timer = 0.01 // reset
			m_prop.EmitSound("MK_Item_Shroom_Use")
		}
		
		m_boost_type = type
		m_boost_timer = Time() + duration
		if (m_driver)
		{
			m_driver.AddCond(TF_COND_SPEED_BOOST)
			if (type != BOOST_SURFACE)
				MakePlayerCheer(m_driver)	
		}
	}
	
	BoostStop = function()
	{
		if (m_boost_timer == 0.0)
			return
	
		if (m_driver)
			m_driver.RemoveCond(TF_COND_SPEED_BOOST)
		m_boost_timer = 0.0
		m_boost_type = BOOST_NONE
	}
	
	DriftStop = function()
	{
		if (!m_drifting)
			return
			
		m_drifting = false
		m_boost_stage = 0
		m_prop.StopSound("MK_Kart_Drift")
		
		ToggleWheelParticles(false, true)
	}
	
	RescueInit = function()
	{
		if (m_rescue_point != null)
			return
		
		DriftStop()
		BoostStop()
		DropHeldItem()	
		
		m_head.AcceptInput("SetAnimation", "spin", null, null)
		
		m_rescued = false
		m_rescue_point = m_map_next_point + Vector(0, 0, 64)
		m_rescue_plane = m_map_next_plane

		EntityEntFire(m_entity, "CallScriptFunction", "RescueStart", 1.0)
		
		MakePlayerComplain(m_driver)
	}
	
	RescueStart = function()
	{
		HudPlayAnimation("respawn_start")
		EntityEntFire(m_entity, "CallScriptFunction", "Rescue", 2.0)
	}
	
	Rescue = function()
	{
		m_rescued = true
		m_gravity_factor = 1.0
		
		m_origin = m_rescue_point * 1.0	
		m_angles = VectorAngles(m_rescue_plane.normal)		
		m_entity.SetAbsOrigin(m_origin)
		m_entity.SetAbsAngles(m_angles)
		
		m_head.AcceptInput("SetAnimation", "idle", null, null)

		m_prop.EmitSound("MK_Lakitu_Pickup")
		m_prop.SetTeam(-23)
		
		ClearItems()
		
		HudPlayAnimation("respawn_end")
		EntityEntFire(m_entity, "CallScriptFunction", "RescueDrop", 2.0)
	}	
	
	RescueDrop = function()
	{
		m_rescued = false
		m_rescue_point = null
		m_rescue_plane = null
		m_rescue_land_buffer = 15
	}
	
	PhysicsRescue = function(dt)
	{
		if (m_rescued)
		{
			m_ground = null
			m_slope_normal = Vector(0, 0, 1)
			m_velocity *= 0.0
		}
		else
		{
			PhysicsGravity(dt)
		}
	}
	
	CanSpinout = function()
	{
		return m_star_timer == 0.0 && 
				m_bullet_timer == 0.0 &&
				m_mega_timer == 0.0 &&
				m_cannon_end_pos == null
	}
	
	Spinout = function(type)
	{
		if (m_spin_out_type != SPINOUT_NONE && type <= m_spin_out_type)
			return false
		
		DriftStop()
		BoostStop()
		
		if (m_spin_out_type == SPINOUT_NONE)
			m_head.AcceptInput("SetAnimation", "spin", null, null)
		
		local drop_item = false		
		switch (type)
		{
			case SPINOUT_SPIN:
			{
				m_prop.EmitSound("MK_Kart_Spin")
				m_prop.AcceptInput("SetAnimation", "spinout", null, null)
				m_spin_out_timer = Time() + 1.0
				break
			}
			case SPINOUT_SPIN_DOUBLE:
			{
				m_prop.EmitSound("MK_Kart_Spin")
				m_prop.AcceptInput("SetAnimation", "spinout_double", null, null)
				m_spin_out_timer = Time() + 2.0	
				break
			}		
			case SPINOUT_TUMBLE_FORWARD:
			{
				m_prop.AcceptInput("SetAnimation", "tumble_forward", null, null)
				m_spin_out_timer = Time() + 1.2	
				m_velocity *= 0.4
				m_ground = null
				break
			}
			case SPINOUT_TUMBLE_LEFT:
			{
				m_prop.EmitSound("MK_Item_Star_Hit")
				m_prop.AcceptInput("SetAnimation", "tumble_right", null, null)			
				m_spin_out_timer = Time() + 1.2
				m_velocity = m_entity.GetAbsAngles().Left() * -1.0
				m_velocity.z += 2.5
				m_velocity.Norm()
				m_velocity *= 400.0
				m_ground = null
				drop_item = true
				break
			}
			case SPINOUT_TUMBLE_RIGHT:
			{
				m_prop.EmitSound("MK_Item_Star_Hit")
				m_prop.AcceptInput("SetAnimation", "tumble_left", null, null)
				m_spin_out_timer = Time() + 1.2
				m_velocity = m_entity.GetAbsAngles().Left()
				m_velocity.z += 2.5
				m_velocity.Norm()
				m_velocity *= 400.0
				m_ground = null
				drop_item = true
				break			
			}
			case SPINOUT_LAUNCH_UP:
			{
				m_prop.AcceptInput("SetAnimation", "tumble_high", null, null)
				m_spin_out_timer = Time() + 2.5
				m_velocity = Vector(0, 0, 800)
				m_ground = null
				drop_item = true
				break
			}		
			case SPINOUT_ENGINE_FAIL:
			{	
				m_prop.EmitSound("MK_Kart_Burnout")
				DispatchParticleEffect("enginefail", 
					m_origin + m_angles.Forward() * -60.0 + m_angles.Up() * 12.0, 
					vec3_up)
				m_prop.AcceptInput("SetAnimation", "burnout", null, null)
				m_spin_out_timer = Time() + 2.5
				m_velocity *= 0.0
				break
			}
		}
		
		if (drop_item)
			DropItems()
		
		m_spin_out_type = type
		return true
	}
	
	ToggleWheelParticles = function(active, kill)
	{
		local pfx = m_drift_pfx
		
		if (active && !pfx)
		{
			pfx = SpawnEntityFromTableSafe("info_particle_system",
			{
				effect_name = "error"
				origin       = m_origin - (m_angles.Forward() * 36.0) - (m_angles.Left() * 1) - (m_angles.Up() * 24.0)
				angles       = m_angles
				start_active = true
			})
			SetEntityParent(pfx, m_prop)
		}
		
		if (pfx)
		{
			SetPropInt(pfx, "m_iEffectIndex", m_drift_pfx_index)
			SetPropBool(pfx, "m_bActive", active)		
			pfx.SetDrawEnabled(active)
		}

		if (kill && pfx)
		{
			EntityEntFire(pfx, "Kill", "", 0.5)
			pfx = null
		}
		
		m_drift_pfx = pfx
	}	
	
	Shrink = function(timer)
	{
		if (m_mega_timer > 0.0)
		{
			StopMega()
			return true
		}
		
		local not_shrinked = m_shrink_timer == 0.0
		if (not_shrinked)
			m_prop.EmitSound("MK_Kart_Shrink")
		m_prop.SetModelScale(0.5, 1.0)
		if (m_shadow)
			m_shadow.SetModelScale(0.5, 1.0)
		Spinout(SPINOUT_SPIN)
		m_shrink_timer = timer
		
		return not_shrinked
	}
	
	Grow = function()
	{
		m_prop.EmitSound("MK_Kart_Grow")
		m_prop.SetModelScale(1.0, 1.0)
		if (m_shadow)
			m_shadow.SetModelScale(1.0, 1.0)
		m_shrink_timer = 0.0
	}
	
	Squish = function(duration)
	{
		local not_squished = m_shrink_timer == 0.0
		local time = Time()
		
		if (not_squished)
			m_prop.EmitSound("MK_Kart_Shrink")
		m_prop.SetModelScale(0.5, 0.3)
		if (m_shadow)
			m_shadow.SetModelScale(0.5, 0.3)
		m_spin_out_timer = time + 0.5
		m_velocity *= 0.5
		m_shrink_timer = time + duration
		
		return not_squished
	}
	
	HudPlayAnimation = function(name)
	{
		m_hud.ResetSequence(m_hud.LookupSequence(name))
		AddThinkToEnt(m_hud, "ThinkAdvanceAnimUntilEnd")
	}
	
	HudStartShock = function()
	{
		m_hud.SetBodygroup(1, 1)
	}
	
	HudResetShock = function()
	{
		m_hud.SetBodygroup(1, 0)
	}
	
	HudUpdateLap = function()
	{
		SetPropInt(m_hud, "m_clrRender", (Max(m_lap_idx + 1, 1) << 24) | 0x00FFFFFF)
	}
	
	HudUpdatePosition = function()
	{
		SetPropInt(m_hud, "m_iTextureFrameIndex", m_position_idx)
	}
	
	HudUpdateItem = function(idx)
	{
		SetPropInt(m_hud, "m_iTeamNum", idx + 2)
	}
	
	UpdateHead = function(tick)
	{
		if ((m_id & 1) == (tick & 1))
		{
			local delta = (m_origin - map_data.center) * 0.00161
			delta.z = -delta.x
			delta.x = 0.0
			delta.y *= -1.0
			m_head.SetAbsOrigin(delta + map_data.head_center + m_head_offset)		
		}
	}
	
	Touch_mk_itembox     = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_banana      = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_fib         = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_bomb        = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_star        = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_shroom      = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_shroom_mega = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_shroom_gold = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_shell_green = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_shell_red   = function(entity) { entity.GetScriptScope().Touch(this) }	
	Touch_mk_kart_proxy  = function(entity) 
	{
		if (activator == m_proxy)
			return
		if (m_cannon_end_pos || m_rescued)
			return
		
		local other = activator.GetOwner().GetScriptScope()
		local time = Time()
		if (!kart_touch_swap)
		{
			if (m_touch_timer > time)
				return
				
			m_touch_timer = time + 0.5
			other.m_touch_timer = time + 0.5
				
			if (other.m_bullet_timer == 0.0
				&& other.m_mega_timer == 0.0
				&& other.m_star_timer == 0.0)
			{
				local speed = m_velocity.Length()
				local target_speed = other.m_velocity.Length()
				if (speed > target_speed)
				{	
					if (speed >= 100.0)
					{
						kart_touch_swap = this
						other.Touch_mk_kart_proxy(m_proxy)
					}
					return
				}
				else
				{
					if (target_speed < 100.0)
						return
				}				
			}
		}
		else
		{
			other = kart_touch_swap
			kart_touch_swap = null
		}
		
		if (team_battle && other.m_team == m_team)
			return
		
		local target_origin = other.m_origin
		local target_direction = other.m_forward
		local right = (target_origin - m_origin).Cross(target_direction).z <= 0.0
		
		if (other.m_bullet_timer > 0.0)
		{
			if (m_star_timer == 0.0 
				&& Spinout(right ? SPINOUT_TUMBLE_RIGHT : SPINOUT_TUMBLE_LEFT))
			{
				AddKillFeedAndVoiceCommand(m_driver, other.m_driver, "vehicle")
			}
		}
		else if (other.m_mega_timer > 0.0)
		{
			if (m_star_timer == 0.0 && m_mega_timer == 0.0 && Squish(5.0))
			{
				AddKillFeedAndVoiceCommand(m_driver, other.m_driver, "rocketpack_stomp")
			}
		}
		else if (other.m_star_timer > 0.0)
		{
			if (m_bullet_timer == 0.0
				&& m_star_timer == 0.0
				&& Spinout(right ? SPINOUT_TUMBLE_RIGHT : SPINOUT_TUMBLE_LEFT))
			{
				AddKillFeedAndVoiceCommand(m_driver, other.m_driver, "wrench_golden")
			}
		}
		// collision penalties disabled for more than 12 players
		else if (karts.len() <= 12 && other.m_velocity.Length() > 100.0)
		{
			m_prop.EmitSound("MK_Kart_Collide_Vehicle")
			m_prop.EmitSound(SFX_WARE_KART_HORN)

			local target_speed = other.m_velocity.Length()
			local add_velocity = m_angles.Left()
			if (target_speed < 200.0)
				target_speed = 100.0
			else if (target_speed >= 1400.0)
				target_speed = 350.0
			else if (target_speed > 350.0)
				target_speed = 200.0
			add_velocity *= right ? -target_speed : target_speed
			
			m_velocity *= 0.5
			m_velocity += add_velocity
		}
	}
	Touch_pinball_bound = function(entity)
	{
		local normal = m_origin - entity.GetOrigin()
		normal.z = 0.0
		normal.Norm()
		
		local dir = m_velocity * 1.0
		dir.Norm()
		
		local dot = dir.Dot(normal)
		local speed = Max(300.0, m_velocity.Length())				
		local reflection = dir - (normal * (dot * 2.0))
		reflection.Norm()
		m_velocity = reflection * (speed * 2.0)
		
		m_entity.EmitSound("MK_Bound_Hit")		
		EmitSoundOnClient("MK_Bound_Hit", m_driver)
		
		Spinout(SPINOUT_SPIN)			
	}
	Touch_pinball_flipper = function(entity)
	{
		Spinout(SPINOUT_SPIN)
	}
	
	Touch = function()
	{
		if (activator)
		{
			local name = activator.GetClassname()
			local func_name = "Touch_" + name
			if (func_name in this)
				this[func_name](activator)	
		}
	}
	
	PickItem = function(position)
	{
		local id = ITEM_NONE	
		local r = RandomFloat(0.0, 100.0)
		local accum = 0.0
		local item_table = Ware_MinigameScope.item_probability
		local item_table_count = item_table.len()
		local player_count = karts.len()
		local position_count = 12
		
		// TODO HACK position is rarely higher than player count? WTF?
		if (position >= player_count)
			position = player_count - 1
		
		if (player_count > position_count)
		{
			local position_scale = position * position_count.tofloat() / player_count.tofloat()
			
			local position1 = position_scale.tointeger()
			local position2 = position1 + 1
			if (position2 >= position_count)
			{
				position_scale = position_count.tofloat()
				position2 = position_count - 1
			}
			
			local t = position_scale - position1.tofloat()
			local t_inv = (1.0 - t)
			for (local i = 0; i < item_table_count; i++) 
			{
				local chance = (t_inv * item_table[i][position1]) + (t * item_table[i][position2])
				accum += chance
				if (r <= accum)
				{
					id = Ware_MinigameScope.item_table_to_id[i]
					break
				}
			}		
		}
		else
		{
			for (local i = 0; i < item_table_count; i++) 
			{
				local chance = item_table[i][position]
				accum += chance
				if (r <= accum)
				{
					id = Ware_MinigameScope.item_table_to_id[i]
					break
				}
			}
		}
		
		// pows are disabled for this version
		if (id == ITEM_POW)
		{
			id = ITEM_SHROOM_TWO	
		}
		// this is not the right way of doing this but solving it properly is x10 more code
		else if (id == ITEM_SHOCK)
		{
			local reroll = Ware_MinigameScope.item_shock_timer >= Time()
			if (!reroll && karts.len() > 24)
				reroll = RandomInt(1, 3) > 1
			if (reroll)
				id = ITEM_STAR
			else
				Ware_MinigameScope.item_shock_timer = Time() + 30.0
		}
		else if (id == ITEM_BLOOPER)
		{
			local reroll = Ware_MinigameScope.item_blooper_timer >= Time()
			if (!reroll && karts.len() > 24)
				reroll = RandomInt(1, 3) > 1
			if (reroll)
				id = ITEM_SHROOM_ONE
			else
				Ware_MinigameScope.item_blooper_timer = Time() + 30.0
		}
		
		return id
	}
	
	RollItem = function()
	{
		if (m_item_idx != ITEM_NONE)
			return
		
		local idx = PickItem(m_position_idx)

		m_item_idx = -idx
		HudUpdateItem(ITEM_LAST + 1)
			
		EmitSoundOnClient("MK_Item_Roulette", m_driver)
		EntityEntFire(m_entity, "CallScriptFunction", "SelectItem", 4.0)
	}
	
	SelectItem = function()
	{
		if (m_item_idx >= ITEM_NONE)
			return
				
		local idx = -m_item_idx
		SetItem(idx)
	}
	
	SetItem = function(idx)
	{
		if (idx == ITEM_NONE)
		{
			if (m_item_idx < 0 && m_driver)
				m_driver.StopSound("MK_Item_Roulette")
		}
		
		m_item_idx = idx
		m_item_scope = item_map[idx]
		HudUpdateItem(idx)
	}
	
	SetHeldItems = function(idx, entities)
	{
		if (entities)
			m_items_held = entities
		else
			m_items_held.clear()
		m_items_held_idx = idx
		m_items_held_scope = item_map[idx]
	}
	
	DropHeldItem = function()
	{
		if (m_items_held_idx != ITEM_NONE)
		{
			m_items_held_scope.OnDrop(m_items_held, this)
			SetHeldItems(ITEM_NONE, null)
		}			
	}
	
	RemoveHeldItem = function(entity)
	{
		local idx = m_items_held.find(entity)
		if (idx != null)
		{
			m_items_held.remove(idx)
			if (m_items_held.len() == 0)
			{
				m_items_held_idx   = ITEM_NONE
				m_items_held_scope = null
			}
		}
	}
	
	DropItems = function()
	{
		DropHeldItem()
		
		if (m_item_idx != ITEM_NONE)
		{
			if (m_item_idx > ITEM_NONE)
			{
				if ("OnDrop" in m_item_scope)
					m_item_scope.OnDrop(null, this)	
			}
			SetItem(ITEM_NONE)			
		}
	}
	
	ClearItems = function()
	{
		DropHeldItem()
		
		if (m_star_timer > 0.0) m_star_timer = 0.01
		if (m_mega_timer > 0.0) m_mega_timer = 0.01
		if (m_shrink_timer > 0.0) m_shrink_timer = 0.01
		if (m_bullet_timer > 0.0) m_bullet_timer = 0.01
		if (m_blooper_timer > 0.0) m_blooper_timer = 0.01
		if (m_shroom_gold_timer > 0.0) m_shroom_gold_timer = 0.01
		UpdateItems(Time(), 0.0)

		SetItem(ITEM_NONE)
	}
		
	StartStar = function()
	{
		if (m_star_timer == 0.0)
		{
			if (m_driver)
				m_driver.AddCond(TF_COND_INVULNERABLE)		
			QuietMusic()
			EmitSoundEx
			({
				sound_name  = "MK_Item_Star_Music"
				entity      = m_prop
				filter_type = RECIPIENT_FILTER_GLOBAL
			})
		}
		m_star_timer = Time() + 6.5	
		UpdateSkin()
	}
	
	StopStar = function()
	{
		RestoreMusic()
		m_prop.StopSound("MK_Item_Star_Music")
		if (m_driver)
			m_driver.RemoveCond(TF_COND_INVULNERABLE)
		m_prop.EmitSound("TFPlayer.InvulnerableOff")
		m_star_timer = 0.0	
		UpdateSkin()		
	}
	
	StartMega = function()
	{
		if (m_mega_timer == 0.0)
		{
			m_prop.EmitSound("MK_Item_Shroom_Mega_Use")
			EntityEntFire(m_entity, "CallScriptFunction", "StartMegaMusic", 0.9)
			m_prop.SetModelScale(1.5, 1.0)	
			if (m_driver)			
				Ware_AddPlayerAttribute(m_driver, "voice pitch scale", 0.8, -1)			
		}
		m_mega_timer = Time() + 10.0		
	}
	
	StartMegaMusic = function()
	{
		if (m_mega_timer == 0.0)
			return
		
		QuietMusic()
		EmitSoundEx
		({
			sound_name  = "MK_Item_Shroom_Mega_Music"
			entity      = m_prop
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
	}
	
	StopMega = function()
	{
		m_mega_timer = 0.0
		
		RestoreMusic()
		m_prop.StopSound("MK_Item_Shroom_Mega_Music")
		m_prop.EmitSound("MK_Item_Shroom_Mega_Finish")
		m_prop.SetModelScale(1.0, 1.0)
		
		if (m_driver)
			Ware_RemovePlayerAttribute(m_driver, "voice pitch scale")
	}

	ShowBlooper = function()
	{
		local blooper = CreateEntitySafe("obj_teleporter")
		blooper.SetAbsOrigin(m_origin)
		blooper.SetAbsAngles(m_angles)
		blooper.SetModel("models/mariokart/items/blooper.mdl")
		blooper.SetSolid(SOLID_NONE)
		SetPropBool(blooper, "m_bPlacing", true)
		SetPropInt(blooper, "m_fObjectFlags", 2)
		SetPropInt(blooper, "m_fEffects", EF_NOSHADOW)
		SetPropEntity(blooper, "m_hBuilder", m_driver)
		SetEntityParent(blooper, m_prop)
		blooper.SetLocalOrigin(Vector(0, 0, 52))
		EntityEntFire(blooper, "Kill", "", 2.0)
		return blooper
	}
	
	StartBlooper = function()
	{
		if (m_blooper_timer == 0.0)
		{
			SetPropInt(m_driver, "m_clrRender", 0xFF323232)
			m_hud.SetBodygroup(2, 1)
		}
		m_blooper_timer = Time() + 8.0		
	}
	
	StopBlooper = function()
	{
		SetPropInt(m_driver, "m_clrRender", 0xFFFFFFFF)
		m_hud.SetBodygroup(2, 0)
		m_blooper_timer = 0.0
	}
	
	StartBullet = function()
	{
		if (m_bullet_timer != 0.0)
			return
		
		DriftStop()
		BoostStop()
		
		if (m_driver)
		{
			SetPropInt(m_driver, "m_nRenderMode", kRenderNone)
			m_driver.SetForceLocalDraw(false)
		}
		
		m_prop.EmitSound("MK_Item_Bullet_On")
		EmitSoundEx
		({
			sound_name  = "MK_Item_Bullet_Fly"
			entity      = m_prop
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
		m_prop.SetModel("models/mariokart/items/bullet.mdl")
		m_bullet_timer = Time() + 6.0
		m_ground = null	
	}
	
	PhysicsBullet = function()
	{
		// epsilon to prevent being stuck
		local next_point = m_map_next_point + m_map_next_plane.normal * 40.0
		local dir = (next_point + Vector(0, 0, 40)) - m_origin
		dir.Norm()
		
		local speed = m_cannon_end_pos ? 4500.0 : 2000.0
		m_direction = dir
		m_velocity = dir * speed
		m_angles = QuaternionBlend(m_angles.ToQuat(), VectorAngles(dir).ToQuat(), 0.15).ToQAngle()
	}
	
	StopBullet = function()
	{
		if (m_driver)
		{
			SetPropInt(m_driver, "m_nRenderMode", kRenderNormal)
			m_driver.SetForceLocalDraw(true)
		}
		m_prop.SetModel(m_model)
		m_prop.StopSound("MK_Item_Bullet_Fly")
		m_prop.EmitSound("MK_Item_Bullet_Off")
		m_bullet_timer = 0.0
		
		SetItem(ITEM_NONE)
	}
	
	UpdateItems = function(time, dt)
	{
		if (m_star_timer > 0.0 && m_star_timer < time)
			StopStar()
		
		if (m_bullet_timer > 0.0)
		{
			if (m_cannon_end_pos)
				m_bullet_timer += dt
			if (m_bullet_timer < time)
				StopBullet()
		}
		
		if (m_blooper_timer > 0.0 && m_blooper_timer < time)
			StopBlooper()	
			
		if (m_shroom_gold_timer > 0.0 && m_shroom_gold_timer < time)
		{
			SetItem(ITEM_NONE)
			m_shroom_gold_timer = 0.0	
		}
		
		if (m_mega_timer > 0.0 && m_mega_timer < time)
			StopMega()
		
		if (m_shrink_timer > 0.0 && m_shrink_timer < time)
			Grow()	
			
		if (m_spin_out_timer > 0.0 && m_spin_out_timer < time)
		{
			m_spin_out_timer = 0.0
			m_spin_out_type = SPINOUT_NONE
			m_head.AcceptInput("SetAnimation", "idle", null, null)
		}
	}
	
	SetupPoint = function()
	{
		local start_index = map_data.point_start_indices[map_data.checkpoint_last]
		local end_index = map_data.point_end_indices[map_data.checkpoint_last]		
		
		local pos = m_entity.GetOrigin()
		local closest_dist = FLT_MAX	
		for (local i = start_index; i < end_index; i++)
		{
			local point = map_data.points[i]
			local dist = (point - pos).Length()
			if (dist < closest_dist)
			{
				local plane = map_data.planes[i]
				//if (pos.Dot(plane.normal) <= plane.dist) // behind
				{
					m_map_point = point
					m_map_plane = plane
					m_map_point_idx = i
					closest_dist = dist
				}
			}
		}
		
		m_map_next_point_idx = (m_map_point_idx + 1) % map_data.point_count
		m_map_next_point = map_data.points[m_map_next_point_idx]
		m_map_next_plane = map_data.planes[m_map_next_point_idx]
	}
	
	UpdatePoint = function()
	{
		local advance
		if (m_origin.Dot(m_map_next_plane.normal) >= m_map_next_plane.dist)
		{
			advance = true		
			m_map_point_idx = m_map_point_idx + 1
			if (m_map_point_idx >= map_data.point_count)
			{
				AddLap()
				m_map_point_idx = 0
			}
		}
		else if (m_origin.Dot(m_map_plane.normal) < m_map_plane.dist)
		{
			advance = true		
			m_map_point_idx = m_map_point_idx - 1
			if (m_map_point_idx < 0)
			{
				RemoveLap()
				m_map_point_idx = map_data.point_count - 1
			}
		}
		
		if (advance)
		{
			m_map_point = map_data.points[m_map_point_idx]
			m_map_plane = map_data.planes[m_map_point_idx]
			
			m_map_next_point_idx = (m_map_point_idx + 1) % map_data.point_count
			m_map_next_point = map_data.points[m_map_next_point_idx]
			m_map_next_plane = map_data.planes[m_map_next_point_idx]		
		}
	}
	
	AddLap = function()
	{
		m_lap_idx++
		
		if (m_lap_valid_idx != INT_MIN)
		{
			if (m_lap_idx == m_lap_valid_idx)
				m_lap_valid_idx = INT_MIN
			return
		}
		if (m_lap_idx <= 0)
			return
			
		local time = Time()
		if (m_lap_last_time == 0.0)
		{
			m_lap_times.append(time - Ware_MinigameScope.race_start_time)
			m_lap_last_time = time
		}
		else
		{
			m_lap_times.append(time - m_lap_last_time)
			m_lap_last_time = time
		}
		
		local lap_last = Ware_MinigameScope.race_max_laps
		if (m_lap_idx == lap_last)
		{
			if (karts_finished.find(this) == null)
				karts_finished.append(this)
		}
		else 
		{
			if (m_driver)
			{
				QuietMusic()
				EmitSoundOnClient("MK_Lap", m_driver)	
				EntityEntFire(m_entity, "CallScriptFunction", "RestoreMusic", 2.5)				
			}
			HudUpdateLap()
		}
	}

	RemoveLap = function()
	{
		if (m_lap_valid_idx == INT_MIN)
			m_lap_valid_idx = m_lap_idx
		m_lap_idx--
	}

	SetCheckpoint = function()
	{
		local idx = GetPropInt(caller, "m_iTextureFrameIndex")
		if (m_checkpoint_idx == idx)
			return	
		if (idx == 1)
			m_pinball_score = false
		m_checkpoint_idx = idx
	}
	
	SetPosition = function(position, shift, time)
	{	
		m_position_relative = position
		
		local idx = position + shift
		if (idx == m_position_idx)
			return
		
		if (m_position_timer < time)
		{
			if (idx > m_position_idx)
				EmitSoundOnClient("MK_Position_Loss", m_driver)
			else if (idx < m_position_idx)
				EmitSoundOnClient("MK_Position_Gain", m_driver)
			m_position_timer = time + 0.5
		}
	
		m_position_idx = idx
		HudUpdatePosition()
	}	
	
	Finish = function()
	{
		if (m_driver)
		{
			EmitSoundEx
			({
				sound_name  = "MK_Music_Pinball"
				entity      = m_driver
				flags       = SND_STOP
				filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
			})
			
			EmitSoundOnClient("MK_Race_Finish", m_driver)	
		}
	}
	
	QuietMusic = function()
	{
		if (m_driver)
		{
			EmitSoundEx
			({
				sound_name  = "MK_Music_Pinball"
				entity      = m_driver
				volume      = 0.2
				flags       = SND_CHANGE_VOL
				filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
			})
		}
	}

	RestoreMusic = function()
	{
		if (m_driver)
		{
			local params =
			{
				sound_name  = "MK_Music_Pinball"
				volume      = 1.0
				entity      = m_driver
				flags       = SND_CHANGE_VOL
				filter_type = RECIPIENT_FILTER_SINGLE_PLAYER			
			}
			
			if (m_lap_idx >= Ware_MinigameScope.race_max_laps - 1)
			{
				params.pitch <- 110
				params.flags <- SND_CHANGE_VOL|SND_CHANGE_PITCH
			}
		
			EmitSoundEx(params)
		}
	}
	
	PinballScore = function()
	{
		if (m_pinball_score)
			return
		m_pinball_score = true
		EmitSoundOnClient("MK_Pinball_Score", m_driver)
	}
	
	UpdateDebug = function()
	{
		if (Ware_ListenHost.IsAlive())
		{
			if (m_driver != Ware_ListenHost)
				return
		}
		else
		{
			if (GetPropEntity(Ware_ListenHost, "m_hObserverTarget") != m_driver)
				return
		}	
			
		local x = 0.1, y = 0.35
		local r = 200, g = 255, b = 200, a = 255
		local i = 0
		local dt = NDEBUG_TICK * kart_skip_tick
		local DrawText = function(...)
		{
			vargv.insert(0, this)
			local text = format.acall(vargv)
			DebugDrawScreenTextLine(x, y, i++, text, r, g, b, a, dt)			
		}
		
		DrawText("Buttons: %d", m_buttons)
		DrawText("Forward Move: %d", m_forward_move)
		DrawText("Side Move: %d", m_side_move)
		DrawText("Speed: %g", m_velocity.Length2D())
		DrawText("Velocity X: %g", m_velocity.x)
		DrawText("Velocity Y: %g", m_velocity.y)
		DrawText("Velocity Z: %g", m_velocity.z)
		DrawText("Ground: %s", m_ground ? m_ground.GetClassname() : "null")
		DrawText("Slope Z: %g", m_slope_normal.z)
		DrawText("Gravity: %g", m_gravity_factor)
		DrawText("Drifting: %s", m_drifting.tostring())
		DrawText("Engine pitch: %d", m_engine_pitch)
		DrawText("Boost type: %d", m_boost_type)
		DrawText("Boost counter: %d", m_boost_counter)
		DrawText("Item index: %d", m_item_idx)
		DrawText("Held items index: %d", m_items_held_idx)
		DrawText("Held items: %d", m_items_held.len())
		
		i++
		DrawText("Position: %d (%d)", m_position_idx, m_position_relative)
		DrawText("Checkpoint: %d", m_checkpoint_idx)
		DrawText("Lap: %d", m_lap_idx)
		if (m_lap_valid_idx != INT_MIN)
			DrawText("Last Valid Lap: %d", m_lap_valid_idx)
		
		i++
		DrawText("Point: %d", m_map_point_idx)
		DrawText("Point Next: %d", m_map_next_point_idx)

		i++
		foreach (j, time in m_lap_times)
			DrawText("Lap %d time: %g", j, time)
	}
}

local function ExplosionCreate(origin, radius, duration, inflictor, owner_kart, icon)
{
	local explosion = Ware_CreateEntity("logic_relay")
	explosion.ValidateScriptScope()
	local scope = explosion.GetScriptScope()
	scope.m_owner_kart      <- owner_kart
	scope.m_origin          <- origin
	scope.m_radius          <- radius
	scope.m_duration        <- duration
	scope.m_icon            <- icon
	scope.m_blast_timer     <- Time() + 0.5
	scope.m_hits            <- { [inflictor] = true }
	scope.m_classnames      <- 
	{
		mk_kart        = true
		mk_banana      = true
		mk_fib         = true
		mk_bomb        = true			
		mk_shell_green = true
		mk_shell_red   = true
		mk_shroom      = true
		mk_shroom_gold = true
		mk_shroom_mega = true
		mk_star        = true
	}
	scope.ThinkExplosion <- function()
	{
		local origin = m_origin
		local radius = m_radius
		local spinout_type = Time() < m_blast_timer ? SPINOUT_LAUNCH_UP : SPINOUT_SPIN
		
		// entities may get deleted as they are looped here, so store a list
		local entities = []
		for (local entity; entity = Entities.FindInSphere(entity, origin, radius);)
		{
			if (entity in m_hits)
				continue
			m_hits[entity] <- true
			entities.append(entity)
		}
		
		foreach (entity in entities)
		{
			// bomb might delete them...
			if (!entity.IsValid())
				continue
		
			local classname = entity.GetClassname()
			if (!(classname in m_classnames))
				continue
				
			if (classname == "mk_kart")
			{
				local kart = entity.GetScriptScope()
				if (kart.m_star_timer > 0.0 || kart.m_bullet_timer > 0.0 || kart.m_cannon_end_pos != null)
					continue
				
				if (kart.Spinout(spinout_type))
				{
					AddKillFeedAndVoiceCommand(kart.m_driver, m_owner_kart ? m_owner_kart.m_driver : null, m_icon)
				}
			}
			else if (classname == "mk_bomb")
			{
				entity.GetScriptScope().Explode()
			}
			else
			{
				entity.GetScriptScope().Destroy()
			}
		}
		return 0.1
	}
	AddThinkToEnt(explosion, "ThinkExplosion")
	EntityEntFire(explosion, "Kill", "", duration)
	scope.ThinkExplosion()
}

local function ItemCreate(classname, model, owner_kart, type)
{
	local item = Ware_SpawnEntity("prop_dynamic_override",
	{
		classname  = classname
		model      = model
		solid      = SOLID_NONE
		spawnflags = 128 // disable vphysics or this causes insane lag!!
	})
	item.SetSolid(SOLID_BBOX)
	item.SetSize(Vector(-16, -16, 0), Vector(16, 16, 32))
	item.ValidateScriptScope()
	local scope = item.GetScriptScope()
	scope.m_owner_kart    <- owner_kart
	scope.m_velocity      <- Vector()
	scope.m_standby       <- true
	scope.m_grace_timer   <- 1e30
	scope.m_origin_offset <- type <= ITEM_TYPE_BOMB ? Vector(0, 0, 18) : Vector()
	scope.m_type          <- type
	scope.Physics <- function()
	{
		if (m_standby)
			return -1
		
		local origin = self.GetOrigin()
		local center = origin + m_origin_offset
		m_velocity.z -= gravity_rate * TICKDT
		
		local trace = 
		{
			start      = center
			end        = center + m_velocity * TICKDT
			mask       = MASK_PLAYERSOLID_BRUSHONLY
			ignore     = self
			startsolid = false
		}	
		TraceLineEx(trace)
		if (trace.hit)
		{
			if (trace.startsolid || (trace.surface_flags & SURF_SKY))
			{
				Destroy()
				return
			}
			
			local normal = trace.plane_normal
			if (!trace.startsolid && normal.z < 0.7)
			{
				local speed = m_velocity.Norm()
				m_velocity = (m_velocity - (normal * (m_velocity.Dot(normal) * 2.0))) * speed * 0.5
			}		
			else
			{
				local pos = trace.pos
				if (m_type == ITEM_TYPE_FIB)
					pos.z += 32.0
				self.SetAbsOrigin(pos)
				m_velocity *= 0.0
				
				if (m_type == ITEM_TYPE_BANANA)
					self.EmitSound("MK_Item_Banana_Land")
				else if (m_type == ITEM_TYPE_FIB)
					self.EmitSound("MK_Itembox_Land")		

				RemoveEntityThink(self)
			}				
		}
		else
		{
			self.SetAbsOrigin(trace.end - m_origin_offset)
		}
		
		return -1
	}
	scope.Touch <- function(kart)
	{
		if (kart == m_owner_kart && m_grace_timer >= Time())
			return	
		
		// HACK: don't know when exactly this happens, but it caused errors
		if (!self.IsValid())
			return
			
		switch (m_type)
		{
			case ITEM_TYPE_BANANA:
			{
				if (kart.CanSpinout() && kart.Spinout(SPINOUT_SPIN))
				{
					AddKillFeedAndVoiceCommand(kart.m_driver, m_owner_kart ? m_owner_kart.m_driver : null, "warfan")
				}
				
				Destroy()			
				break
			}
			case ITEM_TYPE_FIB:
			{
				if (kart.CanSpinout() && kart.Spinout(SPINOUT_TUMBLE_FORWARD))
				{
					AddKillFeedAndVoiceCommand(kart.m_driver, m_owner_kart ? m_owner_kart.m_driver : null, "thirddegree")
				}
				
				DispatchParticleEffect("drg_cow_explosion_sparkles", self.GetOrigin(), vec3_zero)
				kart.m_prop.EmitSound("MK_Itembox_Hit")
				Destroy()
				break
			}		
			case ITEM_TYPE_BOMB:
			{
				Explode()
				break
			}
			case ITEM_TYPE_STAR:
			{
				kart.StartStar()
				Destroy()
				break
			}
			case ITEM_TYPE_SHROOM:
			{
				kart.Boost(2.0, BOOST_SHROOM)
				Destroy()
				break
			}	
			case ITEM_TYPE_SHROOM_MEGA:
			{
				kart.StartMega()
				Destroy()
				break
			}	
			case ITEM_TYPE_SHROOM_GOLD:
			{
				kart.Boost(4.0, BOOST_SHROOM)
				Destroy()
				break
			}
			case ITEM_TYPE_SHELL_GREEN:
			case ITEM_TYPE_SHELL_RED:
			{
				if (kart.CanSpinout() && kart.Spinout(SPINOUT_TUMBLE_FORWARD))
				{
					AddKillFeedAndVoiceCommand(kart.m_driver, m_owner_kart ? m_owner_kart.m_driver : null, 
						m_type == ITEM_TYPE_SHELL_GREEN ? "passtime_pass" : "passtime_steal")
				}

				Destroy()
				break
			}
		}
	}
	scope.Explode <- function()
	{
		// HACK
		SetPropString(self, "m_iClassname", "")
		
		local origin = self.GetOrigin()
		local center = origin + Vector(0, 0, 32)
	
		DispatchParticleEffect("fireSmokeExplosion_track", center, vec3_zero)
		DispatchParticleEffect("asplode_hoodoo_burning_debris", center, vec3_zero)
		self.EmitSound("MK_Item_Bomb_Explode")
	
		ExplosionCreate(origin, 192.0, 2.0, self, m_owner_kart, "taunt_soldier")
		Destroy()
	}
	scope.Destroy <- function()
	{
		if (m_owner_kart)
			m_owner_kart.RemoveHeldItem(self)
			
		if (m_type == ITEM_TYPE_BOMB)
		{
			self.StopSound("MK_Item_Bomb_Fuse")
		}
		else
		{
			local hit = "m_hit" in this && m_hit // HACK
			if (m_type == ITEM_TYPE_SHELL_GREEN) 
			{
				self.StopSound("MK_Item_Shell_Green_Follow")	
				DispatchParticleEffect("spell_skeleton_bits_green", self.GetOrigin(), vec3_zero)			
				self.EmitSound(hit ? "MK_Item_Shell_Hit" : "MK_Item_Shell_Break")
			}
			else if (m_type == ITEM_TYPE_SHELL_RED)
			{
				self.StopSound("MK_Item_Shell_Red_Follow")
				DispatchParticleEffect("spell_pumpkin_mirv_bits_red", self.GetOrigin(), vec3_zero)
				self.EmitSound(hit ? "MK_Item_Shell_Hit" : "MK_Item_Shell_Break")
			}
		}
		
		RemoveEntityThink(self)
		self.Kill()
	}
	AddThinkToEnt(item, "Physics")
	return item	
}

local item_base_throwable =
{
	OnPressedAttack = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE)
			ThrowOne(kart, false)
		else
			Attach(kart)
	}
	
	OnPressedAttack2 = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE)
			ThrowOne(kart, true)
		else
			Attach(kart)
	}
	
	OnReleasedAttack = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE && kart.m_items_held_idx != ITEM_BANANA_THREE)
			ThrowOne(kart, false)
	}
	
	OnReleasedAttack2 = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE && kart.m_items_held_idx != ITEM_BANANA_THREE)
			ThrowOne(kart, true)
	}
	
	OnDrop = function(items, kart)
	{
		OnDropInternal(items, kart, m_type)
	}
	
	// HACK for shrooms to pass their own type
	OnDropInternal = function(items, kart, type)
	{
		local count = 1
		switch (kart.m_item_idx)
		{
			case ITEM_SHROOM_TWO:
				count = 2
				break
			case ITEM_BANANA_THREE:
			case ITEM_SHELL_GREEN_THREE:
			case ITEM_SHELL_RED_THREE:
			case ITEM_SHROOM_THREE:
				count = 3
				break				
		}

		if (!items)
		{
			items = []
			for (local i = 0; i < count; i++)
			{
				local item = Create(kart, type)
				item.SetAbsOrigin(kart.m_entity.GetOrigin())
				items.append(item)
			}
		}
		
		foreach (item in items)
		{
			local item_scope = item.GetScriptScope()
			item.AcceptInput("ClearParent", "", null, null)
			Drop(item_scope)
		}
	}
	
	Drop = function(item_scope)
	{
		item_scope.m_standby = false
		item_scope.m_grace_timer = Time() + 0.5
		local t = RandomFloat(-PI, PI)
		local velocity = Vector(cos(t), sin(t), 2.0)
		velocity.Norm()
		velocity *= 400.0
		item_scope.m_velocity = velocity	
	}
	
	Attach = function(kart)
	{
		local item_idx = kart.m_item_idx
		local items = []
		local count = item_idx == ITEM_BANANA_THREE ? 3 : 1
		local offset = 0.0
		for (local i = 0; i < count; i++)
		{
			local item = Create(kart, m_type)
			items.append(item)
			SetEntityParent(item, kart.m_prop, "item_back")		
			item.SetLocalOrigin(Vector(offset, 0, 0))
			offset -= 16.0
		}
		
		kart.SetItem(ITEM_NONE)	
		kart.SetHeldItems(item_idx, items)		
	}
	
	ThrowOne = function(kart, front)
	{
		local item = kart.m_items_held.top()
		Throw(item, kart, front)
		kart.RemoveHeldItem(item)	
	}

	Throw = function(item, kart, front)
	{
		local item_scope = item.GetScriptScope()
		local forward = kart.m_entity.GetAbsAngles().Forward()
		local offset = front ? 85.0 : -60.0		
		local velocity
		if (front)
		{
			item_scope.m_velocity = kart.m_velocity + (forward * 800.0) + Vector(0, 0, 600)
			item.EmitSound("MK_Item_Banana_Fly")
		}
		item.AcceptInput("ClearParent", "", null, null)
		item.SetAbsOrigin(kart.m_entity.GetOrigin() + forward * offset)
		item.SetAbsAngles(QAngle(item_scope.m_type == 1 ? 37.0 : 0.0, item.GetAbsAngles().y, 0.0))
		item_scope.m_standby = false
		item_scope.m_grace_timer = Time() + 0.5
		if (item_scope.m_type == ITEM_TYPE_BOMB)
		{
			item.EmitSound("MK_Item_Bomb_Fuse")
			item.SetSkin(1)
			EntityEntFire(item, "CallScriptFunction", "Explode", 4.0)
		}
	}
	
	Create = function(kart, type)
	{
		local item
		switch (type)
		{
			case ITEM_TYPE_BANANA:
			{
				item = ItemCreate("mk_banana", "models/mariokart/items/banana.mdl", kart, type)
				break
			}
			case ITEM_TYPE_FIB:
			{			
				item = ItemCreate("mk_fib", "models/mariokart/items/fib.mdl", kart, type)
				local sprite = SpawnEntityFromTableSafe("env_glow",
				{
					model      = "models/mariokart/items/fib_mark.vmt"
					scale      = 0.5
					rendermode = kRenderTransColor
				})
				SetEntityParent(sprite, item, "mark")
				break
			}	
			case ITEM_TYPE_BOMB:
			{
				item = ItemCreate("mk_bomb", "models/mariokart/items/bomb.mdl", kart, type)
				break
			}
			case ITEM_TYPE_STAR:
			{
				item = ItemCreate("mk_star", "models/mariokart/items/star.mdl", kart, type)
				break
			}
			case ITEM_TYPE_SHROOM:
			{
				item = ItemCreate("mk_shroom", "models/mariokart/items/shroom.mdl", kart, type)
				break
			}
			case ITEM_TYPE_SHROOM_MEGA:
			{
				item = ItemCreate("mk_shroom_mega", "models/mariokart/items/shroom_mega.mdl", kart, type)
				break
			}
			case ITEM_TYPE_SHROOM_GOLD:
			{
				item = ItemCreate("mk_shroom_gold", "models/mariokart/items/shroom_gold.mdl", kart, type)
				break
			}	
			case ITEM_TYPE_SHELL_GREEN:
			{
				item = ItemCreate("mk_shell_green", "models/mariokart/items/shell_green.mdl", kart, type)
				break
			}			
			case ITEM_TYPE_SHELL_RED:
			{
				item = ItemCreate("mk_shell_red", "models/mariokart/items/shell_red.mdl", kart, type)
				break
			}	
			case ITEM_TYPE_SHELL_BLUE:
			{
				item = ItemCreate("mk_shell_blue", "models/mariokart/items/shell_blue.mdl", kart, type)
				break
			}			
		}
		return item
	}
	
	m_type = null
}

item_banana <- clone(item_base_throwable)
item_banana.m_type = ITEM_TYPE_BANANA

item_fib <- clone(item_base_throwable)
item_fib.m_type = ITEM_TYPE_FIB

item_bomb <- clone(item_base_throwable)
item_bomb.m_type = ITEM_TYPE_BOMB

item_shell <-
{
	OnPressedAttack = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE)
			ThrowOne(kart, true)
		else
			Attach(kart)
	}
	
	OnPressedAttack2 = function(kart)
	{
		if (kart.m_items_held_idx != ITEM_NONE)
			ThrowOne(kart, false)
		else
			Attach(kart)
	}
	
	OnReleasedAttack = function(kart)
	{
		local held_idx = kart.m_items_held_idx 
		if (held_idx != ITEM_NONE && held_idx != ITEM_SHELL_GREEN_THREE && held_idx != ITEM_SHELL_RED_THREE)
			ThrowOne(kart, true)
	}
	
	OnReleasedAttack2 = function(kart)
	{
		local held_idx = kart.m_items_held_idx 
		if (held_idx != ITEM_NONE && held_idx != ITEM_SHELL_GREEN_THREE && held_idx != ITEM_SHELL_RED_THREE)
			ThrowOne(kart, false)
	}
	
	OnDrop = function(items, kart)
	{
		item_base_throwable.OnDropInternal(items, kart, m_type)
	}
	
	Attach = function(kart)
	{
		local item_idx = kart.m_item_idx
		local count = 1
		if (item_idx == ITEM_SHELL_GREEN_THREE || item_idx == ITEM_SHELL_RED_THREE)
			count = 3
		
		local items = []
		for (local i = 0; i < count; i++)
		{
			local item = item_base_throwable.Create(kart, m_type)
			items.append(item)
			if (count == 1)
				SetEntityParent(item, kart.m_prop, "item_back")		
			else if (i == 0)
				SetEntityParent(item, kart.m_prop, "item_spin1")		
			else if (i == 1)
				SetEntityParent(item, kart.m_prop, "item_spin2")
			else if (i == 2)
				SetEntityParent(item, kart.m_prop, "item_spin3")			
		}
		
		kart.SetItem(ITEM_NONE)	
		kart.SetHeldItems(item_idx, items)		
	}
	
	ThrowOne = function(kart, front)
	{
		local item = kart.m_items_held.top()
		Throw(item, kart, front)
		kart.RemoveHeldItem(item)	
	}

	Throw = function(item, kart, front)
	{
		local item_scope = item.GetScriptScope()
		
		item_scope.m_hit     <- false
		item_scope.m_gravity <- 0.0		
		item_scope.m_bounces <- 0
		item_scope.m_target_point     <- null
		item_scope.m_target_point_idx <- -1
		item_scope.m_target_kart      <- null
		item_scope.m_target_lock      <- false
		item_scope.m_standby = false
		item_scope.m_grace_timer = Time() + 0.2
		item_scope.Physics <- function()
		{
			if (m_standby)
				return -1
				
			local origin = self.GetOrigin()

			if (m_type == ITEM_TYPE_SHELL_RED)
			{
				if (m_target_kart && m_target_kart.m_entity.IsValid())
				{
					if (m_target_lock)
					{
						local speed = m_velocity.Length()
						local dir = m_target_kart.m_entity.GetOrigin() - origin
						dir.z = 0.0
						dir.Norm()
						m_velocity = dir * speed	
					}
					else
					{
						if ((origin - m_target_point).Length2D() < 64.0)
						{
							m_target_point_idx++
							if (m_target_point_idx >= map_data.point_count)
								m_target_point_idx = 0							
							m_target_point = map_data.points[m_target_point_idx]
						}
						
						local current_point_idx = m_target_point_idx - 1
						if (current_point_idx < 0)
							current_point_idx = map_data.point_count - 1
						
						if (m_target_kart.m_map_point_idx == current_point_idx)
						{
							if ((origin - m_target_kart.m_entity.GetOrigin()).Length2D() < 1024.0)
								m_target_lock = true
						}
						
						local speed = m_velocity.Length()
						local dir = m_target_point - origin
						dir.Norm()
						m_velocity = dir * speed
					}				
				}
			}
	
			local origin_offset = Vector(0, 0, 18)
			local gravity_offset = Vector(0, 0, m_gravity * TICKDT)		
			local trace = 
			{
				start      = origin + Vector(0, 0, 4)
				end        = origin - gravity_offset
				mask       = MASK_PLAYERSOLID_BRUSHONLY
				ignore     = self
				startsolid = false
			}	
			TraceLineEx(trace)		

			if (trace.hit)
			{
				local normal = trace.plane_normal
				if (normal.LengthSqr() == 0.0)
				{
					m_gravity = 0.0
				}	
				else
				{
					local speed = m_velocity.Norm()
					m_velocity = normal.Cross(m_velocity)
					m_velocity = normal.Cross(m_velocity)
					m_velocity.Norm()
					m_velocity *= -speed
					m_gravity = 0.0			
				}
			}
			else
			{
				origin.z -= m_gravity
				m_gravity += 12.0 * TICKDT			
			}
			
			origin += origin_offset
			trace.start = origin
			trace.end = origin + m_velocity * TICKDT
			trace.startsolid = false
			TraceLineEx(trace)
			
			if (trace.hit)
			{
				if (trace.startsolid)
				{
					Destroy()
				}
				else
				{
					local normal = trace.plane_normal
					if (normal.z < 0.7)
					{
						if (m_type == ITEM_TYPE_SHELL_RED || (++m_bounces) > 5)
						{
							Destroy()
						}
						else
						{
							self.EmitSound("MK_Item_Shell_Hit")
							
							local speed = m_velocity.Norm()
							m_velocity = (m_velocity - (normal * (m_velocity.Dot(normal) * 2.0))) * speed
						}
					}		
					else
					{
						self.SetAbsOrigin(trace.pos)
					}
				}
			}
			else
			{
				self.SetAbsOrigin(trace.pos - origin_offset)
			}
			
			return -1
		}
		
		item.AcceptInput("ClearParent", "", null, null)
		
		if (front)
		{
			item.SetAbsOrigin(kart.m_origin + kart.m_forward * 64.0)
			local item_velocity = kart.m_forward * (m_type == ITEM_TYPE_SHELL_GREEN ? 500.0 : 250.0)
			local item_speed = Max(item_velocity.Norm() + kart.m_velocity.Length(), 1400.0)
			item_scope.m_velocity <- item_velocity * item_speed
				
			if (item_scope.m_type == ITEM_TYPE_SHELL_RED)
			{
				local target_kart
				for (local i = kart.m_position_relative - 1; i >= 0; i--)
				{
					local other = karts[i]
					if (other.m_rescued || other.m_cannon_end_pos)
						continue				
					if (team_battle && other.m_team == m_owner_kart.m_team)
						continue					
					item_scope.m_target_point_idx = kart.m_map_next_point_idx
					item_scope.m_target_point     = kart.m_map_next_point
					item_scope.m_target_kart      = other
					break
				}
			}			
		}
		else
		{
			item.SetAbsOrigin(kart.m_origin + kart.m_forward * -64.0)
			item_scope.m_velocity <- kart.m_forward  * -400.0
		}
		
		EntityEntFire(item, "CallScriptFunction", "Destroy", 20.0)
		
		EmitSoundEx
		({
			sound_name  = item_scope.m_type == ITEM_TYPE_SHELL_GREEN ? "MK_Item_Shell_Green_Follow" : "MK_Item_Shell_Red_Follow"
			entity      = item
			filter_type = RECIPIENT_FILTER_GLOBAL
		})	
	}
	
	m_type = null
}

item_shell_green <- clone(item_shell)
item_shell_green.m_type = ITEM_TYPE_SHELL_GREEN

item_shell_red <- clone(item_shell)
item_shell_red.m_type = ITEM_TYPE_SHELL_RED

item_shell_blue <-
{
	OnPressedAttack = function(kart)
	{
		kart.SetItem(ITEM_NONE)
		
		local item_origin = (kart.m_origin - kart.m_base_offset + Vector(0, 0, 2.0)) + kart.m_forward * 70.0
		local item = Ware_SpawnEntity("prop_dynamic_override",
		{
			classname = "mk_shell_blue"
			model     = "models/mariokart/items/shell_blue.mdl"
			origin    = item_origin
			solid     = SOLID_NONE
		})
		local trail = SpawnEntityFromTableSafe("env_spritetrail",
		{
			spritename = "effects/flagtrail_blu.vmt"
			origin     = item_origin
			lifetime   = 1.0
			startwidth = 10.0
			endwidth   = 5.0
			rendermode = kRenderTransColor
		})
		SetEntityParent(trail, item)
			
		item.ValidateScriptScope()
		local scope = item.GetScriptScope()
		
		scope.m_owner_kart            <- kart
		scope.m_target_point          <- kart.m_map_next_point
		scope.m_target_point_idx      <- kart.m_map_next_point_idx
		scope.m_target_kart           <- null
		scope.m_target_kart_origin    <- null
		scope.m_target_kart           <- null
		scope.m_stage                 <- 0
		scope.m_spin_t                <- -PI
		scope.m_wait_time             <- 0.5
		scope.m_height_offset         <- Vector(0, 0, 140)
	
		scope.Physics <- function()
		{
			switch (m_stage)
			{
				case 0:
				{
					local origin = self.GetOrigin()
					if ((origin - m_target_point).Length2D() < 64.0)
					{
						m_target_point_idx++
						if (m_target_point_idx >= map_data.point_count)
							m_target_point_idx = 0
							
						m_target_point = map_data.points[m_target_point_idx]
					}
					
					m_target_kart = null
					foreach (kart in karts)
					{
						if (team_battle && m_owner_kart.m_team == kart.m_team)
							continue
						m_target_kart = kart
						break
					}
					
					local current_point_idx = m_target_point_idx - 1
					if (current_point_idx < 0)
						current_point_idx = map_data.point_count - 1
					
					if (m_target_kart 
						&& m_target_kart.m_entity.IsValid()
						&& m_target_kart.m_map_point_idx == current_point_idx)
					{
						m_target_kart_origin = m_target_kart.m_entity.GetOrigin()
						if ((origin - m_target_kart_origin).Length2D() < 1024.0)
							m_stage++
					}
					
					local dir = (m_target_point + m_height_offset) - origin
					dir.Norm()
					
					local velocity = dir * 2500.0
					self.SetAbsOrigin(origin + velocity * TICKDT)
					break
				}
				case 1:
				{
					local origin = self.GetOrigin()
					if (m_target_kart.m_entity.IsValid())
						m_target_kart_origin = m_target_kart.m_entity.GetOrigin()
					if ((origin - m_target_kart_origin).Length2D() < 32.0)
					{
						self.StopSound("MK_Item_Shell_Blue_Fly")
						EmitSoundEx
						({
							sound_name  = "MK_Item_Shell_Blue_Warning"
							entity      = self
							filter_type = RECIPIENT_FILTER_GLOBAL
						})
			
						m_height_offset.z = 90.0
						m_stage++
						return
					}
					
					local dir = (m_target_kart_origin + m_height_offset) - origin
					dir.Norm()
		
					local velocity = dir * 2500.0
					self.SetAbsOrigin(origin + velocity * TICKDT)
					break
				}
				case 2:
				{
					if (m_target_kart.m_entity.IsValid())
						m_target_kart_origin = m_target_kart.m_entity.GetOrigin()
					
					m_spin_t += 10.0 * TICKDT
					if (m_spin_t >= PI)
					{
						m_wait_time = Time() + m_wait_time
						m_stage++
					}
					
					local origin = m_target_kart_origin + m_height_offset
					origin.x += 48.0 * cos(m_spin_t)
					origin.y += 48.0 * sin(m_spin_t)
					self.SetAbsOrigin(origin)
					break
				}		
				case 3:
				{
					if (m_wait_time < Time())
						m_stage++
					
					if (m_target_kart.m_entity.IsValid())
						m_target_kart_origin = m_target_kart.m_entity.GetOrigin()
					self.SetAbsOrigin(m_target_kart_origin + m_height_offset)
					break
				}
				case 4:
				{
					m_height_offset.z -= 1400.0 * TICKDT
					if (m_height_offset.z <= -100.0)
					{
						self.SetAbsOrigin(m_target_kart_origin)
						Explode()
						return
					}
					
					self.SetAbsOrigin(m_target_kart_origin + m_height_offset)
					break
				}
			}
			
			return -1
		}
		scope.Explode <- function()
		{
			local origin = self.GetOrigin()
			local center = origin + Vector(0, 0, 32)
			DispatchParticleEffect("drg_cow_explosioncore_charged_blue", center, vec3_zero)
			DispatchParticleEffect("drg_cow_explosion_sparkles_charged_blue", center, vec3_zero)
			DispatchParticleEffect("rd_robot_explosion_shockwave", origin, vec3_zero)
			self.EmitSound("MK_Item_Shell_Blue_Explode")

			ExplosionCreate(origin, 192.0, 1.5, self, m_owner_kart, "taunt_soldier_lumbricus")
			
			Destroy()		
		}
		scope.Destroy <- function()
		{
			if (m_stage >= 2)
				self.StopSound("MK_Item_Shell_Blue_Warning")
			else
				self.StopSound("MK_Item_Shell_Blue_Fly")
			
			self.Kill()
		}
		
		EmitSoundEx
		({
			sound_name  = "MK_Item_Shell_Blue_Fly"
			entity      = item
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
		
		AddThinkToEnt(item, "Physics")
		EntityEntFire(item, "CallScriptFunction", "Explode", 60.0)	
	}
}

item_shroom <-
{
	OnPressedAttack = function(kart)
	{
		kart.Boost(2.0, BOOST_SHROOM)
		if (kart.m_item_idx == ITEM_SHROOM_THREE)
			kart.SetItem(ITEM_SHROOM_TWO)
		else if (kart.m_item_idx == ITEM_SHROOM_TWO)		
			kart.SetItem(ITEM_SHROOM_ONE)
		else if (kart.m_item_idx == ITEM_SHROOM_ONE)		
			kart.SetItem(ITEM_NONE)
	}
	
	OnDrop = function(items, kart)
	{
		item_base_throwable.OnDropInternal(items, kart, ITEM_TYPE_SHROOM)
	}
}

item_shroom_gold <-
{
	OnPressedAttack = function(kart)
	{
		if (kart.m_shroom_gold_timer == 0.0)
			kart.m_shroom_gold_timer = Time() + 7.5
		kart.Boost(2.0, BOOST_SHROOM)
	}
	
	OnDrop = function(items, kart)
	{
		item_base_throwable.OnDropInternal(items, kart, ITEM_TYPE_SHROOM_GOLD)
	}
}

item_shroom_mega <-
{
	OnPressedAttack = function(kart)
	{
		kart.StartMega()
		kart.SetItem(ITEM_NONE)
	}
	
	OnDrop = function(items, kart)
	{
		item_base_throwable.OnDropInternal(items, kart, ITEM_TYPE_SHROOM_MEGA)
	}
}

item_star <-
{
	OnPressedAttack = function(kart)
	{
		kart.StartStar()
		kart.SetItem(ITEM_NONE)
	}
	
	OnDrop = function(items, kart)
	{
		item_base_throwable.OnDropInternal(items, kart, ITEM_TYPE_STAR)
	}
}

item_bullet <-
{
	OnPressedAttack =  function(kart)
	{
		kart.StartBullet()
	}
}

item_shock <-
{
	OnPressedAttack = function(kart)
	{
		Ware_PlaySoundOnAllClients("MK_Item_Shock_Use")
		kart.SetItem(ITEM_NONE)
		
		local time = Time()
		local min_time = time + 2.0
		local max_time = time + 10.0
		local delta_time = max_time - min_time
		local player_count = (Max(karts.len(), 12) - 1).tofloat()
		
		foreach (other in karts)
		{
			DispatchParticleEffect("mk_lightning_parent", other.m_origin, vec3_up)		
			other.HudStartShock()		
			EntityEntFire(other.m_entity, "CallScriptFunction", "HudResetShock", 1.5)
			
			if (other == kart)
				continue
			if (team_battle && other.m_team == kart.m_team)
				continue				
			if (other.m_rescued 
				|| other.m_bullet_timer > 0.0 
				|| other.m_star_timer > 0.0 
				|| other.m_cannon_end_pos)
				continue
	
			AddKillFeedMessage(other.m_driver, kart.m_driver, "spellbook_lightning")
			MakePlayerComplain(other.m_driver)						 
			other.Shrink(max_time - delta_time * other.m_position_idx.tofloat() / player_count)
			
			other.DropItems()
		}
		
		MakePlayerCheer(kart.m_driver)
	}	
}

item_blooper <-
{
	OnPressedAttack = function(kart)
	{
		EmitSoundOnClient("MK_Item_Blooper_Use", kart.m_driver)
		kart.SetItem(ITEM_NONE)
		
		local position = kart.m_position_idx
		foreach (other in karts)
		{
			if (team_battle && other.m_team == kart.m_team)
				continue		
			if (other.m_position_idx > position)
				continue
			if (other.m_rescued || other.m_bullet_timer > 0.0)
				continue

			if (other.m_position_idx < position)
			{
				EmitSoundOnClient("MK_Item_Blooper_Attack", other.m_driver)
				EntityEntFire(other.m_entity, "CallScriptFunction", "StartBlooper", 2.0)
			}

			other.ShowBlooper()
		}
	}
}

item_map = 
{
	[ITEM_NONE]				 = null,
	[ITEM_BANANA_ONE]		 = item_banana,
	[ITEM_SHROOM_MEGA]		 = item_shroom_mega,
	//[ITEM_POW]			 = item_pow,
	[ITEM_SHOCK]			 = item_shock,
	[ITEM_STAR]				 = item_star,
	[ITEM_SHROOM_TWO]		 = item_shroom,
	[ITEM_FIB]				 = item_fib,
	[ITEM_BOMB]				 = item_bomb,
	[ITEM_SHROOM_THREE]		 = item_shroom,
	[ITEM_BULLET]			 = item_bullet,
	[ITEM_SHELL_BLUE]		 = item_shell_blue,
	[ITEM_SHROOM_ONE]		 = item_shroom,
	[ITEM_SHELL_RED_THREE]	 = item_shell_red,
	[ITEM_SHELL_GREEN_ONE]	 = item_shell_green,
	[ITEM_BANANA_THREE]		 = item_banana,
	[ITEM_SHROOM_GOLD]		 = item_shroom_gold,
	[ITEM_SHELL_RED_ONE]	 = item_shell_red,
	[ITEM_BLOOPER]			 = item_blooper,
	[ITEM_SHELL_GREEN_THREE] = item_shell_green,
}