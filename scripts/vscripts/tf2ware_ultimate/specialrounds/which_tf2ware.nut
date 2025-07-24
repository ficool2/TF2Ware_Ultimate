
// TODO: Add slag, tony or universe.

default_spawns   <- []
special_spawns   <- []
special_rotation <- []

sky_name <- ""

wares <-
[
	{
		name = "MicroTF2"
		home = "home_micro"
		spawn_name = "teamspawn_micro"
		skybox = "sky05"
		minigames =
		[
			"airblast"
			"break_barrel"
			"build_this"
			"change_class"
			"dont_touch"
			"double_jump"
			"flood"
			"hit_player"      // TODO: limit to just boston basher? guillotine? also should we add guillotine to normal one
			"jarate"
			"kamikaze"
			"land_platform"
			"laugh"
			"math"
			"move"
			"projectile_jump" // needle, sticky, rocket. maybe disable others?
			"rocket_jump"     // TODO: make this a boss just for this special somehow? also limit it to just micro arena, again, somehow.
			"sap"
			"sawrun"		  // TODO: only micro arena
			"type_word"
			"shoot_target"
			"simon_says"
			"spycrab"
			"stay_ground"
			"stun"
		]
		bossgames =
		[
			"beep_block"
			"escape_factory"
			"falling_platforms" // close enough to smash arena ig
			"typing"
		]
		themes =
		[
			"_default"
			"ds_diy_orbulon"
			"ds_diy_shuffle"
			"ds_touched_jimmyt"
			"ds_touched_wario"
			"ds_touched_warioman"
			"wii_mona"
		]
	}
]
Ware <- RandomElement(wares)

special_round <- Ware_SpecialRoundData
({
	name = "Which TF2Ware Is This Anyway?"
	author =  "pokemonPasta"
	description = "I thought these versions didn't work anymore.."
	category = ""
	
	home_location = "home_micro"
})

function OnStart()
{
	local theme = Ware_SetTheme(RandomElement(Ware.themes))
	
	Ware_ChatPrint(null, "TF2Ware Version: {color}{str}", COLOR_GREEN, Ware.name)
	Ware_ChatPrint(null, "New Theme: {color}{str}", COLOR_GREEN, theme.visual_name) // TODO: dont set this twice. the problem is themes are set well before specialrounds. need to swap the order
	
	sky_name = Convars.GetStr("sv_skyname")
	SetSkyboxTexture(Ware.skybox)
	
	for (local spawn; spawn = FindByClassname(spawn, "info_player_teamspawn");)
	{
		local name = spawn.GetName()
		
		if(name == Ware.spawn_name)
		{
			EntityAcceptInput(spawn, "Enable")
			special_spawns.append(spawn)
		}
		else if (name == "home_spawn" || name == "home_big_spawn")
		{
			EntityAcceptInput(spawn, "Disable")
			default_spawns.append(spawn)
		}
	}
	
	Ware_MinigameHomeLocation.Teleport(Ware_Players)
}

function GetMinigameName(is_boss)
{
	printl("GET 1 -----------------")
	
	if(is_boss)
	{
		printl("GET BOSS -----------------")
		return RandomElement(Ware.bossgames)
	}
	else
	{
		printl("GET MINI -----------------")
		
		if(special_rotation.len() == 0)
			special_rotation = clone(Ware.minigames)
		
		return RemoveRandomElement(special_rotation)
	}
}

function OnMinigameStart()
{
	if(Ware_Minigame.file_name == "flood")
			EntityAcceptInput(FindByName(null, "MainRoom_WaterMinigameStart"), "Trigger")
}

function OnEnd()
{
	SetSkyboxTexture(sky_name)
	
	foreach(ent in special_spawns)
		EntityAcceptInput(ent, "Disable")
	
	foreach(ent in default_spawns)
		EntityAcceptInput(ent, "Enable")
		
	//Ware_CheckHomeLocation(Ware_Players.len())
}
