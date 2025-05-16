
minigame <- Ware_MinigameData
({
	name           = "Flipper Ball"
	author         = ["TonyBaretta", "ficool2"]
	description    = "Get to the end!"
	modes          = 2
	duration       = Ware_MinigameMode == 0 ? 27.0 : 28.0
	end_delay      = 0.5	
	music          = Ware_MinigameMode == 0 ? "fastbros" : "letsgetquirky"
	location       = "pinball"
	custom_overlay = "get_end"
})

balls <- []
ball_model <- "models/tf2ware_ultimate/big_soccer_ball.mdl"

function OnPrecache()
{
	PrecacheModel(ball_model)
	
	Ware_PrecacheMinigameMusic("fastbros", false)
	Ware_PrecacheMinigameMusic("letsgetquirky", false)
}

function OnTeleport(players)
{
	if (Ware_MinigameMode == 0)
	{
		Ware_TeleportPlayersRow(players,
			Ware_MinigameLocation.center_bottom,
			QAngle(0, -90, 0),
			1000.0,
			65.0, 65.0)
	}
	else if (Ware_MinigameMode == 1)
	{
		Ware_TeleportPlayersRow(players,
			Ware_MinigameLocation.center_top,
			QAngle(0, 90, 0),
			2100.0,
			-64.0, 60.0)
	}
}

function OnStart()
{
	if (Ware_MinigameMode == 0)
		Ware_SetGlobalLoadout(TF_CLASS_SCOUT)
	else
		Ware_SetGlobalLoadout(TF_CLASS_PYRO)
	Ware_CreateTimer(@() SpawnBall(), 1.0)
}

function SpawnBall()
{
	local alive_players = Ware_MinigamePlayers.filter(@(i, player) player.IsAlive())
	if (alive_players.len() > 0)
	{
		local player = RandomElement(alive_players)
		local origin = player.GetOrigin()

		local ball_origin = Ware_MinigameLocation.center_top + Vector(0, 220, 365)
		ball_origin.x = origin.x

		local ball = Ware_SpawnEntity("prop_physics_override"
		{
			classname = "passtime_pass", // killicon
			origin = ball_origin,
			model = ball_model,
			skin = RandomInt(0, 1),
			disableshadows = true,
			minhealthdmg = INT_MAX, // don't destroy on touch
			spawnflags = 16, // break on touch
			overridescript = "mass,1000"
		})
		balls.append(ball)
		
		if (balls.len() < 50)
			return 1.0
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		if (params.damage_type & DMG_SLASH)
		{
			// the attacker is the player, so recover the true attacker from the damage position
			local attacker = Entities.FindByClassnameNearest("passtime_pass", params.damage_position, 0.0)
			if (attacker)
				victim.TakeDamage(10000, DMG_BLAST|DMG_CRIT, attacker)
			return false
		}
	}
	else if (victim.GetClassname() == "passtime_pass")
	{
		return false
	}
}

function OnUpdate()
{
	local win_threshold
	if (Ware_MinigameMode == 0)
	{
		local win_y = Ware_MinigameLocation.center_top.y + 64.0
		foreach (player in Ware_MinigamePlayers)
		{
			if (player.IsAlive() && player.GetOrigin().y < win_y)
				Ware_PassPlayer(player, true)
		}

	}
	else if (Ware_MinigameMode == 1)
	{
		local win_y = Ware_MinigameLocation.center_bottom.y - 400.0
				
		for (local i = balls.len() - 1; i >= 0; i--)
		{
			local ball = balls[i]
			if (!ball.IsValid())
			{
				balls.remove(i)
				continue
			}
			
			if (ball.GetOrigin().y > win_y)
			{
				ball.Kill()
				balls.remove(i)
			}
		}
		
		foreach (player in Ware_MinigamePlayers)
		{
			if (player.IsAlive() && player.GetOrigin().y > win_y)
				Ware_PassPlayer(player, true)
		}		
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() == 0
}