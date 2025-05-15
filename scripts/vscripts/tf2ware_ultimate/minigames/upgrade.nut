mission <- RandomInt(0, 1)
damage_mode <- RandomInt(0, 1)
if(mission == 0 && damage_mode == 1)
	mission = 2
minigame <- Ware_MinigameData
({
	name		   = "Upgrade"
	author		 = ["tilderain"]
	description	=
	[
		"Upgrade and do over 125 damage!"
		"Upgrade and resist the damage!"
		"Upgrade firing speed and hit faster than 0.8s!"
	]
	duration	   = 8.5
	music		  = (mission != 1) ? "upgrademusic" : "upgraderesist"
	custom_overlay =
	[
		"upgrade_damage"
		"upgrade_resist"
		"upgrade_rate"
	]
	fail_on_death = true
})

MISSION_DAMAGE <- 0
MISSION_RESIST <- 1
MISSION_RATE <- 2

killicon_dummy <- null

bot_data <-
{
	[TF_CLASS_SCOUT]        = ["models/bots/scout/bot_scout.mdl", "Scout.MVM_CritDeath"],
	[TF_CLASS_SNIPER]       = ["models/bots/sniper/bot_sniper.mdl", "Sniper.MVM_CritDeath"],
	[TF_CLASS_SOLDIER]      = ["models/bots/soldier/bot_soldier.mdl", "Soldier.MVM_CritDeath"],
	[TF_CLASS_DEMOMAN]      = ["models/bots/demo/bot_demo.mdl", "Demoman.MVM_CritDeath"],
	[TF_CLASS_MEDIC]        = ["models/bots/medic/bot_medic.mdl", "Medic.MVM_CritDeath"],
	[TF_CLASS_HEAVYWEAPONS] = ["models/bots/heavy/bot_heavy.mdl", "Heavy.MVM_CritDeath"],
	[TF_CLASS_PYRO]         = ["models/bots/pyro/bot_pyro.mdl", "Pyro.MVM_CritDeath"],
	[TF_CLASS_SPY]          = ["models/bots/spy/bot_spy.mdl", "Spy.MVM_CritDeath"],
	[TF_CLASS_ENGINEER]     = ["models/bots/engineer/bot_engineer.mdl", "Engineer.MVM_CritDeath"],
}

explode_particle <- "hightower_explosion"
bot_location <- Ware_MinigameLocation.center + Vector(0,0,150)

buster_mdl <- "models/bots/demo/bot_sentry_buster.mdl"

snd_explode <- "mvm/sentrybuster/mvm_sentrybuster_explode.wav"
snd_intro <- "mvm/sentrybuster/mvm_sentrybuster_intro.wav"
snd_loop <- "mvm/sentrybuster/mvm_sentrybuster_loop.wav"
snd_spin <- "mvm/sentrybuster/mvm_sentrybuster_spin.wav"

func_upgrade <- null

function OnPrecache()
{
	for (local i = 1; i <= 11; i++)
	{
		PrecacheSound(format("vo/mvm_get_to_upgrade%02d.mp3", i))
	}


	for (local i = 1; i <= 11; i++)
	{
		PrecacheSound(format( "vo/mvm_sentry_buster_alerts%02d.mp3", i))
	}

	PrecacheModel(buster_mdl)

	PrecacheSound(snd_explode);
	PrecacheSound(snd_intro);
	PrecacheSound(snd_loop);
	PrecacheSound(snd_spin);

	foreach (data in bot_data)
	{
		PrecacheModel(data[0])
		PrecacheScriptSound(data[1])
	}

	PrecacheParticle(explode_particle)

	Ware_PrecacheMinigameMusic("upgrademusic", false)
	Ware_PrecacheMinigameMusic("upgraderesist", false)
}

function OnStart()
{

	killicon_dummy = Ware_CreateEntity("handle_dummy")
	ForceEnableUpgrades(2)
	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, false)
		player.SetCurrency(1500)
		//Ware_SetPlayerLoadout(player, TF_CLASS_SNIPER, ["Kukri", "SMG", "Sniper Rifle"])
		//player.BleedPlayerEx(8, 10, false, 0)
		//GivePlayerBottle(player)
		local minidata = Ware_GetPlayerMiniData(player)
		minidata.lastHit <- -2
		minidata.curHit <- -1
	}
	local x = Ware_MinigameLocation.center.x
	local y = Ware_MinigameLocation.center.y
	local z = Ware_MinigameLocation.center.z
	SpawnUpgradeStation(x, y, z, 270)
	SpawnUpgradeSign(x+100, y-60, z+120, 270)
	SpawnUpgradeStation(x, y, z, 90)
	SpawnUpgradeSign(x-100, y+60, z+120, 90)

	SpawnFuncUpgrade(Ware_MinigameLocation.center)


	if(mission == MISSION_DAMAGE || mission == MISSION_RATE)
	{
		Ware_PlaySoundOnAllClients(format("vo/mvm_get_to_upgrade%02d.mp3", RandomInt(1,11)))

		local class_idx = TF_CLASS_ENGINEER
   		local bot = Ware_SpawnEntity("prop_dynamic_override",
   		{
			targetname  = "upgrade_robot"
   	  		origin      = bot_location
			modelscale  = 2
			health = INT_MAX
   		})
		// set the model after spawning to avoid precaching gibs (don't need those)
		bot.SetModelSimple(bot_data[class_idx][0])
		bot.SetSolid(SOLID_BBOX)
		bot.SetSize(bot.GetBoundingMins(), bot.GetBoundingMaxs())
		bot.AcceptInput("SetAnimation", "Stand_MELEE", null, null)
		bot.SetMoveType(MOVETYPE_NONE, 0)
		bot.ValidateScriptScope()
		bot.GetScriptScope().hit_sound <- bot_data[class_idx][1]

		Ware_ShowAnnotation(Ware_MinigameLocation.center + Vector(0, 0, 300), "Hit Me!")
	}
	else if (mission == MISSION_RESIST)
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
			health = INT_MAX
   		})
		// set the model after spawning to avoid precaching gibs (don't need those)
		bot.SetModelSimple(buster_mdl)
		bot.SetSolid(SOLID_BBOX)
		bot.SetSize(bot.GetBoundingMins(), bot.GetBoundingMaxs())
		bot.AcceptInput("SetAnimation", "Stand_MELEE", null, null)
		//bot.SetMoveType(MOVETYPE_NONE, 0)
		bot.ValidateScriptScope()

		CreateTimer(@() SetExplodeAnim(bot), 5.5)
		CreateTimer(@() ExplodeBot(bot), 7.5)
	}

	Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Original")

	foreach (player in Ware_MinigamePlayers)
		Ware_SetPlayerMission(player, mission)
	//Prevent ui lingering
	CreateTimer(@() MoveUpgrade(), 8.475)
}

function MoveUpgrade()
{
	if(func_upgrade)
		func_upgrade.SetOrigin(Vector(0,0,0))
}

function SetExplodeAnim(bot)
{
	bot.AcceptInput("SetAnimation", "sentry_buster_preexplode", null, null)
}

function ExplodeBot(bot)
{
	Ware_PlaySoundOnAllClients(snd_explode)
	bot.Kill()
	local particle = Ware_SpawnEntity("info_particle_system",
	{
		origin = bot_location
		effect_name = explode_particle,
		start_active = true
	})
	SpawnHurt(DMG_BLAST, "tf_projectile_rocket")
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

function CheckWeaponFire(weapon, player)
{
	if(mission == MISSION_DAMAGE)
	{
		firetime <- GetPropFloat(weapon, "m_flLastFireTime")
		if(firetime < 1) return
		local minidata = Ware_GetPlayerMiniData(player)
		if(minidata.curHit != firetime)
		{
			minidata.lastHit <- minidata.curHit
			minidata.curHit <- firetime
			local dmg = weapon.GetAttribute("damage bonus", 1)
			//Ware_ChatPrint(null, "{int}", dmg)
			if(dmg > 1.49 || player.InCond(TF_COND_CRITBOOSTED_USER_BUFF))
			    Ware_PassPlayer(player, true)
		}
	}
	else if(mission == MISSION_RATE)
	{
		firetime <- GetPropFloat(weapon, "m_flLastFireTime")
		if(firetime < 1) return
		local minidata = Ware_GetPlayerMiniData(player)
		if(minidata.curHit != firetime)
		{
			minidata.lastHit <- minidata.curHit
			minidata.curHit <- firetime
			//Ware_ChatPrint(null, "{int}", GetPropFloat(weapon, "m_flLastFireTime"))

			local diff = minidata.curHit - minidata.lastHit
			Ware_ShowText(player, CHANNEL_MINIGAME, format("Last hit: %.1fs", diff), Ware_GetMinigameRemainingTime())
			if(diff < 0.79)
        		Ware_PassPlayer(player, true)
		}
	}
}

function OnUpdate()
{
	foreach(player in Ware_MinigamePlayers)
	{
		local weapon = player.GetActiveWeapon()
		if (weapon && weapon.GetSlot() == TF_SLOT_PRIMARY)
			CheckWeaponFire(weapon, player)
	}
}

function OnTakeDamage(params)
{
	if (params.const_entity.GetName() == "upgrade_robot")
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer() && mission == MISSION_DAMAGE)
		{
			if(attacker.InCond(TF_COND_CRITBOOSTED_USER_BUFF))
				params.damage *= 3
			Ware_PlaySoundOnClient(attacker, params.const_entity.GetScriptScope().hit_sound)
			Ware_ShowText(attacker, CHANNEL_MINIGAME, format("Damage: %.1f", params.damage), Ware_GetMinigameRemainingTime())
		//	if(params.damage > 125)
        //		Ware_PassPlayer(attacker, true)
		}
		/*if (attacker && attacker.IsPlayer() && mission == MISSION_RATE)
		{
			Ware_PlaySoundOnClient(attacker, params.const_entity.GetScriptScope().hit_sound)
			local minidata = Ware_GetPlayerMiniData(attacker)

			minidata.lastHit <- minidata.curHit
			minidata.curHit <- Ware_GetMinigameTime()
			
			local diff = minidata.curHit - minidata.lastHit
			Ware_ShowText(attacker, CHANNEL_MINIGAME, format("Last hit: %.1fs", diff), Ware_GetMinigameRemainingTime())
			if(diff < 0.79)
        		Ware_PassPlayer(attacker, true)
		}*/

		return false
	}

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
		player.GrantOrRemoveAllUpgrades(true, false)
	}

	ResetCanteens()

	if(mission == MISSION_RESIST)
	{
		local survivors = Ware_GetAlivePlayers()
		foreach (player in survivors)
		{
			Ware_PassPlayer(player, true)
		}
	}
}
	
function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.GrantOrRemoveAllUpgrades(true, false)
		player.SetCurrency(0)
	}


	ForceEnableUpgrades(0)

	local ent = null
	//Needs to be removed manually
	while(ent = Entities.FindByClassname(ent, "func_upgradestation"))
    {
        ent.Kill()
    }

	Ware_PlaySoundOnAllClients(snd_loop, 1.0, 100, SND_STOP)
}

function OnPlayerInventory(player)
{
	Ware_SetPlayerLoadout(player, TF_CLASS_SOLDIER, "Original")
}

//from https://github.com/Lazyneer/MvM-Upgrades-Vscript/blob/master/scripts/vscripts/mapspawn.nut
//Spawns a full upgrade station, only right angles allowed
function SpawnUpgradeStation(x, y, z, angle)
{
	local pos = Vector(x, y, z)
	local ang = Vector(0, angle, 0)

	Ware_SpawnEntity("prop_dynamic",
	{
		targetname  = "vscript_upgrade_station",
		model	   = "models/props_mvm/mvm_upgrade_center.mdl",
		origin	  = pos,
		angles	  = ang,
		disableshadows  = 1,
		solid	   = 0
	})

	Ware_SpawnEntity("prop_dynamic",
	{
		targetname  = "vscript_upgrade_station",
		model	   = "models/props_mvm/mvm_upgrade_tools.mdl",
		origin	  = pos,
		angles	  = ang,
		disableshadows  = 1
	})

}

function SpawnFuncUpgrade(pos)
{
	local mins = Vector(-150, -150, -150)
	local maxs = Vector(150, 150, 150)

	func_upgrade = Ware_SpawnEntity("func_upgradestation",
	{
		targetname  = "vscript_upgrade_station",
		origin	  = pos
	})

	func_upgrade.KeyValueFromInt("solid", 2)
	func_upgrade.KeyValueFromString("mins", mins.x.tostring() + " " + mins.y.tostring() + " " + mins.z.tostring())
	func_upgrade.KeyValueFromString("maxs", maxs.x.tostring() + " " + maxs.y.tostring() + " " + maxs.z.tostring())
}


//Spawns a sign, works with any rotation
function SpawnUpgradeSign(x, y, z, angle, height = 128)
{
	local pos = Vector(x, y, z)
	local ang = Vector(0, angle, 0)
	local size = 32
	local offset = 32

	Ware_SpawnEntity("prop_dynamic",
	{
		targetname  = "vscript_upgrade_station",
		model	   = "models/props_mvm/mvm_upgrade_sign.mdl",
		origin	  = pos,
		angles	  = ang,
		disableshadows  = 1,
		solid	   = 0,
		DefaultAnim = "idle"
	})


}

function ResetCanteens()
{
    local ent = null
    while(ent = Entities.FindByClassname(ent, "tf_powerup_bottle"))
    {
        NetProps.SetPropInt(ent, "m_usNumCharges", 0)
        NetProps.SetPropBool(ent, "m_bActive", false)
        ent.RemoveAttribute("critboost")
        ent.RemoveAttribute("ubercharge")
        ent.RemoveAttribute("building instant upgrade")
        ent.RemoveAttribute("refill_ammo")
        ent.RemoveAttribute("recall")
    }
}

//Doesnt work
function GivePlayerBottle(player)
{


	local weapon = Ware_CreateEntity("tf_powerup_bottle")
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 489)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	SetPropBool(weapon, "m_bValidatedAttachedEntity", true)

	NetProps.SetPropInt(weapon, "m_usNumCharges", 1101)
	NetProps.SetPropBool(weapon, "m_bActive", true)

    weapon.AddAttribute("critboost", 1, -1)

	weapon.SetTeam(player.GetTeam())

	weapon.SetOwner(player)

	weapon.DispatchSpawn()

	player.Weapon_Equip(weapon)
}