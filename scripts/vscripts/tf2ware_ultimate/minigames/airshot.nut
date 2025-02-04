minigame <- Ware_MinigameData
({
    name        = "Airshot"
	description = "Shoot the Target!"
    author      = ["Black_Knight"]
    location    = "targetrange"
    duration    = 5.0
	music		= "urgent"
})

bot_model <- "models/props_training/target_soldier.mdl"
hit_sound  <- "Player.HitSoundBeepo"

bot <- null

function OnPrecache()
{
    PrecacheModel(bot_model)
    PrecacheScriptSound(hit_sound)
}

function OnStart()
{   
	local angles = QAngle(0, -90, 0)
    Ware_CreateTimer(@() SpawnBot(angles), 2.0)
	Ware_CreateTimer(@() SpawnBot(QAngle(0, 90, 0)), 2.0)
    Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Direct Hit")
}

function TeleportSides(players_left, players_right)
{
	local left = Vector(2240, -4670, -3999)
	local right = Vector(2303, -3135, -3999)
	local PlaceSide = function(players, origin, angles, y_offset)
	{
		local x_offset = 80.0
		local pos = origin * 1.0
		local x = 0
		foreach (player in players)
		{
			if (++x > 20)
			{
				pos.y += y_offset
				x = 1
			}
			
			pos.x = origin.x + (x / 2) * ((x & 1) ? x_offset : -x_offset)
			Ware_TeleportPlayer(player, pos, angles, vec3_zero)
		}		
	}	
	PlaceSide(players_left, left, QAngle(0, 90, 0), 80.0)
	PlaceSide(players_right, right, QAngle(0, 270, 0), -80.0)	
}

function OnTeleport(players)
{
	local red_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_RED)
	local blue_players = players.filter(@(i, player) player.GetTeam() == TF_TEAM_BLUE)	
	local left_team = RandomInt(TF_TEAM_RED, TF_TEAM_BLUE)
	if (left_team == TF_TEAM_RED)
	TeleportSides(red_players, blue_players)
	else
	TeleportSides(blue_players, red_players)
}

function SpawnBot(angles)
{
	local lines = clone(Ware_Location.targetrange.lines)
    local line = RemoveRandomElement(lines)
	local origin = Lerp(line[0], line[1], RandomFloat(0.0, 1.0))
    bot = Ware_SpawnEntity("prop_physics_override",
    {
        model = bot_model
        origin = origin
        angles = angles
        health = 1
    })
    bot.AddEFlags(EFL_NO_DAMAGE_FORCES)
    bot.SetPhysVelocity(Vector(RandomFloat(-300, 300), 0, RandomFloat(1500, 1700)))
}

function OnTakeDamage(params)
{
	if (params.const_entity.GetClassname() == "prop_physics")
	{
		local attacker = params.attacker

		if (attacker && attacker.IsPlayer())
           Ware_PassPlayer(attacker, true)
		   Ware_PlaySoundOnClient(attacker, hit_sound)
	}
    return false
}