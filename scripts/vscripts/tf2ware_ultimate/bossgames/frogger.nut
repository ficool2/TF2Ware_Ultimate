minigame <- Ware_MinigameData
({
	name           = "Frogger"
	author         = ["Mecha the Slag", "ficool2"]
	description    = "Get to the end!"
	duration       = 95.0
	end_delay      = 1.0
	max_scale      = 1.0
	location       = "frogger"
	music          = "frogger"
	custom_overlay = "get_end"
	start_pass     = false
	thirdperson    = true
})

first <- true

planks <- []

frog_model <- "models/tf2ware_ultimate/frog.mdl"
jump_sound <- "TF2Ware_Ultimate.FroggerHop"
death_sound <- "TF2Ware_Ultimate.FroggerSquash"

function OnPrecache()
{
	PrecacheModel(frog_model)
	PrecacheScriptSound(jump_sound)
	PrecacheScriptSound(death_sound)
}

function OnStart()
{
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_AddPlayerAttribute(player, "no_attack", 1, -1)
		Ware_AddPlayerAttribute(player, "no double jump", 1, -1)
		Ware_AddPlayerAttribute(player, "increased jump height", 0.6, -1)
		Ware_GetPlayerMiniData(player).jumping <- false
		Ware_TogglePlayerWearables(player, false)
		player.SetCustomModelWithClassAnimations(frog_model)
		
		// show hats
		for (local wearable = player.FirstMoveChild(); wearable; wearable = wearable.NextMovePeer())
		{
			if (IsWearableHat(wearable))
				Ware_ToggleWearable(wearable, true)
		}
	}
		
	local timer = Ware_SpawnEntity("team_round_timer",
	{
		timer_length   = minigame.duration - 5.0,
		auto_countdown = true,
		show_in_hud    = true,
		show_time_remaining = true,
		setup_length   = 6,
	})
	EntityAcceptInput(timer, "Resume")

	// no i dont know why these are named like that
	local door2 = FindByName(null, "frogger_door2")
	local door3 = FindByName(null, "frogger_door3")

	foreach(door in [door2, door3])
	{
		door.ValidateScriptScope()

		door.GetScriptScope().OnClose <- OnBoxClose
		door.ConnectOutput("OnClose", "OnClose")

		door.GetScriptScope().OnOpen <- OnBoxOpen
		door.ConnectOutput("OnOpen", "OnOpen")
	}
	door2.GetScriptScope().hurt <- FindByName(null, "frogger_hurt2")
	door3.GetScriptScope().hurt <- FindByName(null, "frogger_hurt3")

	Ware_CreateTimer(@() OpenDoors(), 6.0)
	SetupMap()
}

function SetupMap()
{
	planks.clear()
	
	local plank_names = ["a", "b", "c"]
	foreach (name in plank_names)
	{
		local remove_count = RandomInt(0, 2)
		local speed = RandomFloat(100.0, 550.0)
		local targetname = "frogger_logs_" + name + "*"
		for (local plank; plank = FindByName(plank, targetname);)
		{
			MarkForPurge(plank)
			if (plank.GetClassname() != "func_tracktrain")
				continue
				
			if (remove_count > 0 && RandomInt(0, 2) == 0)
			{
				plank.AddSolidFlags(FSOLID_NOT_SOLID)
				
				local prop = plank.FirstMoveChild()
				if (prop)
				{
					prop.DisableDraw()
					MarkForPurge(prop)
				}
				
				remove_count--
			}
				
			plank.KeyValueFromFloat("startspeed", speed)
			EntityAcceptInput(plank, "StartForward")
			
			planks.append(plank)
		}	
	}	
	
	for (local sawblade; sawblade = FindByName(sawblade, "frogger_saw_linear_*");)
	{
		sawblade.KeyValueFromFloat("speed", RandomFloat(150.0, 250.0))
		EntityAcceptInput(sawblade, "Open")
		MarkForPurge(sawblade)
	}	
	
	EntFire("frogger_Train1_*", "StartForward")
	EntFire("frogger_Train2_*", "StartForward")
	EntFire("frogger_Train3_*", "StartForward")

	EntFire("frogger_door2", "Unlock")
	EntFire("frogger_door3", "Unlock")
	EntFire("frogger_door5", "Unlock")
	EntFire("frogger_door2", "Open")
	EntFire("frogger_door3", "Open")
	EntFire("frogger_door5", "Open")
	
	local spike_timer = FindByName(null, "frogger_spike_timer")
	spike_timer.KeyValueFromFloat("RefireTime", RandomFloat(1.0, 5.0))
	EntityAcceptInput(spike_timer, "Enable")
	MarkForPurge(spike_timer)

	local box1 = FindByName(null, "frogger_door2")
	local box2 = FindByName(null, "frogger_door3")
	EntityOutputs.AddOutput(box1, "OnFullyClosed", "!self", "SetSpeed", "80", 0.0, -1)
	EntityOutputs.AddOutput(box1, "OnFullyOpen", "!self", "SetSpeed", "500", 0.0, -1)
	EntityOutputs.AddOutput(box2, "OnFullyClosed", "!self", "SetSpeed", "100", 0.0, -1)
	EntityOutputs.AddOutput(box2, "OnFullyOpen", "!self", "SetSpeed", "500", 0.0, -1)
	MarkForPurge(box1)
	MarkForPurge(box2)
}

function CleanupMap()
{
	foreach (plank in planks)
	{
		if (plank.IsValid())
		{
			plank.RemoveSolidFlags(FSOLID_NOT_SOLID)
			local prop = plank.FirstMoveChild()
			if (prop)
				prop.EnableDraw()
		}
	}
	
	EntFire("frogger_start_door", "Close")
	EntFire("frogger_start_door_*", "Close")
	
	EntFire("frogger_logs_*", "Stop")
	EntFire("frogger_Train1_*", "Stop")
	EntFire("frogger_Train2_*", "Stop")
	EntFire("frogger_Train3_*", "Stop")
	
	EntFire("frogger_spike_timer", "Disable")
	
	EntFire("frogger_saw_linear_*", "SetSpeed", "0")
	
	EntFire("frogger_door2", "Close")
	EntFire("frogger_door3", "Close")
	EntFire("frogger_door5", "Close")
	EntFire("frogger_door2", "Lock")
	EntFire("frogger_door3", "Lock")
	EntFire("frogger_door5", "Lock")
	
	local box1 = FindByName(null, "frogger_door2")
	local box2 = FindByName(null, "frogger_door3")
	EntityOutputs.RemoveOutput(box1, "OnFullyClosed", "!self", "SetSpeed", "80")
	EntityOutputs.RemoveOutput(box1, "OnFullyOpen", "!self", "SetSpeed", "500")
	EntityOutputs.RemoveOutput(box2, "OnFullyClosed", "!self", "SetSpeed", "100")
	EntityOutputs.RemoveOutput(box2, "OnFullyOpen", "!self", "SetSpeed", "500")
}

function OpenDoors()
{
	EntFire("frogger_start_door", "Open")
	EntFire("frogger_start_door_" + RandomInt(0, 2), "Open")
}

function OnPlayerDeath(player, attacker, params)
{
	player.EmitSound(death_sound)
}

function OnUpdate()
{
	local threshold = Ware_MinigameLocation.center.y + 7150.0
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		
		local jumping = GetPropBool(player, "m_Shared.m_bJumping")
		if (jumping && !minidata.jumping)
			player.EmitSound(jump_sound)
		minidata.jumping = jumping
		
		SetPropFloat(player, "m_flMaxspeed", 300.0)
		
		if (player.IsAlive() && player.GetOrigin().y > threshold)
		{
			Ware_PassPlayer(player, true)
			
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}made it to the goal first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
	}
}

function OnBoxClose()
{
	EntityAcceptInput(hurt, "Enable")
}

function OnBoxOpen()
{
	EntityAcceptInput(hurt, "Disable")
}

function OnEnd()
{
	CleanupMap()
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
	{
		Ware_TogglePlayerWearables(player, true)
		player.SetCustomModel("")
	}
}

function OnCheckEnd()
{
	return Ware_GetPassedPlayers(false, true).len() == 0
}