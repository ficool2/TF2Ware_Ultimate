
minigame <- Ware_MinigameData
({
	name           = "Double Jump"
	author         = ["Gemidyne", "pokemonPasta"]
	modes          = 2
	description    = Ware_MinigameMode == 0 ? "Double Jump!" : "Triple Jump!"
	custom_overlay = Ware_MinigameMode == 0 ? "double_jump" : "triple_jump"
	duration       = 4.0
	music          = "ringring"
	fail_on_death  = true
})

function OnPrecache()
{
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/double_jump")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/double_jump_fail")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/triple_jump")
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SCOUT, "Atomizer")
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local airdashes = GetPropInt(player, "m_Shared.m_iAirDash") // doesn't count jump from ground - double == 1, triple == 2
		switch (Ware_MinigameMode)
		{
			case 0:
				if (airdashes == 1)
					Ware_PassPlayer(player, true)
				else if (airdashes == 2)
				{
					Ware_SuicidePlayer(player)
					Ware_ShowScreenOverlay(player, "hud/tf2ware_ultimate/minigames/double_jump_fail")
				}
				break
			case 1:
				if (airdashes == 2)
					Ware_PassPlayer(player, true)
				break
		}
	}
}
