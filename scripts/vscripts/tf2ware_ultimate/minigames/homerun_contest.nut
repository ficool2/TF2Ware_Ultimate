
// TODO:
// - make damage -> percent better (bit low atm?)
//		- ~0.2 is alright but heavy does way too much
// - make percent -> knockback a lot better
//		- massscale is possibly not a good solution? too high is good distance but barely moves when low, too low has an upper limit to movement
// - add dispensers to podiums
// - set up podiums/podium clips for >1 player
// - add wincon based on furthest distance
// - add teleport trigger at end if its hit really far to go back to start of location or to an extension of the arena.
// - allow class changes? maybe one class change? not sure the best way to do this

//Extend podium clip height, set targetname for podium
//Knockback calc for base hits and then seperate desty for final hits
//Restructure win check to timer?

sandbag_model <- "models/tf2ware_ultimate/sandbag.mdl"
HomeRun_Sandbags <- []

minigame <- Ware_MinigameData
({
	name           = "Home-Run Contest"
	author         = "pokemonPasta"
	description    = "Home-Run Contest!"
	duration       = 23
	location       = "homerun_contest"
	music          = "targets"
	convars        =
	{
		tf_fastbuild = 1
	}
})

function OnPrecache()
{
	PrecacheModel(sandbag_model)

	for (local i = 1; i <= 5; i++)
	{
		PrecacheSound(format("tf2ware_ultimate/homerun/%d.mp3", i))
		PrecacheSound(format("tf2ware_ultimate/homerun/hit%d.mp3", i))
	}

	PrecacheSound("tf2ware_ultimate/homerun/smash.mp3")
	PrecacheSound("tf2ware_ultimate/homerun/failure.mp3")
	PrecacheSound("tf2ware_ultimate/homerun/anewrecord.mp3")
	PrecacheSound("tf2ware_ultimate/homerun/complete.mp3")
	PrecacheSound("tf2ware_ultimate/homerun/ready.mp3")
	Ware_PrecacheMinigameMusic("targets", true)
}

function OnTeleport(players)
{
	Ware_TogglePlayerLoadouts(true)
	// unfortunately have to exclude pyro because it sucks dick
	class_idx <- RandomInt(TF_CLASS_FIRST, TF_CLASS_SPY)
	if (class_idx == TF_CLASS_PYRO)
		class_idx = TF_CLASS_HEAVYWEAPONS
	
	foreach (player in players)
	{
		Ware_SetPlayerClass(player, TF_CLASS_SOLDIER)
		local data = Ware_GetPlayerData(player)
		player.ForceRegenerateAndRespawn()
	}
	Ware_TogglePlayerLoadouts(false)

	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center
		QAngle(0, 90, 0),
		0.0
		0.0, 0.0)
}

local timer = 5

win_distance <- 6000
highest_distance <- 0
highest_player <- null

game_over <- false

shouldend <- false

function OnPick()
{
	return Ware_Players.len() < 56
}

function OnStart()
{
	fog <- Ware_SpawnEntity("env_fog_controller",
	{
		fogenable = true,
		fogcolor = "0 0 0",
		fogcolor2 = "20 20 20",
		fogstart = 250,
		fogend = 3500,
		fogmaxdensity = 0.9,
		farz = 2400,
	})

	local clip = null
	for (local ent; ent = FindByName(ent, "HomeRun_PodiumClip");)
	{
		clip = ent.GetModelName()
		EntityAcceptInput(ent, "Enable")
	}

	//Ware_PlaySoundOnAllClients("tf2ware_ultimate/homerun/ready.mp3")

	// TODO:
	// spawn a podium for each player
	// create a podium clip around each podium
	local name = null
	local addx = 400
	local addy = 0
	local the = Vector(0,0,0)

	//Findbyname HomeRun_Podium
	for (local ent; ent = FindByClassname(ent, "func_brush");)
	{
		the = ent.GetOrigin()
		if(the.x == -12127.5)
		{
			the = ent.GetOrigin()
			Ware_ChatPrint(null, "lol {float}", the)
			name = ent.GetModelName()
			break;
		}
	}
	local index = 0

	foreach(player in Ware_MinigamePlayers)
	{
	//	SetPropEntity(player, "m_Local.m_PlayerFog.m_hCtrl", fog)
		local minidata = Ware_GetPlayerMiniData(player)
		local newbrush = null
		local neworigin = Vector(0,0,0)
		if(index>0)
		{
			if(index%5==0) 
			{
				addy -= 400
				addx = 0
			}
			newbrush = Ware_SpawnEntity("func_brush", {
				model = name,
				origin = the + Vector(addx, addy, 0),
			})
			neworigin = the + Vector(addx, addy, 0),

			newbrush = Ware_SpawnEntity("func_brush", {
				model = clip,
				origin = the + Vector(addx, addy, 0),
				targetname = "HomeRun_PodiumClip",
			})
			player.SetOrigin( the + Vector(addx, addy, 50) )
			minidata.sandbag <- Ware_SpawnEntity("prop_physics_override", {
				model = sandbag_model,
				targetname = format("sandbag%d", index)
				origin = the + Vector(addx, addy, 0) + Vector(0, 150, 80),
				//origin = player.GetOrigin() + Vector(0, 150, 60),
				angles = QAngle(0, -90, 0),
				massscale = 500
			})
			addx += 400
		}
		else
		{
			minidata.sandbag <- Ware_SpawnEntity("prop_physics_override", {
				model = sandbag_model,
				targetname = format("sandbag%d", index)
				origin = the + Vector(0, 150, 80),
				//origin = player.GetOrigin() + Vector(0, 150, 60),
				angles = QAngle(0, -90, 0),
				massscale = 5
			})
			neworigin = Ware_MinigameLocation.center
		}

		index++

		local sandbag = minidata.sandbag
		EntityAcceptInput(sandbag, "Sleep")
		sandbag.ValidateScriptScope()
		local scope = sandbag.GetScriptScope()
		scope.percent <- 0.0
		scope.destY <- 0.0
		scope.player <- player // this might cause null reference issues if a player disconnects, maybe kill the sandbag if a player leaves?
		scope.flying <- false
		scope.outsidePodium <- false
		scope.lastOrigin <- sandbag.GetOrigin()
		scope.groundTime <- -1
		scope.lastHitTime <- 0
		scope.initOrigin <- neworigin

		HomeRun_Sandbags.append(sandbag)

		sandbag.SetGravity(0.1)

		minidata.camera <- Ware_SpawnEntity("point_viewcontrol",
		{
			classname  = "ware_viewcontrol" // don't preserve
			target =     minidata.sandbag.GetName()
			origin     = sandbag.GetOrigin() + Vector(600, 0, 0)
			angles     = QAngle(0, 180, 0)
			spawnflags = 8
		})
		//minidata.camera.SetMoveType(12, 0)

		//SetEntityParent(minidata.camera, sandbag)


		// i need to delay this for some reason
		Ware_CreateTimer(function() {Ware_ShowText(player, CHANNEL_MINIGAME, format("Sandbag: 0.0%%"), Ware_GetMinigameRemainingTime())},0.1)
	}


	Ware_CreateTimer(function()
	{
		if (timer > 0)
		{
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, format("hud/tf2ware_ultimate/countdown_%d", timer))
			Ware_PlaySoundOnAllClients(format("tf2ware_ultimate/homerun/%d.mp3", timer), 1.0)
		}

		timer--

		if (timer >= 0)
			return 1.0
		else if (timer == -1)
		{
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, null)

			for (local ent; ent = FindByName(ent, "HomeRun_PodiumClip");)
				EntityAcceptInput(ent, "Disable")
			return 1.0
		}
		else if (timer == -2)
		{
			return 1.0
		}
		else if (timer == -3)
		{
			Ware_SetGlobalAttribute("no_attack", 1, -1)
			Ware_SetGlobalAttribute("no_jump", 1, -1)
			foreach (player in Ware_MinigamePlayers)
				player.AddFlag(FL_ATCONTROLS)
		}
	}, 5.0)

	Ware_ChatPrint(null, "{color}HINT:{color} Rack up damage and then finish with a strong attack, melee, or tauntkill!", COLOR_GREEN, TF_COLOR_DEFAULT)
}

function IsPointInTrigger(point, trigger)
{
	trigger.RemoveSolidFlags(4)  // FSOLID_NOT_SOLID
	local trace =
	{
		start = point
		end   = point
		mask  = 1
	}
	TraceLineEx(trace)
	trigger.AddSolidFlags(4)

	return trace.hit && trace.enthit == trigger
}

function OnUpdate()
{

	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		//Sometimes game freaks out because camera is missing
		if(!minidata.camera.IsValid() || !minidata.sandbag.IsValid())
			return
		local camera = minidata.camera
		local origin = minidata.sandbag.GetOrigin() + Vector(600, 0, 0)
		if(origin.x > -10200)
			origin.x = -10200
		camera.KeyValueFromVector("origin", origin)
	}

	local time = Time()
	foreach (player in Ware_MinigamePlayers)
	{
		local attack_time = player.GetTauntAttackTime()
		if (attack_time >= time)
		{
			local target = player // squirrel needs this to be happy
			Ware_CreateTimer(@() SpawnFireball(target), attack_time - time)
			player.ClearTauntAttack()
		}
	}
	if(!shouldend && Ware_GetMinigameRemainingTime() < 9.5)
	{
		shouldend = true
		foreach(sandbag in HomeRun_Sandbags)
		{
			if(sandbag.GetScriptScope().outsidePodium)
			{
				shouldend = false
				break
			}
		}
		if(shouldend)
		{
			Ware_Minigame.duration = 1
			Ware_CreateTimer(function() {game_over = true}, 2.5)
		}
	}
	foreach(sandbag in HomeRun_Sandbags)
	{
		local scope = sandbag.GetScriptScope()
		if(!scope.outsidePodium)
		{
			local org = sandbag.GetOrigin()
			local ent = FindByName(null, "HomeRun_PodiumClip")
			if(VectorDistance2D(org, scope.initOrigin) > 230)
			{
				Ware_ChatPrint(null, "lol {int}", VectorDistance2D(org, scope.initOrigin))
				SetCamera(scope.player)
				scope.outsidePodium = true
				scope.flying = true
				if(scope.lastHitTime < Time() + 1)
					scope.destY = 0
			}
			else
			{
				//Clipping thru floor
				if(org.z < -14200)
					sandbag.SetOrigin(org + Vector(0,0,100))
			}
			if(Ware_GetMinigameRemainingTime() < 2.5)
			{
				scope.outsidePodium = true
				Ware_PlaySoundOnClient(scope.player, "tf2ware_ultimate/homerun/failure.mp3")
			}
		}
		else if(scope.flying)
		{
			local distance = sandbag.GetOrigin().y - scope.initOrigin.y
			Ware_ShowText(scope.player, CHANNEL_MINIGAME, format("Distance: %.1fHU", distance), Ware_GetMinigameRemainingTime())

			local nudgeTo = (scope.destY/60)
			if(nudgeTo > 1000 && distance < nudgeTo)
			{
				//	sandbag.SetPhysVelocity(sandbag.GetPhysVelocity()*0.99999)
				sandbag.SetPhysVelocity(sandbag.GetPhysVelocity()*1.12)
			}
			else if (nudgeTo > 1000 && distance > nudgeTo)
			{
			//	sandbag.SetPhysVelocity(sandbag.GetPhysVelocity()*0.99444)
			}


			local origin = sandbag.GetOrigin()
			if(abs(scope.lastOrigin.z - origin.z) <= 1)
				scope.groundTime++

			scope.lastOrigin = origin

			//printl("lol +" + scope.groundTime)
			if(distance > win_distance)
			{
				Ware_PassPlayer(scope.player, true)
			}
			if(distance > highest_distance)
			{
				highest_distance = distance
				highest_player = scope.player
			}

			if(scope.groundTime > 99999 || Ware_GetMinigameRemainingTime() < 2.5)
			{
				if(distance > win_distance)
				{
					Ware_PassPlayer(scope.player, true)
					if(highest_player == scope.player)
					{
						Ware_PlaySoundOnClient(scope.player, "tf2ware_ultimate/homerun/anewrecord.mp3")
						Ware_ChatPrint(null, "{player} {color}got the highest distance with {float}HU!",
							scope.player, TF_COLOR_DEFAULT, distance)
							Ware_GiveBonusPoints(scope.player)
					}
					else
					{
						Ware_PlaySoundOnClient(scope.player, "tf2ware_ultimate/homerun/complete.mp3")
					}

				}
				else
				{
					Ware_PlaySoundOnClient(scope.player, "tf2ware_ultimate/homerun/failure.mp3")
				}

				scope.flying = false
				sandbag.SetMoveType(MOVETYPE_NONE, 0)
			}

		}
	}

}

function OnCheckEnd()
{
	return game_over
}

function SpawnFireball(player)
{
	local fireball = Ware_CreateEntity("tf_projectile_spellfireball")
	fireball.Teleport(
		true, player.EyePosition(),
		true, player.EyeAngles(),
		true, player.EyeAngles().Forward() * 650.0)
	fireball.SetTeam(player.GetTeam())
	fireball.SetOwner(player)
	fireball.SetModelScale(3.0, 0.0)
	SetPropBool(fireball, "m_bCritical", true)
	fireball.DispatchSpawn()
}

function OnTakeDamage(params)
{
	local ent = params.const_entity
	local attacker = params.attacker

	if (!(attacker.IsPlayer() && attacker.IsValid()))
		return

	local sandbag = Ware_GetPlayerMiniData(attacker).sandbag

	if (ent == sandbag)
	{
		local scope = sandbag.GetScriptScope()
		local dmg = (params.damage * 0.15) + RandomFloat(-0.2, 0.2)
		if(sandbag.GetOrigin().z > -14050)
			dmg *= 2
		scope.percent += dmg
		local percent = scope.percent

		local melee_multiplier = (params.weapon && params.weapon.IsMeleeWeapon()) ? 1.0 : 1.0

		if (params.inflictor.GetClassname() == "tf_projectile_spellfireball")
		{
			melee_multiplier = 2.0
			params.damage_force *= 20
			params.damage = 500.0
		}

		//printl("pre: " + params.damage_force)
		params.damage_force *= ((percent / 5.0) * melee_multiplier)
		if (melee_multiplier > 1.0)
			params.damage_force.z = fabs(params.damage_force.z)

		//printl("post: " + params.damage_force)

		scope.destY <- params.damage_force.y
		scope.lastHitTime <- Time()

		ent.Teleport(false, Vector(), false, QAngle(), true, params.damage_force)

		//printl("damage pos" + params.damage_position)

		DispatchParticleEffect("ExplosionCore_sapperdestroyed", params.damage_position, Vector())
		DispatchParticleEffect("repair_claw_heal_blue3", params.damage_position, Vector())

		if(timer >= 0)
		{
			ent.EmitSound(format("tf2ware_ultimate/homerun/hit%d.mp3", RandomInt(1,5)))
			Ware_ShowText(attacker, CHANNEL_MINIGAME, format("Sandbag: %.1f%%", percent), Ware_GetMinigameRemainingTime())
		}
		else if(timer < 0)
		{
			ent.EmitSound("tf2ware_ultimate/homerun/smash.mp3")
			SetCamera(attacker)
			scope.flying = true
			scope.outsidePodium = true
		}

	}
	else if (attacker == ent || attacker == sandbag)
	{
		params.damage == 0.0
	}
}

function OnGameEvent_player_builtobject(params)
{
	local building = EntIndexToHScript(params.index)
	if (!building)
		return

	SetPropInt(building, "m_nDefaultUpgradeLevel", 2)
}

function OnEnd()
{

}

function GiveSpecialMelee(player)
{
	local data = Ware_GetPlayerData(player)
	local melee, vm

	if (!data.special_melee || !data.special_melee.IsValid())
	{
		melee = CreateEntitySafe("tf_weapon_bat")
		SetPropInt(melee, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1123)
		SetPropBool(melee, "m_AttributeManager.m_Item.m_bInitialized", true)
		melee.DispatchSpawn()

		for (local i = 0; i < 4; i++)
			SetPropIntArray(melee, "m_nModelIndexOverrides", bat_modelindex, i)
		SetPropBool(melee, "m_bBeingRepurposedForTaunt", true)
		SetPropInt(melee, "m_nRenderMode", kRenderTransColor)
	}

	if (!data.special_vm || !data.special_vm.IsValid())
	{
		vm = Entities.CreateByClassname("tf_wearable_vm")
		SetPropInt(vm, "m_nModelIndex", bat_modelindex)
		SetPropBool(vm, "m_bValidatedAttachedEntity", true)
		vm.DispatchSpawn()
	}

	if (melee || vm)
		Ware_EquipSpecialMelee(player, melee, vm)
}


function SetCamera(player)
{
	local camera = Ware_GetPlayerMiniData(player).camera
	TogglePlayerViewcontrol(player, camera, true)
	player.SetForceLocalDraw(true)
	player.AddHudHideFlags(HIDEHUD_TARGET_ID)
	player.RemoveCond(TF_COND_TAUNTING)
	player.AddCond(TF_COND_GRAPPLED_TO_PLAYER) // prevent taunting
	SetPropInt(player, "m_takedamage", DAMAGE_YES)
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local camera = Ware_GetPlayerMiniData(player).camera
		TogglePlayerViewcontrol(player, camera, false)
		player.SetForceLocalDraw(false)
		player.RemoveHudHideFlags(HIDEHUD_TARGET_ID)
		player.RemoveFlag(FL_ATCONTROLS)
	}
}
