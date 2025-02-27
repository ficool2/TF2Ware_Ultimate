minigame <- Ware_MinigameData
({
	name            = "Say the Word"
	author          = ["Gemidyne", "ficool2"]
	description     = "Say the word below!"
	duration        = 4.0 + Ware_GetTimeScale() // extra time for lag compensation
	end_delay       = 0.5
	music           = "getready"
	custom_overlay2 = "../chalkboard"
	suicide_on_end  = true
})

words <-
[
	"Heavy"
	"Scout"
	"Jarate"
	"Wrench"
	"Spy"
	"Soldier"
	"Medic"
	"Sniper"
	"Sasha"
	"Engy"
	"Saxton"
	"Sandman"
	"Pyro"
	"Demoman"
	"Engineer"
	"Bat"
	"Bear"
	"Fists"
	"White"
	"Wario"
	"Valve"
	"Black"
	"Yellow"
	"Green"
	"Blue"
	"Flowey" // :)
	"Mann Co"
	"Sentry"
	"Rocket"
	"Sticky"
	"Uber"
	"Cloak"
	"Sandvich"
	"Sandwich"
	"Bonk"
	"Hale"
	"Crate"
	"Key"
	"Taunt"
	"Spycrab"
	"Crits"
	"Payload"
	"Capture"
	"Arena"
	"Comics"
	"Unusual"
	"Strange"
	"Gaben"
	"Steam"
	"Scrap"
	"Sheen"
	"Point"
	"Tank"
	"Sapper"
	"Conga"
	"Yeti"
	"Intel"
	"Contract"
	"Aussie"
	"Earbud"
	"Disguise"
	"Aimbot"
	"2Fort"
	"Dustbowl"
	"Granary"
	"Gravelpit"
	"Hydro"
	"Well"
	"Krampus"
	"Phlog"
	"Prophunt"
	"Smash"
	"TF2Ware"
	"Redsun"
	"Frog"
	"Meow"
	"Cat"
	"Skull"
	"Cookie"
	"Turtle"
	"VScript"
	"Squirrel"
	"Pawn"
	"Inspect"
	"Crash"
	"Raiden"
	"Freaky"
	"Banana"
	
	// these two are evil but rare
	"Bombinomicon"
	"Shahanshah"
	// I'm so sorry
	"Claidheamh Mor"
]

first <- true
word <- null

function OnStart()
{
	word = RandomElement(words)
	// these spaces are to prevent localization
	Ware_ShowMinigameText(null, format(" %s ", word))
	word = word.tolower()

	Ware_CreateTimer(@() OnNonLagCompensatedEnd(), Ware_Minigame.duration - Ware_GetTimeScale()) // fire the end early before lag compensation happens
}

function OnNonLagCompensatedEnd()
{
	Ware_ChatPrint(null, "The correct time was {color}{%02d}:{%02d}{color} or {color}{%02d}:{%02d}", 
		COLOR_LIME, hour, minute, TF_COLOR_DEFAULT, COLOR_LIME, hour + 12, minute)
}

function OnPlayerSay(player, text)
{	
	if (text.tolower() == word)
	{
		if (player.IsAlive() && Time() - GetPlayerLatency(player) < Ware_MinigameStartTime + Ware_Minigame.duration - Ware_GetTimeScale()) // pass the player if they typed it in time but server received it late
		{
			Ware_PassPlayer(player, true)
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}said the word first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
		return false
	}
	else
	{
		if (Ware_IsPlayerPassed(player) || !player.IsAlive())
			return
		
		Ware_SuicidePlayer(player)
	}
}