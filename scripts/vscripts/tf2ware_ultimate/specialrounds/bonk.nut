bat_model <- "models/weapons/c_models/tf2ware/c_bonk_bat.mdl"
bat_modelindex <- PrecacheModel(bat_model)

bat_hit_sound <- "TF2Ware_Ultimate.BonkBatHit"

special_round <- Ware_SpecialRoundData
({
	name = "Bonk"
	author = ["Mecha the Slag", "ficool2"]
	description = "Everyone gets a BONK BAT!"
	categories = ["weapon"]
	allow_damage = true
})

function OnPrecache()
{
	PrecacheModel(bat_model)
	PrecacheScriptSound(bat_hit_sound)
}

function GiveSpecialMelee(player)
{
	local data = Ware_GetPlayerData(player)
	local melee, vm

	if (!data.special_melee || !data.special_melee.IsValid())
	{
		melee = CreateEntitySafe("tf_weapon_bat")
		SetPropInt(melee, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 1123)
		SetPropBool(melee, "m_AttributeManager.m_Item.m_bInitialized", true)
		melee.DispatchSpawn()

		for (local i = 0; i < 4; i++)
			SetPropIntArray(melee, "m_nModelIndexOverrides", bat_modelindex, i)
		SetPropBool(melee, "m_bBeingRepurposedForTaunt", true)
		SetPropInt(melee, "m_nRenderMode", kRenderTransColor)
	}

	if (!data.special_vm || !data.special_vm.IsValid())
	{
		vm = Entities.CreateByClassname("tf_wearable_vm")
		SetPropInt(vm, "m_nModelIndex", bat_modelindex)
		SetPropBool(vm, "m_bValidatedAttachedEntity", true)
		vm.DispatchSpawn()
	}

	if (melee || vm)
		Ware_EquipSpecialMelee(player, melee, vm)
}

function OnStart()
{
	foreach (player in Ware_GetValidPlayers())
		GiveSpecialMelee(player)
}

function OnPlayerInventory(player)
{
	GiveSpecialMelee(player)
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer())
		{
			if (params.damage_type & DMG_CLUB)
			{
				local weapon = params.weapon
				if (weapon && GetPropInt(weapon, "m_nModelIndexOverrides") == bat_modelindex)
				{
					params.damage = 1.0

					Ware_UngroundPlayer(victim)

					local scale = 450.0
					local dir = attacker.EyeAngles().Forward()
					local vel = victim.GetAbsVelocity()
					dir.z = Max(dir.z, 0.0)
					vel += dir * scale
					vel.z += scale
					victim.SetAbsVelocity(vel)
					victim.EmitSound(bat_hit_sound)
				}
			}
		}
	}
}

function OnEnd()
{
	foreach (player in Ware_Players)
		Ware_DestroySpecialMelee(player)
}