mode <- 0
if (RandomInt(1, 10) == 1 || Ware_IsSpecialRoundSet("math_only"))
	mode = 1

minigame <- Ware_MinigameData
({
	name           = mode == 0 ? "Super Typing Attack 2: Goodbye Keyboard" : "Hyper Math Rumble: Digit Destruction"
	author         = ["Gemidyne", "ficool2"]
	description    = mode == 0 ? "Type each word as fast as you can!" : "Solve each question as fast as you can!"
	duration       = 210.0
	end_delay      = 5.0
	min_players    = 2
	location       = "typing"
	music          = null
	custom_overlay = ""
})

sound_boss_start       <- "TF2Ware_Ultimate.TypingBossStart"
sound_descent_begin    <- "TF2Ware_Ultimate.TypingDescentBegin"
sound_spiral_inward    <- "TF2Ware_Ultimate.TypingSpiralInward"
sound_bad_end          <- "TF2Ware_Ultimate.TypingBadEnd"
sound_good_end         <- "TF2Ware_Ultimate.TypingGoodEnd"
sound_level_up         <- "TF2Ware_Ultimate.TypingLevelUp"
sound_difficulty_up    <- "TF2Ware_Ultimate.TypingDifficultyUp"
sound_overview_start   <- "TF2Ware_Ultimate.TypingOverviewStart"
sound_word_start       <- "TF2Ware_Ultimate.TypingWordStart"
sound_word_fail        <- "TF2Ware_Ultimate.TypingWordFail"
sound_word_success     <- "TF2Ware_Ultimate.TypingWordSuccess"
sound_word_relax       <- "TF2Ware_Ultimate.TypingWordRelax"

if (mode == 0)
{
	overlay_type         <- "hud/tf2ware_ultimate/minigames/typing"
	overlay_prepare      <- "hud/tf2ware_ultimate/minigames/typing_prepare"
	overlay_difficulty   <- "hud/tf2ware_ultimate/minigames/typing_difficulty"
}
else
{
	overlay_type         <- "hud/tf2ware_ultimate/minigames/type_answers"
	overlay_prepare      <- "hud/tf2ware_ultimate/minigames/type_answers_prepare"
	overlay_difficulty   <- "hud/tf2ware_ultimate/minigames/type_answers_difficulty"
}

overlay_announcement <- "hud/tf2ware_ultimate/minigames/announcement"

music_choices <- ["hga", "hvd", "lod", "pta", "spc", "tuh"]
current_music <- null

difficulty <- 0
level <- 0

if (mode == 0)
{
	difficulties <- ["Easy", "Medium", "Hard"]
	dictionary <- {}
	IncludeScript("tf2ware_ultimate/bossgames/data/dictionary", dictionary)
}

word_typing <- false
word_type_duration <- 20.0
word_rotation <- []
word_high_score <- 0
word_timer <- null
median_score <- 0
game_over <- false

function OnPrecache()
{
	PrecacheScriptSound(sound_boss_start)
	PrecacheScriptSound(sound_descent_begin)
	PrecacheScriptSound(sound_spiral_inward)
	PrecacheScriptSound(sound_bad_end)
	PrecacheScriptSound(sound_good_end)
	PrecacheScriptSound(sound_level_up)
	PrecacheScriptSound(sound_difficulty_up)
	PrecacheScriptSound(sound_overview_start)
	PrecacheScriptSound(sound_word_start)
	PrecacheScriptSound(sound_word_fail)
	PrecacheScriptSound(sound_word_success)
	PrecacheScriptSound(sound_word_relax)     

	PrecacheOverlay(overlay_type)
	PrecacheOverlay(overlay_prepare)
	PrecacheOverlay(overlay_difficulty)
	PrecacheOverlay(overlay_announcement)
	
	foreach (choice in music_choices)
		Ware_PrecacheMinigameMusic("typing-" + choice, true)
}

function OnPick()
{
	return !Ware_IsSpecialRoundSet("no_text")
}

function OnStart()
{
	Ware_ToggleChatFlood(false)
	
	Ware_PlaySoundOnAllClients(sound_boss_start)
	CreateTimer(Descent, 3.0)
	
	foreach (player in Ware_Players)
		player.AddFlag(FL_ATCONTROLS)
}

function OnCleanup()
{
	Ware_ToggleChatFlood(true)

	SetCamera(null)
	
	Ware_PlayMinigameMusic(null, current_music, SND_STOP)
	
	foreach (player in Ware_Players)
		player.RemoveFlag(FL_ATCONTROLS)
}

function Descent()
{
	EntFire("DRBoss_DescentSequence_Start", "Trigger")
	SetCamera("DRBoss_DescentCamera_Point")
	Ware_PlaySoundOnAllClients(sound_descent_begin)
	Ware_ShowScreenOverlay(Ware_Players, null)
	Ware_ShowMinigameText(Ware_Players, "")
	current_music = "typing-" + RemoveRandomElement(music_choices)
	Ware_PlayMinigameMusic(null, current_music)
	CreateTimer(Prepare, 3.5)
}

function Prepare()
{
	EntFire("DRBoss_SpinInCamera_Start", "Trigger")
	SetCamera("DRBoss_SpiralCamera_Point")
	Ware_PlaySoundOnAllClients(sound_spiral_inward)
	Ware_ShowScreenOverlay(Ware_Players, overlay_prepare)
	CreateTimer(StartWords, 3.5)
}

function GenerateWords()
{
	word_rotation.clear()
	
	if (mode != 0)
	{
		for (local n = 0; n < 50; n++)
		{
			local var_count = difficulty + 2
			local min = 0, max = 12
			local numbers = [RandomInt(min, max)]
			local operators = ["+", "-", "*"]
			local expression = numbers[0].tostring()
			local result = numbers[0]

			for (local i = 1; i < var_count; i++)
			{
				// only first operator can be multiply/divide
				local operator_max = i == 1 ? 2 : 1
				local operator = operators[RandomInt(0, operator_max)]
				local number
				
				switch (operator) 
				{
					case "+":
						number = RandomInt(min, max + 3)
						result += number
						break
					case "-":
						number = RandomInt(min, max + 3)
						result -= number
						break
					case "*":
						local mul = RandomInt(1, 10) == 1 ? -1 : 1
						number = RandomInt(min, max) * mul
						result *= number
						break
				}	
				
				numbers.append(number)
				expression += " " + operator + " " + number
			}
			
			word_rotation.append
			({
				numbers    = numbers				
				expression = expression
				result     = result	
			})			
		}
	}
	else
	{
		word_rotation = Shuffle(clone(dictionary[difficulties[difficulty]]))
	}
}

function StartWords()
{
	EntFire("DRBoss_CloseupCamera_Start", "Trigger")
	SetCamera("DRBoss_CloseupCamera_Point")
	Ware_PlaySoundOnAllClients(sound_word_start)
	
	GenerateWords()

	foreach (player in Ware_Players)
	{
		Ware_ShowScreenOverlay(player, player.IsAlive() ? overlay_type : null)
			
		if (Ware_MinigamePlayers.find(player) != null)
		{
			local minidata = Ware_GetPlayerMiniData(player)
			minidata.score <- player.IsFakeClient() ? RandomInt(0, 5) : 0 // debug
			minidata.word_count <- 0
			if (!("word_count_total" in minidata))
				minidata.word_count_total <- 0
			if (player.IsAlive())
			{
				ResetPlayerChatCooldown(player)
				ShowWord(player, 0)		
			}
		}
	}
	
	word_typing = true
	word_timer = Ware_SpawnEntity("team_round_timer",
	{
		timer_length        = word_type_duration
		auto_countdown      = true
		show_in_hud         = true
		show_time_remaining = true
	})
	EntityAcceptInput(word_timer, "Resume")
	
	CreateTimer(EndWords, word_type_duration)
}

function EndWords()
{
	word_typing = false
	word_timer.Kill()
	
	Ware_ShowScreenOverlay(Ware_Players, overlay_announcement)
	Ware_PlayMinigameMusic(null, current_music, SND_STOP)
	Ware_ShowText(Ware_Players, CHANNEL_BACKUP, "", 1.0)
			
	EntFire("DRBoss_OverviewSequence_Start", "Trigger")
	SetCamera("DRBoss_DescentCamera_Point")
	
	local players = [], scores = []
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		if (player.IsAlive())
		{
			players.append(player)		
			scores.append(minidata.score)
				
			if (mode == 0)
			{
				// double the reported WPM to compensate for chat delay
				Ware_ChatPrint(player, "Your words-per-minute (WPM) was {color}{int}", COLOR_LIME, 
					(minidata.word_count / (word_type_duration / 60.0)).tointeger() * 1.5)
			}			
		}
	}
	if (scores.len() == 0)
	{
		CheckGameOver()
		return
	}
	
	Ware_PlaySoundOnAllClients(sound_overview_start)
	
	scores.sort(@(a, b) b <=> a)
	median_score = Max(Median(scores), 1)
	
	local failed = 0, max_display = 6
	local failed_players = []
	local text
	if (mode == 0)
		text = "The players with the lowest number of words typed were...\n"	
	else
		text = "The players with the lowest number of solved questions were...\n"
	
	if (median_score != scores[0]) // if median is same as highest score then everyone succeeded
	{
		foreach (player in players)
		{
			if (Ware_GetPlayerMiniData(player).score <= median_score)
			{
				failed_players.append(player)
				if (failed++ < max_display)
					text += GetPlayerName(player) + "\n"		
			}
		}
		
		if (failed > max_display)
			text += format("\n\nand %d more...", failed - max_display)
	}
	else
	{
		text += "no one!\n\nEveryone survives to the next level!"
	}
	
	Ware_ShowMinigameText(Ware_Players, text)
	
	CreateTimer(function()
	{
		if (failed_players.len() > 0)
		{
			local player = failed_players.remove(0)
			if (player.IsValid())
				Ware_SuicidePlayer(player)					
			return failed_players.len() == 0 ? 1.5 : 0.1
		}
		else
		{
			CheckGameOver()
		}
	}, 3.0)
}

function CheckGameOver()
{
	local players = Ware_GetAlivePlayers()
	if (players.len() <= 1 || level > 4)
	{
		game_over = true
		if (players.len() > 0)
		{
			foreach (player in Ware_Players)
			{
				if (players.find(player) != null)
				{
					Ware_PlaySoundOnClient(player, sound_good_end)
					Ware_PassPlayer(player, true)
				}
				else
				{
					Ware_PlaySoundOnClient(player, sound_bad_end)
				}
			}
				
			if (players.len() > 1)
			{
				local text = "The winners are...\n"
				foreach (player in players)
					text +=  GetPlayerName(player) + "\n"
				Ware_ShowMinigameText(Ware_Players, text)
			}
			else
			{
				local player = players[0]
				local average_word_count = Ware_GetPlayerMiniData(player).word_count_total / (level + 1).tofloat()
				Ware_ShowMinigameText(Ware_Players, format("The winner is...\n%s!", GetPlayerName(player)))
				
				if (mode == 0)
				{
					// double the reported WPM to compensate for chat delay
					Ware_ChatPrint(null, "{player}{color} had a total WPM of {color}{int}{color}!", 
						player, TF_COLOR_DEFAULT, COLOR_LIME,
						(average_word_count / (word_type_duration / 60.0)).tointeger() * 1.5, 
						TF_COLOR_DEFAULT)		
				}
			}
		}
		else
		{
			Ware_PlaySoundOnAllClients(sound_bad_end)
			Ware_ShowMinigameText(Ware_Players, "Nobody is the winner...")
		}
	}
	else
	{
		level++
		
		local text = "The remaining players are...\n\n"
		
		local max_display = 6
		local count = max_display
		foreach (player in players)
		{
			text += GetPlayerName(player) + "\n"
			if (--count <= 0)
				break
		}
		
		if (players.len() > max_display)
			text += format("\n\nand %d more...", players.len() - max_display)
		
		Ware_ShowMinigameText(Ware_Players, text)

		Ware_PlaySoundOnAllClients(sound_level_up)
		CreateTimer(Descent, 3.0)
		
		if (level == 1 || level == 3)
		{
			Ware_ShowScreenOverlay(Ware_Players, overlay_difficulty)
			Ware_PlaySoundOnAllClients(sound_difficulty_up)
			difficulty++
		}
	}
}

function SetCamera(name)
{
	// grab any valid camera if disabling
	local camera = FindByName(null, name ? name : "DRBoss_DescentCamera_Point")
	if (name != null)
	{
		foreach (player in Ware_Players)
		{
			TogglePlayerViewcontrol(player, camera, true)
			player.SetForceLocalDraw(true)
			player.AddHudHideFlags(HIDEHUD_TARGET_ID)
			player.RemoveCond(TF_COND_TAUNTING)
			player.AddCond(TF_COND_GRAPPLED_TO_PLAYER) // prevent taunting
			SetPropInt(player, "m_takedamage", DAMAGE_YES)
		}
	}
	else
	{
		foreach (player in Ware_Players)
		{
			TogglePlayerViewcontrol(player, camera, false)		
			player.SetForceLocalDraw(false)
			player.RemoveHudHideFlags(HIDEHUD_TARGET_ID)
			player.RemoveCond(TF_COND_GRAPPLED_TO_PLAYER)
		}
	}
}

function ShowWord(player, score)
{
	local word = word_rotation[score]
	local next_word = word_rotation[score + 1]
	
	local text, text2
	if (mode != 0)
	{
		text = word.expression + " = ?"
		text2 = "Next question:\n" + next_word.expression
	}
	else
	{
		// these spaces are needed to avoid localization kicking in!!
		text = format(" %s ", word)
		text2 = "Next word:\n" + next_word
	}
		
	Ware_ShowText(player, CHANNEL_MINIGAME, text, word_type_duration, "255 255 40")
	Ware_ShowText(player, CHANNEL_BACKUP, text2, word_type_duration, "255 255 255", -1.0, 0.4)
	
	local spec_text
	foreach (spectator in Ware_Players)
	{
		if (!spectator.IsAlive() && GetPropEntity(spectator, "m_hObserverTarget") == player)
		{
			if (spec_text == null)
			{
				if (mode != 0)
					spec_text = format("%s's current question is:\n%s", GetPlayerName(player), word.expression)
				else
					spec_text = format("%s's current word is:\n%s", GetPlayerName(player), word)
			}
			Ware_ShowText(spectator, CHANNEL_MINIGAME, spec_text, word_type_duration, "255 255 255")
		}
	}
}

function OnPlayerSay(player, text)
{
	if (word_typing)
	{
		if (player.IsAlive() && Ware_MinigamePlayers.find(player) != null)
		{
			EntityEntFire(player, "CallScriptFunction", "ResetSelfChatCooldown")
			
			local minidata = Ware_GetPlayerMiniData(player)
			// should be impossible to run out of words
			local word = word_rotation[minidata.score]
			
			local pass = false
			if (mode != 0)
				pass = word.result == StringToInteger(text)
			else
				pass = text.tolower() == word.tolower()
			
			if (pass)
			{
				minidata.word_count++
				minidata.word_count_total++
				
				minidata.score++
				if (minidata.score > word_high_score)
				{
					Ware_PlaySoundOnClient(player, sound_word_relax)
					word_high_score = minidata.score
				}
				else
				{
					Ware_PlaySoundOnClient(player, sound_word_success)
				}
							
				ShowWord(player, minidata.score)
				return false
			}
			else
			{
				Ware_PlaySoundOnClient(player, sound_word_fail)
			}
		}
	}
}

function OnCheckEnd()
{
	 return game_over
}