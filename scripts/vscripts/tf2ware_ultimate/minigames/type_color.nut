mode <- RandomInt(0, 1)

minigame <- Ware_MinigameData
({
	name            = "Type the Color"
	author          = ["Mecha the Slag", "ficool2"]
	description     = mode == 0 ? "Type the text below!" : "Type the color below!"
	duration        = 4.0 + Ware_GetTimeScale() // extra time for lag compensation
	end_delay       = 0.5
	music           = "getready"
	custom_overlay  = mode == 0 ? "type_text" : "type_color"
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
	local overlay = mode == 0 ? "type_text" : "type_color"

	PrecacheOverlay("hud/tf2ware_ultimate/minigames/" + overlay)
}

function OnStart()
{
	local text_idx   = RandomIndex(text_colors)
	local visual_idx = RandomIndex(colors)
	
	text_color = text_colors[text_idx]
	visual_color = text_colors[visual_idx]

	// these spaces are to prevent localization
	Ware_ShowMinigameText(null, format(" %s ", text_color), colors[visual_idx])
	
	answer = mode == 0 ? text_color : visual_color

	Ware_CreateTimer(@() OnNonLagCompensatedEnd(), Ware_Minigame.duration - Ware_GetTimeScale()) // fire the end early before lag compensation happens
}

function OnNonLagCompensatedEnd()
{
	Ware_ChatPrint(null, "The correct answer was {color}{str}", CONST["COLOR_" + answer], answer)
}

function OnPlayerSay(player, text)
{	
	if (text.tolower() == answer.tolower())
	{
		if (player.IsAlive() && Time() - GetPlayerLatency(player) < Ware_MinigameStartTime + Ware_Minigame.duration - Ware_GetTimeScale()) // pass the player if they typed it in time but server received it late
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