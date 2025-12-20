minigame <- Ware_MinigameData
({
	name          = "Jump Rope"
	author        = ["Mecha the Slag", "ficool2"]
	description   = "Jump the rope!"
	duration      = 69.0
	end_delay     = 1.0
	music         = "jumprope"
	location      = "jumprope"
	start_pass    = true
	fail_on_death = true
	thirdperson   = true
})

jumprope_door <- null
jumprope_mins <- null
jumprope_maxs <- null

function OnStart()
{
	Ware_SetGlobalAttribute("no double jump", 1, -1)
	
	jumprope_door = FindByName(null, "jumprope_door")
	MarkForPurge(jumprope_door)
	SetPropFloat(jumprope_door, "m_flSpeed", 100.0)
	EntityAcceptInput(jumprope_door, "Open")
	
	Ware_CreateTimer(@() IncreaseRopeSpeed(), 5.0)
	Ware_CreateTimer(@() CheckPlayerZones(), 5.0)
	
	jumprope_mins = Ware_MinigameLocation.center + Vector(-220, -108, 0)
	jumprope_maxs = Ware_MinigameLocation.center + Vector(220, 108, 128)
}

function IncreaseRopeSpeed()
{
	local speed = GetPropFloat(jumprope_door, "m_flSpeed")
	SetPropFloat(jumprope_door, "m_flSpeed", speed + 25.0)
	
	local input = RandomInt(1, 5) == 1 ? "Close" : "Open"
	if (input == "Open")
		SetPropInt(jumprope_door, "m_toggle_state", 1)
	EntityAcceptInput(jumprope_door, input)
	
	return 5.0
}

function CheckPlayerZones()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		local origin = player.GetOrigin()
		local mins = player.GetPlayerMins()
		local maxs = player.GetPlayerMaxs()
		
		local health = player.GetHealth()
		local max_health = player.GetMaxHealth()
		local ratio = max_health / 125.0
		
		if (player.GetPlayerClass() == TF_CLASS_MEDIC)
			ratio *= 1.25
		
		if (IntersectBoxBox(origin + mins, origin + maxs, jumprope_mins, jumprope_maxs))
			HealPlayer(player, 10.0 * ratio)
		else
			HealPlayer(player, -10.0 * ratio)
	}
	
	return 1.0
}

function OnEnd()
{
	EntityAcceptInput(jumprope_door, "Close")
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}