minigame <- Ware_MinigameData
({
	name           = "Count Bombs"
	author         = ["sasch", "ficool2"]
	description    = "How many bombs?"
	duration       = 8.0
	end_delay      = 0.5
	music          = "thethinker"
	suicide_on_end = true
})

prop_model <- "models/tf2ware_ultimate/dummy_sphere.mdl"
sprite_model <- "sprites/tf2ware_ultimate/bomb_red.vmt"

count <- 0

function OnPrecache()
{
	PrecacheModel(prop_model)
	PrecacheSprite(sprite_model)
}

function OnStart()
{
	count = RandomInt(6, 10)
	
	for (local i = 0; i < count; i++)
	{
		local pos = Ware_MinigameLocation.center
		pos += Vector(RandomFloat(-250, 250), RandomFloat(-250, 250), RandomFloat(250, 300))
	
		local prop = Ware_SpawnEntity("prop_physics_override", 
		{
			model          = prop_model
			origin         = pos
			massscale      = 0.015
			rendermode     = kRenderTransColor
			renderamt      = 0
			disableshadows = true
		})
		prop.SetCollisionGroup(TFCOLLISION_GROUP_COMBATOBJECT)
		
		local sprite = Ware_SpawnEntity("env_glow",
		{
			model       = sprite_model
			origin      = pos
			scale       = 0.25
			spawnflags  = 1
			rendermode  = 1
			rendercolor = "255 255 255"
		})
		
		SetEntityParent(sprite, prop)
		
		Ware_SlapEntity(prop, RandomFloat(40, 80))
	}
}

function OnEnd()
{
	Ware_ChatPrint(null, "The correct answer was {color}{int}", COLOR_LIME, count)
}

function OnPlayerSay(player, text)
{
	local num = StringToInteger(text)
	if (num == null)
		return
		
	if (num != count)
	{
		if (player.IsAlive() && !Ware_IsPlayerPassed(player))
		{
			// servers may display player as dead, so delay to end of frame
			Ware_CreateTimer(@() Ware_SuicidePlayer(player), 0.0)
		}
	}
	else
	{
		if (player.IsAlive())
			Ware_PassPlayer(player, true)
	}
	
	// intentionally allow the message to be shown as it can be easily inferred otherwise
}