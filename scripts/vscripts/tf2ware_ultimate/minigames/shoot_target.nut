mode <- RandomInt(0, 1)
target_names <- ["Scout", "Soldier", "Pyro", "Demoman", "Heavy", "Engineer", "Medic", "Sniper", "Spy"]
target_class <- RandomElement(target_names)

minigame <- Ware_MinigameData
({
	name           = "Shoot Target"
	author         = ["Gemidyne", "ficool2"]
	description    = format("Shoot the %s target!", mode == 0 ? "" : target_class)
	location       = "targetrange"
	duration       = 5.0
	music          = mode == 0 ? "wildwest" : "cheerful"
	custom_overlay = mode == 0 ? "shoot_target" : "shoot_target_" + target_class.tolower()
})

function OnPrecache()
{
	foreach (name in target_names)
	{
		PrecacheModel(format("models/props_training/target_%s.mdl", name.tolower()))
		PrecacheOverlay("hud/tf2ware_ultimate/minigames/shoot_target_" + name.tolower())
	}
	PrecacheOverlay("hud/tf2ware_ultimate/minigames/shoot_target")
	Ware_PrecacheMinigameMusic("wildwest", false)
	Ware_PrecacheMinigameMusic("cheerful", false)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SNIPER, "Sydney Sleeper")
		
	local angles = [QAngle(0, -90, 0), QAngle(0, -270, 0)]
	if(mode == 0)
	{
		local pos = RandomInt(0,4)
		for (local side = 0; side < 2; side++)
		{
			local line = Ware_MinigameLocation.lines[pos]
			local yoff = side == 0 ? -10 : 10
			local prop = Ware_SpawnEntity("prop_dynamic",
			{
				targetname = "class_target"
				model      = format("models/props_training/target_%s.mdl", target_class.tolower())
				origin     = Lerp(line[0], line[1], 0) + Vector(0,yoff,-75)
				angles     = angles[side]
				solid      = SOLID_VPHYSICS
				skin       = side
			})
			prop.ValidateScriptScope()
			local scope = prop.GetScriptScope()
			scope.moving_down <- false
			scope.top_z <- prop.GetOrigin().z + 68.0

			Ware_CreateTimer(@() MoveTarget(prop), 2)
		}
	}
	else
	{
		for (local side = 0; side < 2; side++)
		{
			local indices = [0, 1, 2, 3, 4]
			Shuffle(indices)

			local target_count = RandomInt(1, 5)
			for (local i = 0; i < target_count; i++)
			{
				local line = Ware_MinigameLocation.lines[indices[i]]
				local name = i == 0 ? target_class : RandomElement(target_names)
				Ware_SpawnEntity("prop_dynamic",
				{
					targetname = "class_target"
					model      = format("models/props_training/target_%s.mdl", name.tolower())
					origin     = Lerp(line[0], line[1], RandomFloat(0.0, 1.0))
					angles     = angles[side]
					solid      = SOLID_VPHYSICS
					skin       = side
				})
			}
		}
	}
}

function MoveTarget(prop)
{
	local scope = prop.GetScriptScope()
	local zoff = scope.moving_down ? -6.0 : 6.0
	prop.SetAbsOrigin(prop.GetOrigin() + Vector(0, 0, zoff))

	if (prop.GetOrigin().z < scope.top_z)
	{
		return 0.01
	}
	else
	{
		scope.moving_down = true
		return 1.5
	}
		
}

function OnTakeDamage(params)
{
	local victim = params.const_entity
	if (victim.GetName() == "class_target")
	{
		local attacker = params.attacker
		if (attacker && attacker.IsPlayer())	
		{
			local class_name = victim.GetModelName().slice(29)
			class_name = class_name.slice(0, class_name.find(".mdl"))
			
			if (class_name == target_class.tolower())
				Ware_PassPlayer(attacker, true)
			else
				Ware_SuicidePlayer(attacker)
			
			Ware_PlaySoundOnClient(attacker, class_name + ".PainSevere01")
		}
		
		return false
	}
}