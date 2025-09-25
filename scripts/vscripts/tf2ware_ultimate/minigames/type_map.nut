minigame <- Ware_MinigameData
({
	name            = "Say the Map"
	author          = ["ficool2"]
	description     = "Say the name of the map!"
	duration        = 7.0
	end_delay       = 0.5
	music           = "whatsthat"
	suicide_on_end  = true
})

map_model <- "models/tf2ware_ultimate/map.mdl"
// needs to match the model
maps <-
[
	// bsp names first, "nice" name second, alternative answers afterwards
	// casing is ignored for answers
	[ [ "arena_badlands", "cp_badlands", "koth_badlands" ], "Badlands", "bad lands", "badland", "badlands" ],
	[ [ "arena_granary", "cp_granary", ], "Granary" ],
	[ [ "arena_lumberyard" ], "Lumberyard", "lumber yard" ],
	[ [ "arena_ravine" ], "Ravine" ],
	[ [ "arena_sawmill", "ctf_sawmill", "koth_sawmill" ], "Sawmill", "saw mill" ],
	[ [ "arena_watchtower" ], "Watchtower", "watch tower" ],
	[ [ "arena_well", "ctf_well", "cp_well" ], "Well" ],
	[ [ "cp_degrootkeep" ], "DeGroot Keep", "degroot", "degrootkeep" ],
	[ [ "cp_dustbowl", "tr_dustbowl" ], "Dustbowl", "dust bowl" ],
	[ [ "cp_egypt_final" ], "Egypt", "egypt final" ],
	[ [ "cp_fastlane" ], "Fastlane", "fast lane" ],
	[ [ "cp_foundry", "ctf_foundry" ], "Foundry" ],
	[ [ "cp_gorge", "ctf_gorge", "cp_5gorge" ], "Gorge", "5gorge", "5 gorge", "five gorge", "George"],
	[ [ "cp_gravelpit" ], "Gravelpit", "gravel pit" ],
	[ [ "cp_junction_final", "cp_junction" ], "Junction", "junction final" ],
	[ [ "cp_mercenarypark" ], "Mercenary Park", "mercenarypark" ],
	[ [ "cp_mountainlab" ], "Mountain Lab", "mountainlab" ],
	[ [ "cp_powerhouse" ], "Powerhouse", "power house" ],
	[ [ "cp_process_final", "cp_process" ], "Process", "process final" ],
	[ [ "cp_steel" ], "Steel" ],
	[ [ "ctf_2fort" ], "2Fort", "teufort", "two fort", "twofort", "teu fort" ],
	[ [ "ctf_doublecross" ], "Double Cross", "doublecross" ],
	[ [ "ctf_turbine" ], "Turbine" ],
	[ [ "pd_watergate" ], "Watergate", "water gate" ],
	[ [ "pl_barnblitz" ], "Barnblitz", "barn blitz" ],
	[ [ "pl_goldrush" ], "Gold Rush", "goldrush" ],
	[ [ "pl_pier" ], "Pier" ],
	[ [ "pl_upward" ], "Upward", "up ward" ],
	[ [ "plr_hightower" ], "Hightower", "high tower" ],
	[ [ "sd_doomsday" ], "Doomsday", "dooms day" ],
	[ [ "tc_hydro" ], "Hydro" ],
]

first <- false
map <- null

function OnPick()
{
	return !Ware_IsSpecialRoundSet("thirdperson") // TODO: why the fuck does this break but not the other typing ones
}

function OnPrecache()
{
	PrecacheModel(map_model)
}

function OnStart()
{
	local map_idx = RandomIndex(maps)
	map = maps[map_idx]
	
	foreach (player in Ware_MinigamePlayers)
	{
		local viewmodel = GetPropEntity(player, "m_hViewModel")
		if (viewmodel)
		{
			SetPropBool(player, "m_Local.m_bDrawViewmodel", false)
			
			local pos = viewmodel.GetOrigin()
			local ang = viewmodel.GetAbsAngles()
			local map = Ware_SpawnEntity("prop_dynamic_override",
			{
				origin         = pos + ang.Forward() * 32.0 + ang.Up() * -4.0
				angles         = ang
				model          = map_model
				skin           = map_idx
				disableshadows = true
			})
			SetEntityParent(map, viewmodel)
			Ware_GetPlayerMiniData(player).map <- map
		}
		else
		{
			// should always have a viewmodel, but if not, just pass them
			Ware_PassPlayer(player, true)
		}
	}
}

function OnEnd()
{
	Ware_ChatPrint(null, "The correct answer was {color}{str}{color} ({str})", 
		COLOR_LIME, map[1], TF_COLOR_DEFAULT, RandomElement(map[0]))
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
		SetPropBool(player, "m_Local.m_bDrawViewmodel", true)
}

function MatchesMap(text)
{
	// match by bsp name
	// try matching with spaces as underscores, eg "ctf 2fort -> ctf_2fort"
	local text2 = ""
	foreach (c in text)
	{
		if (c == ' ')
			text2 += "_"
		else
			text2 += c
	}
	
	foreach (bsp_name in map[0])
	{
		if (text == bsp_name || text2 == bsp_name)
			return true
	}
	
	// match by usual names
	foreach (i, name in map)
	{
		if (i == 0) continue
		if (text == name.tolower())
			return true
	}
	
	return false
}

function OnPlayerSay(player, text)
{	
	if (MatchesMap(text.tolower()))
	{
		if (player.IsAlive())
		{
			Ware_PassPlayer(player, true)
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}said the correct map first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
		return false
	}
	else
	{
		if (Ware_IsPlayerPassed(player) || !player.IsAlive())
			return
		
		Ware_SuicidePlayer(player)
	}
}

function OnPlayerDeath(player, attacker, params)
{
	local data = Ware_GetPlayerMiniData(player)
	if ("map" in data && data.map.IsValid())
		data.map.Kill()
}