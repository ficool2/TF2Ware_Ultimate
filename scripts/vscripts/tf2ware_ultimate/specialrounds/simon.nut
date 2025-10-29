
simon <- RandomBool()
friends <- [
	"Salmon"
	"Samuel"
	"Simothy"
	"Samantha"
	"Sam"
	"Cerberus"
	"Simone"
	"Simeon"
	"Samson"
	"Sinéad"
	"SCP-079"
	"Silvester"
	"Sensal"
	"Saxton Hale"
	"Scout"
	"Soldier"
	"Sniper"
	"Spy"
	"Sebastian"
]

special_round <- Ware_SpecialRoundData
({
	name = "Simon Goes Crazy"
	author = "pokemonPasta"
	description = "Only do what Simon tells you to do."
	category = "scores"
	
	opposite_win = !simon
})

function OnStart()
{
	foreach(player in Ware_Players)
		Ware_GetPlayerSpecialRoundData(player).hint_shown <- false
}

function OnPlayerConnect(player)
{
	Ware_GetPlayerSpecialRoundData(player).hint_shown <- false
}

function OnBeginIntermission(is_boss)
{
	// do this early bcuz minigamestart happens after something that checks opposite_win
	simon = RandomBool()
	special_round.opposite_win = !simon
}

function OnMinigameStart()
{
	local someone = GetSomeone()
	local text = (simon ? "Simon" : someone) + " Says:"
	Ware_ShowText(Ware_Players, CHANNEL_MISC, text, Ware_GetMinigameRemainingTime(), "255 255 255", -1.0, 0.13)
	
	local description = Ware_Minigame.description
	local is_array = typeof(description) == "array"
	local desc_len = Ware_Minigame.description.len()
	foreach(player in Ware_MinigamePlayers)
	{
		if(is_array)
			description = Ware_Minigame.description[Min(Ware_GetPlayerMission(player), desc_len - 1)]
		
		Ware_ChatPrint(player, "{color}{str} {color}{str}", COLOR_GREEN, text, TF_COLOR_DEFAULT, description)
	}
}

function OnCalculateScore(data)
{
	if (simon == data.passed)
	{
		data.score += Ware_Minigame.boss ? Ware_PointsBossgame : Ware_PointsMinigame
		return
	}
	
	local player = data.player
	local special_data = Ware_GetPlayerSpecialRoundData(player)
	if (!simon)
	{
		local text = "{color}Simon didn't say \"{color}{str}{color}\"."
		if (!special_data.hint_shown)
		{
			text += "\n{color}HINT: {color}Only do what Simon tells you to do!"
			special_data.hint_shown = true
		}
		
		local description = Ware_Minigame.description
		if (typeof(description) == "array")
			description = description[Min(data.mission, description.len() - 1)]
		Ware_ChatPrint(player, text, TF_COLOR_DEFAULT, TF_COLOR_RED, description, TF_COLOR_DEFAULT, COLOR_GREEN, TF_COLOR_DEFAULT)
	}
}

function GetSomeone()
{
	if(RandomBool())
		return "Someone"
	
	return RandomElement(friends)
}
