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
	convars = {
		sv_airaccelerate = 1000
	}
	fail_on_death = true
	start_pass    = true
})

hoop_model <- "models/props_halloween/hwn_jump_hoop01.mdl"
hoop_sound <- "ui/hitsound_beepo.wav"

hoops <- []

local hoop_delay = 3.5

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
		player.RemoveHudHideFlags(HIDEHUD_PIPES_AND_CHARGE)

		local minidata = Ware_GetPlayerMiniData(player)
		minidata.last_origin <- player.GetCenter()
		minidata.jumps <- 0
		minidata.attack2 <- false
		SetPropBool(player, "m_Shared.m_bShieldEquipped", true)

		SetPropFloat(player, "m_Shared.m_flChargeMeter", 0.0)

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
			player.SetAbsVelocity(dir*-300)
		}
	}, 2.0)

	local origin = Ware_MinigameLocation.center + Vector(0, 0, 200)

	SpawnHoop(origin, false, true)

	for(local i = 1; i < 6; i++)
	{
		local origin = Ware_MinigameLocation.center + Vector(RandomFloat(-400, 400), RandomFloat(-400, 400), RandomFloat(100, 300))
		Ware_CreateTimer(function() {
			SpawnHoop(origin, true)
		}, ((i * hoop_delay) + 1.5))
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}

function SpawnHoop(origin, randomangle, firsthoop = false)
{
	local t = 0
	
	local dirs = [0, 10, 20, 25]
	local num = RemoveRandomElement(dirs)
	if (RandomBool())
		num = -num
	if (!randomangle)
		num = 0
	local dir = Vector(num,num,20)
	dir.Norm()
	
	local scale = RandomFloat(0.7, 1.0)
	local hoop = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin         = origin
		angles         = VectorAngles(dir)
		model          = hoop_model
		modelscale     = scale
		disableshadows = true
	})

	local hoop_dict = {
		entity = hoop
		origin = origin
		radius = 315.0 * scale
		normal = dir
		dist   = dir.Dot(origin)
	}
	hoops.append(hoop_dict)
	local delay = hoop_delay
	if (firsthoop)
		delay = 6
	Ware_CreateTimer(function()
	{
		hoops.remove(hoops.find(hoop_dict))
		hoop.Kill()
	}, hoop_delay)
	//RemapValClamped(Ware_GetTimeScale(), 1.0, 2.0, 1.7, 2.6)
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		local origin = player.GetCenter()


		local attack2 = GetPropInt(player, "m_nButtons") & IN_ATTACK2
		if (attack2 && !minidata.attack2)
		{
			player.AddCond(TF_COND_SHIELD_CHARGE)
		}
		minidata.attack2 = attack2

		if(player.GetFlags() & FL_ONGROUND && Ware_GetMinigameTime() > 1.0)
		{
			Ware_SuicidePlayer(player)
			continue
		}

		foreach (i, hoop in hoops)
		{
			local jumps = minidata.jumps


			local point = IntersectLinePlane(minidata.last_origin, origin, hoop.normal, hoop.dist)
			if (point == null)
				continue
			
			local dist = VectorDistance(point, hoop.origin)
			if (dist > hoop.radius)
				continue

			minidata.jumps++

			local gravity = 800.0

			local velocity = player.GetAbsVelocity()
			local n = hoop.normal
			local nSquared = n.Dot(n)

			// Check if normal vector is valid (non-zero)
			if (nSquared > 1e-8)
			{
			    // Calculate projection of velocity onto normal
			    local proj = velocity.Dot(n) / nSquared
			    // Remove normal component to get tangential velocity
			    local tangential = velocity - n * proj
			    // Apply new normal boost (1750) while preserving tangential velocity
			    local newVelocity = n * 1600 + tangential
				if(newVelocity.z < 1500) newVelocity.z = 1500
			    player.SetAbsVelocity(newVelocity)
			}
			else
			{
			    // Fallback to original behavior if normal is invalid
			    player.SetAbsVelocity(n * 1500)
			}

			player.RemoveCond(TF_COND_SHIELD_CHARGE)
								
			Ware_PlaySoundOnClient(player, hoop_sound, 1.0, 90 + jumps * 10)
		}
		minidata.last_origin = origin
	}
	
	//local points = (10).tofloat()
	//local point_prev = point_a
    //for (local i = 1.0; i <= points; i += 1.0) 
	//{
    //    local t = i / points
    //    local point = LerpQuadratic(point_a, point_b, point_c, t)
    //    DebugDrawLine(point_prev, point, 255, 0, 0, false, NDEBUG_TICK)
    //    point_prev = point
    //}	
}
function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.SetRageMeter(0)
		SetPropBool(player, "m_Shared.m_bRageDraining", false)
		player.AddHudHideFlags(HIDEHUD_PIPES_AND_CHARGE)
	}
}