minigame <- Ware_MinigameData
({
	name           = "Memorize a Pair"
	author         = ["PedritoGMG"]
	description    = "Memorize a Pair!"
	duration       = 10.0
    location       = "dirtsquare"
    music          = "wanted"
})

local charactersConst = [
    "scout",    // 1
    "sniper",   // 2
    "soldier",  // 3
    "demoman",  // 4
    "medic",    // 5
    "heavy",    // 6
    "pyro",     // 7
    "spy",      // 8
    "engineer"  // 9
]

first <- true
xPos <- -400
yPos <- 1250
zPos <- 250
separation <- 250
boxSize <- 20

columns <- 4
rows <- 4
frameSize <- columns*rows

characters <- (function() {
    local chars = clone(charactersConst)
    local result = []
    while (result.len() != frameSize) {
        local element = RemoveRandomElement(chars)
        result.append(element)
        result.append(element)
    }
    return Shuffle(result)
})()

randomCards <- []
showAnimationProps <- []
showAnimationHeads <- []

model_head  <- "models/mariokart/head.mdl"
model_random  <- "models/class_menu/random_class_icon.mdl"
sound_show1 <- "misc/halloween/spelltick_01.wav"
sound_show2 <- "misc/halloween/spelltick_02.wav"
overlay_fail <- "hud/tf2ware_ultimate/minigames/memorize_a_pair_fail"

function OnPrecache()
{
	PrecacheModel(model_head)
	PrecacheModel(model_random)
	PrecacheSound(sound_show1)
	PrecacheSound(sound_show2)
	PrecacheOverlay(overlay_fail)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersRow(players,
		Ware_MinigameLocation.center - Vector(0, 400, 0),
		QAngle(-10, 90, 0),
		700.0,
		69.0, 64.0)
}

function OnStart()
{
	Ware_SetGlobalLoadout(TF_CLASS_SPY, "Festive Revolver")

	foreach (player in Ware_MinigamePlayers) {
		Ware_GetPlayerMiniData(player).selected_card <- null
		player.AddCustomAttribute("no_attack", 1, -1)
	}

	for (local i = 0; i < rows; i++) {
		for (local j = 0; j < columns; j++) {
			local pos = Ware_MinigameLocation.center * 1.0
    		pos += Vector(xPos + (separation * j), yPos, zPos + (separation * i))
			CreateRandomCard(RemoveRandomElement(characters), (i + j) % 2, pos)
		}
	}

	StartShowAnimation()
}

function OnTakeDamage(params)
{
	if (!(params.damage_type & DMG_BULLET))
		return

	local entity = params.const_entity
	if (charactersConst.find(entity.GetName()) != null)
	{
		local attacker = params.attacker
		if (attacker != null && attacker.IsPlayer())
		{
			local minidata = Ware_GetPlayerMiniData(attacker)

			if (minidata.selected_card == null) {
				SpawnCardResultToPlayer(entity, attacker)
				minidata.selected_card = entity
				return
			}

			if (minidata.selected_card == entity)
				return

			if (minidata.selected_card.GetName() == entity.GetName()) {
				SpawnCardResultToPlayer(entity, attacker)
				Ware_PassPlayer(attacker, true)
				if (first)
				{
					Ware_ChatPrint(null, "{player} {color}was the first to find a pair!", attacker, TF_COLOR_DEFAULT)
					Ware_GiveBonusPoints(attacker)
					first = false
				}
				return
			}

			SpawnCardResultToPlayer(entity, attacker)
			Ware_SuicidePlayer(attacker)
			Ware_ShowScreenOverlay(attacker, overlay_fail)
		}
	}
}

function StartShowAnimation() {
	foreach (className in charactersConst) {
		local chosens = []
		foreach (cards in randomCards)
			if (cards.GetName() == className)
				chosens.append(cards)
		if (chosens.len()!=0)
			showAnimationProps.append(RandomElement(chosens))
	}

	local timers = [
		{ time = 0.10, func = function() {
			Ware_PlaySoundOnAllClients(sound_show1)
			foreach (card in showAnimationProps)
				showAnimationHeads.append(SpawnCardResult(card))
		}},
		{ time = 0.90, func = function() { SetRenderModeAll(showAnimationHeads, 10) }},
		{ time = 1.00, func = function() {
			Ware_PlaySoundOnAllClients(sound_show2)
			SetRenderModeAll(showAnimationHeads, 0)
		}},
		{ time = 1.90, func = function() { SetRenderModeAll(showAnimationHeads, 10) }},
		{ time = 2.0, func = function() {
			Ware_PlaySoundOnAllClients(sound_show1)
			SetRenderModeAll(showAnimationHeads, 0)
		}},
		{ time = 2.90, func = function() {
			SetRenderModeAll(showAnimationHeads, 10)
			foreach (player in Ware_MinigamePlayers)
				player.RemoveCustomAttribute("no_attack")
		}},
	]

	function SetRenderModeAll(heads, mode) {
		foreach (head in heads) {
			SetPropInt(head, "m_nRenderMode", mode)
		}
	}

	foreach (timer in timers) {
		Ware_CreateTimer(timer.func, timer.time)
	}
}

function SpawnCardResult(card)
{
	local origin = card.GetOrigin()
	local head_ent = Ware_SpawnEntity("prop_dynamic_override",
	{
		model          = model_head
		origin         = Vector(origin.x, origin.y-10, origin.z)
        angles         = QAngle(0, 90, 360)
		massscale      = 0.0001
        modelscale     = 9
		disableshadows = true
	})
	head_ent.SetBodygroup(0, charactersConst.find(card.GetName()))
	return head_ent
}

function SpawnCardResultToPlayer(card, player)
{
	local head_ent = Ware_CreateEntity("obj_teleporter")
	local origin = card.GetOrigin()
	head_ent.SetAbsOrigin(Vector(origin.x, origin.y-10, origin.z))
	head_ent.SetAbsAngles(QAngle(0, 90, 360))
	head_ent.DispatchSpawn()
	head_ent.SetModel(model_head)
	head_ent.SetModelScale(9, 0.0)
	head_ent.SetBodygroup(0, charactersConst.find(card.GetName()))
	head_ent.AddEFlags(Constants.FEntityEFlags.EFL_NO_THINK_FUNCTION)
	head_ent.SetSolid(SOLID_NONE)
	SetPropBool(head_ent, "m_bPlacing", true)
	SetPropInt(head_ent, "m_fObjectFlags", 2)
	SetPropEntity(head_ent, "m_hBuilder", player)
}

function CreateRandomCard(name, skin, origin)
{
	local prop = Ware_SpawnEntity("prop_dynamic_override",
	{
		targetname     = name
		model          = model_random
		origin         = origin
        angles         = QAngle(0, 270, 0)
		massscale      = 0.0001
        modelscale     = 5
		disableshadows = true
		skin 		   = skin
	})
	prop.SetCollisionGroup(TFCOLLISION_GROUP_COMBATOBJECT)
    prop.SetSolid(SOLID_BBOX)
    prop.SetSize(Vector(-boxSize, -boxSize, -boxSize), Vector(boxSize, boxSize, boxSize))
	randomCards.append(prop)
}