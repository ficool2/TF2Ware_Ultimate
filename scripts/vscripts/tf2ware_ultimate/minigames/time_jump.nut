minigame <- Ware_MinigameData
({
	name        = "Time Jumps"
	author      = ["tilderain"]
	description = "Time your jumps to the top!"
	duration    = 6.5
	end_delay   = 0.2
	music       = "starlift"
	thirdperson = true
})

jump_count <- 10
target_height  <- 500.0
wing_model <- "models/workshop/player/items/medic/sf14_purity_wings/sf14_purity_wings.mdl"
bird <- null
bird_model <- "models/props_forest/dove.mdl"

function OnPrecache()
{
	PrecacheModel(wing_model)
	PrecacheModel(bird_model)
}

function OnStart()
{
	local item_attributes =  { "air dash count" : jump_count }
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerLoadout(player, TF_CLASS_SCOUT, "Wrap Assassin", item_attributes)
		Ware_SetPlayerAmmo(player, TF_AMMO_GRENADES1, jump_count)
		Ware_AddPlayerAttribute(player, "head scale", 1.5, -1)
		
		local wings = Ware_SpawnWearable(player, wing_model)
		SetEntityParent(wings, player)
	}
	
	Ware_ShowAnnotation(Ware_MinigameLocation.center + Vector(0, 0, target_height), "Goal!")

	bird = Ware_SpawnEntity("prop_dynamic",
	{
		model       = bird_model
		origin      = Ware_MinigameLocation.center + Vector(RandomFloat(-200, 200), RandomFloat(-200, 200), 100)
		defaultanim = "fly_cycle"
		modelscale  = 5
	})
	bird.SetMoveType(MOVETYPE_FLYGRAVITY, 0)

	Ware_CreateTimer(function()
	{
		bird.SetAbsVelocity(Vector(0,0,300))
		return 0.45
	}, 0.0)
}

function OnUpdate()
{
	local time = Time()
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		local height = Ware_GetPlayerHeight(player)
		
		if (height > target_height)
			Ware_PassPlayer(player, true)
			
		local weapon = player.GetActiveWeapon()
		if (weapon)
		{
			local jump_remaining = Clamp(jump_count - GetPropInt(player, "m_Shared.m_iAirDash") + 1, 0, jump_count)
			SetPropFloat(weapon, "m_flNextSecondaryAttack", time + 0.3)		
			Ware_SetPlayerAmmo(player, TF_AMMO_GRENADES1, jump_remaining)
		}
	}
}