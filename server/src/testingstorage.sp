#pragma semicolon 1

#include <sourcemod>

#define S3_MAXPLAYERS 100

new String:g_playerName[S3_MAXPLAYERS][33];
new String:g_playerSteamID[S3_MAXPLAYERS][20];
new g_playerTeam[S3_MAXPLAYERS];
new bool:g_playerActive[S3_MAXPLAYERS];

new g_survivorKills[S3_MAXPLAYERS][8]; // stores the kills for each survivor for each SI type
new g_survivorDmg[S3_MAXPLAYERS][8];   // stores the dmg for each survivor for each SI type
new g_survivorHitGroupType1[S3_MAXPLAYERS][8]; // hit group counter for hunter, boomer, smoker, zombie, tank
new g_survivorHitGroupType2[S3_MAXPLAYERS][7]; // hit group counter for jockey, charger, spitter
new g_survivorHitGroupTypeSurvivor[S3_MAXPLAYERS][8]; // hit group counter for survivors
new g_survivorFFDmg[S3_MAXPLAYERS];     // friendly fire counter

new g_infectedKills[S3_MAXPLAYERS]; // stores the kills for each SI 
new g_infectedDmg[S3_MAXPLAYERS]; // stores the damage for each SI
new g_infectedFFDmg[S3_MAXPLAYERS]; // stores FF damage for each SI

new g_playerNextAvailableSpot = 0;

// This function obtains a new player ID for storage purposes
// This function will also set the g_playerActive array to true and increment the counter as well SO USE THE NUMBER
// it will return -1 if the system is currently recording the maximum amount of active players
GetNewPlayerID(client) {
	if (IsPlayerTableFull()) {
		for ( new i = 0; i < S3_MAXPLAYERS; i++) {
			if (!IsPlayerIDActive(i)) {
				// delete current date
				return i; // if there is an inactive player then give that spot
			}
		}
	}
	else {
		new newPlayerID = GetNextAvailablePlayerID();
		EnablePlayerID(newPlayerID);
		MoveNextAvailablePlayerID();
		return newPlayerID; // if the player table is not full then return the next spot
	}
	return -1; //basically nothing more can be recorded
}

// this gets a playerID by specifiying a client index
GetPlayerIDOfClient(client) {
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
			if(StrEqual(steamID, g_playerSteamID[i]) && StrEqual(name, g_playerName[i])) {
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

bool:SetPlayerInfo(const String:name[], const String:steamID[]) {

}



bool:RecordKill(playerID, victimType) {

}

bool:RecordDamage(playerID, damage, victimType) {

}

bool:RecordHitGroup(playerID, victimType, hitGroup) {
	if (IsPlayerIDActive(playerID) && (victimType >= 0) && (victimType <= 9)) {
		switch (victimType) {
			case 0,1,5,6,7: {
				if((hitGroup =< 7) && (hitGroup > 0)) {
					g_survivorHitGroupType1[playerID][victimType]++;
					return true;
				}
			}
			case 2,3,4: {
				if((hitGroup =< 5) && (hitGroup >= 0)) {
					g_survivorHitGroupType2[playerID][victimType]++;
					return true;
				}
			}
			case 9: {
				if ((hitGroup >= 49) && (hitGroup <= 55)) {
					switch (hitGroup) {
						case 49: {
							g_survivorHitGroupTypeSurvivor[playerID][1]++;
							return true;
						}
						case 50: {
							g_survivorHitGroupTypeSurvivor[playerID][2]++;
							return true;
						}
						case 51: {
							g_survivorHitGroupTypeSurvivor[playerID][3]++;
							return true;
						}
						case 52: {
							g_survivorHitGroupTypeSurvivor[playerID][4]++;
							return true;
						}
						case 53: {
							g_survivorHitGroupTypeSurvivor[playerID][5]++;
							return true;
						}
						case 54: {
							g_survivorHitGroupTypeSurvivor[playerID][6]++;
							return true;
						}
						case 55: {
							g_survivorHitGroupTypeSurvivor[playerID][7]++;
							return true;
						}
						default: {
							return false;
						}
					
					}
					g_survivorHitGroupTypeSurvivor[S3_MAXPLAYERS][7]++;
					return true;
				}
			}
			default: {
				return false;
			}
		}
	}
	return false;
}

bool:RecordFFDamage() {

}



bool:EnablePlayerID(playerID) {
	if (IsValidPlayerID(i)) {
		g_playerActive[playerID] = true;
		return true;
	}
	return false;
}

bool:DisablePlayerID(playerID) {
	if (IsValidPlayerID(playerID)) {
		g_playerActive[playerID] = false;
		return true;
	}
	return false;
}

// checks to see if the player array is full or not
bool:IsPlayerTableFull() {
	if (g_playerNextAvailableSpot == S3_MAXPLAYERS) {
		return true;
	}
	return false;
}

// checks to see if a player id is active by using a client index
bool:IsPlayerIDActiveByClient(client) {
	new playerID = -1;
	if (IsClientAlive(client)) {
		playerID = GetPlayerIDOfClient(client);
	}
	
	if (IsValidPlayerID(playerID)) {
		return g_playerActive[playerID];
	}
	return false;
}

// checks to see if a player id is active
bool:IsPlayerIDActive(playerID) {
	if (IsValidPlayerID(playerID)) {
		return g_playerActive[playerID]
	}
	return false;
}

bool:IsValidPlayerID(playerID) {
	if ((playerID < S3_MAXPLAYERS) && !(playerID < 0)) {
		return true;
	}
	return false;
}

MoveNextAvailablePlayerID() {
	g_playerNextAvailableSpot++;
}

GetNextAvailablePlayerID() {
	return g_playerNextAvailableSpot;
}








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


public Plugin:myinfo = {
		   name = "Test Storage System",
		 author = "sauce",
	description = "Storage System",
		version = "0.0.1"
};

public OnPluginStart() {

}