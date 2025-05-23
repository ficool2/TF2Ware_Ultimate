// by ficool2

class Ware_BotData
{
	function constructor(entity)
	{
		me = entity
		minigame_timers = []
	}
	
	me = null
	minigame_timers = null
}

if (!("Ware_Bots" in this))
{
	Ware_Bots <- []
}

SetConvarValue("tf_bot_difficulty", 0)
SetConvarValue("tf_bot_melee_only", 1)
SetConvarValue("tf_bot_sniper_melee_range", -1)
SetConvarValue("tf_bot_reevaluate_class_in_spawnroom", 0)
SetConvarValue("tf_bot_keep_class_after_death", 1)

Ware_BotMinigameBehaviors <- 
{
	type_word = {}
	catch_cubes = {}
	basketball = {}
	jump_rope = {}
}

Ware_BotMinigameBehavior <- null

function Ware_BotLoadBehaviors()
{
	foreach (minigame, scope in Ware_BotMinigameBehaviors)
	{
		local file_name = "tf2ware_ultimate/botbehavior/minigames/" + minigame	
		try
		{			
			IncludeScript(file_name, scope)	
		}
		catch (e)
		{
			Ware_Error("Failed to load '%s.nut'. Missing from disk or syntax error", path)
		}
	}
}

function Ware_BotSetup(bot)
{
	// disables visibility of enemies
	bot.AddBotAttribute(IGNORE_ENEMIES)
	bot.SetMaxVisionRangeOverride(0.01)
	// makes spies not attempt to cloak
	bot.SetMissionTarget(Ware_IncursionDummy)
	// set MISSION_SNIPER which effectively does nothing
	bot.SetMission(3, true)
	bot.GetScriptScope().bot_data <- Ware_BotData(bot)
	
	if (Ware_Bots.find(bot) == null)
		Ware_Bots.append(bot)
}

function Ware_BotDestroy(bot)
{
	local bot_data = bot.GetScriptScope().bot_data
	foreach (timer in bot_data.minigame_timers)
		KillTimer(timer)
}

function Ware_BotUpdate()
{
	if (Ware_Minigame 
		&& Ware_BotMinigameBehavior
		&& "OnUpdate" in Ware_BotMinigameBehavior)
	{
		foreach (bot in Ware_Bots)
			Ware_BotMinigameBehavior.OnUpdate(bot)
	}
	else
	{
		// TODO roam around
	}
}	

function Ware_BotOnMinigameStart()
{
	if (Ware_Minigame.file_name in Ware_BotMinigameBehaviors)
	{
		Ware_BotMinigameBehavior = Ware_BotMinigameBehaviors[Ware_Minigame.file_name]
	
		if ("OnStart" in Ware_BotMinigameBehavior)	
		{
			foreach (bot in Ware_Bots)
				Ware_BotMinigameBehavior.OnStart(bot)
		}
	}
	else
	{
		Ware_BotMinigameBehavior = null
	}
}

function Ware_BotOnMinigameEnd()
{
	foreach (bot in Ware_Bots)
	{
		local bot_data = bot.GetScriptScope().bot_data
		foreach (timer in bot_data.minigame_timers)
			KillTimer(timer)		
		bot_data.minigame_timers.clear()
	}
}

function Ware_BotCreateMinigameTimer(bot, callback, delay)
{
	local timer = CreateTimer(callback, delay)
	bot.GetScriptScope().bot_data.minigame_timers.append(timer)
	return timer
}

function Ware_BotTryWordTypo(bot, text, chance)
{
	// TODO higher typo chance with longer word
	
	if (RandomFloat(0.0, 1.0) > chance)
		return text
	
	if (text.len() < 2)
		return text
		
	local i = RandomInt(0, text.len() - 2)
	local chars = text.toupper() == text ? text.tolower() : text
	local type = RandomInt(0, 3)
	
	switch (type)
	{
		case 0: // swap
		{
			local tmp = chars[i]
			chars = chars.slice(0, i) + chars[i + 1].tochar() + tmp.tochar() + chars.slice(i + 2)
			break;
		}
		case 1: // omit
		{
			chars = chars.slice(0, i) + chars.slice(i + 1)
			break
		}
		case 2: // repeat
		{
			chars = chars.slice(0, i) + chars[i].tochar() + chars[i].tochar() + chars.slice(i + 1)
			break
		}
		case 3: // wrong
		{
			local keyboard = "abcdefghijklmnopqrstuvwxyz"
			local wrongChar = keyboard[RandomInt(0, keyboard.len() - 1)]
			chars = chars.slice(0, i) + wrongChar.tochar() + chars.slice(i + 1)
			break
		}
	}

	return chars
}