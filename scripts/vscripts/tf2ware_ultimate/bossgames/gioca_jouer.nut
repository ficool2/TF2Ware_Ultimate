
// Gioca Jouer consists of a bunch of smaller challenges
// that sum up to a boss game. These will be referred to
// as "microgames" in this file. - pokemonpasta

MICRO_SLEEP  <- 0   // don't move
MICRO_WAVE   <- 1   // taunt
MICRO_HITCH  <- 2   // jump
MICRO_SNEEZE <- 3   // crouch
MICRO_WALK   <- 4   // don't stop moving
MICRO_SWIM   <- 5   // swimming
MICRO_SKI    <- 6   // go left
MICRO_SPRAY  <- 7   // look down and use the spray
MICRO_MACHO  <- 8   // spycrab
MICRO_HORN   <- 9   // use kart horn (medic key)
MICRO_BELL   <- 10  // jump + crouch
MICRO_OKAY   <- 11  // say cheers (c+3)
MICRO_KISS   <- 12  // call medic
MICRO_COMB   <- 13  // disguise
MICRO_WAVE2  <- 14  // taunt
MICRO_WAVE3  <- 15  // re-taunt
MICRO_SUPER  <- 16  // rocket jump
MICRO_RESET  <- 17  // Reset. If we consider "reset" a microgame then we dont have to make a separate reset function, and we get previous OnMicroEnd call for free.

micro <- null        // microgame tracker

micro_time_start <- 0.0
micro_second_phase <- false

TIMER_FIRST <- 3.5820886
TIMER_SECOND <- 1.791044

min_score <- 4000

minigame <- Ware_MinigameData
({
	name          = "Gioca Jouer"
	author        = ["TonyBaretta", "pokemonPasta"]
	description   = "Gioca Jouer!"
	duration      = 140.0
	end_delay     = 1.0
	location      = "boxarena"
	music         = "giocajouer"
	start_pass    = false
	convars = {
		tf_max_voice_speak_delay = -1
	}
})

pass_sound <- "Halloween.PumpkinDrop"
fail_sound <- "TF2Ware_Ultimate.Fail"

microgame_info <-
[
	// description                   overlay                                        custom score scaling
	[ "Don't Move!",                 "hud/tf2ware_ultimate/minigames/dont_move"            1, 1], // MICRO_SLEEP
	[ "Taunt!",                      "hud/tf2ware_ultimate/minigames/taunt"                1, 1], // MICRO_WAVE
	[ "Jump!",                       "hud/tf2ware_ultimate/minigames/jump"                 1, 1], // MICRO_HITCH
	[ "Crouch!",                     "hud/tf2ware_ultimate/minigames/crouch"               1, 1], // MICRO_SNEEZE
	[ "Move!",                       "hud/tf2ware_ultimate/minigames/move"                 1, 1], // MICRO_WALK
	[ "Swimming!",                   "hud/tf2ware_ultimate/minigames/gioca_jouer_swim"     1, 1], // MICRO_SWIM
	[ "Go Left!",                    "hud/tf2ware_ultimate/minigames/go_left"              1, 1], // MICRO_SKI
	[ "Look Down and Hit Spray!",    "hud/tf2ware_ultimate/minigames/gioca_jouer_spray"    1, 1], // MICRO_SPRAY
	[ "Spycrab!",                    "hud/tf2ware_ultimate/minigames/spycrab"              1, 1], // MICRO_MACHO
	[ "Use Kart Horn! (Left Click)", "hud/tf2ware_ultimate/minigames/gioca_jouer_horn"     1, 1], // MICRO_HORN
	[ "Jump + Crouch!",              "hud/tf2ware_ultimate/minigames/gioca_jouer_bell"     1, 1], // MICRO_BELL
	[ "Say Cheers! (C+3)",           "hud/tf2ware_ultimate/minigames/gioca_jouer_okay"     1, 1], // MICRO_OKAY
	[ "Call Medic!",                 "hud/tf2ware_ultimate/minigames/call_medic"           1, 1], // MICRO_KISS
	[ "Disguise!",                   "hud/tf2ware_ultimate/minigames/gioca_jouer_disguise" 0.9, 0.7], // MICRO_COMB
	[ "Taunt!",                      "hud/tf2ware_ultimate/minigames/taunt"                1, 0.8], // MICRO_WAVE2
	[ "Re-Taunt!",                   "hud/tf2ware_ultimate/minigames/retaunt"              1, 0.8], // MICRO_WAVE3
	[ "Rocket Jump!",                "hud/tf2ware_ultimate/minigames/rocket_jump"          0.85, 0.5], // MICRO_SUPER
	[ null,                          null,                                                 null, null], // MICRO_RESET
]

function OnPrecache()
{
	PrecacheScriptSound(pass_sound)
}

function OnPick()
{
	return Ware_TimeScale == 1.0 // gioca doesnt really work at other timescales
}

function OnStart()
{
	foreach(player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		minidata.gj_score <- 0
		minidata.gj_passed <- 0
		minidata.gj_is_pass <- false
		minidata.gj_combo <- 0
		minidata.gj_highest_chombo <- 0
	}
	// TODO: incorporate into array somehow?
	GiocaJouer_Countdown(5.43) // first round
	GiocaJouer_Countdown(83.05) // second round
	Ware_CreateTimer(@() PrintScorers(), 83.05)
	
	// set a timer for each microgame. each tick of
	// the "clock" ends the previous microgame,
	// increments "micro", and starts the next one.
	for (local i = 0; i < 18; i++)
	{
		Ware_CreateTimer(@() GiocaJouer_Clock(), 22.394 + (TIMER_FIRST * i))
		Ware_CreateTimer(@() GiocaJouer_Clock(), 101.723 + (TIMER_SECOND * i))
	}
}

function GetWinThreshhold()
{

	local win_threshold
	if (Ware_Players.len() > 64)
		win_threshold = 10
	else if (Ware_Players.len() > 24)
		win_threshold = 6
	else if (Ware_Players.len() > 3)
		win_threshold = 3
	else
		win_threshold = 1

	return win_threshold
}

function GetScoreList()
{
	local playerScoreList = []
	foreach (player in Ware_MinigamePlayers) 
	{
		local minidata = Ware_GetPlayerMiniData(player)
	    playerScoreList.append
		({
	        player = player
	        score = minidata.gj_score
			combo = minidata.gj_highest_chombo
	    })
	}

	playerScoreList.sort(@(a, b) b.score <=> a.score)

	return playerScoreList
}

function PrintScorers(printyou=true)
{
	local win_threshold = GetWinThreshhold()
	local playerScoreList = GetScoreList()
	for (local i = 0; i < win_threshold && i < playerScoreList.len(); i++) 
	{
	    Ware_ChatPrint(null, "{player}{color} has {int} points, with a combo high of {int}! ", 
			playerScoreList[i].player, TF_COLOR_DEFAULT, playerScoreList[i].score,  playerScoreList[i].combo)
	}

	local topPlayers = []
	for (local i = 0; i < win_threshold && i < playerScoreList.len(); i++)
	    topPlayers.append(playerScoreList[i].player)

	if (!printyou) return

	foreach (player in Ware_Players)
	{
		if (topPlayers.find(player) == null)
		{
			local minidata = Ware_GetPlayerMiniData(player)
			Ware_ChatPrint(player, "You have {int} points!", 
			minidata.gj_score)
		}
	}
}

function GiocaJouer_Countdown(delay)
{
	local timer = 1
	Ware_CreateTimer(function()
	{
		if (timer <= 8)
		{
			// count up to 8
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, format("hud/tf2ware_ultimate/countdown_%s", timer.tostring()))
			timer++
			return 0.489 * Ware_GetPitchFactor()
		}
		else
		{
			// kill the overlay
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, null)
		}
	}, delay * Ware_GetPitchFactor())
}

function GiocaJouer_Clock()
{
	if (micro == null)
		micro = 0
	else
	{
		OnMicroEnd()
		micro++
	}
	OnMicroStart()
}

function GiocaJouer_PassPlayer(player, pass)
{
	local minidata = Ware_GetPlayerMiniData(player)
	if ("gj_passed" in minidata)
	{
		if (pass)
			minidata.gj_passed += micro_second_phase ? 2 : 1
		//local text = pass ? "^" : "X"
		//Ware_ShowText(player, CHANNEL_BACKUP, text, 0.25, "255 255 255", -1, -0.5)
	}

}

function GetScoreThreshhold(gj_passed)
{
	local scores = [230, 205, 170, 140, 100]
	local sel = micro_second_phase ? 3 : 2
	for (local i = 0; i < scores.len(); i++) 
		scores[i] = scores[i] * microgame_info[micro][sel]
	for (local i = 0; i < scores.len(); i++) 
		if (gj_passed > scores[i])
			return i
	return 5
}

function GetScoreTextAndColor(gj_passed)
{
	local score = GetScoreThreshhold(gj_passed)
	local text
	local color
	if (score == 0) {text = "PERFECT!!"; color = "253 61 181"}
	else if (score == 1) {text = "GREAT!"; color = "0 255 255"}
	else if (score == 2) {text = "GOOD"; color = "0 255 0"}
	else if (score == 3) {text = "OK"; color = "255 255 255"}
	else if (score == 4) {text = "BAD"; color = "200 200 200"}
	else {text = "AWFUL"; color = "255 0 0"}
	return [text, color]
}

function ShowScores(player, gj_passed)
{
	local minidata = Ware_GetPlayerMiniData(player)

	local scores = GetScoreTextAndColor(gj_passed)
	local timer = micro_second_phase ? TIMER_SECOND / 2 : TIMER_FIRST / 2
	Ware_ShowText(player, CHANNEL_MINIGAME, scores[0] + " +" + floor(gj_passed).tostring(), timer, scores[1], -1, -0.55)
	//Ware_ShowText(player, CHANNEL_MINIGAME, scores[0], timer, scores[1], -1, -0.55)
	if (minidata.gj_combo > 1)
		Ware_ShowText(player, CHANNEL_BACKUP,
			minidata.gj_combo + " COMBO",
			timer, scores[1], -1, -0.60)
	/*Ware_ShowText(player, CHANNEL_BACKUP,
		"+" + floor(gj_passed).tostring() + " " + minidata.gj_combo + " COMBO",
		timer, scores[1], -1, -0.60)*/
}

function ComboCheck(player)
{
	local minidata = Ware_GetPlayerMiniData(player)
	local score = GetScoreThreshhold(minidata.gj_passed)
	if (score == 0)
	{
		minidata.gj_combo += 1
		if(minidata.gj_combo > minidata.gj_highest_chombo)
			minidata.gj_highest_chombo = minidata.gj_combo
	}
	else
		minidata.gj_combo = 0
}

function DisplayNextMicro(micro)
{
	if(micro > 16) return
	Ware_ShowText(Ware_Players, CHANNEL_MISC, "NEXT: " + microgame_info[micro][0], 4, "128 128 128", -1, -0.70)
}

function GiocaJouer_PassPlayerWithSpeed(player)
{
	local minidata = Ware_GetPlayerMiniData(player)
	if ("gj_passed" in minidata && "gj_is_pass" in minidata)
	{
		if (!minidata.gj_is_pass)
		{
			minidata.gj_is_pass = true
			local timer = micro_second_phase ? TIMER_SECOND*2 : TIMER_FIRST
			local sub_time = (Time() - micro_time_start)
			if (micro_second_phase) sub_time *= 2
			minidata.gj_passed += (timer - sub_time) * 75
			ComboCheck(player)
			ShowScores(player, minidata.gj_passed)		
		}
	}

}


function GiocaJouer_CheckTauntableMelee(player)
{
	// can't taunt with sharp dresser as spy
	local player_class = player.GetPlayerClass()
	if (player_class == TF_CLASS_SPY)
	{
		local melee = player.GetActiveWeapon()		
		local id = GetPropInt(melee, "m_AttributeManager.m_Item.m_iItemDefinitionIndex")
		if (id == 638)
		{
			melee.Kill()
			Ware_GivePlayerWeapon(player, "Knife")			
		}
	}
	// or heavy with all-class melee
	else if (player_class == TF_CLASS_HEAVYWEAPONS)
	{
		local melee = player.GetActiveWeapon()
		if (melee && melee.GetName() == "tf_weapon_fireaxe")
		{
			melee.Kill()
			Ware_GivePlayerWeapon(player, "Fists")			
		}
	}
}

function OnMicroStart()
{
	//DisplayNextMicro(micro+1)
	minigame.description = microgame_info[micro][0]
	Ware_ShowScreenOverlay(Ware_MinigamePlayers, microgame_info[micro][1])

	micro_time_start = Time()
	
	// if we consider reset a microgame, we dont have to make a separate function
	if (micro == MICRO_RESET)
	{
		micro = null
		micro_second_phase = true
		return
	}
	
	// start passed? and also any microgames that need setup
	foreach(player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		
		// put default case outside of switch to avoid repeating on false cases that need other code
		GiocaJouer_PassPlayer(player, false)
		switch (micro)
		{
			case MICRO_SLEEP:
			case MICRO_WALK:
				GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SWIM:
				player.AddCond(TF_COND_SWIMMING_CURSE)
				break
			case MICRO_HORN:
				player.AddCond(TF_COND_HALLOWEEN_KART)
				break
			case MICRO_WAVE:
			case MICRO_WAVE2:
			// WAVE3 forces a class switch
				GiocaJouer_CheckTauntableMelee(player)
				break
		}
	}
	
	// loadouts. can move to switch if a non-global loadout function is made
	if (micro == MICRO_MACHO)
	{
		Ware_SetGlobalLoadout(TF_CLASS_SPY, "Disguise Kit")
	}
	else if (micro == MICRO_COMB)
	{
		Ware_DelayPDASwitch = true
		Ware_SetGlobalLoadout(TF_CLASS_SPY, "Disguise Kit")
		Ware_DelayPDASwitch = false
	}
	// do this one a minigame early bcuz original did it. otherwise move to MICRO_SUPER
	else if (micro == MICRO_WAVE3)
	{
		Ware_SetGlobalLoadout(TF_CLASS_SOLDIER, "Rocket Jumper")
	}
}

function OnUpdate()
{
	// setup for MICRO_SPRAY, inefficient inside the foreach
	local sprayed_players = []
	if (micro == MICRO_SPRAY)
	{
		for (local can; can = FindByClassname(can, "spraycan");)
		{
			MarkForPurge(can)
			can.KeyValueFromString("classname", "ware_spraycan")
			sprayed_players.append(can.GetOwner())
		}
	}
	
	// microgame rules
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		switch (micro)
		{
			case MICRO_SLEEP:
				if (player.GetAbsVelocity().Length() < 5.0)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_WAVE:
			case MICRO_WAVE2:
			case MICRO_WAVE3:
				if (player.IsTaunting())
					GiocaJouer_PassPlayerWithSpeed(player)
				break
			case MICRO_HITCH:
				if (GetPropBool(player, "m_Shared.m_bJumping"))
					GiocaJouer_PassPlayerWithSpeed(player)
				break
			case MICRO_SNEEZE:
				if (player.GetFlags() & FL_DUCKING)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_WALK:
				if (player.GetAbsVelocity().Length() > 75.0)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SWIM:
				if (player.GetAbsVelocity().Length() > 75.0)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SKI:
				if (GetPropInt(player, "m_nButtons") & IN_MOVELEFT)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SPRAY:
				if (sprayed_players.find(player) != null)
					GiocaJouer_PassPlayerWithSpeed(player)
				break
			case MICRO_MACHO:
				if ((player.GetFlags() & FL_DUCKING) && (player.EyeAngles().x < -70.0))
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_BELL:
				if (GetPropBool(player, "m_Shared.m_bJumping") && (player.GetFlags() & FL_DUCKING))
					GiocaJouer_PassPlayerWithSpeed(player)
				break
			case MICRO_COMB:
				if (player.InCond(TF_COND_DISGUISING) || player.InCond(TF_COND_DISGUISED))
				{
					GiocaJouer_PassPlayerWithSpeed(player)
					player.RemoveCond(TF_COND_DISGUISING)					
					player.RemoveCond(TF_COND_DISGUISED)
				}
				break
			case MICRO_SUPER:
				if (player.GetOrigin().z > -6900.0)
					GiocaJouer_PassPlayerWithSpeed(player)
				break
		}
	}
}

function OnPlayerHorn(player)
{
	if (micro == MICRO_HORN)
		GiocaJouer_PassPlayerWithSpeed(player)
}

function OnPlayerVoiceline(player, voiceline)
{
	if (voiceline in VCD_MAP)
	{
		switch (micro)
		{
			case MICRO_OKAY:
				if (VCD_MAP[voiceline].find(".Cheers") != null)
					GiocaJouer_PassPlayerWithSpeed(player)
				break
			case MICRO_KISS:
				if (VCD_MAP[voiceline].find(".Medic") != null)
					GiocaJouer_PassPlayerWithSpeed(player)
				break
		}
	}
}

function OnMicroEnd()
{
	foreach(player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
		local minidata = Ware_GetPlayerMiniData(player)
		
		// specific minigame cleanup
		switch (micro)
		{
			case MICRO_WAVE:
			case MICRO_WAVE2:
			case MICRO_WAVE3:
				ForceRemovePlayerTaunt(player)
				break
			case MICRO_SWIM:
				player.RemoveCond(TF_COND_SWIMMING_CURSE)
				player.RemoveCond(TF_COND_URINE)
				break
			case MICRO_HORN:
				player.RemoveCond(TF_COND_HALLOWEEN_KART)
				break
			case MICRO_COMB:
			case MICRO_MACHO:
			case MICRO_SUPER:
				Ware_StripPlayer(player, true)
				break
		}
		if (!minidata.gj_is_pass)
		{
			ComboCheck(player)
			ShowScores(player, minidata.gj_passed)

		}
			
		if (minidata.gj_passed>70)
		{			

			// TODO: move emitsound to when you pass the objective for each microgame.
			// For microgames that start false, play it ONCE when you call GiocaJouer_PassPlayer(player, true)
			// For microgames that start true, keep it here in OnEnd()
			// also lower the volume
			EmitSoundOnClient(pass_sound, player)
		}
		else
		{
			EmitSoundOnClient(fail_sound, player)
		}

		minidata.gj_score += minidata.gj_passed + minidata.gj_combo
		minidata.gj_passed = 0
		minidata.gj_is_pass = false
	}
}

function OnEnd()
{
	local winners = []

	local win_threshold = GetWinThreshhold()
	local playerScoreList = GetScoreList()
	for (local i = 0; i < win_threshold && i < playerScoreList.len(); i++) 
	{
	    Ware_ChatPrint(null, "{player}{color} has {int} points, with a combo high of {int}! ", 
			playerScoreList[i].player, TF_COLOR_DEFAULT, playerScoreList[i].score,  playerScoreList[i].combo)
	}

	local winners = []
	local low_score = min_score
	for (local i = 0; i < win_threshold && i < playerScoreList.len(); i++)
	{
		if (playerScoreList[i].score >= min_score)
	    	winners.append(playerScoreList[i].player)
		low_score = playerScoreList[i].score
	}


	if (winners.len() >= 1)
	{
		foreach(player in winners)
		{
			Ware_PassPlayer(player, true)
			Ware_ChatPrint(player, "You won! Your score was {color}{int}",	
				COLOR_LIME, Ware_GetPlayerMiniData(player).gj_score)
		}
		foreach(player in Ware_MinigamePlayers)
		{
			if (!Ware_IsPlayerPassed(player))
			{
				Ware_ChatPrint(player, "You lose! Your score was {color}{int}{color}, but you needed to get {color}{int}",
					COLOR_LIME, Ware_GetPlayerMiniData(player).gj_score, TF_COLOR_DEFAULT
					COLOR_LIME, low_score)
			}
		}
		Ware_GiveBonusPoints(winners[0])
	}
	else
	{
		foreach(player in Ware_MinigamePlayers)
		{
			if (!Ware_IsPlayerPassed(player))
			{
				Ware_ChatPrint(player, "You lose! Your score was {color}{int}{color}, but you needed to get {color}{int}",
					COLOR_LIME, Ware_GetPlayerMiniData(player).gj_score, TF_COLOR_DEFAULT
					COLOR_LIME, min_score)
			}
		}
	}
}
