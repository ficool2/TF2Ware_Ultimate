minigame <- Ware_MinigameData
({
	name        = "Stun Merasmus"
	author      = ["TonyBaretta", "ficool2"]
	description = "Stun Merasmus!"
	duration    = 8.0
	music       = "nearend"
	convars     =
	{
		tf_flamethrower_burstammo = 0,
	}
})

merasmus <- null

function OnPick()
{
	return !Ware_IsSpecialRoundSet("merasmus")
}

function OnPrecache()
{
	PrecacheEntityFromTable({classname = "merasmus"})
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_PYRO, "Flame Thrower")
	
	foreach (player in Ware_MinigamePlayers)
	{
		player.AddCond(TF_COND_HALLOWEEN_SPEED_BOOST)
		player.AddCond(TF_COND_HALLOWEEN_BOMB_HEAD)
	}
	
	Ware_CreateTimer(@() SpawnMerasmus(), 0.1)
}

function SpawnMerasmus()
{
	merasmus = Ware_SpawnEntity("merasmus",
	{
		origin = Ware_MinigameLocation.center + Vector(0, 0, 32),
		modelscale = 0.5,
	})
	
	Ware_ShowAnnotation(merasmus.GetOrigin() + Vector(0, 0, 80), "Stun me!")
}

function OnUpdate()
{
	local merasmus_origin
	if (merasmus && merasmus.IsValid())
		merasmus_origin = merasmus.GetOrigin()
	
	foreach (player in Ware_MinigamePlayers)
		Ware_DisablePlayerPrimaryFire(player)
}

function OnTakeDamage(params)
{
	local attacker = params.attacker
	if (params.const_entity.GetClassname() == "merasmus")
	{
		if (attacker
			&& attacker.IsPlayer()
			&& params.damage_stats == TF_DMG_CUSTOM_MERASMUS_PLAYER_BOMB)
		{
			Ware_PassPlayer(attacker, true)
		}
	}
	else if (attacker && attacker.GetClassname() == "merasmus")
	{
		params.damage *= 5.0
	}
}

function OnEnd()
{
	if (merasmus.IsValid())
	{
		SendGlobalGameEvent("merasmus_killed", {})
		merasmus.Kill()
	}
	
	foreach (player in Ware_MinigamePlayers)
	{
		player.RemoveCond(TF_COND_HALLOWEEN_SPEED_BOOST)
		player.RemoveCond(TF_COND_HALLOWEEN_BOMB_HEAD)
		player.RemoveCond(TF_COND_CRITBOOSTED_PUMPKIN)
		player.RemoveCond(TF_COND_SPEED_BOOST)
		player.RemoveCond(TF_COND_INVULNERABLE)
	}
}