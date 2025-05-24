// by ficool2 and pokemonpasta

// Settings for a minigame or bossgame
class Ware_MinigameData
{
	function constructor(table = null)
	{
		location        = "home"
		min_players     = 0
		max_players     = 256
		modes           = 1
		start_pass      = false
		allow_damage    = false
		allow_suicide   = false
		force_backstab  = false
		start_freeze    = 0.0
		fail_on_death   = false
		suicide_on_end  = false
		collisions 	    = false
		friendly_fire   = true
		thirdperson     = false
		boss		    = false
		show_scores     = true
		end_delay       = 0.0
		convars         = []
		entities        = []
		cleanup_names   = {}
		timers		    = []
		annotations     = []
		conditions      = []
		
		if (table)
		{
			foreach (key, value in table)
				this[key] = value
		}
	}
	
	// == Mandatory settings ==
	
	// Visual name
	name			= null
	// Who made the minigame?
	// Used for credits, please format your username the same way for each minigame you make. Use an array for multiple authors.
	author			= null
	// Description shown to people
	// This can either be a string or an array of strings (when using missions)
	description		= null
	// Length before ending
	duration		= null
	
	// == Optional settings ==
	
	// Music to play when the minigame starts
	// If you are going to be playing music separate from this parameter, make sure to precache it in OnPrecache with Ware_PrecacheMinigameMusic
	music			= null
	// Map location to teleport to (Ware_Location enum), default is home
	location		= null
	// Minimum amount of players needed to start, default is 0
	min_players		= null
	// Maximum amount of players needed to start, default is 256
	max_players     = null
	// Number of modes the minigame has, default is 1. This is used for minigames that share code but have variations such as Simon Says.
	// Setting a higher value than 1 will randomly assign a value  between 0 and (value - 1) to Ware_MinigameMode every time the minigame starts, which can be referred to for different modes
	modes           = null
	// Whether players will be flagged as passed when minigame starts, default is false
	start_pass		= null
	// Is damage to other players allowed? Default is false
	allow_damage	= null
	// Max player scale allowed in the minigame. If a player's scale is higher, it's clamped to max_scale and restored at the end. Default is null.
	max_scale       = null
	// Do suicides count for points? Default is false
	allow_suicide   = null	
	// Allow backstabs with any weapon
	force_backstab  = null
	// Freeze players when minigame starts, default is 0 seconds (don't freeze)
	// Useful to allow some reaction time to not fall off a ledge etc
	start_freeze    = null
	// Whether players should be automatically failed when they die, default is false
	fail_on_death	= null
	// Whether players should suicide if they haven't passed when minigame ends, default is false
	suicide_on_end	= null
	// Enables collisions between players, default is false
	collisions    	= null
	// Toggle friendlyfire, default is true
	friendly_fire	= null
	// Force players into thirdperson? Default is false
	thirdperson	    = null
	// Delay after the minigame "ends" before showing results, default is 0.0
	end_delay		= null
	// Show player scores on scoreboard while minigame is active, default is true\
	show_scores     = null
	// Custom text overlay to show rather than the default implied from name
	// This can either be a string or an array of strings (when using missions)
	custom_overlay	= null
	// Secondary custom text overlay to show 
	// Same rules as above
	custom_overlay2 = null
	// Table of convars to set for this minigame
	// Reverted to previous values after minigame ends
	convars			= null
	
	// == Internal use only ==
	
	// Is a boss game?
	boss			= null
	// File name
	file_name       = null
	// Entities spawned by the minigame, to remove after it ends
	entities		= null
	// Entity names to delete after minigame ends (e.g. projectiles)
	cleanup_names	= null
	// Timers spawned by the minigame, stopped after it ends
	timers			= null
	// Annotations created by the minigame, hidden after it ends
	annotations		= null
	// Player conditions added by the minigame, reverted after end
	conditions		= null
	
	// == Callbacks ==
	// If these functions exist in a minigame's scope, they are passed to the appropriate points in the code.
	// Game events in a minigame scope are also supported in the typical format (e.g. "OnGameEvent_player_builtobject(params)")
	
	// OnPrecache()                        - Ware_PrecacheNext checks all minigame scopes for OnPrecache when the map is loaded and calls any found. 
	//                                     - Use this if you need to precache anything.
	cb_on_precache          = null
	// OnPick()                            - Called when the minigame is selected for play. 
	//                                     - Returning false prevents the minigame from being selected.
	cb_on_pick              = null
	// OnTeleport(players)                 - Called when the minigame is teleporting players to the minigame's location.
	//                                     - If this function is not defined, uses the default Teleport function of the location instead.
	cb_on_teleport          = null
	// OnStart()                           - Called when the minigame is starting, after all players have teleported in.
	cb_on_start             = null
	// OnUpdate()                          - Called by Ware_OnUpdate every frame.
	cb_on_update			= null
	// OnCheckEnd()                        - Called by Ware_OnUpdate. 
	//                                       Return a condition in this function and if the condition is met, the minigame will end early.
	cb_on_check_end			= null
	// OnEnd()                             - Called when the minigame is ending, before results are calculated and players are teleported back.
	//                                     - Note that this can fire slightly before the minigame duration ends depending on the value of minigame's "end_delay".
	cb_on_end               = null
	// OnCleanup()	                       - Called after the minigame has ended and is cleaning up all of its information and state.
	//                                     - Use this to revert any changes done to the map, players, etc
	cb_on_cleanup           = null
	
	// OnTakeDamage(params)                - Called by OnTakeDamage in main.nut and functions as normal.
	cb_on_take_damage		= null
	// OnPlayerAttack(player)              - Called by Ware_OnUpdate, when a player attacks and passes that player.
	cb_on_player_attack		= null
	// OnPlayerDeath(player, attacker, params) - Called by OnGameEvent_player_death.
	//                                       Passes the victim player, attacker player (might be null) and remaining parameters.
	cb_on_player_death		= null
	// OnPlayerDisconnect(player)          - Called by OnGameEvent_player_disconnect, and passes the player.
	cb_on_player_disconnect	= null
	// OnPlayerSay(player, text)           - Called by OnGameEvent_player_say, and passes the player and what they typed.
	//									   - Leading and trailing whitespace is removed from the text
	cb_on_player_say		= null
	// OnPlayerVoiceline(player, name)     - Called by Ware_OnUpdate, and passes the player who used a voiceline and the name of the voiceline.
	cb_on_player_voiceline	= null
	// OnPlayerHorn(player)                - Called by Ware_OnUpdate when a player uses the horn in a kart (MOUSE1).
	//                                     - Passes the player who used a horn.
	cb_on_player_horn		= null
	// OnPlayerTouch(player, other_player) - Called by Ware_OnUpdate when two players touch and passes the two players.
	cb_on_player_touch		= null
	// OnPlayerInventory(player)  - Called by OnGameEvent_post_inventory_application.
	//                            - This happens when a player spawns, but is intended for manipulating loadouts.
	cb_on_player_inventory     = null
}

// Global variables

// The current minigame data. Null if no minigame active
Ware_Minigame             <- null
// Current minigame's scope
Ware_MinigameScope        <- {}
// Current minigame's location
Ware_MinigameLocation     <- null
// Current home location, players get teleported back here after a minigame
Ware_MinigameHomeLocation <- null

// Gets the time elapsed in seconds since the minigame has started
function Ware_GetMinigameTime()
{
	return Time() - Ware_MinigameStartTime
}

// Gets the time remaining in seconds before a minigame ends
function Ware_GetMinigameRemainingTime()
{
	return (Ware_MinigameStartTime + Ware_Minigame.duration + Ware_Minigame.end_delay) - Time()
}

// Precache a music file
// This is done automatically if specified in the minigame's "music" setting
function Ware_PrecacheMinigameMusic(name, is_boss)
{
	PrecacheSound(format("tf2ware_ultimate/v%d/music_%s/%s.mp3", WARE_MUSIC_VERSION, is_boss ? "bossgame" : "minigame", name))
}

// Sets the value of a convar
// The current value will be saved (if not already saved) and reverted after the minigame ends
function Ware_SetConvarValue(convar, value)
{
	Ware_Minigame.convars[convar] <- value
	if (!(name in Ware_MinigameSavedConvars))
		Ware_MinigameSavedConvars[name] <- GetConvarValue(name)
	SetConvarValue(name, value)
}

// Creates a timer that will be automatically killed early if the minigame ends before the timer executes
// Behaves identically to CreateTimer
function Ware_CreateTimer(on_timer_func, delay)
{
	local timer = CreateTimer(on_timer_func, delay)
	Ware_Minigame.timers.append(timer)
	return timer
}

// Creates an entity that will be automatically deleted after the minigame is over
// This behaves identically to Entities.CreateByClassname
function Ware_CreateEntity(classname)
{
	local entity = CreateEntitySafe(classname)
	Ware_Minigame.entities.append(entity)
	return entity
}

// Creates an entity that will be automatically deleted after the minigame is over
// This behaves identically to SpawnEntityFromTable
function Ware_SpawnEntity(classname, keyvalues)
{
	local entity = SpawnEntityFromTableSafe(classname, keyvalues)
	Ware_Minigame.entities.append(entity)
	return entity
}

// Spawns a temporary wearable (cosmetic, etc) that will be removed when a minigame ends
// This doesn't attach it to the player. You need to use SetEntityParent after spawning it
function Ware_SpawnWearable(player, model_name)
{
	local wearable = Ware_CreateEntity("tf_wearable")
	wearable.KeyValueFromString("classname", "ware_wearable")
	SetPropInt(wearable, "m_nModelIndex", PrecacheModel(model_name))
	SetPropBool(wearable, "m_bValidatedAttachedEntity", true)
	wearable.SetOwner(player)
	wearable.DispatchSpawn()
	return wearable
}

// Toggles the visibility of a cosmetic
function Ware_ToggleWearable(wearable, toggle)
{
	wearable.SetDrawEnabled(toggle)
}

// Shows a 2D annotation positioned in the 3D world
// Annotations are automatically hidden when a minigame ends
// "input" can be a vector or an entity handle
// If it's an entity handle, the annotation will follow that entity
// If you want it to start at an entity but stay there, pass that entity's origin instead
// Returns a unique ID which may be used to hide it later with Ware_HideAnnotation
function Ware_ShowAnnotation(input, text, lifetime = -1)
{
	local vector, entindex

	if (typeof(input) == "Vector")
	{
		vector = input
		entindex = 0
	}
	else if (typeof(input) == "instance")
	{
		vector = input.GetOrigin()
		entindex = input.entindex()
	}
	else
	{
		Ware_Error("Invalid input type passed to Ware_ShowAnnotation")
		return
	}
	
	if (Ware_SpecialRound && Ware_SpecialRound.reverse_text)
		text = ReverseString(text)
	
	local id = Ware_AnnotationIDs++
	
	SendGlobalGameEvent("show_annotation",
	{
		worldPosX = vector.x,
		worldPosY = vector.y,
		worldPosZ = vector.z,
		id = id,
		text = text,
		lifetime = lifetime,
		visibilityBitfield = 0,
		follow_entindex = entindex,
		show_distance = false,
		show_effect = false,
		play_sound = "common/null.wav",
	})
	
	if (Ware_Minigame != null)
		Ware_Minigame.annotations.append(id)
	
	return id
}

// Hides an annotation using an ID returned from Ware_ShowAnnotation
function Ware_HideAnnotation(id)
{
	SendGlobalGameEvent("hide_annotation", { id = id })
	if (Ware_Minigame != null)
	{
		local idx = Ware_Minigame.annotations.find(id)
		if (idx != null)
			Ware_Minigame.annotations.remove(idx)
	}
}

// Toggle whether respawn rooms in the home locations are enabled or not
// By default, they are disabled when a minigame starts, and enabled when the minigame ends
function Ware_ToggleRespawnRooms(toggle)
{
	if (toggle)
	{
		foreach (trigger in Ware_RespawnRooms)
			trigger.AcceptInput("SetActive", "", null, null)
	}
	else
	{
		foreach (trigger in Ware_RespawnRooms)
			trigger.AcceptInput("SetInactive", "", null, null)
	}
}