
building_modes <-
[
	[ "Build a Sentry!",              "build_sentry",        OBJ_SENTRYGUN  ],
	[ "Build a Dispenser!",           "build_dispenser",     OBJ_DISPENSER  ],
	[ "Build a Teleporter Entrance!", "build_tele_entrance", OBJ_TELEPORTER ],
	[ "Build a Teleporter Exit!",     "build_tele_exit",     OBJ_TELEPORTER ],
	[ "Build Something!",             "build_something",     null           ],
]
building_mode <- building_modes[Ware_MinigameMode]

minigame <- Ware_MinigameData
({
	name           = "Build This"
	author         = ["Gemidyne", "pokemonPasta"]
	modes          = 5
	description    = building_mode[0]
	duration       = 4.0
	music          = "sillytime"
	custom_overlay = building_mode[1]
})

function OnPrecache()
{
	foreach (mode in building_modes)
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/" + building_mode[1])
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_ENGINEER, [ "Construction PDA", "Toolbox"], {}, true)
}

function OnGameEvent_player_builtobject(params)
{
	local building = EntIndexToHScript(params.index)
	if (!building)
		return
	local player = GetPlayerFromUserID(params.userid)
	if (!player)
		return
	
	if (Ware_MinigameMode == 4)
	{
		Ware_PassPlayer(player, true)
	}
	else
	{
		local building_enum = params.object
		if (building_enum == building_mode[2])
		{
			if ((Ware_MinigameMode < 2) ||
				(Ware_MinigameMode == 2 && GetPropInt(building, "m_iObjectMode") != 1) || // tele entrance
				(Ware_MinigameMode == 3 && GetPropInt(building, "m_iObjectMode") == 1) // tele exit
			)
			{
				Ware_PassPlayer(player, true)
			}
		}
	}
	
	Ware_SetPlayerAmmo(player, TF_AMMO_METAL, 0);
}
