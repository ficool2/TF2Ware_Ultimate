special_round <- Ware_SpecialRoundData
({
	name             = "Cramped Quarters"
	author           = ["Mecha the Slag", "ficool2"]
	description      = "Don't touch anyone!"
	category         = ""
	min_players      = 2
})

local touch_dmg = false
local grace = false
local grace_warning = false
local disabled_msg_this_round = false
local last_minigame = null

function IsDisabledMinigame()
{
	if (!Ware_Minigame)
		return false

	return (
		Ware_Minigame.name == "Basketball" || Ware_Minigame.name == "Floppy Scout" || Ware_Minigame.name == "Shark" || Ware_Minigame.name == "Trampoline" || Ware_Minigame.name == "Trivia"
	)
}

function OnStart()
{
	foreach(player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).touched <- false

	disabled_msg_this_round = false
	last_minigame = Ware_Minigame
}

function OnPlayerSpawn(player)
{
	Ware_GetPlayerSpecialRoundData(player).touched <- false
}

function OnPlayerTouch(player1, player2)
{
	if (grace)
	{
		if(!grace_warning)
		{
			Ware_ChatPrint(null,
				"{color}The grace period is still active. {color}Stay away{color}!",
				TF_COLOR_DEFAULT, TF_COLOR_RED, TF_COLOR_DEFAULT)

			grace_warning = true
		}

		return
	}

	if (IsDisabledMinigame())
	{
		if (!disabled_msg_this_round)
		{
			Ware_ChatPrint(null,
				"Cramped Quarters is disabled during this minigame.")
			disabled_msg_this_round = true
		}
		return
	}

	if (Ware_Minigame || Ware_Finished)
	{
		touch_dmg = true	
		local truce = GetPropBool(GameRules, "m_bTruceActive")
		SetPropBool(GameRules, "m_bTruceActive", false)
		player1.TakeDamage(1000.0, DMG_BULLET, player2)
		SetPropBool(GameRules, "m_bTruceActive", truce)
		touch_dmg = false

		// don't spam the chat if killing somehow fails, but still try to kill.
		local data = Ware_GetPlayerSpecialRoundData(player1)
		if(!data.touched)
		{
			local color2 = player2.GetTeam() == TF_TEAM_RED ? TF_COLOR_RED : TF_COLOR_BLUE
			Ware_ChatPrint(player1, "You touched {color}{player}{color}!", color2, player2, TF_COLOR_DEFAULT)
			data.touched = true
		}
	}
}

function OnTakeDamage(params)
{
	if (touch_dmg)
		params.force_friendly_fire = true
}

function OnMinigameStart()
{
	if (last_minigame != Ware_Minigame)
	{
		disabled_msg_this_round = false
		last_minigame = Ware_Minigame
	}

	if (IsDisabledMinigame())
		return

	grace = true
	grace_warning = false

	local grace_time = (Ware_Minigame.duration >= 40.0) ? 10.0 : 2.5

	Ware_CreateTimer(function(){grace = false}, grace_time)
}