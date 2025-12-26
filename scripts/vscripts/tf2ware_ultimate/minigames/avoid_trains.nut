minigame <- Ware_MinigameData
({
	name          = "Avoid the Trains"
	author		  = ["TonyBaretta", "ficool2"]
	description   = "Dodge the trains!"
	duration      = 6.0
	music         = "train"
	modes         = 2
	start_pass    = true
	fail_on_death = true
})	

train_model <- "models/props_vehicles/train_enginecar.mdl"

train_rain <- 
[
	Ware_FixupMP3("tf2ware_ultimate/v%d/train_rain/train_rain_3.mp3")
	Ware_FixupMP3("tf2ware_ultimate/v%d/train_rain/train_rain_5.mp3")
	Ware_FixupMP3("tf2ware_ultimate/v%d/train_rain/train_rain_6.mp3")
	Ware_FixupMP3("tf2ware_ultimate/v%d/train_rain/train_rain_10.mp3")
	Ware_FixupMP3("tf2ware_ultimate/v%d/train_rain/train_rain_17.mp3")
]

horn_sound <- "TF2Ware_Ultimate.KartHorn"

function OnPrecache()
{
	PrecacheModel(train_model)
	
	foreach(sound in train_rain)
		PrecacheSound(sound)
	
	PrecacheScriptSound(horn_sound)
}

function OnStart()
{
	if (Ware_MinigameMode == 0)
	{
		local sound = RandomElement(train_rain)
		Ware_PlaySoundOnAllClients(sound)
		Ware_PlaySoundOnAllClients(sound)
		Ware_PlaySoundOnAllClients(sound)
	}
	
	local minigame_players = clone(Ware_MinigamePlayers)
	
	local train_count
	if (Ware_MinigameMode == 0)
		train_count = Max(Min(minigame_players.len() / 3, minigame_players.len()), 1)
	else if (Ware_MinigameMode == 1)
		train_count = Min(minigame_players.len(), 2)
	
	local i = 0
	Ware_CreateTimer(function()
	{
		if (i++ < train_count)
		{
			if (minigame_players.len() > 0)
			{
				local player = RemoveRandomElement(minigame_players)
				SpawnTrain(player.GetOrigin())
				return 0.08
			}
		}
	}, 1.0)
	
}

function SpawnTrain(pos)
{
	local train_pos, train_ang, train_vel
	if (Ware_MinigameMode == 0)
	{
		train_pos = pos + Vector(0, 0, RandomFloat(1950, 2020))
		train_ang = QAngle(90, 0, 0)
		train_vel = Vector(0, 0, RandomFloat(-800, -1000))
	}
	else if (Ware_MinigameMode == 1)
	{
		local axes = [[1, 0], [-1, 0], [0, -1], [0, 1]]
		local axis = RandomElement(axes)
		local offset_x = (Ware_MinigameLocation.maxs.x - Ware_MinigameLocation.mins.x) + 1132.0
		local offset_y = (Ware_MinigameLocation.maxs.y - Ware_MinigameLocation.mins.y) + 1132.0
		local x = RandomFloat(offset_x, offset_x + 150.0)
		local y = RandomFloat(offset_y, offset_y + 150.0)
		train_pos = pos + Vector(x * axis[0], y * axis[1], 0)
		train_ang = QAngle(0, -atan2(axis[1], -axis[0]) * RAD2DEG, 0)
		train_vel = Vector(RandomFloat(-1200, -1300) * axis[0], RandomFloat(-1200, -1300) * axis[1], 0)
	}
	
	local train = Ware_SpawnEntity("prop_dynamic",
	{
		targetname = "train"
		model      = train_model
		origin     = train_pos
		angles     = train_ang
	})
	train.SetMoveType(MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT)
	train.SetAbsVelocity(train_vel)
	
	train.ValidateScriptScope()
	train.GetScriptScope().played_sound <- false
	
	local hurt = Ware_SpawnEntity("trigger_hurt",
	{
		origin     = train_pos
		damage     = 1000
		damagetype = DMG_VEHICLE
		spawnflags = SF_TRIGGER_ALLOW_CLIENTS
	})
	SetEntityParent(hurt, train)
	hurt.SetSolid(SOLID_BBOX)
	hurt.SetSize(train.GetBoundingMinsOriented(), train.GetBoundingMaxsOriented())
}

function OnTakeDamage(params)
{
	if (params.damage_type & DMG_VEHICLE)
	{
		if (params.inflictor)
		{
			local train = params.inflictor.GetMoveParent()
			if (train.GetName() == "train")
			{
				local scope = train.GetScriptScope()
				if (!scope.played_sound)
				{
					train.EmitSound(horn_sound)
					scope.played_sound = true
				}
			}
		}
	}
}
