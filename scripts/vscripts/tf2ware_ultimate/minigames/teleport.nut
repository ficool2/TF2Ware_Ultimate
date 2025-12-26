
Destinations <- {
	// location     max teles
	circlepit       = 12
	circlepit_big   = 12
	sawrun          = 10
	sawrun_micro    = 10
	boxarena        = 12
	beach           = 12
	frogger         = 8
	warehouse       = 12
	// todo: add more...
}

DestinationsArr <- []
TeleDestinations <- {}
local max_teles = 0
foreach(k, v in Destinations)
{
	DestinationsArr.append(k)
	TeleDestinations[k] <- []
	max_teles += v
}

minigame <- Ware_MinigameData
({
	name           = "Teleport"
	author         = "pokemonPasta"
	description    = [
		"Teleport Home!"
		"Teleport To Your Exit!"
	]
	custom_overlay = [
		"teleport_home"
		"teleport_exit"
	]
	duration       = 5.0
	location       = "homerun_contest"
	music          = "settingthescene"
	max_players    = max_teles
	allow_damage   = true
})

function OnTeleport(players)
{
	local center = Ware_MinigameLocation.center + Vector(0, 10000, 0)
	local radius = Ware_MinigamePlayers.len() * 20.0
	center.z = -14390
	Ware_TeleportPlayersCircle(players, center, radius)
}

function OnStart()
{
	foreach(player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerLoadout(player, TF_CLASS_ENGINEER, "Eureka Effect", { "deploy time increased" : 1.0, "cannot pick up buildings" : 1.0 })
		Ware_ChatPrint(player, "{color}HINT: {color}Press R to open the teleport menu.", COLOR_GREEN, TF_COLOR_DEFAULT)
		Ware_SetPlayerMission(player, RandomInt(0,1))
		
		local assigned = false
		local destination = RandomElement(DestinationsArr)

		while(!assigned){
			if(TeleDestinations[destination].len() < Destinations[destination])
				assigned = true
			else
				destination = RandomElement(DestinationsArr)
		}
	
		Ware_GetPlayerMiniData(player).destination <- Ware_Location[destination]
		
		local teleporter = Ware_SpawnEntity("obj_teleporter",{
			TeamNum        = player.GetTeam()
			defaultupgrade = 2
			SolidToPlayer  = 0
			teleporterType = 2
		})
		
		EntityAcceptInput(teleporter, "SetBuilder", "", player) // set builder of teleporter to player so they can teleport to it
		
		TeleDestinations[destination].append(teleporter)
	}
	
	foreach(destination, teleporters in TeleDestinations)
		if(teleporters.len() > 0)
			Ware_Location[destination].Teleport(teleporters) // will this work? surely
}

function OnUpdate()
{
	foreach(player in Ware_MinigamePlayers)
	{
		local destination = Ware_GetPlayerMission(player) == 0 ? Ware_MinigameHomeLocation : Ware_GetPlayerMiniData(player).destination
		local mins = destination.mins
		local maxs = destination.maxs
		local origin = player.GetOrigin()
		if (mins.x < origin.x &&
			mins.y < origin.y &&
			mins.z < origin.z &&
			maxs.x > origin.x &&
			maxs.y > origin.y &&
			maxs.z > origin.z
		)
			Ware_PassPlayer(player, true)
	}
}

function OnTakeDamage(params)
{
	local weapon = params.weapon
	if(weapon && weapon.IsMeleeWeapon())
		params.damage = 0.0
}