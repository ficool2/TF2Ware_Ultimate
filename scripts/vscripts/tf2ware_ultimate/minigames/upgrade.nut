MISSION_DAMAGE <- 0
MISSION_RESIST <- 1
MISSION_RATE   <- 2

minigame <- Ware_MinigameData
({
	name		   = "Upgrade"
	author		   = ["tilderain"]
	description    = ["Upgrade your damage!", "Upgrade and resist the damage!", "Upgrade your firing speed!"][Ware_MinigameMode]
	modes          = 3
	duration	   = Ware_MinigameMode != 1 ? 6.5 : 8.5
	location       = "warehouse"
	music		   = Ware_MinigameMode != 1 ? "upgrademusic" : "upgraderesist"
	custom_overlay = ["upgrade_damage", "upgrade_resist", "upgrade_rate"][Ware_MinigameMode]
	fail_on_death  = true
})

killicon_dummy <- null

explode_particle <- "hightower_explosion"

buster_mdl <- "models/bots/demo/bot_sentry_buster.mdl"

snd_explode <- "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
snd_intro <- "mvm/sentrybuster/mvm_sentrybuster_intro.wav"
snd_loop <- "mvm/sentrybuster/mvm_sentrybuster_loop.wav"
snd_spin <- "mvm/sentrybuster/mvm_sentrybuster_spin.wav"

upgradestations <- []

give_loadout <- true

function OnPrecache()
{
	for (local i = 1; i <= 11; i++)
		PrecacheSound(format("vo/mvm_get_to_upgrade%02d.mp3", i))

	for (local i = 1; i <= 7; i++)
		PrecacheSound(format( "vo/mvm_sentry_buster_alerts%02d.mp3", i))
		
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/upgrade_damage")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/upgrade_resist")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/upgrade_rate")

	PrecacheModel(buster_mdl)

	PrecacheSound(snd_explode)
	PrecacheSound(snd_intro)
	PrecacheSound(snd_loop)
	PrecacheSound(snd_spin)

	PrecacheParticle(explode_particle)

	Ware_PrecacheMinigameMusic("upgrademusic", false)
	Ware_PrecacheMinigameMusic("upgraderesist", false)
}

function OnTeleport(players)
{
	local red_players = []
	local blue_players = []
	foreach (player in players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			red_players.append(player)
		else if (team == TF_TEAM_BLUE)
			blue_players.append(player)
	}
	
	Ware_TeleportPlayersRow(red_players,
		Ware_MinigameLocation.center + Vector(45, 500.0, 0),
		QAngle(0, 270, 0),
		500.0,
		45.0, 50.0)
	Ware_TeleportPlayersRow(blue_players,
		Ware_MinigameLocation.center + Vector(45, -500.0, 0),
		QAngle(0, 90, 0),
		500.0,
		45.0, 50.0)
}

function OnStart()
{
	ForceEnableUpgrades(2)
	// this is needed to prevent server crash with item whitelist enabled
	Ware_TogglePlayerLoadouts(true)
	
	killicon_dummy = Ware_CreateEntity("handle_dummy")
	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, false)
		player.SetCurrency(1500)
		local minidata = Ware_GetPlayerMiniData(player)
		minidata.last_hit <- -2
		minidata.cur_hit <- -1
	}

	local x = Ware_MinigameLocation.center.x
	local y = Ware_MinigameLocation.center.y
	local z = Ware_MinigameLocation.center.z
	SpawnUpgradeStation(x, y, z, 270)
	SpawnUpgradeSign(x+100, y-60, z+120, 270)
	SpawnUpgradeStation(x, y, z, 90)
	SpawnUpgradeSign(x-100, y+60, z+120, 90)

	SpawnFuncUpgrade(Ware_MinigameLocation.center)

	if (Ware_MinigameMode == MISSION_DAMAGE || Ware_MinigameMode == MISSION_RATE)
	{
		Ware_PlaySoundOnAllClients(format("vo/mvm_get_to_upgrade%02d.mp3", RandomInt(1,11)))
	}
	else if (Ware_MinigameMode == MISSION_RESIST)
	{
		Ware_PlaySoundOnAllClients(format("vo/mvm_sentry_buster_alerts%02d.mp3", RandomInt(1,3)))
		Ware_PlaySoundOnAllClients(snd_intro, 0.25)
		Ware_PlaySoundOnAllClients(snd_loop, 0.20)
		
		CreateTimer(@() Ware_PlaySoundOnAllClients(snd_loop, 1.0, 100, SND_STOP), 5.5)
		CreateTimer(@() Ware_PlaySoundOnAllClients(snd_spin, 0.35), 5.5)

   		local bot = Ware_SpawnEntity("prop_dynamic_override",
   		{
			targetname  = "buster"
   	  		origin      = Ware_MinigameLocation.center + Vector(0,0,150)
			modelscale  = 2
			health      = INT_MAX
   		})
		// set the model after spawning to avoid precaching gibs (don't need those)
		bot.SetModelSimple(buster_mdl)
		bot.SetSolid(SOLID_BBOX)
		bot.SetSize(bot.GetBoundingMins(), bot.GetBoundingMaxs())
		bot.AcceptInput("SetAnimation", "Stand_MELEE", null, null)
		//bot.SetMoveType(MOVETYPE_NONE, 0)
		bot.ValidateScriptScope()

		Ware_CreateTimer(@() SetExplodeAnim(bot), 5.5)
		Ware_CreateTimer(@() ExplodeBot(bot), 7.5)
	}
	
	Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Original")

	// prevent ui lingering
	local end_delay = Ware_MinigameMode != 1 ? 0.25 : 1.5
	Ware_CreateTimer(function() 
	{
		foreach (station in upgradestations)
			station.SetAbsOrigin(vec3_zero)
	}, Ware_GetMinigameRemainingTime() - end_delay)
}

function SetExplodeAnim(bot)
{
	bot.AcceptInput("SetAnimation", "sentry_buster_preexplode", null, null)
}

function ExplodeBot(bot)
{
	Ware_PlaySoundOnAllClients(snd_explode)
	local particle = Ware_SpawnEntity("info_particle_system",
	{
		origin = bot.GetOrigin()
		effect_name = explode_particle,
		start_active = true
	})
	bot.Kill()
	SpawnHurt(DMG_BLAST, "megaton")
}

function SpawnHurt(type, kill_icon)
{
	local hurt = Ware_SpawnEntity("trigger_hurt",
	{
		classname  = kill_icon
		origin     = Ware_MinigameLocation.center
		damage     = 400
		damagetype = type
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_BBOX)
	hurt.SetSize(Vector(-3000, -3000, -3000), Vector(3000, 3000, 3000))
}

function OnTakeDamage(params)
{
	if (params.const_entity.IsPlayer())
	{
		local attacker = params.attacker
		local inflictor = params.inflictor
		
		if (attacker && !attacker.IsPlayer())
		{
			// trigger_hurt overrides the kill icon, so using a dummy entity as a workaround
			killicon_dummy.KeyValueFromString("classname", attacker.GetClassname())
			params.inflictor = killicon_dummy	
			params.attacker = killicon_dummy
		}
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (Ware_MinigameMode == MISSION_RESIST)
		{
			if (player.IsAlive())
				Ware_PassPlayer(player, true)
		}
	}
}
	
function OnCleanup()
{
	give_loadout = false
	
	// WARNING: the order of operations here is important or the server will CRASH
	// upgrades must be removed first, then upgrades disabled, then loadouts re-enabled in that order
	
	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, true)
		player.SetCurrency(0)
	}
	
	ForceEnableUpgrades(0)	
	Ware_TogglePlayerLoadouts(false)

	Ware_PlaySoundOnAllClients(snd_loop, 1.0, 100, SND_STOP)
}

function OnPlayerInventory(player)
{
	if (!give_loadout)
		return
	
	Ware_SetPlayerLoadout(player, TF_CLASS_SOLDIER, "Original")
	
	if (Ware_MinigameMode != MISSION_RESIST)
	{
		foreach (player in Ware_MinigamePlayers)
		{
			if (!player.IsAlive())
				continue
		
			local weapon = player.GetActiveWeapon()		
			if (Ware_MinigameMode == MISSION_DAMAGE)
			{
				if (player.InCond(TF_COND_CRITBOOSTED_USER_BUFF))
				{
					Ware_PassPlayer(player, true)
				}
				else
				{
					if (weapon && weapon.GetSlot() == TF_SLOT_PRIMARY && weapon.GetAttribute("damage bonus", 1.0) > 1.5)
					{
						Ware_PassPlayer(player, true)
					}
				}
			}
			else if (Ware_MinigameMode == MISSION_RATE)
			{
				if (weapon && weapon.GetSlot() == TF_SLOT_PRIMARY && weapon.GetAttribute("fire rate bonus", 1.0) < 0.7)
				{
					Ware_PassPlayer(player, true)
				}				
			}
		}
	}
}

function SpawnUpgradeStation(x, y, z, angle)
{
	local pos = Vector(x, y, z)
	local ang = Vector(0, angle, 0)

	Ware_SpawnEntity("prop_dynamic",
	{
		model	= "models/props_mvm/mvm_upgrade_center.mdl"
		origin	= pos
		angles	= ang
		solid	= SOLID_NONE
		disableshadows  = true
	})

	Ware_SpawnEntity("prop_dynamic",
	{
		model	= "models/props_mvm/mvm_upgrade_tools.mdl"
		origin	= pos
		angles	= ang
		disableshadows  = true
	})

}

function SpawnFuncUpgrade(pos)
{
	local entity = Ware_SpawnEntity("func_upgradestation",
	{
		classname = "ware_upgradestation" // don't preserve on restart
		origin = pos
	})
	entity.SetSolid(SOLID_BBOX)
	entity.SetSize(Vector(-150, -150, -150), Vector(150, 150, 150))
	upgradestations.append(entity)
}

function SpawnUpgradeSign(x, y, z, angle)
{
	local pos = Vector(x, y, z)
	local ang = Vector(0, angle, 0)

	Ware_SpawnEntity("prop_dynamic",
	{
		targetname   = "vscript_upgrade_station"
		model	     = "models/props_mvm/mvm_upgrade_sign.mdl"
		origin	     = pos
		angles	     = ang
		solid	     = SOLID_NONE
		DefaultAnim  = "idle"
		disableshadows = true
	})
}