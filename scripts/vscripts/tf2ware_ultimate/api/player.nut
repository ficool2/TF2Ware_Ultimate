// by ficool2 and pokemonpasta

// Gamemode-specific data each player has
// Not to be confused with Ware_PlayersData, which is the array of every instance of this class
class Ware_PlayerData
{
	function constructor(entity)
	{
		player           = entity
		index			 = player.entindex()
		scope            = entity.GetScriptScope()
		lerp_time        = 0.0
		passed           = false
		passed_effects   = false
		mission          = 0
		suicided         = false
		attributes       = {}
		melee_attributes = {}
		start_sound      = false
		score			 = 0
		bonus            = 0
		horn_timer		 = 0.0
		horn_buttons	 = 0
		spawn_time       = 0.0
	}
	
	// The player's entity handle
	player		     	= null
	// The player's entindex
	index			 	= null
	// The player's script scope
	scope		     	= null
	// The player's cl_interp (for lag compensation
	lerp_time			= null
	// Whether or not the player has passed the current minigame. Note this can change back and forth and is only checked at the end of a minigame.
	passed		     	= null
	// Used to add effects to players who have passed the previous minigame.
	passed_effects   	= null
	// For minigames that use missions (e.g. dont_laugh, slender, ghostbusters), what mission this player is on.
	mission		     	= null
	// Whether the player kill-binded during the minigame
	suicided            = null
	// Entity handle for the player's melee weapon.
	melee		     	= null
	// Entindex for the player's melee weapon.
	melee_index      	= null
	// Entity handle for special melees, which are created by certain minigames or special rounds.
	special_melee       = null
	// Entity handle for the special melee's viewmodel.
	special_vm          = null
	// Table of attributes the player currently has.
	attributes	     	= null
	// Table of attributes the player's melee weapon currently has.
	melee_attributes 	= null
	// Whether or not the player is currently listening to the starting music during Waiting for Players.
	start_sound      	= null
	// The player's stored scale if a particular minigame is altering it.
	saved_scale         = null
	// The player's stored team if a particular minigame is altering it.
	saved_team       	= null
	// The player's current score, including bonus points.
	score			 	= null
	// 	The player's bonus points
	bonus               = null
	// Used to track horn cooldown while the player is in a kart.
	horn_timer		 	= null
	// Used to track if the player is currently pressing the horn button while in a kart.
	horn_buttons	 	= null
	// Timestamp when player last respawned
	spawn_time          = null
}

// Global variables
if (!("Ware_Players" in this)) // These variables never reset
{
	// List of all players in the server
	Ware_Players                  <- []
	// List of all players participating in the current minigame/bossgame
	Ware_MinigamePlayers          <- []
}

// Gets the gamemode data associated with a player
function Ware_GetPlayerData(player)
{
	return player.GetScriptScope().ware_data
}

// Gets the minigame data ("minidata") associated with a player
// Minidata is a table where a minigame can store it's own variables
// E.g. useful to keep track of scores per-player in a minigame
// The table is purged after a minigame is ended
function Ware_GetPlayerMiniData(player)
{
	return player.GetScriptScope().ware_minidata
}

// Gets the special round data associated with a player
// This functions like minidata but is used in special rounds instead, and is cleared when a special round ends.
function Ware_GetPlayerSpecialRoundData(player)
{
	return player.GetScriptScope().ware_specialdata
}

// Marks a player as "passed" during a minigame
// This also plays the sound and particle effects
// This does nothing if the player is already passed
// Returns true if the player's pass state changed
function Ware_PassPlayer(player, pass)
{
	local data = player.GetScriptScope().ware_data
	if (data.passed == pass)
		return false
	if (data.suicided && Ware_Minigame && !Ware_Minigame.allow_suicide)
		return false
	
	if (!Ware_BlockPassEffects)
	{
		local pass_flag = !(Ware_SpecialRound && Ware_SpecialRound.opposite_win)
		if (pass == pass_flag && !data.passed_effects)
		{
			Ware_ShowPassEffects(player)
			data.passed_effects = true
		}
	}
	
	data.passed = pass
	return true
}

// Returns true if the player is considered "passed" during a minigame
function Ware_IsPlayerPassed(player)
{
	return player.GetScriptScope().ware_data.passed
}

// Awards bonus points for certain objectives in minigames (first, fastest, etc.)
// This only functions if Ware_BonusPoints is true, or in the bonus points special round, otherwise it does nothing.
// If multiple players are to be awarded please pass an array of players, to avoid spamming the chat.
function Ware_GiveBonusPoints(target, points = 1)
{
	local award = true
	if (!Ware_BonusPoints && !(Ware_SpecialRound && Ware_SpecialRound.bonus_points))
		award = false
	
	// even if there's no award, this is still tracked for the event	
	local player_indices_awarded = ""
	local awarded = target
	if (typeof(awarded) == "instance")
		awarded = [target]
	foreach (player in awarded)
		player_indices_awarded += player.entindex().tochar()
	
	if (award)
	{
		// account for multiple possible but we only got 1 player
		if (typeof(target) == "array" && target.len() == 1)
			target = target[0]
		
		if (typeof(target) == "instance")
		{
			local data = target.GetScriptScope().ware_data
			data.score += points
			data.bonus += points
			
			Ware_ChatPrint(null, "{color}{str}{color} was awarded an extra {str}!",
				TF_COLOR_RED, GetPlayerName(target), TF_COLOR_DEFAULT, points == 1 ? "point" : format("%d points", points))
		}
		else
		{
			local text = ""
			local params = [this, text, points == 1 ? "point" : format("%d points", points), TF_COLOR_RED]
			foreach (player in target)
			{
				local data = player.GetScriptScope().ware_data
				data.score += points
				data.bonus += points
				
				text += text == "" ? "The following players were each awarded an extra {str}: {color}" : "{color}, {color}"
				text += GetPlayerName(player)
				params.append(TF_COLOR_DEFAULT)
				params.append(TF_COLOR_RED)
			}
			text += "{color}!"
			params += TF_COLOR_DEFAULT
			params[1] = text
			
			Ware_ChatPrint.acall(params)
		}
	}
	
	Ware_EventCallback("bonus_points", 
	{
		minigame_name      = Ware_Minigame ? Ware_Minigame.name : ""
		minigame_file_name = Ware_Minigame ? Ware_Minigame.file_name : ""
		players_awarded    = player_indices_awarded
	})
}

// Sets the player's "mission"
// This should be an incremental number starting from 0
// Minigames can have different objectives for different players
// This can be used to assign players to the corresponding objective
// This will automatically choose the appropriate minigame overlay as well
// Internally, all player's begin on mission 0 by default
function Ware_SetPlayerMission(player, mission)
{
	return player.GetScriptScope().ware_data.mission = mission
}

// Returns the player's current "mission", see above
function Ware_GetPlayerMission(player)
{
	return player.GetScriptScope().ware_data.mission
}

// Sets a player loadout, i.e. their class and their items
// This removes all items/weapons they currently have, including their melee (unless "keep_melee" is true)
// If class is TF_CLASS_UNDEFINED, the class is not changed
// Items is an optional item name, or array of item names to give to the player
// For a list of item names, see items.nut
// If items is null, the player is switched to their default melee
// Item attributes is a list of attributes to apply to the given item, or default melee
function Ware_SetPlayerLoadout(player, player_class, items = null, item_attributes = {}, keep_melee = false, switch_weapon = true)
{
	if (player_class != TF_CLASS_UNDEFINED)
		Ware_SetPlayerClass(player, player_class, false)
	
	if (items)
	{
		Ware_StripPlayer(player, keep_melee)
		
		if (typeof(items) == "array")
		{
			local last_item = items[items.len() - 1]
			foreach (item in items)
				Ware_GivePlayerWeapon(player, item, {}, switch_weapon && item == last_item)
		}
		else
		{
			Ware_GivePlayerWeapon(player, items, item_attributes, switch_weapon)
		}
	}
	else
	{
		player.RemoveCond(TF_COND_TAUNTING)
		
		local data = player.GetScriptScope().ware_data
		local melee
		if (data.special_melee)
			melee = data.special_melee
		else
			melee = data.melee

		if (melee && !melee.IsValid())
			melee = null
			
		if (melee)
		{
			if (item_attributes.len() > 0)
			{
				foreach (attribute, value in item_attributes)
					melee.AddAttribute(attribute, value, -1.0)
				data.melee_attributes = clone(item_attributes)
			}
		}
		
		melee = Ware_ForceSwitchPlayerMelee(player, melee)
		
	}
		
	SetPropEntity(player, "m_hLastWeapon", null)	
}

// Sets a loadout for all players
// See Ware_SetPlayerLoadout
function Ware_SetGlobalLoadout(player_class, items = null, item_attributes = {}, keep_melee = false, switch_weapon = true)
{
	foreach (player in Ware_MinigamePlayers)
		Ware_SetPlayerLoadout(player, player_class, items, item_attributes, keep_melee, switch_weapon)		
}

// Strips all items/weapons from a player
// If give_default_melee is true, their default melee is given back
function Ware_StripPlayer(player, give_default_melee)
{
	player.RemoveCond(TF_COND_DISGUISING)
	player.RemoveCond(TF_COND_DISGUISED)
	player.RemoveCond(TF_COND_TAUNTING)
	player.RemoveCond(TF_COND_ZOOMED)
		
	local data = player.GetScriptScope().ware_data
	local melee = data.melee
	local special_melee = data.special_melee
	
	for (local i = 0; i < MAX_WEAPONS; i++)
	{
		local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
		if (weapon)
		{
			SetPropEntityArray(player, "m_hMyWeapons", null, i)

			if (weapon != melee && weapon != special_melee)
				KillWeapon(weapon)
		}
	}

	if (give_default_melee)
	{
		local use_melee
		if (special_melee != null && special_melee.IsValid())
			use_melee = special_melee
		else if (melee != null && melee.IsValid())
			use_melee = melee
		
		if (use_melee)
		{
			SetPropEntityArray(player, "m_hMyWeapons", use_melee, data.melee_index)
			
			local active_weapon = player.GetActiveWeapon()
			if (active_weapon != use_melee)
			{
				if (active_weapon != null)
				{								
					// force switch fixes
					local classname = active_weapon.GetClassname()
					if (classname == "tf_weapon_minigun")
					{
						SetPropEntity(player, "m_hActiveWeapon", null)
					}
					else if (startswith(classname, "tf_weapon_sniperrifle"))
					{
						SetPropFloat(active_weapon, "m_flNextPrimaryAttack", 0.0)
					}
					else if (classname == "tf_weapon_rocketpack")
					{
						active_weapon.AddAttribute("holster_anim_time", 0.0, -1)
						SetPropFloat(active_weapon, "m_flLaunchTime", 0.0)	
						if (player.InCond(TF_COND_ROCKETPACK))
						{
							// needed to stop air sound
							SendGlobalGameEvent("rocketpack_landed", { userid = GetPlayerUserID(player) })
							player.RemoveCond(TF_COND_ROCKETPACK)
						}
					}
					else if (classname == "tf_weapon_mechanical_arm")
					{
						local viewmodel = GetPropEntity(player, "m_hViewModel")
						if (viewmodel)
							viewmodel.SetBodygroup(1, 0)
					}
				}
				
				use_melee = Ware_ForceSwitchPlayerMelee(player, use_melee)
			}
		}
	}
}

// Gives a specified item/weapon to the player
// For a list of item names, see items.nut
// "attributes" is a table of attributes that will be applied on the weapon
// If "switch_weapon" is true, the player is automatically switched to the new weapon
function Ware_GivePlayerWeapon(player, item_name, attributes = {}, switch_weapon = true)
{
	local item = ITEM_MAP[item_name]
	local item_id = item.id
	local item_classname = item.classname
	
	if (item_classname == "tf_weapon_shotgun") 
	{
		local player_class = player.GetPlayerClass()
		if (player_class == TF_CLASS_SOLDIER)
		{
			if (item_id == 9) item_id = 10
			item_classname = "tf_weapon_shotgun_soldier"
		}
		else if (player_class == TF_CLASS_PYRO)
		{
			if (item_id == 9) item_id = 12
			item_classname = "tf_weapon_shotgun_pyro"
		}	
		else if (player_class == TF_CLASS_HEAVYWEAPONS)
		{
			if (item_id == 9) item_id = 11
			item_classname = "tf_weapon_shotgun_hwg"
		}	
		else /* if (player_class == TF_CLASS_ENGINEER)*/
		{
			if (item_id == 9) item_id = 9
			item_classname = "tf_weapon_shotgun_primary"
		}			
	}
	else if (item_id == 22) // pistol
	{
		if (player.GetPlayerClass() == TF_CLASS_SCOUT)
			item_id = 23
	}
	else if (item_classname == "saxxy")
	{
		item_classname = SAXXY_CLASSNAME_MAP[player.GetPlayerClass()]
	}
	
	local weapon = CreateEntitySafe(item_classname)
	SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", item_id)
	SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	SetPropBool(weapon, "m_bValidatedAttachedEntity", true)
	weapon.SetTeam(player.GetTeam())
	weapon.DispatchSpawn()
	
	if (item_id == 28) // builder
	{
		for (local i = 0; i < 3; i++)
			SetPropIntArray(weapon, "m_aBuildableObjectTypes", 1, i)
		SetPropInt(weapon, "m_iObjectType", 0)
		switch_weapon = false
	}
	else if (item_id == 735 || item_classname == "tf_weapon_sapper") // sapper
	{
		SetPropIntArray(weapon, "m_aBuildableObjectTypes", 1, 3)
		SetPropInt(weapon, "m_iObjectType", 3)
		SetPropInt(weapon, "m_iSubType", 3)
	}
	
	weapon.ValidateScriptScope()
	weapon.GetScriptScope().last_fire_time <- 0.0
	
	// bit of a hack: penetration is required for friendlyfire to work
	if (startswith(item_classname, "tf_weapon_sniperrifle"))
		weapon.AddAttribute("projectile penetration", 1, -1)
		
	// this is to give people more time to react
	weapon.AddAttribute("deploy time increased", 1.5, -1)
		
	// prevent thriller taunt
	weapon.AddAttribute("special taunt", 1, -1)
	
	foreach (attribute, value in attributes)
		weapon.AddAttribute(attribute, value, -1.0)

	player.Weapon_Equip(weapon)
	if (switch_weapon)
	{
		if (item_id != 28) // toolbox
		{
			if (Ware_DelayPDASwitch && (item_id == 25 || item_id == 27)) // construction pda
			{
				// build/disguise menu will not show up unless its holstered for a bit
				// NOTE; avoid switching to PDAs if possible as it's only 99% reliable even with this much delay
				EntFireByHandle(player, "CallScriptFunction", "Ware_FixupPlayerWeaponSwitch", 0.5, weapon, weapon)
			}
			else
			{
				player.Weapon_Switch(weapon)
			}
		}
	}
	
	if (Ware_Minigame != null)
	{
		if (item_id in ITEM_PROJECTILE_MAP)
		{
			local proj_classname = ITEM_PROJECTILE_MAP[item_id]
			if (!(proj_classname in Ware_Minigame.cleanup_names))
			{
				Ware_Minigame.cleanup_names[proj_classname] <- 1
				Ware_Minigame.cleanup_names["ware_projectile"] <- 1
			}
		}
	}
	
	return weapon
}

// Force switch to the player melee
function Ware_ForceSwitchPlayerMelee(player, melee)
{
	if (melee)
		player.Weapon_Switch(melee)
	
	// removed: this was an attempt to workaround the no-melee bug, but this didn't fix it
	// keeping old code here if needed again
	
	/*
	if (melee)
	{
		player.Weapon_Switch(melee)
		if (player.GetActiveWeapon() == melee)
			return melee
		// HACK: failsafe for unknown rare bug where the player has no melee
		// Unsure whether this is caused by a switch failure or melee not being physically present
	}
	
	// If melee is null, or the switch failed, gives default melee
	local weapon = Ware_GivePlayerWeapon(player, STOCK_MELEE_MAP[player.GetPlayerClass()])
	if (player.GetActiveWeapon() == weapon)
	{
		local data = player.GetScriptScope().ware_data
		if (data.melee && data.melee.IsValid())
			KillWeapon(data.melee)
		data.melee = weapon
		return weapon
	}
	else
	{
		// if switch still failed we are screwed at this point!!
		weapon.Destroy()
		return null
	}
	*/
}

// Equips a melee that should override the default one, if the player doesn't have one already
// This melee will only be used if the minigame doesn't strip out melees
// A viewmodel entity can also be equipped, intended to complement the special weapon
// Either "melee" or "vm" can be null to not equip them respectively
function Ware_EquipSpecialMelee(player, melee, vm)
{
	local data = Ware_GetPlayerData(player)
	
	if (melee)
	{
		player.Weapon_Equip(melee)
		local index = data.melee_index
		for (local i = 0; i < MAX_WEAPONS; i++)
		{
			local weapon = GetPropEntityArray(player, "m_hMyWeapons", i)
			if (weapon == melee)
			{
				SetPropEntityArray(player, "m_hMyWeapons", null, i)
				index = i
				data.melee_index = i
				break
			}
		}
		
		SetPropEntityArray(player, "m_hMyWeapons", melee, index)
		player.Weapon_Switch(melee)
		data.special_melee = melee	
	}
	
	if (vm)
	{
		local special_vm = data.special_vm	
		if (!special_vm || !special_vm.IsValid())
		{
			player.EquipWearableViewModel(vm)
			vm.KeyValueFromString("classname", "ware_specialvm")
			data.special_vm = vm
		}
	}	
}

// Destroys the special melee a player has, and the viewmodel for it, if any
function Ware_DestroySpecialMelee(player)
{
	local data = Ware_GetPlayerData(player)
	
	local special_vm = data.special_vm	
	local special_melee = data.special_melee
	
	if (special_vm)
	{
		if (special_vm.IsValid())
			special_vm.Kill()
		data.special_vm = null
	}
	
	if (special_melee)
	{	
		local weapon = player.GetActiveWeapon()		
		if (weapon == special_melee)
			player.Weapon_Switch(data.melee)
			
		if (special_melee.IsValid())
			KillWeapon(special_melee)
		
		data.special_melee = null
	}
}

// Players that are force switched to PDAs not show the menu unless given with a delay
// Set this to true and revert back to false before giving a weapon if you want to show the menu
// Note this is not reliable depending on lag, and may sometimes still not show the menu
Ware_DelayPDASwitch <- false

// Sets the player's class, and regenerates their health, ammo, melee etc
// If "switch_melee" is true, the player will be switched to their new melee
// Does nothing if the player is already the given class
local Ware_CheckTeleportEffectTimer // Ignore this
function Ware_SetPlayerClass(player, player_class, switch_melee = true)
{
	if (player.GetPlayerClass() == player_class)
		return
	
	SetPropInt(player, "m_Shared.m_iDesiredPlayerClass", player_class)
	player.SetPlayerClass(player_class)
	player.Regenerate(true)
	player.SetCustomModelWithClassAnimations(GetPropString(player, "m_PlayerClass.m_iszCustomModel"))

	local melee = Ware_ParseLoadout(player)
	if (melee)
		Ware_ModifyMeleeAttributes(melee)
		
	player.SetHealth(player.GetMaxHealth())
	
	// teleport effect gets cleared on class change, need to recreate it here
	// creating timers is expensive so avoid doing that for every player
	player.RemoveCond(TF_COND_TELEPORTED)
	if (!Ware_CheckTeleportEffectTimer || !Ware_CheckTeleportEffectTimer.IsValid())
	{
		Ware_CheckTeleportEffectTimer = CreateTimer(function()
		{
			local top_scorers = Ware_MinigameTopScorers
			foreach (player in Ware_MinigamePlayers)
			{
				if (top_scorers.find(player) != null)
					player.AddCond(TF_COND_TELEPORTED)
			}
		}, 0.25)
	}

	if (melee != null)
	{
		// not sure why this is needed
		melee.SetModel(TF_CLASS_ARMS[player_class])
	}
	
	if (switch_melee)
	{
		melee = Ware_ForceSwitchPlayerMelee(player, melee)
		if (melee)
			melee.EnableDraw()
	}
}

// Sets the player's team
// Their current team is saved and reverted when a minigame ends
function Ware_SetPlayerTeam(player, team)
{
	local old_team = player.GetTeam()
	local data = player.GetScriptScope().ware_data
	if (data.saved_team == null)
		data.saved_team = old_team
	Ware_SetPlayerTeamInternal(player, team)
}

// Sets the player's scale
// If save_scale is passed, also saves the previous scale and reverts it at the end of the next minigame
// NOTE: Only reverts the first saved scale since the end of the previous minigame
function Ware_SetPlayerScale(player, scale, time = 0.0, save_scale = false)
{
	if (save_scale)
	{
		local old_scale = player.GetModelScale()
		local data = player.GetScriptScope().ware_data
		
		if (data.saved_scale == null)
			data.saved_scale = old_scale
	}
	
	player.SetModelScale(scale, time)
}

// Iterates Ware_SetPlayerScale across all players
function Ware_SetGlobalPlayerScale(scale, time = 0.0, save_scale = false)
{
	foreach(player in Ware_MinigamePlayers)
		Ware_SetPlayerScale(player, scale, time, save_scale)
}

// Toggles the visibility of all wearables (including weapons!) on a player
function Ware_TogglePlayerWearables(player, toggle)
{
	for (local wearable = player.FirstMoveChild(); wearable; wearable = wearable.NextMovePeer())
	{
		MarkForPurge(wearable)
		Ware_ToggleWearable(wearable, toggle)
	}
}

// Gets a list of alive players, optionally on the given team
function Ware_GetAlivePlayers(team = TEAM_UNASSIGNED)
{
	if (team & TF_TEAM_MASK)
		return Ware_MinigamePlayers.filter(@(i, player) player.GetTeam() == team && player.IsAlive())
	else
		return Ware_MinigamePlayers.filter(@(i, player) player.IsAlive())
}

// Gets a list of players on the given team
function Ware_GetTeamPlayers(team)
{
	return Ware_MinigamePlayers.filter(@(i, player) player.GetTeam() == team)
}

// Gets a list of players that haven't been passed
// Optionally it will only fetch alive unpassed players
function Ware_GetUnpassedPlayers(alive_only = false)
{
	// Ware_MinigamePlayersData.filter(@(i, data) data.passed
	local players = []
	foreach (data in Ware_MinigamePlayersData)
	{
		if (data.passed)
			continue
		local player = data.player
		if (alive_only && !player.IsAlive())
			continue
		players.append(player)
	}
	return players
}

// Gets a list of alive players that are on red or blue team
// Internally this decides what players will be placed into a minigame
function Ware_GetValidPlayers(is_boss = false)
{
	if (Ware_SpecialRound && Ware_SpecialRound.cb_get_valid_players.IsValid())
		return Ware_SpecialRound.cb_get_valid_players()
	else
	{
		local valid_players = []
		foreach (player in Ware_Players)
		{
			if (player.GetTeam() & TF_TEAM_MASK)
			{
				if (!player.IsAlive())
				{
					// only respawn everyone before the boss
					// for minigames intentionally not respawning people
					// as punishment for dying in certain special rounds (like Skull)
					if (is_boss && Ware_CanPlayerRespawn(player))
					{
						player.ForceRespawn()
						// safety check
						if (player.IsAlive())
							valid_players.append(player)	
					}
				}
				else
				{
					valid_players.append(player)
				}
			}
		}
		return valid_players
	}
}

// Finds a player whose name contains the given string
function Ware_FindPlayerByName(name)
{
	local name_lower = name.tolower()
	foreach (player in Ware_Players)
	{
		if (GetPlayerName(player).tolower().find(name_lower) != null)
			return player
	}
	return null
}

// Returns true if there is atleast one red and one blue player
function Ware_ArePlayersOnBothTeams()
{
	local red = false
	local blue = false
	foreach (player in Ware_Players)
	{
		local team = player.GetTeam()
		if (team == TF_TEAM_RED)
			red = true
		if (team == TF_TEAM_BLUE)
			blue = true
		if (red && blue)
			return true
	}
	return false
}

// Gets a list of players in a minigame sorted by their score
function Ware_GetSortedScorePlayers(reverse)
{
	local players = clone(Ware_MinigamePlayersData)
	if (reverse)
		players.sort(@(a, b) b.score <=> a.score)
	else
		players.sort(@(a, b) a.score <=> b.score)		
	players = players.map(@(data) data.player)
	return players
}

// Adds an attribute to the player
// Given attributes are removed automatically when the minigame ends
function Ware_AddPlayerAttribute(player, name, value, duration)
{
	if (name == "voice pitch scale" && Ware_SpecialRound && Ware_SpecialRound.pitch_override >= 0)
	{
		Ware_UpdatePlayerVoicePitch(player)
	}
	else
	{
		player.AddCustomAttribute(name, value, duration)
		player.GetScriptScope().ware_data.attributes[name] <- value
	}
}

// Removes an attribute from the player
function Ware_RemovePlayerAttribute(player, name)
{
	Ware_RemovePlayerAttributeInternal(player, name)
	local ware_data = player.GetScriptScope().ware_data
	if (name in ware_data.attributes)
		delete ware_data.attributes[name]
}

// Adds an attribute to all players
// See Ware_AddPlayerAttribute
function Ware_SetGlobalAttribute(name, value, duration)
{
	foreach (player in Ware_MinigamePlayers)
		Ware_AddPlayerAttribute(player, name, value, duration)
}

// Sets a condition to all players
// This is removed automatically when a minigame ends
function Ware_SetGlobalCondition(condition)
{
	foreach (player in Ware_MinigamePlayers)
		player.AddCond(condition)
	if (Ware_Minigame.conditions.find(condition) == null)
		Ware_Minigame.conditions.append(condition)
}

// Forces a player to commit suicide (as if they kill binded)
function Ware_SuicidePlayer(player)
{
	player.TakeDamageCustom(player, player, null, Vector(), Vector(), 99999.0, DMG_CLUB|DMG_PREVENT_PHYSICS_FORCE, TF_DMG_CUSTOM_SUICIDE)
}

// Force all players that haven't passed the minigame to suicide
function Ware_SuicideFailedPlayers()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsAlive() && !Ware_IsPlayerPassed(player))
			Ware_SuicidePlayer(player)
	}
}

// Damage all players in a radius
// The damage will have linear falloff
function Ware_RadiusDamagePlayers(origin, radius, damage, attacker)
{
	foreach (player in Ware_MinigamePlayers)
	{
		local dist = VectorDistance(player.GetOrigin(), origin)
		if (dist > radius)
			continue
			
		dist += DIST_EPSILON // prevent divide by zero
		local falloff = 1.0 - dist / radius
		if (falloff <= 0.0)
			continue
			
		player.TakeDamage(damage * falloff, DMG_BLAST, attacker)
	}	
}

// Teleports a player to the given origin, angles and/or velocity
// The 3 parameters are optional and can be set to null to not change that property
// Special rounds may override the roll (z) angle
function Ware_TeleportPlayer(player, origin, angles, velocity)
{
	local has_origin = true, has_angles = true, has_velocity = true
	
	if (origin == null)
	{
		has_origin = false
		origin = vec3_zero
	}
	else
	{
		// potential fix for players not getting teleported
		SetPropVector(player, "m_oldOrigin", origin)
	}
	
	if (angles == null)
	{
		has_angles = false
		angles = ang_zero
	}
	if (velocity == null)
	{
		has_velocity = false
		velocity = vec3_zero
	}
	
	if (Ware_SpecialRound && Ware_SpecialRound.cb_get_player_roll.IsValid())
		angles = QAngle(angles.x, angles.y, Ware_SpecialRound.cb_get_player_roll(player))
		
	player.Teleport(has_origin, origin, has_angles, angles, has_velocity, velocity)
}

// Place the given array of players in a circle
function Ware_TeleportPlayersCircle(players, origin, radius)
{
	local inv = 360.0 / players.len().tofloat()
	local i = 0
	foreach (player in players)
	{
		local angle = i++ * inv
		local pos = Vector(
			origin.x + radius * cos(angle * PI / 180.0),
			origin.y + radius * sin(angle * PI / 180.0),
			origin.z)
		local ang = QAngle(0.0, angle + 180.0, 0.0)
		Ware_TeleportPlayer(player, pos, ang, vec3_zero)
	}
}

// Place the given array of players in a rectangular formation
function Ware_TeleportPlayersRow(players, origin, angles, max_width, offset_horz, offset_vert)
{
	// TODO should make this work for non-cardinal axes
	local axis_horz = (angles.y == 0.0 || fabs(angles.y) == 180.0) ? "x" : "y"
	local axis_vert = axis_horz == "x" ? "y" : "x"
	
	local center = origin * 1.0
	local reset = center[axis_vert]
	local accum = 0.0
	foreach (player in players)
	{
		if (accum >= max_width)
		{
			center[axis_vert] = reset
			center[axis_horz] += offset_horz
			accum = 0.0
		}
		
		center[axis_vert] = origin[axis_vert] - max_width * 0.5 + accum
		Ware_TeleportPlayer(player, center, angles, vec3_zero)
		accum += offset_vert
	}	
}

// Gets the player's height above the minigame location
// This will only work if the location has a "center" Vector variable defined
function Ware_GetPlayerHeight(player)
{
	return player.GetOrigin().z - Ware_MinigameLocation.center.z
}

// Disables primary fire for the player's current weapon, for the given duration
function Ware_DisablePlayerPrimaryFire(player, duration = 0.2)
{
	local weapon = player.GetActiveWeapon()
	if (weapon != null)
		SetPropFloat(weapon, "m_flNextPrimaryAttack", Time() + duration)
}

// Gets the player's reserve ammo
function Ware_GetPlayerAmmo(player, ammo_type)
{
	return GetPropIntArray(player, "m_iAmmo", ammo_type)
}

// Sets the player's reserve ammo
function Ware_SetPlayerAmmo(player, ammo_type, ammo)
{
	SetPropIntArray(player, "m_iAmmo", ammo, ammo_type)
}

// Ungrounds a player, allowing them to be knocked back more easily
function Ware_UngroundPlayer(player)
{
	SetPropEntity(player, "m_hGroundEntity", null)
	player.RemoveFlag(FL_ONGROUND)
}

// Pushes a player towards the direction they are looking
// Adds extra vertical velocity
function Ware_PushPlayer(player, scale)
{
	Ware_UngroundPlayer(player)
	
	local dir = player.EyeAngles().Forward()
	dir.x *= scale
	dir.y *= scale
	dir.z *= scale * 2.0
	player.SetAbsVelocity(player.GetAbsVelocity() + dir)
}

// Pushes a player away from another player
// Adds extra vertical velocity
function Ware_PushPlayerFromOther(player, other_player, scale)
{
	Ware_UngroundPlayer(player)
	
	local dir = player.GetOrigin() - other_player.GetOrigin()
	dir.Norm()
	dir.x *= scale
	dir.y *= scale
	dir.z *= scale * 2.0
	player.SetAbsVelocity(player.GetAbsVelocity() + dir)
}

// Shows text on the screen, with the same properties as the game_text entity
// The text will only display as long as the minigame itself
// Text can be reversed by a special round
// If "player" is null, the text is displayed to all players participating in the minigame
function Ware_ShowMinigameText(player, text, color = "255 255 255", x = -1.0, y = 0.3)
{
	if (player == null)
		Ware_ShowText(Ware_MinigamePlayers, CHANNEL_MINIGAME, text, Ware_GetMinigameRemainingTime(), color, x, y)
	else
		Ware_ShowText(player, CHANNEL_MINIGAME, text, Ware_GetMinigameRemainingTime(), color, x, y)
}

// Shows the primary overlay texture on the specified player(s)
// If name is null, it removes the overlay
function Ware_ShowScreenOverlay(players, name)
{
	if (typeof(players) != "array")
		players = [players]
	foreach (player in players)
		player.SetScriptOverlayMaterial(name ? name : "")
}

// Shows the secondary overlay texture on the specified player(s)
// This will also hide the name indicator for players when they are under the crosshair
// (As it shows up in front of the overlay)
// If name is null, it removes the overlay, unless a special round wants to use another it's own
function Ware_ShowScreenOverlay2(players, name)
{
	if (typeof(players) != "array")
		players = [players]
	
	if (!name)
	{
		foreach (player in players)
		{
			player.RemoveHudHideFlags(HIDEHUD_TARGET_ID)
			
			local overlay_name = "off"
			if (Ware_SpecialRound && Ware_SpecialRound.cb_get_overlay2.IsValid())
				overlay_name = Ware_SpecialRound.cb_get_overlay2()
				
			ClientCmd.AcceptInput("Command", format("r_screenoverlay %s", overlay_name), player, null)
		}
	}
	else
	{
		foreach (player in players)
		{
			player.AddHudHideFlags(HIDEHUD_TARGET_ID)
			ClientCmd.AcceptInput("Command", format("r_screenoverlay %s", name), player, null)
		}
	}
}

// Runs a client command on the given player
// If player is null, the command is ran on all playeers
function Ware_RunClientCommand(players, command)
{
	if (typeof(players) != "array")
		players = [players]
		
	local cmd = ClientCmd
	foreach (player in players)
		cmd.AcceptInput("Command", command, player, null)
}