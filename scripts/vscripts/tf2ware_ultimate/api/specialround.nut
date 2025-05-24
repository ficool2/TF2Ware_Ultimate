// by ficool2 and pokemonpasta

// Settings for a special round
class Ware_SpecialRoundData
{
	function constructor(table = null)
	{
		min_players       = 0
		max_players       = 256
		convars           = {}
		reverse_text      = false
		allow_damage      = false
		force_collisions  = false
		opposite_win      = false
		friendly_fire     = true
		force_pvp_damage  = false
		bonus_points      = false
		allow_respawnroom = true
		boss_count        = 1
		boss_threshold    = Ware_BossThreshold
		speedup_threshold = Ware_SpeedUpThreshold
		pitch_override    = -1
		
		if (table)
		{
			foreach (key, value in table)
				this[key] = value
		}
	}
	
	// == Mandatory settings ==
	
	// Visual name
	name             		 = null
	// Who made this?
	// Used for credits, please format your username the same way for each special round you make. Use an array for multiple authors.
	author           		 = null
	// Description shown in chat
	description      		 = null
	// Category string
	// Used when stacking multiple special rounds. More than one special round from a given category cannot be stacked.
	// If category is blank, it's assumed it has no possible conflicts with any other special round
	category                 = null
	
	// == Optional settings ==
	// Minimum amount of players needed to start, default is 0
	min_players      		 = null
	// Maximum amount of players needed to start, default is 256
	max_players      		 = null	
	// Table of convars to set for this special round
	// Reverted to previous values after special round ends	
	convars          		 = null
	// Reverse all text! Default is false
	reverse_text     		 = null
	// Always allow damage, including between minigames, default is false
	allow_damage     		 = null
	// Always enable collisions between players, default is false
	force_collisions 		 = null
	// Inverted win condition, e.g. not passing means you win, default is false
	opposite_win			 = null
	// Friendly fire allowed on minigames? Default is true
	friendly_fire            = null
	// Always allow player to always damage each other. Default is false
	force_pvp_damage         = null
	// Allow respawning in intermission when changing class? Default is true
	allow_respawnroom        = null	
	// Award bonus points? Default is false
	bonus_points             = null
	// Amount of bosses to play, default is 1
	boss_count       		 = null
	// Amount of minigames played before a boss, default is Ware_BossThreshold in config.nut
	boss_threshold           = null
	// Amount of minigames played before a speedup, default is Ware_SpeedUpThreshold in config.nut
	speedup_threshold        = null
	// Override player voice pitch if set
	pitch_override           = null

	// == Internal use only ==
	file_name                = null
	
	// == Callbacks == 
	// If these functions exist in a special round's scope, they are passed to the appropriate points in the code.
	// Game events in a special round scope are also supported in the typical format (e.g. "OnGameEvent_player_builtobject(params)")
	// Note some of these callbacks replace crucial parts of the gameplay loop.
	// If the logic in these functions isn't replicated properly, gameplay may get stuck.
	// e.g. Normally Ware_Speedup calls Ware_BeginIntermission at the end.
	//      If you include OnSpeedup in the scope but don't call Ware_BeginIntermission or something else in the gameplay loop, the game will get stuck after speedup.
	
	// OnPrecache()               - Ware_PrecacheNext checks all special round scopes for OnPrecache when the map is loaded and calls any found. 
	//                            - Use this if you need to precache anything.
	cb_on_precache             = null
	// OnPick()                   - Called when the special round is selected for play. 
	//                            - Returning false prevents the minigame from being selected.
	cb_on_pick                 = null
	// OnStart()                  - Called when this special round begins.
	cb_on_start                = null
	// OnUpdate()                 - Called by Ware_OnUpdate every frame.
	cb_on_update               = null
	// OnEnd()                    - Called when this special round ends.
	cb_on_end                  = null
	// GetName(params)            - Called by Ware_GetSpecialRoundName. Overrides the English name for the special round if specified.
	cb_get_name                = null	
	// GetOverlay2()              - Replaces the default secondary overlay texture in Ware_ShowScreenOverlay2 (see player.nut). 
	//                            - Return an overlay texture for it to be set.
	cb_get_overlay2            = null	
	// GetMinigameName(is_boss)   - Replaces the minigame selection process in Ware_StartMinigame. 
	//                            - Return a minigame name for it to be attempted to be selected, or null to use default pick.
	cb_get_minigame            = null
	// OnMinigameStart()          - Called by Ware_StartMinigame when a minigame starts. 
	//                            - This is after a minigame has been chosen, so you can refer to Ware_Minigame and similar.
	cb_on_minigame_start       = null
	// OnMinigameEnd()            - Called by Ware_EndMinigame when a minigame ends. 
	//                            - This is before the minigame is cleaned up, so you can still refer to Ware_Minigame and similar.
	cb_on_minigame_end         = null
	// OnMinigameCleanup()        - Called by Ware_EndMinigame when a minigame cleans up, before scores are calculated.
	cb_on_minigame_cleanup     = null
	// OnBeginIntermission(is_boss) - Called when intermission starts.
	//                              - If this returns true, the default logic for Ware_BeginIntermission is replaced.
	//                              - Note there are some debug functions that are always called.
	//                              - This replaces a core part of the gameplay loop, 
	//                                and if Ware_StartMinigame or another appropriate function isn't called, the game will stop.
	cb_on_begin_intermission   = null
	// OnSpeedup()                - Called by Ware_Speedup.
	//                            - If this returns true, replaces the speedup logic in a similar way to OnBeginIntermission.
	cb_on_speedup              = null	
	// OnBeginBoss()              - Called by Ware_BeginBoss when a boss notification appears.
	//                            - If this returns true, the default logic for Ware_BeginBoss is replaced.
	//                            - Since this replaces a core part of the gameplay loop, 
	//                            - you need to call Ware_BeginIntermission yourself to continue it.
	cb_on_begin_boss           = null
	// OnCheckGameOver()          - Called by Ware_FinishMinigameInternal, return true to force an early game over
	cb_on_check_gameover       = null
	// GetValidPlayers()          - Replaces Ware_GetValidPlayers, which is used when selecting players to play a minigame.
	//                            - Return an array of players in this function and those players will be assigned to play a minigame and added to Ware_MinigamePlayers.
	cb_get_valid_players       = null
	// OnCalculateScore(data)     - Called when performing score calculation at the end of a minigame.
	//                            - This function is called for each player in Ware_MinigamePlayers, and passes that player's data each time.
	//                            - Return false to use the normal score calculation instead
	cb_on_calculate_score      = null
	// OnCalculateTopScorers(top_players) - Replaces assignment to Ware_MinigameTopScorers, which is used for assigning top scorer particle effects
	//                              and determining the winner at the end of the game. 
	//                            - top_players is a reference to Ware_MinigameTopScorers, so append players to the passed array.
	//							  - If false is returned, the default calculation will be used.
	cb_on_calculate_topscorers = null
	// OnDeclareWinners(top_players, top_score, winner_count) - Replaces winner declaration in Ware_GameOver. 
	//                            - Passes some relevant information that might be used for replacement info.
	//							  - If false is returned, the default declaration is used.
	cb_on_declare_winners      = null
	// OnPlayerConnect(player)    - Called by OnGameEvent_player_spawn during late spawn setup, and passes the player
	cb_on_player_connect       = null
	// OnPlayerDisconnect(player) - Called by OnGameEvent_player_disconnect, and passes the player.
	cb_on_player_disconnect	   = null
	// OnPlayerSpawn(player)      - Called by OnGameEvent_player_spawn and passes the player that spawned.
	cb_on_player_spawn         = null
	// OnPlayerPostSpawn(player)  - Called at the end of the frame by OnGameEvent_player_spawn
	//                            - Useful to apply attributes as those won't apply in OnPlayerSpawn
	cb_on_player_postspawn     = null
	// OnPlayerInventory(player)  - Called by OnGameEvent_post_inventory_application. 
	//                            - This happens when a player spawns, but is intended for manipulating loadouts.
	cb_on_player_inventory     = null
	// OnPlayerVoiceline(player, name) - Called by Ware_OnUpdate, and passes the player who used a voiceline and the name of the voiceline.
	cb_on_player_voiceline	= null
	// GetPlayerRoll(player)      - Replaces the z value in player QAngles on spawn and teleport.
	cb_get_player_roll         = null
	// CanPlayerRespawn(player)   - If returns true, allows a dead player to respawn
	cb_can_player_respawn      = null
	// OnPlayerTouch(player, other_player) - Called by Ware_OnUpdate when two players touch and passes the two players.
	cb_on_player_touch         = null
	// OnTakeDamage(params)       - Called by OnTakeDamage in main.nut and functions as normal.
	cb_on_take_damage          = null
	
	// NOTE: if you are adding callbacks, update the double_trouble special round (it forwards every callback!)
}

// Rolls and starts a special round
// Returns true if a special round was successfully rolled
function Ware_BeginSpecialRound()
{
	return Ware_BeginSpecialRoundInternal()
}

// Ends the current special round if present
function Ware_EndSpecialRound()
{
	Ware_EndSpecialRoundInternal()
}

// Forces next round to be a special round
function Ware_ForceSpecialRound()
{
	Ware_SpecialRoundNext = true
}

// Checks if given special round is set by filename
// This also checks for Double Trouble's two special rounds
function Ware_IsSpecialRoundSet(file_name)
{
	if (Ware_SpecialRound)
	{
		if ("IsSet" in Ware_SpecialRoundScope)
		{	
			if (Ware_SpecialRoundScope.IsSet(file_name))
				return true
		}
		return Ware_SpecialRound.file_name == file_name
	}
	return false
}