
minigame <- Ware_MinigameData
({
	name           = "Melee Arena"
	author         = ["TonyBaretta", "ficool2"]
	description    = "Survive!"
	location       = "circlepit"
	duration       = 10.9
	end_delay      = 1.0
	music          = "keepitup"
	custom_overlay = "survive"
	min_players    = 2
	// removed: don't put it multiple times in rotation
	//modes          = 5
	// small players fly into the air and i have no idea why - pokepasta
	max_scale      = 1.0
	start_pass     = true
	start_freeze   = 0.5
	allow_damage   = true
	fail_on_death  = true
	collisions     = Ware_Players.len() <= 40
	convars =
	{
		tf_avoidteammates = 0
	}
	
})


function OnStart()
{
	local attributes = { "mod see enemy health" : 1.0 }
	local mode = RandomInt(0, 4) // Ware_MinigameMode
	if (mode == 0)
		Ware_SetGlobalLoadout(TF_CLASS_MEDIC, null, attributes)
	else if (mode == 1)
		Ware_SetGlobalLoadout(TF_CLASS_SCOUT, null, attributes)
	else if (mode == 2)
		Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Hot Hand", attributes)
	else if (mode == 3)
		Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, null, attributes)
	else if (mode == 4)
		Ware_SetGlobalLoadout(TF_CLASS_ENGINEER, "Gunslinger", attributes)
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	local attacker = params.attacker
	if (victim.IsPlayer()
		&& attacker && attacker != victim && attacker.IsPlayer())
	{
		local amount = 35.0
		params.damage = amount
		// must add health here instead of 'add_onhit_addhealth' attribute because it doesn't work with friendlyfire
		HealPlayer(attacker, amount)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() <= 1
}