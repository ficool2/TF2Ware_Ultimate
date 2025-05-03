
arenas <- [
	"rocketjump"
	"rocketjump_micro"
]

minigame <- Ware_MinigameData
({
	name           = "Rocket Jump"
	author         = ["TonyBaretta", "Gemidyne", "ficool2"]
	description    = "Get to the top!"
	duration       = 37.0
	end_delay      = 1.0
	max_scale      = 1.0
	location       = RandomElement(arenas)
	music          = "steadynow"
	custom_overlay = "get_top"
	start_pass     = false
})

first <- true
endzone <- FindByName(null, "plugin_Bossgame1_WinArea")

function OnStart()
{
	if (minigame.location == "rocketjump_micro")
		minigame.duration += 5.0
	
	Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Rocket Launcher", {"blast dmg to self increased": 0.02})
	
	// this gets very difficult with higher timescale so make the train start later
	EntFire("rocketjump_train", "StartForward", "", RemapValClamped(Ware_GetTimeScale(), 1.0, 2.0, 3.0, 10.0))
	
	endzone.ValidateScriptScope()
	endzone.GetScriptScope().OnStartTouch <- OnEndzoneStartTouch.bindenv(this)
	endzone.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function OnReachEnd(player)
{
	Ware_PassPlayer(player, true)
	
	if (first)
	{
		Ware_ChatPrint(null, "{player} {color}made it to the top first in {%.1f} seconds!",
			player, TF_COLOR_DEFAULT, Ware_GetMinigameTime())
		Ware_GiveBonusPoints(player)
		first = false
	}
}

if (minigame.location == "rocketjump")
{
	function OnUpdate()
	{
		local threshold = Ware_MinigameLocation.center.z + 2600.0
		foreach (player in Ware_MinigamePlayers)
		{
			if (player.IsAlive() && GetPropEntity(player, "m_hGroundEntity") != null)
			{
				local origin = player.GetOrigin()
				if (origin.z > threshold)
					OnReachEnd(player)
			}
		}
	}
}

function OnEndzoneStartTouch()
{
	if (activator && activator.IsPlayer())
		OnReachEnd(activator)
}

function OnEnd()
{
	endzone.DisconnectOutput("OnStartTouch", "OnStartTouch")
}

function OnCleanup()
{
	EntFire("rocketjump_train", "TeleportToPathTrack", "boss8_path")
	EntFire("rocketjump_train", "Stop")
}

function OnCheckEnd()
{
	return Ware_GetUnpassedPlayers(true).len() == 0
}