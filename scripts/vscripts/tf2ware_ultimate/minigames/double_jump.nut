mode <- RandomInt(0, 1)

minigame <- Ware_MinigameData
({
	name           = "Double Jump"
	author         = ["Gemidyne", "pokemonPasta"]
	description    = mode == 0 ? "Double Jump!" : "Triple Jump!"
	custom_overlay = mode == 0 ? "double_jump" : "triple_jump"
	duration       = 4.0
	music          = "ringring"
	fail_on_death  = true
	convars =
	{
		tf_scout_air_dash_count = 69
	}
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

function FailJump(player)
{
	Ware_SuicidePlayer(player)
	Ware_ShowScreenOverlay(player, "hud/tf2ware_ultimate/minigames/double_jump_fail")
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local airdashes = GetPropInt(player, "m_Shared.m_iAirDash") // doesn't count jump from ground - double == 1, triple == 2
		switch (mode)
		{
			case 0:
				if (airdashes == 1)
					Ware_PassPlayer(player, true)
				else if (airdashes == 2)
					FailJump(player)
				break
			case 1:
				if (airdashes == 2)
					Ware_PassPlayer(player, true)
				else if (airdashes == 3)
					FailJump(player)
				break
		}
	}
}
