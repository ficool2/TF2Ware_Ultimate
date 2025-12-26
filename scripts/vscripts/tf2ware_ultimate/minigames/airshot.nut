minigame <- Ware_MinigameData
({
    name         = "Airshot"
	description  = "Shoot the Bot!"
    author       = ["Black_Knight", "ficool2"]
    location     = "targetrange"
    duration     = 5.5
	start_freeze = 0.25
	music		 = "urgent"
})

lines <- []
bots <- []
bot_data <-
{
	[TF_CLASS_SCOUT]        = ["models/bots/scout/bot_scout.mdl", "Scout.MVM_Death"],
	[TF_CLASS_SNIPER]       = ["models/bots/sniper/bot_sniper.mdl", "Sniper.MVM_Death"],
	[TF_CLASS_SOLDIER]      = ["models/bots/soldier/bot_soldier.mdl", "Soldier.MVM_Death"],
	[TF_CLASS_DEMOMAN]      = ["models/bots/demo/bot_demo.mdl", "Demoman.MVM_Death"],
	[TF_CLASS_MEDIC]        = ["models/bots/medic/bot_medic.mdl", "Medic.MVM_Death"],
	[TF_CLASS_HEAVYWEAPONS] = ["models/bots/heavy/bot_heavy.mdl", "Heavy.MVM_Death"],
	[TF_CLASS_PYRO]         = ["models/bots/pyro/bot_pyro.mdl", "Pyro.MVM_Death"],
	[TF_CLASS_SPY]          = ["models/bots/spy/bot_spy.mdl", "Spy.MVM_Death"],
	[TF_CLASS_ENGINEER]     = ["models/bots/engineer/bot_engineer.mdl", "Engineer.MVM_Death"],
}

function OnPrecache()
{
	foreach (data in bot_data)
	{
		PrecacheModel(data[0])
		PrecacheScriptSound(data[1])
	}
}

function OnStart()
{   
	lines = clone(Ware_MinigameLocation.lines)
    Ware_CreateTimer(@() SpawnBot( QAngle(0, -90, 0)), 1.8)
	Ware_CreateTimer(@() SpawnBot(QAngle(0, 90, 0)), 2.0)
	Ware_CreateTimer(@() SpawnBot(QAngle(0, RandomBool() ? -90 : 90, 0)), 2.7)
    Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Direct Hit", { "deploy time increased" : 2.5 })
}

function OnTeleport(players)
{
	Ware_MinigameLocation.TeleportTeamsToSides(players, 
		Ware_MinigameLocation.left_mid, Ware_MinigameLocation.right_mid)
}

function SpawnBot(angles)
{
    local line = RemoveRandomElement(lines)
	local origin = Lerp(line[0], line[1], RandomFloat(0.3, 0.7))
	if (origin.y > Ware_MinigameLocation.center.y)
		origin.y -= 64.0
	else
		origin.y += 64.0
	origin.z += 10.0
		
	local class_idx = RandomInt(TF_CLASS_FIRST, TF_CLASS_LAST)
    local bot = Ware_SpawnEntity("prop_dynamic_override",
    {
		targetname  = "airshot_robot"
        origin      = origin
        angles      = angles
    })
	// set the model after spawning to avoid precaching gibs (don't need those)
	bot.SetModelSimple(bot_data[class_idx][0])
	bot.SetSolid(SOLID_BBOX)
	bot.SetSize(bot.GetBoundingMins(), bot.GetBoundingMaxs())
	bot.AcceptInput("SetAnimation", "airwalk_MELEE", null, null)
	bot.SetMoveType(MOVETYPE_FLYGRAVITY, 0)
	bot.SetGravity(0.6)
	bot.SetAbsVelocity(Vector(RandomFloat(-300, 300), 0, RandomFloat(500, 600)))
	bot.SetAngularVelocity(0.0, 135.0, 0.0)
	bot.ValidateScriptScope()
	bot.GetScriptScope().hit_sound <- bot_data[class_idx][1]
	
	local glow = Ware_SpawnEntity("tf_glow",
	{
		target    = "bignet" // don't get deleted
		GlowColor = "255 255 255 255"
	})
	SetPropEntity(glow, "m_hTarget", bot)
				
	bots.append(bot)

}

function OnUpdate()
{
	bots = bots.filter(@(i, bot) bot.IsValid())
	foreach (bot in bots)
	{
		// fall through floor
		if (bot.GetAbsVelocity().z == 0.0)
		{
			bot.SetAbsVelocity(bot.GetAbsVelocity() - Vector(0, 0, 800))
			bot.SetMoveType(MOVETYPE_NOCLIP, 0)
		}
	}
}

function OnTakeDamage(params)
{
	if (params.const_entity.GetName() == "airshot_robot")
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer())
		{
		   Ware_PlaySoundOnClient(attacker, params.const_entity.GetScriptScope().hit_sound)		
           Ware_PassPlayer(attacker, true)
		}

		return false
	}
}