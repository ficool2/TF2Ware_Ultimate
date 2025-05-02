
// TODO: More testing/fixes when players join or leave mid-round

// wipeout description found at https://wiki.teamfortress.com/wiki/TF2Ware

player_thresholds <- [
	[20, 100],
	[19, 95],
	[18, 90],
	[17, 85],
	[16, 80],
	[15, 75],
	[14, 70],
	[13, 65],
	[12, 60],
	[11, 55],
	[10, 50],
	[9, 45],
	[8, 40],
	[7, 35],
	[6, 30],
	[5, 20], // 5 players at 20 alive or higher
	[4, 10], // 4 players at 10 or higher
	[3,  3], // etc
	[2,  0]
]

duel_sounds <- {
	three_lives      = "ui/duel_challenge.wav"
	two_lives        = "ui/duel_challenge_accepted.wav"
	one_life         = "ui/duel_event.wav"
	three_lives_last = "ui/duel_challenge_with_restriction.wav"
	two_lives_last   = "ui/duel_challenge_accepted_with_restriction.wav"
}

overlay <- "hud/tf2ware_ultimate/get_ready.vmt"

Wipeout_PlayerRotation <- []
Wipeout_ValidPlayers <- []
Wipeout_Spectators <- []

special_round <- Ware_SpecialRoundData
({
	name = "Wipeout"
	author = ["Mecha the Slag", "pokemonPasta"]
	description = "2 lives, battle in smaller groups until one player remains!" // TODO: better description
	category = "meta" // TODO: wipeout modifies special_round late which double trouble doesn't support
	
	min_players = 3
	
	boss_count     = INT_MAX
	boss_threshold = INT_MAX
})

function OnPrecache()
{
	foreach(k, v in duel_sounds)
		PrecacheSound(v)
}

function OnStart()
{
	foreach(player in Ware_Players)
	{
		local max_lives = 2 // TODO: Find a different fix to the long rounds then set this back to 3.
		Ware_GetPlayerSpecialRoundData(player).lives <- max_lives
		Ware_GetPlayerData(player).score = max_lives
	}
	Ware_SetTheme("_tf2ware_classic")
}

function OnPlayerConnect(player)
{
	local data = Ware_GetPlayerSpecialRoundData(player)
	if (!("lives" in data) && special_round.boss_threshold != 0)
		data.lives <- 1
	else
		data.lives <- 0
	Ware_GetPlayerData(player).score = data.lives
}

function OnPlayerDisconnect(player)
{
	foreach(arr in [Wipeout_Spectators, Wipeout_ValidPlayers, Wipeout_PlayerRotation])
	{
		local idx = arr.find(player)
		if (idx != null)
			arr.remove(idx)
	}
}

function OnTakeDamage(params)
{
	local arr = Wipeout_Spectators
	if (!Ware_Finished && arr.find(params.const_entity) != null || arr.find(params.inflictor) != null)
		params.damage = 0.0
}

function OnBeginIntermission(is_boss)
{
	Wipeout_ValidPlayers <- []
	Wipeout_Spectators <- []
	local alive_player_count = Wipeout_GetAlivePlayers().len()
	local player_count
	foreach(threshold in player_thresholds)
	{
		if (alive_player_count >= threshold[1])
		{
			player_count = threshold[0]
			break
		}
	}
	
	while (Wipeout_ValidPlayers.len() < player_count)
	{
		if (Wipeout_PlayerRotation.len() > 0)
		{
			local player = RemoveRandomElement(Wipeout_PlayerRotation)
			if ((player.GetTeam() & TF_TEAM_MASK) && player.IsAlive())
			{
				Wipeout_ValidPlayers.append(player)
			}
		}
		else
			Wipeout_PlayerRotation <- Wipeout_GetAlivePlayers()
	}
	
	foreach(player in Ware_Players)
	{
		if (Wipeout_ValidPlayers.find(player) == null)
			Wipeout_Spectators.append(player)
	}
	
	local holdtime = Ware_GetThemeSoundDuration("intro")
	local pre_text = format("This %s players are:\n", is_boss ? "bossgame's" : "minigame's")
	local player_list = ""
	
	foreach(player in Wipeout_ValidPlayers)
	{
		player_list += GetPlayerName(player)
		player_list += "\n"
	}
	
	foreach (player in Ware_Players)
	{
		Ware_ShowScreenOverlay2(player, null)
		
		local lives = Ware_GetPlayerSpecialRoundData(player).lives
		if (Wipeout_ValidPlayers.find(player) != null)
		{
			Ware_ShowScreenOverlay(player, overlay)
			
			local text = pre_text + player_list + format("You have %d %s remaining.", lives, lives == 1 ? "life" : "lives")
			Ware_ShowText(player, CHANNEL_MISC, text, holdtime)
			
			local sound
			switch (lives) {
				case 3:
					if (player_count > 3)
						sound = duel_sounds.three_lives
					else
						sound = duel_sounds.three_lives_last
					break
				case 2:
					if (player_count > 3)
						sound = duel_sounds.two_lives
					else
						sound = duel_sounds.two_lives_last
					break
				case 1:
					sound = duel_sounds.one_life
					break
			}
			Ware_PlayGameSound(player, "intro", 0, 0.15) // still play this but very quiet, feels weird without it
			Ware_PlaySoundOnClient(player, sound)
		}
		if (Wipeout_Spectators.find(player) != null)
		{
			Ware_ShowScreenOverlay(player, null)
			
			local text = pre_text + player_list + (lives > 0 ? "Please wait for your turn." : "You are out of lives and cannot continue.")
			Ware_ShowText(player, CHANNEL_MISC, text, holdtime)
			
			Ware_PlayGameSound(player, "intro")
		}
	}
		
	CreateTimer(@() Ware_StartMinigame(is_boss), holdtime)
	return true
}

function OnUpdate()
{
	if(Ware_Minigame)
	{
		foreach(spec in Wipeout_Spectators)
		{
			if(!spec.IsAlive()) continue
			local origin1 = spec.GetOrigin()
			foreach(pl in Wipeout_ValidPlayers)
			{
				if(!pl.IsAlive()) continue
				local origin2 = pl.GetOrigin()
				if(VectorDistance(origin1, origin2) < 300)
				{

           			local delta = origin2 - origin1
					local dir = delta * 1.0
					dir.Norm()
                	local newOrigin = origin1 - (dir * 80)
                	spec.KeyValueFromVector("origin", newOrigin)
				}		
			}
		}
	}
}

function GetValidPlayers()
{
	return Wipeout_ValidPlayers
}

function Wipeout_GetAlivePlayers()
{
	local alive_players = []
	
	foreach(player in Ware_Players)
	{
		local data = Ware_GetPlayerSpecialRoundData(player)
		if (data.lives && data.lives > 0)
			alive_players.append(player)
	}
	
	return alive_players
}

function OnCalculateTopScorers(top_players)
{
	foreach (data in Ware_PlayersData)
	{
		local player = data.player
		local lives = Ware_GetPlayerSpecialRoundData(player).lives
		if (lives > 0)
		{
			top_players.append(player)
		}
	}
}

function OnCalculateScore(data)
{
	local specialdata = Ware_GetPlayerSpecialRoundData(data.player)
	
	if (!data.passed)
		specialdata.lives--
	
	specialdata.lives = Max(0, specialdata.lives)
	
	data.score = specialdata.lives
}

function OnMinigameStart()
{
	if("Teleport" in Ware_MinigameLocation)
		Ware_MinigameLocation.Teleport(Wipeout_Spectators)
	else if(Ware_MinigameLocation != Ware_MinigameHomeLocation)
	{
		local spacing_x = 58.0, spacing_y = 65.0

		Ware_TeleportPlayersRow(Wipeout_Spectators,
			Ware_MinigameLocation.center,
			QAngle(0, 0, 0),
			500.0,
			-spacing_x, spacing_y)
	}
	foreach(player in Wipeout_Spectators)
	{
		//Put this before ghost mode or it'll spawn a bunch of pdas and run out of edicts
		Ware_SetPlayerClass(player, TF_CLASS_SPY)
		player.AddCond(TF_COND_HALLOWEEN_GHOST_MODE)
		if(Ware_MinigameLocation != Ware_MinigameHomeLocation)
			player.SetOrigin(player.GetOrigin() + Vector(0,0,225))

		//Ware_AddPlayerAttribute(player, "mod see enemy health", 1, -1)

		player.SetMoveType(MOVETYPE_NOCLIP, 0)

		SetPropInt(player, "m_nRenderMode", kRenderTransColor)	
		SetEntityColor(player, 255, 255, 255, 40)
	}
}
function OnMinigameEnd()
{
	switch (Wipeout_GetAlivePlayers().len()) {
		case 2:
			special_round.boss_threshold = 0
			break
		case 1:
			special_round.boss_threshold = 0
			special_round.boss_count = 0
			break
		case 0:
			special_round.boss_count = INT_MAX
			foreach(player in Ware_MinigamePlayers)
			{
				local data = Ware_GetPlayerSpecialRoundData(player)
				data.lives <- 1
				Ware_GetPlayerData(player).score = data.lives
			}
			break
	}
	
	foreach(player in Wipeout_Spectators)
	{
		//Ware_PlayGameSound(player, "victory") // there's just a weird silence without this
		
		local lives = Ware_GetPlayerSpecialRoundData(player).lives
		if(lives > 0)
		{
			player.RemoveCond(TF_COND_HALLOWEEN_GHOST_MODE)
			Ware_SetPlayerClass(player, RandomInt(TF_CLASS_FIRST, TF_CLASS_SNIPER))
		}

		player.SetMoveType(MOVETYPE_WALK, 0)
		player.SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
		player.RemoveCond(TF_COND_HALLOWEEN_KART)
		SetPropInt(player, "m_nRenderMode", kRenderNormal)	
		SetEntityColor(player, 255, 255, 255, 100)


	}
	Ware_MinigameHomeLocation.Teleport(Wipeout_Spectators)

	AnnounceKnockouts()
}


function AnnounceKnockouts()
{
	local knocked_out = 0
	
	foreach (data in Ware_PlayersData)
	{
		local player = data.player
		local idx = Wipeout_ValidPlayers.find(player)
		if (idx == null)
			continue

		local lives = Ware_GetPlayerSpecialRoundData(player).lives
		if (lives <= 0)
		{
			knocked_out++
			Ware_ChatPrint(null, "{player}{color} has been {color}wiped out!", player, "9AB973", COLOR_GREEN);
			
			Wipeout_ValidPlayers.remove(idx)
			if(Wipeout_GetAlivePlayers().len() != 2)
				player.AddCond(TF_COND_HALLOWEEN_GHOST_MODE)
			SetEntityColor(player, 255, 255, 255, 40)
		}
	}
	
	local players_len = Wipeout_GetAlivePlayers().len()

	if (knocked_out > 0)
	{
		Ware_ChatPrint(null, "{int} {str} been wiped out! There are {int} {str} still standing.", 
			knocked_out,
			knocked_out > 1 ? "players have" : "player has",
			players_len,
			players_len == 1 ? "player" : "players")
	}
	//else
	//{
	//	Ware_ChatPrint(null, "No one has been knocked out! There are {int} {str} still standing.", 
	//		players_len,
	//		players_len == 1 ? "player" : "players")		
	//}
}


function OnDeclareWinners(top_players, top_score, winner_count)
{
	if (winner_count > 1)
	{
		// NOTE: this should never happen
		Ware_ChatPrint(null, "{color}The winners each with {int} {str} remaining:", TF_COLOR_DEFAULT, top_score == 1 ? "life" : "lives")
		foreach (player in top_players)
			Ware_ChatPrint(null, "> {player} {color}!", player, TF_COLOR_DEFAULT)
	}
	else if (winner_count == 1)
	{
		Ware_ChatPrint(null, "{player} {color}won with {int} {str} remaining!", top_players[0], TF_COLOR_DEFAULT, top_score, top_score == 1 ? "life" : "lives")
	}	
	else if (winner_count == 0)
	{
		Ware_ChatPrint(null, "{color}Nobody won!?", TF_COLOR_DEFAULT)
	}
}
