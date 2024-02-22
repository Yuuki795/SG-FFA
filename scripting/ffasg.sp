#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <build>
#pragma newdecls required
#pragma semicolon 1

char mapName[32];

int clientOnPoint;

public Plugin myinfo =
{
	name = "SG Free For All",
	author = "Yuuki",
	description = "",
	version = "1.0.0",
	url = "https://github.com//ffasg"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	//used from another gamemode I made. Put it here so that plugin is not needed.
	RegPluginLibrary("build_test");
	CreateNative("Build_IsClientValid", Native_IsClientValid);
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	SDKHook(FindEntityByClassname(-1, "trigger_capture_area"), SDKHook_StartTouchPost, OnTouch);
	SDKHook(FindEntityByClassname(-1, "trigger_capture_area"), SDKHook_EndTouchPost, EndTouch);
	// HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

// public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
// {
//     int i = -1;
//     int CP = 0;

//     for (int n = 0; n <= 16; n++)
//     {
//         CP = FindEntityByClassname(i, "trigger_capture_area");
//         if (IsValidEntity(CP))
//         {
//             AcceptEntityInput(CP, "Disable");
//             i = CP;
//         }
//         else
//             break;
//     }
// } 

public void OnMapStart()
{	
	GetCurrentMap(mapName, sizeof(mapName));

	if(StrContains(mapName, "ffa_", true) == -1 && StrContains(mapName, "koth_", true) == -1)
	{
		ThrowError("[SG FFA] Current map is not a FFA map! Disabling Plugin.");
	}

	else
	{
		CreateTimer(5.0, DisplayHud);
		PrintToServer("[SG FFA] Loaded");
	}
}

public void OnTouch(int other, int client)
{
	if(Build_IsClientValid(client, client))
	{
		clientOnPoint = client;
		int playerTeam = GetClientTeam(client);
		int point;
		point = FindEntityByClassname(-1, "team_control_point");
		SetVariantInt(playerTeam);
		AcceptEntityInput(point,"SetOwner",0,0);
	}
}

public void EndTouch(int other, int client)
{
	//PrintToChat(other, "Not Touching");
	if(Build_IsClientValid(client, client))
	{
		clientOnPoint = -1;
		int point;
		point = FindEntityByClassname(-1, "team_control_point");
		SetVariantInt(0);
		AcceptEntityInput(point,"SetOwner",0,0);
	}	
}

public Action DisplayHud(Handle timer)
{
	for(int i = 1; i <= MAXPLAYERS; i++) if (Build_IsClientValid(i, i))
	{

		SetHudTextParams(-9.5, 0.01, 0.01, 0, 255, 255, 255, 0, 1.0, 0.5, 0.5);
		ShowHudText(i, -1, "%s", "Person1: 0", i);
		ShowHudText(i, -1, "%s", "\nPerson2: 0", i);
		ShowHudText(i, -1, "%s", "\n\nPerson3: 0", i);
		if (clientOnPoint > 0) {
			char buffer[32];
			GetClientName(i, buffer, sizeof(buffer));
			SetHudTextParams(-1.0, 0.01, 0.01, 0, 255, 255, 255, 0, 1.0, 0.5, 0.5);
			ShowHudText(i, -1, "%s is on point!", buffer, i);
		}

	}
	CreateTimer(0.1, DisplayHud);
}


public int Native_IsClientValid(Handle hPlugin, int iNumParams) 
{
	int client = GetNativeCell(1);
	int iTarget = GetNativeCell(2);
	
	if(client < 0) return false; 
	if(client > MaxClients) return false; 
	if(!IsClientConnected(client)) return false;
	if(!IsClientInGame(client)) return false;
	
	if(iTarget < 0) return false; 
	if(iTarget > MaxClients) return false; 
	if(!IsClientConnected(iTarget)) return false;
	if(!IsClientInGame(iTarget)) return false;
	
	bool IsAlive;
	if (iNumParams == 3)
		IsAlive = GetNativeCell(3);

	if (IsAlive) 
	{
		if (!IsPlayerAlive(iTarget)) 
		{
			return false;
		}
	}
	return true;
}