minigame <- Ware_MinigameData
({
	name           = "Grapple Health Kit"
	author         = ["GeeNoVoid"]
	description    = "Grab a Health Kit"
	duration       = 5.5
	music          = "pyoro"
})

prop_model <- "models/tf2ware_ultimate/dummy_sphere.mdl"
healthkit_model <- "models/items/medkit_large.mdl"
parachute_model <- "models/workshop/weapons/c_models/c_paratooper_pack/c_paratrooper_parachute.mdl"

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_UNDEFINED, "Grappling Hook")

	local count = Ware_MinigamePlayers.len()
	for(local i = 0; i < count; i++)
	{
		local pos = Vector(
				RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
				RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
				RandomFloat(Ware_MinigameLocation.center.z + 750.0, Ware_MinigameLocation.center.z + 850.0))
		local ang = QAngle(0, RandomFloat(-180, 180), 0)

		local healthkit = Ware_SpawnEntity("prop_dynamic",
		{
			model       = healthkit_model
			origin      = pos
			angles      = ang
			health      = INT_MAX
			solid       = SOLID_BBOX
		})

		local parachute = Ware_SpawnEntity("prop_dynamic",
		{
			model       = parachute_model
			origin      = healthkit.GetOrigin() + Vector(16, 0, -48)
			defaultanim = "deploy_idle"
			health      = INT_MAX
			solid       = SOLID_BBOX
		})

		local prop = Ware_SpawnEntity("prop_physics_override", 
		{
			model          = prop_model
			origin         = healthkit.GetOrigin()
			massscale      = 0.015
			rendermode     = kRenderTransColor
			renderamt      = 0
			disableshadows = true
		})
		prop.SetCollisionGroup(COLLISION_GROUP_DEBRIS)

		SetEntityParent(healthkit, prop)
		SetEntityParent(parachute, prop)
	}


}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local target = player.GetGrapplingHookTarget()
		if (target && (target.GetModelName() == parachute_model || target.GetModelName() == healthkit_model))
		{
			target.GetMoveParent().Kill()
			Ware_StripPlayer(player, true)
			player.AddCustomAttribute("no_attack", 1, 0.5)
			Ware_PassPlayer(player, true)
		}
	}
}