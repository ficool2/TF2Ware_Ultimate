special_round <- Ware_SpecialRoundData
({
	name        = "Double Trouble"
	author      = "ficool2"
	description = "Two special rounds will be stacked together!"
	category    = "meta"
})

scopes <- []

function OnPick()
{
	local desired_count = 2
	
	local player_count = Ware_GetValidPlayers().len()
	
	local categories = clone(Ware_SpecialRoundCategories)
	// don't add ourself!!!!
	delete categories["meta"]
	
	// load in any debug/forced special rounds first
	local debug_len = Ware_DebugNextSpecialRound.len()
	if (debug_len >= desired_count)
	{
		// in case any don't get picked, we'll let the rest be random picked
		desired_count = debug_len
		
		foreach (file_name in Ware_DebugNextSpecialRound)
		{
			// in case someone is silly..
			if (file_name == "double_trouble")
				continue
				
			// intentional random pick
			if (file_name == "any")
				continue
				
			local scope = Ware_LoadSpecialRound(file_name, player_count, false)
			if (scope)
			{
				scopes.append(scope)
				
				// don't random roll conflicting special rounds under the same category
				// note that forcing incompatible categories is intentionally allowed
				local category = scope.special_round.category
				if (category in categories)
				{
					if (category != "none")
					{
						delete categories[category]
					}
					else
					{
						local file_names = categories[category]
						RemoveElementIfFound(file_names, file_name)
						
						// make sure we don't have empty categories
						if (file_names.len() == 0)
							delete categories[category]
					}
				}
			}
		}
	}
	else
	{
		local random = RandomFloat(0.0, 1.0)
		// triple trouble???
		if (random <= 0.333)
			desired_count++
		// quadruple trouble????
		if (random <= 0.1)
			desired_count++
		// ULTRA TROUBLE!!!!
		if (random <= 0.01)
			desired_count++			
	}

	// deep clone as we will remove picks from the list
	foreach (category, file_names in categories)
		categories[category] = clone(file_names)
	
	// fill in the rest of desired special  rounds
	// as some might have rejected the pick earlier
	while (true)
	{
		if (scopes.len() >= desired_count)
			break
			
		if (categories.len() == 0)
			break
			
		local category_pool = []
		// pick random category, weighted towards categories with more items
		// ("none" has a lot of them)
		foreach (category, file_names in categories)
			category_pool.extend(array(file_names.len(), category))
		
		local pick_category = RandomElement(category_pool)
		local file_names = categories[pick_category]
		local file_index = RandomIndex(file_names)
		// don't try pick this again
		local file_name = file_names.remove(file_index)
		
		local scope = Ware_LoadSpecialRound(file_name, player_count, false)
		if (scope)
		{
			scopes.append(scope)
			
			// don't try pick anything else from this category
			if (pick_category != "none" || file_names.len() == 0)
				delete categories[pick_category]	
		}
		else if (file_names.len() == 0)
		{
			delete categories[pick_category]
		}
	}
	
	local scope_len = scopes.len()
	if (scope_len == 3)
	{
		special_round.name        = "Triple Trouble"
		special_round.description = "THREE special rounds will be stacked together!!"
	}
	else if (scope_len == 4)
	{
		special_round.name        = "Quadruple Trouble"
		special_round.description = "QUADRUPLE special rounds will be stacked together!!!"
	}
	else if (scope_len >= 5)
	{
		special_round.name = "ULTRA TROUBLE"
		special_round.description = format("%d special rounds will be stacked together!!!!", scope_len)
	}	
	
	foreach (callback_name, func in delegated_callbacks)
	{
		foreach (scope in scopes)
		{
			if (callback_name in scope)
				this[callback_name] <- func.bindenv(this)
		}
	}
	delete delegated_callbacks
	
	local data = special_round
	foreach (scope in scopes)
	{
		local src = scope.special_round
		
		foreach (name, value in src.convars) 
			data.convars[name] <- value
		
		data.reverse_text      = data.reverse_text      || src.reverse_text
		data.allow_damage      = data.allow_damage      || src.allow_damage
		data.force_collisions  = data.force_collisions  || src.force_collisions
		data.opposite_win      = data.opposite_win      || src.opposite_win
		data.friendly_fire     = data.friendly_fire     && src.friendly_fire
		data.force_pvp_damage  = data.force_pvp_damage  || src.force_pvp_damage
		data.bonus_points      = data.bonus_points      || src.bonus_points
		data.allow_respawnroom = data.allow_respawnroom && src.allow_respawnroom
		
		if (src.boss_count > data.boss_count)        
			data.boss_count = src.boss_count		
		// never extend boss thresholds for slow-mo
		if (src.boss_threshold    != data.boss_threshold && data.boss_threshold >= Ware_BossThreshold)    
			data.boss_threshold    = src.boss_threshold
		if (src.speedup_threshold != data.speedup_threshold) 
			data.speedup_threshold = src.speedup_threshold
		if (src.pitch_override    != data.pitch_override)    
			data.pitch_override    = src.pitch_override	
	}
	
	return true
}

function GetName()
{
	local line = special_round.name + "\n"
	foreach (scope in scopes)
		line += format("-> %s\n", scope.special_round.name)
	return line
}

// called externally
function IsSet(file_name)
{
	foreach (scope in scopes)
	{
		if (scope.special_round.file_name == file_name)
			return true
	}
	
	return false
}

function OnStartInternal() 
{
	foreach (scope in scopes)
	{
		Ware_ChatPrint(null, "{color}{color}{str}{color}! {str}", TF_COLOR_DEFAULT, COLOR_GREEN, scope.special_round.name, 
			TF_COLOR_DEFAULT,  scope.special_round.description)
	}		
}

OnStart <- OnStartInternal // might get overriden below

// call the function only if it exists in that scope
local call_failed
function DelegatedCall(scope, name, ...)
{
	call_failed = false
	if (name in scope)
	{
		vargv.insert(0, scope)
		return scope[name].acall(vargv)
	}
	call_failed = true
}

delegated_callbacks <-
{
	function OnStart()
	{
		OnStartInternal()
		
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnStart")
	}

	function OnUpdate()
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnUpdate")
	}

	function OnEnd()
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnEnd")
	}

	function GetOverlay2()
	{
		foreach (scope in scopes)
		{
			// take first valid result
			local ret = DelegatedCall(scope, "GetOverlay2")
			if (ret != null)
				return ret
		}
	}

	function GetMinigameName(is_boss)
	{
		foreach (scope in scopes)
		{
			// take first valid result
			local ret = DelegatedCall(scope, "GetMinigameName", is_boss)
			if (ret != null)
				return ret
		}
	}

	function OnMinigameStart()
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnMinigameStart")
	}

	function OnMinigameEnd()
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnMinigameEnd")
	}

	function OnMinigameCleanup()
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnMinigameCleanup")
	}

	function GetEndEffects()
	{
		foreach(scope in scopes)
			DelegatedCall(scope, "GetEndEffects")
	}
	
	function OnBeginIntermission(is_boss)
	{
		// return true if either one wants to override logic
		local result = false
		foreach (scope in scopes)
		{
			if (DelegatedCall(scope, "OnBeginIntermission", is_boss))
				result = true
		}
		
		// handle simon special round opposite_win logic
		// start from first scope's value
		local len = scopes.len()
		if (len > 0)
			special_round.opposite_win = scopes[0].special_round.opposite_win
	
		// flip for each additional scope that has it true
		for (local i = 1; i < len; i++) 
		{
			if (scopes[i].special_round.opposite_win)
				special_round.opposite_win = !special_round.opposite_win
		}
		
		return result
	}

	function OnSpeedup()
	{
		local result = false
		foreach (scope in scopes)
		{
			if (DelegatedCall(scope, "OnSpeedup"))
				result = true
		}
		return result
	}
	
	function OnBeginBoss()
	{
		local result = false
		foreach (scope in scopes)
		{
			if (DelegatedCall(scope, "OnBeginBoss"))
				result = true
		}
		return result
	}
	
	function OnCheckGameOver()
	{
		// if either one returns true then it's game over
		local result = false
		foreach (scope in scopes)
		{
			if (DelegatedCall(scope, "OnCheckGameOver"))
				result = true
		}
		return result
	}

	function GetValidPlayers()
	{
		// these cannot overlap so don't run two instances
		foreach (scope in scopes)		
		{
			local ret = DelegatedCall(scope, "GetValidPlayers")	
			if (!call_failed)
				return ret
		}
	}

	function OnCalculateScore(data)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnCalculateScore", data)
			if (!call_failed && ret)
				return ret
		}
		return false
	}

	function OnCalculateTopScorers(top_players)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnCalculateTopScorers", top_players)
			if (!call_failed && ret)
				return ret
		}
		return false
	}

	function OnDeclareWinners(top_players, top_score, winner_count)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnDeclareWinners", top_players, top_score, winner_count)
			if (!call_failed && ret)
				return ret
		}	
		return false
	}

	function OnShowChatText(player, fmt)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnShowChatText", player, fmt)
			if (!call_failed)
				fmt = ret
		}			
		return fmt
	}

	function OnShowGameText(players, channel, text)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnShowGameText", players, channel, text)
			if (!call_failed)
				text = ret
		}			
		return text
	}

	function OnShowOverlay(players, overlay_name)
	{
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnShowOverlay", players, overlay_name)
			if (!call_failed)
				overlay_name = ret
		}			
		return overlay_name
	}

	function OnPlayerConnect(player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerConnect", player)
	}

	function OnPlayerDisconnect(player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerDisconnect", player)
	}

	function OnPlayerSpawn(player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerSpawn", player)
	}
	
	function OnPlayerPostSpawn(player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerPostSpawn", player)
	}

	function OnPlayerInventory(player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerInventory", player)
	}
	
	function OnPlayerVoiceline(player, name)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerVoiceline", player, name)
	}	
	
	function OnPlayerTouch(player, other_player)
	{
		foreach (scope in scopes)		
			DelegatedCall(scope, "OnPlayerTouch", player, other_player)
	}		

	function GetPlayerRoll(player)
	{
		// take first successful call
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "GetPlayerRoll", player)
			if (!call_failed)
				return ret
		}
	}

	function CanPlayerRespawn(player)
	{
		// only respawn if all agree
		// if the function doesn't exist then assume it's allowed
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "CanPlayerRespawn", player)
			if (!call_failed && !ret)
				return false
		}		
		return true
	}

	function OnTakeDamage(params)
	{
		// cancel damage if any one explicitly returns false
		foreach (scope in scopes)
		{
			local ret = DelegatedCall(scope, "OnTakeDamage", params)
			if (!call_failed && ret == false)
				return false
		}
	}
}