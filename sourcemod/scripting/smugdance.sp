#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Moonly Days"
#define PLUGIN_VERSION "0.01"
#define TAUNT_RUSSIAN 1157

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <tf2items>

char g_HatKidModel[] = "models/ahit_smug_dance/hatkid.mdl";
char g_HatKidMusic[] = "player/hatkid_taunt.wav";

bool g_IsDancing[MAXPLAYERS + 1];
Handle hPlayTaunt;

public Plugin myinfo = 
{
	name = "Smug dance",
	author = PLUGIN_AUTHOR,
	description = "asd",
	version = PLUGIN_VERSION,
	url = "rcatf2.ru"
};

public void OnPluginStart()
{
	Handle conf = LoadGameConfigFile("tf2.tauntem");
	if (conf == INVALID_HANDLE)
	{
		SetFailState("Unable to load gamedata/tf2.tauntem.txt. Good luck figuring that out.");
		return;
	}
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(conf, SDKConf_Signature, "CTFPlayer::PlayTauntSceneFromItem");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	hPlayTaunt = EndPrepSDKCall();
	if (hPlayTaunt == INVALID_HANDLE)
	{
		SetFailState("Unable to initialize call to CTFPlayer::PlayTauntSceneFromItem. Wait patiently for a fix.");
		CloseHandle(conf);
		return;
	}
	CloseHandle(conf);
	
	RegConsoleCmd("sm_smug", cSmug, "SMUG.");
	HookEvent("player_spawn", evPlayerSpawn);
	HookEvent("player_death", evPlayerSpawn);
  	HookUserMessage(GetUserMessageId("PlayerTauntSoundLoopStart"), HookTauntMessage, true);
	AddNormalSoundHook(SHook);
}

public Action:evPlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    if (client < 1)return Plugin_Continue;
    if(g_IsDancing[client]){
	    RemoveValveHat(client, true);
	    HideWeapons(client, true);
	    SetVariantString("");
	    AcceptEntityInput(client, "SetCustomModel");
   	}
    return Plugin_Continue;
}

public void ReSendTaunt(int byte)
{
	Handle message = StartMessageAll("PlayerTauntSoundLoopStart");
	BfWriteByte(message, byte);
	BfWriteString(message, g_HatKidMusic);
	EndMessage();
}

public Action:HookTauntMessage(UserMsg:msg_id, BfRead msg, const players[], playersNum, bool:reliable, bool:init) 
{
	int byte = msg.ReadByte();
	char string[PLATFORM_MAX_PATH]; //The sound
	msg.ReadString(string, PLATFORM_MAX_PATH);

	if (g_IsDancing[byte] && StrEqual(string, "music.russian"))
	{
		RequestFrame(ReSendTaunt, byte);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("models/ahit_smug_dance/hatkid.mdl");
	AddFileToDownloadsTable("models/ahit_smug_dance/hatkid.sw.vtx");
	AddFileToDownloadsTable("models/ahit_smug_dance/hatkid.vvd");
	AddFileToDownloadsTable("models/ahit_smug_dance/hatkid.dx80.vtx");
	AddFileToDownloadsTable("models/ahit_smug_dance/hatkid.dx90.vtx");
	
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/kidhat.vmt");
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/kidhat.vtf");
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/null.vtf");
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/rose.vmt");
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/tie.vmt");
	AddFileToDownloadsTable("materials/models/a_hat_in_time/hats/hat_kid_base_hat/tie.vtf");
	
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/eyes_smug.vmt");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/eyes_smug.vtf");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidbody.vmt");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidbody.vtf");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidhair.vmt");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidhair.vtf");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidhair_normal.vtf");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/hatkidlegs.vmt");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/mouth_smug.vmt");
	AddFileToDownloadsTable("materials/models/ahit_smug_dance/mouth_smug.vtf");
	
	AddFileToDownloadsTable("sound/player/hatkid_taunt.wav");
	
	PrecacheModel(g_HatKidModel);
}

public Action:SHook(clients[64], &numClients, String:sound[PLATFORM_MAX_PATH], &Ent, &channel, &Float:volume, &level, &pitch, &flags) 
{
	if(0<Ent<=MaxClients && IsClientInGame(Ent)){
		if (g_IsDancing[Ent])
		{
			return Plugin_Handled;
	    }
	}
	return Plugin_Continue;
}

public Action cSmug(int client, int args){
	int ent = MakeCEIVEnt(client, TAUNT_RUSSIAN);
	Address pEconItemView = GetEntityAddress(ent) + view_as<Address>(FindSendPropInfo("CTFWearable", "m_Item"));
	if (!IsValidAddress(pEconItemView))
	{
		ReplyToCommand(client, "[SM] Couldn't find CEconItemView for taunt");
		return Plugin_Handled;
	}
	bool bSuccess = SDKCall(hPlayTaunt, client, pEconItemView);
	if(bSuccess)
	{
		g_IsDancing[client] = true;
		SetVariantString(g_HatKidModel);
		HideWeapons(client);
		RemoveValveHat(client);
		AcceptEntityInput(client, "SetCustomModel");
		SetEntProp(client, Prop_Send, "m_bCustomModelRotates", 1);
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
		SetEntProp(client, Prop_Send, "m_nBody", 0);
	}
	return Plugin_Handled;
}

stock int MakeCEIVEnt(int client, int itemdef, int particle=0)
{
	static Handle hItem;
	if (hItem == INVALID_HANDLE)
	{
		hItem = TF2Items_CreateItem(OVERRIDE_ALL|PRESERVE_ATTRIBUTES|FORCE_GENERATION);
		TF2Items_SetClassname(hItem, "tf_wearable_vm");
		TF2Items_SetQuality(hItem, 6);
		TF2Items_SetLevel(hItem, 1);
	}
	TF2Items_SetItemIndex(hItem, itemdef);
	return TF2Items_GiveNamedItem(client, hItem);
}

public void TF2_OnConditionRemoved(int client, TFCond cond)
{
	if(cond == TFCond_Taunting && g_IsDancing[client])
	{
		g_IsDancing[client] = false;
		SetVariantString("");
		AcceptEntityInput(client, "SetCustomModel");
		if(IsPlayerAlive(client))
		{
			HideWeapons(client,true);
			RemoveValveHat(client,true);
		}
	}
}

stock bool IsValidAddress(Address pAddress)
{
	if (pAddress == Address_Null)	//yes the other one overlaps this but w/e
		return false;
	return ((pAddress & view_as<Address>(0x7FFFFFFF)) >=  view_as<Address>(0x00000000));
}


// Credit: FlaminSarge's Model Manager
stock HideWeapons(client, bool:unhide = false)
{
	HideWeaponWearables(client, unhide);
	new m_hMyWeapons = FindSendPropOffs("CTFPlayer", "m_hMyWeapons");	

	for (new i = 0, weapon; i < 47; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		decl String:classname[64];
		if (weapon > MaxClients && IsValidEdict(weapon) && GetEdictClassname(weapon, classname, sizeof(classname)) && StrContains(classname, "weapon") != -1)
		{
			SetEntityRenderMode(weapon, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
			SetEntityRenderColor(weapon, 255, 255, 255, (unhide ? 255 : 5));
		}
	}
}
stock HideWeaponWearables(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642) continue;
			if (GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}

stock RemoveValveHat(client, bool:unhide = false)
{
	new edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_wearable")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFWearable") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
	edict = MaxClients+1;
	while((edict = FindEntityByClassname(edict, "tf_powerup_bottle")) != -1)
	{
		decl String:netclass[32];
		if (GetEntityNetClass(edict, netclass, sizeof(netclass)) && strcmp(netclass, "CTFPowerupBottle") == 0)
		{
			new idx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
			if (idx != 57 && idx != 133 && idx != 231 && idx != 444 && idx != 405 && idx != 608 && idx != 642 && GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity") == client)
			{
				SetEntityRenderMode(edict, (unhide ? RENDER_NORMAL : RENDER_TRANSCOLOR));
				SetEntityRenderColor(edict, 255, 255, 255, (unhide ? 255 : 0));
			}
		}
	}
}