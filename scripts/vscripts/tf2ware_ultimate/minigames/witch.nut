minigame <- Ware_MinigameData
({
	name          = "Witch"
	author        = "ficool2"
	description   = "Don't startle the witch!"
	duration      = 12.0
	end_delay     = 1.0
	music         = "witchhour"
	start_pass    = true
	fail_on_death = true
	allow_damage  = true
})

witch_origin         <- null
witch_model          <- "models/tf2ware_ultimate/alaxe/witch.mdl"
witch_spawn_particle <- "wrenchmotron_teleport_beam"
witch_leave_particle <- "halloween_ghost_smoke"
witch_spawn_sound    <- "Weapon_DRG_Wrench.Teleport"
witch_cry_sound      <- "TF2Ware_Ultimate.WitchCry"
witch_scream_sound   <- "TF2Ware_Ultimate.WitchScream"
witch_shriek_sound   <- "TF2Ware_Ultimate.WitchShriek"
witch_step_sound     <- "cleats_conc.StepLeft"
witches              <- []

function OnPrecache()
{
	PrecacheModel(witch_model)
	PrecacheParticle(witch_spawn_particle)
	PrecacheParticle(witch_leave_particle)
	PrecacheScriptSound(witch_spawn_sound)
	PrecacheScriptSound(witch_cry_sound)
	PrecacheScriptSound(witch_scream_sound)
	PrecacheScriptSound(witch_shriek_sound)
	PrecacheScriptSound(witch_step_sound)
}

function OnStart()
{
	// detect melee hits against world
	SetPropInt(World, "m_takedamage", DAMAGE_EVENTS_ONLY)
	witch_origin = Ware_MinigameLocation.center
	Ware_ShowAnnotation(witch_origin + Vector(0, 0, 68), "WITCH!", 1.5)
	Ware_CreateTimer(@() SpawnWitchPre(), 1.0)
	Ware_CreateTimer(@() SpawnWitch(), 1.5)
}

function OnCleanup()
{
	foreach (witch in witches)
	{
		DispatchParticleEffect(witch_leave_particle, witch.GetOrigin() + Vector(0, 0, 12), Vector(0, 0, 1))
		witch.StopSound(witch_cry_sound)
	}
	SetPropInt(World, "m_takedamage", DAMAGE_NO)
}

function WitchThink()
{
	local time = Time()
	// update at cl_interp minimum
	local dt = 0.05
	local my_origin = self.GetOrigin()
	
	if (threat && (!threat.IsValid() || !threat.IsAlive()))
		threat = null

	if (threat == null)
	{
		self.ResetSequence(self.LookupSequence("walk"))
		
		if (amb_timer < time)
		{
			self.EmitSound(cry_sound)
			amb_timer = time + RandomFloat(2.5, 4.0)
		}
		
		if (threat == null)
		{
			if (path_timer < time)
			{
				// move in a random direction			
				path_timer = time + RandomFloat(1.5, 5.0)			
				local angle = RandomFloat(-PI, PI)
				move_dir = Vector(cos(angle), sin(angle))
			}
		}
	}
	else
	{
		// move towards threats
		move_dir = threat.GetOrigin() - my_origin
		move_dir.z = 0.0		
		move_dir.Norm()
		
		if (shake_timer < time)
		{
			ScreenShake(my_origin, 15, 10, 1.0, 1000.0, 0, true)
			shake_timer = time + RandomFloat(0.4, 0.6)
		}
		
		if (step_timer < time)
		{
			self.EmitSound(step_sound)
			step_timer = time + 0.15
		}		
		
		if (VectorDistance(threat.GetOrigin(), my_origin) < 70.0)
		{
			self.EmitSound(shriek_sound)
			threat.TakeDamageCustom(self, self, null, Vector(), Vector(), 1000.0, DMG_CLUB|DMG_CRIT, TF_DMG_CUSTOM_DECAPITATION)
		}			

		amb_timer = time + 1.5
		path_timer = time
	}

	if (move_dir != null)
	{
		// face towards direction  with interpolation
		local yaw = self.GetAbsAngles().y
		local target_yaw = atan2(move_dir.y, move_dir.x) * RAD2DEG
		
		local delta = AngleNormalize(target_yaw - yaw)
		local new_yaw = AngleNormalize(yaw + delta * 0.3)
		self.SetAbsAngles(QAngle(0, new_yaw, 0))
		
		local angle = new_yaw * DEG2RAD
		move_dir = Vector(cos(angle), sin(angle))
		local move_speed = threat ? 600.0 : 60.0
		
		// collision check
		// assumes location is flat
		local dest = move_dir * move_speed * dt
		local offset = Vector(0, 0, 32)
		
		local trace = 
		{
			start   = my_origin + offset
			end     = my_origin + dest + offset
			mask    = MASK_PLAYERSOLID_BRUSHONLY
			hullmin = Vector(-4, -4, -4)
			hullmax = Vector(4, 4, 4)
			ignore  = self
		}
		TraceHull(trace)
		if (trace.fraction == 1.0)
		{
			self.SetAbsOrigin(my_origin + dest)
		}
		else
		{
			// move opposite way
			move_dir *= -1.0
		}
	}
	
	self.StudioFrameAdvance()
	return dt
}

function WitchStartle(player)
{
	if (threat != null)
		return
	
	threat = player
	
	if (!(player in started_players))
	{
		started_players[player] <- true
		Ware_ChatPrint(null, "{player} {color}startled the {color}WITCH{color}!", 
			player, TF_COLOR_DEFAULT, COLOR_RED, TF_COLOR_DEFAULT)
		Ware_ChatPrint(player, "{color}TIP{color}: Don't attack, type in chat or use voice!", 
			COLOR_GREEN, TF_COLOR_DEFAULT)
		EntityEntFire(player, "SpeakResponseConcept", "TLK_PLAYER_NEGATIVE")
	}
	
	self.ResetSequence(self.LookupSequence("run"))					
	self.EmitSound(scream_sound)
}

function SpawnWitchPre()
{
	DispatchParticleEffect(witch_spawn_particle, witch_origin, Vector(1, 0, 0))
	EmitSoundEx
	({
		sound_name = witch_spawn_sound
		origin     = witch_origin
		delay      = -1.5
		filter     = RECIPIENT_FILTER_GLOBAL
	})
}

function SpawnWitch()
{
	local witch = Ware_SpawnEntity("base_boss",
	{
		classname = "voodoo_pin" // kill icon
		targetname = "ware_witch"
		origin    = witch_origin
		angles    = QAngle(0, RandomFloat(-180, 180), 0)
		model     = witch_model
		health    = INT_MAX
	})
	EntityAcceptInput(witch, "Disable")
	witch.ResetSequence(witch.LookupSequence("idle"))
	witch.ValidateScriptScope()
	local scope = witch.GetScriptScope()
	scope.threat <- null
	scope.started_players <- {}
	scope.amb_timer <- Time() + 0.5
	scope.path_timer <- 0.0
	scope.shake_timer <- 0.0
	scope.step_timer <- 0.0
	scope.move_dir <- null
	scope.cry_sound <- witch_cry_sound
	scope.scream_sound <- witch_scream_sound
	scope.shriek_sound <- witch_shriek_sound
	scope.step_sound <- witch_step_sound
	scope.WitchThink <- WitchThink.bindenv(scope)
	scope.WitchStartle <- WitchStartle.bindenv(scope)
	AddThinkToEnt(witch, "WitchThink")
	witches.append(witch)
	
	Ware_SpawnEntity("tf_glow",
	{
		target    = "ware_witch"
		GlowColor = "148 0 211 255"
	})
}

function StartleWitch(player, radius)
{
	if (!player.IsAlive())
		return
	
	local player_origin = player.GetOrigin()
	foreach (witch in witches)
	{
		if (VectorDistance(witch.GetOrigin(), player_origin) < radius)
			witch.GetScriptScope().WitchStartle(player)
	}	
}

function OnUpdate()
{
	foreach (player in Ware_Players)
	{
		if (PlayerVoiceListener.IsPlayerSpeaking(player.entindex()))
			StartleWitch(player, 2000.0)
	}	
}

function OnTakeDamage(params)
{
	local attacker = params.attacker
	if (!attacker || !attacker.IsPlayer())
		return
		
	local victim = params.const_entity
	if (victim.GetClassname() == "voodoo_pin")
	{
		if (attacker && attacker.IsPlayer())
			victim.GetScriptScope().WitchStartle(attacker)
	}
	else if (victim == World || victim.IsPlayer())
	{
		StartleWitch(attacker, 1000.0)
		if (attacker && attacker.IsPlayer())
			return false
	}
}

function OnPlayerSay(player, voiceline)
{
	Ware_CreateTimer(@() player.IsValid() ? StartleWitch(player, 1500.0) : null, 0.25)
}

function OnPlayerVoiceline(player, voiceline)
{
	Ware_CreateTimer(@() player.IsValid() ? StartleWitch(player, 2048.0) : null, 0.4)
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}