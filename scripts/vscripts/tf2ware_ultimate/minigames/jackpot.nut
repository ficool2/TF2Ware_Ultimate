minigame <- Ware_MinigameData
({
	name           = "Hit the Jackpot"
	author         = ["PedritoGMG"]
	description    = "Hit the Jackpot!"
	duration       = 10.0
	max_players    = 64 	// 9 ents for each player | 576
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
local centerToSlotOrigin = Vector(0, 27.5, 0)
// More speed = Less Sync
speedDefault <- 32
local separation = 30

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
sound_dispenser <- "weapons/dispenser_idle.wav"
sound_heal <- "weapons/dispenser_heal.wav"
sound_ammo <- "weapons/dispenser_generate_metal.wav"
overlay_fail <- "hud/tf2ware_ultimate/minigames/jackpot_fail"

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
		local cloneCC = clone(columnCharacters)
		for (local i = 0; i < size; i++) {
			local icon = SpawnIconToPlayer(RemoveRandomElement(cloneCC))
			icon.SetOrigin(origin + Vector( 0, separation * i, 0))
			icon.SetAbsAngles(angles)
			icon.SetAbsVelocity(Vector(0, -speed, 0))
			icon.ValidateScriptScope()
			icon.GetScriptScope().ColumnSlot <- this
			this.icons.append(icon)
			AllSlotsIcons.append(icon)
		}
    }

	function SpawnIconToPlayer(name)
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
		SetPropEntity(ent, "m_hBuilder", this.player)
		SetPropString(ent, "m_iName", "slot_icon")
		return ent
	}
	function GetMiddleOne() {
		return FindClosestEntity(this.icons, this.origin + centerToSlotOrigin)
	}
	function Stop() {
		foreach (icon in this.icons) {
			icon.SetMoveType(MOVETYPE_NONE, 0)
		}
	}

	function FindClosestEntity(entities, targetOrigin) {
		if (entities.len() == 0) return null

		local closest = null
		local minDist = null

		foreach (ent in entities) {
			local dist = VectorDistance(ent.GetOrigin(), targetOrigin)
			if (closest == null || dist < minDist) {
				minDist = dist
				closest = ent
			}
		}

		return closest
	}
}

function OnPrecache()
{
	PrecacheModel(model_head)
	PrecacheModel(model_dispenser)
	PrecacheSound(sound_dispenser)
	PrecacheSound(sound_heal)
	PrecacheSound(sound_ammo)
	PrecacheOverlay(overlay_fail)
}


function OnStart()
{
	Ware_PlaySoundOnAllClients(sound_dispenser)
	Ware_PlaySoundOnAllClients(sound_heal)

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
		skin 			= RandomInt(0, 1)
	})

	foreach (player in Ware_MinigamePlayers) {
		TogglePlayerViewcontrol(player, camera, true)

		local minidata = Ware_GetPlayerMiniData(player)
		minidata.holding_attack <- 0
		minidata.clicks <- 0
		minidata.SlotMachine <- []
		for (local i = 1; i <= columnSize; i++) {
			local origin = cameraOrigin + Vector(-separation*2, -20, -90) // Center to Left
			minidata.SlotMachine.append(
				ColumnSlot(player, speedDefault*i , columnSize, origin + Vector(separation*i, 0, 0), cameraAngle)
			)
		}
		minidata.SlotMachine
	}

	// Tesing | to see the places where straight icons are checked
	/*
	local minidata = Ware_GetPlayerMiniData(GetListenServerHost())
	foreach (slot in minidata.SlotMachine) {
		DebugDrawCircle(slot.origin + centerToSlotOrigin, Vector(0, 255, 0), 50, 10.0, true, 10.0)
	}
	*/

}

function OnEnd()
{
	Ware_PlaySoundOnAllClients(sound_dispenser, 1.0, 100, SND_STOP)
	Ware_PlaySoundOnAllClients(sound_heal, 1.0, 100, SND_STOP)
	foreach (player in Ware_MinigamePlayers)
		TogglePlayerViewcontrol(player, camera, false)
}

function OnUpdate()
{
    foreach (icon in AllSlotsIcons)
	{
		// Less Space = Less Sync | idk how to fix
		local limit = 22.5

		local IconSlot = icon.GetScriptScope().ColumnSlot
        local origin = icon.GetOrigin()

		if (IconSlot.origin.y - limit > origin.y) {
			icon.KeyValueFromVector("origin", (IconSlot.origin + Vector(0, limit * 3, 0)))

			//Fix for visible teleport
			local currentIcon = icon // Local Copy
			SetPropInt(icon, "m_nRenderMode", 10)
			Ware_CreateTimer(@() SetPropInt(currentIcon, "m_nRenderMode", 0), 0.05)
		}
    }
	foreach (player in Ware_MinigamePlayers)
	{
		local minidata = Ware_GetPlayerMiniData(player)
		local buttons = GetPropInt(player, "m_nButtons")

		if (buttons & IN_ATTACK && !minidata.holding_attack)
		{
			if (minidata.clicks < columnSize) {
				Ware_PlaySoundOnClient(player, sound_ammo)
				minidata.SlotMachine[minidata.clicks].Stop()
			}

			if (minidata.clicks == columnSize-1) {
				local iconsResult = []

				for (local i = 0; i < columnSize; i++)
					iconsResult.append(minidata.SlotMachine[i].GetMiddleOne())

				if (allSameBodygroup(iconsResult, 0))
				{
					Ware_PassPlayer(player, true)
					if (first)
					{
						Ware_ChatPrint(null, "{player} {color}was the first to hit the jackpot!", player, TF_COLOR_DEFAULT)
						Ware_GiveBonusPoints(player)
						first = false
					}
				} else {
					Ware_ShowScreenOverlay(player, overlay_fail)
				}

			}
			minidata.clicks++
		}

		minidata.holding_attack = (buttons & IN_ATTACK) != 0
	}
}

function allSameBodygroup(entities, groupId) {
    if (entities.len() == 0) return true;

    local firstBg = entities[0].GetBodygroup(groupId);
    foreach (ent in entities) {
        if (ent.GetBodygroup(groupId) != firstBg) {
            return false;
        }
    }
    return true;
}

function SetRenderModeAll(ents, mode) {
	foreach (ent in ents)
		SetPropInt(ents, "m_nRenderMode", mode)
}