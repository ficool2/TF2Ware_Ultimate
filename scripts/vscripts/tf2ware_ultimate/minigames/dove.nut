minigame <- Ware_MinigameData
({
	name           = "Dove Hunt"
	author         = ["tilderain"]
	description    = "Kill the birds!"
	duration       = 18
	end_delay      = 0.5
	music          = "duckhunt"
})

spawn_rate <- null

bird_model <- "models/props_forest/dove.mdl"

required_amount <- 3

function OnPrecache()
{
	PrecacheSound("tf2ware_ultimate/mp_hit_indication_3c.wav")
	PrecacheModel(bird_model)
}

function OnStart()
{
	spawn_rate = RemapValClamped(Ware_MinigamePlayers.len().tofloat(), 0.0, 32.0, 0.5, 0.05)
	Ware_SetGlobalLoadout(TF_CLASS_SNIPER, "Huntsman")

	foreach (player in Ware_MinigamePlayers)
	{
		Ware_GetPlayerMiniData(player).points <- 0
		
		local weapon = player.GetActiveWeapon()
		if (weapon == null)
			continue

		weapon.SetClip1(1)
	}
	
	Ware_CreateTimer(@() SpawnDove(), 0.25)
}

function DoveThink()
{
	local time = Time()
	if (spawn_time + 7.0 < Time()) 
	{
		self.Kill()
		return
	}
	
	// update at cl_interp minimum
	local dt = 0.05
	
	local move_speed = 300.0
	local dest = move_dir * move_speed * dt
	local offset = Vector(0, 0, 32)
	self.SetAbsOrigin(self.GetOrigin() + dest)
	self.StudioFrameAdvance()
	
	return dt
}



function SpawnDove()
{
	local origin = Vector(
		RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
		RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
		Ware_MinigameLocation.center.z + RandomFloat(250, 500))

	local angle = RandomFloat(-180, 180)
	local vec_angle = Vector(cos(angle), sin(angle))
	local yaw = atan2(vec_angle.y, vec_angle.x) * RAD2DEG

	local dove = Ware_SpawnEntity("base_boss",
	{	
		model       = bird_model
		origin      = origin
		angles      = QAngle(0, yaw, 0)
		defaultanim = "fly_cycle"
		health      = 9999
		targetname  = "dovehuntdove"
	})
	dove.SetModelScale(RandomFloat(3.5, 4.5), 0.25)
	EntityAcceptInput(dove, "Disable")
	
	dove.SetSolid(SOLID_BBOX)
	dove.SetSize(Vector(-14, -14, 0), Vector(14, 14, 8))
	dove.ResetSequence(dove.LookupSequence("fly_cycle"))
	dove.ValidateScriptScope()
	local dove_scope = dove.GetScriptScope()

	dove_scope.move_dir <- vec_angle
	dove_scope.spawn_time <- Time()

	dove_scope.DoveThink <- DoveThink.bindenv(dove_scope)
	AddThinkToEnt(dove, "DoveThink")
	
	//DispatchParticleEffect("Explosion_bubbles", origin, Vector(1, 0, 0))
	
	return spawn_rate
}


function OnTakeDamage(params)
{
	if (params.const_entity.GetClassname() == "base_boss")
	{
		local player = params.attacker

		if (player && player.IsPlayer())
		{
			local minidata = Ware_GetPlayerMiniData(player)
			minidata.points++
				
			Ware_ShowText(player, CHANNEL_MINIGAME, "x", 0.25, "255 255 255", -1, -1)
			
			if (minidata.points >= required_amount)
				Ware_PassPlayer(player, true)		
		}
		DispatchParticleEffect("blood_impact_red_01", params.const_entity.GetOrigin(), vec3_zero)
		params.const_entity.Kill()

		return true
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

function OnEnd()
{
    local highest_amount = required_amount - 1
    local highest_players = []

    foreach (player in Ware_MinigamePlayers)
    {
        local minidata = Ware_GetPlayerMiniData(player)
        if (minidata.points > highest_amount)
            highest_amount = minidata.points
    }

    foreach (player in Ware_MinigamePlayers)
    {
        local minidata = Ware_GetPlayerMiniData(player)
        if (minidata.points == highest_amount)
            highest_players.append(player)
    }

    if (highest_players.len() > 0)
    {
        foreach (player in highest_players)
        {
            Ware_ChatPrint(null, "{player} {color}killed the most doves with {int} shot!", 
                player, TF_COLOR_DEFAULT, highest_amount)
        }
        Ware_GiveBonusPoints(highest_players)
    }
}