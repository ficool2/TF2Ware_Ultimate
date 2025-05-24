// whenever new entries are added, these should be incremented so it's automatically added to server configs
const WARE_MINIGAME_VERSION     = 4
const WARE_BOSSGAME_VERSION     = 1
const WARE_SPECIALROUND_VERSION = 5
const WARE_THEME_VERSION        = 3

// everytime music is changed AND the map is *publicly* updated
// this must be incremented to prevent caching errors
// deprecated: this is bumped automatically when uploading to workshop
const WARE_MUSIC_VERSION = 3

// keep in sync with sourcemod plugin
WARE_PLUGIN_VERSION <- [1, 2, 7]

Ware_CfgPath <- "tf2ware_ultimate/%s.cfg"

function Ware_LoadConfigFile(file_name, scriptdata = true)
{
	// try load the config from "scriptdata" first
	local cfg_name
	if (scriptdata)
	{
		cfg_name = format(Ware_CfgPath, file_name)
		local file = FileToString(cfg_name)
		if (file)
			return file
	}

	// if not found, load it from our default config
	// scriptdata cannot be read when packed into BSP, so it's stored as code
	local scope = {}
	IncludeScript(format("tf2ware_ultimate/default/%s", file_name), scope)
	
	if (scriptdata)
	{
		// write out the default config to scriptdata for future usage
		StringToFile(cfg_name, scope.buffer)
	}
	
	return scope.buffer
}

function Ware_LoadConfigSettings()
{
	// default values (should match settings.cfg)
	// incase they aren't present there
	Ware_BossThreshold        <- 20
	Ware_SpeedUpThreshold     <- 5
	Ware_SpeedUpInterval      <- 0.15
	Ware_SpecialRoundInterval <- 3
	Ware_PointsMinigame       <- 1
	Ware_PointsBossgame       <- 5
	Ware_BonusPoints          <- 0
	Ware_MaxMinigameWeight    <- 0
		
	local settings_map = 
	{
		boss_threshold         = "Ware_BossThreshold"
		speedup_threshold      = "Ware_SpeedUpThreshold"
		speedup_interval       = "Ware_SpeedUpInterval"
		// removed: special_round_chance = "Ware_SpecialRoundChance" 
		specialround_interval  = "Ware_SpecialRoundInterval"
		points_minigame        = "Ware_PointsMinigame"
		points_bossgame        = "Ware_PointsBossgame"
		bonus_points           = "Ware_BonusPoints"
		max_miniweight         = "Ware_MaxMinigameWeight"
	}
	
	local file = Ware_LoadConfigFile("settings")
	local lines = split(file, "\r\n", true)
	foreach (line in lines)
	{
		if (startswith(line, "//"))
			continue
		local keyvalue = split(line, " =", true)
		local key = keyvalue[0]
		if (key in settings_map)
		{
			local value = keyvalue[1]
			this[settings_map[key]] = value.find(".") != null ? value.tofloat() : value.tointeger()
		}
	}
}

function Ware_LoadConfigList(file_name, list, expected_version = 0, version_callback = null)
{
	local file = Ware_LoadConfigFile(file_name)
	local lines = split(file, "\r\n", true)

	// legacy configs had no VERSION header
	local version = 0
	if (lines.len() >= 1)
	{
		if (startswith(lines[0], "VERSION "))
			version = lines.remove(0).slice(8).tointeger()
	}
	
	if (version < expected_version && version_callback)
	{
		version_callback(version, lines)
		Ware_WriteConfigList(file_name, expected_version, lines)
	}	
	
	foreach (line in lines)
	{
		if (!startswith(line, "//"))
			list.append(line)
	}

	return version
}

function Ware_LoadConfigMinigames()
{
	// bump this when new entries are added, and fill in the loop below
	local latest_version = WARE_MINIGAME_VERSION
	Ware_LoadConfigList("minigames", Ware_Minigames, latest_version, function(version, lines)
	{
		for (local v = version + 1; v <= latest_version; v++)
		{
			switch (v)
			{
				case 2:
					AppendElementIfUnique(lines, "airshot")
					AppendElementIfUnique(lines, "destroy_barrels")
					AppendElementIfUnique(lines, "heavy_medic")
					AppendElementIfUnique(lines, "vacc")
					// this was supposed to be under v1 but forgot to add it in default config
					AppendElementIfUnique(lines, "type_map")
					break
				case 3:
					AppendElementIfUnique(lines, "wanted")
					AppendElementIfUnique(lines, "pickup_can")
					break
				case 4:
					RemoveElementIfFound(lines, "heavy_medic")
					AppendElementIfUnique(lines, "buff")
					AppendElementIfUnique(lines, "cap")
					AppendElementIfUnique(lines, "dove")
					AppendElementIfUnique(lines, "floppy")
					AppendElementIfUnique(lines, "intel")
					AppendElementIfUnique(lines, "needle_jump")
					AppendElementIfUnique(lines, "time_jump")		
					AppendElementIfUnique(lines, "uber")
					AppendElementIfUnique(lines, "upgrade")			
					break
			}
		}
	})
}

function Ware_LoadConfigBossgames()
{
	// bump this when new entries are added, and fill in the loop below
	local latest_version = WARE_BOSSGAME_VERSION
	Ware_LoadConfigList("bossgames", Ware_Bossgames, latest_version, function(version, lines)
	{
		for (local v = version + 1; v <= latest_version; v++)
		{
			switch (v)
			{
				case 1:
					// we winga
					AppendElementIfUnique(lines, "wega_challenge")
					break
			}
		}
	})
}

function Ware_LoadConfigSpecialRounds()
{
	// bump this when new entries are added, and fill in the loop below
	local latest_version = WARE_SPECIALROUND_VERSION
	Ware_LoadConfigList("specialrounds", Ware_SpecialRounds, latest_version, function(version, lines)
	{
		for (local v = version + 1; v <= latest_version; v++)
		{
			switch (v)
			{
				case 1:
					AppendElementIfUnique(lines, "hale")
					break
				case 2:
					AppendElementIfUnique(lines, "squid_game")
					// v1 had a bug where it didn't write the newline
					// and this entry got killed off
					local idx = lines.find("adrenaline_shot")
					if (idx == null) lines.insert(0, "adrenaline_shot")
					break
				case 3:
					AppendElementIfUnique(lines, "speedrun")
					AppendElementIfUnique(lines, "wheelchair")
					AppendElementIfUnique(lines, "barrels")
					break
				case 4:
					AppendElementIfUnique(lines, "cramped_quarters")
					// v3 had the wrong name
					local idx = lines.find("speed_run")
					if (idx != null) lines[idx] = "speedrun"
					break
				case 5:
					AppendElementIfUnique(lines, "hunger_update")
					AppendElementIfUnique(lines, "merasmus")
					AppendElementIfUnique(lines, "singleplayer")
					AppendElementIfUnique(lines, "swap_madness")
					break
			}
		}
	})
}

function Ware_ExtractVersion(file, end_callback)
{
	local version = 0
	if (startswith(file, "VERSION "))
	{
		// extracting the digits and consuming the newline
		local start = 8
		local end = start
		while (file[end] <= '9')
			++end
		local line_end = end
		if (file[line_end] == '\r')
			line_end++
		version = file.slice(start, end).tointeger()
		
		// optimization to avoid copying the huge string around
		end_callback(line_end)
	}	
	return version
}

function Ware_LoadConfigThemes()
{
	local file = Ware_LoadConfigFile("themes")
	
	local latest_version = WARE_THEME_VERSION
	local version = Ware_ExtractVersion(file, function(line_end) { file = file.slice(line_end) })
	
	compilestring(format("Ware_Themes<-[\n%s]", file))()

	if (version < latest_version)
	{
		local file_default = Ware_LoadConfigFile("themes", false)
		
		// skip past version header
		Ware_ExtractVersion(file_default, function(line_end) { file_default = file_default.slice(line_end) })

		compilestring(format("Ware_ThemesDefault<-[\n%s]", file_default))()
		
		local header = "VERSION " + WARE_THEME_VERSION + "\n"
		file = header + file
		
		// write them in order
		local keys = ["theme_name", "visual_name", "author", "internal", "sounds"]
		local function FormatValue(value)
		{
			local valuestr = value.tostring()
			switch (typeof(value))
			{
				case "float":
					if (valuestr.find(".") == null) valuestr += ".0"
					break
				case "string":
					valuestr = "\"" + valuestr + "\""
					break
			}
			return valuestr
		}
		local function WriteTheme(name)
		{
			local theme
			foreach (test in Ware_ThemesDefault)
			{
				if (test.theme_name == name)
				{
					theme = test
					break
				}
			}
			if (!theme) // should not happen
				return
				
			Ware_Themes.append(theme)

			local buffer = ""
			buffer += "{\n"
			foreach (key in keys)
			{
				if (!(key in theme))
					continue
				local value = theme[key]
				if (typeof(value) == "table")
				{
					buffer += format("\t%s = \n\t{\n", key)
					foreach (subkey, subvalue in value)			
						buffer += format("\t\t\"%s\": %s\n", subkey, FormatValue(subvalue))				
					buffer += "\t}\n"
				}
				else
				{
					buffer += format("\t%s = %s\n", key, FormatValue(value))
				}
			}
			buffer += "},\n"
			file += buffer
		}
				
		for (local v = version + 1; v <= latest_version; v++)
		{
			switch (v)
			{
				case 1:
					file += "\n// added by automatic versioning\n"
					WriteTheme("ds_touched_mona")
					WriteTheme("wii_penny")
					break
				case 2:
					WriteTheme("ds_diy_microgame")
					WriteTheme("wii_tinywario")
					WriteTheme("switch_moveit_wario")
					break
				case 3:
					WriteTheme("mw_pandora")
					WriteTheme("mw_starlight")
					WriteTheme("switch_moveit_cricket")
					WriteTheme("switch_moveit_jimmyt")
					break
			}
		}
		
		local cfg_name = format(Ware_CfgPath, "themes")
		StringToFile(cfg_name, file)
		
		delete Ware_ThemesDefault
	}
	
	Ware_InternalThemes <- []
	for (local i = Ware_Themes.len() - 1; i >= 0; i--)
	{
		local theme = Ware_Themes[i]
		if ("internal" in theme)
		{
			Ware_InternalThemes.append(theme)
			Ware_Themes.remove(i)
		}
	}
}

function Ware_LoadConfigMeleeAttributes()
{
	// don't see the point of versioning this currently, so always load default
	local file = Ware_LoadConfigFile("melee_attributes", false)
	compilestring(format("Ware_MeleeAttributeOverrides<-{\n%s}", file))()
}

function Ware_LoadConfig()
{
	Ware_Minigames         <- []
	Ware_Bossgames         <- []
	Ware_SpecialRounds     <- []
	Ware_FakeSpecialRounds <- []
	Ware_GameOverlays      <- []
	
	Ware_LoadConfigSettings()
	Ware_LoadConfigMinigames()
	Ware_LoadConfigBossgames()
	Ware_LoadConfigSpecialRounds()
	Ware_LoadConfigList("fake_specialrounds", Ware_FakeSpecialRounds)	
	Ware_LoadConfigList("overlays", Ware_GameOverlays)	
	Ware_LoadConfigThemes()
	Ware_LoadConfigMeleeAttributes()
}

function Ware_WriteConfigList(file_name, version, lines)
{	
	local cfg_name = format(Ware_CfgPath, file_name)
	local buffer = "VERSION " + version + "\n"
	foreach (line in lines)
		buffer += line + "\n"
	StringToFile(cfg_name, buffer)
}

Ware_LoadConfig()