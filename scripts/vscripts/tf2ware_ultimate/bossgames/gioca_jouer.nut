
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

chrises <-
[
	"tf2ware_ultimate/gioca/sleep"
	"tf2ware_ultimate/gioca/wave"
	"tf2ware_ultimate/gioca/hitch"
	"tf2ware_ultimate/gioca/sneeze"
	"tf2ware_ultimate/gioca/walk"
	"tf2ware_ultimate/gioca/swim"
	"tf2ware_ultimate/gioca/ski"
	"tf2ware_ultimate/gioca/spray"
	"tf2ware_ultimate/gioca/macho"
	"tf2ware_ultimate/gioca/horn"
	"tf2ware_ultimate/gioca/ring"
	"tf2ware_ultimate/gioca/ok"
	"tf2ware_ultimate/gioca/kiss"
	"tf2ware_ultimate/gioca/comb"
	"tf2ware_ultimate/gioca/wave2nd"
	"tf2ware_ultimate/gioca/wave3rd"
	"tf2ware_ultimate/gioca/super"
]

micro <- null        // microgame tracker
micro_num <- 0        // microgame num
min_score <- 16      // minimum score to win. Only the players with the highest score win, might change this to just check min_score, and increase min_score.
micro_grace <- false // tracks grace period for certain microgames.

micro_rotation <- [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16]

minigame <- Ware_MinigameData
({
	name          = "Gioca Jouer"
	author        = ["TonyBaretta", "pokemonPasta"]
	description   = "Gioca Jouer!"
	duration      = 140.0
	end_delay     = 1.0
	location      = "boxarena"
	music         = "giocajourer-inst"
	start_pass    = false
})

pass_sound <- "Halloween.PumpkinDrop"
fail_sound <- "TF2Ware_Ultimate.Fail"

announcements <-
[
	["tf2ware_ultimate/gioca/123.mp3", 5.511],
	["tf2ware_ultimate/gioca/yaa.mp3", 80.727],
	["tf2ware_ultimate/gioca/1232.mp3", 83.05],
	["tf2ware_ultimate/gioca/superdance.mp3", 87.403],
	["tf2ware_ultimate/gioca/alright.mp3", 132.380],
]

microgame_info <-
[
	// description                   overlay                                                absolute times
	[ "Don't Move!",                 "hud/tf2ware_ultimate/minigames/dont_move",            22.394, 101.723 ], // MICRO_SLEEP
	[ "Taunt!",                      "hud/tf2ware_ultimate/minigames/taunt",                25.671, 103.255 ], // MICRO_WAVE
	[ "Jump!",                       "hud/tf2ware_ultimate/minigames/jump",                 29.103, 105.039 ], // MICRO_HITCH
	[ "Crouch!",                     "hud/tf2ware_ultimate/minigames/crouch",               33.147, 106.812 ], // MICRO_SNEEZE
	[ "Move!",                       "hud/tf2ware_ultimate/minigames/move",                 36.428, 108.627 ], // MICRO_WALK
	[ "Swimming!",                   "hud/tf2ware_ultimate/minigames/gioca_jouer_swim",     40.368, 110.264 ], // MICRO_SWIM
	[ "Go Left!",                    "hud/tf2ware_ultimate/minigames/go_left",              43.908, 112.206 ], // MICRO_SKI
	[ "Look Down and Hit Spray!",    "hud/tf2ware_ultimate/minigames/gioca_jouer_spray",    47.361, 114.010 ], // MICRO_SPRAY
	[ "Spycrab!",                    "hud/tf2ware_ultimate/minigames/spycrab",              50.563, 115.689 ], // MICRO_MACHO
	[ "Use Kart Horn! (Left Click)", "hud/tf2ware_ultimate/minigames/gioca_jouer_horn",     53.875, 117.515 ], // MICRO_HORN
	[ "Jump + Crouch!",              "hud/tf2ware_ultimate/minigames/gioca_jouer_bell",     58.288, 119.372 ], // MICRO_BELL
	[ "Say Cheers! (C+3)",           "hud/tf2ware_ultimate/minigames/gioca_jouer_okay",     61.402, 121.146 ], // MICRO_OKAY
	[ "Call Medic!",                 "hud/tf2ware_ultimate/minigames/call_medic",           65.550, 123.182 ], // MICRO_KISS
	[ "Disguise!",                   "hud/tf2ware_ultimate/minigames/gioca_jouer_disguise", 68.572, 124.682 ], // MICRO_COMB
	[ "Taunt!",                      "hud/tf2ware_ultimate/minigames/taunt",                72.226, 126.529 ], // MICRO_WAVE2
	[ "Re-Taunt!",                   "hud/tf2ware_ultimate/minigames/retaunt",              75.954, 128.775 ], // MICRO_WAVE3
	[ "Rocket Jump!",                "hud/tf2ware_ultimate/minigames/rocket_jump",          79.432, 130.411 ], // MICRO_SUPER
	[ null,                          null,                                                  82.961, 132.342 ], // MICRO_RESET
]

function OnPrecache()
{
	PrecacheScriptSound(pass_sound)
	foreach(announcement in announcements)
	{
		PrecacheSound(announcement[0])
	}
	foreach(sound in chrises)
	{
		PrecacheSound(format("%s.mp3", sound))
		PrecacheSound(format("%s2.mp3", sound))
	}
}


function OnStart()
{
	foreach(player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		minidata.gj_score <- 0
		minidata.gj_passed <- false
	}
	// TODO: incorporate into array somehow?
	GiocaJouer_Countdown(5.43) // first round
	GiocaJouer_Countdown(83.05) // second round
	
	// set a timer for each microgame. each tick of
	// the "clock" ends the previous microgame,
	// increments "micro", and starts the next one.

	Shuffle(micro_rotation)
	micro_rotation.append(MICRO_RESET)

	foreach(announcement in announcements)
	{
		local sound = announcement[0] //squirrel
		Ware_CreateTimer(@() Ware_PlaySoundOnAllClients(sound), announcement[1])
	}
	foreach (microgame in microgame_info)
	{
		Ware_CreateTimer(@() GiocaJouer_Clock(), microgame[2])
		Ware_CreateTimer(@() GiocaJouer_Clock(), microgame[3])
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
			return 0.489
		}
		else
		{
			// kill the overlay
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, null)
		}
	}, delay)
}

function GiocaJouer_Clock()
{
	if (micro == null)
	{
		micro = 0
		if(micro_num > 0)
			micro_num++
	}
	else
	{
		OnMicroEnd()
		micro_num++
	}
	OnMicroStart()
}

function GiocaJouer_PassPlayer(player, pass)
{
	local minidata = Ware_GetPlayerMiniData(player)
	if ("gj_passed" in  minidata)
		minidata.gj_passed = pass
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
	micro = micro_rotation[micro_num%18]
	minigame.description = microgame_info[micro][0]
	Ware_ShowScreenOverlay(Ware_MinigamePlayers, microgame_info[micro][1])

	// if we consider reset a microgame, we dont have to make a separate function
	if (micro == MICRO_RESET)
	{
		micro = null
		return
	}

	local sound = chrises[micro]
	if(micro_num > 16) sound += "2"
	sound += ".mp3"
	Ware_PlaySoundOnAllClients(sound)

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
				micro_grace <- true
				Ware_CreateTimer(function() {micro_grace <- false}, 1.0) // can't be more than about 2sec
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
	else if (micro == MICRO_SUPER)
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
				if (player.GetAbsVelocity().Length() > 5.0 && !micro_grace)
					GiocaJouer_PassPlayer(player, false)
				break
			case MICRO_WAVE:
			case MICRO_WAVE2:
			case MICRO_WAVE3:
				if (player.IsTaunting())
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_HITCH:
				if (GetPropBool(player, "m_Shared.m_bJumping"))
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SNEEZE:
				if (player.GetFlags() & FL_DUCKING)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_WALK:
				if (player.GetAbsVelocity().Length() < 75.0 && !micro_grace)
					GiocaJouer_PassPlayer(player, false)
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
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_MACHO:
				if ((player.GetFlags() & FL_DUCKING) && (player.EyeAngles().x < -70.0))
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_BELL:
				if (GetPropBool(player, "m_Shared.m_bJumping") && (player.GetFlags() & FL_DUCKING))
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_SUPER:
				if (player.GetOrigin().z > -6900.0)
					GiocaJouer_PassPlayer(player, true)
				break
		}
	}
}

function OnPlayerHorn(player)
{
	if (micro == MICRO_HORN)
		GiocaJouer_PassPlayer(player, true)
}

function OnPlayerVoiceline(player, voiceline)
{
	if (voiceline in VCD_MAP)
	{
		switch (micro)
		{
			case MICRO_OKAY:
				if (VCD_MAP[voiceline].find(".Cheers") != null)
					GiocaJouer_PassPlayer(player, true)
				break
			case MICRO_KISS:
				if (VCD_MAP[voiceline].find(".Medic") != null)
					GiocaJouer_PassPlayer(player, true)
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
				if (player.InCond(TF_COND_DISGUISING) || player.InCond(TF_COND_DISGUISED))
				{
					GiocaJouer_PassPlayer(player, true)
					player.RemoveCond(TF_COND_DISGUISING)					
					player.RemoveCond(TF_COND_DISGUISED)
				}
				Ware_StripPlayer(player, true)
				break
			case MICRO_MACHO:
			case MICRO_SUPER:
				Ware_StripPlayer(player, true)
				break
		}
		if (minidata.gj_passed)
		{
			minidata.gj_score++
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
	}
}

function OnEnd()
{
	local high_score = 0
	local winners = []
	foreach(player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		local score = minidata.gj_score
		
		if (score > high_score)
		{
			high_score = score
			winners.clear()
			winners.append(player)
			continue
		}
		
		if (score == high_score)
		{
			winners.append(player)
			continue
		}
	}
	if (high_score >= min_score)
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
				Ware_ChatPrint(player, "You lose! Your score was {color}{int}{color}, but the winning score was {color}{int}",
					COLOR_LIME, Ware_GetPlayerMiniData(player).gj_score, TF_COLOR_DEFAULT
					COLOR_LIME, high_score)
			}
		}
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
