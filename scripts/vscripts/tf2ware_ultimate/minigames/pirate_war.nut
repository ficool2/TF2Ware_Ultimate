minigame <- Ware_MinigameData
({
	name           = "Pirate War"
	author         = "ficool2"
	description    = "Board the enemy ship!"
	duration       = 10.7
	end_delay	   = 1.0
	min_players    = 2
	max_scale      = 1.0
	music          = null
	location       = "beach"
	allow_damage   = true
	friendly_fire  = false
	collisions     = true
	convars		   = 
	{
		tf_avoidteammates		   = 1
		tf_avoidteammates_pushaway = 0
	}
})
 
start_sound <- "ambient/medieval_dooropen.wav" // music
ship_model  <- "models/tf2ware_ultimate/pirate_ship.mdl"
plank_model <- "models/props_mining/board001_reference.mdl"

red_ship  <- null
blue_ship <- null

ship_pos1 <- null
ship_pos2 <- null

ship_spawns <-
[
	Vector(-390, 110, 418)
	Vector(-390, 50, 418)
	Vector(-390, -20, 418)
	Vector(-390, -90, 418)
	
	Vector(-180, 140, 333)
	Vector(-190, 80, 333)
	Vector(-190, 10, 333)
	Vector(-190, -60, 333)
	Vector(-190, -130, 333)
	
	Vector(-110, -160, 333)
	Vector(-8, -174, 333)
	Vector(100, -168, 333)
	
	Vector(200, 140, 333)
	Vector(200, 80, 333)
	Vector(200, 10, 333)
	Vector(200, -60, 333)
	Vector(200, -130, 333)
	
	Vector(310, 90, 368)
	Vector(310, 40, 368)
	Vector(310, -20, 368)
	Vector(310, -90, 368)
	
	Vector(-10, -78, 438)
	Vector(70, -18, 438)
	Vector(-10, 72, 438)
	Vector(-80, -18, 438)
]

function OnPrecache()
{
	PrecacheSound(start_sound)
	PrecacheModel(ship_model)
	PrecacheModel(plank_model)
}

function OnTeleport(players)
{
	local swap = RandomBool()
	
	ship_pos1 = Ware_MinigameLocation.center + Vector(2200, 600, -256)
	ship_pos2 = Ware_MinigameLocation.center + Vector(2200, -500, -256)
	
	red_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = swap ? ship_pos1 : ship_pos2
		model       = ship_model
		solid       = SOLID_VPHYSICS
	})
	blue_ship = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin      = swap ? ship_pos2 : ship_pos1
		model       = ship_model
		solid       = SOLID_VPHYSICS		
		skin        = 1
	})
	
	local red_spawn_ang = swap ? QAngle(0, -90, 0) : QAngle(0, 90, 0)
	local blue_spawn_ang = swap ? QAngle(0, 90, 0) : QAngle(0, -90, 0)
	
	local red_ship_origin = red_ship.GetOrigin()
	local blue_ship_origin = blue_ship.GetOrigin()
	
	local spawns = Shuffle(ship_spawns)
	local spawn_len = spawns.len()
	local red_spawn_idx = 0
	local blue_spawn_idx = 0
	
	foreach (player in players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
		{
			if (red_spawn_idx >= spawn_len)
				red_spawn_idx = 0
				
			local offset = spawns[red_spawn_idx++]
			if (!swap)
				offset.y *= -1.0
			Ware_TeleportPlayer(player, red_ship_origin + offset, red_spawn_ang, vec3_zero)		
		}
		else if (team == TF_TEAM_BLUE)
		{
			if (blue_spawn_idx >= spawn_len)
				blue_spawn_idx = 0

			local offset = spawns[blue_spawn_idx++]
			if (swap)
				offset.y *= -1.0			
			Ware_TeleportPlayer(player, blue_ship_origin + offset, blue_spawn_ang, vec3_zero)	
		}
	}
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Persian Persuader")
	
	SpawnPlanks(ship_pos2)
	
	local hurt = Ware_SpawnEntity("func_croc",
	{
		origin     = Ware_MinigameLocation.center - Vector(0, 0, 88)
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_BBOX)
	hurt.SetSize(Vector(-4096, -2048, -256), Vector(4096, 2048, 0))
	
	Ware_PlaySoundOnAllClients(start_sound)
}

function SpawnPlank(pos, modelscale, mins, maxs)
{
	local upright = RandomBool()
	local plank = Ware_SpawnEntity("prop_dynamic_override",
	{
		targetname  = "wahh"	
		origin 	    = pos
		angles      = QAngle(upright ? 90 : -90, RandomBool() ? 90 : -90, 0)
		model		= plank_model
		modelscale  = modelscale
		solid		= SOLID_BBOX
	})
	
	local plank_mins = mins * 1.0
	local plank_maxs = maxs * 1.0
	if (!upright)
	{
		local maxz = plank_maxs.z
		plank_maxs.z = plank_mins.z * -1.0
		plank_mins.z = maxz * -1.0
	}
	
	plank.SetSize(plank_mins, plank_maxs)
}

function SpawnPlanks(anchor_pos)
{	
	local plank
	local mins = Vector(-32, -320, -10) * 0.1
	local maxs = Vector(32, 320, 0) * 0.1
	local y = 555
	
	SpawnPlank(anchor_pos + Vector(-130, y, 350), 10.5, mins, maxs)	
	
	SpawnPlank(anchor_pos + Vector(40, y, 350), 10, mins, maxs)
	
	SpawnPlank(anchor_pos + Vector(210, y, 350), 11, mins, maxs)
	
	if (Ware_MinigamePlayers.len() > 16)
	{
		SpawnPlank(anchor_pos + Vector(-360, y, 400), 13.5, mins, maxs)	
	
		SpawnPlank(anchor_pos + Vector(360, y, 400), 13.5, mins, maxs)
	}
}

function OnCleanup()
{
	Ware_PlaySoundOnAllClients(start_sound, 1.0, 100, SND_STOP)
}

function OnUpdate()
{
	local time = Time()
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue	
			
		local ground = GetPropEntity(player, "m_hGroundEntity")
		local enemy_ship = player.GetTeam() == TF_TEAM_RED ? blue_ship : red_ship
		if (ground == enemy_ship)
			Ware_PassPlayer(player, true)
	}
}

function OnCheckEnd()
{
	return Ware_GetPassedPlayers(false, true).len() == 0
}