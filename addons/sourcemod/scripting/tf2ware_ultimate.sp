// Purpose of this plugin:
// - set sv_cheats 1 for the duration of the map
// - allow vscript to control host_timescale
// - block cheat commands and impulses on the server-side, as sv_cheats is required for host_timescale modification
// - use tournament whitelist system to block weapons/body cosmetics/taunts to prevent spawn lagspikes

#define LOADOUT_WHITELISTER 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "TF2Ware Ultimate"
// if changing this, change it in VScript's config.nut too
#define PLUGIN_VERSION "1.4.0"

// unused event repurposed for vscript <-> sourcemod communication
#define PROXY_EVENT "tf_map_time_remaining"

public Plugin myinfo =
{
	name        = PLUGIN_NAME,
	author      = "ficool2",
	description = "Dedicated functionality for TF2Ware Ultimate",
	version     = PLUGIN_VERSION,
	url         = "https://github.com/ficool2/TF2Ware_Ultimate"
};

#if LOADOUT_WHITELISTER
#include "loadout_whitelister.sp"
#endif

bool g_Enabled = false;

ArrayList g_CheatCommands;
ArrayList g_CheatCommandsArgs;
int g_CheatImpulses[] = { 76, 81, 82, 83, 101, 102, 103, 106, 107, 108, 195, 196, 197, 200, 202, 203 };

int g_TextProxy = INVALID_ENT_REFERENCE;

float g_ScriptPerfValue = 1.5;
float g_AntiFloodValue = 0.0;

ConVar host_timescale;
ConVar vscript_perf_warning_spew_ms;
ConVar datacachesize;
ConVar sv_cheats;
ConVar sm_flood_time;

//ConVar ware_version;
ConVar ware_cheats;
ConVar ware_log_cheats;

bool ShouldEnable()
{
	// TODO check how this behaves with workshop maps
	char map_name[PLATFORM_MAX_PATH];
	GetCurrentMap(map_name, sizeof(map_name));
	return StrContains(map_name, "tf2ware_ultimate", false) != -1;
}

Action ListenerCheatCommand(int client, const char[] command, int argc)
{
	if (!ware_cheats.BoolValue && client > 0)	
	{
		if (ware_log_cheats.BoolValue)
		{
			char name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			LogMessage("Client '%s' attempted to execute cheat command '%s'", name, command);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

Action ListenerCheatCommandArgs(int client, const char[] command, int argc)
{
	if (!ware_cheats.BoolValue && argc >= 1)
	{
		if (ware_log_cheats.BoolValue)
		{
			char name[MAX_NAME_LENGTH];
			GetClientName(client, name, sizeof(name));
			LogMessage("Client '%s' attempted to execute cheat command '%s'", name, command);	
		}		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action ListenerVScript(Event event, const char[] name, bool dontBroadcast)
{
	char id[32];
	event.GetString("id", id, sizeof(id), "");
	if (StrEqual(id, "tf2ware_ultimate"))
	{
		char routine[64];
		event.GetString("routine", routine, sizeof(routine), "");
		
		if (StrEqual(routine, "timescale"))
		{
			host_timescale.SetFloat(event.GetFloat("value", 1.0), true, false);
		}
		else if (StrEqual(routine, "loadout_on"))
		{
#if LOADOUT_WHITELISTER
			script_allow_loadout = true;
#endif
		}
		else if (StrEqual(routine, "loadout_off"))
		{
#if LOADOUT_WHITELISTER
			script_allow_loadout = false;
#endif
		}
		else if (StrEqual(routine, "flood_off"))
		{
			if (sm_flood_time != INVALID_HANDLE)
			{
				g_AntiFloodValue = sm_flood_time.FloatValue;
				sm_flood_time.SetFloat(-1.0);
			}	
		}	
		else if (StrEqual(routine, "flood_on"))
		{
			if (sm_flood_time != INVALID_HANDLE)
			{
				sm_flood_time.SetFloat(g_AntiFloodValue);
			}
		}	
		else
		{
			//LogMessage("Unknown VScript routine '%s'", routine);
		}
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{	
	int proxy = EntRefToEntIndex(g_TextProxy);
	if (proxy == INVALID_ENT_REFERENCE)
	{
		proxy = FindEntityByClassname(-1, "ware_textproxy");
		if (proxy != -1)
			g_TextProxy = EntIndexToEntRef(proxy);
	}
	
	if (IsValidEntity(proxy))
	{
		// ask vscript whether to hide the message
		SetEntPropEnt(proxy, Prop_Data, "m_hDamageFilter", client);
		SetEntPropString(proxy, Prop_Send, "m_szText", sArgs);
		SetVariantString("Ware_OnPlayerSayProxy");
		AcceptEntityInput(proxy, "CallScriptFunction", client, client);
		int show = GetEntProp(proxy, Prop_Data, "m_iHammerID");
		if (show == 1)
			return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnCheatsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	// cheats must be enabled for host_timescale to function
	sv_cheats.SetInt(1, true, false);
}

public Action HookVoiceCommand(UserMsg msg_id, BfRead bf, const int[] players, int playersNum, bool reliable, bool init)
{
	return Plugin_Handled;
}

void Enable()
{
	if (g_Enabled || !ShouldEnable())
		return;
	g_Enabled = true;
	
	LogMessage("Enabling...");
	
#if LOADOUT_WHITELISTER
	GameData gamedata = LoadGameConfigFile("tf2ware_ultimate");
	if (gamedata)	
	{
		LoadoutWhitelister_Start(gamedata);
	}
	else
	{
		LogError("Failed to retrieve 'tf2ware_ultimate' gamedata, loadout caching will be unavailable");	
	}
	delete gamedata;
#endif

	host_timescale = FindConVar("host_timescale");
	vscript_perf_warning_spew_ms = FindConVar("vscript_perf_warning_spew_ms");
	sv_cheats = FindConVar("sv_cheats");
	sm_flood_time = FindConVar("sm_flood_time");
	
	// incase a faulty plugin removes replicated flag, make sure to restore it
	host_timescale.Flags = host_timescale.Flags | FCVAR_REPLICATED;
	host_timescale.SetFloat(1.0, true, false);
	sv_cheats.Flags = sv_cheats.Flags | FCVAR_REPLICATED;
	sv_cheats.SetInt(1, true, false);
	
	// bump this because loading minigames from disk frequently takes a few ms and clogs the log
	// ficool2: perf warnings during ontakedamage callback can cause VM crashes, bumped to a Big number now
	float minWarningMs = 1000.0;
	if (vscript_perf_warning_spew_ms.FloatValue < minWarningMs)
	{
		g_ScriptPerfValue = vscript_perf_warning_spew_ms.FloatValue;
		vscript_perf_warning_spew_ms.SetFloat(minWarningMs, false, false);
	}
	
	HookConVarChange(sv_cheats, OnCheatsChanged);
	
	CreateConVar("ware_version", PLUGIN_VERSION, "TF2Ware Ultimate plugin version");
	ware_cheats = CreateConVar("ware_cheats", "0", "Enable sv_cheats commands");
	ware_log_cheats = CreateConVar("ware_log_cheats", "1", "Log cheat command attempts");
	
	// unused event repurposed for vscript <-> sourcemod communication
	HookEvent(PROXY_EVENT, ListenerVScript, EventHookMode_Pre);
	
	HookUserMessage(GetUserMessageId("VoiceSubtitle"), HookVoiceCommand, true);

	char name[64];
	char description[128];
	bool is_command;
	int flags;
	
	Handle hConCommandIter = FindFirstConCommand(name, sizeof(name), is_command, flags, description, sizeof(description));
	do 
	{
		if (is_command && (flags & FCVAR_CHEAT))
		{	
			AddCommandListener(ListenerCheatCommand, name);
			g_CheatCommands.PushString(name);
		}
	} 
	while ( FindNextConCommand(hConCommandIter, name, sizeof(name), is_command, flags, description, sizeof(description)));
	
	// special cases
	g_CheatCommands.PushString("give");	
	g_CheatCommands.PushString("te");
	g_CheatCommands.PushString("addcond");	
	g_CheatCommands.PushString("removecond");	
	g_CheatCommands.PushString("mp_playgesture");	
	g_CheatCommands.PushString("mp_playanimation");	
	for (int i = 0; i < g_CheatCommands.Length; i++)	
	{		
		g_CheatCommands.GetString(i, name, sizeof(name));
		AddCommandListener(ListenerCheatCommand, name);
	}
	
	g_CheatCommandsArgs.PushString("kill");	
	g_CheatCommandsArgs.PushString("explode");	
	g_CheatCommandsArgs.PushString("fov");		
	for (int i = 0; i < g_CheatCommandsArgs.Length; i++)	
	{		
		g_CheatCommandsArgs.GetString(i, name, sizeof(name));
		AddCommandListener(ListenerCheatCommandArgs, name);
	}	
	
}

void Disable(bool map_unload)
{
	if (!g_Enabled)
		return;
	g_Enabled = false;
	
	LogMessage("Disabling...");
	
#if LOADOUT_WHITELISTER
	LoadoutWhitelister_End(map_unload);
#endif

	UnhookConVarChange(sv_cheats, OnCheatsChanged);
	
	UnhookEvent(PROXY_EVENT, ListenerVScript, EventHookMode_Pre);
	
	UnhookUserMessage(GetUserMessageId("VoiceSubtitle"), HookVoiceCommand, true);
	
	// OnPluginEnd will clear these automatically
	if (map_unload)
	{
		char name[64];
		for (int i = 0; i < g_CheatCommands.Length; i++)
		{
			g_CheatCommands.GetString(i, name, sizeof(name));	
			RemoveCommandListener(ListenerCheatCommand, name);	
		}
		
		for (int i = 0; i < g_CheatCommandsArgs.Length; i++)
		{
			g_CheatCommandsArgs.GetString(i, name, sizeof(name));
			RemoveCommandListener(ListenerCheatCommandArgs, name);	
		}		
	}
	
	g_CheatCommands.Clear();
	g_CheatCommandsArgs.Clear();
	
	host_timescale.SetFloat(1.0, true, false);
	sv_cheats.SetInt(0, true, false);
	vscript_perf_warning_spew_ms.SetFloat(g_ScriptPerfValue, false, false);
}

public void OnClientPutInServer(int client)
{
	if (!g_Enabled)
		return;
		
#if LOADOUT_WHITELISTER
	LoadoutWhitelister_InitClient(client);
#endif
}

public void OnClientPostAdminCheck(int client)
{
	if (!g_Enabled)
		return;
	
	// allow admins to use dev commands
	if (CheckCommandAccess(client, "ware_admincheck", ADMFLAG_RCON))
		SetEntProp(client, Prop_Data, "m_autoKickDisabled", 1);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (g_Enabled)
	{
		if (impulse > 0 && !ware_cheats.BoolValue)
		{
			for (int i = 0; i < sizeof(g_CheatImpulses); i++)
			{
				if (impulse == g_CheatImpulses[i])
				{
					if (ware_log_cheats.BoolValue)
					{
						char name[MAX_NAME_LENGTH];
						GetClientName(client, name, sizeof(name));
						LogMessage("Client '%s' attempted to execute cheat impulse '%d'", name, impulse);		
					}					
					impulse = 0;					
					break;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public void OnPluginStart()
{
	// tf2ware exhausts more than 256mb of model data
	// this has been the culprit of random server crashes on map load
	datacachesize = FindConVar("datacachesize");
	if (datacachesize.IntValue < 512)
		datacachesize.IntValue = 512;
	
	g_CheatCommands = new ArrayList(ByteCountToCells(64));
	g_CheatCommandsArgs = new ArrayList(ByteCountToCells(64));
	Enable();
}

public void OnPluginEnd()
{
	Disable(false);
}

public void OnMapStart()
{
	Enable();
	
#if LOADOUT_WHITELISTER
	LoadoutWhitelister_ReloadWhitelist();
#endif
}

public void OnMapEnd()
{
	Disable(true);
}