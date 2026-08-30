minigame <- Ware_MinigameData
({
	name        = "Hit the Balls!"
	author      = ["TonyBaretta", "ficool2"]
	description = "Hit the balls to the other side!"
	duration    = 20.0
	end_delay   = 1.0
	location    = "boxarena"
	music       = "knockout"
	min_players = 2
	sort_teams  = true
})

ball_model <- "models/player/items/scout/soccer_ball.mdl"
beam_model <- "sprites/laser.vmt"
end_sound <- "player/taunt_bell.wav"

ball_count <- 0
ball_max_count <- 0

function OnPick()
{
	return Ware_ArePlayersOnBothTeams()
}

function OnPrecache()
{
	PrecacheModel(ball_model)
	PrecacheSprite(beam_model)
	PrecacheSound(end_sound)
}

function OnTeleport(players)
{
	local red_players = []
	local blue_players = []

	foreach (player in players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			red_players.append(player)
		else if (team == TF_TEAM_BLUE)
			blue_players.append(player)
	}

	Ware_TeleportPlayersRow(red_players,
		Ware_MinigameLocation.center + Vector(0, 500.0, 0),
		QAngle(0, 270, 0),
		1300.0,
		65.0, 65.0)
	Ware_TeleportPlayersRow(blue_players,
		Ware_MinigameLocation.center + Vector(0, -500.0, 0),
		QAngle(0, 90, 0),
		1300.0,
		65.0, 65.0)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Necro Smasher")
	
	// make melees pass through
	foreach (player in Ware_MinigamePlayers)
		player.AddSolidFlags(FSOLID_NOT_SOLID)

	local beam = Ware_CreateEntity("env_beam")
	beam.SetOrigin(Ware_MinigameLocation.center + Vector(-1000, 0, 64))
	SetPropVector(beam, "m_vecEndPos", Ware_MinigameLocation.center + Vector(1000, 0, 64))
	beam.SetModel(beam_model)
	beam.KeyValueFromString("rendercolor", "255 255 0")
	beam.KeyValueFromInt("renderamt", 100)
	beam.DispatchSpawn()
	SetPropFloat(beam, "m_fWidth", 7.0)
	SetPropFloat(beam, "m_fEndWidth", 7.0)
	EntityAcceptInput(beam, "TurnOn")
	
	local barrier = Ware_CreateEntity("func_brush")
	barrier.SetOrigin(Ware_MinigameLocation.center)
	barrier.SetSolid(SOLID_BBOX)
	barrier.SetSize(Vector(-1000, -16, 0), Vector(1000, 16, 1000))
	barrier.SetCollisionGroup(TFCOLLISION_GROUP_RESPAWNROOMS)
	
	ball_max_count = Ware_MinigamePlayers.len() > 24 ? 20 : 10
	if (Ware_MinigamePlayers.len() >= 64)
		ball_max_count *= 2
	Ware_CreateTimer(@() SpawnBalls(), 0.1)
}

function SpawnBalls()
{
	local ball = Ware_SpawnEntity("prop_soccer_ball",
	{
		model = ball_model,
		origin = Ware_MinigameLocation.center + Vector(RandomFloat(-700, 700), 320.0, 100),
		skin = 0,
	})
	ball.AddFlag(FL_DONTTOUCH)
	ball = Ware_SpawnEntity("prop_soccer_ball",
	{
		model = ball_model,
		origin = Ware_MinigameLocation.center + Vector(RandomFloat(-700, 700), -320.0, 100),
		skin = 1,
	})
	ball.AddFlag(FL_DONTTOUCH)
	
	if (++ball_count < ball_max_count)
		return 0.1
	else if (ball_count % 2 == 0) // to prevent ties, don't allow even number of balls.
	{
		local side = RandomBool() ? 1 : -1
		ball = Ware_SpawnEntity("prop_soccer_ball",
		{
			model = ball_model,
			origin = Ware_MinigameLocation.center + Vector(RandomFloat(-700, 700), 320 * side, 100),
			skin = RandomInt(0,1)
		})
		ball.AddFlag(FL_DONTTOUCH)
	}
}

function OnEnd()
{
	Ware_PlaySoundOnAllClients(end_sound)
	Ware_PlaySoundOnAllClients(end_sound)
	
	local red_score = 0
	local blue_score = 0
	for (local ball; ball = FindByClassname(ball, "prop_soccer_ball");)
	{
		if (ball.GetOrigin().y < Ware_MinigameLocation.center.y)
			red_score++
		else
			blue_score++
	}
	
	Ware_ChatPrint(null, "{color}RED{color} score: {int}", 
		TF_COLOR_RED, TF_COLOR_DEFAULT, red_score)
	Ware_ChatPrint(null, "{color}BLU{color} score: {int}", 
		TF_COLOR_BLUE, TF_COLOR_DEFAULT, blue_score)
	
	local winning_team
	if (blue_score > red_score)
		winning_team = TF_TEAM_BLUE
	else if (red_score > blue_score)
		winning_team = TF_TEAM_RED
	
	if (winning_team)
	{
		foreach (player in Ware_MinigamePlayers)
		{
			if (player.GetTeam() == winning_team)
				Ware_PassPlayer(player, true)
		}
	}
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
		player.RemoveSolidFlags(FSOLID_NOT_SOLID)
}