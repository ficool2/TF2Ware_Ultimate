minigame <- Ware_MinigameData
({
	name            = "Math"
	author          = ["Mecha the Slag", "ficool2"]
	description     = "Type the answer!"
	duration        = 4.0
	end_delay       = 0.5
	music           = "question"
	custom_overlay  = "type_answer"
	custom_overlay2 = "../chalkboard"
	modes           = 4
	suicide_on_end  = true
})

a <- null
b <- null
operator <- null
answer <- null

first <- true

function OnStart()
{
	if (Ware_MinigameMode == 0)
	{
		if (RandomInt(0, 49) == 0)
		{
			a = RandomInt(1, 9) * 1000
			b = 9001 - a
		}
		else
		{
			a = RandomInt(3, 15)
			b = RandomInt(3, 15)
		}
		
		answer = a + b
		operator = "+"
	}
	else if (Ware_MinigameMode == 1)
	{
		a = RandomInt(3, 15)
		b = RandomInt(3, 15)
		answer = a - b
		operator = "-"
	}
	else if (Ware_MinigameMode == 2)
	{
		a = RandomInt(2, 12)
		b = RandomInt(2, 12)
		if (RandomInt(0, 9) == 0)
			a = -a	
		if (RandomInt(0, 9) == 0)
			b = -b
		answer = a * b
		operator = "*"
	}
	else if (Ware_MinigameMode == 3)
	{
		// always leaves no remainder
		b = RandomInt(2, 10)
		a = b * RandomInt(1, 10)
		answer = a / b
		operator = "/"		
	}
	
	Ware_ShowMinigameText(null, format("%d %s %d = ?", a, operator, b))
}

function OnEnd()
{
	Ware_ChatPrint(null, "The correct answer was {int} {str} {int} = {color}{int}", a, operator, b, COLOR_LIME, answer)
}

function OnPlayerSay(player, text)
{
	local num = StringToInteger(text)
	if (num == null)
		return
	
	if (num != answer)
	{
		if (player.IsAlive() && !Ware_IsPlayerPassed(player))
		{
			local text = format("%d %s %d = %s", a, operator, b, text)
			Ware_ShowMinigameText(player, text)
			Ware_SuicidePlayer(player)
		}		
		return true
	}
		
	if (!Ware_IsPlayerPassed(player) && player.IsAlive())
	{
		local text = format("%d %s %d = %d", a, operator, b, num)
		Ware_ShowMinigameText(player, text)
		Ware_PassPlayer(player, true)
		
		if (first)
		{
			Ware_ChatPrint(null, "{player} {color}guessed the answer first!", player, TF_COLOR_DEFAULT)
			Ware_GiveBonusPoints(player)
			first = false
		}
	}
	
	return false
}