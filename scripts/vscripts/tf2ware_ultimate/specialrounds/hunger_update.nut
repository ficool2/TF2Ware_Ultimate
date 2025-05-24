special_round <- Ware_SpecialRoundData
({
	name = "Hunger Update"
	author = "tilderain"
	description = "Eat to survive!"
	category = ""
})

foods <- []

dmg_tick <- 0

items <-
[
	["Sandvich"              , "eat_plate_sandvich",      "Sandvich",         "models/items/plate.mdl"],
	["Festive Sandvich"      , "eat_plate_sandvich_xmas", "Festive Sandvich", "models/items/plate_sandwich_xmas.mdl"],
	["Robo-Sandvich"         , "eat_plate_sandvich_robo", "Robo-Sandvich",    "models/items/plate_robo_sandwich.mdl"],
	["Dalokohs Bar"          , "eat_plate_chocolate",     "Chocolate Bar",    "models/workshop/weapons/c_models/c_chocolate/plate_chocolate.mdl"],
	["Fishcake"              , "eat_plate_fishcake",      "Fishcake",         "models/workshop/weapons/c_models/c_fishcake/plate_fishcake.mdl"],
	["Buffalo Steak Sandvich", "eat_plate_steak",         "Steak",            "models/workshop/weapons/c_models/c_buffalo_steak/plate_buffalo_steak.mdl"],
	["Second Banana"         , "eat_plate_banana",        "Banana",           "models/items/banana/plate_banana.mdl"],
]

function OnPrecache()
{
	foreach (item in items) 
		PrecacheModel(item[3])
}

function OnStart()
{
	foreach (player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).last_eat <- Time()
}

function OnPlayerSpawn(player)
{
	Ware_GetPlayerSpecialRoundData(player).last_eat <- Time()
}

function OnMedTouch()
{
	if (activator.IsPlayer())
		Ware_GetPlayerSpecialRoundData(activator).last_eat <- Time()
}

function OnUpdate()
{
	foreach (player in Ware_Players)
	{
		if (!player.IsAlive()) 
			continue

		local last_eat = Time() - Ware_GetPlayerSpecialRoundData(player).last_eat 
		
		if (dmg_tick % 60 == 0)
			player.SetHealth(player.GetHealth() - last_eat * 4)
		
		if (player.GetHealth() <= 0)
		{
			Ware_GetPlayerSpecialRoundData(player).last_eat <- Time()
			Ware_SuicidePlayer(player)
		}

		if (foods.len() < 100)
		{	
			if ((dmg_tick % 400 == 0) || (RandomInt(0, 400) == 0))
			{
       			local start = player.EyePosition()
				local forward = player.EyeAngles().Forward()

       			local food = SpawnEntityFromTableSafe("item_healthkit_small",
				{
					origin = start + forward * 360.0
				})

       			food.SetModel(RandomElement(items)[3])
				for (local i = 0; i < 1; i++)
					SetPropIntArray(food, "m_nModelIndexOverrides", 0, i)

				food.SetMoveType(MOVETYPE_FLYGRAVITY, MOVECOLLIDE_FLY_BOUNCE)
				food.SetAbsVelocity(Vector(0, 0, -100))
				food.SetSolid(SOLID_BBOX)

				food.ValidateScriptScope()
				food.GetScriptScope().OnPlayerTouch <- OnMedTouch
				food.ConnectOutput("OnPlayerTouch", "OnPlayerTouch")
				foods.append(food)
    		}
		}	
		else
		{
			local food = foods.remove(0)
			if (food.IsValid())
				food.Kill()
		}
	}

	dmg_tick++
}

