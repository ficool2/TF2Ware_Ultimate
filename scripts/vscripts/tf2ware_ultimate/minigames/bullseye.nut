minigame <- Ware_MinigameData
({
	name        = "Bullseye"
	author      = ["Mecha the Slag", "ficool2"]
	description = "Hit the Bullseye 5 times!"
	duration    = 4.0
	music       = "wildwest"
})

prop_model <- "models/tf2ware_ultimate/dummy_sphere.mdl"
sprite_model <- "sprites/tf2ware_ultimate/" + (RandomInt(0, 100) <= 5 ? "bullseye_gabe.vmt" : "bullseye.vmt")

function OnPrecache()
{
	PrecacheModel(prop_model)
	PrecacheSprite("sprites/tf2ware_ultimate/bullseye.vmt")
	PrecacheSprite("sprites/tf2ware_ultimate/bullseye_gabe.vmt")
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Winger")
	
	local pos = Ware_MinigameLocation.center + Vector(0.0, 0.0, RandomFloat(200.0, 400.0))
	local prop = Ware_SpawnEntity("prop_dynamic_override", 
	{
		targetname = "bullseye"
		model      = prop_model
		origin     = pos
		solid      = SOLID_VPHYSICS
		rendermode = kRenderTransColor
		renderamt  = 0
	})
	prop.SetCollisionGroup(TFCOLLISION_GROUP_COMBATOBJECT)
	
	local sprite = Ware_SpawnEntity("env_glow",
	{
		model       = sprite_model
		origin      = pos
		scale       = 0.25
		spawnflags  = 1
		rendermode  = kRenderTransColor
		rendercolor = "255 255 255"
	})	
	SetEntityParent(sprite, prop)
	
	Ware_ShowAnnotation(sprite, "Bullseye!")
	
	foreach (player in Ware_MinigamePlayers)
		Ware_GetPlayerMiniData(player).points <- 0
}

function OnTakeDamage(params)
{
	if (params.const_entity.GetName() == "bullseye")
	{
		local attacker = params.attacker
		if (attacker != null && attacker.IsPlayer())
		{
			local minidata = Ware_GetPlayerMiniData(attacker)
			minidata.points++
			if (minidata.points >= 5)
				Ware_PassPlayer(attacker, true)
		}
	}
}