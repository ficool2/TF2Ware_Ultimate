// by ficool2

// Folded stuff for easier usage
foreach (k, v in NetProps.getclass())
    if (k != "IsValid")
        ROOT[k] <- NetProps[k].bindenv(NetProps)
		
FindByClassname        <- Entities.FindByClassname.bindenv(Entities)
FindByClassnameNearest <- Entities.FindByClassnameNearest.bindenv(Entities)
FindByClassnameWithin  <- Entities.FindByClassnameWithin.bindenv(Entities)
FindByName             <- Entities.FindByName.bindenv(Entities)

SetConvarValue  <- Convars.SetValue.bindenv(Convars)
GetConvarValue  <- Convars.GetStr.bindenv(Convars)

// Return the minimum value of a and b
function Min(a, b)
{
    return (a <= b) ? a : b
}

// Return the maximum value of a and b
function Max(a, b)
{
    return (a >= b) ? a : b
}

// Return a value clamped between the boundaries of min and max
function Clamp(val, min, max)
{
	return (val < min) ? min : (max < val) ? max : val
}

// Round number to the nearest whole integer
function Round(x)
{
    if (x < 0.0)
        return (x - 0.5).tointeger()
    else
        return (x + 0.5).tointeger()
}

// Snap a number or vector to the interval y
function Snap(x, y)
{
	return Round(x / y) * y
}

// Lerp a value linearly between A and B, t being percentage from 0 to 1
function Lerp(a, b, t)
{
    return a + (b - a) * t
}

// Lerp a value quadraticly between A, B, and C, t being percentage from 0 to 1
function LerpQuadratic(a, b, c, t) 
{
	local u = 1.0 - t
	return (a * (u * u)) + (b * (2.0 * u * t)) + (c * (t * t))
}

// Remap a value from the range A - B into C - D
function RemapVal(x, a, b, c, d)
{
	return c + (d - c) * (x - a) / (b - a)
}

// Remap a value from the range A - B into C - D
// If the value is outside of the boundary, it is clamped
function RemapValClamped(v, a, b, c, d)
{
	local cv = (v - a) / (b - a)
	if (cv <= 0.0)
		return c
	if (cv >= 1.0)
		return d
	return c + (d - c) * cv
}

// Normalize an angle into [-180, 180] range
function AngleNormalize(angle)
{
	return (angle + 180.0) % 360.0 - 180.0
}

// Snap a vector to the interval y
function VectorSnap(vec, y)
{
	return Vector(Snap(vec.x, y), Snap(vec.y, y), Snap(vec.z, y))
}

// Get 2D distance between two points
function VectorDistance2D(a, b)
{
	return (a - b).Length2D()
}

// Get 3D distance between two points
function VectorDistance(a, b)
{
	return (a - b).Length()
}

// Converts forward vector to euler angles
function VectorAngles(forward)
{
	local yaw, pitch;
	if (forward.y == 0.0 && forward.x == 0.0)
	{
		yaw = 0.0
		pitch = forward.z > 0.0 ? 270.0 : 90.0
	}
	else
	{
		yaw = atan2(forward.y, forward.x) * RAD2DEG
		if (yaw < 0.0)
			yaw += 360.0
		pitch = atan2(-forward.z, forward.Length2D()) * RAD2DEG
		if (pitch < 0.0)
			pitch += 360.0
	}
	return QAngle(pitch, yaw, 0.0)
}

// Same as VectorAngles but aligned along basis vector
function VectorAngles2(forward, up)
{
	local left = up.Cross(forward)
	left.Norm()	
	local xyDist = forward.Length2D()
	if (xyDist > 0.001)
	{
		return QAngle(
			atan2(-forward.z, xyDist) * RAD2DEG,
			atan2(forward.y, forward.x) * RAD2DEG,
			atan2(left.z, (left.y * forward.x) - (left.x * forward.y)) * RAD2DEG)
	}
	else
	{
		return QAngle(
			atan2(-forward.z, xyDist) * RAD2DEG,
			atan2(-left.x, left.y) * RAD2DEG,
			0.0)
	}	
}

// Returns a valid axis perpendicular to the given unit vector (for cross product)
function VectorPerpendicularAxis(normal)
{
	if (fabs(normal.x) > 1e-4 || fabs(normal.y) > 1e-4)
		return Vector(0, 0, 1)
	else
		return Vector(1, 0, 0)
}

// Ensures quaternion q is within 180 degrees of quaternion p
function QuaternionAlign(p, q)
{
	local qt = Quaternion()
	local px = p.x, py = p.y, pz = p.z, pw = p.w, qx = q.x, qy = q.y, qz = q.z, qw = q.w
	local a = (px - qx) * (px - qx) + (py - qy) * (py - qy) + (pz - qz) * (pz - qz) + (pw - qw) * (pw - qw)
	local b = (px + qx) * (px + qx) + (py + qy) * (py + qy) + (pz + qz) * (pz + qz) + (pw + qw) * (pw + qw)
	if (a > b)
	{
		qt.x = -qx; qt.y = -qy; qt.z = -qz; qt.w = -qw
	}
	else
	{
		qt.x = qx; qt.y = qy; qt.z = qz; qt.w = qw
	}
	return qt
}

// Fast but inaccurate quaternion interpolation
function QuaternionBlend(p, q, t)
{
	q = QuaternionAlign(p, q)
	local sclp = 1.0 - t
	local qt = Quaternion
	(
		sclp * p.x + t * q.x,
		sclp * p.y + t * q.y,
		sclp * p.z + t * q.z,
		sclp * p.w + t * q.w
	)
	qt.Norm()
	return qt
}

// Returns true if the two AABBs are intersecting
function IntersectBoxBox(a_mins, a_maxs, b_mins, b_maxs) 
{
    return (a_mins.x <= b_maxs.x && a_maxs.x >= b_mins.x) &&
           (a_mins.y <= b_maxs.y && a_maxs.y >= b_mins.y) &&
           (a_mins.z <= b_maxs.z && a_maxs.z >= b_mins.z)
}

// Performs line segment vs plane intersection test
// If successful, returns point of intersection
// Otherwise returns null
function IntersectLinePlane(start, end, normal, dist)
{
	local dir = end - start
	local d = normal.Dot(dir)
	if (fabs(d) < 1e-6)
		return null
    local t = (dist - normal.Dot(start)) / normal.Dot(dir)
	if (t < 0.0 || t > 1.0)
		return null
    return start + dir * t
}

// Performs ray vs sphere intersection test
// If hit, returns true
function IntersectRayWithSphere(start, dir, center, radius_sqr) 
{
    local oc = start - center
    local a = dir.Dot(dir)
    local b = 2.0 * oc.Dot(dir)
    local c = oc.Dot(oc) - radius_sqr
    local d = b * b - 4.0 * a * c
    return d > 0.0
}

// Performs ray vs AABB intersection test, within [near, far] range
// If hit, returns distance of ray to the box
// Otherwise returns -1
function IntersectRayWithBox(start, dir, mins, maxs, near, far)
{
	if (fabs(dir.x) > 0.0001)
	{
		local recip_dir = 1.0 / dir.x
		local t1 = (mins.x - start.x) * recip_dir
		local t2 = (maxs.x - start.x) * recip_dir		
		if (t1 < t2)
        {
			if (t1 >= near)
				near = t1
			if (t2 <= far)
				far = t2
        }
		else
        {
			if (t2 >= near)
				near = t2
			if (t1 <= far)
				far = t1
        }		
		if (near > far)
			return -1.0
	}
	else if (start.x < mins.x || start.x > maxs.x)
	{
		return -1.0
	}
	
	if (fabs(dir.y) > 0.0001)
	{
		local recip_dir = 1.0 / dir.y
		local t1 = (mins.y - start.y) * recip_dir
		local t2 = (maxs.y - start.y) * recip_dir	
		if (t1 < t2)
        {
			if (t1 >= near)
				near = t1
			if (t2 <= far)
				far = t2
        }
		else
        {
			if (t2 >= near)
				near = t2
			if (t1 <= far)
				far = t1
        }		
		if (near > far)
			return -1.0
	}
	else if (start.y < mins.y || start.y > maxs.y)
	{
		return -1.0
	}

	if (fabs(dir.z) > 0.0001)
	{
		local recip_dir = 1.0 / dir.z
		local t1 = (mins.z - start.z) * recip_dir
		local t2 = (maxs.z - start.z) * recip_dir	
		if (t1 < t2)
        {
			if (t1 >= near)
				near = t1
			if (t2 <= far)
				far = t2
        }
		else
        {
			if (t2 >= near)
				near = t2
			if (t1 <= far)
				far = t1
        }
	}
	else if (start.z < mins.z || start.z > maxs.z)
	{
		return -1.0
	}
	if (near > far)
		return -1.0
      
	return near
}

// Format a vector in Squirrel form
function VectorFormat(vec)
{
	return format("Vector(%g, %g, %g)", vec.x, vec.y, vec.z)
}

// Create an array with integers in a range (inclusive)
function FillArray(a, b)
{
	local arr = []
	for (local i = a; i <= b; i++)
		arr.append(i)
	
	return arr
}

// Randomly shuffle up an array
function Shuffle(arr)
{
	for (local i = arr.len() - 1; i > 0; i--)
	{
		local j = RandomInt(0, i)
		local t = arr[j]
		arr[j] = arr[i]
		arr[i] = t
	}
	return arr
}

// Gets median element from array
function Median(arr)
{
	local n = arr.len()
	if (n % 2 == 0) 
		return (arr[n / 2 - 1] + arr[n / 2]) / 2
	else
		return arr[n / 2]
}

// Return a random index into the array
function RandomIndex(arr)
{
	return RandomInt(0, arr.len() - 1)
}

// Return a random element from the array
function RandomElement(arr)
{
	return arr[RandomIndex(arr)]
}

// Remove and return a random element from the array
function RemoveRandomElement(arr)
{
	return arr.remove(RandomIndex(arr))
}

// Removes an element from an array if found
function RemoveElementIfFound(arr, element)
{
	local idx = arr.find(element)
	if (idx != null)
		arr.remove(idx)
}

// Appends element to the array if not already present
function AppendElementIfUnique(arr, element)
{
	if (arr.find(element) == null)
		arr.append(element)
}

// Returns the given column from a 2D array
function GetElementsColumn(arr, column)
{
	local elements = []
	foreach (elem in arr)
		elements.append(elem[column])
	return elements
}

// Returns either true or false at random
function RandomBool()
{
	return RandomInt(0, 1) == 1
}

// Reverse a string, with color markers fixed up
function ReverseString(str)
{
	local result = ""
	local stack = []
	
	local len = str.len()
	for (local i = 0; i < len; i++) 
	{
		local c = str.slice(i, i + 1)
		if (c == "\x07" && i + 6 < len) 
		{
			// TODO this doesn't work right, no color markers for now
			//stack.push(str.slice(i, i + 7))
			i += 6;
		} 
		else 
		{
			stack.push(c)
		}
	}
	
	len = stack.len()
	for (local i = 0; i < len; i++)
		result += stack.pop()
	
	return result
}

// Safely converts a text to string, returns null if couldn't be converted
function StringToInteger(text)
{
	try
	{
		return text.tointeger()	
	}
	catch (e)
	{
		return null
	}
}

// Converts float timestamp to ticks
function TimeToTicks(time)
{
	return (0.5 + time / TICKDT).tointeger()
}

// Splits the float time into HMS format
// Returns a table of "hours", "minutes" and "seconds"
function FloatToTimeHMS(time)
{
	local h, m, s
	s = Round(time)
	h = s / 3600
	s -= h * 3600
	m = s / 60
	s = s % 60
	return { hours = h, minutes = m, seconds = s }
}

// Formats a float time into minutes:seconds:milliseconds
function FloatToTimeFormat(time)
{
	local minutes = (time / 60).tointeger()
	local seconds = (time % 60).tointeger()
	local milliseconds = ((time - floor(time)) * 1000).tointeger()
	return format("%02d:%02d:%03d", minutes, seconds, milliseconds)
}

// Generates an alphanumeric hash of the specified time
// This is seeded by both the game's RNG routine and current system time
function GenerateHash(length) 
{
    local radix = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
    local radix_len = radix.len()
	
	local tm = {}
    local combined = RandomInt(1, INT_MAX)
	LocalTime(tm)
    combined = (combined * 1 + tm.second) % INT_MAX
    combined = (combined * 10 + tm.minute) % INT_MAX
    combined = (combined * 100 + tm.hour) % INT_MAX
    combined = (combined * 1000 + tm.day) % INT_MAX
   
	local hash = ""  
    for (local i = 0; i < length; i++) 
	{
		local position = i + 1
		local value = combined
		value = value * position + i * 31
		value = value * 17 + 23
		combined = (combined * 31 + value) % INT_MAX
		hash += radix[value % radix_len].tochar()
    }
    
    return hash
}

function CollectGameEventsInScope(scope)
{
	local events = []
	local event_prefix = "OnGameEvent_"
	local event_prefix_len = event_prefix.len()
	foreach (key, value in scope)
	{
		if (typeof(value) == "function"
			&& typeof(key) == "string"
			&& key.find(event_prefix, 0) == 0)
		{
				local event_name = key.slice(event_prefix_len)
				if (event_name.len() > 0)
				{
					if (!(event_name in GameEventCallbacks))
					{
						GameEventCallbacks[event_name] <- []
						RegisterScriptGameEventListener(event_name)
					}
					
					GameEventCallbacks[event_name].push(scope)
					events.append(event_name)
				}
		}
	}	
	return events
}

function ClearGameEventsFromScope(scope, events)
{
	foreach (event_name in events)
	{
		local callbacks = GameEventCallbacks[event_name]
		local idx = callbacks.find(scope)
		if (idx != null)
			callbacks.remove(idx)
	}
	events.clear()
}

// Marks an entity as purged for the stringtable
// For internal use only
function MarkForPurge(entity)
{
	SetPropBool(entity, "m_bForcePurgeFixedupStrings", true)
}

// Precache a model including gibs
function PrecacheModelGibs(model)
{
	PrecacheEntityFromTable({ classname = "tf_generic_bomb", model = model })
}

// Precache a material
function PrecacheMaterial(material)
{
    local entity = SpawnEntityFromTableSafe("vgui_screen", { overlaymaterial = material })
    local index = GetPropInt(entity, "m_nOverlayMaterial")
    entity.Destroy()
    return index
}

// Precache a sprite material
function PrecacheSprite(sprite)
{
	PrecacheModel(sprite)
	return true
}

// Precache an overlay texture
// Do NOT precache shader overlays with this
function PrecacheOverlay(overlay)
{
	PrecacheModel(overlay + ".vmt")
	return true
}

// Precache a particle and returns index
function PrecacheParticle(name)
{
	local particle = SpawnEntityFromTableSafe("info_particle_system", 
	{
		effect_name  = name
		start_active = false
	})
	local index = GetPropInt(particle, "m_iEffectIndex")
	particle.Destroy()
	return index
}

// Create an entity that doesn't leak the stringtable
// Always use this instead of raw Entities.CreateByClassname
function CreateEntitySafe(classname)
{
	local entity = Entities.CreateByClassname(classname)
	MarkForPurge(entity)
	return entity
}

// Spawn an entity that doesn't leak the stringtable
// Always use this instead of raw SpawnEntityFromTable
function SpawnEntityFromTableSafe(classname, keyvalues)
{
	local entity = SpawnEntityFromTable(classname, keyvalues)
	MarkForPurge(entity)
	return entity
}

// Gathers all instances of the specified entity classname
function FindAllOfEntity(classname)
{
	local entities = []
	for (local entity; entity = FindByClassname(entity, classname);)
	{
		MarkForPurge(entity)
		entities.append(entity)
	}
	return entities
}

// Removes all instances of the specified entity classname
function RemoveAllOfEntity(classname)
{
	local entities = FindAllOfEntity(classname)
	foreach (entity in entities)
		entity.Kill()
}

// Removes a think function for an entity
// Works even if called from it's own think function
function RemoveEntityThink(entity)
{
	AddThinkToEnt(entity, null)
	SetPropString(entity, "m_iszScriptThinkFunction", "")
}

// Creates a timer that executes the given function after a delay
// The function may return a float value to repeat the function again after the new delay
// If the function returns nothing or null, the timer is killed
// Returns a handle to the timer, like an entity
function CreateTimer(on_timer_func, delay)
{
	local relay = CreateEntitySafe("logic_relay")
	relay.ValidateScriptScope()
	local relay_scope = relay.GetScriptScope()
	relay_scope.scope <- this
	relay_scope.repeat <- false
	
	SetInputHook(relay, "Trigger", 
	function()
	{
		local delay = (on_timer_func.bindenv(scope))()
		if (delay != null)
		{
			repeat = true
			EntFireByHandle(self, "Trigger", "", delay, null, null)
		}
		return false
	}
	function() 
	{
		if (repeat)
			repeat = false
		else if (self.IsValid()) 
			self.Kill()
	})
	
	EntFireByHandle(relay, "Trigger", "", delay, null, null)
	return relay
}

// Executes the function of a timer
function FireTimer(timer)
{
	if (timer && timer.IsValid())
	{
		timer.GetScriptScope().InputTrigger()
		KillTimer(timer)
	}
}

// Kills the timer, it will not execute any pending function
function KillTimer(timer)
{
	if (timer && timer.IsValid())
	{
		timer.TerminateScriptScope()
		timer.Kill()
	}
}

// Sets an entity's rendering color
function SetEntityColor(entity, r, g, b, a)
{
    local color = (r) | (g << 8) | (b << 16) | (a << 24)
    SetPropInt(entity, "m_clrRender", color)
}

// Convenience wrapper for EntFireByHandle
function EntityEntFire(entity, input, parameter = "", delay = 0.0, activator = null, caller = null)
{
	EntFireByHandle(entity, input, parameter, delay, activator, caller);
}

// Convenience wrapper for AcceptInput
function EntityAcceptInput(entity, input, parameter = "", activator = null, caller = null)
{
	return entity.AcceptInput(input, parameter, activator, caller)
}

// Disable interpolation for an entity on this frame
function EntityMarkTeleport(entity)
{
	SetPropInt(entity, "m_ubInterpolationFrame", (GetPropInt(entity, "m_ubInterpolationFrame") + 1) % 4)
}

// Returns true if the entity is a hat wearable
function IsWearableHat(entity)
{
	if (!startswith(entity.GetClassname(), "tf_wearable"))
		return false
	
	return entity.LookupBone("bip_head") >= 0 || entity.LookupBone("prp_helmet") >= 0
}

// Sets an entity's parent, optionally to a given attachment
// If "parent" is null, the entity is unparented
function SetEntityParent(entity, parent, attachment = null)
{
	if (parent)
	{
		entity.AcceptInput("SetParent", "!activator", parent, null)
		if (attachment)
			entity.AcceptInput("SetParentAttachment", attachment, parent, null)
	}
	else
	{
		entity.AcceptInput("ClearParent", "", null, null)
	}
}

// Sets a player's parent
// Unlike SetEntityParent, this is intended when parenting players to another player
// Prevents the player from going invisible
// If "parent" is null, the player is unparented
function SetPlayerParentPlayer(player, parent, attachment = null)
{
	if (parent)
	{
		SetPropInt(player, "m_fEffects", EF_BONEMERGE|EF_BONEMERGE_FASTCULL)
	}
	else
	{
		SetPropInt(player, "m_fEffects", 0)
		SetPropInt(player, "m_iParentAttachment", 0)
	}
	
	SetEntityParent(player, parent, attachment)
}

// Reset's player heath
// Intended to workaround health being set to 1 after transforming into ghost mode
function PlayerResetHealth()
{
	self.SetHealth(self.GetMaxHealth())
}

// Internal use only
local _PostInputScope = null
local _PostInputFunc  = null

// Sets functions that execute before and/or after a given input is received on the entity
// Both pre_func and post_func are optional
function SetInputHook(entity, input, pre_func, post_func)
{
	entity.ValidateScriptScope()
	local scope = entity.GetScriptScope()
	if (post_func)
	{
		local wrapper_func = function() 
		{ 
			_PostInputScope = scope
			_PostInputFunc  = post_func
			if (pre_func)
				return pre_func.call(scope)
			return true
		}
		
		scope["Input" + input]           <- wrapper_func
		scope["Input" + input.tolower()] <- wrapper_func
	}
	else if (pre_func)
	{
		scope["Input" + input]           <- pre_func
		scope["Input" + input.tolower()] <- pre_func
	}
}

// Internal wrapper for SetInputHook
ROOT.setdelegate(
{
	_delslot = function(k)
	{
		if (_PostInputScope && k == "activator" && "activator" in this)
		{
			_PostInputFunc.call(_PostInputScope)
			_PostInputFunc = null
		}
		
		rawdelete(k)
	}
})

// Plays a sound on the given client
function PlaySoundOnClient(player, name, volume = 1.0, pitch = 100, flags = 0)
{
	EmitSoundEx(
	{
		sound_name = name,
		volume = volume
		pitch = pitch,
		entity = player,
		flags = flags,
		filter_type = RECIPIENT_FILTER_SINGLE_PLAYER
	})
}

// Plays a sound on all clients
function PlaySoundOnAllClients(name, volume = 1.0, pitch = 100, flags = 0)
{
	EmitSoundEx(
	{
		sound_name = name,
		volume = volume
		pitch = pitch,
		flags = flags,
		filter_type = RECIPIENT_FILTER_GLOBAL
	})
}

// Returns true if the handle is the "fake" player for SourceTV or replays
function IsPlayerSourceTV(player)
{
	return PlayerInstanceFromIndex(player.entindex()) == null
}

// Gets a player's chat name
function GetPlayerName(player)
{
    return GetPropString(player, "m_szNetname")
}

// Gets a player's user ID
function GetPlayerUserID(player)
{
    return GetPropIntArray(PlayerMgr, "m_iUserID", player.entindex())
}

// Gets a player's SteamID3, e.g. [U:1234]
function GetPlayerSteamID3(player)
{
    return GetPropString(player, "m_szNetworkIDString")
}

// Gets a player's latency in seconds
function GetPlayerLatency(player)
{
	return GetPropIntArray(PlayerMgr, "m_iPing", player.entindex()) * 0.001;
}

// Prevents a player's score from counting towards stranges
function BrickPlayerScore(player)
{
	// spoof as bot so this doesn't upload stats to steam
	local is_bot = player.IsFakeClient()
	if (!is_bot) 
		player.AddFlag(FL_FAKECLIENT)

	// this bricks the scoreboard score to always be 0
	// so stranges don't get leveled up by our scoreboard manipulation
	SendGlobalGameEvent("player_escort_score", 
	{
		player = player.entindex(),
		points = -9999999
	})

	if (!is_bot) 
		player.RemoveFlag(FL_FAKECLIENT)
}

// Reset chatting cooldown on a player
function ResetPlayerChatCooldown(player)
{
	SetPropFloat(player, "m_fLastPlayerTalkTime", 0.0)
	SetPropFloat(player, "m_flPlayerTalkAvailableMessagesTier1", 2.0)
	SetPropFloat(player, "m_flPlayerTalkAvailableMessagesTier2", 10.0)
}

// Equivalent but for entfire (useful for player_say)
function ResetSelfChatCooldown()
{
	ResetPlayerChatCooldown(self)
}

// Plays a sound on a player, if they are valid and alive
function PlayVocalization(player, sound)
{
	if (player.IsValid() && player.IsAlive())
		player.EmitSound(sound)
}

// Burns a player
function BurnPlayer(player, burn_damage, burn_duration)
{
	local trigger = CreateEntitySafe("trigger_ignite")
	trigger.KeyValueFromInt("spawnflags", 1)
	trigger.KeyValueFromFloat("damage_percent_per_second", burn_damage)
	trigger.KeyValueFromFloat("burn_duration", burn_duration)
	trigger.AcceptInput("StartTouch", "", player, player)
	trigger.Kill()
}

// Heals (or damages) a player
function HealPlayer(player, amount)
{
	if (amount > 0)
	{
		local health = player.GetHealth()
		local max_health = player.GetMaxHealth()
		if (amount > max_health - health)
			amount = max_health - health
		
		if (amount > 0)
		{
			player.SetHealth(health + amount)
			
			SendGlobalGameEvent("player_healonhit",
			{
				amount = amount,
				entindex = player.entindex(),
				weapon_def_index = -1,
			})
		}
	}
	else if (amount < 0)
	{
		SendGlobalGameEvent("player_healonhit",
		{
			amount = amount,
			entindex = player.entindex(),
			weapon_def_index = -1,
		})
		
		player.TakeDamage(amount * -1, DMG_PREVENT_PHYSICS_FORCE, player)
	}
}

// Stop a player's taunt and cancel the taunt cooldown
function ForceRemovePlayerTaunt(player)
{
	player.RemoveCond(TF_COND_TAUNTING)

	// remove the cooldown for next taunt
	// allow this to work in midair
	local ground = GetPropEntity(player, "m_hGroundEntity")
	SetPropEntity(player, "m_hGroundEntity", World)
	player.AddCustomAttribute("gesture speed increase", 99999, -1)
	player.Taunt(TAUNT_BASE_WEAPON, 0)
	player.RemoveCond(TF_COND_TAUNTING)
	player.RemoveCustomAttribute("gesture speed increase")
	SetPropEntity(player, "m_hGroundEntity", ground)
}

// Removes a player's ragdoll, if it exists
function KillPlayerRagdoll(player)
{
	local ragdoll = GetPropEntity(player, "m_hRagdoll")
	if (ragdoll)
	{
		MarkForPurge(ragdoll)
		ragdoll.Kill()
	}
}

// Safely enables or disables a point_viewcontrol to workaround bugs
function TogglePlayerViewcontrol(player, camera, toggle)
{
	if (toggle)
	{
		// viewcontrol makes player invulnerable
		local take_damage = GetPropInt(player, "m_takedamage")	
		camera.AcceptInput("Enable", "", player, player)
		SetPropInt(player, "m_takedamage", take_damage) 		
	}
	else
	{
		// viewcontrol doesn't disable for dead players
		// and sets the wrong damage state
		local take_damage = GetPropInt(player, "m_takedamage")
		local life_state = GetPropInt(player, "m_lifeState")
		SetPropInt(player, "m_lifeState", 0) 
		SetPropEntity(camera, "m_hPlayer", player)	
		camera.AcceptInput("Disable", "", player, player)
		SetPropInt(player, "m_lifeState", life_state) 	
		SetPropInt(player, "m_takedamage", take_damage) 	
	}
}

// Silently kills a player (no kill feed, screams, etc)
function KillPlayerSilently(player)
{
	SetPropInt(player, "m_iObserverLastMode", OBS_MODE_CHASE)
	local team = NetProps.GetPropInt(player, "m_iTeamNum")
	SetPropInt(player, "m_iTeamNum", TEAM_SPECTATOR)
	player.DispatchSpawn()
	SetPropInt(player, "m_iTeamNum", team)
}

// Tries to unstuck a player, assuming they may be stuck in geometry
// Only does tests horizontally
// Returns true if player wasn't stuck or has been unstuck, false otherwise
function UnstuckPlayer(player)
{
	local origin = player.GetOrigin()
	local mins = player.GetPlayerMins()
	local maxs = player.GetPlayerMaxs()
	
	// do a trace to see if they're stuck at all
	local trace = 
	{
		start      = origin
		end        = origin
		hullmin    = mins
		hullmax    = maxs
		mask       = MASK_PLAYERSOLID_BRUSHONLY
		ignore     = player
		startsolid = false
	}
	
	// DebugDrawBox(trace.start, trace.hullmin, trace.hullmax, 255, 255, 255, 15, 10)
	TraceHull(trace)
	if (!trace.hit)
		return true
	
	// trace each direction twice, once in opposite direction
	local nudge_factor = maxs.x - mins.x
	foreach (vec in UnstuckVectors)
	{
		local dir = vec * nudge_factor
		
		// assuming "start" is clear, sweep towards the obstacle
		// so the trace places us as close as possible
		trace.start = origin + dir
		trace.startsolid = false
		
		// DebugDrawBox(trace.start, trace.hullmin, trace.hullmax, 255, 255, 255, 100, 30)
		TraceHull(trace)
		if (!trace.startsolid)
		{
			player.SetAbsOrigin(trace.endpos)
			return true
		}
		
		trace.start = origin - dir
		trace.startsolid = false
		
		// DebugDrawBox(trace.start, trace.hullmin, trace.hullmax, 255, 255, 255, 100, 30)
		TraceHull(trace)
		if (!trace.startsolid)
		{
			player.SetAbsOrigin(trace.endpos)
			return true
		}
	}
	
	return false
}

// Internal use only
UnstuckVectors <-
[
	Vector(1, 0, 0)  // x
	Vector(0, 1, 0)  // y
	Vector(1, 1, 0)  // x+y
	Vector(1, -1, 0) // x-y
]

// Adds a message to the killfeed
function AddKillFeedMessage(victim, attacker, icon)
{
	SendGlobalGameEvent("player_death"
	{
		userid             = GetPlayerUserID(victim)
		victim_entindex    = victim.entindex()
		inflictor_entindex = attacker ? attacker.entindex() : 0
		attacker           = attacker ? GetPlayerUserID(attacker) : 0
		weapon             = icon
		death_flags        = TF_DEATH_FEIGN_DEATH
	})
}

// Removes a weapon, including any attachments it has
function KillWeapon(weapon)
{
	local wearable = GetPropEntity(weapon, "m_hExtraWearable")
	if (wearable)
	{
		MarkForPurge(wearable)
		wearable.Destroy()
	}
	
	wearable = GetPropEntity(weapon, "m_hExtraWearableViewModel")
	if (wearable)
	{
		MarkForPurge(wearable)
		wearable.Destroy()
	}
	
	weapon.Destroy()
}

// Internal use only
if (!("TriggerHurtDisintegrateProxy" in this) || !TriggerHurtDisintegrateProxy.IsValid())
{
	// Spoof an item to create the disintegration effect
    TriggerHurtDisintegrateProxy <- CreateEntitySafe("tf_weapon_bat")
    SetPropInt(TriggerHurtDisintegrateProxy, "m_AttributeManager.m_Item.m_iItemDefinitionIndex", 349)
    SetPropBool(TriggerHurtDisintegrateProxy, "m_AttributeManager.m_Item.m_bInitialized", true)
    TriggerHurtDisintegrateProxy.DispatchSpawn()
	TriggerHurtDisintegrateProxy.DisableDraw()
    TriggerHurtDisintegrateProxy.AddAttribute("ragdolls become ash", 1, -1)
	TriggerHurtDisintegrateProxy.KeyValueFromString("classname", "ware_disintegrate")
}
  
// Trigger hurt effect used by the map
function TriggerHurtSmack()
{
	self.TakeDamage(1000, DMG_BULLET, activator)
}

// Trigger hurt effect used by the map
function TriggerHurtDisintegrate()
{
	if (self.IsValid()) // safety check otherwise this will crash
	{
		if (self.IsPlayer())
		{
			SetPropEntity(TriggerHurtDisintegrateProxy, "m_hOwner", self)
			self.EmitSound("Fire.Engulf")
			self.TakeDamageCustom(
				caller, self, TriggerHurtDisintegrateProxy, 
				Vector(), Vector(), 
				1000, DMG_BURN, TF_DMG_CUSTOM_BURNING)
		}
		else
		{
			self.TakeDamage(1000, DMG_BURN, caller)
		}
	}
}

// Think function that does nothing (workaround for MOVETYPE_PUSH bug)
function ThinkDummy()
{
	return -1
}

// Think function that removes itself when the current animation is done
function ThinkAdvanceAnimUntilEnd()
{
	self.StudioFrameAdvance()
	if (self.GetCycle() == 1.0)
		RemoveEntityThink(self)
	return 0.05 // minimum interpolation
}

// Draw coordinate axes at given position
function DebugDrawAxes(pos, size, no_depth_test, duration)
{
	DebugDrawLine(
		pos + Vector(-size, 0, 0), 
		pos + Vector(size, 0, 0),
		255, 0, 0, no_depth_test, duration)
	DebugDrawLine(
		pos + Vector(0, -size, 0), 
		pos + Vector(0, size, 0),
		0, 255, 0, no_depth_test, duration)
	DebugDrawLine(
		pos + Vector(0, 0, -size), 
		pos + Vector(0, 0, size),
		0, 0, 255, no_depth_test, duration)
}

// Draw text representing the vector at it's position
function DebugDrawVector(vec, no_depth_test, duration)
{
	DebugDrawText(vec, format("(%g %g %g)", vec.x, vec.y, vec.z), no_depth_test, duration)
}

// Prints specified levels of call stack
function DumpCallstack(levels = 16)
{
	for (local level = 2; level < levels; level++)
	{
		local s = getstackinfos(level)
		if (!s)
			break
		printf("\t%s (line %d) [%s]\n",  s.func, s.line, s.src)
	}
}