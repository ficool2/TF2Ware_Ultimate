
special_round <- Ware_SpecialRoundData
({
	name = "Barrels"
	author = "tilderain"
	description = "Explosive barrels will rain from the sky!"
	category = "entities"
})

local barrels = []

function OnPrecache()
{
	PrecacheModelGibs("models/tf2ware_ultimate/explosive_barrel.mdl")
}

function OnUpdate()
{
	if(barrels.len() < 64)
	{	
		if (RandomInt(0, 48) == 0)
		{ 
			local ply = RandomElement(Ware_Players)
			local barrelOrigin =  ply.GetOrigin() +
								Vector(RandomFloat(-250.0, 250.0), 
									   RandomFloat(-250.0, 250.0),
									   RandomFloat(250.0, 1000.0))
			if (TraceLine(barrelOrigin, barrelOrigin, ply) > 0.0)
			{
				local barrel = SpawnEntityFromTableSafe("prop_physics_multiplayer",
				{
					//Ware_MinigameLocation.center
					origin	 = barrelOrigin
					model	  = "models/tf2ware_ultimate/explosive_barrel.mdl"
					targetname = "explosive_barrel"
				})
				barrels.append(barrel)
			}
		}
	}
	else
	{
		local barrel = barrels.remove(0)
	
		if (barrel.IsValid())
		{
			barrel.Kill()
		}
	}

}

function OnTakeDamage(params)
{
	//Barrels won't do non-self inflicted damage otherwise
	local victim = params.const_entity
	if (victim.GetName() == "explosive_barrel")
	{
		params.attacker = victim
	}
}