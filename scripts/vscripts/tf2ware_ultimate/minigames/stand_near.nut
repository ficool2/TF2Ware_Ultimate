
minigame <- Ware_MinigameData
({
	name           = "Stand Near"
	author         = ["sasch", "ficool2"]
	modes          = 2
	description    = Ware_MinigameMode == 1 ? "Don't stand near anybody!" : "Stand near somebody!"
	duration       = 4.0
	end_delay      = 1.0
	music          = "spotlightsonyou"
	min_players    = 2
	start_pass     = true
	allow_damage   = true
	fail_on_death  = true
	custom_overlay = Ware_MinigameMode == 1 ? "stand_away" : "stand_near"
})

function OnPrecache()
{
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/stand_away")
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/stand_near")
}

function OnEnd()
{
	local threshold = 96.0
	
	local targets = []
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
		{
			Ware_PassPlayer(player, false)
			continue
		}
		
		targets.append({player = player, origin = player.GetOrigin(), kill = true})
	}
	
	foreach (target1 in targets)
	{
		foreach (target2 in targets)
		{
			if (target1 == target2)
				continue
				
			local dist = VectorDistance(target1.origin, target2.origin)
			if (dist < threshold)
			{
				if (Ware_MinigameMode == 1)
					target1.player.TakeDamage(1000.0, DMG_BLAST, target2.player)
				else
					target1.kill = false
				break
			}
		}
	}
	
	if (Ware_MinigameMode == 0)
	{
		foreach (target in targets)
		{
			if (target.kill)
				Ware_SuicidePlayer(target.player)
		}
	}
}

function OnTakeDamage(params)
{
	if (params.damage_custom == TF_DMG_CUSTOM_SUICIDE)
		return
	if (params.damage_type == DMG_BLAST)
		return
	
	params.damage = 10
	
	local victim = params.const_entity
	if (victim.IsPlayer() && params.attacker != null)
	{
		local dir = params.attacker.EyeAngles().Forward()
		dir.z = 128.0
		dir.Norm()
		
		victim.SetAbsVelocity(victim.GetAbsVelocity() + dir * 300.0)
	}
}