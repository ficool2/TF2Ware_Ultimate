function OnUpdate(bot)
{
	BotLookAt(bot, bot.GetCenter() + Vector(0, 0, 1000), 9999.0, 9999.0)
    local loco = bot.GetLocomotionInterface()
    loco.FaceTowards(bot.GetCenter() + Vector(0, 0, 1000))

	bot.AddFlag(FL_DUCKING)
}

function OnEnd(bot)
{
	bot.RemoveFlag(FL_DUCKING)
}