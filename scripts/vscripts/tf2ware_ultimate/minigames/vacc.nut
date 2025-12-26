minigame <- Ware_MinigameData
({
	name           = "Pop the Vacc"
	author         = ["tilderain"]
	description    = "Vaccinate!"
	duration       = 5.0
	music          = "falling"
	fail_on_death  = true
	start_pass     = true
})

CLASS_SOLDIER <- 0
CLASS_PYRO <- 1
CLASS_HEAVY <- 2

class_names <- ["soldier","pyro","heavy"]
class_idx <- RandomIndex(class_names)
	
team_idx <- RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)

prop <- null
killicon_dummy <- null

minigun_particle <- "muzzle_minigun_constant_core"
flamethrower_particle <- "flamethrower"

function OnStart()
{
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerClass(player, TF_CLASS_MEDIC)
		Ware_StripPlayer(player, false)
		Ware_GivePlayerWeapon(player, "Vaccinator", { "mod weapon blocks healing" : 1, "uber duration bonus" : 2.0 })
		local weapon = player.GetActiveWeapon()
		SetPropFloat(weapon, "m_flChargeLevel", 0.25)

		//Doesn't work
		//SetPropFloat(weapon, "m_flNextPrimaryAttack", 1e100)
	}
	
	local pos = Ware_MinigameLocation.center
	prop = Ware_SpawnEntity("prop_dynamic",
	{
		model       = format("models/player/%s.mdl", class_names[class_idx])
		origin      = pos
		skin        = team_idx - 2
		modelscale  = 2
		defaultanim = RandomBool() ? "taunt_aerobic_A" : "taunt_aerobic_B"
	})
	
	killicon_dummy = Ware_CreateEntity("handle_dummy")

	Ware_ShowAnnotation(pos + Vector(0, 0, 150), "Resist Me!")
	Ware_ChatPrint(null, "{color}HINT:{color} Press R to swap resistance type and right click to activate!", COLOR_GREEN, TF_COLOR_DEFAULT)
	
	local name = class_names[class_idx] + format(".Taunts%02d", RandomInt(1,19))

	if(class_idx == CLASS_PYRO )
		name = "Pyro.BattleCry0" + RandomInt(1,2)

	prop.EmitSound(name)

	if(class_idx == CLASS_SOLDIER)
	{
		Ware_CreateTimer(@() SpawnRockets(), 1.8)
		Ware_CreateTimer(@() SpawnHurt(DMG_BLAST, "tf_projectile_rocket"), 3.5)
	}

	else if(class_idx == CLASS_PYRO)
		Ware_CreateTimer(@() SpawnFires(), 3.5)
	else
		Ware_CreateTimer(@() SpawnGuns(), 3.5)
}

function OnPrecache()
{
	PrecacheParticle(flamethrower_particle)
	PrecacheParticle(minigun_particle)
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
function SpawnRockets()
{
	local spawner = Ware_SpawnEntity("tf_point_weapon_mimic", 
	{
		origin     = Ware_MinigameLocation.center
		WeaponType = class_idx
		SpeedMin   = 500
		SpeedMax   = 500
		Damage     = 0
		Crits      = true
		angles     = QAngle(90, 0, 0)
		SplashRadius = 10000
	})
	spawner.SetTeam(TEAM_SPECTATOR)

	foreach (player in Ware_MinigamePlayers)
	{
		local down = QAngle(90, 0, 0)
		local dir = down.Forward() + down.Left() * RandomFloat(-0.4, 0.4) + down.Up() * RandomFloat(-0.4, 0.4)
		dir.Norm()
		spawner.SetForwardVector(dir)
		
		local pos = player.GetOrigin()
		spawner.SetOrigin(player.GetOrigin() + dir * RandomFloat(-900.0, -1300.0))
	
		spawner.AcceptInput("FireOnce", "", null, null)
		
		local rocket = FindByClassname(null, "tf_projectile_rocket")
		if (rocket != null)
		{
			MarkForPurge(rocket)
			rocket.SetOwner(player)
			rocket.SetTeam(TEAM_SPECTATOR)
			rocket.KeyValueFromString("classname", "ware_projectile")
		}
	}
}

function SpawnParticle(particle)
{
	local particle = Ware_SpawnEntity("info_particle_system",
	{
		origin       = Ware_MinigameLocation.center + Vector(0,0,50)
		angles       = QAngle(1, 0, 0)
		effect_name  = particle
		start_active = true
	})
}

function SpawnFires()
{
	SpawnParticle(flamethrower_particle)

	prop.EmitSound("Weapon_FlameThrower.FireStart")
	SpawnHurt(DMG_BURN, "flamethrower")
}

function SpawnGuns()
{
	SpawnParticle(minigun_particle)

	prop.EmitSound("Weapon_Minigun.FireCrit")

	SpawnHurt(DMG_BULLET, "minigun")
}

function OnEnd()
{
	prop.StopSound("Weapon_Minigun.FireCrit")
	prop.StopSound("Weapon_FlameThrower.FireStart")
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
		
		if (inflictor && inflictor.GetClassname() == "ware_projectile")
		{
			params.weapon = null
			// prevents server crash because of attacker not being a player
			SetPropEntity(inflictor, "m_hLauncher", null)
		}
	}
}
