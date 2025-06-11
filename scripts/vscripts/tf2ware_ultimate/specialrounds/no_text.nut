text_mgr <- null

special_round <- Ware_SpecialRoundData
({
	name = "No Text"
	author = "42"
	description = "We refuse to elaborate what you need to do."
	category = ""
})

function OnStart()
{
	// hack to prevent hud texts being shown
	Ware_TextManager.KeyValueFromInt("effect", 2)
	Ware_TextManager.KeyValueFromFloat("fxtime", 999999999.0)
}

function OnEnd()
{
	Ware_TextManager.KeyValueFromInt("effect", 0)
	Ware_TextManager.KeyValueFromFloat("fxtime", 0.0)
}

function OnMinigameStart()
{
	ClearTexts()
}

function OnMinigameEnd()
{
	ClearTexts()
	
	if (typeof(Ware_Minigame.description) != "array")
	{
		Ware_ChatPrint(null, "The minigame was {color}{str}", COLOR_GREEN, Ware_Minigame.description)
	}
	else
	{
		foreach (player in Ware_MinigamePlayers)
			Ware_ChatPrint(player, "The minigame was {color}{str}", COLOR_GREEN, Ware_Minigame.description[Ware_GetPlayerMission(player)])
	}
}

function OnSpeedup()
{
	ClearTexts()
}

function OnUpdate()
{
	ClearTexts()
}

function ClearTexts()
{
	foreach (player in Ware_MinigamePlayers)
		player.SetScriptOverlayMaterial("")
	
	if (Ware_Minigame != null)
	{
		local annotations = Ware_Minigame.annotations
		for (local i = annotations.len() - 1; i >= 0; i--)
			Ware_HideAnnotation(annotations[i])
	}
}