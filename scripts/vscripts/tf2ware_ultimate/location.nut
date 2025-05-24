// by ficool2

// Stores list of locations
// Each location shares these in common:
// - "center" vector
// -- Center point of the location
// - "Init()" function
// -- Called when the map starts, allows locations to setup their own data
// - "Teleport(players)" function
// -- Executed when players are about to be teleported into this location
// - "cameras" array
// -- Optional list info_observer_point names associated with the location
//    These are automatically enabled/disabled
Ware_Location <- {}

// Internal use only
Ware_LocationParent <-
{
	function DebugDraw()
	{
		DebugDrawLine(center, center + Vector(0, 0, 32), 0, 0, 255, true, 10.0)
		if ("mins" in this && "maxs" in this)
			DebugDrawBox(Vector(), mins, maxs, 255, 0, 0, 50, 10.0)
	}
}

// == Locations ==

Ware_Location.home <-
{
	center     = Vector(-512, 760, -512)
	mins       = Vector(-896, 376, -512)
	maxs       = Vector(-128, 1144, 3550)
	cameras    = ["home_camera"]
	spawns     = []
	spawn_name = "home_spawns"
	spawn_idx  = 0
	Init       = function()
	{
		for (local spawn; spawn = FindByName(spawn, spawn_name);)
		{
			MarkForPurge(spawn)
			spawns.append(spawn)
		}
	}
	Teleport   = function(players)
	{
		local spawn_len = spawns.len()
		foreach (player in players)
		{
			local spawn = spawns[spawn_idx]
			spawn_idx = (spawn_idx + 1) % spawn_len
			Ware_TeleportPlayer(player, spawn.GetOrigin(), spawn.GetAbsAngles(), vec3_zero)
		}
	}
}

Ware_Location.home_big <-
{
	center     = Vector(1688, 1560, -864)
	mins       = Vector(946, 820, -864)
	maxs       = Vector(2428, 2298, 3198)
	cameras    = ["home_big_camera"]
	spawns     = []
	spawn_name = "home_big_spawns"
	spawn_idx  = 0
	Init       = Ware_Location.home.Init
	Teleport   = Ware_Location.home.Teleport
}

Ware_Location.circlepit <-
{
	center   = Vector(-1952, -872, 720)
	radius   = 288.0
	Teleport = function(players) { Ware_TeleportPlayersCircle(players, center, radius) }
}

Ware_Location.circlepit_big <-
{
	center   = Vector(-3304, 2400, 1056)
	radius   = 600.0
	Teleport = Ware_Location.circlepit.Teleport
}

Ware_Location.sawrun <-
{
	center   = Vector(4480, -4000, -4495)
	finish   = Vector(4480, -3056, -4495)
	Teleport = function(players) 
	{
		local spacing_x = -50.0, spacing_y = 50.0
		if (players.len() > 40)
		{
			spacing_x *= 0.75
			spacing_y *= 0.5
		}
		Ware_TeleportPlayersRow(players,
			center - Vector(40, 0, 0),
			QAngle(0, 90, 0),
			480.0,
			spacing_x, spacing_y)
	}
}

Ware_Location.sawrun_micro <-
{
	center   = Vector(-160, 5546, -11887)
	finish   = Vector(-160, 5948, -11887)
	Teleport = function(players) 
	{
		local spacing_x = -50.0, spacing_y = 50.0
		if (players.len() > 40)
		{
			spacing_x *= 0.75
			spacing_y *= 0.5
		}	
		Ware_TeleportPlayersRow(players,
			center - Vector(0, 512, 0),
			QAngle(0, 90, 0),
			460.0,
			spacing_x, spacing_y)
	}
}

Ware_Location.targetrange <-
{
	center    = Vector(2264, -3896, -3968)
	left      = Vector(2303, -5380, -3999)
	right     = Vector(2303, -2410, -3999)
	left_mid  = Vector(2240, -4670, -3999)
	right_mid = Vector(2303, -3135, -3999)
	cameras   = ["targetrange_camera1", "targetrange_camera2"]
	lines	  = 
	[
		[Vector(2400, -4056, -3999), Vector(2944, -4056, -3999)],
		[Vector(1536, -4056, -3999), Vector(2080, -4056, -3999)],
		[Vector(2016, -3896, -3999), Vector(2560, -3896, -3999)],
		[Vector(2496, -3712, -3999), Vector(3040, -3712, -3999)],
		[Vector(1536, -3712, -3999), Vector(2080, -3712, -3999)],
	]
	Teleport = function(players)
	{
		TeleportTeamsToSides(players, left, right)
	}
	TeleportTeamsToSides = function(players, pos_left, pos_right)
	{
		local red_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_RED)
		local blue_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_BLUE)	
		local left_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)		
		if (left_team == TF_TEAM_RED)
			TeleportSide(red_players, blue_players, pos_left, pos_right)
		else
			TeleportSide(blue_players, red_players, pos_left, pos_right)	
	}
	TeleportSide = function(players_left, players_right, pos_left, pos_right)
	{
		local function PlaceSide(players, origin, angles, y_offset)
		{
			local x_offset = 80.0
			local pos = origin * 1.0
			local x = 0
			foreach (player in players)
			{
				if (++x > 20)
				{
					pos.y += y_offset
					x = 1
				}
				
				pos.x = origin.x + (x / 2) * ((x & 1) ? x_offset : -x_offset)
				Ware_TeleportPlayer(player, pos, angles, vec3_zero)
			}		
		}	
		PlaceSide(players_left, pos_left, QAngle(0, 90, 0), 80.0)
		PlaceSide(players_right, pos_right, QAngle(0, 270, 0), -80.0)	
	}
}

Ware_Location.boxarena <-
{
	center   = Vector(-1792, 8192, -7135)
	mins     = Vector(-2736, 7248, -7135)
	maxs     = Vector(-832, 9152, -5552)
	radius   = 600.0
	cameras  = ["boxarena_camera"]
	Teleport = function(players) 
	{ 
		local r = radius
		if (players.len() > 40.0)
			r += 200.0
		Ware_TeleportPlayersCircle(players, center, r)
	}
}

Ware_Location.beach <-
{
	center   = Vector(4400, 6568, -3790)
	mins     = Vector(4112, 5656, -4200)
	maxs     = Vector(8192, 7680, -3296)
	cameras  = ["beach_camera"]
	Teleport = function(players)
	{
		Ware_TeleportPlayersRow(players, 
			center, 
			QAngle(), 
			1000.0, 
			64.0, 64.0)
	}
}

Ware_Location.manor <-
{
	center  	  = Vector(8048, -6440, -3615)
	lobby		  = Vector(6048, -5516, -3822)
}

Ware_Location.pinball <-
{
	center        = Vector(-3840, -1280, -6792)
	center_top    = Vector(-3840, -5344, -5679)
	center_bottom = Vector(-3840, 1884, -7599)
	cameras       = ["pinball_camera"]
}

Ware_Location.factoryplatform <-
{
	center        = Vector(4208, 1664, -5215)
	center_left   = Vector(3708, 1664, -5271)
	center_right  = Vector(4700, 1664, -5271)
}

Ware_Location.love <-
{
	center         = Vector(5376, -1480, -5920)
	center_left    = Vector(6160, -984, -5919)
	center_right   = Vector(6080, -2100, -5919)
	cameras        = ["love_camera"]
	walls          = []
	Init           = function()
	{
		for (local wall; wall = FindByName(wall, "love_door*");)
		{
			MarkForPurge(wall)	
			wall.AddFlag(FL_UNBLOCKABLE_BY_PLAYER)
			walls.append(wall)
		}
	}
}

Ware_Location.kart_containers <-
{
	center         = Vector(-1200, 3450, -6718)
	cameras        = ["kartcontainers_camera"]
	Teleport = function(players)
	{
		local pos = center * 1.0
		local width = 900.0
		if (players.len() > 64)
		{
			pos.x -= 350.0
			width += 600.0
		}
		Ware_TeleportPlayersRow(Ware_GetSortedScorePlayers(false), 
			pos,
			QAngle(0, 180, 0),
			width,
			128.0, 128.0)
	}
}

Ware_Location.kart_paths <-
{
	center         = Vector(-6688, 928, -5984)
	center_left    = Vector(-7095, -5300, -6046)
	center_right   = Vector(-6520, -5300, -6046)
	angles         = QAngle(0, 90, 0)
	width          = 380.0
	spacing        = 100.0
	Teleport = function(players)
	{
		local sorted_players = Ware_GetSortedScorePlayers(true)
		local red_players = sorted_players.filter(@(i, player) player.GetTeam() == TF_TEAM_RED)
		local blue_players = sorted_players.filter(@(i, player) player.GetTeam() == TF_TEAM_BLUE)
		
		local left_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
		
		if (left_team == TF_TEAM_RED)
		{
			Ware_TeleportPlayersRow(red_players, center_left, angles, width, spacing, spacing)
			Ware_TeleportPlayersRow(blue_players, center_right, angles, width, spacing, spacing)
		}
		else
		{
			Ware_TeleportPlayersRow(blue_players, center_left, angles, width, spacing, spacing)
			Ware_TeleportPlayersRow(red_players, center_right, angles, width, spacing, spacing)
		}
	}
	
}

Ware_Location.kart_ramp <-
{
	center   = Vector(-7000, -10400, -6494)
	Teleport = function(players)
	{
		Ware_TeleportPlayersRow(Ware_GetSortedScorePlayers(true), 
			center,
			QAngle(0, 90, 0),
			1500.0,
			200.0, 100.0)
	}
}

Ware_Location.frogger <-
{
	center   = Vector(11488, -6150, -6447)
	cameras  = ["frogger_camera1", "frogger_camera2", "frogger_camera3"]
	Teleport = function(players)
	{
		local spacing = 50.0
		if (players.len() > 40)
			spacing *= 0.7
		Ware_TeleportPlayersRow(players, 
			center,
			QAngle(0, 90, 0),
			400.0,
			-spacing, spacing)
	}
}

Ware_Location.sumobox <-
{
	center   = Vector(-4600, -9500, -6142)
	radius   = 480
	cameras  = ["sumobox_camera"]
	Teleport = function(players) { Ware_TeleportPlayersCircle(players, center, radius) }
}

Ware_Location.mandrill <-
{
	center   = Vector(-1536, -13024, -5344)
	start    = Vector(2240, -13562, -5343)
	maze     = Vector(-3584, -14720, -5344)
	cameras  = ["mandrill_camera"]
	Teleport = function(players)
	{
		foreach (player in players)
			Ware_TeleportPlayer(player, start, QAngle(0, 180, 0), vec3_zero)
	}
}

Ware_Location.rocketjump <-
{
	center   = Vector(128, -3344, -7392)
	radius   = 400
	cameras  = ["rocketjump_camera"]
	Teleport = function(players) { Ware_TeleportPlayersCircle(players, center, radius) }
}

Ware_Location.rocketjump_micro <-
{
	center = Vector(1940, 4780, -6490)
	radius = 400
	Teleport = function(players) { Ware_TeleportPlayersCircle(players, center, radius) }
}

Ware_Location.hexplatforms <-
{
	center      = Vector(2304, -8448, -4880)
	// TODO need to dynamically align this camera
	//cameras     = ["hexplatforms_camera"]
	plat_models = []
	Init        = function()
	{
		for (local plat; plat = FindByName(plat, "hexplatforms_pillar*");)
		{
			MarkForPurge(plat)
			plat_models.append(plat.GetModelName())
			plat.Kill()
		}	
	}
	Teleport = function(players) 
	{ 
		// Handled by minigame because of dynamic pillars
	}
}

Ware_Location.dirtsquare <-
{
	center      = Vector(1648, -1776, -511)
	radius      = 768.0
	cameras     = ["dirtsquare_camera"]
	Teleport = function(players) { Ware_TeleportPlayersCircle(players, center, radius) }
}

Ware_Location.jumprope <-
{
	center      = Vector(80, -1008, -4959)
	Teleport = function(players) 
	{ 
		local red_players  = players.filter(@(i, player) player.GetTeam() == TF_TEAM_RED)
		local blue_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_BLUE)
		local center_left  = center + Vector(0, 300, 0)
		local center_right = center + Vector(0, -300, 0)
		local width   = 700.0
		local spacing = 60.0
		Ware_TeleportPlayersRow(red_players, center_left, QAngle(0, 270, 0), width, spacing, spacing)
		Ware_TeleportPlayersRow(blue_players, center_right, QAngle(0, 90, 0), width, -spacing, spacing)
	}	
}

Ware_Location.obstaclecourse <-
{
	center      = Vector(-1696, -3968, -3927)
	cameras     = ["obstaclecourse_camera"]
	Teleport = function(players) 
	{ 
		// highest scoring players start last
		Ware_TeleportPlayersRow(Ware_GetSortedScorePlayers(false), center, QAngle(0, 90, 0), 600.0, -60.0, 60.0)
	}	
}

Ware_Location.ballcourt <-
{
	center      = Vector(5800, -2176, -7200)
	left        = Vector(5792, -3064, -7199)
	right       = Vector(5792, -1278, -7199)
	cameras     = ["basketball_camera", "basketball_camera2"]
	Teleport = function(players) 
	{ 
		local players_left = players.slice(0, players.len() / 2)
		local players_right = players.slice(players.len() / 2)
		local width = 1200.0
		Ware_TeleportPlayersRow(players_left, left, QAngle(0, 90, 0), width, -60.0, 59.0)
		Ware_TeleportPlayersRow(players_right, right, QAngle(0, 270, 0), width, 60.0, 59.0)
	}	
}

Ware_Location.beepblockskyway_micro <-
{
	center = Vector(-13285, -14470, -9760)
	cameras = ["Beatblock_Camera1", "Beatblock_Camera2", "Beatblock_Camera3"	]
	Teleport = function(players)
	{
		// highest scoring players start last
		Ware_TeleportPlayersRow(Ware_GetSortedScorePlayers(true), center, QAngle(0, 90, 0), 450, 50, 80)
	}
}

Ware_Location.beepblockskyway_ultimate <-
{
	center = Vector(-8960, -13500, -9760)
	cameras = ["Beatblock_Camera4", "Beatblock_Camera5", "Beatblock_Camera6"]
	Teleport = function(players)
	{	
		// highest scoring players start last
		Ware_TeleportPlayersRow(Ware_GetSortedScorePlayers(true), center, QAngle(0, 90, 0), 900, 80, 110)
	}
}

Ware_Location.warehouse <-
{
	center = Vector(1000, 11900, -4159)
	mins   = Vector(480, 11664, -4160)
	maxs   = Vector(1560, 12592, -3648)
	cameras = ["warehouse_camera"]	
	Teleport = function(players)
	{
		Ware_TeleportPlayersRow(players, 
			center,
			QAngle(0, 90, 0),
			900.0,
			64.0, 64.0)
	}	
}

Ware_Location.homerun_contest <-
{
	center = Vector(-12128, -5470, -14207)
	Teleport = function(players)
	{
		Ware_TeleportPlayersRow(players,
			center
			QAngle(0, 90, 0),
			0.0,
			0.0, 0.0)
	}
}

Ware_Location.factory <-
{
	center = Vector(4200, 2450, -6205)
	Teleport = function(players)
	{
		local spacing_y = 80.0
		if (players.len() > 40)
			spacing_y = 50.0
		Ware_TeleportPlayersRow(players,
			center
			QAngle(0.0, 180.0, 0.0),
			400.0,
			50.0, spacing_y)
	}
}

Ware_Location.typing <-
{
	center = Vector(7192, 2648, -6392)
	radius = 355.0
	// these are converted to point_viewcontrol
	//cameras = ["DRBoss_CloseupCamera_Point", "DRBoss_DescentCamera_Point", "DRBoss_SpiralCamera_Point"]
	Teleport = function(players)
	{
		Ware_TeleportPlayersCircle(players,	center, radius)
	}
}

Ware_Location.boxingring <-
{
	center      = Vector(-900, -400, -5645)
	Teleport = function(players) 
	{ 
		local red_players  = players.filter(@(i, player) player.GetTeam() == TF_TEAM_RED)
		local blue_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_BLUE)
		local center_left  = center + Vector(375, 0, 0)
		local center_right = center + Vector(-375, 0, 0)
		local width   = 800.0
		local spacing = 60.0
		Ware_TeleportPlayersRow(red_players, center_left, QAngle(0, 180, 0), width, spacing, spacing)
		Ware_TeleportPlayersRow(blue_players, center_right, ang_zero, width, spacing, spacing)
	}
}

Ware_Location.inventoryday <-
{
	side_left  = Vector(1800, 4500, -11630)
	side_right = Vector(1800, 3400, -11630)
	center     = Vector(1340, 3960, -11630)
	radius     = 800.0
	Teleport = function(players)
	{
		Ware_TeleportPlayersCircle(players, center, radius)
	}
}

Ware_Location.abcdeathpit <-  // NOTE: Players can get stuck if collisions are on (they will still die though)
{
	center = Vector(128, 1160, -4000)
	radius = 1.0
	Teleport = function(players)
	{
		Ware_TeleportPlayersCircle(players, center, radius)
	}
}

Ware_Location.waluigi_pinball <-
{
	center         = Vector(2240, 134, 8054)
	cameras        = ["waluigi_camera"]
	hud_camera_pos = Vector(96, 4640, -512)
	hud_head_pos   = Vector(424, 4640, -512)
	start_position = Vector(11968, 4150, 5560)
	cannon_trigger = null
	cannon_end_pos = Vector(-6856, 4125, 11770)
	bound_spin_pos = Vector(8429, 0, 6253)
	bound_spinners = []
	flippers       = []
	checkpoints    = []
	point_groups   = 
	[
		[
			Vector(11790.2, 4123.93, 5561.78)
			Vector(9677.25, 4123.2, 5561.78)
			Vector(9185.06, 4122.51, 5626.12)
			Vector(-6550.7, 4126.9, 11380.5)
			Vector(-8716.07, 4123.02, 11296.1)
			Vector(-8968.93, 4046.26, 11296.1)
			Vector(-9210.59, 3932.12, 11296.1)
			Vector(-9397.14, 3819.48, 11296.1)
			Vector(-9565.99, 3599.69, 11296.1)
			Vector(-9741.72, 3411.7, 11296.1)
			Vector(-9861.47, 3196.4, 11296.1)
			Vector(-9934.35, 2972.93, 11296.1)
			Vector(-9996.96, 2535.83, 11296.1)
			Vector(-10020.9, 2167.44, 11296.1)
			Vector(-9964.87, 1716.25, 11296.1)
			Vector(-9959.17, 1464.51, 11296.1)
			Vector(-9886.86, 1030.32, 11296.1)
			Vector(-9750.43, 772.904, 11296.1)
			Vector(-9440.7, 341.823, 11296.1)
			Vector(-9217.71, 196.158, 11296.1)
			Vector(-8973.75, 74.1843, 11296.1)
			Vector(-8724.8, 1.72433, 11296.1)
			Vector(-7877.53, 1.67155, 11296.1)
			Vector(-7734.79, 0.56002, 11310.1)
		],
		[
			Vector(-7594.14, 0.403604, 11352.4)
			Vector(-7491.89, -0.064868, 11156.3)
			Vector(-5094.98, 0.782582, 10234)
			Vector(-4817.46, 116.214, 10127)
			Vector(-4666.33, 298.279, 10068.8)
			Vector(-4578.9, 537.593, 10035.2)
			Vector(-4475.67, 686.118, 9995.53)
			Vector(-4475.79, 1072.25, 9995.41)
			Vector(-4509.88, 1350.44, 10008.3)
			Vector(-4506.37, 1750.12, 10006.7)
			Vector(-4449.71, 1967.88, 9985.05)
			Vector(-4249.59, 2102.57, 9908.15)
			Vector(-4083.98, 2176.16, 9844.24)
			Vector(-3844.44, 2235.28, 9751.78)
			Vector(-3157.22, 2235.93, 9487.9)
			Vector(-2878.18, 2165.04, 9380.14)
			Vector(-2700.95, 2023.51, 9312.01)
			Vector(-2564.86, 1847.5, 9259.29)
			Vector(-2471.61, 1583.12, 9223.47)
			Vector(-2421.78, 1373.16, 9203.95)
			Vector(-2384.09, 880.531, 9189.45)
			Vector(-2458.09, 520.34, 9217.87)
			Vector(-2497.95, 141.43, 9232.87)
			Vector(-2690.18, -161.283, 9306.92)
			Vector(-2954.19, -464.065, 9408.67)
			Vector(-3224.19, -698.995, 9513.1)
			Vector(-3595.47, -981.684, 9656.19)
			Vector(-3751.86, -1260.59, 9716.57)
			Vector(-3788.54, -1553.07, 9730.51)
			Vector(-3817.95, -1672.97, 9741.76)
			Vector(-3712.29, -1908.35, 9703.87)
			Vector(-3635.06, -2016.22, 9674.15)
			Vector(-3400.97, -2148.9, 9588.51)
			Vector(-3108.32, -2173.67, 9473.18)
			Vector(-2623.53, -2247.73, 9282.12)
			Vector(-2212.89, -2248.89, 9123.17)
			Vector(-1697.25, -2249.68, 9030.71)
			Vector(-1130.54, -2250.27, 9092.39)
			Vector(-147.383, -2247.82, 9473.95)
			Vector(312.273, -2252.22, 9780.38)
			Vector(1181.97, -2253.15, 9497.62)
			Vector(2601.38, -2249.74, 9410.95)
			Vector(3013.39, -2250.01, 9368.31)
			Vector(3161.77, -2258.16, 9365.32)
			Vector(3265.28, -2275.77, 9363.77)
			Vector(3362.64, -2309.73, 9350.87)
			Vector(3584.37, -2439.99, 9345.5)
			Vector(3804.99, -2679.17, 9330.34)
			Vector(3913.46, -2929.77, 9310.08)
			Vector(3964.6, -3089.86, 9295.77)
			Vector(3948.22, -3345.66, 9281.01)
			Vector(3824.15, -3678.59, 9255.3)
			Vector(3601.69, -3916.23, 9232.41)
			Vector(3300.04, -4077.47, 9208.62)
			Vector(2970.15, -4114.52, 9185.63)
			Vector(2646.78, -4033.98, 9162.71)
			Vector(2366.64, -3832.89, 9129.86)
			Vector(2166.92, -3535.06, 9092.16)
			Vector(2095.83, -3181.86, 9049.48)
			Vector(2123.53, -2866.96, 9019.74)
			Vector(2107.19, -2603.84, 8991.74)
			Vector(2093.57, -2396.64, 8966.6)
			Vector(2077.3, -1959.45, 8901.68)
			Vector(2091.94, -1518.75, 8836.23)
			Vector(2095.46, -1127.9, 8697.96)
			Vector(2093.47, -249.76, 8182.79)
			Vector(2092.59, 187.265, 8029.05)
			Vector(2091.85, 593.688, 7986)
			Vector(2093.9, 962.909, 8055.21)
			Vector(2092.5, 1328.66, 8216.35)
			Vector(2092.64, 1428.77, 8249.51)
			Vector(2092.14, 1559.37, 8286.27)
			Vector(2022.87, 1891.02, 8333.65)
			Vector(1842.22, 2170.39, 8356.09)
			Vector(1548.58, 2372.06, 8370.34)
			Vector(1234.34, 2431.67, 8385.85)
			Vector(878.354, 2388.6, 8409.78)
			Vector(-709.188, 1645.97, 8604.38)
			Vector(-910.961, 1489.28, 8641.23)
			Vector(-1079.72, 1243.85, 8668.4)
			Vector(-1117.16, 1162.56, 8669.73)
			Vector(-1155.29, 829.187, 8665.96)
			Vector(-1076.79, 506.29, 8631.77)
			Vector(-884.939, 221.566, 8558.36)
			Vector(-591.612, 52.7133, 8454.37)
			Vector(-251.743, 4.59168, 8318.86)
			Vector(-57.6437, 1.0338, 8217.54)
			Vector(1.36269, -0.634346, 8183.74)
			Vector(840.48, -0.806147, 7597.98)
			Vector(1101.67, 1.67295, 7501.27)
			Vector(7042.89, 18.4492, 6452.28)
			Vector(12072, 0.503553, 5565.64)
			Vector(14447, 1.99043, 5561.78)
			Vector(14822.7, 373.128, 5561.78)
			Vector(14827.9, 3672, 5561.78)
			Vector(14495.6, 4116.73, 5561.78)
		]
	],
	itembox_positions = 
	[
		Vector(-10239, 2155.45, 11344.1)
		Vector(-10091.1, 2155.11, 11344.1)
		Vector(-9911.38, 2159.93, 11344.1)
		Vector(-9739.2, 2169.79, 11344.1)
		Vector(-10244.4, 1985.77, 11344.1)
		Vector(-10092, 1990.24, 11344.1)
		Vector(-9897.69, 1997.33, 11344.1)
		Vector(-9740.47, 2006.8, 11344.1)
		Vector(3651.58, -2974.09, 9328.11)
		Vector(3805.16, -2922.43, 9348.56)
		Vector(3979.84, -2857.07, 9370.11)
		Vector(4142.28, -2804.02, 9389.53)
		Vector(3703.63, -3099.54, 9313.82)
		Vector(3843.12, -3089.13, 9329.74)
		Vector(4046.43, -3053, 9355.99)
		Vector(4188.67, -3024.63, 9374.9)
		Vector(3840.5, 287.869, 7065.26)
		Vector(3744.83, 162.972, 7082.14)
		Vector(3733.71, -162.612, 7084.1)
		Vector(3796.92, -295.442, 7072.95)
		Vector(3851.87, 110.324, 7063.26)
		Vector(3831.86, -80.6778, 7066.79)
		Vector(3946.23, 6.47485, 7046.61)
		Vector(8624.28, 389.463, 6221.73)
		Vector(8170.2, 378.546, 6301.78)
		Vector(8158.13, -370.986, 6303.91)
		Vector(8616.77, -393.952, 6223.06)
		Vector(7959.5, -11.4514, 6338.83)
		Vector(8856.33, -4.01582, 6180.92)
	],

	Init = function()
	{
		cannon_trigger = FindByName(null, "pinball_cannon")				
		for (local checkpoint; checkpoint = FindByName(checkpoint, "pinball_checkpoint*");)
		{
			MarkForPurge(checkpoint)
			checkpoints.append(checkpoint)
		}
		
		local bound_size = Vector(150, 150, 150)
		for (local bound; bound = FindByName(bound, "pinball_bound*");)
		{
			MarkForPurge(bound)
			local scale = endswith(bound.GetModelName(), "big.mdl") ? 2.0 : 1.0
			bound.SetSolid(SOLID_OBB)
			bound.SetSize(bound_size * -scale, bound_size * scale)
			bound.KeyValueFromString("classname", "pinball_bound")
			if (endswith(bound.GetName(), "spin"))
			{
				local bound_pos = bound.GetOrigin()
				bound_pos.z = bound_spin_pos.z + 50.0
				bound.ValidateScriptScope()
				bound.GetScriptScope().origin_relative <- bound_spin_pos - bound_pos
				bound_spinners.append(bound.GetScriptScope())
			}
		}
		
		for (local flipper; flipper = FindByName(flipper, "pinball_flipper_*");)
		{
			MarkForPurge(flipper)
			flipper.SetSolid(SOLID_BBOX)
			flipper.SetSize(flipper.GetBoundingMinsOriented(), flipper.GetBoundingMaxsOriented())
			flipper.KeyValueFromString("classname", "pinball_flipper")
		}
	}
}

Ware_Location.wega_challenge <-
{
	start   = Vector(-32, -13280, -12580)
	cameras  = ["wega_camera"]
	Teleport = function(players)
	{
		Ware_TeleportPlayersRow(players, start, ang_zero, 192, 32, 32)
	}
}