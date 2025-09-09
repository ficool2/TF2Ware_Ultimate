function OnUpdate(bot)
{

	local dest = Ware_MinigameScope.goal_vectors + Vector(0,4000,700000)
    local loco = bot.GetLocomotionInterface()

	BotLookAt(bot, dest, 9999.0, 9999.0)
    loco.FaceTowards(dest)
	loco.Approach(dest, 999)

	bot.AddFlag(FL_DUCKING)
}

function OnEnd(bot)
{
	bot.RemoveFlag(FL_DUCKING)
}