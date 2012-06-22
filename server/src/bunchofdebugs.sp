#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
// Constants for the different teams----------------
new const TEAM_NONE       = 0;
new const TEAM_SPECTATOR  = 1;
new const TEAM_SURVIVOR   = 2;
new const TEAM_INFECTED   = 3;

new g_debug = false;
public Plugin:myinfo = {
		   name = "Bunch of Debugs",
		 author = "sauce",
	description = "Just a bunch of debug tools",
		version = "1"
};

public OnPluginStart() {
	RegAdminCmd("sm_isfakeclient", Command_IsFakeClient,ADMFLAG_SLAY);
	RegAdminCmd("sm_enabledebug", Command_EnableDebug, ADMFLAG_SLAY);
	RegAdminCmd("sm_disabledebug", Command_DisableDebug, ADMFLAG_SLAY);
	RegAdminCmd("sm_printclients", Command_PrintClients, ADMFLAG_SLAY);
	RegAdminCmd("sm_printclientbyname", Command_PrintClientByName, ADMFLAG_SLAY);
	RegAdminCmd("sm_printclient", Command_PrintClientByIndex, ADMFLAG_SLAY);
	RegAdminCmd("sm_printsurvivors", Command_PrintSurvivors, ADMFLAG_SLAY);
	RegAdminCmd("sm_printinfected", Command_PrintInfected, ADMFLAG_SLAY);
	RegAdminCmd("sm_printhumans", Command_PrintHumans, ADMFLAG_SLAY);
	RegAdminCmd("sm_printbots", Command_PrintBots, ADMFLAG_SLAY);
	RegAdminCmd("sm_printtime", Command_PrintRoundTime, ADMFLAG_SLAY);
	RegAdminCmd("sm_printgamemode", Command_PrintGameMode, ADMFLAG_SLAY);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
}

public Action:Command_PrintRoundTime(client, args) {
	PrintToChatAll("%f",GameRules_GetProp("m_flAccumulatedTime"));
	return Plugin_Handled;
}

public Action:Command_EnableDebug(client, args) {
	g_debug = true;
	return Plugin_Handled;
}

public Action:Command_DisableDebug(client, args) {
	g_debug = false;
	return Plugin_Handled;
}

public Action:Command_PrintGameMode(client, args) {
	decl String:buffer[100] = "\0";
	GetConVarString(FindConVar("mp_gamemode"), buffer, sizeof(buffer));
	PrintToChatAll("GameMode = %s", buffer);
}

public Action:Command_IsFakeClient(client, args) {
	new String:arg1[33];
	GetCmdArg(1, arg1, sizeof(arg1));
	new clientID = StringToInt(arg1);
	if (clientID == 0) {
		PrintToChat(client, "client = %d is invalid (because it's world)", clientID);
	}
	if (IsClientConnected(clientID)) {
		PrintToChat(client, "IsFakeClient(%d) = %s [%d] %N",clientID,(IsFakeClient(clientID)) ? "true" : "false",clientID,clientID);
	}
	else {
		PrintToChat(client, "client = %d is not connected", clientID);
	}
	return Plugin_Handled;
}

public Action:Command_PrintClients(client,args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientAlive(i)) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Action:Command_PrintClientByName(client, args) {
	new String:arg1[33];
	new String:name[33];
	new find = 0;
	new found = false;
	GetCmdArg(1, arg1, sizeof(arg1));
	
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientAlive(i)) {
			GetClientName(i, name, sizeof(name));
			if (StrContains(name, arg1,false)) {
				find = i;
				found = true;
			}
		}
	}
	
	if (found) {
		PrintToChatAll("%N's client = %d",find,find);
	}
	else {
		PrintToChatAll("%s not found",arg1);
	}
	return Plugin_Handled;
}

public Action:Command_PrintClientByIndex(client, args) {
	new String:arg1[5];
	GetCmdArg(1, arg1, sizeof(arg1));
	new clientIndex = StringToInt(arg1);
	if (IsClientAlive(clientIndex)) {
		PrintToChatAll("client[%d] = %N",clientIndex,clientIndex);
	}
	return Plugin_Handled;
}

public Action:Command_PrintSurvivors(client,args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientSurvivor(i)) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Action:Command_PrintInfected(client,args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientInfected(i)) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Action:Command_PrintBots(client,args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientBot(i)) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Action:Command_PrintHumans(client,args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientHuman(i)) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		PrintToChatAll("attacker = %d, entityID = %d, hitgroup = %d, amount = %d, type = %d",
	               GetEventInt(event,"attacker"),
				   GetEventInt(event,"entityid"),
				   GetEventInt(event,"hitgroup"),
				   GetEventInt(event,"amount"),
				   GetEventInt(event,"type"));
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		new String:weapon[100];
		GetEventString(event,"weapon",weapon,sizeof(weapon));
		PrintToChatAll("userID = %d, attacker = %d, attackerEntID = %d, health = %d, armor = %d, weapon = %s, dmg_health = %d, dmg_armor = %d, hitgroup = %d, type = %d",
	               GetEventInt(event,"userid"),GetEventInt(event,"attacker"),
				   GetEventInt(event,"attackerentid"),GetEventInt(event,"health"),
				   GetEventInt(event,"armor"),weapon,
				   GetEventInt(event,"dmg_health"),GetEventInt(event,"dmg_armor"),
				   GetEventInt(event,"hitgroup"),GetEventInt(event,"type"));
	}
	
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		PrintToChatAll("\x01Event \x03PlayerFirstSpawn \x04FIRED!");
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		PrintToChatAll("\x01Event \x03PlayerSpawn \x04FIRED!");
	}
}

public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		PrintToChatAll("\x01Event \x03PlayerBotReplace \x04FIRED!");
	}
}

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_debug) {
		PrintToChatAll("\x01Event \x03BotPlayerReplace \x04FIRED!");
	}
}
// This function determines if a given client index corresponds to a human player
IsClientHuman(client) {
	if (client == 0) {
		return false;
	}
	else if (client > MaxClients) {
		return false;
	}
	else if (client && IsClientInGame(client) && IsClientConnected(client)) {
		if(!IsFakeClient(client)) {
			return true;
		}
		return false;
	}
	return false;
}

// This function determines if a given client index corresponds to a bot
IsClientBot(client) {
	if (client == 0) {
		return false;
	}
	else if (client > MaxClients) {
		return false;
	}
	else if (client && IsClientInGame(client) && IsClientConnected(client)) {
		if (IsFakeClient(client)) {
			return true;
		}
		return false;
	}
	return false;
}

// This function determines if a given client index corresponds to a human player or bot
IsClientAlive(client) {
	if (client == 0) {
		return false;
	}
	else if (client > MaxClients) {
		return false;
	}
	else if (client && IsClientInGame(client) && IsClientConnected(client)) {
		return true;
	}
	return false;
}

// This function determines if a given client index is the Console/World (client index = 0)
IsClientWorld(client) {
	if (client == 0)) {
		return true;
	}
	return false;
}

IsClientSurvivor(client) {
	if (client == 0) {
		return false;
	}
	else if (client > MaxClients) {
		return false;
	}
	else if (client && IsClientInGame(client) && IsClientConnected(client)) {
		if (GetClientTeam(client) == TEAM_SURVIVOR) {
			return true;
		}
		return false;
	}
	return false;
}

IsClientInfected(client) {
	if (client == 0) {
		return false;
	}
	else if (client > MaxClients) {
		return false;
	}
	else if (client && IsClientInGame(client) && IsClientConnected(client)) {
		if (GetClientTeam(client) == TEAM_INFECTED) {
			return true;
		}
		return false;
	}
	return false;
}
