// by ficool2

class Ware_BotData
{
	function constructor(entity)
	{
		me = entity
		minigame_timers = []
		roam_dest = null

		path = []				
		path_index = 0
		path_target_pos = null
		path_update_time_next = 0.0
		path_update_time_delay = 0.0 
		path_update_force = false	
		path_areas = {}
		stuck = false
		stuck_time = 0.0
		stuck_reset_time = 1e30
	}
	
	me = null
	minigame_timers = null
	roam_dest = null

	path = null
	path_index = null
	path_target_pos = null
	path_update_time_next = null
	path_update_time_delay = null
	path_update_force = null	
	path_areas = null

	stuck				= null
	stuck_time			= null
	stuck_reset_time	= null
	stuck_pos			= null
}

if (!("Ware_Bots" in this))
{
	Ware_Bots <- []
}

SetConvarValue("tf_bot_difficulty", 0)
SetConvarValue("tf_bot_melee_only", 1)
SetConvarValue("tf_bot_sniper_melee_range", -1)
SetConvarValue("tf_bot_reevaluate_class_in_spawnroom", 0)
SetConvarValue("tf_bot_keep_class_after_death", 1)

Ware_BotMinigameBehaviors <- 
{
	type_word = {}
	catch_cubes = {}
	basketball = {}
	jump_rope = {}
	boxing = {}
	dove = {}
	bullseye = {}
	swim_up = {}
	water_war = {}
	type_color = {}
	type_time = {}
	type_map = {}
	watch_fall = {}
	wanted = {}
	trivia = {}
	treasure_hunt = {}
	touch_sky = {}
	time_jump = {}
	taunt_kill = {}
	sumo = {}
	stun = {}
	street_fighter = {}
	stay_ground = {}
	stand_near = {}
	spycrab = {}
	flipper_ball = {}
	piggyback = {}
	airblast = {}
	airshot = {}
	avoid_props = {}
	avoid_trains = {}
	backstab = {}	
	bombs = {}
	break_barrel = {}
	break_box = {}
	bumpers = {}
	caber_king = {}
	cap = {}
	catch_money = {}
	count_bombs = {}
	change_class = {}
	destroy_barrels = {}
	math = {}
	pop_jack = {}
	projectile_jump = {}
	needle_jump = {}
	halloween_fight = {}
	melee_arena = {}
	hit_balls = {}
	hit_player = {}
	headshot = {}
	sniper_war = {}
	dodge_laser = {}
	dont_touch = {}
	eat_plate = {}
	shark = {}
	ghost = {}
	grapple_player = {}
	grapple_cutout = {}
	shoot_gifts = {}
	shoot_barrel = {}
	cuddly_heavies = {}
	flood = {}
	falling_platforms = {}
	wild_west = {}
	limbo = {}
	pickup_can = {}
	build_this = {}
	typing = {}
}

Ware_BotMinigameBehavior <- null

function Ware_BotLoadBehaviors()
{
	foreach (minigame, scope in Ware_BotMinigameBehaviors)
	{
		local file_name = "tf2ware_ultimate/botbehavior/minigames/" + minigame	
		try
		{			
			IncludeScript(file_name, scope)	
		}
		catch (e)
		{
			Ware_Error("Failed to load '%s.nut'. Missing from disk or syntax error", path)
		}
	}
}

function Ware_BotSetup(bot)
{
	// disables visibility of enemies
	bot.AddBotAttribute(IGNORE_ENEMIES)
	bot.SetMaxVisionRangeOverride(0.01)
	// makes spies not attempt to cloak
	bot.SetMissionTarget(Ware_IncursionDummy)
	// set MISSION_SNIPER which effectively does nothing
	bot.SetMission(3, true)
	bot.GetScriptScope().bot_data <- Ware_BotData(bot)
	
	if (Ware_Bots.find(bot) == null)
		Ware_Bots.append(bot)
}

function Ware_BotDestroy(bot)
{
	local bot_data = bot.GetScriptScope().bot_data
	foreach (timer in bot_data.minigame_timers)
		KillTimer(timer)
}

function Ware_BotUpdate()
{
	if (Ware_Minigame 
		&& Ware_BotMinigameBehavior
		&& "OnUpdate" in Ware_BotMinigameBehavior)
	{
		foreach (bot in Ware_Bots)
			Ware_BotMinigameBehavior.OnUpdate(bot)
	}
	else
	{
		// TODO roam around
		foreach (bot in Ware_Bots)
			Ware_BotRoam(bot)
	}
}	


function ForceTaunt(player, taunt_id)
{
  	if (player.IsTaunting()) return

	local weapon = Entities.CreateByClassname("tf_weapon_bat")
	local active_weapon = player.GetActiveWeapon()
	player.StopTaunt(true) // both are needed to fully clear the taunt
	player.RemoveCond(7)
	weapon.DispatchSpawn()
	NetProps.SetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", taunt_id)
	NetProps.SetPropBool(weapon, "m_AttributeManager.m_Item.m_bInitialized", true)
	NetProps.SetPropBool(weapon, "m_bForcePurgeFixedupStrings", true)
	NetProps.SetPropEntity(player, "m_hActiveWeapon", weapon)
	NetProps.SetPropInt(player, "m_iFOV", 0) // fix sniper rifles
	player.HandleTauntCommand(0)
	NetProps.SetPropEntity(player, "m_hActiveWeapon", active_weapon)
	weapon.Kill()
}


function Ware_BotRoam(bot)
{
	local bot_data = bot.GetScriptScope().bot_data
	local data = Ware_GetPlayerMiniData(bot)

	local arr = Shuffle(Ware_MinigamePlayers)
	if (bot_data.roam_dest == null)
	{
		foreach (prop in arr)
		{
			if (prop && prop.IsPlayer())
			{
				local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
				bot_data.roam_dest = dest
				//DebugDrawLine(bot.GetOrigin(), data.dest,	255, 0, 0, true, 1)
				break
			}
		}
	}
	if (bot_data.roam_dest)
	{
		BotLookAt(bot, bot_data.roam_dest, 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(bot_data.roam_dest)
        loco.Approach(bot_data.roam_dest, 999.0)
		if (RandomInt(0,500) == 0)
			bot.PressFireButton(-1)
		local passed = Ware_GetPlayerData(bot).passed

		if(!passed)
		{
			if (RandomInt(0,2000) == 0)
				ForceTaunt(bot, 31413) //mourning
		}
		else
		{
			local taunts = [0, 167, 463, 1118, 1157]
			if (RandomInt(0,1000) == 0)
				ForceTaunt(bot, RandomElement(taunts))
		}
        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
		local dist = VectorDistance(bot_data.roam_dest, bot.GetCenter())
		//Ware_ChatPrint(null, "{int}", dist2)
		if (dist < 50)
			bot_data.roam_dest = null
	}

}


function Ware_BotOnMinigameStart()
{
	if (Ware_Minigame.file_name in Ware_BotMinigameBehaviors)
	{
		Ware_BotMinigameBehavior = Ware_BotMinigameBehaviors[Ware_Minigame.file_name]
	
		if ("OnStart" in Ware_BotMinigameBehavior)	
		{
			foreach (bot in Ware_Bots)
				Ware_BotMinigameBehavior.OnStart(bot)
		}
	}
	else
	{
		Ware_BotMinigameBehavior = null
	}
}

function Ware_BotOnMinigameEnd()
{
	foreach (bot in Ware_Bots)
	{
		local bot_data = bot.GetScriptScope().bot_data
		foreach (timer in bot_data.minigame_timers)
			KillTimer(timer)		
		bot_data.minigame_timers.clear()

		if ("OnEnd" in Ware_BotMinigameBehavior)	
		{
			Ware_BotMinigameBehavior.OnEnd(bot)
		}
		BotResetPath(bot)
	}
}

function Ware_BotCreateMinigameTimer(bot, callback, delay)
{
	local timer = CreateTimer(callback, delay)
	bot.GetScriptScope().bot_data.minigame_timers.append(timer)
	return timer
}

function Ware_BotTryWordTypo(bot, text, chance)
{
	// TODO higher typo chance with longer word
	
	if (RandomFloat(0.0, 1.0) > chance)
		return text
	
	if (text.len() < 2)
		return text
		
	local i = RandomInt(0, text.len() - 2)
	local chars = text.toupper() == text ? text.tolower() : text
	local type = RandomInt(0, 3)
	
	switch (type)
	{
		case 0: // swap
		{
			local tmp = chars[i]
			chars = chars.slice(0, i) + chars[i + 1].tochar() + tmp.tochar() + chars.slice(i + 2)
			break;
		}
		case 1: // omit
		{
			chars = chars.slice(0, i) + chars.slice(i + 1)
			break
		}
		case 2: // repeat
		{
			chars = chars.slice(0, i) + chars[i].tochar() + chars[i].tochar() + chars.slice(i + 1)
			break
		}
		case 3: // wrong
		{
			local keyboard = "abcdefghijklmnopqrstuvwxyz"
			local wrongChar = keyboard[RandomInt(0, keyboard.len() - 1)]
			chars = chars.slice(0, i) + wrongChar.tochar() + chars.slice(i + 1)
			break
		}
	}

	return chars
}


function BotLookAt(bot, target_pos, min_rate, max_rate)
{
    local cur_pos = bot.GetOrigin()
    local cur_vel = bot.GetAbsVelocity()
    local cur_speed = cur_vel.Length()
    local cur_eye_pos = bot.EyePosition()
    local cur_eye_ang = bot.EyeAngles()
    local cur_eye_fwd = cur_eye_ang.Forward()

    local dt = TICKDT
    local dir = target_pos - cur_eye_pos
    dir.Norm()
    local dot = cur_eye_fwd.Dot(dir)
    
    local desired_angles = VectorAngles(dir)	
    
    local rate_x = RemapValClamped(fabs(NormalizeAngle(cur_eye_ang.x) - NormalizeAngle(desired_angles.x)), 0.0, 180.0, min_rate, max_rate)
    local rate_y = RemapValClamped(fabs(NormalizeAngle(cur_eye_ang.y) - NormalizeAngle(desired_angles.y)), 0.0, 180.0, min_rate, max_rate)

    if (dot > 0.7)
    {
        local t = RemapValClamped(dot, 0.7, 1.0, 1.0, 0.05)
        local d = sin(1.57 * t) // pi/2
        rate_x *= d
        rate_y *= d
    }

    cur_eye_ang.x = NormalizeAngle(ApproachAngle(desired_angles.x, cur_eye_ang.x, rate_x * dt))
    cur_eye_ang.y = NormalizeAngle(ApproachAngle(desired_angles.y, cur_eye_ang.y, rate_y * dt))
        
    bot.SnapEyeAngles(cur_eye_ang)
}

//AI generated, please improve (?)
function BotCalculateAimPosition(launchOrigin, targetPos, targetVel, launchSpeed, gravity_multiplier) {
    local base_gravity = 800.000061
    local g = -base_gravity * gravity_multiplier
    local iterations = 3
    local T = (targetPos - launchOrigin).Length() / launchSpeed
    local gravityVec = Vector(0, 0, g) // Corrected to use positive g for downward gravity

    if (gravity_multiplier == 0.0) 
	{
    	// Handle zero gravity (projectile moves in straight line)
		local finalPos = null

    	T = (targetPos - launchOrigin).Length() / launchSpeed
    	for (local i = 0; i < iterations; i++) 
		{
    	    finalPos = targetPos + targetVel * T
    	    T = (finalPos - launchOrigin).Length() / launchSpeed
    	}
    	finalPos = targetPos + targetVel * T
	

    	DebugDrawLine(launchOrigin, finalPos, 0, 0, 255, true, 0.125)
        return finalPos
    } 
    else 
	{
        // Gravity-affected trajectory
        local lastValidT = T
        local lastValidPos = targetPos + targetVel * T
        local hadValidSolution = false

        for (local i = 0; i < iterations; i++) 
		{
            local predictedPos = targetPos + targetVel * T
            local toTarget = predictedPos - launchOrigin
            
            local gSquared = g * g
            local b = launchSpeed * launchSpeed - toTarget.z * g // Corrected b calculation
            local discriminant = b * b - gSquared * toTarget.LengthSqr()
            
            if (discriminant >= 0) 
			{
                hadValidSolution = true
                lastValidT = T
                lastValidPos = predictedPos
                local discRoot = sqrt(discriminant)
                T = sqrt((b - discRoot) * 2.0 / gSquared)
            }
            else 
			{
                // Use last valid solution if available
                if (hadValidSolution) 
				{
                    T = lastValidT
                }
                break
            }
        }

        // Calculate vertical drop compensation
        local verticalDrop = 0.5 * -g * lastValidT * lastValidT
        local finalPos = lastValidPos + Vector(0, 0, verticalDrop)
        
        DebugDrawLine(launchOrigin, finalPos, 0, 0, 255, true, 0.125)
        return finalPos
    }
}

function GetWeaponShootPosition(player)
{
	local weapon = player.GetActiveWeapon()
	local offset = null

	switch (NetProps.GetPropInt(weapon, "m_AttributeManager.m_Item.m_iItemDefinitionIndex"))
	{
	case 441: // The Cow Mangler
		offset = Vector(23.5, 8.0, player.GetFlags() & Constants.FPlayer.FL_DUCKING ? 8.0 : -3.0)
		break
	case 513: // The Original
		offset = Vector(23.5, 0.0, player.GetFlags() & Constants.FPlayer.FL_DUCKING ? 8.0 : -3.0)
		break
	case 18: // Rocket Launcher
	case 127: // The Direct Hit
	case 1104: // The Air Strike
	case 205: // Rocket Launcher (Renamed/Strange)
	case 228: // The Black Box
	case 237: // Rocket Jumper
	case 414: // The Liberty Launcher
	case 658: // Festive Rocket Launcher
	case 730: // The Beggar's Bazooka
	case 800: // Silver Botkiller Rocket Launcher Mk.I
	case 809: // Gold Botkiller Rocket Launcher Mk.I
	case 889: // Rust Botkiller Rocket Launcher Mk.I
	case 898: // Blood Botkiller Rocket Launcher Mk.I
	case 907: // Carbonado Botkiller Rocket Launcher Mk.I
	case 916: // Diamond Botkiller Rocket Launcher Mk.I
	case 965: // Silver Botkiller Rocket Launcher Mk.II
	case 974: // Gold Botkiller Rocket Launcher Mk.II
	case 1085: // Festive Black Box
	case 15006: // Woodland Warrior
	case 15014: // Sand Cannon
	case 15028: // American Pastoral
	case 15043: // Smalltown Bringdown
	case 15052: // Shell Shocker
	case 15057: // Aqua Marine
	case 15081: // Autumn
	case 15104: // Blue Mew
	case 15105: // Brain Candy
	case 15129: // Coffin Nail
	case 15130: // High Roller's
	case 15150: // Warhawk
	case 39: // The Flare Gun
	case 351: // The Detonator
	case 595: // The Manmelter
	case 740: // The Scorch Shot
	case 1081: // Festive Flare Gun
		offset = Vector(23.5, 12.0, player.GetFlags() & Constants.FPlayer.FL_DUCKING ? 8.0 : -3.0)
		break
	case 56: // Hunstman
	case 1005: // Festive Huntsman
	case 1092: // The Fortified Compound
	case 997: // Rescue Ranger
	case 305: // Crusader's Crossbow
	case 1079: // Festive Crusader's Crossbow
		offset = Vector(23.5, 12.0, -3.0)
		break
	case 442: // The Righteous Bison
	case 588: // The Pomson 6000
		offset = Vector(23.5, 8.0, player.GetFlags() & Constants.FPlayer.FL_DUCKING ? 8.0 : -3.0)
		break
	case 222: // The Mad Milk
	case 1121: // Mutated Milk
	case 1180: // Gas Passer
	case 58: // Jarate
	case 751: // Festive Jarate
	case 1105: // The Self-Aware Beauty Mark
	case 19: // Grenade Launcher
	case 206: // Grenade Launcher (Renamed/Strange)
	case 308: // The Loch-n-Load
	case 996: // The Loose Cannon
	case 1007: // Festive Grenade Launcher
	case 1151: // The Iron Bomber
	case 15077: // Autumn
	case 15079: // Macabre Web
	case 15091: // Rainbow
	case 15092: // Sweet Dreams
	case 15116: // Coffin Nail
	case 15117: // Top Shelf
	case 15142: // Warhawk
	case 15158: // Butcher Bird
	case 20: // Stickybomb Launcher
	case 207: // Stickybomb Launcher (Renamed/Strange)
	case 130: // The Scottish Resistance
	case 265: // Sticky Jumper
	case 661: // Festive Stickybomb Launcher
	case 797: // Silver Botkiller Stickybomb Launcher Mk.I
	case 806: // Gold Botkiller Stickybomb Launcher Mk.I
	case 886: // Rust Botkiller Stickybomb Launcher Mk.I
	case 895: // Blood Botkiller Stickybomb Launcher Mk.I
	case 904: // Carbonado Botkiller Stickybomb Launcher Mk.I
	case 913: // Diamond Botkiller Stickybomb Launcher Mk.I
	case 962: // Silver Botkiller Stickybomb Launcher Mk.II
	case 971: // Gold Botkiller Stickybomb Launcher Mk.II
	case 1150: // The Quickiebomb Launcher
	case 15009: // Sudden Flurry
	case 15012: // Carpet Bomber
	case 15024: // Blasted Bombardier
	case 15038: // Rooftop Wrangler
	case 15045: // Liquid Asset
	case 15048: // Pink Elephant
	case 15082: // Autumn
	case 15083: // Pumpkin Patch
	case 15084: // Macabre Web
	case 15113: // Sweet Dreams
	case 15137: // Coffin Nail
	case 15138: // Dressed to Kill
	case 15155: // Blitzkrieg
		offset = Vector(16.0, 8.0, -6.0)
		break
	case 17: // Syringe Gun
	case 204: // Syringe Gun (Renamed/Strange)
	case 36: // The Blutsauger
	case 412: // The Overdose
		offset = Vector(16.0, 6.0, -8.0)
		break
	case 812: // The Flying Guillotine
	case 833: // The Flying Guillotine (Genuine)
		offset = Vector(32.0, 0.0, 15.0)
		break
	case 528: // The Short Curcuit
		offset = Vector(40.0, 15.0, -10.0)
		break
	case 44: // Sandman
	case 648: // The Wrap Assassin
		return player.GetOrigin() + player.GetModelScale() *
				(player.EyeAngles().Forward() * 32.0 + Vector(0.0, 0.0, 50.0))
	default:
		return player.EyePosition()
	}

	if (Convars.GetClientConvarValue("cl_flipviewmodels", player.entindex()) == "1")
		offset.y *= -1

	local eye_angles = player.EyeAngles()
	return player.EyePosition() +
			eye_angles.Up() * offset.z +
			eye_angles.Left() * offset.y +
			eye_angles.Forward() * offset.x
}


function Ware_BotAvoidProp(bot, prop, dist, look = true, attack = true)
{
    local botOrigin = bot.GetOrigin()

    if (prop)
    {
        local escape_dist = dist
        local propOrigin = prop.GetOrigin()
        
        // Calculate direction from prop to bot and extend it further
        local escapeDir = botOrigin - propOrigin
        escapeDir.z = 0
		escapeDir.Norm()
        local dest = botOrigin + escapeDir * escape_dist  // Move 200 units further away from prop
        
        //Ware_ChatPrint(null, "{int} {int}", botOrigin, escapeDir)

		if(look)
		{
			loco.FaceTowards(dest)
			BotLookAt(bot, dest, 9999.0, 9999.0)
		}

        local loco = bot.GetLocomotionInterface()


        DebugDrawLine(botOrigin, dest, 0, 0, 255, true, 0.125)

        // Only move if too close to prop
        if(VectorDistance2D(botOrigin, propOrigin) < escape_dist)
            loco.Approach(dest, 999.0)

        if (attack && RandomInt(0,10) == 0)
            bot.PressFireButton(-1)
    }
}


function Ware_BotShootTarget(bot, dest, shoot = true, approach = false, jump = false)
{
    if (dest)
    {
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(dest)
		BotLookAt(bot, dest, 9999.0, 9999.0)
		
		if (approach)
        	loco.Approach(dest, 999.0)
		if (shoot && RandomInt(0,4) == 0)
			bot.PressFireButton(-1)
		if (jump && RandomInt(0,50) == 0)
            loco.Jump()

		//DebugDrawLine(bot.GetOrigin(), dest, 0, 0, 255, true, 0.125)

    }
}

function Ware_BotShootShuffledPlayers(bot)
{
	local prop
	local data = Ware_GetPlayerMiniData(bot)

	local arr = Shuffle(Ware_MinigamePlayers)
	if (!("dest" in data) || data.dest == null)
	{
		if (!("prop" in data) || data.prop == null || !data.prop.IsValid() || !data.prop.IsAlive())
		{
			foreach (prop in arr)
			{
				if (prop && prop.IsPlayer() && (prop.GetTeam() != bot.GetTeam()))
				{

					local dest = prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
					data.dest <- dest
					data.prop <- prop
					//DebugDrawLine(bot.GetOrigin(), data.dest,	255, 0, 0, true, 1)
					break
				}
			}
		}
		else
		{
			local dest = data.prop.GetCenter() + Vector(RandomFloat(-33,33), RandomFloat(-33,33), 0)
			data.dest <- dest
		}
	}
	if (data.prop)
	{
		BotLookAt(bot, data.prop.GetCenter(), 9999.0, 9999.0)
        local loco = bot.GetLocomotionInterface()
        loco.FaceTowards(data.prop.GetCenter())
        loco.Approach(data.prop.GetCenter(), 999.0)
		if (RandomInt(0,1) == 0)
			bot.PressFireButton(-1)
        //if (RandomInt(0,50) == 0)
        //    loco.Jump()
		local dist = VectorDistance(data.dest, bot.GetCenter())
		local dist2 = VectorDistance(data.prop.GetCenter(), data.dest)
		//Ware_ChatPrint(null, "{int}", dist2)
		if (dist < 50 || dist2 > 200)
			data.dest = null
	}

}

::BotPathPoint <- class
{
	constructor(area, pos, how)
	{
		this.area = area
		this.pos = pos
		this.how = how
	}

	area = null
	pos = null
	how = null
}

function BotUpdatePath(bot, target)
{
	local bot_data = bot.GetScriptScope().bot_data

	BotResetPath(bot)
	bot_data.path_target_pos = target
	local pos_start = bot.GetOrigin() + Vector(0, 0, 1)
	local pos_end = bot_data.path_target_pos + Vector(0, 0, 1)
	
	local area_start = NavMesh.GetNavArea(pos_start, 128.0)
	local area_end = NavMesh.GetNavArea(pos_end, 128.0)
	if (area_start == null)
		area_start = NavMesh.GetNearestNavArea(pos_start, 512.0, false, false)
	if (area_end == null)
		area_end = NavMesh.GetNearestNavArea(pos_end, 512.0, false, false)
	if (area_start == null || area_end == null)
		return false
	if (area_start == area_end)
	{
		bot_data.path.append(BotPathPoint(area_end, pos_end, NUM_TRAVERSE_TYPES))
		return true
	}
	
	if (!NavMesh.GetNavAreasFromBuildPath(area_start, area_end, pos_end, 0.0, TEAM_ANY, false, bot_data.path_areas))
		return false
	if (bot_data.path_areas.len() == 0)
		return false
	local area_target = bot_data.path_areas["area0"]
	local area = area_target
	local area_count = bot_data.path_areas.len()
	for (local i = 0; i < area_count && area != null; i++)
	{
		bot_data.path.append(BotPathPoint(area, area.GetCenter(), area.GetParentHow()))
		area = area.GetParent()
	}
	
	bot_data.path.append(BotPathPoint(area_start, bot.GetOrigin(), NUM_TRAVERSE_TYPES))
	bot_data.path.reverse()
	
	local path_count = bot_data.path.len()
	for (local i = 1; i < path_count; i++)
	{
		local path_from = bot_data.path[i - 1]
		local path_to = bot_data.path[i]
		
		path_to.pos = path_from.area.ComputeClosestPointInPortal(path_to.area, path_to.how, path_from.pos)
	}
	bot_data.path.append(BotPathPoint(area_end, pos_end, NUM_TRAVERSE_TYPES))
}
function BotAdvancePath(bot)
{
	local bot_data = bot.GetScriptScope().bot_data
	local path_len = bot_data.path.len()
	if (path_len == 0)
		return false

	local pos = bot.GetOrigin()
    local loco = bot.GetLocomotionInterface()
    //loco.FaceTowards(path[0].pos)
    //loco.Approach(path[0].pos, 999.0)
    for (local i = bot_data.path_index;i < path_len; i++)
    {
		local p = bot_data.path[i]
        DebugDrawLine(pos, p.pos, 0, 255, 0, true, 0.125)
        pos = p.pos
    }

	if (bot_data.path_index >= path_len)
	{
		BotResetPath(bot)
		return false
	}
	if ((bot_data.path[bot_data.path_index].pos - bot.GetOrigin()).Length() < 32.0)
	{
		bot_data.path_index++
		if (bot_data.path_index >= path_len)
		{
			BotResetPath(bot)
			return false
		}
	}
	return true
}
function BotResetPath(bot)
{
	local bot_data = bot.GetScriptScope().bot_data
	bot_data.path_areas.clear()
	bot_data.path.clear()
	bot_data.path_index = 0
	bot_data.path_target_pos = null
}
function BotMove(bot, target)
{
	local bot_data = bot.GetScriptScope().bot_data
	local time = Time()
	local cur_pos = bot.GetOrigin()

	if (bot_data.path_update_force)
	{
		BotUpdatePath(bot, target)
		bot_data.path_update_force = false
	}
	else if (bot_data.path_update_time_next <= time)
	{
		if (bot_data.path_target_pos == null)
		{
			BotUpdatePath(bot, target)
			bot_data.path_update_time_next = time + 1.0 //PATH_UPDATE_INTERVAL
		}
	}
	if (BotAdvancePath(bot))
	{
		local path_pos = bot_data.path[bot_data.path_index].pos	
		local strafe_dir = Vector(0.0, 0.0, 0.0)
		local strafe_length = 0.0
		
		if (bot_data.stuck)
		{
			local cur_eye_ang = bot.EyeAngles()
			local cur_eye_fwd = cur_eye_ang.Forward()

			strafe_dir = cur_eye_fwd.Cross(Vector(0.0, 0.0, 1.0))
			strafe_length = RandomFloat(24.0, 32.0)
			if (RandomInt(0, 1) > 0)
				strafe_length *= -1.0
		}
			
		local path_pos = bot_data.path[bot_data.path_index].pos + strafe_dir * strafe_length

		local loco = bot.GetLocomotionInterface()
		loco.FaceTowards(path_pos)
		loco.Approach(path_pos, 1.0)


		if (bot_data.stuck_time < time)
		{
			if (bot_data.stuck_time > 0.0 && (bot_data.stuck_pos - cur_pos).Length2DSqr() < 676.0) // 26
			{
				bot_data.stuck = true;
				
				if (bot_data.stuck_reset_time < time)
				{
					BotResetPath(bot)
				}
				else if (bot_data.stuck_reset_time == 1e30)
				{
					bot_data.stuck_reset_time = time + 2.5
				}
			}
			else
			{
				bot_data.stuck = false;
				bot_data.stuck_reset_time = 1e30
			}
			
			bot_data.stuck_pos = cur_pos
			bot_data.stuck_time = time + 1.0
		}	
	}
}