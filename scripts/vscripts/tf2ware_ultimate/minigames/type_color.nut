minigame <- Ware_MinigameData
({
	name            = "Type the Color"
	author          = ["Mecha the Slag", "ficool2"]
	description     = Ware_MinigameMode == 0 ? "Type the text below!" : "Type the color below!"
	modes           = 2
	duration        = 4.0
	end_delay       = 0.5
	music           = "getready"
	custom_overlay  = Ware_MinigameMode == 0 ? "type_text" : "type_color"
	custom_overlay2 = "../chalkboard"
	suicide_on_end  = true
})

first <- false

text_color <- null
visual_color <- null
answer <- null

colors <-
[
	"255 255 255",
	"255 0 0",
	"255 255 0"
	"45 130 220" // slightly more legible blue, may need more adjusting to stand out from chalkboard more
]

text_colors <-
[
	"WHITE"
	"RED"
	"YELLOW" // yellow is more distinguishable than green for colorblind players
	"BLUE"
	"GREEN"
	"BLACK"
	"MAGENTA"
	"CYAN"
	"ORANGE"
]

function OnPrecache()
{
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/type_text")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/type_color")
}

function OnStart()
{
	local text_idx   = RandomIndex(text_colors)
	local visual_idx = RandomIndex(colors)
	
	text_color = text_colors[text_idx]
	visual_color = text_colors[visual_idx]

	// these spaces are to prevent localization
	Ware_ShowMinigameText(null, format(" %s ", text_color), colors[visual_idx])
	
	answer = Ware_MinigameMode == 0 ? text_color : visual_color
}

function OnEnd()
{
	Ware_ChatPrint(null, "The correct answer was {color}{str}", CONST["COLOR_" + answer], answer)
}

function OnPlayerSay(player, text)
{	
	if (text.tolower() == answer.tolower())
	{
		if (player.IsAlive())
		{
			Ware_PassPlayer(player, true)
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}said the answer first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
		return false
	}
	else
	{
		if (Ware_IsPlayerPassed(player) || !player.IsAlive())
			return true
		
		Ware_SuicidePlayer(player)
	}
}