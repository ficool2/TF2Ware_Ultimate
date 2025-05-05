merasmus_health_per_player <- RemapValClamped(Ware_Players.len().tofloat(), 0.0, 12.0, 2500.0, 1250.0)
// 33 hits per player at 0 players, ~20 hits per player at 12 players

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
		tf_merasmus_health_base = 1500 + (merasmus_health_per_player * Ware_Players.len())
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

function GiveBonusPoints(target, points = 1)
{
	local award = true

	// even if there's no award, this is still tracked for the event	
	local player_indices_awarded = ""
	local awarded = target
	if (typeof(awarded) == "instance")
		awarded = [target]
	foreach (player in awarded)
		player_indices_awarded += player.entindex().tochar()
	
	if (award)
	{
		// account for multiple possible but we only got 1 player
		if (typeof(target) == "array" && target.len() == 1)
			target = target[0]
		
		if (typeof(target) == "instance")
		{
			local data = target.GetScriptScope().ware_data
			data.score += points
			data.bonus += points
			
			Ware_ChatPrint(null, "{color}{str}{color} was awarded an extra {str}!",
				TF_COLOR_RED, GetPlayerName(target), TF_COLOR_DEFAULT, points == 1 ? "point" : format("%d points", points))
		}
		else
		{
			local text = ""
			local params = [this, null, text]
			foreach (player in target)
			{
				local data = player.GetScriptScope().ware_data
				data.score += points
				data.bonus += points

				text += text == "" ? "The following players were each awarded an extra point: {player} " : " {player} "
				params.append(player)
			}
			text += "{color}!"
			params.append(TF_COLOR_DEFAULT)
			params[2] = text

			Ware_ChatPrint.acall(params)
		}
	}
	
	Ware_EventCallback("bonus_points", 
	{
		minigame_name      = "Kill Merasmus"
		minigame_file_name = "merasmus"
		players_awarded    = player_indices_awarded
	})
}

function OnUpdate()
{
	if (merasmus && !merasmus.IsValid() && !merasmus_killed)
	{
		merasmus_killed = true

		local playerDamageList = []

		foreach (player in Ware_Players) {
		    local special = Ware_GetPlayerSpecialRoundData(player)
		    playerDamageList.append({
		        player = player,
		        damage = special.damage
		    });
		}

		playerDamageList.sort(function(a, b) {
		    return b.damage <=> a.damage
		})

		for (local i = 0; i < 3 && i < playerDamageList.len(); i++) {
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
		for (local i = 0; i < win_threshold && i < playerDamageList.len(); i++) {
		    topPlayers.append(playerDamageList[i].player)
		}
		foreach(player in Ware_Players)
		{
			if(!(player in topPlayers))
			{
				local special = Ware_GetPlayerSpecialRoundData(player)
				Ware_ChatPrint(player, "You did {int} damage to {color}MERASMUS!", 
				special.damage, merasmus_color)
			}
		}
		GiveBonusPoints(topPlayers.remove(0), 2)
		if(topPlayers.len() > 0)
			GiveBonusPoints(topPlayers)
	}
	foreach(player in Ware_Players)
	{
		if(!player.IsAlive()) continue
		local special = Ware_GetPlayerSpecialRoundData(player)
		if(special.vo_timer < Time())
		{
			local player_class = player.GetPlayerClass()
			special.vo_timer <- Time() + 10.0 + RandomInt(0,6)

			if(vos[player_class].len() == 0) continue
			local scene = RandomElement(vos[player_class])
			player.PlayScene(scene, 0.0)
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
		if(params.weapon && params.weapon.GetName() == "tf_weapon_knife")
			params.damage = 20
		if(params.damage > 200)
			params.damage = 20
		if(attacker && attacker.IsPlayer())
		{
			local special = Ware_GetPlayerSpecialRoundData(attacker)
			if(params.damage > 0)
			{
				special.damage += params.damage
				//Ware_ShowText(attacker, CHANNEL_MISC, format("Total: %d", special.damage), 1)
			}
		}
	}
	else if (attacker && attacker.GetClassname() == "merasmus" && !Ware_Finished)
	{
		params.damage *= 0.33
	}
	else if (attacker && attacker.GetClassname() == "merasmus" && Ware_Finished)
	{
		params.damage *= 3
	}
}
function OnCalculateTopScorers(top_players)
{
	if(merasmus && merasmus.IsValid())
	{
		top_players.clear()
	}
	else
	{
		// do everything as normal
		local top_score = 1
		foreach (data in Ware_MinigamePlayersData)
		{
			if (data.score > top_score)
			{
				top_score = data.score
				top_players.clear()
				top_players.append(data.player)
			}
			else if (data.score == top_score)
			{
				top_players.append(data.player)
			}	
		}
	}

}

function OnDeclareWinners(top_players, top_score, winner_count)
{
	if(merasmus && merasmus.IsValid())
	{
		Ware_ChatPrint(null, "{color}MERASMUS!{color} wins!", merasmus_color, TF_COLOR_DEFAULT)
	}
	else
	{
		if (winner_count > 1)
		{
			Ware_ChatPrint(null, "{color}The winners each with {int} points:", TF_COLOR_DEFAULT, top_score)
			foreach (player in top_players)
				Ware_ChatPrint(null, "> {player} {color}!", player, TF_COLOR_DEFAULT)
		}
		else if (winner_count == 1)
		{
			Ware_ChatPrint(null, "{player} {color}won with {int} points!", top_players[0], TF_COLOR_DEFAULT, top_score)
		}	
		else if (winner_count == 0)
		{
			Ware_ChatPrint(null, "{color}Nobody won!?", TF_COLOR_DEFAULT)
		}
	}
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
