treasures <-
[
	["beach", "Octopus", "octopus", "unusual_bubbles", "models/player/items/pyro/treasure_hat_oct.mdl",
		[
			Vector(2170.51, -94.5874, -271.395)
			Vector(2976.74, 174.691, -399.494)
			Vector(466.239, -977.024, -71.8184)
			Vector(2312.92, 945.426, -200.269)
			Vector(3268.91, -522.682, -415.319)
			Vector(3547.32, 773.357, -403.642)
			Vector(2184.68, -295.731, -332.245)
			Vector(2460.42, -124.22, -332.857)
		],
	],
	["manor", "Secret Diary", "secret_diary", "superrare_beams1", "models/player/items/all_class/hwn_spellbook_diary.mdl",
		[
			Vector(-2575.09, -115.668, 209.037)
			Vector(-2355.32, 649.124, -175.273)
			Vector(-1496.04, -793.31, -91.2257)
			Vector(-2271.69, -784.205, -106.629)
			Vector(-180.276, 669.594, -206.969)
			Vector(-3459.82, 356.595, -206.969)
		],
	],	
]

treasure <- RandomElement(treasures)

minigame <- Ware_MinigameData
({
	name           = "Treasure Hunt"
	author         = ["TonyBaretta", "ficool2"]
	description    = format("Find the %s!", treasure[1])
	duration       = 25.0
	max_scale      = 1.0
	music          = "undergroundbros"
	location       = treasure[0]
	custom_overlay = "treasure_hunt_" + treasure[2]
})

debug_spawns <- false

find_sound <- "MatchMaking.MedalClickRare"

function OnPrecache()
{
	foreach (treasure in treasures)
	{
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/treasure_hunt_" + treasure[2])
		PrecacheModel(treasure[4])
	}
	
	PrecacheScriptSound(find_sound)
}

function OnTeleport(players)
{
	if (Ware_MinigameLocation.name == "beach")
	{
		Ware_MinigameLocation.Teleport(players)
	}
	else if (Ware_MinigameLocation.name == "manor")
	{
		local spacing_x = 64.0, spacing_y = 64.0
		if (players.len() > 40)
		{
			spacing_x = 32.0
			spacing_y = 48.0
		}
		
		Ware_TeleportPlayersRow(players,
			Ware_MinigameLocation.center,
			QAngle(0, 180, 0),
			400.0,
			spacing_x, spacing_y)
	}
}

function OnStart()
{
	foreach (player in Ware_MinigamePlayers)
		Ware_GivePlayerWeapon(player, "Grappling Hook")
	
	local position_list = treasure[5]
	if (!debug_spawns)
	{
		local origin = Ware_MinigameLocation.center + RandomElement(position_list)
		local prop = Ware_SpawnEntity("prop_dynamic",
		{
			origin     = origin
			model      = treasure[4]
			modelscale = 2.0
		})
		
		local particle = Ware_SpawnEntity("info_particle_system",
		{
			origin       = origin
			effect_name  = treasure[3]
			start_active = true
		})
		
		local trigger = Ware_SpawnEntity("trigger_multiple",
		{
			origin     = origin
			spawnflags = SF_TRIGGER_ALLOW_CLIENTS
		});		
		trigger.SetSolid(SOLID_BBOX)
		trigger.SetSize(prop.GetBoundingMins(), prop.GetBoundingMaxs())
		trigger.ValidateScriptScope()
		trigger.GetScriptScope().OnStartTouch <- OnTouchTreasure
		trigger.ConnectOutput("OnStartTouch", "OnStartTouch")
	}
	else
	{
		foreach (position in position_list)
		{
			Ware_SpawnEntity("prop_dynamic",
			{
				origin     = Ware_MinigameLocation.center + position
				model      = treasure[4]
				modelscale = 2.0
			})
		}
	}	
}

function OnTouchTreasure()
{
	local player = activator
	if (player)
	{
		Ware_TeleportPlayer(player, Ware_Location.beach.center, ang_zero, vec3_zero)
		Ware_ShowScreenOverlay(player, null)
		Ware_CreateTimer(function()
		{
			if (player)
			{
				player.EmitSound(Ware_MinigameScope.find_sound)
				Ware_PassPlayer(player, true)
				Ware_StripPlayer(player, true)
			}
		}, 0.1)
	}
}