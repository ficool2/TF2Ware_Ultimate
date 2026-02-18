minigame <- Ware_MinigameData
({
	name           = "Basketball"
	author         =  ["TonyBaretta", "ficool2"]
	description    = "Score a Goal!"
	custom_overlay = "score_goal"
	duration       = 7.0
	location       = "ballcourt"
	music          = "march"
	start_pass     = false
	max_scale      = 1.5
})

hoop_sound <- "Halloween.PumpkinDrop"

function OnPrecache()
{
	PrecacheScriptSound(hoop_sound)
}

function OnPick()
{
	// noclip breaks this minigame
	if(Ware_IsSpecialRoundSet("noclip")
		return false

	return true
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, "Grenade Launcher", { "fuse bonus" : 0.6 })
	
	foreach (player in Ware_MinigamePlayers)
	{
		// make grenades pass through
		player.SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
		SetPropInt(player, "m_takedamage", DAMAGE_NO)
	}
	
	EntFire("boss4_door", "Unlock")
	EntFire("boss4_door2", "Unlock")
	EntFire("boss4_door", "Open")
	EntFire("boss4_door2", "Open")
	
	for (local trigger; trigger = FindByName(trigger, "basketball_trigger");)
	{
		MarkForPurge(trigger)
		trigger.ValidateScriptScope()
		trigger.GetScriptScope().OnHoopTouch <- OnHoopTouch
		trigger.ConnectOutput("OnStartTouch", "OnHoopTouch")
	}
}

function OnHoopTouch()
{
	local owner = GetPropEntity(activator, "m_hThrower")
	if (owner)
	{	
		Ware_PlaySoundOnClient(owner, Ware_MinigameScope.hoop_sound)
		Ware_PassPlayer(owner, true)
	}
	
	if(!activator.IsPlayer())
		activator.Kill()
}

function OnUpdate()
{
	for (local grenade; grenade = FindByClassname(grenade, "tf_projectile_pipe");)
	{
		MarkForPurge(grenade)
		grenade.RemoveSolidFlags(FSOLID_TRIGGER)
		grenade.KeyValueFromString("classname", "ware_projectile_pipe")
	}
}

function OnEnd()
{
	EntFire("boss4_door", "Close")
	EntFire("boss4_door2", "Close")
 	EntFire("boss4_door", "Lock")
 	EntFire("boss4_door2", "Lock")
	
	for (local trigger; trigger = FindByName(trigger, "basketball_trigger");)
		trigger.DisconnectOutput("OnStartTouch", "OnHoopTouch")
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		player.SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
		SetPropInt(player, "m_takedamage", DAMAGE_YES)
	}
}
