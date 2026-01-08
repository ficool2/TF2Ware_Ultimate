DEVELOPER_STEAMID3 <-
{
	"[U:1:53275741]"  : 1 // ficool2
	"[U:1:111328277]" : 1 // pokemonPasta
}

function Ware_DevCommandTitle(player)
{
	if (GetPlayerSteamID3(player) in DEVELOPER_STEAMID3)
		return "Developer"
	else if (player == Ware_ListenHost)
		return "Host"
	else
		return "Admin"
}

function Ware_DevCommandForceMinigame(player, text, is_boss, once)
{
	local gamename = is_boss ? "Ware_DebugForceBossgame" : "Ware_DebugForceMinigame"
	local args = split(text, " ")
	
	if (args.len() >= 1)
		ROOT[gamename] = args[0]
	else
		ROOT[gamename] = ""
		
	ROOT[gamename + "Once"] = once	
	
	local name = is_boss ? "bossgame" : "minigame"
	if (once)
		Ware_ChatPrint(player, "{str} set next {str} to '{str}'", Ware_DevCommandTitle(player), name, ROOT[gamename])	
	else
		Ware_ChatPrint(player, "{str} forced {str} '{str}'", Ware_DevCommandTitle(player), name, ROOT[gamename])	
}

Ware_DevCommands <-
{
	"nextminigame"  : function(player, text) { Ware_DevCommandForceMinigame(player, text, false, true)  }
	"nextbossgame"  : function(player, text) { Ware_DevCommandForceMinigame(player, text, true, true)   }
	"forceminigame" : function(player, text) { Ware_DevCommandForceMinigame(player, text, false, false) }
	"forcebossgame" : function(player, text) { Ware_DevCommandForceMinigame(player, text, true, false)  }
	"nexttheme": function(player, text)
	{
		local args = split(text, " ")
		if (args.len() >= 1)
		{
			local theme = args[0]
			if (theme == "default" || theme == "tf2ware_classic")
				Ware_DebugNextTheme = "_" + theme
			else
				Ware_DebugNextTheme = theme
		}
		else
			Ware_DebugNextTheme = ""
		Ware_ChatPrint(null, "{str} forced next theme to '{str}'", Ware_DevCommandTitle(player), Ware_DebugNextTheme)
	}
	"forcetheme": function(player, text)
	{
		local args = split(text, " ")
		if (args.len() >= 1)
		{
			local theme = args[0]
			if (theme == "default" || theme == "tf2ware_classic")
				Ware_DebugForceTheme = "_" + theme
			else
				Ware_DebugForceTheme = theme
		}
		else
			Ware_DebugForceTheme = ""
		Ware_ChatPrint(null, "{str} forced theme to '{str}'", Ware_DevCommandTitle(player), Ware_DebugForceTheme)
	}
	"nextspecial": function(player, text)
	{
		local args = split(text, " ")
		local text = ""
		if (args.len() >= 1)
		{
			Ware_DebugNextSpecialRound = clone(args)
			
			local len = Ware_DebugNextSpecialRound.len()
			for (local i = 0; i < len; i++)
			{
				text += Ware_DebugNextSpecialRound[i]
				if (i < len - 1)
					text += " "
			}
		}
		else
		{
			Ware_DebugNextSpecialRound.clear()
		}
		Ware_ChatPrint(null, "{str} forced next special round to '{str}'", Ware_DevCommandTitle(player), text)
	}
	"forcespecial": function(player, text)
	{
		local args = split(text, " ")
		local text = ""
		local print = "{str} forced special rounds to '{str}'."
		if (args.len() >= 1)
		{
			Ware_DebugForceSpecialRound = true
			Ware_DebugNextSpecialRound = clone(args)
			
			local len = Ware_DebugNextSpecialRound.len()
			for (local i = 0; i < len; i++)
			{
				text += Ware_DebugNextSpecialRound[i]
				if (i < len - 1)
					text += " "
			}
			
			print += " Initial Special Round rolling sequence will not play."
		}
		else
		{
			Ware_DebugForceSpecialRound = false
			Ware_DebugNextSpecialRound.clear()
		}
		Ware_ChatPrint(null, print, Ware_DevCommandTitle(player), text)
	}
	"forcemode": function(player, text)
	{
		local args = split(text, " ")
		if (args.len() >= 1)
		{
			local mode = StringToInteger(args[0])
			if (mode != null && mode >= 0)
			{
				Ware_DebugForceMode = mode
				Ware_ChatPrint(null, "{str} set moded minigames to mode {int}", Ware_DevCommandTitle(player), Ware_DebugForceMode)
			}
			else
			{
				Ware_ChatPrint(player, "Arguments: <mode>, where mode >= 0")
			}
		}
		else
		{
			Ware_DebugForceMode = null
			Ware_ChatPrint(null, "{str} cleared forced mode for moded minigames", Ware_DevCommandTitle(player))
		}	
	}
	"shownext": function(player, text)
	{
		local vars = [
			"Ware_DebugForceMinigame",
			"Ware_DebugForceMinigameOnce",
			"Ware_DebugForceBossgame",
			"Ware_DebugForceBossgameOnce",
			"Ware_DebugNextTheme",
			"Ware_DebugForceTheme",
			"Ware_DebugNextSpecialRound",
			"Ware_DebugForceMode"
		]
		foreach(var in vars)
		{
			local value = ROOT[var]
			if (typeof(value) == "string")
				ClientPrint(player, HUD_PRINTCONSOLE, format("* %s = \"%s\"", var, value))
			else if (typeof(value) == "bool")
				ClientPrint(player, HUD_PRINTCONSOLE, format("* %s = %s", var, value ? "true" : "false"))
			else if (typeof(value) == "integer")
				ClientPrint(player, HUD_PRINTCONSOLE, format("* %s = %d", var, value))
			else if (value == null)
				ClientPrint(player, HUD_PRINTCONSOLE, format("* %s = null", var))
		}
		Ware_ChatPrint(player, "Values printed to console.")
	}
	"clearall": function(player, text)
	{
		Ware_DebugForceMinigame   	= ""
		Ware_DebugForceBossgame   	= ""
		Ware_DebugForceMinigameOnce = false
		Ware_DebugForceBossgameOnce = false
		Ware_DebugNextSpecialRound  = []
		Ware_DebugForceMode         = null
		Ware_DebugNextTheme         = ""
		Ware_DebugForceTheme        = ""
		
		Ware_ChatPrint(player, "All debug variables reset.")
	}
	"killaudio": function(player, text)
	{
		local StopSound = function(path){
			Ware_PlaySoundOnAllClients(path, 1.0, 100, SND_STOP)
			foreach(player in Ware_Players)
				Ware_PlaySoundOnClient(player, path, 1.0, 100, SND_STOP)
		}
		
		foreach(theme in Ware_Themes)
		{
			local folder = theme.theme_name
			foreach(sound, duration in theme.sounds)
			{
				local path = format("tf2ware_ultimate/v%d/music_game/%s/%s.mp3", WARE_MP3_VERSION, folder, sound)
				StopSound(path)
			}
		}
		
		if(Ware_Minigame && Ware_Minigame.music != "")
			StopSound(format("tf2ware_ultimate/v%d/music_minigame/%s.mp3", WARE_MP3_VERSION, Ware_Minigame.music))
				
		Ware_ChatPrint(player, "Attempted to kill all TF2Ware audio. You may need to run this again.")
	}
	"restart" : function(player, text)
	{
		SetConvarValue("mp_restartgame_immediate", 1)
		// TODO these should be "host" or "admin" if a non-dev executes it
		Ware_ChatPrint(null, "{str} has forced a restart", Ware_DevCommandTitle(player))
	}
	"gameover" : function(player, text)
	{
		Ware_DebugGameOver = true
		Ware_ChatPrint(null, "{str} has forced a game over", Ware_DevCommandTitle(player))		
	}
	// I never remember which word is the right one, so let's have both
	"stop" : function(player, text)
	{
		Ware_DebugStop = true
		Ware_ChatPrint(null, "{str} has forced the game to pause", Ware_DevCommandTitle(player))
	}
	"pause" : function(player, text)
	{
		Ware_DebugStop = true
		Ware_ChatPrint(null, "{str} has forced the game to pause", Ware_DevCommandTitle(player))
	}
	"resume" : function(player, text)
	{
		Ware_DebugStop = false
		Ware_ChatPrint(null, "{str} has resumed the game", Ware_DevCommandTitle(player))
	}
	"end" : function(player, text)
	{
		if (Ware_Minigame)
		{
			Ware_ChatPrint(null, "{str} has ended the current {str}...", 
				Ware_DevCommandTitle(player), Ware_Minigame.boss ? "bossgame" : "minigame")
			Ware_EndMinigame()
		}
		else
		{
			Ware_ChatPrint(player, "No minigame is currently running.")
		}
	}
	"remove": function(player, text)
	{
		local remove_target = function(target, arrs)
		{
			local removals = 0
			foreach(arr in arrs)
			{
				local idx = arr.find(target)
				if (idx != null)
				{
					arr.remove(idx)
					removals++
				}
			}
			if (removals > 0)
				Ware_ChatPrint(player, "Successfully removed {str} from {int} array{str}", target, removals, removals == 1 ? "" : "s")
			else
				Ware_ChatPrint(player, "Failed to remove {str} from any arrays", target)
		}
		
		local args = split(text, " ")
		if (args.len() > 0)
		{
			local target = args[1]
			switch (args[0]) {
				case "mini":
					remove_target(target, [Ware_Minigames, Ware_MinigameRotation])
					break
				case "boss":
					remove_target(target, [Ware_Bossgames, Ware_BossgameRotation])
					break
				case "special":
					remove_target(target, [Ware_SpecialRounds, Ware_SpecialRoundRotation])
					break
			}
		}
		else
		{
			Ware_ChatPrint(player, "Arguments: [mini/boss/special] [name]")
		}
	}
	"givescore" : function(player, text)
	{
		local args = split(text, " ", false)
		if (args.len() > 0)
		{
			local arg = 0
			local target = player
			if (args.len() > 1)
				target = Ware_FindPlayerByName(args[arg++])
			if (target)
			{
				local points = StringToInteger(args[arg])
				if (points != null)
				{
					Ware_ChatPrint(player, "Gave {int} points to {player}", points, target)
					if (target != player)
						Ware_ChatPrint(target, "{str} has given you {int} points", Ware_DevCommandTitle(player), points)
					Ware_GetPlayerData(target).score += points
				}
				else
				{
					Ware_ChatPrint(player, "Invalid score")
				}
			}
			else
			{
				Ware_ChatPrint(player, "Player not found")
			}
		}
		else
		{
			Ware_ChatPrint(player, "Arguments: [player name] <score>")
		}
	}
	"timescale" : function(player, text)
	{
		local args = split(text, " ")
		if (args.len() >= 1)
		{
			local scale = args[0].tofloat()
			Ware_SetTimeScale(scale)
			Ware_ChatPrint(null, "{str} has forced timescale to {%g}", Ware_DevCommandTitle(player), scale)
		}
		else		
		{
			Ware_ChatPrint(player, "Missing required scale parameter")
		}
	}
	"help" : function(player, text)
	{
		local cmds = []
		foreach (name, func in Ware_DevCommands)
			if (name != "help")
				cmds.append(name)
		foreach(name, func in Ware_PublicCommands)
			if (name != "help" && !(name in Ware_DevCommands))
				cmds.append(name)
		cmds.sort(@(a, b) a <=> b)
		foreach (name in cmds)
			ClientPrint(player, HUD_PRINTCONSOLE, "* " + name)
		Ware_ChatPrint(player, "See console for list of commands")
	}
}

Ware_PublicCommands <-
{
	"credits" : function(player, text)
	{
		Ware_ShowCredits(player, true)
	}
	"ip" : function(player, args)
	{
		if (IsDedicatedServer())
		{
			Ware_ChatPrint(player, "This command is not supported on dedicated servers.")
			return
		}		
		
		if (Ware_ServerIP == null)
		{
			Ware_ChatPrint(player, "Failed to retrieve server IP. Type 'status' in console to find it manually")
			return
		}
		
		if (!Ware_SDR)
		{
			Ware_ChatPrint(player, "Warning: You don't have {color}-enablefakeip{color} in your launch options. Friends cannot join you unless you are port forwarded or playing on LAN."
				COLOR_LIME, TF_COLOR_DEFAULT)
		}
		
		Ware_ChatPrint(player, "Copy and share the console command below with your friends")
		// doesn't work with SDR...
		//ClientPrint(player, HUD_PRINTTALK, format("\x07DEEFF5steam://connect/%s?appid=440", Ware_ServerIP))
		// skipping Ware_ChatPrint so this doesn't have the prefix or get reversed by special rounds
		if (Ware_ServerPassword && Ware_ServerPassword.len() > 0)
			ClientPrint(player, HUD_PRINTTALK, format("\x07DEEFF5connect %s;password %s", Ware_ServerIP, Ware_ServerPassword))
		else
			ClientPrint(player, HUD_PRINTTALK, format("\x07DEEFF5connect %s", Ware_ServerIP))
	}
	"help" : function(player, text)
	{
		local cmds = []
		foreach (name, func in Ware_PublicCommands)
			if (name != "help")
				cmds.append(name)
			
		cmds.sort(@(a, b) a <=> b)
		foreach (name in cmds)
			ClientPrint(player, HUD_PRINTCONSOLE, "* " + name)
		Ware_ChatPrint(player, "See console for list of commands")
	}
}