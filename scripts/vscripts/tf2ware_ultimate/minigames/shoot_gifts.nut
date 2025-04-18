minigame <- Ware_MinigameData
({
	name           = "Shoot 10 Gifts"
	author         = ["Mecha the Slag", "ficool2"]
	description    = "Shoot the Gift 10 times!"
	duration       = 29.4
	end_delay      = 0.5
	music          = "pumpit"
	location       = "targetrange"
	custom_overlay = "shoot_gift_10"
	convars        =
	{
		// make this easier on higher timescales or its near impossible
		phys_timescale = RemapValClamped(Ware_GetTimeScale(), 1.0, 2.0, 0.9, 0.6),	
	}
})

gift_model <- "models/tf2ware_ultimate/gift.mdl"
hit_sound  <- RandomInt(0, 100) <= 5 ? "tf2ware_ultimate/mp_hit_indication_3c.wav" : "Player.HitSoundBeepo"
bomb_model <- "models/props_lakeside_event/bomb_temp.mdl"
bomb_modelindex <- PrecacheModel(bomb_model)
bomb_count <- 0
bomb_sound <- "vo/taunts/demo/taunt_demo_nuke_8_explosion.mp3"

gift_count <- 0
gifts_active <- []

function OnPrecache()
{
	PrecacheModel(gift_model)
	PrecacheModel(bomb_model)
	PrecacheScriptSound("Player.HitSoundBeepo")
	PrecacheSound(bomb_sound)
	PrecacheSound("tf2ware_ultimate/mp_hit_indication_3c.wav")
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SNIPER, "Sniper Rifle")

	foreach (player in Ware_MinigamePlayers)
		Ware_GetPlayerMiniData(player).points <- 0
			
	Ware_CreateTimer(@() SpawnGift(), 1.0)
}

function SpawnGift()
{
	local line = RandomElement(Ware_MinigameLocation.lines)
	local origin = Lerp(line[0], line[1], RandomFloat(0.0, 1.0))
	local angles = QAngle(0, -90, 0)
	local gift = Ware_SpawnEntity("prop_physics_override",
	{	
		model  = gift_model
		origin = origin
		angles = angles
		skin   = RandomInt(0, 1)
	})
	
	if (gift_count >= 2 
		&& bomb_count < 4
		&& RandomInt(1, 5) == 1)
	{
		SetPropInt(gift, "m_nModelIndex", bomb_modelindex)
		gift.SetModelScale(1.25, 0.0)
		bomb_count++
	}
	else
	{
		gift_count++
	}
	
	gift.KeyValueFromString("classname", "pumpkindeath") // kill icon
	gift.AddEFlags(EFL_NO_DAMAGE_FORCES)
	gift.SetPhysVelocity(Vector(RandomFloat(-500, 500), 0, RandomFloat(1000, 1200)))
	gift.ValidateScriptScope()
	local gift_scope = gift.GetScriptScope()
	gift_scope.lag_record <- [origin]
	gift_scope.mins <- gift.GetBoundingMins()
	gift_scope.maxs <- gift.GetBoundingMaxs()
	gift_scope.GiftThink <- function()
	{
		lag_record.append(self.GetOrigin())
		return -1
	}
	AddThinkToEnt(gift, "GiftThink")
	local gifts = gifts_active
	gifts.append(gift_scope)
	Ware_CreateTimer(function()
	{
		gifts.remove(gifts.find(gift_scope))
		gift.Kill()
	}, RemapValClamped(Ware_GetTimeScale(), 1.0, 2.0, 1.7, 2.6))
	
	return RandomFloat(1.7, 2.0)
}

function OnPlayerAttack(player)
{		
	local eye_position = player.EyePosition()
	local eye_fwd = player.EyeAngles().Forward()
	
	// backtrack gift positions (lag compensation)
	local latency = GetPlayerLatency(player)
	if (player != Ware_ListenHost)
		latency += Ware_GetPlayerData(player).lerp_time
	local tick = TimeToTicks(latency)
	
	foreach (gift in gifts_active)
	{
		local records = gift.lag_record
		local record_tick = Max(records.len() - 1 - tick, 0)
		local lag_origin = gift.lag_record[record_tick]
		
		//DebugDrawBox(gift.self.GetOrigin(), gift.mins, gift.maxs, 255, 0, 0, 20, 3.0)
		//DebugDrawBox(lag_origin, gift.mins, gift.maxs, 0, 255, 0, 20, 3.0)
		//DebugDrawLine(eye_position, eye_position + eye_fwd * 2048.0, 255, 0, 0, false, 3.0)
		
		if (IntersectRayWithBox(eye_position, eye_fwd, 
			lag_origin + gift.mins,
			lag_origin + gift.maxs, 
			0.0, 8192.0) > 0.0)
		{
			if (GetPropInt(gift.self, "m_nModelIndex") == bomb_modelindex)
			{
				player.EmitSound(bomb_sound)
				player.TakeDamage(1000.0, DMG_BLAST, gift.self)
			}
			else
			{
				local minidata = Ware_GetPlayerMiniData(player)
				minidata.points++
				
				Ware_PlaySoundOnClient(player, hit_sound)			
				Ware_ShowText(player, CHANNEL_MINIGAME, "x", 0.25, "255 255 255", -1, -1)
				
				if (minidata.points >= 10)
					Ware_PassPlayer(player, true)		
			}
		}
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (Ware_GetPlayerAmmo(player, TF_AMMO_PRIMARY) == 0)
			SetPropInt(player, "m_nImpulse", 101)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}