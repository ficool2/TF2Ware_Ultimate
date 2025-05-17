minigame <- Ware_MinigameData
({
	name        = "Touch The Sky"
	author      = ["TonyBaretta", "ficool2"]
	description = "Touch the Sky!"
	duration    = 10.0
	end_delay   = 0.2
	music       = "golden"
})

highest_player <- null
highest_height <- 0.0
target_height  <- 1400.0

bird <- null
bird_model <- "models/props_forest/dove.mdl"

function OnPrecache()
{
	PrecacheModel(bird_model)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, null, { "air dash count" : 9999 })
	Ware_ShowAnnotation(Ware_MinigameLocation.center + Vector(0, 0, target_height), "Goal!")

	bird = Ware_SpawnEntity("prop_dynamic",
	{
		model       = bird_model
		origin      = Ware_MinigameLocation.center + Vector(RandomFloat(-200, 200), RandomFloat(-200, 200))
		defaultanim = "fly_cycle"
		modelscale  = 3
	})
	bird.SetMoveType(MOVETYPE_NOCLIP, 0)
	bird.SetAbsVelocity(Vector(0,0,200))
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
			
		// fix pitch going out of bounds
		if (GetPropInt(player, "m_Shared.m_iAirDash") > 10)
			SetPropInt(player, "m_Shared.m_iAirDash", 10)
		
		local height = Ware_GetPlayerHeight(player)
		if (height > highest_height)
		{
			highest_player = player
			highest_height = height
		}
		
		if (height > target_height)
			Ware_PassPlayer(player, true)
	}
}

function OnEnd()
{
	if (highest_height > 512.0 && highest_player.IsValid())
	{
		Ware_ChatPrint(null, "{player} {color}reached the highest point at {str} units!",
							highest_player, TF_COLOR_DEFAULT, format("%.1f", highest_height))
		Ware_GiveBonusPoints(highest_player)
	}
}