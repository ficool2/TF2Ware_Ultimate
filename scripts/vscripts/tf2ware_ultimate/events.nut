function OnScriptHook_OnTakeDamage(params)
{
	if (params.damage_custom == TF_DMG_CUSTOM_SUICIDE)
		return
	
	if (params.damage_type == DMG_PREVENT_PHYSICS_FORCE
		&& params.const_entity != params.attacker)
	{
		// always allow skull damage
		return
	}
	
	local victim = params.const_entity
	local attacker = params.attacker
	local force_pvp = false
		
	if (Ware_SpecialRound)
	{
		if (Ware_SpecialRound.force_pvp_damage)
			force_pvp = victim.IsPlayer() && attacker && attacker.IsPlayer()
		
		if (Ware_SpecialRound.cb_on_take_damage(params) == false
			&& !force_pvp)
		{
			params.damage = 0
			params.early_out = true
			return
		}
		
		if (params.force_friendly_fire)
			force_pvp = true
	}
	
	if (Ware_Finished)
	{
		if (!force_pvp 
			&& params.inflictor != params.const_entity
			&& Ware_MinigameTopScorers.find(params.const_entity) != null 
			&& Ware_MinigameTopScorers.find(params.inflictor) != null)
		{
			params.damage = 0.0
			params.early_out = true
			return
		}
	}
	
	if (Ware_Minigame == null)
	{
		if (params.damage_type & DMG_FALL)
		{
			params.damage = 0
			params.early_out = true
			return
		}
	}
	
	if (victim == attacker)
	{
		if (params.damage_custom == TF_DMG_CUSTOM_TAUNTATK_GRENADE)
		{
			params.damage = 0
			params.early_out = true
			return
		}
	}
	else
	{
		// handle the case where truce is disabled but don't want damage between players
		if (victim.IsPlayer() && attacker.IsPlayer())
		{
			if (!force_pvp && !Ware_Finished && Ware_Started
				&& (!Ware_Minigame || !Ware_Minigame.allow_damage)
				&& (!Ware_SpecialRound || !Ware_SpecialRound.allow_damage))
			{
				params.damage = 0
				params.early_out = true	
				return
			}
		}
	}

	local same_team = false
	if (victim.IsPlayer()
		&& attacker
		&& attacker != victim
		&& attacker.IsPlayer()
		&& victim.GetTeam() == attacker.GetTeam())
	{
		same_team = true
	}

	local can_friendly_fire = params.force_friendly_fire ||
							((!Ware_Minigame || Ware_Minigame.friendly_fire) 
							&& (!Ware_SpecialRound || Ware_SpecialRound.friendly_fire))
	if (can_friendly_fire)
	{
		params.force_friendly_fire = true
		
		// replicate backstabs for teammates
		local force_backstabs = Ware_Minigame && Ware_Minigame.force_backstab
		if ((same_team || force_backstabs) && attacker && attacker.IsPlayer())
		{
			local weapon = attacker.GetActiveWeapon()
			if (force_backstabs || (weapon && weapon.GetClassname() == "tf_weapon_knife"))
			{
				local to_target = victim.GetCenter() - attacker.GetCenter()
				to_target.z = 0.0
				to_target.Norm()

				local attacker_fwd = attacker.EyeAngles().Forward()
				attacker_fwd.z = 0.0
				attacker_fwd.Norm()

				local victim_fwd = victim.EyeAngles().Forward()
				victim_fwd.z = 0.0
				victim_fwd.Norm()

				if (to_target.Dot(victim_fwd) > 0.0 
					&& to_target.Dot(attacker_fwd) > 0.5 
					&& victim_fwd.Dot(attacker_fwd) > -0.3)
				{
					local viewmodel = GetPropEntity(attacker, "m_hViewModel")
					if (viewmodel)
						viewmodel.ResetSequence(viewmodel.LookupSequence("ACT_MELEE_VM_SWINGHARD"))
					
					if(victim.GetClassname() != "merasmus")
						params.damage       = victim.GetHealth() * 2.0
					params.damage_stats = TF_DMG_CUSTOM_BACKSTAB
					params.damage_type  = params.damage_type | DMG_CRIT
				}			
			}
		}
	}
	else
	{
		if (same_team)
		{
			params.damage = 0
			params.early_out = true
			return
		}
	}
	
	if (Ware_Minigame != null 
		&& Ware_Minigame.cb_on_take_damage(params) == false
		&& !force_pvp)
	{
		params.damage = 0
		params.early_out = true
		return
	}
}

function OnGameEvent_teamplay_round_start(params)
{
	if (Ware_NeedsPlugin)
		return
	
	Ware_SetTimeScale(1.0)
	Ware_SetGlobalPlayerScale(1.0)
	
	Ware_ShowSpecialRoundText(Ware_Players) // clear it out
	
	local cmd = ClientCmd
	foreach (data in Ware_PlayersData)
	{
		local player = data.player
		data.score = 0
		data.bonus = 0
		if (data.start_sound)
			Ware_PlayGameSound(player, "lets_get_started", SND_STOP)
		player.SetScriptOverlayMaterial("")
		cmd.AcceptInput("Command", "r_screenoverlay off", player, null)
		cmd.AcceptInput("Command", "r_cleardecals", player, null)
		BrickPlayerScore(player)
	}
	
	Ware_PlayGameSound(null, "results", SND_STOP)
	
	if (IsInWaitingForPlayers())
	{
		// restart if waiting for players was cancelled early
		CreateTimer(function()
		{
			if (!IsInWaitingForPlayers())
				SetConvarValue("mp_restartgame_immediate", 1)
			else
				return 1.0
		}, 1.0)
		return
	}
	
	// TODO: why is this check here? this event shouldn't fire again midround
	if (Ware_Started)
		return
	Ware_Started = true
	
	// check for next theme. otherwise first round always uses default theme
	if (Ware_DebugNextTheme != "")
	{
		Ware_SetTheme(Ware_DebugNextTheme)
		Ware_DebugNextTheme = ""
	}
	else if (Ware_RoundsPlayed > 0 && Ware_Themes.len() > 1)
	{
		// roll a new one
		local themes = clone(Ware_Themes)
		local idx = themes.find(Ware_Theme)
		if (idx != null)
			themes.remove(idx)

		Ware_Theme = RandomElement(themes)
		Ware_SetupThemeSounds()
	}
	else if (Ware_IsThemeValid(Ware_Theme))
	{
		Ware_SetupThemeSounds()
	}
	else
	{
		Ware_Error("Unexpected theme on round start, setting to default instead.")
		Ware_Theme = Ware_Themes[0]
		Ware_SetupThemeSounds()
	}
	
	Ware_ChatPrint(null, "Theme: {color}{str}", COLOR_LIME, Ware_Theme.visual_name)
	
	Ware_ToggleTruce(true)

	Ware_MinigameRotation.clear()
	Ware_ReloadMinigameRotation(false)
	
	// special rounds always occur every N rounds
	// don't do two special rounds in a row (checks for special round from last round and then clears it, unless it's forced)
	local begin_intermission = true
	
	if (Ware_DebugNextSpecialRound.len() > 0 ||
		Ware_SpecialRoundNext ||
		(!Ware_SpecialRoundPrevious &&
			(Ware_RoundsPlayed + 1) % Ware_SpecialRoundInterval == 0))
	{
		Ware_SpecialRoundNext = false
		if (Ware_BeginSpecialRound())
			begin_intermission = false
	}
	else
	{
		Ware_SpecialRoundPrevious = false
	}
	
	// special rounds decide their own intermission delay
	if (begin_intermission)
		CreateTimer(@() Ware_BeginIntermission(false), 0.0)
}

// called only on mp_restartgame
function OnGameEvent_scorestats_accumulated_reset(params)
{
	// save current timelimit
	Ware_MapResetTimer = GetPropFloat(GameRules, "m_flMapResetTime")
}

// called right before the map is reset for a new round
function OnGameEvent_scorestats_accumulated_update(params)
{
	if (Ware_MapResetTimer != null)
	{
		// restore timelimit
		SetPropFloat(GameRules, "m_flMapResetTime", Ware_MapResetTimer)
		Ware_MapResetTimer = null
	}
	
	if (Ware_Minigame) // when restarted mid-minigame
	{
		if ("OnCleanup" in Ware_MinigameScope) 
			Ware_MinigameScope.OnCleanup()
		
		// ensure parented players aren't deleted
		foreach (player in Ware_Players)
		{
			if (player.GetMoveParent())
				SetEntityParent(player, null)
		}
		
		foreach (data in Ware_MinigamePlayersData)
		{
			local player = data.player
			if (!player.IsValid())
				continue
				
			if (data.saved_team != null)
			{
				Ware_SetPlayerTeamInternal(player, data.saved_team)
				data.saved_team = null
			}		
		}
		
		foreach (name, value in Ware_MinigameSavedConvars)
			SetConvarValue(name, value)
		Ware_MinigameSavedConvars.clear()
		
		ClearGameEventsFromScope(Ware_MinigameScope, Ware_MinigameEvents)
		
		if (Ware_Minigame.music)
			Ware_PlayMinigameMusic(null, Ware_Minigame.music, SND_STOP)
	}

	if (Ware_SpecialRound) // same as above
	{
		Ware_EndSpecialRound()
		Ware_PlayGameSound(null, "special_round", SND_STOP)
	}
}

function OnGameEvent_recalculate_truce(params)
{
	if (!Ware_Started)
		return

	// minigames can spawn bosses like merasmus which will revert truce to false after its over
	if (Ware_Minigame)
	{
		if (!Ware_Minigame.allow_damage)
			Ware_ToggleTruce(true)
	}
	else
	{
		Ware_ToggleTruce(true)
	}
}

::Ware_PlayerInitWrapper <- function()
{
	Ware_PlayerInit(self)
}

::Ware_PlayerPostSpawn <- function()
{
	Ware_UpdatePlayerVoicePitch(self)
	
	if (self.IsBotOfType(TF_BOT_TYPE))
		Ware_BotSetup(self)

	local melee = ware_data.special_melee
	if (melee == null)
		melee = ware_data.melee
	
	if (melee && !melee.IsValid())
		melee = null
	
	if (melee != null)
	{
		// TODO: is this code even needed now that loadout cacher is removed?
		// not sure why this is needed
		melee.SetModel(TF_CLASS_ARMS[self.GetPlayerClass()])	
		
		melee = Ware_ForceSwitchPlayerMelee(self, melee)
		if (melee)
		{
			melee.EnableDraw()
			
			// hack: something is not clearing the render color
			// last minute for the playtest
			SetPropInt(melee, "m_clrRender", 0xFFFFFFFF)
		}
	}
	else
	{
		melee = Ware_ForceSwitchPlayerMelee(self, null)
	}
	
	if (Ware_SpecialRound && Ware_SpecialRound.cb_on_player_postspawn.IsValid())
		Ware_SpecialRound.cb_on_player_postspawn(self)	
}

function OnGameEvent_player_spawn(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	if (params.team == TEAM_UNASSIGNED)
	{
		if (player.IsBotOfType(TF_BOT_TYPE))
		{
			Ware_PlayerInit(player)
		}
		else
		{
			// delay this to end of frame as SourceTV won't be registered here yet
			EntityEntFire(player, "CallScriptFunction", "Ware_PlayerInitWrapper", 0.0)
		}
		return
	}
	
	local data = player.GetScriptScope().ware_data

	// this is to fix persisting attributes if restarting mid-minigame
	local melee = data.melee
	if (melee && melee.IsValid())
	{
		foreach (attribute, value in data.melee_attributes)
			melee.RemoveAttribute(attribute)
	}
	data.attributes.clear()
	data.melee_attributes.clear()
	
	if (params.team & TF_TEAM_MASK)
	{
		data.spawn_time = Time()
		data.lerp_time = GetPropFloat(player, "m_fLerpTime")
		
		if (Ware_MinigameTopScorers.find(player) != null)
			player.AddCond(TF_COND_TELEPORTED)
		
		if (!data.start_sound)
			EntityEntFire(player, "CallScriptFunction", "Ware_PlayStartSound", 1.0)
		
		local melee = Ware_ParseLoadout(player)		
		if (melee && !Ware_Finished)
			Ware_ModifyMeleeAttributes(melee)
			
		EntityEntFire(player, "CallScriptFunction", "Ware_PlayerPostSpawn")
		
		player.AddHudHideFlags(HIDEHUD_BUILDING_STATUS|HIDEHUD_CLOAK_AND_FEIGN|HIDEHUD_PIPES_AND_CHARGE)
		player.SetCustomModel("")		
		player.SetHealth(player.GetMaxHealth())	
		player.SetCollisionGroup(COLLISION_GROUP_PUSHAWAY);
		SetPropInt(player, "m_clrRender", 0xFFFFFFFF)
		
		if (Ware_SpecialRound)
		{
			if (Ware_SpecialRound.cb_get_player_roll.IsValid())
			{
				local eye_angles = player.EyeAngles()
				eye_angles.z = Ware_SpecialRound.cb_get_player_roll(player)
				player.SnapEyeAngles(eye_angles)
			}
			
			Ware_SpecialRound.cb_on_player_spawn(player)
		}
	}
}

function OnGameEvent_post_inventory_application(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player == null)
		return
	
	if (Ware_Minigame != null)
		Ware_Minigame.cb_on_player_inventory(player)
		
	if (Ware_SpecialRound)
		Ware_SpecialRound.cb_on_player_inventory(player)
}

function OnGameEvent_player_initial_spawn(params)
{
	local player = PlayerInstanceFromIndex(params.index)
	if (player == null)
		return
	
	BrickPlayerScore(player)
}

function OnGameEvent_player_changeclass(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (player && !player.IsAlive() && !IsInWaitingForPlayers())
		SetPropFloat(player, "m_flDeathTime", Time()) // no late respawns
}

::Ware_PlayerPostDeath <- function()
{
	self.AddHudHideFlags(HIDEHUD_BUILDING_STATUS|HIDEHUD_CLOAK_AND_FEIGN|HIDEHUD_PIPES_AND_CHARGE)
}

function OnGameEvent_player_death(params)
{
	if (params.death_flags & TF_DEATH_FEIGN_DEATH)
		return
	
	RemoveAllOfEntity("tf_ammo_pack")
	RemoveAllOfEntity("halloween_souls_pack")
		
	local player = GetPlayerFromUserID(params.userid)
	if (player)
		EntityEntFire(player, "CallScriptFunction", "Ware_PlayerPostDeath")
	
	if (Ware_Minigame == null)
		return
		
	if (params.customkill == TF_DMG_CUSTOM_SUICIDE)
	{
		// kill-binds have these bits
		if (params.damagebits & (DMG_ALWAYSGIB|DMG_NEVERGIB))
			player.GetScriptScope().ware_data.suicided = true
	}
		
	if (Ware_Minigame.fail_on_death == true)
	{
		if (player)
			Ware_PassPlayer(player, false)
	}
	
	Ware_Minigame.cb_on_player_death(player, GetPlayerFromUserID(params.attacker), params)
}

function OnGameEvent_player_disconnect(params)
{
	local player = GetPlayerFromUserID(params.userid)
	if (!player)
		return
		
	local data = player.GetScriptScope().ware_data
	local idx = Ware_MinigamePlayers.find(player)
	if (idx != null)
		Ware_MinigamePlayers.remove(idx)
		
	idx = Ware_MinigamePlayersData.find(data)
	if (idx != null)
		Ware_MinigamePlayersData.remove(idx)
		
	idx = Ware_Players.find(player)
	if (idx != null)
	{
		Ware_Players.remove(idx)
		Ware_PlayersData.remove(idx)
	}
	
	if (player.IsBotOfType(TF_BOT_TYPE))
	{
		Ware_BotDestroy(player)
		
		idx = Ware_Bots.find(player)
		if (idx != null)
			Ware_Bots.remove(idx)
	}
		
	if (Ware_Minigame == null)
		return
	
	Ware_Minigame.cb_on_player_disconnect(player)
	if (Ware_SpecialRound)
		Ware_SpecialRound.cb_on_player_disconnect(player)
}

function OnGameEvent_teamplay_game_over(params)
{
	// map end
	KillTimer(Ware_RoundEndMusicTimer)
	Ware_PlayGameSound(null, "results", SND_STOP)
	Ware_PlayGameSound(null, "mapend")
}

if (!Ware_Plugin) // plugin calls Ware_PlayerSay directly
{
	function OnGameEvent_player_say(params)
	{	
		local player = GetPlayerFromUserID(params.userid)
		local text = params.text
		Ware_OnPlayerSay(player, text)
	}
}