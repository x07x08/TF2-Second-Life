#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_EXTENSIONS
#include <tf2>

#define PLUGIN_VERSION "1.3"

int    g_iRespawnClient[MAXPLAYERS+1];
bool   g_bRoundStarted;
float  g_fRoundStartTime;
Handle g_hSecondLifeTimer;

ConVar g_hSecondLifeBlockTime;
ConVar g_hSecondLifeEnabled;
ConVar g_hSecondLifeRespawns;
ConVar g_hSecondLifeAllowBlue;
ConVar g_hSecondLifeAllowRed;

public Plugin myinfo = 
{
	name        = "Second Life",
	author      = "tooti, modified by x07x08",
	description = "You get a second life when you die",
	version     = PLUGIN_VERSION,
	url         = ""
}

public void OnPluginStart()
{
	CreateConVar("sm_secondlife_version", PLUGIN_VERSION, "Second Life version, dont touch it :3", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_hSecondLifeEnabled   = CreateConVar("sm_secondlife_enabled", "1", "Enable / disable the plugin.", _,true, 0.0, true , 1.0);
	g_hSecondLifeBlockTime = CreateConVar("sm_secondlife_block_time", "10.0", "Time until respawning is blocked.");
	g_hSecondLifeRespawns  = CreateConVar("sm_secondlife_respawns", "1", "How many lives does a player have?");
	g_hSecondLifeAllowBlue = CreateConVar("sm_secondlife_allow_blue", "0", "Allow blue team to respawn?", _, true, 0.0, true, 1.0);
	g_hSecondLifeAllowRed  = CreateConVar("sm_secondlife_allow_red", "1", "Allow red team to respawn?", _, true, 0.0, true, 1.0);
	
 	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("arena_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("arena_win_panel", OnRoundEnd, EventHookMode_PostNoCopy);
}

public void OnClientConnected(int iClient)
{
	g_iRespawnClient[iClient] = 0;
}

public void OnPlayerDeath(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if(g_hSecondLifeEnabled.BoolValue && g_bRoundStarted)
	{
		int iClient   = GetClientOfUserId(hEvent.GetInt("userid"));
		int iRespawns = g_hSecondLifeRespawns.IntValue;
		
		if (1 <= iClient <= MaxClients)
		{
			if ((GetGameTime() - g_fRoundStartTime < g_hSecondLifeBlockTime.FloatValue) && IsClientInGame(iClient))
			{
				if(g_iRespawnClient[iClient] != iRespawns)
				{
					RequestFrame(SecondLifeRespawn, GetClientUserId(iClient));
				}
			}
		}
	}
}

public void OnRoundEnd(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if(g_hSecondLifeTimer != null)
	{
		KillTimer(g_hSecondLifeTimer);
		g_hSecondLifeTimer = null;
	}
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		g_iRespawnClient[iClient] = 0;
	}
	
	g_bRoundStarted = false;
}

public void OnRoundStart(Event hEvent, const char[] strName, bool bDontBroadcast)
{
	if(g_hSecondLifeTimer != null)
	{
		KillTimer(g_hSecondLifeTimer);
		g_hSecondLifeTimer = null;
	}
	
	g_bRoundStarted   = true;
	g_fRoundStartTime = GetGameTime();
	
	if (g_hSecondLifeEnabled.BoolValue)
	{
		float fRespawnTime = g_hSecondLifeBlockTime.FloatValue;
		
		if (fRespawnTime > 0.0)
		{
			g_hSecondLifeTimer = CreateTimer(fRespawnTime, TimeUpMessage);
		}
	}
}

public void OnMapEnd() 
{
	if(g_hSecondLifeTimer != null)
	{
		KillTimer(g_hSecondLifeTimer);
		g_hSecondLifeTimer = null;
	}
	
	for (int iClient = 1; iClient <= MaxClients; iClient++) 
	{
		g_iRespawnClient[iClient] = 0;
	}
	
	g_bRoundStarted = false;
}

public Action TimeUpMessage(Handle hTimer)
{
	g_hSecondLifeTimer = null;
	
	if (g_hSecondLifeEnabled.BoolValue && g_hSecondLifeBlockTime.FloatValue > 0.0)
	{
		PrintToChatAll("\x01[\03Second Life\01] Respawn time is up!");
	}
	
	return Plugin_Continue;
}

void SecondLifeRespawn(any iUserId)
{
	int iClient = GetClientOfUserId(iUserId);
	
	if (1 <= iClient <= MaxClients)
	{
		if (IsClientInGame(iClient) && !IsFakeClient(iClient) && g_bRoundStarted)
		{
			if (GetClientTeam(iClient) == 2)
			{
				if (g_hSecondLifeAllowRed.BoolValue)
				{
					TF2_RespawnPlayer(iClient);
					g_iRespawnClient[iClient]++;
					PrintToChat(iClient,"\x01[\03Second Life\01] You've got a second life!");
				}
			}
			else if (GetClientTeam(iClient) == 3)
			{
				if (g_hSecondLifeAllowBlue.BoolValue)
				{
					TF2_RespawnPlayer(iClient);
					g_iRespawnClient[iClient]++;
					PrintToChat(iClient,"\x01[\03Second Life\01] You've got a second life!");
				}
			}
		}
	}
}