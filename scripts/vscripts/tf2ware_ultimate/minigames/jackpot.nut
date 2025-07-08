minigame <- Ware_MinigameData
({
	name           = "Hit the Jackpot"
	author         = ["PedritoGMG"]
	description    = "Hit the Jackpot!"
	duration       = 10.0
    music          = "casino"
})

local charactersConst = [
    "Scout",    // 1
    "Sniper",   // 2
    "Soldier",  // 3
    "Demoman",  // 4
    "Medic",    // 5
    "Heavy",    // 6
    "Pyro",     // 7
    "Spy",      // 8
    "Engineer"  // 9
]

first <- true

camera <- null
centerPos <- Ware_MinigameLocation.center * 1.0
cameraOrigin <- Vector(0, 0, 500) + centerPos
cameraAngle <- QAngle(90, 90, 0)
columnSize <- 3
// More speed = Less Sync
speedDefault <- 17.5
local separation = 30

panelSize <- 125

local columnCharacters = (function() {
    local chars = clone(charactersConst)
    local result = []
    while (result.len() != columnSize) {
        result.append(RemoveRandomElement(chars))
    }
    return result
})()

local model_head  = "models/mariokart/head.mdl"
model_dispenser <- "models/buildables/dispenser_lvl3_light.mdl"
overlay_fail <- "hud/tf2ware_ultimate/minigames/memorize_a_pair_fail"

local AllSlotsIcons = []
class ColumnSlot {
	player = null
	speed = 0
	size = 0
	icons = null
	origin = Vector()
	angles = QAngle()

	constructor(player, speed, size, origin, angles) {
		this.player = player
        this.speed = speed
        this.size = size
		this.icons = []
		this.origin = origin
		this.angles = angles
		for (local i = 0; i < size; i++) {
			local icon = SpawnIconToPlayer(player, columnCharacters[i])
			icon.SetOrigin(origin + Vector( 0, separation*i, 0))
			icon.SetAbsAngles(angles)
			icon.SetAbsVelocity(Vector(0, -speed, 0))
			icon.ValidateScriptScope()
			icon.GetScriptScope().ColumnSlot <- this
			this.icons.append(icon)
			AllSlotsIcons.append(icon)
		}
    }

	function SpawnIconToPlayer(player, name)
	{
		local ent = Ware_CreateEntity("obj_teleporter")
		ent.DispatchSpawn()
		ent.SetModel(model_head)
		ent.SetModelScale(2.85, 0.0)
		ent.SetBodygroup(0, charactersConst.find(name))
		ent.AddEFlags(Constants.FEntityEFlags.EFL_NO_THINK_FUNCTION)
		ent.SetSolid(SOLID_NONE)
		ent.SetMoveType(MOVETYPE_FLY, MOVECOLLIDE_FLY_BOUNCE)
		SetPropBool(ent, "m_bPlacing", true)
		SetPropInt(ent, "m_fObjectFlags", 2)
		SetPropEntity(ent, "m_hBuilder", player)
		SetPropString(ent, "m_iName", "slot_icon")
		return ent
	}
	function GetMiddleOne() {
		this.OnGetMiddleOne()
		return
	}
	function OnGetMiddleOne() {
		foreach (icon in this.icons) {
			icon.SetMoveType(MOVETYPE_NONE, 0)
		}
	}
}

function OnPrecache()
{
	PrecacheModel(model_head)
	PrecacheModel(model_dispenser)
	PrecacheOverlay(overlay_fail)
}


function OnStart()
{
	camera = Ware_SpawnEntity("point_viewcontrol",
	{
		origin     = cameraOrigin
		angles     = cameraAngle
		spawnflags = 8
	})
	camera.SetMoveType(MOVETYPE_NONE, 0)

	local dispenser = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin          = cameraOrigin + Vector(-2.5, -150, -120)
		angles          = QAngle(-90, -90, 0)
		model			= model_dispenser
		modelscale      = 3.75
	})


	foreach (player in Ware_MinigamePlayers) {
		TogglePlayerViewcontrol(player, camera, true)
		player.AddHudHideFlags(HIDEHUD_MISCSTATUS|HIDEHUD_HEALTH)
		player.RemoveHudHideFlags(HIDEHUD_MISCSTATUS|HIDEHUD_HEALTH)

		local minidata = Ware_GetPlayerMiniData(player)
		minidata.holding_attack <- 0
		minidata.clicks <- 0
		minidata.SlotMachine <- []
		for (local i = 1; i <= columnSize; i++) {
			local origin = cameraOrigin + Vector(-separation*2, 0, 0)
			minidata.SlotMachine.append(
				ColumnSlot(player, speedDefault*i , columnSize, origin + Vector(separation*i, -25, -90), cameraAngle)
			)
		}
	}
}

function OnEnd()
{
	foreach (player in Ware_MinigamePlayers) {
		TogglePlayerViewcontrol(player, camera, false)
		player.RemoveHudHideFlags(HIDEHUD_MISCSTATUS|HIDEHUD_HEALTH)
		AddThinkToEnt(player, null)
	}
}

function OnUpdate()
{
    foreach (icon in AllSlotsIcons)
	{
		//less space = less sync | idk how to fix
		local limit = 22.5
		local IconSlot = icon.GetScriptScope().ColumnSlot
        local origin = icon.GetOrigin()

		if (IconSlot.origin.y - limit > origin.y)
		{
			icon.KeyValueFromVector("origin", (IconSlot.origin + Vector(0, limit*3, 0)))
		}
    }
	foreach (player in Ware_MinigamePlayers) {
		local minidata = Ware_GetPlayerMiniData(player)
		local buttons = GetPropInt(player, "m_nButtons")
		if (buttons & IN_ATTACK && !minidata.holding_attack)
		{
			if (minidata.clicks < columnSize)
				minidata.SlotMachine[minidata.clicks].GetMiddleOne()
			minidata.clicks++
			printl(minidata.clicks)
		}
		if (buttons & IN_ATTACK)
		{
			minidata.holding_attack = true
		}
		else
		{
			minidata.holding_attack = false
		}
	}
}