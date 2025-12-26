minigame <- Ware_MinigameData
({
	name          = "Taunt Kill"
	author        = ["TonyBaretta", "ficool2"]
	description   = "Taunt Kill!"
	duration      = 21.0
	end_delay     = 0.6
	location      = "boxarena"
	music         = "morning"
	min_players   = 2
	max_scale     = 1.5
	allow_damage  = true
	friendly_fire = false
	collisions    = true
})

suicide_callback <- null

// some taunts don't friendlyfire
function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnTeleport(players)
{
	local center = Ware_MinigameLocation.center
	local radius = Ware_MinigameLocation.radius
	if (players.len() > 50)
	{
		local end = players.len() / 2
		local players1 = players.slice(0, end)
		local players2 = players.slice(end)
		Ware_TeleportPlayersCircle(players1, center, radius)
		Ware_TeleportPlayersCircle(players2, center, radius + 256.0)
	}
	else
	{
		Ware_TeleportPlayersCircle(players, center, radius)
	}
}

function OnStart()
{
	local loadouts =
	[
		[ TF_CLASS_SCOUT,        "Sandman"          	  , @(player) SuicideLine(player, 64.0)    ],
		[ TF_CLASS_SOLDIER,      "Equalizer"        	  , @(player) SuicideSphere(player, 100.0) ],
		[ TF_CLASS_PYRO,         "Flare Gun"        	  , @(player) SuicideLine(player, 64.0)    ],
		[ TF_CLASS_PYRO,         "Rainblower"       	  , @(player) SuicideSphere(player, 100.0) ],
		[ TF_CLASS_PYRO,         "Scorch Shot"      	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_DEMOMAN,      "Eyelander"        	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_HEAVYWEAPONS, "Fists"            	  , @(player) SuicideLine(player, 500.0)   ],
		[ TF_CLASS_ENGINEER,     "Frontier Justice" 	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_ENGINEER,     "Gunslinger"       	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_ENGINEER,     "Taunt: Texan Trickshot" , @(player) SuicideLine(player, 500.0)   ],
		[ TF_CLASS_MEDIC,        "Ubersaw"          	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_SNIPER,       "Huntsman"         	  , @(player) SuicideLine(player, 128.0)   ],
		[ TF_CLASS_SPY,          "Knife"            	  , @(player) SuicideLine(player, 64.0)    ],
	]
	local loadout = RandomElement(loadouts)
	
	Ware_SetGlobalLoadout(loadout[0], loadout[1])
	Ware_SetGlobalAttribute("no_attack", 1, -1)
	
	// simple anti-griefing
	suicide_callback = loadout[2]
}

function OnTakeDamage(params)
{
	return params.const_entity != params.attacker
}

function OnPlayerDeath(player, attacker, params)
{
	if (params.customkill == TF_DMG_CUSTOM_SUICIDE)
		suicide_callback(player)
	else if (attacker && player != attacker)
		Ware_PassPlayer(attacker, true)
}

function OnPlayerDisconnect(player)
{
	suicide_callback(player)
}

function SuicideFilter(player, team)
{
	return player.IsAlive() && player.IsTaunting() && player.GetTeam() != team && GetPropInt(player, "m_nActiveTauntSlot") < 0
}

function SuicideLine(player, radius)
{
	local player_origin = player.GetOrigin()
	local player_team = player.GetTeam()
	for (local other; other = FindByClassnameWithin(other, "player", player_origin, radius);)
	{
		if (!SuicideFilter(other, player_team))
			continue
		local start = other.GetCenter()
		local forward = other.EyeAngles().Forward()	
		forward.z = 0.0
		forward.Norm()
		
		local mins = player_origin + other.GetPlayerMins()
		local maxs = player_origin + other.GetPlayerMaxs()
		
		//DebugDrawLine(start, start + forward * radius, 255, 0, 0, false, 5.0)
		//DebugDrawBox(vec3_zero, mins, maxs, 255, 0, 0, 20, 5.0)

		local t = IntersectRayWithBox(start, forward, mins, maxs, 0.0, radius)
		if (t >= 0.0)
			Ware_PassPlayer(other, true)
	}
}

function SuicideSphere(player, radius)
{
	local player_origin = player.GetOrigin()
	local player_team = player.GetTeam()
	for (local other; other = FindByClassnameWithin(other, "player", player_origin, radius);)
	{
		if (!SuicideFilter(other, player_team))
			continue
		Ware_PassPlayer(other, true)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() <= 1
}
