
minigame <- Ware_MinigameData
({
	name            = Ware_MinigameMode == 1 ? "Grapple the Deer" : "Grapple the Cow"
	author          = ["TonyBaretta", "ficool2"]
	description     = Ware_MinigameMode == 1 ? "Smack the deer!" : "Smack the cow!"
	duration        = 10.5
	location        = "boxarena"
	music           = "farm"
	modes           = 2
	custom_overlay  = Ware_MinigameMode == 1 ? "grapple_deer" : "grapple_cow"
})

cutout_models <-
[
	"models/props_2fort/cow001_reference.mdl"
	"models/props_sunshine/deer_cutout001.mdl"
]
cutout_model <- cutout_models[Ware_MinigameMode]

cow_sounds <- 
[
	"ambient_mp3/cow1.mp3"
	"ambient_mp3/cow2.mp3"
	"ambient_mp3/cow3.mp3"
]

function OnPrecache()
{
	foreach (model in cutout_models)
		PrecacheModel(model)
	foreach (sound in cow_sounds)
		PrecacheSound(sound)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center + Vector(620, 0, 0),
		QAngle(0, 180, 0),
		1300.0,
		65.0, 65.0)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_DEMOMAN, ["Ullapool Caber", "Grappling Hook"])
	
	local angles = Ware_MinigameMode == 1 ? QAngle(0, 90, 0) : QAngle(0, 0, 0)
	
	local lightorigin = Ware_SpawnEntity("info_target",
	{
		origin     = Ware_MinigameLocation.center + Vector(-830, -780, 584)
		spawnflags = 1
	})

	local prop = Ware_SpawnEntity("prop_dynamic",
	{
		origin = Ware_MinigameLocation.center + Vector(-960, 0, 584)
		angles = angles
		model  = cutout_model
		solid  = SOLID_BBOX
	})
	SetPropEntity(prop, "m_hLightingOrigin", lightorigin)
	prop = Ware_SpawnEntity("prop_dynamic",
	{
		origin = Ware_MinigameLocation.center + Vector(-960, -500, 584)
		angles = angles
		model  = cutout_model
		solid  = SOLID_BBOX
	})
	SetPropEntity(prop, "m_hLightingOrigin", lightorigin)
	prop = Ware_SpawnEntity("prop_dynamic",
	{
		origin = Ware_MinigameLocation.center + Vector(-960, 500, 584)
		angles = angles
		model  = cutout_model
		solid  = SOLID_BBOX
	})
	SetPropEntity(prop, "m_hLightingOrigin", lightorigin)
	
	if (Ware_MinigameMode == 0)
	{
		local sound = RandomElement(cow_sounds)
		Ware_PlaySoundOnAllClients(sound)
		Ware_PlaySoundOnAllClients(sound)
	}
}

function OnTakeDamage(params)
{
	local attacker = params.attacker
	if (attacker
		&& attacker.IsPlayer()
		&& (params.damage_type & DMG_BLAST)
		&& params.const_entity.GetModelName() == cutout_model)
	{
		Ware_PassPlayer(attacker, true)	
	}
}