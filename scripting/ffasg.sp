#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <build>
#include <tf2>
#pragma newdecls required
#pragma semicolon 1

char mapName[32];
int pointTracker[MAXPLAYERS + 1];
int clientOnPoint;

ConVar cv_instantSpawn;

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
	cv_instantSpawn = CreateConVar("ffa_instantrespawn", "1", "Enable/Disable Instant Respawn.", _, true, 0.0, true, 1.0);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
	// HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(entity > MaxClients && IsValidEntity(entity) && StrEqual(classname, "trigger_capture_area"))
    {
		SDKHook(entity, SDKHook_StartTouchPost, OnTouch);
		SDKHook(entity, SDKHook_EndTouchPost, EndTouch);
    }
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

public void OnClientPutInServer(int client)
{
	pointTracker[client] = 0;
}

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

		int highestDamage = 0;
		int highestDamageClient = -1;
		

		if (IsClientInGame(i) && GetCurrentPoints(i) > highestDamage)
		{
			highestDamage = GetCurrentPoints(i);
			highestDamageClient = i;
			
		}

		int secondHighestDamage = 0;
		int secondHighestDamageClient = -1;

		for (int z = 1; z <= MaxClients; z++)
		{
			if (IsClientInGame(z) && GetCurrentPoints(z) > secondHighestDamage && z != highestDamageClient)
			{
				secondHighestDamage = GetCurrentPoints(z);
				secondHighestDamageClient = z;
			}
		}

		int thirdHighestDamage = 0;
		int thirdHighestDamageClient = -1;
		
		for (int z = 1; z <= MaxClients; z++)
		{
			if (IsClientInGame(z) && GetCurrentPoints(z) > thirdHighestDamage && z != highestDamageClient && z != secondHighestDamageClient)
			{
				thirdHighestDamage = GetCurrentPoints(z);
				thirdHighestDamageClient = z;
			}
		}

		char highestDamageName[32];
		char secondhighestDamageName[32];
		char thirdhighestDamageName[32];

		SetHudTextParams(-9.5, 0.01, 0.01, 0, 255, 255, 255, 0, 1.0, 0.5, 0.5);

		if(Build_IsClientValid(highestDamageClient, highestDamageClient))
		{
			GetClientName(highestDamageClient, highestDamageName, sizeof(highestDamageName));
			ShowHudText(i, -1, "%s: %i", highestDamageName, highestDamage);
		}

		if(Build_IsClientValid(secondHighestDamageClient, secondHighestDamageClient))
		{
			GetClientName(secondHighestDamageClient, secondhighestDamageName, sizeof(secondhighestDamageName));
			ShowHudText(i, -1, "\n%s: %i", secondhighestDamageName, secondHighestDamage);
		}

		if(Build_IsClientValid(thirdHighestDamageClient, thirdHighestDamageClient))
		{
			GetClientName(thirdHighestDamageClient, thirdhighestDamageName, sizeof(thirdhighestDamageName));
			ShowHudText(i, -1, "\n\n%s: %i", thirdhighestDamageName, thirdhighestDamageName);
		}
		
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

public Action hookPlayerDie(Event event, const char[] name, bool dontBroadcast)
{
	int attackerId = event.GetInt("attacker");
	int victimId = event.GetInt("userid");

	if(attackerId == victimId)
		return;
	pointTracker[GetClientOfUserId(attackerId)] = pointTracker[GetClientOfUserId(attackerId)] + 1;

	RequestFrame(Respawn, GetClientSerial(GetClientOfUserId(victimId)));
}

public int GetCurrentPoints(int client)
{
	return pointTracker[client];
}

public void Respawn(any serial)
{
	if(cv_instantSpawn.IntValue == 1)
	{
		int client = GetClientFromSerial(serial);
		if(client != 0)
		{
			int team = GetClientTeam(client);
			if(!IsPlayerAlive(client) && team != 1)
			{
				TF2_RespawnPlayer(client);
			}
		}
	}
}