special_round <- Ware_SpecialRoundData
({
	name        = "Skull"
	author      = ["Mikusch", "ficool2"]
	description = "Beware of the skull..."
	categories  = []
	allow_respawnroom = false
})

skull_model <- "models/props_mvm/mvm_human_skull_collide.mdl"
skull_sound <- "ambient/halloween/underground_wind_lp_02.wav"
skull_kill_sound <- "Halloween.skeleton_laugh_giant"
skull_height <- 240.0
skull_last_location <- ""
skull_kills <- 0
skull <- null

function OnPrecache()
{
	PrecacheModel(skull_model)
	PrecacheSound(skull_sound)
	PrecacheScriptSound(skull_kill_sound)
}

function OnStart()
{
	local skull_origin = Ware_MinigameHomeLocation.center + Vector(0, 0, skull_height)
	skull = SpawnEntityFromTableSafe("base_boss",
	{
		origin    = skull_origin
		model     = skull_model
		health    = INT_MAX
	})
	skull.SetSolid(SOLID_NONE)
	EntityAcceptInput(skull, "Disable")
	skull_last_location = Ware_MinigameHomeLocation.name

	EmitSoundEx(
	{
		sound_name  = skull_sound
		sound_level = 70
		entity      = skull
		filter_type = RECIPIENT_FILTER_GLOBAL
	})
}

function OnUpdate()
{
	if (skull.IsValid())
	{
		if (skull_last_location != Ware_MinigameLocation.name)
		{
			skull_last_location = Ware_MinigameLocation.name
			skull.SetAbsOrigin(Ware_MinigameLocation.center + Vector(0, 0, skull_height))
		}

		local time = Time()
		local skull_origin = skull.GetOrigin()
		local closest_dist = FLT_MAX, closest_player
		foreach (data in Ware_PlayersData)
		{
			// ignore freshly spawned players for a bit in intermission
			if (!Ware_Minigame && data.spawn_time + 2.0 >= time)
				continue

			local player = data.player
			if (player.IsAlive())
			{
				local dist = VectorDistance(player.EyePosition(), skull_origin)

				if (dist < 50.0)
				{
					// die silently
					local player_class = GetPropInt(player, "m_PlayerClass.m_iClass")
					SetPropInt(player, "m_PlayerClass.m_iClass", TF_CLASS_UNDEFINED)
					player.TakeDamage(10000.0, DMG_PREVENT_PHYSICS_FORCE, skull)
					SetPropInt(player, "m_PlayerClass.m_iClass", player_class)
					if (!player.IsAlive())
					{
						Ware_PlaySoundOnClient(player, skull_kill_sound)
						skull_kills++
						local ragdoll = GetPropEntity(player, "m_hRagdoll")
						if (ragdoll)
						{
							MarkForPurge(ragdoll)
							ragdoll.Kill()
						}
					}
					continue
				}

				if (dist < closest_dist)
				{
					closest_dist   = dist
					closest_player = player
				}
			}
		}

		if (closest_player)
		{
			local skull_angles = skull.GetAbsAngles()
			local dir = closest_player.EyePosition() - skull_origin
			dir.Norm()

			// interpolate smoothly
			local new_angles = QuaternionBlend(skull_angles.ToQuat(), VectorAngles(dir).ToQuat(), 0.1).ToQAngle()
			local new_dir = new_angles.Forward()

			local speed = 70.0
			// speed up the shorter the minigame is, unless in the home area
			if (Ware_Minigame && Ware_MinigameLocation != Ware_MinigameHomeLocation)
				speed *= RemapValClamped(Ware_Minigame.duration, 3.0, 30.0, 3.0, 1.0)

			// move faster inside solid geometry
			if (TraceLine(skull_origin, skull_origin, skull) != 1.0)
				speed *= 3.0
			local new_origin = skull_origin + new_dir * speed * TICKDT

			skull.SetAbsOrigin(new_origin)
			skull.SetAbsAngles(new_angles)
		}
	}
}

function OnEnd()
{
	Ware_ChatPrint(null, "The {color}Skull{color} consumed {color}{int}{color} people!",
		COLOR_RED, TF_COLOR_DEFAULT, COLOR_GREEN, skull_kills, TF_COLOR_DEFAULT)

	if (skull.IsValid())
	{
		EmitSoundEx(
		{
			sound_name  = skull_sound
			sound_level = 70
			entity      = skull
			flags       = SND_STOP
			filter_type = RECIPIENT_FILTER_GLOBAL
		})
		skull.Kill()
	}
}