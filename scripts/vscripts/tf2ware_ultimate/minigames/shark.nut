minigame <- Ware_MinigameData
({
	name           = "Shark"
	author         = ["TonyBaretta", "ficool2"]
	description    = 
	[
		"Get on the beach and avoid the Shark!"
		"You are the Shark. Kill 3 players!"
	]
	duration       = 23.5
	end_delay      = 1.0
	music          = "slowfox"
	location       = "beach"
	allow_damage   = true
	fail_on_death  = true
	min_players    = 4
	custom_overlay = 
	[
		"avoid_shark"
		"shark_kill"
	]
	convars        =
	{
		mp_teams_unbalance_limit = 0
	}
})

shark <- null
shark_icon <- null
shark_kills <- 0

shark_model <- "models/tf2ware/shark.mdl"
shark_sound <- "TF2Ware_Ultimate.Sharkbite"

local blahaj = RandomInt(0, 99) == 0
if (blahaj)
	shark_model <- "models/blahaj_plush/blahaj_plush.mdl"

function OnPrecache()
{
	PrecacheModel("models/tf2ware/shark.mdl")
	PrecacheModel("models/blahaj_plush/blahaj_plush.mdl")
	PrecacheScriptSound(shark_sound)
}

function OnTeleport(players)
{
	shark = RemoveRandomElement(players)

	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center + Vector(3500, 0, -250),
		QAngle(0, -180, 0),
		1500.0,
		65.0, 60.0)
		
	Ware_TeleportPlayer(shark, Ware_MinigameLocation.center + Vector(1500, 0, -200), ang_zero, vec3_zero)
}

function OnStart()
{
	local blocker = Ware_SpawnEntity("func_forcefield",
	{
		origin  = Ware_MinigameLocation.center + Vector(650, 0, 0)
		teamnum = TF_TEAM_RED
	})
	blocker.SetSolid(SOLID_BBOX)
	blocker.SetSize(Vector(-8, -1100, -1100), Vector(8, 1100, 1100))
	
	shark_icon = Ware_SpawnEntity("handle_dummy", { classname = "shark" } ) // kill icon
	
	foreach (player in Ware_MinigamePlayers)
	{
		if (player == shark)
		{
			Ware_SetPlayerMission(player, 1)
			Ware_SetPlayerClass(player, TF_CLASS_PYRO)
			player.SetForcedTauntCam(1)
			player.SetCustomModel(shark_model)
			if (!blahaj)
			{
				player.SetCustomModelRotates(true)
				player.SetCustomModelOffset(Vector(0, 0, -48))
			}
			else
			{
				player.SetCustomModelOffset(Vector(0, 0, 48))
				player.SetModelScale(2.0, 0.0)
			}
			
			Ware_TogglePlayerWearables(shark, false)
			SetPropFloat(player, "m_PainFinished", 1e30) // disable drowning
			Ware_SetPlayerTeam(player, TF_TEAM_BLUE)
		}
		else
		{
			Ware_SetPlayerMission(player, 0)
			Ware_SetPlayerClass(player, TF_CLASS_SOLDIER)
			Ware_SetPlayerTeam(player, TF_TEAM_RED)
		}
	}
}

function OnUpdate()
{
	local shark_pos = shark.IsValid() && shark.IsAlive() ? shark.GetOrigin() : null
	local threshold = Ware_MinigameLocation.center.x + 512.0
	foreach (player in Ware_MinigamePlayers)
	{
		if (player == shark)
			continue
		if (!player.IsAlive())
			continue

		local origin = player.GetOrigin()
		if (shark_pos)
		{
			if (VectorDistance(origin, shark_pos) < 110.0)
			{
				shark.EmitSound(shark_sound)
				player.TakeDamage(20000, DMG_BLAST, shark)
				continue
			}
		}
		
		if (origin.x <= threshold && !Ware_IsPlayerPassed(player))
		{
			Ware_ShowScreenOverlay(player, null)
			Ware_PassPlayer(player, true)
		}
	}
}

function OnPlayerDeath(player, attacker, params)
{
	if (player == shark)
	{
		CreateTimer(@() KillPlayerRagdoll(player), 0.0)
	}
	else
	{
		if (attacker && attacker == shark)
		{
			if (++shark_kills >= 3)
				Ware_PassPlayer(attacker, true)
		}
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	local attacker = params.attacker
	if (attacker && victim != attacker)
	{
		if (attacker != shark)
			return false
			
		params.inflictor = shark_icon
	}
}

function OnCleanup()
{
	if (shark.IsValid())
	{
		shark.SetForcedTauntCam(0)
		shark.SetCustomModel("")
		shark.SetCustomModelRotates(false)
		shark.SetCustomModelOffset(Vector())
		shark.SetModelScale(1.0, 0.0)
		Ware_TogglePlayerWearables(shark, true)
		SetPropFloat(shark, "m_PainFinished", 0.0)
	}
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers(TF_TEAM_RED).len() == 0
}