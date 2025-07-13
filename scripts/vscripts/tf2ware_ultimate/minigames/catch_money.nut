minigame <- Ware_MinigameData
({
	name        = "Catch the Money"
	author      = ["Mecha the Slag", "ficool2"]
	description = "Catch $400!"
	duration    = 18.0
	music       = "casino"
	thirdperson = true
})

cash_models  <- 
[
	"models/items/currencypack_small.mdl"
	"models/items/currencypack_medium.mdl"
	"models/items/currencypack_large.mdl"
]
cash_amounts <-
[
	25
	50
	100
]
cash_multiplier <- 1

required_amount <- 400

bomb_model <- "models/props_lakeside_event/bomb_temp.mdl"
touch_sound <- "MVM.MoneyPickup"
explode_sound <- "Weapon_LooseCannon.Explode"
bomb_modelindex <- PrecacheModel(bomb_model)

spawn_rate <- RemapValClamped(Ware_MinigamePlayers.len().tofloat(), 0.0, 16.0, 0.4, 0.02)

cash_spawned <- 0

collision_group <- Ware_IsSpecialRoundSet("collisions") ? COLLISION_GROUP_NONE : COLLISION_GROUP_DEBRIS

function OnPrecache()
{
	foreach (model in cash_models) 
		PrecacheModel(model)
	PrecacheModel(bomb_model)
	PrecacheScriptSound(touch_sound)
	PrecacheScriptSound(explode_sound)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT)

	foreach (player in Ware_MinigamePlayers)
		player.SetCurrency(0)
		
	// show money counter
	ForceEnableUpgrades(2)
	
	if (Ware_MinigamePlayers.len() >= 32)
		cash_multiplier = 2
	else if (Ware_MinigamePlayers.len() >= 64)
		cash_multiplier = 3
	
	Ware_CreateTimer(@() CreateMoney(), 0.5)
}

function CreateMoney()
{
	if (cash_spawned < 100)
	{
		local origin = Vector(
			RandomFloat(Ware_MinigameLocation.mins.x + 50.0, Ware_MinigameLocation.maxs.x - 50.0),
			RandomFloat(Ware_MinigameLocation.mins.y + 50.0, Ware_MinigameLocation.maxs.y - 50.0),
			Ware_MinigameLocation.center.z + 500.0)
		
		local idx = RandomIndex(cash_models)
		
		local cash = Ware_SpawnEntity("prop_physics_override", 
		{
			origin         = origin
			model          = cash_models[idx]
			disableshadows = true
			minhealthdmg   = INT_MAX // don't destroy on touch
			spawnflags     = SF_PHYSPROP_TOUCH
		})	
		cash.SetCollisionGroup(collision_group)
		
		if (RandomInt(0, 5) == 0)
		{
			SetPropInt(cash, "m_nModelIndex", bomb_modelindex)
			EntityEntFire(cash, "Kill", "", 7.0)
		}
		else
		{
			SetPropInt(cash, "m_iHammerID", cash_amounts[idx] * cash_multiplier)
			cash_spawned++
		}
	}
		
	return spawn_rate
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		if (params.damage_type & DMG_SLASH)
		{
			// the attacker is the player, so recover the true attacker from the damage position
			local attacker = FindByClassnameNearest("prop_physics", params.damage_position, 0.0)
			if (attacker && !attacker.IsEFlagSet(EFL_USER))
			{
				attacker.AddEFlags(EFL_USER)
				SetPropInt(attacker, "m_spawnflags", 0)				
				// the kill must be postponed or it may crash because this damage runs from a physics callback
				EntityEntFire(attacker, "Kill")
					
				if (GetPropInt(attacker, "m_nModelIndex") == bomb_modelindex)
				{
					DispatchParticleEffect("ExplosionCore_MidAir", victim.GetOrigin(), Vector())
					attacker.EmitSound(explode_sound)
					victim.TakeDamage(1000, DMG_BLAST, attacker)
				}
				else
				{			
					cash_spawned--
									
					victim.EmitSound(touch_sound)
					victim.AddCurrency(GetPropInt(attacker, "m_iHammerID"))
					if (victim.GetCurrency() >= required_amount)
						Ware_PassPlayer(victim, true)
				}
			}
				
			return false
		}
	}
}

function OnEnd()
{
	local highest_amount = required_amount - 1
	local highest_player
	
	foreach (player in Ware_MinigamePlayers)
	{
		local currency = player.GetCurrency()
		if (currency > highest_amount)
		{
			highest_amount = currency
			highest_player = player
		}
	}
	
	if (highest_player)
	{
		Ware_ChatPrint(null, "{player} {color}is the richest with ${int} collected!", 
			highest_player, TF_COLOR_DEFAULT, highest_amount)
		Ware_GiveBonusPoints(highest_player)
	}
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
		player.SetCurrency(0)
		
	ForceEnableUpgrades(0)
}