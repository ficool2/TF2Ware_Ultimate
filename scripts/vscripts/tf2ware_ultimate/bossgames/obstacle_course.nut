minigame <- Ware_MinigameData
({
	name           = "Obstacle Course"
	author         = ["Mecha the Slag", "ficool2"]
	description    = "Get to the end!"
	duration       = 49.0
	end_delay      = 1.0
	location       = "obstaclecourse"
	music          = "steadynow"
	start_pass     = false
	start_freeze   = 0.5
	custom_overlay = "get_end"
	convars = 
	{
		tf_avoidteammates = 1
		tf_avoidteammates_pushaway = 1
	}
})

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_HEAVYWEAPONS)
	
	EntFire("obstaclecourse_door", "SetSpeed", "100", 2.0)
	EntFire("obstaclecourse_door", "Open", "", 2.0)
	
	EntFire("obstaclecourse_rotate", "Unlock")
	EntFire("obstaclecourse_rotate", "Open")
}

function OnUpdate()
{
	local threshold = Ware_MinigameLocation.center.y + 3950.0
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsAlive() && player.GetOrigin().y > threshold)
			Ware_PassPlayer(player, true)
	}
}

function OnEnd()
{
	EntFire("obstaclecourse_door", "SetSpeed", "2000")
	EntFire("obstaclecourse_door", "Close")
	
	EntFire("obstaclecourse_rotate", "Close")
	EntFire("obstaclecourse_rotate", "Lock")
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}