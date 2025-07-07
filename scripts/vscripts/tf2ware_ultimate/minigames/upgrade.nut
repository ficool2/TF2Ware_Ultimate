MISSION_DAMAGE <- 0
MISSION_RESIST <- 1

minigame <- Ware_MinigameData
({
	name		   = "Upgrade"
	author		   = ["tilderain"]
	description    = ["Upgrade!", "Upgrade and resist the damage!"][Ware_MinigameMode]
	modes          = 2
	duration	   = 10.5
	location       = "warehouse"
	music		   = Ware_MinigameMode != 1 ? "upgrademusic" : "upgraderesist"
	custom_overlay = ["upgrade", "upgrade_resist"][Ware_MinigameMode]
	fail_on_death  = true
})

upgrade_list <- [
	//text                        name                          money   interval     add+1
	["Damage",                    "damage bonus",               400,    0.25,        true],
	["Clip Size",                 "clip size upgrade atomic",   400,    2,           false],
	["Rocket Specialist",         "rocket specialist",          300,    1,           false],
	["Ammo Capacity",             "maxammo primary increased",  250,    0.5,         true],
	["Firing Speed",              "fire rate bonus",            200,    -0.1,		 true],
	["Reload Speed",              "faster reload rate",         250,    -0.2,        true],
	["Health On Kill",            "heal on kill",               200,    25,          false],
 ]

upgrades <- []

killicon_dummy <- null

explode_particle <- "hightower_explosion"

buster_mdl <- "models/bots/demo/bot_sentry_buster.mdl"

snd_explode <- "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
snd_intro <- "mvm/sentrybuster/mvm_sentrybuster_intro.wav"
snd_loop <- "mvm/sentrybuster/mvm_sentrybuster_loop.wav"
snd_spin <- "mvm/sentrybuster/mvm_sentrybuster_spin.wav"

upgradestations <- []

give_loadout <- true

proj_times <- {}

prop <- null

CLASS_PYRO <- 0
CLASS_HEAVY <- 1

class_names <- ["pyro","heavy"]
class_idx <- RandomIndex(class_names)
	
team_idx <- TF_TEAM_BLUE

minigun_particle <- "muzzle_minigun_constant_core"
flamethrower_particle <- "flamethrower_crit_giant_mvm"

fire_sound <- "MVM.GiantPyro_FlameStart"
gun_sound <- "MVM.GiantHeavyGunFire"

pyro_sound <- "vo/mvm/mght/pyro_mvm_m_BattleCry01.mp3"
heavy_sound <- "vo/mvm/mght/taunts/heavy_mvm_m_Taunts02.mp3"

entrance_sound <- "MVM.GiantHeavyEntrance"

alarm_sound <- "mvm.cpoint_alarm"
windup_sound <- "MVM.GiantHeavyGunWindUp"

function OnPrecache()
{
	for (local i = 1; i <= 11; i++)
	{
		PrecacheSound(format("vo/mvm_get_to_upgrade%02d.mp3", i))
		PrecacheSound(format("vo/mvm_wave_start%02d.mp3", i))
	}


	for (local i = 1; i <= 7; i++)
		PrecacheSound(format( "vo/mvm_sentry_buster_alerts%02d.mp3", i))
		
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/upgrade")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/upgrade_resist")

	PrecacheModel(buster_mdl)

	PrecacheSound(snd_explode)
	PrecacheSound(snd_intro)
	PrecacheSound(snd_loop)
	PrecacheSound(snd_spin)

	PrecacheParticle(explode_particle)

	Ware_PrecacheMinigameMusic("upgrademusic", false)
	Ware_PrecacheMinigameMusic("upgraderesist", false)

	PrecacheSound(pyro_sound)
	PrecacheSound(heavy_sound)
	PrecacheScriptSound(entrance_sound)
	PrecacheScriptSound(alarm_sound)

	/*for (local i = 1; i <= 19; i++)
	{
		local name = "Heavy" + format(".M_MVM_Taunts%02d", i)
		PrecacheScriptSound(name)
	}
	for (local i = 1; i <= 3; i++)
	{
		local name = "Pyro" + format(".M_MVM_BattleCry0%d", i)
		PrecacheScriptSound(name)
	}*/

	PrecacheScriptSound(gun_sound)
	PrecacheScriptSound(fire_sound)
	PrecacheScriptSound(windup_sound)

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

function OnUpdate()
{
	local classname = "tf_projectile_rocket"
	
	local projs = []
	for (local proj; proj = FindByClassname(proj, classname);)
		projs.append(proj)

	local time = Time()
	foreach (proj in projs)
	{
		// At 40 players people are spamming their guns and making the server crash
		if (!(proj in proj_times))
			proj_times[proj] <- time + 0.5
		
		if (proj_times[proj] < time || projs.len() > 5)
			proj.Kill()
	}
}


function OnStart()
{
	ForceEnableUpgrades(2)
	// this is needed to prevent server crash with item whitelist enabled
	Ware_TogglePlayerLoadouts(true)
	
	killicon_dummy = Ware_CreateEntity("handle_dummy")

	local x = Ware_MinigameLocation.center.x
	local y = Ware_MinigameLocation.center.y
	local z = Ware_MinigameLocation.center.z
	SpawnUpgradeStation(x, y, z, 270)
	SpawnUpgradeSign(x+100, y-60, z+120, 270)
	SpawnUpgradeStation(x, y, z, 90)
	SpawnUpgradeSign(x-100, y+60, z+120, 90)

	SpawnFuncUpgrade(Ware_MinigameLocation.center)

	local times = 2

	if (RandomInt(0, 3) == 0) times += 1

	for (local i = 0; i < times; i++)
		upgrades.append(RemoveRandomElement(upgrade_list))

	local currency = 0
	local text = ""
	foreach (up in upgrades)
	{
		local amt = 1
		if (RandomInt(0, 3) == 0) amt += RandomInt(0,2)
		up.append(amt)
		text += amt.tostring() + "x " + up[0] + "\n"
		currency += up[2] * amt
	}

	if (Ware_MinigameMode == MISSION_RESIST)
		currency = 9999

	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, false)
		player.SetCurrency(currency)
		local minidata = Ware_GetPlayerMiniData(player)
		minidata.last_hit <- -2
		minidata.cur_hit <- -1
	}


	if (Ware_MinigameMode == MISSION_DAMAGE)
	{
		Ware_PlaySoundOnAllClients(format("vo/mvm_get_to_upgrade%02d.mp3", RandomInt(1,11)))
		Ware_ShowMinigameText(Ware_Players, text)
	}
	else if (Ware_MinigameMode == MISSION_RESIST)
	{
		local buster = (RandomInt(0,2) == 0)
		if (buster)
		{
			Ware_PlaySoundOnAllClients(format("vo/mvm_sentry_buster_alerts%02d.mp3", RandomInt(1,3)))
			Ware_PlaySoundOnAllClients(snd_intro, 0.25)
			Ware_PlaySoundOnAllClients(snd_loop, 0.20)

			CreateTimer(@() Ware_PlaySoundOnAllClients(snd_loop, 1.0, 100, SND_STOP), 7.5)
			CreateTimer(@() Ware_PlaySoundOnAllClients(snd_spin, 0.35), 7.5)

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

			Ware_CreateTimer(@() SetExplodeAnim(bot), 7.5)
			Ware_CreateTimer(@() ExplodeBot(bot), 9.5)
		}
		else
		{
			
			Ware_PlaySoundOnAllClients(format("vo/mvm_wave_start%02d.mp3", RandomInt(1,11)))
			prop = Ware_SpawnEntity("prop_dynamic",
			{
				model       = format("models/bots/%s/bot_%s.mdl", class_names[class_idx], class_names[class_idx])
				origin      = Ware_MinigameLocation.center + Vector(0,0,150)
				skin        = team_idx - 2
				modelscale  = 2
				defaultanim = "Stand_PRIMARY"
			})
			
			local name = heavy_sound

			if(class_idx == CLASS_PYRO )
				name = pyro_sound

			prop.EmitSound(name)
			prop.EmitSound(entrance_sound)

			Ware_CreateTimer(@() prop.EmitSound(alarm_sound), 3.5)
			Ware_CreateTimer(@() prop.EmitSound(alarm_sound), 6.5)

			

			if(class_idx == CLASS_PYRO)
				Ware_CreateTimer(@() SpawnFires(), 9.5)
			else
			{
				Ware_CreateTimer(@() prop.EmitSound(windup_sound), 8.5)
				Ware_CreateTimer(@() SpawnGuns(), 9.5)
			}

		}
	}

	
	Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Original")

	// prevent ui lingering
	local end_delay = 0.25
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

function SpawnHurt(type, kill_icon)
{
	local hurt = Ware_SpawnEntity("trigger_hurt",
	{
		classname  = kill_icon
		origin     = Ware_MinigameLocation.center
		damage     = 200
		damagetype = type
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	hurt.SetSolid(SOLID_BBOX)
	hurt.SetSize(Vector(-3000, -3000, -3000), Vector(3000, 3000, 3000))
}

function SpawnParticle(particle)
{
	local particle = Ware_SpawnEntity("info_particle_system",
	{
		origin       = Ware_MinigameLocation.center + Vector(0,0,240)
		angles       = QAngle(1, 0, 0)
		effect_name  = particle
		start_active = true
	})
}

function SpawnFires()
{
	SpawnParticle(flamethrower_particle)

	prop.EmitSound(fire_sound)
	SpawnHurt(DMG_BURN, "flamethrower")
}

function SpawnGuns()
{
	SpawnParticle(minigun_particle)

	prop.EmitSound(gun_sound)

	SpawnHurt(DMG_BULLET, "minigun")
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

	if (prop)
	{
		prop.StopSound(gun_sound)
		prop.StopSound(fire_sound)
	}
}
	
function OnCleanup()
{
	// WARNING: the order of operations here is important or the server will CRASH
	// upgrades must be removed first, then upgrades disabled, then loadouts re-enabled in that order
	
	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, false)
		player.SetCurrency(0)
	}
	give_loadout = false
	
	ForceEnableUpgrades(0)	
	Ware_TogglePlayerLoadouts(false)

	Ware_PlaySoundOnAllClients(snd_loop, 1.0, 100, SND_STOP)
}

function fround(val, decimalPoints)
{
	local f = pow(10, decimalPoints) * 1.0;
	local newVal = val * f;
	newVal = floor(newVal + 0.5)
	newVal = (newVal * 1.0) / f;
	return newVal;
}

function OnPlayerInventory(player)
{
	if (!give_loadout)
		return

	if (!player.IsAlive())
		return
	
	Ware_SetPlayerLoadout(player, TF_CLASS_SOLDIER, "Original")
	
	if (Ware_MinigameMode != MISSION_RESIST)
	{
		local weapon = player.GetActiveWeapon()
		if(!weapon) return

		if (Ware_MinigameMode == MISSION_DAMAGE)
		{
			local hits = 0
			foreach (up in upgrades)
			{
				local calc = fround(up[3] * up[5], 1)
				local pass = false
				local atrb = fround(weapon.GetAttribute(up[1], 0.0), 1)
				if (up[4])
					calc += 1
				if (atrb == calc)
				{
					hits += 1
					pass = true
				}
					
				//Ware_ChatPrint(null, "{str}: actual: {int}  expected:{int} PASS:{int}", up[1], atrb, calc, pass)
			}
			if(hits == upgrades.len())
				Ware_PassPlayer(player, true)
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