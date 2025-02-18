minigame <- Ware_MinigameData
({
	name          = "Pick Up That Can"
	author		  = "CzechMate"
	description   = "Pick up and trash the can!"
	duration      = 13.0
	music         = "adventuretime"
})

trashcan_model <- "models/props_trainstation/trashcan_indoor001b.mdl"
can_model <- "models/props_junk/popcan01a.mdl"

////////////////////////// --- Settings --- ///////////////////////////////////////////

local pickupDistance = 128.0 // Distance the player can pick up the prop from
local distance = 50.0   // Distance from player to the picked up prop
local outline = true    // Outline props?
local canOffset = 100.0 // X and Y Offset for spawning cans
local canHeightOffset = 300.0   // Z Offset for spawning cans
local canRadiusSqr = 32.0*32.0  // Pickup radius for cans, squared
local propFaceSameDirection = false // If true, makes the prop face the same direction as the player (similar to Half-Life 2)
local canName = "can_minigame"  // Can targetname
local cans = []
local trashDelay = 0.3	// Ware_CreateTimer delay

//////////////////////////////////////////////////////////////////////////////////////

function OnPrecache()
{
	PrecacheModel(can_model)
	PrecacheModel(trashcan_model)
}

function OnStart()
{
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata =  Ware_GetPlayerMiniData(player)
        minidata.LastButtons <- 0
		minidata.LastActionKey <- false
        minidata.PickedProp <- player
	}

	if (Ware_MinigameLocation.name.find("big") != null)
	{
		SpawnTrashcan(Vector(0, 0, 5), trashDelay)
		SpawnTrashcan(Vector(366, 366, 0), trashDelay)
		SpawnTrashcan(Vector(366, -366, 0), trashDelay)
		SpawnTrashcan(Vector(-366, 366, 0), trashDelay)
		SpawnTrashcan(Vector(-366, -366, 0), trashDelay)
	} else {
		SpawnTrashcan(Vector(0, 0, 5), trashDelay)
	}

	SpawnCans()
	Ware_ChatPrint(null, "{color}TIP{color}: Pick up cans with mouse click, reload or action key and put them into the trash can!", 
		COLOR_GREEN, TF_COLOR_DEFAULT)
}

// Inspired by Prop Kill (https://github.com/Batfoxkid/TF2-Prop-Kill)
function OnUpdate()
{
	local time = Time()
	foreach (player in Ware_MinigamePlayers)
	{
		if (!player.IsAlive())
			continue
			
		local weapon = player.GetActiveWeapon()
		if (weapon)
			SetPropFloat(weapon, "m_flNextPrimaryAttack", time + 0.3)			
			
		local buttons = GetPropInt(player, "m_nButtons")
		local minidata = Ware_GetPlayerMiniData(player)
		local newButtons = buttons & ~minidata.LastButtons
		local usingActionKey = player.IsUsingActionSlot()
		
		if ((newButtons & (IN_ATTACK|IN_ATTACK2|IN_RELOAD|IN_USE)) || (usingActionKey && !minidata.LastActionKey))
		{
			if (minidata.PickedProp != player && minidata.PickedProp.IsValid())
			{
				minidata.PickedProp.SetOwner(null)
				minidata.PickedProp = player
			}
			else 
			{
				local eye_pos = player.EyePosition()
				local eye_fwd = player.EyeAngles().Forward()
				foreach (can in cans)
				{
					if (can.GetOwner() != null)
						continue				
					local can_origin = can.GetOrigin()
					if (VectorDistance(eye_pos, can_origin) > pickupDistance)
						continue
					if (IntersectRayWithSphere(eye_pos, eye_fwd, can_origin, canRadiusSqr))
					{
						minidata.PickedProp = can
						can.SetOwner(player)
						can.GetScriptScope().LastHolder <- player
						can.GetScriptScope().GraceHolderTime <- time + 0.25								
					}
				}
			}
		}

		if (minidata.PickedProp != player && minidata.PickedProp.IsValid())
		{
			local eye_position = player.EyePosition()
			local eye_angles = player.EyeAngles()
			local prop_origin = minidata.PickedProp.GetOrigin()
			local prop_angles = minidata.PickedProp.GetAbsAngles()
			local velocity = (eye_position + (eye_angles.Forward() * distance) - prop_origin) * 100

			if (propFaceSameDirection)
				prop_angles = eye_angles
			minidata.PickedProp.Teleport(false, prop_origin, true, prop_angles, true, velocity)
			minidata.PickedProp.SetPhysAngularVelocity(Vector(0.0, 0.0, 0.0))
			minidata.PickedProp.GetScriptScope().GraceHolderTime = time + 0.25
		}

		minidata.LastButtons = buttons
		minidata.LastActionKey = usingActionKey
	}
}

function OnPlayerDeath(player, attacker, params)
{
	local minidata = Ware_GetPlayerMiniData(player)
    if (minidata.PickedProp && minidata.PickedProp.IsValid())
		minidata.PickedProp.SetOwner(null)
}

function SpawnTrashcan(location, delay) 
{
	local newLocation = Ware_MinigameLocation.center * 1.0 + location
	SpawnTriggerPush(newLocation)
	Ware_CreateTimer(function() {
		local trashcan = Ware_SpawnEntity("prop_dynamic",
		{  
			model = trashcan_model
			origin = newLocation + Vector(0, 0, 15)
			solid = SOLID_VPHYSICS
		})

		if (outline)
		{
			local glow = Ware_CreateEntity("tf_glow")
			glow.KeyValueFromString("GlowColor", "0 255 0 255")
			SetPropEntity(glow, "m_hTarget", trashcan)
			SetEntityParent(glow, trashcan)
		}

    	SpawnTriggerMultiple(newLocation)
	}, delay)
}

function SpawnCans()
{
	local mins = Ware_MinigameLocation.mins
	local maxs = Ware_MinigameLocation.maxs
	local center = Ware_MinigameLocation.center

	foreach (player in Ware_MinigamePlayers)
	{
        local origin = Vector(
			RandomFloat(mins.x + canOffset, maxs.x - canOffset),
			RandomFloat(mins.y + canOffset, maxs.y - canOffset),
			center.z + canHeightOffset)

		local can = Ware_SpawnEntity("prop_physics",
		{
            targetname = canName
			model = can_model
			origin = origin
		})
        can.SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
        can.ValidateScriptScope()
        can.GetScriptScope().LastHolder <- null
		can.GetScriptScope().GraceHolderTime <- 0.0

        if (outline)
        {
            local glow = Ware_CreateEntity("tf_glow")
            glow.KeyValueFromString("GlowColor", "255 0 111 255")
            SetPropEntity(glow, "m_hTarget", can)
			SetEntityParent(glow, can)
        }
		
		cans.append(can)
	}
}

function SpawnTriggerMultiple(location)
{
    local trigger_multiple = Ware_SpawnEntity("trigger_multiple",
    {
        targetname = "trashcan_trigger"
        origin     = location
        spawnflags = SF_TRIGGER_ALLOW_PHYSICS
    })
    trigger_multiple.SetSize(Vector(-5, -5, 0), Vector(5, 5, 24))
    trigger_multiple.SetSolid(SOLID_BBOX)

    trigger_multiple.ValidateScriptScope()
	trigger_multiple.GetScriptScope().OnStartTouch <- OnTriggerTouch
	trigger_multiple.ConnectOutput("OnStartTouch", "OnStartTouch")
}

function SpawnTriggerPush(location)
{
    local trigger_push = Ware_SpawnEntity("trigger_push", 
    {
        targetname = "trashcan_push"
        origin     = location
        pushdir    = QAngle(0, RandomFloat(0, 360), 0)
        speed      = 1000
        spawnflags = SF_TRIGGER_ALLOW_CLIENTS 
    })
    trigger_push.SetSize(Vector(-20, -20, 0), Vector(20, 20, 50))
    trigger_push.SetSolid(SOLID_BBOX)
    EntFireByHandle(trigger_push, "Disable", "", 0.5, null, null)
}

function OnTriggerTouch()
{
    if (activator.GetName() == canName)
    {
        local player = activator.GetScriptScope().LastHolder
        if (player)
            Ware_PassPlayer(player, true)

		RemoveElementIfFound(cans, activator)
		
        activator.Destroy() // If the cans are not removed, they will lag the server due to physics calculations.
    }
}
