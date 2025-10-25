
minigame <- Ware_MinigameData
({
	name          = "Market Garden"
	author        = "pokemonPasta"
	description   = "Market garden someone!"
	duration      = 12.0
	music         = "duckhunt"
	min_players   = 2
	allow_damage  = true
})

function OnStart()
{
	foreach(player in Ware_MinigamePlayers)
	{
		Ware_SetPlayerLoadout(player, TF_CLASS_SOLDIER, ["Market Gardener", "Rocket Jumper"], { "deploy time increased" : 1.0 })
		player.SetHealth(195)
	}
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (!victim.IsPlayer())
		return
		
	local attacker = params.attacker
	if (!attacker || !attacker.IsPlayer())
		return
	
	local weapon = params.weapon
	if (weapon && weapon.GetName() == "tf_weapon_shovel" && !attacker.InCond(TF_COND_BLASTJUMPING))
		params.damage = 0.0
}

function OnPlayerDeath(player, attacker, params)
{
	if (attacker && attacker.IsPlayer())
		Ware_PassPlayer(attacker, true)
}

function OnCheckEnd()
{
	return Ware_GetAlivePlayers().len() < 2
}