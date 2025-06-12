special_round <- Ware_SpecialRoundData
({
	name = "Double Trouble"
	author = "ficool2"
	description = "Two special rounds will be stacked together!"
	category = "meta"
})

scope_a <- null
scope_b <- null

function OnPick()
{
	local categories = clone(Ware_SpecialRoundCategories)
	// don't include ourself...
	if ("meta" in categories)
		delete categories.meta
		
	local special_rounds = []
	if (Ware_DebugNextSpecialRound2.len() == 0)
	{
		foreach (category, file_names in categories)
		{
			foreach (file_name in file_names)
				special_rounds.append({category = category, file_name = file_name})
		}
	}
	else
	{
		special_rounds.append({category = "none", file_name = Ware_DebugNextSpecialRound2[0]})
		special_rounds.append({category = "none", file_name = Ware_DebugNextSpecialRound2[1]})
		Ware_DebugNextSpecialRound2.clear()
	}

	local pick_a, pick_b

	local player_count = Ware_GetValidPlayers().len()
	local max_count = Min(16, special_rounds.len())
	for (local i = 0; i <  max_count; i++)
	{
		pick_a = RemoveRandomElement(special_rounds)
		local scope = Ware_LoadSpecialRound(pick_a.file_name, player_count, false)
		if (scope)
		{
			scope_a = scope
			break
		}
	}
	
	if (!scope_a)
		return false
		
	max_count = Min(32, special_rounds.len())
	for (local i = 0; i < max_count; i++)
	{
		pick_b = RemoveRandomElement(special_rounds)
		if (pick_b.category != "none" && pick_b.category == pick_a.category)
			continue
		
		local scope = Ware_LoadSpecialRound(pick_b.file_name, player_count, false)
		if (scope)
		{
			scope_b = scope
			break
		}
	}
	
	if (!scope_b)
		return false
		
	foreach (callback_name, func in delegated_callbacks)
	{
		if (callback_name in scope_a || callback_name in scope_b)
			this[callback_name] <- func.bindenv(this)
	}
	delete delegated_callbacks
	
	local data = special_round
	local data_a = scope_a.special_round
	local data_b = scope_b.special_round
	
	foreach (name, value in data_a.convars) data.convars[name] <- value
	foreach (name, value in data_b.convars) data.convars[name] <- value
	data.reverse_text      = data_a.reverse_text || data_b.reverse_text
	data.allow_damage      = data_a.allow_damage || data_b.allow_damage
	data.force_collisions  = data_a.force_collisions || data_b.force_collisions
	data.opposite_win      = data_a.opposite_win || data_b.opposite_win
	data.friendly_fire     = data_a.friendly_fire && data_b.friendly_fire
	data.force_pvp_damage  = data_a.force_pvp_damage || data_b.force_pvp_damage
	data.bonus_points      = data_a.bonus_points || data_b.bonus_points
	data.allow_respawnroom = data_a.allow_respawnroom && data_b.allow_respawnroom
	// choose whichever one has non-default value
	data.boss_count        = data_a.boss_threshold != data.boss_count ? data_a.boss_count : data_b.boss_count
	data.boss_threshold    = data_a.boss_threshold != data.boss_threshold ? data_a.boss_threshold : data_b.boss_threshold
	data.speedup_threshold = data_a.speedup_threshold != data.speedup_threshold ? data_a.speedup_threshold : data_b.speedup_threshold
	data.pitch_override    = data_a.pitch_override != data.pitch_override ? data_a.pitch_override : data_b.pitch_override
	
	return true
}

function GetName()
{
	return format("%s\n-> %s\n-> %s\n", 
		special_round.name, 
		scope_a.special_round.name
		scope_b.special_round.name)	
}

// called externally
function IsSet(file_name)
{
	return file_name == scope_a.special_round.file_name || file_name == scope_b.special_round.file_name
}

function OnStartInternal() 
{
	Ware_ChatPrint(null, "{color}{color}{str}{color}! {str}", TF_COLOR_DEFAULT, COLOR_GREEN, scope_a.special_round.name, 
		TF_COLOR_DEFAULT,  scope_a.special_round.description)
	Ware_ChatPrint(null, "{color}{color}{str}{color}! {str}", TF_COLOR_DEFAULT, COLOR_GREEN, scope_b.special_round.name, 
		TF_COLOR_DEFAULT, scope_b.special_round.description)	
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
		
		DelegatedCall(scope_a, "OnStart")
		DelegatedCall(scope_b, "OnStart")
	}

	function OnUpdate()
	{
		DelegatedCall(scope_a, "OnUpdate")
		DelegatedCall(scope_b, "OnUpdate")
	}

	function OnEnd()
	{
		DelegatedCall(scope_a, "OnEnd")
		DelegatedCall(scope_b, "OnEnd")
	}

	function GetOverlay2()
	{
		// take first valid result
		local ret = DelegatedCall(scope_a, "GetOverlay2")
		if (ret == null)
			ret = DelegatedCall(scope_b, "GetOverlay2")	
		return ret
	}

	function GetMinigameName(is_boss)
	{
		local ret = DelegatedCall(scope_a, "GetMinigameName", is_boss)
		if (ret == null)
			ret = DelegatedCall(scope_b, "GetMinigameName", is_boss)	
		return ret
	}

	function OnMinigameStart()
	{
		DelegatedCall(scope_a, "OnMinigameStart")
		DelegatedCall(scope_b, "OnMinigameStart")
	}

	function OnMinigameEnd()
	{
		DelegatedCall(scope_a, "OnMinigameEnd")
		DelegatedCall(scope_b, "OnMinigameEnd")
	}

	function OnMinigameCleanup()
	{
		DelegatedCall(scope_a, "OnMinigameCleanup")
		DelegatedCall(scope_b, "OnMinigameCleanup")
	}

	function OnBeginIntermission(is_boss)
	{
		// return true if either one wants to override logic
		local ret_a = DelegatedCall(scope_a, "OnBeginIntermission", is_boss)
		local ret_b = DelegatedCall(scope_b, "OnBeginIntermission", is_boss) 
		
		// for simon special round
		special_round.opposite_win = scope_a.special_round.opposite_win
		if (scope_b.special_round.opposite_win)
			special_round.opposite_win = !special_round.opposite_win 
		
		return ret_a || ret_b
	}

	function OnSpeedup()
	{
		local ret_a = DelegatedCall(scope_a, "OnSpeedup")
		local ret_b = DelegatedCall(scope_b, "OnSpeedup")
		return ret_a || ret_b
	}
	
	function OnBeginBoss()
	{
		local ret_a = DelegatedCall(scope_a, "OnBeginBoss")
		local ret_b = DelegatedCall(scope_b, "OnBeginBoss") 
		return ret_a || ret_b
	}
	
	function OnCheckGameOver()
	{
		// if either one returns true then it's game over
		local ret_a = DelegatedCall(scope_a, "OnCheckGameOver")
		local ret_b = DelegatedCall(scope_b, "OnCheckGameOver") 
		return ret_a || ret_b
	}

	function GetValidPlayers()
	{
		// these cannot overlap so don't run two instances
		local ret = DelegatedCall(scope_a, "GetValidPlayers")
		if (call_failed)
			ret = DelegatedCall(scope_b, "GetValidPlayers")	
		return ret
	}

	function OnCalculateScore(data)
	{
		local ret = DelegatedCall(scope_a, "OnCalculateScore", data)
		if (call_failed || ret == false)
			ret = DelegatedCall(scope_b, "OnCalculateScore", data)	
		if (call_failed)
			ret = false
		return ret
	}

	function OnCalculateTopScorers(top_players)
	{
		local ret = DelegatedCall(scope_a, "OnCalculateTopScorers", top_players)
		if (call_failed || ret == false)
			ret = DelegatedCall(scope_b, "OnCalculateTopScorers", top_players)	
		if (call_failed)
			ret = false	
		return ret
	}

	function OnDeclareWinners(top_players, top_score, winner_count)
	{
		local ret = DelegatedCall(scope_a, "OnDeclareWinners", top_players, top_score, winner_count)
		if (call_failed || ret == false)
			ret = DelegatedCall(scope_b, "OnDeclareWinners", top_players, top_score, winner_count)	
		if (call_failed)
			ret = false	
		return ret
	}

	function OnShowChatText(player, fmt)
	{
		local ret = DelegatedCall(scope_a, "OnShowChatText", player, fmt)
		if (!call_failed)
			fmt = ret
		
		ret = DelegatedCall(scope_a, "OnShowChatText", player, fmt)
		if (!call_failed)
			fmt = ret
		
		return fmt
	}

	function OnShowGameText(players, channel, text)
	{
		local ret = DelegatedCall(scope_a, "OnShowGameText", players, channel, text)
		if (!call_failed)
			text = ret
		
		ret = DelegatedCall(scope_b, "OnShowGameText", players, channel, text)
		if (!call_failed)
			text = ret
		
		return text
	}

	function OnShowOverlay(players, overlay_name)
	{
		local ret = DelegatedCall(scope_a, "OnShowOverlay", players, overlay_name)
		if (!call_failed)
			overlay_name = ret
		
		ret = DelegatedCall(scope_b, "OnShowOverlay", players, overlay_name)
		if (!call_failed)
			overlay_name = ret
		
		return overlay_name
	}

	function OnPlayerConnect(player)
	{
		DelegatedCall(scope_a, "OnPlayerConnect", player)
		DelegatedCall(scope_b, "OnPlayerConnect", player)
	}

	function OnPlayerDisconnect(player)
	{
		DelegatedCall(scope_a, "OnPlayerDisconnect", player)
		DelegatedCall(scope_b, "OnPlayerDisconnect", player)
	}

	function OnPlayerSpawn(player)
	{
		DelegatedCall(scope_a, "OnPlayerSpawn", player)
		DelegatedCall(scope_b, "OnPlayerSpawn", player)
	}
	
	function OnPlayerPostSpawn(player)
	{
		DelegatedCall(scope_a, "OnPlayerPostSpawn", player)
		DelegatedCall(scope_b, "OnPlayerPostSpawn", player)
	}

	function OnPlayerInventory(player)
	{
		DelegatedCall(scope_a, "OnPlayerInventory", player)
		DelegatedCall(scope_b, "OnPlayerInventory", player)
	}
	
	function OnPlayerVoiceline(player, name)
	{
		DelegatedCall(scope_a, "OnPlayerVoiceline", player, name)
		DelegatedCall(scope_b, "OnPlayerVoiceline", player, name)
	}	
	
	function OnPlayerTouch(player, other_player)
	{
		DelegatedCall(scope_a, "OnPlayerTouch", player, other_player)
		DelegatedCall(scope_b, "OnPlayerTouch", player, other_player)
	}		

	function GetPlayerRoll(player)
	{
		// take first successful call
		local ret = DelegatedCall(scope_a, "GetPlayerRoll", player)
		if (call_failed)
			ret = DelegatedCall(scope_b, "GetPlayerRoll", player)	
		return ret
	}

	function CanPlayerRespawn(player)
	{
		// only respawn if both agree
		// if the function doesn't exist then assume it's allowed
		local ret_a = DelegatedCall(scope_a, "CanPlayerRespawn", player)
		if (call_failed)
			ret_a = true
		local ret_b = DelegatedCall(scope_b, "CanPlayerRespawn", player)	
		if (call_failed)
			ret_b = true		
		return ret_a && ret_b
	}

	function OnTakeDamage(params)
	{
		// cancel damage if either one explicitly returns false
		local ret_a = DelegatedCall(scope_a, "OnTakeDamage", params)
		local ret_b = DelegatedCall(scope_b, "OnTakeDamage", params)
		if (ret_a == false || ret_b == false)
			return false
	}
}