arenas <-
[
	"beepblockskyway_micro"
	"beepblockskyway_ultimate"
]

minigame <- Ware_MinigameData
({
	name           = "Beep Block Skyway"
	author         = ["Gemidyne", "pokemonPasta"]
	description    = "Get to the End!"
	custom_overlay = "get_end"
	duration       = 130.0
	end_delay      = 1.1
	location       = RandomElement(arenas)
	fail_on_death  = true
	start_freeze   = 0.5
	convars =
	{
		tf_avoidteammates = 0
	}
})

// variables
tempo            <- 0.0
tempo_increase   <- 1.2
beat             <- 0.0
bgm_offset       <- 0.0
interrupted      <- false
interrupt_timer  <- FLT_MAX

beep_sound <- Ware_FixupMP3("tf2ware_ultimate/v%d/beep_block_beep.mp3")
swap_sound <- Ware_FixupMP3("tf2ware_ultimate/v%d/beep_block_door.mp3")
hurryup_sound <- Ware_FixupMP3("tf2ware_ultimate/v%d/hurryup.mp3")
tele_sound <- "Building_Teleporter.Send"

// brushes
green_blocks    <- []
yellow_blocks   <- []
active_blocks   <- RandomElement([green_blocks, yellow_blocks])
inactive_blocks <- active_blocks == green_blocks ? yellow_blocks : green_blocks

// trigger brushes
endzone <- FindByName(null, "plugin_Bossgame5_WinArea")
tele1   <- FindByName(null, "BeepBlock_Tele1")
tele2   <- FindByName(null, "BeepBlock_Tele2")

function OnPrecache()
{
	PrecacheSound(beep_sound)
	PrecacheSound(swap_sound)
	PrecacheSound(hurryup_sound)
	PrecacheScriptSound(tele_sound)
	
	Ware_PrecacheMinigameMusic("beepblockskyway", true)
	Ware_PrecacheMinigameMusic("beepblockskyway-twelve", true)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_ENGINEER)
	
	// fixes tilting from fall damage on ramp near the end of _ultimate arena
	Ware_SetGlobalCondition(TF_COND_GRAPPLINGHOOK)
	
	// separate entities are needed to keep bounding box within separate areas and not break visibility
	// these do/while loops append all beatblocks to their appropriate array, and then BeepBlock_FireInput
	// checks for array and fires across all entities in array
	for (local ent; ent = FindByName(ent, "beatblock_green");)
		green_blocks.append(ent)

	for (local ent; ent = FindByName(ent, "beatblock_yellow");)
		yellow_blocks.append(ent)
	
	BeepBlock_FireInput(green_blocks, "Alpha", "255")
	BeepBlock_FireInput(yellow_blocks, "Alpha", "255")
	
	BeepBlock_FireInput(active_blocks, "Enable")
	BeepBlock_FireInput(inactive_blocks, "Disable")
	
	endzone.ValidateScriptScope()
	endzone.GetScriptScope().OnStartTouch <- OnEndzoneTouch
	endzone.GetScriptScope().first <- true
	endzone.ConnectOutput("OnStartTouch", "OnStartTouch")
	
	tele1.ValidateScriptScope()
	tele1.GetScriptScope().OnStartTouch <- OnTele1Touch
	tele1.GetScriptScope().tele_sound <- tele_sound
	tele1.ConnectOutput("OnStartTouch", "OnStartTouch")
	
	tele2.ValidateScriptScope()
	tele2.GetScriptScope().OnStartTouch <- OnTele2Touch
	tele2.GetScriptScope().tele_sound <- tele_sound
	tele2.ConnectOutput("OnStartTouch", "OnStartTouch")
	
	Ware_CreateTimer(function(){StartBlocks()}, 0.7)
}

function StartBlocks()
{
	if (RandomInt(0, 9) != 0)
	{
		minigame.music = "beepblockskyway"
		BeepBlock_SetTempo(120.0)
		bgm_offset = 0.028
	}
	else
	{
		minigame.music = "beepblockskyway-twelve"
		BeepBlock_SetTempo(140.0)
		bgm_offset = -0.097
	}
	Ware_PlayMinigameMusic(null, minigame.music)
	
	// using return in the timer for each subsequent sequence seems to add up a lot of processing delays over time
	// instead, we create all the sequences at the start, offset every 2 bars using i
	// this has more consistent timing, though it is a bit less flexible
	local sequence_count = ceil(minigame.duration / (8.0 * beat))
	for (local i = 0; i < sequence_count; i++)
	{
		Ware_CreateTimer(function() {
			if (!interrupted)
				BeepBlock_Sequence()
		}, bgm_offset + (6.0 * beat) + i * (8.0 * beat))
	}
}

function OnUpdate()
{
	if (((Ware_MinigamePlayers.len() > 1 && !endzone.GetScriptScope().first) || floor(Ware_GetMinigameRemainingTime()) == 30.0) && !interrupted)
		BeepBlock_Interrupt()
}

// no fall damage, but trigger_hurt uses fall damage so we check for that too
function OnTakeDamage(params)
{
	if ((params.damage_type & DMG_FALL) && params.inflictor.GetClassname() != "trigger_hurt")
		params.damage = 0.0
}

function BeepBlock_Sequence()
{
	local i = 0
	Ware_CreateTimer(function() {
		if (i++ < 3)
		{
			Ware_PlaySoundOnAllClients(beep_sound, 0.6)
			BeepBlock_Beep()
			return beat
		}
		else
		{
			Ware_PlaySoundOnAllClients(swap_sound)
			BeepBlock_Swap()
		}
	}, 0.0)
}

function BeepBlock_Beep()
{
	BeepBlock_FireInput(active_blocks, "Alpha", "210")
	
	Ware_CreateTimer(function() {
		BeepBlock_FireInput(active_blocks, "Alpha", "255")
	}, (beat / 2.0))
}

function BeepBlock_Swap()
{
	BeepBlock_FireInput(active_blocks, "Disable")
	BeepBlock_FireInput(inactive_blocks, "Enable")
	
	active_blocks <- inactive_blocks
	inactive_blocks <- active_blocks == green_blocks ? yellow_blocks : green_blocks
}

function BeepBlock_Interrupt()
{
	if (interrupted)
		return
	
	interrupted = true
	
	Ware_PlayMinigameMusic(null, minigame.music, SND_STOP)
	Ware_ShowScreenOverlay(Ware_MinigamePlayers, "hud/tf2ware_ultimate/minigames/hurry_up")
	Ware_PlaySoundOnAllClients(hurryup_sound)
	
	Ware_CreateTimer(function() {
		Ware_PlaySoundOnAllClients(format("tf2ware_ultimate/v%d/music_bossgame/%s.mp3", WARE_MP3_VERSION, minigame.music),
		1.0, 100 * Ware_GetPitchFactor() * tempo_increase)
		
		BeepBlock_SetTempo(tempo * tempo_increase)
		
		local sequence_count = ceil(Ware_GetMinigameRemainingTime() / (8.0 * beat))
		for (local i = 0; i < sequence_count; i++)
		{
			Ware_CreateTimer(function() {
				BeepBlock_Sequence()
			}, bgm_offset * tempo_increase + (6.0 * beat) + i * (8.0 * beat))
		}
		
		local length = Min(60, Round(Ware_GetMinigameRemainingTime()).tointeger())
		interrupt_timer = Time() + length - 1.0
		
		local timer = Ware_SpawnEntity("team_round_timer",
		{
			timer_length   = length,
			auto_countdown = false,
			show_in_hud    = true,
			show_time_remaining = true,
		})
		EntityAcceptInput(timer, "Resume")
	}, 3.0)
	
}

function BeepBlock_SetTempo(desired_tempo)
{
	tempo = desired_tempo
	beat = 60.0 / tempo
}

function BeepBlock_FireInput(target, action, params = "")
{
	if (typeof(target) == "array")
	{
		foreach(ent in target)
			EntityAcceptInput(ent, action, params)
	}
	else
		EntityAcceptInput(target, action, params)
}

function OnEndzoneTouch()
{
	local player = activator
	
	if (player.IsPlayer() && player.IsValid() && !Ware_IsPlayerPassed(player))
	{
		local hms = FloatToTimeHMS(Ware_GetMinigameTime())
		if (first)
		{
			Ware_ChatPrint(null, "{player} {color}reached the end first in {%d}:{%02d}!", 
				player, TF_COLOR_DEFAULT, hms.minutes, hms.seconds)
				Ware_GiveBonusPoints(player)
			first = false
		}
		else
		{
			Ware_ChatPrint(player, "{color}You reached the end in {%d}:{%02d}!", 
				TF_COLOR_DEFAULT, hms.minutes, hms.seconds)
		}
		
		Ware_PassPlayer(player, true)
		Ware_CreateTimer(@() Ware_ShowScreenOverlay(player, null), 0.02)
	}
}

function OnTele1Touch()
{
	local player = activator
	
	if (player.IsPlayer() && player.IsValid())
	{
		Ware_PlaySoundOnClient(player, tele_sound)
		Ware_AddPlayerAttribute(player, "increased jump height", 1.15, Ware_GetMinigameRemainingTime())
	}
}

function OnTele2Touch()
{
	local player = activator
	
	if (player.IsPlayer() && player.IsValid())
	{
		Ware_PlaySoundOnClient(player, tele_sound)
		player.RemoveCustomAttribute("increased jump height")
	}
}

function OnEnd()
{
	endzone.DisconnectOutput("OnStartTouch", "OnStartTouch")
	tele1.DisconnectOutput("OnStartTouch", "OnStartTouch")
	tele2.DisconnectOutput("OnStartTouch", "OnStartTouch")
	
	BeepBlock_FireInput(green_blocks, "Alpha", "255")
	BeepBlock_FireInput(yellow_blocks, "Alpha", "255")
}

function OnCheckEnd()
{
	return BeepBlock_CheckEnd() || Time() >= interrupt_timer
}

function BeepBlock_CheckEnd()
{
	return Ware_GetPassedPlayers(false, true).len() == 0
}
