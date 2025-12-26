minigame <- Ware_MinigameData
({
	name           = "Slender"
	author         = ["TonyBaretta", "ficool2"]
	description    = 
	[
		"Collect every page!"
		"You are Slender: Kill every survivor!"
	]
	duration       = 215.0
	end_delay      = 1.5
	music          = "slender"
	location       = "manor"
	custom_overlay =
	[
		"slender_survivor"
		"slender_kill"
	]
	min_players    = 10
	max_scale      = 1.0
	start_pass     = true
	allow_damage   = true
	friendly_fire  = false
	collisions     = true
	convars        =
	{
		mp_teams_unbalance_limit = 0
	}
})

MISSION_SURVIVOR <- 0
MISSION_SLENDER  <- 1

fog <- null
slenders <- []
pages <- []

debug_pages <- false
debug_page_ent <- null
debug_pressed <- false

sound_intro <- "TF2Ware_Ultimate.SlenderIntro"
sound_page <- "TF2Ware_Ultimate.SlenderPage"
slender_model <- "models/arrival/slenderman.mdl"
page_model <- "models/slender/sheet.mdl"

local pages_info =
[
	[ // 0
		[Vector(-3582, 14, -195),  272.0],
		[Vector(-3552, 447, -195), 270.0],
		[Vector(-3177, 423, -139), 180.0],
		[Vector(-3273, -182, -200), 90.0],
		[Vector(-3330, 165, -201), 180.0],
	],
	[ // 1
		[Vector(-2618, -710, -239), 180.0],
		[Vector(-3291, -210, -195), 180.0],
		[Vector(-2489, -436, -288), 180.0],
		[Vector(-3053, -428, -199), 90.0 ],
		[Vector(-3673, -498, -203), 270.0],
		[Vector(-2572, -182, -203), 90.0 ],
	],
	[ // 2
		[Vector(-2276, -297, -203), 270.0],
		[Vector(-2033, 323, -350),  180.0],
		[Vector(-2119, 756, -370),  0.0  ],
		[Vector(-2127, 42, -406),   90.0 ],
		[Vector(-1803, 1384, -396), 225.0],
		[Vector(-1602, 658, -394),  180.0],
	],
	[ // 3
		[Vector(-3158, 522, 77),    0.0  ],
		[Vector(-2490, -104, 193),  180.0],
		[Vector(-2495, 632, 35),    0.0  ],
		[Vector(-3158, 184, -78),   0.0  ],
		[Vector(-2885, 798, -207),  270.0],
		[Vector(-2490, 148, 69),    180.0],
		[Vector(-2426, 446, 63),    270.0],
		[Vector(-3062, 84, 135),    0.0  ],
		[Vector(-2934, 168, -209),  0.0  ],
	],
	[ // 4
		[Vector(-1982, 118, 21),    0.0  ],
		[Vector(-2010, 84, 91),     180.0],
		[Vector(-2072, 466, 89),    90.0 ],
		[Vector(-1390, 466, 71),    90.0 ],
	],
	[ // 5
		[Vector(-520, 850, -143),   90.0 ],
		[Vector(-88, 908, 77),      185.0],
		[Vector(-70, 580, 67),      6.0  ],
		[Vector(-135, 718, 65),     270.0],
		[Vector(-817, 466, 74),     90.0 ],
		[Vector(-1516, 718, 69),    270.0],
	],
	[ // 6
		[Vector(-906, 56, -209),    0.0  ],
		[Vector(642, 14, -3),       180.0],
		[Vector(-646, 656, -205),   271.0],
		[Vector(-42, -262, -201),   90.0 ],
		[Vector(476, 254, -201),    270.0],
	],
	[ // 7
		[Vector(-952, -362, -213),  276.0],
		[Vector(-1419, -778, -199), 4.0  ],
		[Vector(-1204, -838, -238), 90.0 ],
		[Vector(-1374, -192, -207), 0.0  ],
		[Vector(-399, -582, -97),   90.0 ],
		[Vector(-1576, -362, -175), 270.0],
	],
]

pages_collected <- 0

local page_add_time = 12.0
local pages_max = pages_info.len()

local end_time = 0.0
local end_time_max = 0.0

function OnPrecache()
{
	PrecacheScriptSound(sound_intro)
	PrecacheScriptSound(sound_page)
	PrecacheModel(slender_model)
	PrecacheModel(page_model)
}

function OnStart()
{
	fog = Ware_SpawnEntity("env_fog_controller",
	{
		fogenable = true,
		fogcolor = "0 0 0",
		fogcolor2 = "20 20 20",
		fogstart = 100,
		fogend = 484,
		fogmaxdensity = 0.999,
		fogRadial = true,
	})
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (slenders.find(player) != null)
		{
			Ware_SetPlayerMission(player, MISSION_SLENDER)
			Ware_SetPlayerClass(player, TF_CLASS_SPY)
			Ware_StripPlayer(player, false)
			Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
			Ware_AddPlayerAttribute(player, "voice pitch scale", 0, -1)
			Ware_TogglePlayerWearables(player, false)
			player.SetCustomModel(slender_model)
			player.SetModelScale(1.4, 0.0)
		}
		else
		{
			Ware_SetPlayerMission(player, MISSION_SURVIVOR)
			Ware_SetPlayerClass(player, TF_CLASS_MEDIC)
			Ware_StripPlayer(player, true)
			Ware_SetPlayerTeam(player, TF_TEAM_RED)
			Ware_PassPlayer(player, false)
			if (!debug_pages)
				SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
			Ware_GetPlayerMiniData(player).pages_collected <- 0
		}
	}
	
	foreach (i, group in pages_info)
	{
		local infos = debug_pages ? group : [RandomElement(group)]
		foreach (j, info in infos)
		{
			local page = Ware_SpawnEntity("prop_dynamic_override",
			{
				origin  = Ware_MinigameLocation.center + info[0]
				angles  = QAngle(0, info[1], 0)
				model   = page_model
				solid   = SOLID_BBOX
				skin    = i
				teamnum = TF_TEAM_RED
				disableshadows = true
			})
			page.SetTeam(TF_TEAM_RED) // glow only shows to survivors
			page.SetModelScale(1.1, 0.0) // dont't scale collision
			pages.append(page)
		}
	}
	
	Ware_PlaySoundOnAllClients(sound_intro)
	
	end_time = Time() + (minigame.duration - pages_max * page_add_time)
	end_time_max = end_time
	
	Ware_CreateTimer(function() 
	{
		Ware_PlayMinigameMusic(null, Ware_Minigame.music)
		return 28.5
	}, 28.5)
	
	Ware_CreateTimer(@() ShowStatusText(), 1.0)
}

function OnTeleport(players)
{
	local max_slender_count = players.len() > 40 ? 5 : 3
	local slender_count = Clamp(ceil(players.len() / 10.0).tointeger(), 1, max_slender_count)
	for (local i = 0; i < slender_count; i++)
		slenders.append(RemoveRandomElement(players))
	
	Ware_TeleportPlayersRow(slenders,
		Ware_MinigameLocation.center + Vector(-2700, -60, 8),
		QAngle(0, 90, 0),
		400.0,
		60.0, 60.0)
	
	local spacing = 60.0
	if (players.len() > 40)
		spacing *= 0.65
	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.lobby,
		QAngle(0, -90, 0),
		400.0,
		spacing, spacing)
}

function ShowStatusText()
{
	local hms = FloatToTimeHMS(Max(end_time - Time(), 0.0))
	Ware_ShowMinigameText(null, format("%d/%d\n%d:%02d", pages_collected, pages_max, hms.minutes, hms.seconds))
	return 1.0
}

function OnUpdate()
{
	local slenders_data = {}
	foreach (player in slenders)
	{
		if (player.IsValid() && player.IsAlive())
			slenders_data[player] <- player.GetCenter()
	}

	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		local mission = Ware_GetPlayerMission(player)
		if (mission == MISSION_SLENDER)
		{
			SetPropFloat(player, "m_flMaxspeed", 203.0 + pages_collected * 5.0)
		}
		else if (mission == MISSION_SURVIVOR)
		{
			SetPropFloat(player, "m_flMaxspeed", 230.0)
			
			foreach (slender, origin in slenders_data)
			{
				if (VectorDistance(player.GetCenter(), origin) <= 90.0)
					player.TakeDamage(300.0, DMG_CLUB, slender)
			}
		}
	}
	
	if (debug_pages)
	{
		Debug()
	}
}

function Debug()
{	
	local host = GetListenServerHost()
	if (host)
	{
		if (!debug_page_ent)
		{
			debug_page_ent = Ware_SpawnEntity("prop_dynamic_override",
			{
				model          = page_model
				skin           = 0
				teamnum        = TF_TEAM_RED
				disableshadows = true
			})
		}
		
		local trace = 
		{
			start      = host.EyePosition()
			end        = host.EyePosition() + host.EyeAngles().Forward() * 1024
			mask       = MASK_PLAYERSOLID_BRUSHONLY
			ignore     = host
		}	
		TraceLineEx(trace)
		
		if (trace.hit)
		{
			local normal = trace.plane_normal
			local page_origin = VectorSnap(trace.endpos + normal * 2.0, 1.0)
			local page_angles = VectorAngles(normal)
			debug_page_ent.SetAbsOrigin(page_origin)
			debug_page_ent.SetAbsAngles(page_angles)
			
			local pressed = GetPropInt(host, "m_nButtons") & IN_RELOAD
			if (pressed)
			{
				if (!debug_pressed)
				{
					local relative_origin = page_origin - Ware_MinigameLocation.center
					printf("[Vector(%g, %g, %g), %g],\n",
						relative_origin.x, relative_origin.y, relative_origin.z, page_angles.y)
				}
			}
			
			debug_pressed = pressed
		}
	}		
		
	foreach (i, page in pages)
	{
		if (page.IsValid())
		{
			local text = format("%d - %s", page.GetSkin(), (page.GetOrigin() - Ware_MinigameLocation.center).ToKVString())			
			DebugDrawText(page.GetOrigin(), text, false, 0.03)
		}
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	local attacker = params.attacker
	if (victim.IsPlayer())
	{
		if (victim.GetPlayerClass() == TF_CLASS_SPY)
			return false
	}
	else if (victim.GetClassname() == "prop_dynamic"
			&& victim.GetModelName() == page_model
			&& !victim.IsEFlagSet(EFL_KILLME))
	{
		victim.EmitSound(sound_page)
		victim.SetSolid(SOLID_NONE)
		EntityEntFire(victim, "Kill", "", 0.1)
		
		pages_collected++
		if (attacker && attacker.IsPlayer())
			Ware_GetPlayerMiniData(attacker).pages_collected++
		
		end_time += page_add_time
		if (end_time > end_time_max)
		{
			end_time = Time() + (minigame.duration - pages_max * page_add_time)
			end_time_max = end_time
		}
		ShowStatusText()
	}	
}

function OnPlayerDeath(player, attacker, params)
{
	if (player.GetPlayerClass() == TF_CLASS_SPY)
	{
		player.SetCustomModel("")
		CreateTimer(@() KillPlayerRagdoll(player), 0.0)
	}
}

function OnEnd()
{
	if (pages_collected >= pages_max)
	{
		local survivors = Ware_GetTeamPlayers(TF_TEAM_RED)		
		foreach (player in survivors)
		{
			if (player.IsAlive())
				Ware_PassPlayer(player, true)
			// dead survivors who picked up a page will pass
			else if (Ware_GetPlayerMiniData(player).pages_collected > 0)
				Ware_PassPlayer(player, true)
		}
			
		foreach (player in slenders)
		{
			if (player.IsValid())
				Ware_PassPlayer(player, false)
		}
		
		Ware_ChatPrint(null, "All pages collected... The Survivors win!")
	}
	else if (Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0)
	{
		Ware_ChatPrint(null, "All survivors are dead... Slender wins!")
	}
	else
	{
		Ware_ChatPrint(null, "Time's up... Slender wins!")
	}
}

function OnCleanup()
{
	Ware_ShowMinigameText(null, "")
	
	foreach (player in Ware_MinigamePlayers)
	{
		local mission = Ware_GetPlayerMission(player)
		if (mission == MISSION_SURVIVOR)
		{
			SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", null)
		}
		else if (mission == MISSION_SLENDER)
		{
			player.SetModelScale(1.0, 0.0)
			player.SetCustomModel("")
			Ware_TogglePlayerWearables(player, true)
		}
	}
}

function OnCheckEnd()
{
	return end_time < Time() || Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0 || pages_collected >= pages_max
}