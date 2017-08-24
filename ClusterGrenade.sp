#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

bool AllowCluster[MAXPLAYERS + 1] =  { true, ... };

public Plugin myinfo = 
{
	name = "Cluster Grenade",
	author = PLUGIN_AUTHOR,
	description = "Throw multiple grenades at once in a cluster.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
}

public void OnEntityCreated(int iEntity, const char[] classname) 
{
	if(StrEqual(classname, "hegrenade_projectile", false))
	{
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}

public Action OnEntitySpawned(int iGrenade)
{
	int client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if (IsValidClient(client) && AllowCluster[client])
	{
		CreateCluster(client);
	}
}

public void CreateCluster(int client)
{
	AllowCluster[client] = false;
	float angles[3];
	float ang[4][3];
	float pos[3];
	float vel[4][3];
	GetClientEyeAngles(client, angles);
	GetClientEyePosition(client, pos);
	ang[0][0] = angles[0] - 7.0;
	ang[0][1] = angles[1] - 7.0;
	ang[1][0] = angles[0] + 7.0;
	ang[1][1] = angles[1] + 7.0;
	ang[2][0] = angles[0] - 7.0;
	ang[2][1] = angles[1] + 7.0;
	ang[3][0] = angles[0] + 7.0;
	ang[3][1] = angles[1] - 7.0;
	GetAngleVectors(ang[0], vel[0], NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang[1], vel[1], NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang[2], vel[2], NULL_VECTOR, NULL_VECTOR);
	GetAngleVectors(ang[3], vel[3], NULL_VECTOR, NULL_VECTOR);
	ScaleVector(vel[0], 1250.0);
	ScaleVector(vel[1], 1250.0);
	ScaleVector(vel[2], 1250.0);
	ScaleVector(vel[3], 1250.0);
	int GEntities[4];
	float g_fSpin[3] =  { 4877.4, 0.0, 0.0 };
	float fPVelocity[3];
	//char input[] = "!self,InitializeSpawnFromWorld,,999.0,-1";
	for (int i = 0; i < sizeof(GEntities); i++)
	{
		GEntities[i] = CreateEntityByName("hegrenade_projectile");
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVelocity);
		AddVectors(vel[i], fPVelocity, vel[i]);
		
		SetEntPropVector(GEntities[i], Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropEnt(GEntities[i], Prop_Data, "m_hThrower", client);
		SetEntPropEnt(GEntities[i], Prop_Data, "m_hOwnerEntity", client);
		SetEntProp(GEntities[i], Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntPropFloat(GEntities[i], Prop_Send, "m_DmgRadius", 350.0);
		SetEntPropFloat(GEntities[i], Prop_Send, "m_flDamage", 99.0);
		//Format(input, sizeof(input), "!self,InitializeSpawnFromWorld,,%0.2f,-1", GetRandomFloat(2.0, 4.0));
		AcceptEntityInput(GEntities[i], "InitializeSpawnFromWorld");
		AcceptEntityInput(GEntities[i], "FireUser1", GEntities[i]);
		if (DispatchSpawn(GEntities[i]))
		{
			TeleportEntity(GEntities[i], pos, ang[i], vel[i]);
		}
	}
	CreateTimer(2.0, AllowClusterAgain, _, client);
}

public Action AllowClusterAgain(Handle timer, any client)
{
	AllowCluster[client] = true;
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}