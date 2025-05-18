minigame <- Ware_MinigameData
({
	name          = "Kart Race"
	author        = ["TonyBaretta", "pokemonPasta"]
	music         = "moomoofarm"
	description   = "Race to the End!"
	end_delay     = 0.5
	start_freeze  = 0.5
	allow_damage  = true
	collisions    = true
	max_scale     = 1.5
})

tracks <-
[  // location          endzone vectors              duration
	["kart_containers", Vector(-1250, 4450, -5960),  22.0],
	["kart_paths",      Vector(-7000, 9850, -6047),  26.5],
	["kart_ramp",       Vector(-8000, -6475, -6527), 10.0],
]

mode <- RandomInt(0, 2)
if (Ware_Players.len() > 40)
	mode = 0

first <- mode != 2

minigame.location    = tracks[mode][0]
endzone_vector      <- tracks[mode][1]
minigame.duration    = tracks[mode][2]

function OnPrecache()
{
	for (local i = 1; i <= 3; i++)
		PrecacheSound(format("vo/announcer_begins_%dsec.mp3", i))
	
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/kart")
}

function OnStart()
{
	for (local ent; ent = FindByClassname(ent, "trigger_push");)
	{
		ent.ValidateScriptScope()
		ent.GetScriptScope().OnStartTouch <- OnTriggerStartTouch
		ent.GetScriptScope().OnEndTouch <- OnTriggerEndTouch
		ent.ConnectOutput("OnStartTouch", "OnStartTouch")
		ent.ConnectOutput("OnEndTouch", "OnEndTouch")
	}
	
	// put everyone in karts and freeze them
	foreach (player in Ware_MinigamePlayers)
	{
		player.AddCond(TF_COND_HALLOWEEN_KART)
		player.AddCond(TF_COND_HALLOWEEN_KART_CAGE)
	}
	
	// start a countdown
	local timer = 3
	Ware_CreateTimer(function()
	{
		Ware_ShowScreenOverlay(Ware_MinigamePlayers, format("hud/tf2ware_ultimate/countdown_%d", timer))
		if (timer > 0)
			Ware_PlaySoundOnAllClients(format("vo/announcer_begins_%dsec.mp3", timer), 1.0, 100 * Ware_GetPitchFactor())
		
		timer--
		
		if (timer >= 0)
			return 1.0
		else
		{
			// when hits 0, unfreeze players
			foreach (player in Ware_MinigamePlayers)
				player.RemoveCond(TF_COND_HALLOWEEN_KART_CAGE)
			Ware_ShowScreenOverlay(Ware_MinigamePlayers, "hud/tf2ware_ultimate/minigames/kart")
		}
	}, 0.0)
}

function OnTriggerStartTouch()
{
	if (activator && activator.IsPlayer())
	{
		activator.AddCond(TF_COND_HALLOWEEN_KART_DASH)
	}
}

function OnTriggerEndTouch()
{
	if (activator && activator.IsPlayer())
	{
		local vel = activator.GetAbsVelocity()
		vel.z = Clamp(vel.z, 150, 1000)
		activator.SetAbsVelocity(vel)
	}
}

function OnUpdate()
{
	foreach (player in Ware_MinigamePlayers)
	{
		if (player.IsAlive() &&
			player.GetOrigin().x > endzone_vector.x &&
			player.GetOrigin().y > endzone_vector.y &&
			player.GetOrigin().z > endzone_vector.z)
		{
			Ware_PassPlayer(player, true)
			
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}finished the race first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}			
		}
	}
}

function OnEnd()
{
	for (local ent; ent = FindByClassname(ent, "trigger_push");)
	{
		ent.DisconnectOutput("OnStartTouch", "OnStartTouch")
		ent.DisconnectOutput("OnEndTouch", "OnEndTouch")
	}
	
	foreach(player in Ware_MinigamePlayers)
		player.RemoveCond(TF_COND_HALLOWEEN_KART_DASH)
}

function OnCheckEnd()
{
    return Ware_GetAlivePlayers().len() == 0
}

function OnCleanup()
{
	foreach (player in Ware_MinigamePlayers)
		player.RemoveCond(TF_COND_HALLOWEEN_KART)
}
