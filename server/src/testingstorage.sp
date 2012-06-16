#pragma semicolon 1

#include <sourcemod>

#define S3_MAXPLAYERS 255

new String:g_playerName[S3_MAXPLAYERS][33];
new String:g_playerSteamID[S3_MAXPLAYERS][20];
new bool:g_playerActive[S3_MAXPLAYERS];

new g_survivorKills[S3_MAXPLAYERS][8]; // stores the kills for each survivor for each SI type
new g_survivorDmg[S3_MAXPLAYERS][8];   // stores the dmg for each survivor for each SI type
new g_survivorHeadShots[S3_MAXPLAYERS]; // headshot counter
new g_survivorFFDmg[S3_MAXPLAYERS];     // friendly fire counter

new g_infectedKills[S3_MAXPLAYERS]; // stores the kills for each SI 
new g_infectedDmg[S3_MAXPLAYERS]; // stores the damage for each SI
new g_infectedFFDmg[S3_MAXPLAYERS]; // stores FF damage for each SI



IsPlayerActive(client) {
	new playerID = -1;
	if (IsClientBot(client)) {
		playerID = GetBotPlayerIDByClient(client);
	}
	else if (IsClientHuman(client)) {
		playerID = GetPlayerIDByClient(client);
		
	}
	if (playerID != -1) {
		return g_playerActive[playerID];
	}
	return false;
}

GetPlayerIDByClient(client) {
	if (IsClientHuman(client)) {
		new String:steamID[20];
		GetClientAuthString(client,steamID,sizeof(steamID));
		return GetPlayerIDBySteamID(steamID);
	}
	else if (IsClientBot(client)) {
		new String:steamID[20];
		GetClientAuthString(client,steamID,sizeof(steamID));
		
		new String:name[33];
		GetClientName(client, name, sizeof(name));
		for (new i = 0; i < S3_MAXPLAYERS; i++) {
			if(StrEqual(steamID, g_playerSteamID[i]) && StrEqual(steamID, g_playerSteamID[i])) {
				return i;
			}
		}
	}
	return -1;
}

GetPlayerIDBySteamID(const String:steamID) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		if(StrEqual(steamID, g_playerSteamID[i])) {
			return i;
		}
	}
	return -1;
}

public Plugin:myinfo = {
		   name = "Test Storage System",
		 author = "sauce",
	description = "Storage System",
		version = "0.0.1"
};

public OnPluginStart() {

}