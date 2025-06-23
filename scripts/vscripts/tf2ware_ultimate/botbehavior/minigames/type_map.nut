function OnStart(bot)
{
	// TODO scale by difficulty
	local chance = 0.3
	local delay = RandomFloat(1.5, 5.0)
	
	Ware_BotCreateMinigameTimer(bot, function()
	{	
		local arr = Ware_MinigameScope.map
		arr = arr.slice(1, arr.len())
		local word
		if (RandomFloat(0, 1) > chance)
			word = Ware_BotTryWordTypo(bot, RandomElement(arr), chance)
		else
			word = RandomElement(["idk", "lol", "wtf", "your mom", "penis", "2FORT", 
			"dustbowl", "invasion", "balls", "gravel", "powerhouse", "steel", "well", "Nuketown",
			"best map", "hydro my beloved", "2fort duh", "drywater", "duysbton3w;l", "UPWARD", "control points", "dustbol", "map name"])
		Say(bot, word, false)
	}, delay)
}