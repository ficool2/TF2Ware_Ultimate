special_round <- Ware_SpecialRoundData
({
	name             = "Cramped Quarters"
	author           = ["Mecha the Slag", "ficool2"]
	description      = "Don't touch anyone!"
	categories 		 = ["collisions"]
	min_players      = 2
})

local touch_dmg = false
local grace = false

function OnStart()
{
	foreach(player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).touched <- false
}

function OnPlayerSpawn(player)
{
	Ware_GetPlayerSpecialRoundData(player).touched <- false
}

function OnPlayerTouch(player1, player2)
{
	if(grace)
		return

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
	grace = true
	Ware_CreateTimer(function(){grace = false}, Min(1.0, Ware_Minigame.duration / 4))
}
