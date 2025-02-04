
special_round <- Ware_SpecialRoundData
({
	name = "Barrels"
	author = "tilderain"
	description = "Explosive barrels will rain from the sky!"
	category = ""
})

local barrels = []

function OnPrecache()
{
	PrecacheModel("models/props_frontline/splosivebarrel_explosive.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib01.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib02.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib03.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib04.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib05.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib06.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib07.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib08.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib09.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib10.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib11.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib12.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib13.mdl")
	PrecacheModel("models/props_frontline/splosivebarrel_jib14.mdl")
}

function OnUpdate()
{
	if(barrels.len() < 64)
	{	
		if (RandomInt(0, 48) == 0)
			{ 
				local plyOrigin = RandomElement(Ware_Players).GetOrigin()
			
				local barrel = SpawnEntityFromTableSafe("prop_physics_multiplayer",
				{
					//Ware_MinigameLocation.center
					origin	 = plyOrigin + 
								Vector(RandomFloat(-250.0, 250.0), 
									   RandomFloat(-250.0, 250.0),
									   RandomFloat(250.0, 1000.0))
					model	  = "models/props_frontline/splosivebarrel_explosive.mdl"
					targetname = "explosive_barrel"
				})
			barrels.append(barrel)
		}
	}
	else
	{
		local barrel = barrels.remove(0)
	
		if(barrel.IsValid())
		{
			barrel.Kill()
		}
	}

}

function OnTakeDamage(params)
{
	//Barrels won't do non-self inflicted damage otherwise
	local victim = params.const_entity
	if(victim.GetName() == "explosive_barrel")
	{
		params.attacker = victim
	}
}