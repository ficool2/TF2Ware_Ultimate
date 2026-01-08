
// TODO: More testing/fixes when players join or leave mid-round
// TODO: Give players that join mid-round 1 life, but avoid any cheesing from relogging. DONE, needs test

// TODO: Fix any minigames where things fall from the sky bcuz the things collide with spectators.
// TODO: Fix halloween bosses targeting spectators.

// wipeout description found at https://wiki.teamfortress.com/wiki/TF2Ware

MaxLives <- Ware_Players.len() >= 24 ? 2 : 3

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
	two_lives_last   = "ui/duel_challenge_accepted_with_restriction.wav"
}

overlay_getready <- "hud/tf2ware_ultimate/get_ready.vmt"

Wipeout_SteamIDs     <- [] // used only to prevent cheesing by rejoining
Wipeout_ValidPlayers <- []

special_round <- Ware_SpecialRoundData
({
	name = "Wipeout"
	author = ["Mecha the Slag", "pokemonPasta"]
	description = format("%d lives, battle in smaller groups until one player remains!", MaxLives) // TODO: better description
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

function Wipeout_SetupData(player, lives = 0)
{
	local data = Ware_GetPlayerSpecialRoundData(player)
	data.solid_flags <- (player && player.IsPlayer() ? GetPropInt(player, "m_Collision.m_usSolidFlags") : null)
	data.lives <- lives
	data.is_playing <- false
	data.has_played <- false
}

function Wipeout_GetAlivePlayers()
{
	local alive_players = []
	
	foreach(player in Ware_Players)
	{
		local data = Ware_GetPlayerSpecialRoundData(player)
		if ("lives" in data && data.lives > 0)
			alive_players.append(player)
	}
	
	return alive_players
}

function OnStart()
{
	foreach(player in Ware_Players)
	{
		Wipeout_SetupData(player, MaxLives)
		Ware_GetPlayerData(player).score = MaxLives
		Wipeout_SteamIDs.append(GetPlayerSteamID3(player))
	}
}

function OnPlayerConnect(player)
{
	local steam_id = GetPlayerSteamID3(player)
	local num_players = Wipeout_GetAlivePlayers().len()
	if(Wipeout_SteamIDs.find(steam_id) == null && num_players >= 5)
	{
		Wipeout_SteamIDs.append(steam_id)
		Wipeout_SetupData(player, 1)
	}
	else
		Wipeout_SetupData(player)
}

function OnPlayerSpawn(player)
{
	local data = Ware_GetPlayerSpecialRoundData(player)
	if (!("lives" in data))
		Wipeout_SetupData(player, 0)
}

function OnTakeDamage(params)
{
	local player = params.const_entity
	local inflictor = params.inflictor
	if(!Ware_Finished &&
		((player && player.IsPlayer() && !Ware_GetPlayerSpecialRoundData(player).is_playing) ||
		(inflictor && inflictor.IsPlayer() && !Ware_GetPlayerSpecialRoundData(inflictor).is_playing)))
	{
		params.damage = 0.0
		params.early_out = true
	}
}

function OnBeginIntermission(is_boss)
{
	Wipeout_ValidPlayers.clear()
	
	// check player thresholds and adjust player amount
	local alive_players = Wipeout_GetAlivePlayers()
	local alive_player_count = alive_players.len()
	local player_count
	foreach(threshold in player_thresholds)
	{
		if (alive_player_count >= threshold[1])
		{
			player_count = threshold[0]
			break
		}
	}
	
	// assemble valid players
	local player_rotation = alive_players.filter(function(i,v){return !Ware_GetPlayerSpecialRoundData(v).has_played})
	if(player_rotation.len() < player_count)
	{
		Wipeout_ValidPlayers.extend(player_rotation)
		player_rotation.clear()
		foreach(player in alive_players)
		{
			local data = Ware_GetPlayerSpecialRoundData(player)
			data.has_played = !data.has_played
			if(!data.has_played)
				player_rotation.append(player)
		}
	}
	
	while (Wipeout_ValidPlayers.len() < player_count)
	{
		local player = RemoveRandomElement(player_rotation)
		local data = Ware_GetPlayerSpecialRoundData(player)
		Wipeout_ValidPlayers.append(player)
		data.has_played = true
	}
	
	// get text hold time, assemble text
	local holdtime = Ware_GetThemeSoundDuration("intro")
	local pre_text = format("This %s players are:\n", is_boss ? "bossgame's" : "minigame's")
	local player_list = ""
	
	foreach(player in Wipeout_ValidPlayers)
	{
		player_list += GetPlayerName(player)
		player_list += "\n"
	}
	
	// for each player clear overlay, show text depending on status, play sound
	foreach (player in Ware_Players)
	{
		Ware_ShowScreenOverlay2(player, null)
		
		local lives = Ware_GetPlayerSpecialRoundData(player).lives
		if (Wipeout_ValidPlayers.find(player) != null)
		{
			Ware_ShowScreenOverlay(player, overlay_getready)
			
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
			Ware_PlayGameSound(player, "intro", 0, 0.25) // still play this but very quiet, feels weird without it
			Ware_PlaySoundOnClient(player, sound)
		}
		else
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
	foreach(player in Wipeout_ValidPlayers)
		Ware_GetPlayerSpecialRoundData(player).is_playing = true
		
	return Wipeout_ValidPlayers
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
	// valid players get passed through normal logic. handle invalid players here (teleport etc)
	local Spectators = Ware_Players.filter(function(i,v){return !Ware_GetPlayerSpecialRoundData(v).is_playing})
	foreach(player in Spectators)
		Ware_ChatPrint(player, "The players are now playing {color}{str}{color}!", COLOR_GREEN, Ware_Minigame.name, TF_COLOR_DEFAULT)
	
	local location = clone(Ware_MinigameLocation)
	local name = location.name
	local disabled_locations = [// special cases, make players use spectator for any complex locations
		"factory"
		"frogger"
		"hexplatforms"
		"homerun_contest"
		"manor"
		"obstaclecourse"
		"typing"
		"waluigi_pinball"
	]
	if(disabled_locations.find(name) != null || startswith(name, "kart") || startswith(name, "beepblock")) 
	{
		foreach(player in Spectators)
			KillPlayerSilently(player)
			
		return
	}
	
	if(Ware_Minigame.file_name == "trivia") // another edge case..... would rather show players winners area over invisible players at the question
	{
		location = Ware_Location.beach
		name = location.name
	}
		
	location.Teleport(Spectators)
	
	if("maxs" in location && "mins" in location) // TODO: Remove this check once all locations have mins and maxs defined.
	{
		local lerps = { // lerp from min.z to max.z; TODO: should we move this to location tables?
			"beach": 0.75
			"boxingring": 0.3
			"circlepit": 0.4
			"circlepit-big": 0.4
			"factoryplatform": 0.4
			"home": 0.15
			"home-big": 0.15
			"inventoryday": 0.35
			"love": 0.5
			"rocketjump": 0.8
			"rocketjump_micro": 0.8
			"sawrun" : 0.6
			"sawrun_micro": 0.6
			"smasharena": 0.45
			"sumobox": 0.6
			"warehouse": 0.55
			"wega_challenge": 0.6
		} 
		local tele_lerp = name in lerps ? lerps[name] : 0.25
		
		foreach(player in Spectators)
		{
			player.SetGravity(0.00001)
			Ware_AddPlayerAttribute(player, "no_jump", 1.0, Ware_Minigame.duration)
			Ware_ShowMinigameText(player, Ware_GetPlayerSpecialRoundData(player).lives > 0 ? "Please wait for your turn." : "You are out of lives and cannot continue.")
			DisablePlayerVisibility(player)
			
			local origin = player.GetOrigin()
			origin.z = Lerp(location.mins.z, location.maxs.z, tele_lerp)
			Ware_TeleportPlayer(player, origin, null, null)
		}
	}
	else
	{
		foreach(player in Spectators)
		{
			Ware_ShowMinigameText(player, Ware_GetPlayerSpecialRoundData(player).lives > 0 ? "Please wait for your turn." : "You are out of lives and cannot continue.")
			DisablePlayerVisibility(player)
		}
	}
}

function GetMinigameEndEffects(player, participated, passed)
{
	if(participated)
		return {}
	
	return {overlay = "", sound = "victory"}
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
		default:
			special_round.boss_threshold = INT_MAX
			special_round.boss_count = INT_MAX
	}
	
	foreach(player in Ware_Players)
	{
		EnablePlayerVisibility(player)
		player.SetGravity(1.0)
		
		player.ForceRegenerateAndRespawn()
		
		local data = Ware_GetPlayerSpecialRoundData(player).is_playing = false
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
	foreach(player in Ware_Players)
		EnablePlayerVisibility(player)
}

// stolen from singleplayer.nut
function DisablePlayerVisibility(player)
{
    player.AddCustomAttribute("voice pitch scale", 0, -1)
    Ware_TogglePlayerWearables(player, false)
    player.AddHudHideFlags(HIDEHUD_TARGET_ID)
    SetPropInt(player, "m_nRenderMode", kRenderNone)
	Ware_GetPlayerSpecialRoundData(player).collision_group <- player.GetCollisionGroup()
	player.AddSolidFlags(FSOLID_NOT_SOLID)
}

function EnablePlayerVisibility(player)
{
	player.RemoveHudHideFlags(HIDEHUD_TARGET_ID)
	SetPropInt(player, "m_nRenderMode", kRenderNormal)
	Ware_TogglePlayerWearables(player, true)
	player.SetSolidFlags(Ware_GetPlayerSpecialRoundData(player).solid_flags)
}
