special_round <- Ware_SpecialRoundData
({
	name             = "Collisions"
	author           = "ficool2"
	description      = "Players are always solid to each other!"
	categories 		 = ["collisions"]
	force_collisions = true
	min_players      = 2
	max_players      = 40
	convars          =
	{
		tf_avoidteammates = 0
	}
})

function OnStart()
{
	foreach (player in Ware_Players)
		player.SetCollisionGroup(COLLISION_GROUP_PLAYER)
}

function OnEnd()
{
	foreach (player in Ware_Players)
		player.SetCollisionGroup(COLLISION_GROUP_PUSHAWAY)
}