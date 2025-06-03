// ~42 hits per player
merasmus_health_per_player <- 2750.0
merasmus_health_base <- 2000.0
merasmus_health <- merasmus_health_base + merasmus_health_per_player * Ware_Players.len()

special_round <- Ware_SpecialRoundData
({
	name = "Kill Merasmus"
	author = "tilderain"
	description = "Or else!"
	category = ""
	convars = 
	{
		tf_merasmus_lifetime = 999999
		tf_merasmus_chase_range = 10000000
		tf_merasmus_chase_duration = 10000000
		tf_merasmus_health_base = merasmus_health
		tf_merasmus_health_per_player = 0
	}
})

merasmus <- null
merasmus_killed <- false

merasmus_color <- "71b149"

function OnPlayerConnect(player)
{
	Ware_GetPlayerSpecialRoundData(player).damage <- 0
	Ware_GetPlayerSpecialRoundData(player).vo_timer <- Time() + 4.0
}

function OnStart()
{
	CreateTimer(@() SpawnMerasmus(), 0.25)
	foreach (player in Ware_Players)
	{
		local special = Ware_GetPlayerSpecialRoundData(player)
		special.damage <- 0
		special.vo_timer <- Time() + 4.0
	}
}

function OnUpdate()
{
	if (merasmus && !merasmus.IsValid() && !merasmus_killed)
	{
		merasmus_killed = true
		OnMerasmusKilled()
	}
	
	if (!merasmus_killed)
	{
		foreach (player in Ware_Players)
		{
			if (!player.IsAlive()) 
				continue
			
			local special = Ware_GetPlayerSpecialRoundData(player)
			if (special.vo_timer < Time())
			{
				local player_class = player.GetPlayerClass()
				special.vo_timer <- Time() + 10.0 + RandomFloat(0.0, 6.0)
	
				local vo = vos[player_class]
				if (vo.len() == 0) 
					continue
	
				player.PlayScene(RandomElement(vo), 0.0)
			}
		}
	}
}

function OnPrecache()
{
	PrecacheEntityFromTable({classname = "merasmus"})
}

function SpawnMerasmus()
{
	merasmus = SpawnEntityFromTableSafe("merasmus",
	{
		origin = Ware_MinigameLocation.center + Vector(0, 0, 32),
		modelscale = 1,
		targetname = "merasmus_special"
	})
}

function OnMinigameStart()
{
	if (merasmus && merasmus.IsValid())
		merasmus.SetOrigin(Ware_MinigameLocation.center + Vector(0, 0, 32))
}

function OnMinigameEnd()
{
	if (merasmus && merasmus.IsValid())
		merasmus.SetOrigin(Ware_MinigameLocation.center + Vector(0, 0, 32))
}

function OnTakeDamage(params)
{
	local attacker = params.attacker
	if (params.const_entity.GetClassname() == "merasmus")
	{
		//spy op
		if (params.weapon && params.weapon.GetName() == "tf_weapon_knife")
			params.damage = 20
		
		if (params.damage > 200)
			params.damage = 20
		
		if (attacker && attacker.IsPlayer())
		{
			local special = Ware_GetPlayerSpecialRoundData(attacker)
			if(params.damage > 0)
			{
				special.damage += params.damage
				//Ware_ShowText(attacker, CHANNEL_MISC, format("Total: %d", special.damage), 1)
			}
		}
	}
	else if (attacker && attacker.GetClassname() == "merasmus")
	{
		params.damage *= Ware_Finished ? 3.0 : 0.33
	}
}

function OnCalculateTopScorers(top_players)
{
	if (merasmus && merasmus.IsValid())
	{
		top_players.clear()
	}
	else
	{
		// use default calculation
		return false
	}
}

function OnDeclareWinners(top_players, top_score, winner_count)
{
	if (merasmus && merasmus.IsValid())
	{
		Ware_ChatPrint(null, "{color}MERASMUS{color} wins!", merasmus_color, TF_COLOR_DEFAULT)
	}
	else
	{
		// use default winning declaration
		return false
	}
}

function OnMerasmusKilled()
{
	local playerDamageList = []
	foreach (player in Ware_Players) 
	{
	    local special = Ware_GetPlayerSpecialRoundData(player)
	    playerDamageList.append
		({
	        player = player
	        damage = special.damage
	    })
	}

	playerDamageList.sort(@(a, b) b.damage <=> a.damage)

	for (local i = 0; i < 3 && i < playerDamageList.len(); i++) 
	{
	    Ware_ChatPrint(null, "{player}{color} did {int} damage to {color}MERASMUS!", 
			playerDamageList[i].player, TF_COLOR_DEFAULT, playerDamageList[i].damage, merasmus_color)
	}

	local win_threshold
	if (Ware_Players.len() > 64)
		win_threshold = 10
	else if (Ware_Players.len() > 24)
		win_threshold = 6
	else if (Ware_Players.len() > 3)
		win_threshold = 3
	else
		win_threshold = 1

	local topPlayers = []
	for (local i = 0; i < win_threshold && i < playerDamageList.len(); i++)
	    topPlayers.append(playerDamageList[i].player)

	foreach (player in Ware_Players)
	{
		if (topPlayers.find(player) == null)
		{
			local special = Ware_GetPlayerSpecialRoundData(player)
			Ware_ChatPrint(player, "You did {int} damage to {color}MERASMUS!", 
			special.damage, merasmus_color)
		}
	}
	
	Ware_AwardBonusPoints(topPlayers.remove(0), 2, true, special_round.name, special_round.file_name)
	if (topPlayers.len() > 0)
		Ware_AwardBonusPoints(topPlayers, 1, true, special_round.name, special_round.file_name)
}

vos <-
[
	[], //nothing
	["scenes/player/scout/low/4477.vcd"
	"scenes/player/scout/low/4478.vcd"
	"scenes/player/scout/low/4479.vcd"
	"scenes/player/scout/low/4480.vcd"
	"scenes/player/scout/low/4481.vcd"
	"scenes/player/scout/low/4695.vcd"
	"scenes/player/scout/low/4482.vcd"
	"scenes/player/scout/low/4482.vcd"
	"scenes/player/scout/low/4483.vcd"
	"scenes/player/scout/low/4697.vcd"
	"scenes/player/scout/low/4493.vcd"
	"scenes/player/scout/low/4487.vcd"
	"scenes/player/scout/low/4489.vcd"
	"scenes/player/scout/low/4698.vcd"
	"scenes/player/scout/low/4491.vcd"
	"scenes/player/scout/low/4492.vcd"
	"scenes/player/scout/low/4494.vcd"
	"scenes/player/scout/low/4699.vcd"
	"scenes/player/scout/low/4699.vcd"
	"scenes/player/scout/low/4700.vcd"
	"scenes/player/scout/low/4496.vcd"
	"scenes/player/scout/low/4701.vcd"
	"scenes/player/scout/low/4497.vcd"
	"scenes/player/scout/low/4497.vcd"
	"scenes/player/scout/low/4498.vcd"
	"scenes/player/scout/low/4702.vcd"
	"scenes/player/scout/low/4702.vcd"],
	[],
	//sniper??
	["scenes/player/soldier/low/4566.vcd"
	"scenes/player/soldier/low/4567.vcd"
	"scenes/player/soldier/low/4516.vcd"
	"scenes/player/soldier/low/4517.vcd"
	"scenes/player/soldier/low/4506.vcd"
	"scenes/player/soldier/low/4507.vcd"
	"scenes/player/soldier/low/4509.vcd"
	"scenes/player/soldier/low/4499.vcd"
	"scenes/player/soldier/low/4511.vcd"
	"scenes/player/soldier/low/4512.vcd"
	"scenes/player/soldier/low/4513.vcd"
	"scenes/player/soldier/low/4514.vcd"
	"scenes/player/soldier/low/4515.vcd"
	"scenes/player/soldier/low/4524.vcd"
	"scenes/player/soldier/low/4502.vcd"
	"scenes/player/soldier/low/4503.vcd"
	"scenes/player/soldier/low/4504.vcd"
	"scenes/player/soldier/low/4505.vcd"
	"scenes/player/soldier/low/4500.vcd"
	"scenes/player/soldier/low/4510.vcd"
	"scenes/player/soldier/low/4521.vcd"
	"scenes/player/soldier/low/4522.vcd"
	"scenes/player/soldier/low/4522.vcd"
	"scenes/player/soldier/low/4523.vcd"
	"scenes/player/soldier/low/4523.vcd"
	"scenes/player/soldier/low/4526.vcd"
	"scenes/player/soldier/low/4526.vcd"
	"scenes/player/soldier/low/4525.vcd"
	"scenes/player/soldier/low/4525.vcd"
	"scenes/player/soldier/low/4527.vcd"
	"scenes/player/soldier/low/4527.vcd"
	"scenes/player/soldier/low/4529.vcd"
	"scenes/player/soldier/low/4529.vcd"
	"scenes/player/soldier/low/4528.vcd"
	"scenes/player/soldier/low/4528.vcd"
	"scenes/player/soldier/low/4530.vcd"
	"scenes/player/soldier/low/4530.vcd"
	"scenes/player/soldier/low/4531.vcd"
	"scenes/player/soldier/low/4531.vcd"
	"scenes/player/soldier/low/4533.vcd"
	"scenes/player/soldier/low/4533.vcd"
	"scenes/player/soldier/low/4534.vcd"
	"scenes/player/soldier/low/4534.vcd"
	"scenes/player/soldier/low/4535.vcd"
	"scenes/player/soldier/low/4535.vcd"
	"scenes/player/soldier/low/4536.vcd"
	"scenes/player/soldier/low/4536.vcd"
	"scenes/player/soldier/low/4537.vcd"
	"scenes/player/soldier/low/4537.vcd"
	"scenes/player/soldier/low/4538.vcd"
	"scenes/player/soldier/low/4538.vcd"
	"scenes/player/soldier/low/4539.vcd"
	"scenes/player/soldier/low/4539.vcd"],
	["scenes/player/demoman/low/4597.vcd"
	"scenes/player/demoman/low/4598.vcd"
	"scenes/player/demoman/low/4599.vcd"
	"scenes/player/demoman/low/4600.vcd"
	"scenes/player/demoman/low/4581.vcd"
	"scenes/player/demoman/low/4582.vcd"
	"scenes/player/demoman/low/4583.vcd"
	"scenes/player/demoman/low/4576.vcd"
	"scenes/player/demoman/low/4576.vcd"
	"scenes/player/demoman/low/5454.vcd"
	"scenes/player/demoman/low/4577.vcd"
	"scenes/player/demoman/low/4577.vcd"
	"scenes/player/demoman/low/4578.vcd"
	"scenes/player/demoman/low/4578.vcd"
	"scenes/player/demoman/low/4579.vcd"
	"scenes/player/demoman/low/4579.vcd"
	"scenes/player/demoman/low/4580.vcd"
	"scenes/player/demoman/low/4580.vcd"
	"scenes/player/demoman/low/4575.vcd"],
	["scenes/player/medic/low/4676.vcd"
	"scenes/player/medic/low/4677.vcd"
	"scenes/player/medic/low/4734.vcd"
	"scenes/player/medic/low/4643.vcd"
	"scenes/player/medic/low/4644.vcd"
	"scenes/player/medic/low/4647.vcd"
	"scenes/player/medic/low/4648.vcd"
	"scenes/player/medic/low/4646.vcd"
	"scenes/player/medic/low/4645.vcd"
	"scenes/player/medic/low/4735.vcd"
	"scenes/player/medic/low/4736.vcd"
	"scenes/player/medic/low/4731.vcd"
	"scenes/player/medic/low/4732.vcd"
	"scenes/player/medic/low/4649.vcd"
	"scenes/player/medic/low/4650.vcd"],
	["scenes/player/heavy/low/4760.vcd"
	"scenes/player/heavy/low/4761.vcd"
	"scenes/player/heavy/low/4762.vcd"
	"scenes/player/heavy/low/4763.vcd"
	"scenes/player/heavy/low/5455.vcd"
	"scenes/player/heavy/low/4741.vcd"
	"scenes/player/heavy/low/4742.vcd"
	"scenes/player/heavy/low/4737.vcd"
	"scenes/player/heavy/low/4738.vcd"
	"scenes/player/heavy/low/4739.vcd"
	"scenes/player/heavy/low/4740.vcd"],

	[], //pyro



	[], //spy

	[], //engie
]
