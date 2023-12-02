#include <sourcemod>
#include <rtd2>
#include <tf2attributes>
#include <sdktools>
#include <sdkhooks>
#include <tf2>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.0.1"
#define SOUND_METAL_CAP "kingo/rtd/metal_cap.mp3"
#define SOUND_METAL_CAP_STEP "kingo/rtd/metal_cap_step.mp3"

bool g_Active[MAXPLAYERS + 1] = { false, ... };


public Plugin myinfo = 
{
	name = "Metal Cap RTD Perk",
	author = "kingo",
	description = "Adds the metal cap from SM64",
	version = PLUGIN_VERSION,
	url = "kingo.tf"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	}
	
	return APLRes_Success;
} 

public void OnPluginStart()
{
    if (RTD2_IsRegOpen())RegisterPerk();
    AddNormalSoundHook(SoundHook);
}

public void OnPluginEnd()
{
    RTD2_DisableModulePerks();
}

public void OnMapStart()
{
    AddFileToDownloadsTable("sound/kingo/rtd/metal_cap.mp3");
    AddFileToDownloadsTable("sound/kingo/rtd/metal_cap_step.mp3");
    
    PrecacheSound(SOUND_METAL_CAP);
    PrecacheSound(SOUND_METAL_CAP_STEP);
}

public void RTD2_OnRegOpen()
{
    RegisterPerk();
}

void RegisterPerk()
{
    RTD2_ObtainPerk("metal_cap")
        .SetName("Metal Cap")
        .SetGood(true)
        .SetSound(SOUND_METAL_CAP)
        .SetTime(40)
        .SetCall(MetalCap_Call);
}

public void MetalCap_Call(int client, RTDPerk perk, bool enable)
{
    g_Active[client] = enable;
    if (enable)
    {
        EnablePerk(client);
        return;
    }
    DisablePerk(client);
}

void EnablePerk(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
    SDKHook(client, SDKHook_PreThink, OnPreThink);
    SetEntityRenderColor(client, 0, 0, 0, 255);
}

void DisablePerk(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
    SDKUnhook(client, SDKHook_PreThink, OnPreThink);
    SetEntityRenderColor(client, 255, 255, 255, 255);
    StopSound(client, SNDCHAN_AUTO, SOUND_METAL_CAP);
}

Action OnTakeDamagePre(int victim, int &attacker, int &inflictor, float &damage, int &damageType, int &weapon, float damageForce[3],
float damagePosition[3], int damagecustom)
{
    damage = 0.0;
    if (damageType & DMG_DROWN)return Plugin_Changed;
    
    if (attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients)return Plugin_Continue;

    TF2_AddCondition(victim, TFCond_UberchargedCanteen, 0.01);
    return Plugin_Continue;
}

void OnPreThink(int client)
{ 
    if (GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 2)ApplyAbsVelImpulse(client, { 0.0, 0.0, -25.0 });
}

public void OnClientPutInServer(int client)
{
    g_Active[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum,
int &tickcount, int &seed, int mouse[2])
{
    if (g_Active[client] && GetEntProp(client, Prop_Send, "m_nWaterLevel") >= 2 
    && buttons & IN_JUMP)
    {
        buttons &= ~IN_JUMP;
    }
    
    return Plugin_Continue;
}

//Replacing doesnt work for footsteps? Are they clientside?
Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    if (entity <= 0 || entity > MaxClients || !g_Active[entity] || StrContains(sample, "footsteps", false) == -1)return Plugin_Continue;
    EmitSoundToAll(SOUND_METAL_CAP_STEP, entity, SNDCHAN_AUTO, SNDLEVEL_NORMAL, _, 0.4, _, _, _, _, _, _);
    return Plugin_Continue;
}

void ApplyAbsVelImpulse(int client, float impulse[3] = { 0.0, 0.0, 0.0 })
{
    float m_vecAbsVelocity[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", m_vecAbsVelocity);
    AddVectors(m_vecAbsVelocity, impulse, m_vecAbsVelocity);
    SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", m_vecAbsVelocity);
}