simon    <- RandomInt(0, 1)
suffixes <- ["Taunt", "Jump", "Crouch", "Medic", "Eat", "Drink", "Inspect", "Horn", "Type", "Charge"]

minigame <- Ware_MinigameData
({
	name           = "Simon Says"
	author         = ["Mecha the Slag", "Gemidyne", "ficool2"]
	description    = "Simon says..."
	duration       = 4.0
	music          = "clumsy"
	modes          = 10
	start_pass     = simon == 0
	custom_overlay = format("%s_says_%s", simon ? "simon" : "someone", suffixes[Ware_MinigameMode].tolower())
	description    = format("%s says %s!", simon ? "Simon" : "Someone", suffixes[Ware_MinigameMode])
})

function OnPrecache()
{
	foreach (suffix in suffixes)
	{
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/simon_says_" + suffix.tolower())
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/someone_says_" + suffix.tolower())
	}
	
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/simon_says_fail")
}

function OnStart()
{
	if (Ware_MinigameMode == 4)
	{
		local items = ["Sandvich", "Dalokohs Bar", "Fishcake", "Buffalo Steak Sandvich", "Second Banana"]
		Ware_SetGlobalLoadout(TF_CLASS_HEAVYWEAPONS, RandomElement(items))
	}
	else if (Ware_MinigameMode == 5)
	{
		local items = ["Bonk! Atomic Punch", "Crit-a-Cola"]
		Ware_SetGlobalLoadout(TF_CLASS_SCOUT, RandomElement(items))
	}
	else if (Ware_MinigameMode == 7)
	{
		Ware_SetGlobalCondition(TF_COND_HALLOWEEN_KART)
	}
	else if (Ware_MinigameMode == 9)
	{ 
		foreach (player in Ware_MinigamePlayers)
		{
			Ware_SetPlayerLoadout(player, TF_CLASS_DEMOMAN)
			Ware_GetPlayerMiniData(player).attack2 <- false
			SetPropBool(player, "m_Shared.m_bShieldEquipped", true)
		}
	}
}

function PassOrFailPlayer(player, pass)
{
	Ware_PassPlayer(player, pass)
	if (!pass)
		Ware_ShowScreenOverlay(player, "hud/tf2ware_ultimate/minigames/simon_says_fail")
}
	
if (Ware_MinigameMode == 3 || Ware_MinigameMode == 4 || Ware_MinigameMode == 5)
{
	function OnPlayerVoiceline(player, voiceline)
	{
		local pass = simon == 0
		if (Ware_IsPlayerPassed(player) != pass)
			return
			
		if (Ware_MinigameMode == 5)
		{
			if (voiceline.find("taunt04") != null)
				PassOrFailPlayer(player, !pass)
		}
		else
		{
			if (voiceline in VCD_MAP)
			{
				if (Ware_MinigameMode == 3)
				{				
					if (VCD_MAP[voiceline].find(".Medic") != null)
						PassOrFailPlayer(player, !pass)
				}
				else if (Ware_MinigameMode == 4)
				{
					if (VCD_MAP[voiceline] == "Heavy.SandwichEat")
						PassOrFailPlayer(player, !pass)
				}
			}
		}
	}
}
else if (Ware_MinigameMode == 7)
{
	function OnPlayerHorn(player)
	{
		local pass = simon == 0
		PassOrFailPlayer(player, !pass)
	}
}
else if (Ware_MinigameMode == 8)
{
	function OnPlayerSay(player, text)
	{
		local pass = simon == 0
		PassOrFailPlayer(player, !pass)
	}
}
else if (Ware_MinigameMode == 9)
{
	// TODO: Prevent charge spam after initial charge
	local pass = simon == 0
	function OnUpdate()
	{
		foreach (player in Ware_MinigamePlayers)
		{
			local minidata = Ware_GetPlayerMiniData(player)
			local attack2 = GetPropInt(player, "m_nButtons") & IN_ATTACK2
			if (attack2 && !minidata.attack2)
			{
				player.AddCond(TF_COND_SHIELD_CHARGE)
				PassOrFailPlayer(player, !pass)
			}
			minidata.attack2 = attack2
		}
	}
}
else
{
	function OnUpdate()
	{	
		if (Ware_GetMinigameTime() < 1.0) // grace period
			return
				
		local pass = simon == 0
		foreach (player in Ware_MinigamePlayers)
		{
			if (Ware_IsPlayerPassed(player) != pass)
				continue
				
			if (Ware_MinigameMode == 0)
			{
				if (player.IsTaunting())
					PassOrFailPlayer(player, !pass)
			}
			else if (Ware_MinigameMode == 1)
			{
				if (GetPropBool(player, "m_Shared.m_bJumping"))
					PassOrFailPlayer(player, !pass)
			}
			else if (Ware_MinigameMode == 2)
			{
				if (player.GetFlags() & FL_DUCKING)
					PassOrFailPlayer(player, !pass)
			}	
			else if (Ware_MinigameMode == 6)
			{
				local weapon = player.GetActiveWeapon()
				if (weapon && GetPropInt(weapon, "m_nInspectStage") >= 0)
					PassOrFailPlayer(player, !pass)
			}
		}
	}
}

function OnEnd()
{
	if (Ware_MinigameMode == 4 || Ware_MinigameMode == 5)
	{
		foreach (player in Ware_MinigamePlayers)
		{
			player.RemoveCond(TF_COND_PHASE)
			player.RemoveCond(TF_COND_ENERGY_BUFF)
		}
	}
}