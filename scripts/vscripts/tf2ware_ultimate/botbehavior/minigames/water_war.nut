//todo nearest
function OnUpdate(bot)
{
	local prop

	local arr = Shuffle(Ware_MinigamePlayers)
	foreach (prop in arr)
	{
		if (prop && prop.IsPlayer() && prop.IsAlive())
		{
			local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
			Ware_BotShootTarget(bot, dest, true, true)
			break
		}
	}
}
