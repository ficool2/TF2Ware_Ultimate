
minigame <- Ware_MinigameData
({
	name           = "Escape the Factory"
	author         = ["Gemidyne", "pokemonPasta"]
	description    = "Escape the Factory!"
	duration       = 130.0
	end_delay      = 1.1
	max_scale      = 1.4
	location       = "factory"
	music          = "escape_factory"
	convars =
	{
		tf_avoidteammates = 0
	}
})

endzone <- FindByName(null, "plugin_Bossgame2_WinArea")

function OnStart()
{
	foreach(player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerLoadout(player, TF_CLASS_ENGINEER, null, { "active health degen" : -1.0 })
		Ware_SetPlayerAmmo(player, TF_AMMO_METAL, 0)
	}
	
	endzone.ValidateScriptScope()
	endzone.GetScriptScope().OnStartTouch <- OnEndzoneTouch
	endzone.GetScriptScope().first <- true
	endzone.ConnectOutput("OnStartTouch", "OnStartTouch")
	
	EntFire("ERBoss_InitRelay", "Trigger")
	EntFire("ERBoss_Start", "Trigger")
	
	Ware_CreateTimer(function() 
	{
		Ware_PlayMinigameMusic(null, Ware_Minigame.music)
		return 74.5
	}, 74.5)
}

function OnEndzoneTouch()
{
	local player = activator
	
	if (player.IsPlayer() && player.IsValid() && !Ware_IsPlayerPassed(player))
	{
		local hms = FloatToTimeHMS(Ware_GetMinigameTime())
		if (first)
		{
			Ware_ChatPrint(null, "{player} {color}reached the end first in {%d}:{%02d}!", 
				player, TF_COLOR_DEFAULT, hms.minutes, hms.seconds)
			Ware_GiveBonusPoints(player)
			first = false
		}
		else
		{
			Ware_ChatPrint(player, "{color}You reached the end in {%d}:{%02d}!", 
				TF_COLOR_DEFAULT, hms.minutes, hms.seconds)
		}
		
		Ware_PassPlayer(player, true)
		
		local weapon = player.GetActiveWeapon()
		if (weapon)
			weapon.RemoveAttribute("active health degen")
		
		Ware_CreateTimer(@() Ware_ShowScreenOverlay(player, null), 0.02)	
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.IsPlayer())
	{
		local inflictor = params.inflictor
		if (inflictor && inflictor.GetClassname() == "env_laser")
		{
			// fix weapons being dissolved after respawn
			params.damage_type = params.damage_type & ~(DMG_DISSOLVE)	
			params.damage_stats = TF_DMG_CUSTOM_PLASMA
			params.damage *= 2.0
		}
	}
}

function OnEnd()
{
	endzone.DisconnectOutput("OnStartTouch", "OnStartTouch")
	
	EntFire("ERBoss_Stop", "Trigger")
}

function OnCheckEnd()
{
	return Ware_GetUnpassedPlayers(true).len() == 0
}
