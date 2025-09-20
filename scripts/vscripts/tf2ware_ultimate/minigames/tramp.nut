minigame <- Ware_MinigameData
({
	name           = "Trampoline"
	author         = "tilderain"
	description    = "Jump on the hoops!"
	duration       = 15.5
	end_delay      = 1.0
	location       = "dirtsquare"
	music          = "happyville"
	thirdperson    = true
	convars = 
	{
		sv_airaccelerate = 1000
	}
	fail_on_death = true
	start_pass    = true
})

hoop_model <- "models/props_halloween/hwn_jump_hoop01.mdl"
hoop_sound <- "ui/hitsound_beepo.wav"

hoop        <- null
hoop_radius <- 0.0

function OnPrecache()
{
	PrecacheModel(hoop_model)
	PrecacheSound(hoop_sound)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersCircle(players, Ware_MinigameLocation.center + Vector(0, 0, 500), 150.0)
}

function OnStart()
{
	Ware_ChatPrint(null, "{color}HINT:{color} Press left and right to strafe in the air!", COLOR_GREEN, TF_COLOR_DEFAULT)

	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerClass(player, TF_CLASS_DEMOMAN)
		Ware_GetPlayerMiniData(player).jumps <- 0
		player.SetMoveType(MOVETYPE_NONE, 0)
	}

	Ware_CreateTimer(function()
	{
		// when hits 0, unfreeze players
		foreach (player in Ware_MinigamePlayers)
		{
			local dir = player.GetOrigin() - Ware_MinigameLocation.center
			dir.Norm()

			player.SetMoveType(MOVETYPE_WALK, 0)
			player.SetAbsVelocity(dir * -300.0)
		}
	}, 2.0)

	local origin = Ware_MinigameLocation.center + Vector(0, 0, 200)
	SpawnHoop(origin, true)

	Ware_CreateTimer(function() 
	{
		hoop.Kill()
		
		local origin = Ware_MinigameLocation.center + Vector(RandomFloat(-400, 400), RandomFloat(-400, 400), RandomFloat(100, 300))
		SpawnHoop(origin, false)
		
		return 3.0
	}, 3.5)
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}

function SpawnHoop(origin, firsthoop)
{
	local scale = RandomFloat(0.7, 1.0)
	
	hoop = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin         = origin
		angles         = QAngle(90, 0, 0)
		model          = hoop_model
		modelscale     = scale
		disableshadows = true
	})
	
	hoop_radius = 315.0 * scale
}

function OnUpdate()
{
	if (!hoop)
		return
	
	local hoop_origin = hoop.GetOrigin()
	local fatal_ground = Ware_GetMinigameTime() > 1.0
	
	foreach (player in Ware_MinigamePlayers)
	{	
		if (!player.IsAlive())
			continue
		
		if (fatal_ground && (player.GetFlags() & FL_ONGROUND))
		{
			Ware_SuicidePlayer(player)
			continue		
		}
		
		local origin = player.GetOrigin()	
		if (origin.z > hoop_origin.z)
			continue
			
		if (VectorDistance2D(origin, hoop_origin) > hoop_radius)
			continue
			
		local minidata = Ware_GetPlayerMiniData(player)
		Ware_PlaySoundOnClient(player, hoop_sound, 1.0, 90 +  minidata.jumps * 10)
		minidata.jumps++
		
		local velocity = player.GetAbsVelocity()
		velocity.z = 1200.0
		player.SetAbsVelocity(velocity)
		
		origin.z = hoop_origin.z + 0.01
		player.SetAbsOrigin(origin)
	}
}