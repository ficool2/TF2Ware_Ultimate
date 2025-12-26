hour <- 0
minute <- 0
accepted_text <- []
first <- true

minigame <- Ware_MinigameData
({
	name           = "Say the Time"
	author         = "ficool2"
	description    = "Say the time!"
	duration       = 7.0
	location       = "dirtsquare"
	music          = "countdown"
	start_freeze   = 0.5
})

clock_model <- "models/tf2ware_ultimate/clock.mdl"

function OnPrecache()
{
	PrecacheModel(clock_model)
}

function GetClockPosition()
{
	return Ware_MinigameLocation.center + Vector(0, 600, 320)
}

function OnTeleport(players)
{
	Ware_TeleportPlayersRow(players, 
		Ware_MinigameLocation.center - Vector(0, 400, 0), 
		QAngle(-10, 90, 0), 
		700.0, 
		69.0, 64.0)
		
	local clock_pos = GetClockPosition()
	foreach (player in players)
	{
		local eye_pos = player.EyePosition()
		local dir = clock_pos - eye_pos
		dir.Norm()
		
		local angles = VectorAngles(dir)
		angles.x = AngleNormalize(angles.x)
		angles.y = AngleNormalize(angles.y)
		player.SnapEyeAngles(angles)
	}
}

function OnStart()
{
	while (hour == minute)
	{
		if (RandomInt(1, 10) > 1)
			minute = (RandomInt(0, 6) * 10) % 60
		else
			minute = (RandomInt(0, 12) * 5) % 60
		hour = RandomInt(0, 12) % 12
	}
	
	local h = hour.tostring()
	local m = minute.tostring()
	
	// standardize single-digit to 0h or 0m format
	local hh = h.len() == 1 ? "0" + h : h
	local mm = m.len() == 1 ? "0" + m : m
	
	if (minute == 0)
		accepted_text.append(h)           // "h"
	
	accepted_text.append(h + ":" + m)     // "h:m"
	accepted_text.append(h + ":" + mm)    // "h:mm"
	accepted_text.append(hh + ":" + m)    // "hh:m"
	accepted_text.append(hh + ":" + mm)   // "hh:mm"
	accepted_text.append(h + " " + m)     // "h m"
	accepted_text.append(h + " " + mm)    // "h mm"
	accepted_text.append(hh + " " + m)    // "hh m"
	accepted_text.append(hh + " " + mm)   // "hh mm"
	accepted_text.append(h + m)           // "hm"
	accepted_text.append(hh + mm)         // "hhmm"
	
	// accept AM/PM ambiguity
	local ahh = (hour + 12).tostring()
	
	if (minute == 0)
		accepted_text.append(ahh)         // "ahh"
	
	accepted_text.append(ahh + ":" + m)   // "ahh:m"
	accepted_text.append(ahh + ":" + mm)  // "ahh:m"
	accepted_text.append(ahh + " " + m)   // "ahh m"
	accepted_text.append(ahh + " " + mm)  // "ahh m"
	accepted_text.append(ahh + m)         // "ahhm"
	accepted_text.append(ahh + mm)        // "ahhmm"

	local clock = Ware_SpawnEntity("prop_dynamic_override",
	{
		origin = GetClockPosition()
		angles = QAngle(0, 270, 0)
		model  = clock_model
	})
	SetPropBool(clock, "m_bClientSideAnimation", false)
	clock.SetPoseParameter(clock.LookupPoseParameter("minutes"), minute / 60.0)
	clock.SetPoseParameter(clock.LookupPoseParameter("hours"), hour / 12.0 + ((1.0 / 12.0) * minute / 60.0))
	clock.StudioFrameAdvance()
}

function OnEnd()
{
	Ware_ChatPrint(null, "The correct time was {color}{%02d}:{%02d}{color} or {color}{%02d}:{%02d}", 
		COLOR_LIME, hour, minute, TF_COLOR_DEFAULT, COLOR_LIME, hour + 12, minute)
}

function HasDigits(text)
{
	foreach (c in text)
	{
		if (c >= '0' && c <= '9')
			return true
	}
	return false
}

function OnPlayerSay(player, text)
{	
	if (!HasDigits(text))
		return
	
	local clean_text = text.tolower()
	// remove pm/am suffixes
	local idx = clean_text.find("pm")
	if (idx == null)
		idx = clean_text.find("am")
	if (idx != null)
		clean_text = clean_text.slice(0, idx)
	clean_text = rstrip(clean_text)
	
	if (accepted_text.find(clean_text) != null)
	{
		if (player.IsAlive())
		{
			Ware_PassPlayer(player, true)
			if (first)
			{
				Ware_ChatPrint(null, "{player} {color}said the time first!", player, TF_COLOR_DEFAULT)
				Ware_GiveBonusPoints(player)
				first = false
			}
		}
		return false
	}
	else
	{
		if (Ware_IsPlayerPassed(player) || !player.IsAlive())
			return
		
		Ware_SuicidePlayer(player)
	}
}