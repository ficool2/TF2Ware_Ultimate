special_round <- Ware_SpecialRoundData
({
	name = "Sit Out"
	author = "rake"
	description = "Winning streaks reward you with not playing the next minigame"
})

SIT_OUT_AMOUNT <- 1
SIT_OUT_THRESHOLD <- 2

function OnStart()
{
	foreach (player in Ware_Players.filter(@(i, player) (player.GetTeam() & TF_TEAM_MASK) != 0))
	{
		local special = Ware_GetPlayerSpecialRoundData(player)
		special.won_microgames <- 0
		special.sit_out <- 0
	}
}

function OnPlayerConnect(player)
{
	local special = Ware_GetPlayerSpecialRoundData(player)
	special.won_microgames <- 0
	special.sit_out <- 0
}

function OnMinigameStart()
{
	foreach (player in Ware_Players)
	{
		local special = Ware_GetPlayerSpecialRoundData(player)
		if (special.sit_out--)
		{
			local text = format("You are out for %d more microgames.", special.sit_out--);
			Ware_ShowText(player, CHANNEL_MISC, text, 4.98)
		}
	}
}

function OnCalculateScore(data)
{
	local special = Ware_GetPlayerSpecialRoundData(data.player)
	if (data.passed)
	{
		if (++data.won_microgames >= SIT_OUT_THRESHOLD)
		{
			special.sit_out = SIT_OUT_AMOUNT
			special.won_microgames = 0
		}

	}
	else
	{
		special.won_microgames = 0
	}

	return false
}

function GetValidPlayers()
{
	return Ware_Players.filter(@(idx, player) (
		Ware_GetPlayerSpecialRoundData(player).sit_out == 0
	))
}