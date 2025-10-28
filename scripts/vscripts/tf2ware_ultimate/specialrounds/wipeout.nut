
// NEW REWORK IDEA!!
// This will use the Smash Arena location as a home
// and have a big TV with 4 sides showing live feed of the minigame (func_monitor)

// TODO: More testing/fixes when players join or leave mid-round
// TODO: Make spectators more interesting (use actual spectating stuff?)
// TODO: Give players that join mid-round 1 life, but avoid any cheesing from relogging.

// wipeout description found at https://wiki.teamfortress.com/wiki/TF2Ware

player_thresholds <- [
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
	two_lives_last   = "duel_challenge_accepted_with_restriction.wav"
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
	categories = ["unique"] // TODO: wipeout modifies special_round late which double trouble doesn't support

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
	// some brush/ent stuff needed for smash arena idea
	// might need to go in OnTeleport
	local trigger = FindByName(null, "smasharena_trigger")
	EntityAcceptInput(trigger, "EndTouch")
	EntityAcceptInput(trigger, "Disable")

	foreach(player in Ware_Players)
	{
		local max_lives = 2 // TODO: Find a different fix to the long rounds then set this back to 3.
		Ware_GetPlayerSpecialRoundData(player).lives <- max_lives
		Ware_GetPlayerData(player).score = max_lives
	}
}

function OnPlayerConnect(player)
{
	Ware_GetPlayerSpecialRoundData(player).lives <- 0
}

function OnPlayerSpawn(player)
{
	local data = Ware_GetPlayerSpecialRoundData(player)
	if (!("lives" in data))
		data.lives <- 0
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
	if (arr.find(params.const_entity) != null || arr.find(params.inflictor) != null)
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

function OnCalculateScore(data)
{
	local specialdata = Ware_GetPlayerSpecialRoundData(data.player)

	if (!data.passed)
		specialdata.lives--

	specialdata.lives = Max(0, specialdata.lives)

	data.score = specialdata.lives
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
			}
			break
	}

	foreach(player in Wipeout_Spectators)
	{
		Ware_PlayGameSound(player, "victory") // there's just a weird silence without this
	}
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

function OnEnd()
{
	EntityAcceptInput(FindByName(null, "smasharena_trigger"), "Enable")
}