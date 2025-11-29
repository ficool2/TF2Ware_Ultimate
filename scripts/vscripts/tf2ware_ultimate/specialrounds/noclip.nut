special_round <- Ware_SpecialRoundData
({
	name = "Noclip"
	author = "ficool2"
	description = "Everyone can noclip! Press ACTION KEY (default: H) to noclip!"
	categories = []
})

function OnStart()
{
	foreach (player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).noclip_action_key <- false
}

function OnPlayerConnect(player)
{
	foreach (player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).noclip_action_key <- false
}

function OnUpdate()
{
	foreach (player in Ware_Players)
	{
		local data = Ware_GetPlayerSpecialRoundData(player)
		local action_key = player.IsUsingActionSlot()

		if (action_key && !data.noclip_action_key)
		{
			if (player.IsAlive())
			{
				if (player.GetMoveType() == MOVETYPE_NOCLIP)
					player.SetMoveType(MOVETYPE_WALK, MOVECOLLIDE_DEFAULT)
				else
					player.SetMoveType(MOVETYPE_NOCLIP, MOVECOLLIDE_DEFAULT)
			}
		}

		data.noclip_action_key <- action_key
	}
}