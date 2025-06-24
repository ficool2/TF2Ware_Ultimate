special_round <- Ware_SpecialRoundData
({
	name = "No Text"
	author = "FortyTwoFortyTwo"
	description = "__ ______ __ _________ ____ ___ ____ __ __"
	category = ""
})

function OnMinigameStart()
{
	ClearTexts()
}

function OnMinigameEnd()
{
	ClearTexts()
	
	local game = Ware_Minigame.boss ? "bossgame" : "minigame"
	
	if (typeof(Ware_Minigame.description) != "array")
	{
		Ware_ChatPrint(null, "The {str} was {color}{str}", game, COLOR_GREEN, Ware_Minigame.description)
	}
	else
	{
		foreach (player in Ware_MinigamePlayers)
			Ware_ChatPrint(player, "The {str} was {color}{str}", game, COLOR_GREEN, Ware_Minigame.description[Ware_GetPlayerMission(player)])
	}
}

function OnUpdate()
{
	foreach (player in Ware_Players)
		player.AddHudHideFlags(HIDEHUD_HEALTH|HIDEHUD_BUILDING_STATUS|HIDEHUD_CLOAK_AND_FEIGN|HIDEHUD_PIPES_AND_CHARGE|HIDEHUD_METAL|HIDEHUD_TARGET_ID)

	ClearTexts()
}

function OnShowChatText(player, text)
{
	// Allow text if minigame isn't ongoing or it has just ended
	if (!Ware_Minigame || Ware_MinigameEnded)
		return text
	
	// If colour isn't used in text, then its likely one of the chat commands is being used, which we can allow
	if (text.find("{color}") == null)
		return text
	
	// Otherwise block every other texts
	return null
}

function OnShowGameText(players, channel, text)
{
	// Allow special round text show as usual
	if (channel == CHANNEL_SPECIALROUND)
		return text
	
	// Allow "X" hitreg to show up
	if (text == "x")
		return text
	
	// Block everything else
	return null
}

function OnShowOverlay(players, overlay_name)
{
	return null
}

function ClearTexts()
{
	if (Ware_Minigame != null)
	{
		local annotations = Ware_Minigame.annotations
		for (local i = annotations.len() - 1; i >= 0; i--)
			Ware_HideAnnotation(annotations[i])
	}
}