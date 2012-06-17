/* ****************************************************************************
* Simple Survival Stats
* By sauce & guyguy
* 
* This plugin basically displays damage
* stats, kill stats, FF stats, and headshot stats
*
* Usage:        !stats [detail] <--- personal summarized stats
*           !stats all [detail] <--- summarized stats
*           !stats mvp [detail] <--- round stats with MVP info
*		 !stats <name> [detail] <--- stats for specific player
*		               [detail] <--- optional detail flag for more information
*          !resetstats          <--- Admin Command for resetting stats
*
* Code Index: 1.000 MAIN COMPILER DIRECTIVES
*             2.000 PLUGIN INFORMATION
*             3.000 GLOBAL CONSTANTS
*             4.000 GLOBAL VARIABLES
*             5.000 GENERAL CALLBACK FUNCTIONS
*             6.000 ADMIN COMMAND FUNCTIONS
*			  7.000 CONSOLE COMMAND FUNCTIONS
*			  8.000 EVENT CALLBACK FUNCTIONS
*             9.000 HELPER FUNCTIONS
* 
* Features to add: Granular Weapon Stats (requested by phoenix)
*                  Headshot % not count (requested by sauce)
*                  Granular Zombie Stats (requested by sauce)
*                  Granular Item Usage Stats (requested by sauce)
*                  Data collection via sql and sqllite databases (requested by sauce)
*                  Web interface for viewing stats (requested by sauce)
*                  Add support for witches
*                  Add support for coop, scavanenge, versus, realism, realism versus
*                  Add mutation support
* Acknowledgements: beatslaughter   - for code from his survival helpers plugin
*                   Domino Effect   - for pre-alpha testing
*                   phoenix_advance - for pre-alpha testing 
*                   trash           - for pre-alpha testing
*                   aTastyCookie    - for pre-alpha testing
*
**************************************************************************** */

/* [1.000]***************MAIN COMPILER DIRECTIVES*************** */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools> // needed to check the state of the game

#define MAXENTITIES 2048
#define S3_MAXPLAYERS 150 // maximum amount of players to track data for
#define DEBUG 0
// when this is 1, debug output displayed for the infected hurt event
#define INFECTED_HURT_DEBUG 1

/* [2.000]***************PLUGIN INFORMATION*************** */
public Plugin:myinfo = {
		   name = "[S3] Simple Survival Stats",
		 author = "sauce & guyguy",
	description = "Statistics collection and display plugin",
		version = "0.0.1"
};

/* [3.000]***************GLOBAL CONSTANTS*************** */

// Constants for different infected types----------------
new const COMMON  = 0;
new const HUNTER  = 1;
new const JOCKEY  = 2;
new const CHARGER = 3;
new const SPITTER = 4;
new const BOOMER  = 5;
new const SMOKER  = 6;
new const TANK    = 7;
new const WITCH   = 8;
new const SURVIVOR = 9;

// Constants for the different teams----------------
new const TEAM_NONE       = 0;
new const TEAM_SPECTATOR  = 1;
new const TEAM_SURVIVOR   = 2;
new const TEAM_INFECTED   = 3;

// Constants for different CI model ids-------------
// NOTE: Works for survival mode only. In the future, check the cvar
// BIO_ZOMBIE (Port Sacrifice)           270
// BIO_ZOMBIE (Traincar)                 440
// CONSTRUCTION_ZOMBIE (sugar mill)      256
// CONSTRUCTION_ZOMBIE (burger tank)     309
// CLOWN_ZOMBIE (Concert)                197
// CLOWN_ZOMBIE (Stadium gate)           259
// RIOT_ZOMBIE                           232
// SURVIVOR_ZOMBIE (riverbank)           212
// SURVIVOR_ZOMBIE (underground)         283

// witch 253 (unused for now)
new const NUM_SPECIAL_ZOMBIES = 9;
new const SPECIAL_ZOMBIE_ID[] =  {270, 440, 256, 309, 197, 259, 232, 212, 283};
new const SPECIAL_ZOMBIE_HP[] =  {150, 150, 150, 150, 150, 150, 50, 1000, 1000};
new const DEFAULT_HP = 50;

// Left 4 Dead 2 weapon names-----------------------
new const NUM_WEAPONS = 47;
//! \brief these are the weapon names obtained through a call to GetClientWeapon()
new const String:WEAPON_NAMES[][64] =
{
	"weapon_autoshotgun",
	"weapon_grenade_launcher",
	"weapon_hunting_rifle",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_pumpshotgun",
	"weapon_rifle",
	"weapon_rifle_ak47",
	"weapon_rifle_desert",
	"weapon_rifle_m60",
	"weapon_rifle_sg552",
	"weapon_shotgun_chrome",
	"weapon_shotgun_spas",
	"weapon_smg",
	"weapon_smg_mp5",
	"weapon_smg_silenced",
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_baseball_bat",
	"weapon_cricket_bat",
	"weapon_crowbar",
	"weapon_electric_guitar",
	"weapon_fireaxe",
	"weapon_frying_pan",
	"weapon_golfclub",
	"weapon_katana",
	"weapon_machete",
	"weapon_tonfa",
	"weapon_knife",
	"weapon_chainsaw",
	"weapon_adrenaline",
	"weapon_defibrillator",
	"weapon_first_aid_kit",
	"weapon_pain_pills",
	"weapon_fireworkcrate",
	"weapon_gascan",
	"weapon_oxygentank",
	"weapon_propanetank",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_ammo_spawn",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary",
	"weapon_gnome",
	"weapon_cola_bottles"
};

//! \brief These are the sniper weapons that can instantly kill a common infected in normal difficulty
new const NUM_INSTAKILL_WEAPONS = 5;
new const String:INSTAKILL_WEAPONS[][64] =
{
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_hunting_rifle",
	"weapon_chainsaw"
};

// This array of game modes is a list of gamemodes that the plugin is compatible with.
// We will add to this as various gamemode support is added
new const NUM_GAMEMODES = 1;
new const String:GAME_MODES[][64] = {
	"survival"
};


// some gamestate variables from the roundstatetracker plugin that I made
// I'm putting this here temporarily...
new const NUM_ROUNDSTATES = 11;
new const String:ROUND_STATES[][30] = {
	"mapstarted", // 0
	"mapended",   // 1             
	"roundfreezeend", // 2
	"roundstartpreentity", // 3
	"roundstartpostnav", // 4
	"roundend", // 5
	"scavengeroundstart", // 6
	"scavengeroundhalftime", // 7
	"scavengeroundfinished", // 8
	"versusroundstart", // 9
	"survivalroundstart" // 10
};

/* [4.000]***************GLOBAL VARIABLES*************** */

// global variables that track survivor data
new String:g_playerName[S3_MAXPLAYERS][50];    // stores player name
new String:g_playerSteamID[S3_MAXPLAYERS][50]; // stores player steam id
new g_playerTeam[S3_MAXPLAYERS];               // stores player team
new bool:g_playerActive[S3_MAXPLAYERS];        // if player is active or not
new g_playerNextAvailableSpot = 0;             // the next available spot for new player

new g_survivorKills[S3_MAXPLAYERS][9]; // stores the kills for each survivor for each SI type
new g_survivorDmg[S3_MAXPLAYERS][9];   // stores the dmg for each survivor for each SI type
new g_survivorHitGroupType1[S3_MAXPLAYERS][8]; // hit group counter for hunter, boomer, smoker, zombie, tank, witch
new g_survivorHitGroupType2[S3_MAXPLAYERS][7]; // hit group counter for jockey, charger, spitter
new g_survivorHitGroupTypeSurvivor[S3_MAXPLAYERS][8]; // hit group counter for survivors
new g_survivorFFDmg[S3_MAXPLAYERS];     // friendly fire counter
new g_survivorTotalKills[9];            // total kills
new g_survivorTotalDmg[9];              // total damage
new g_survivorHealth[S3_MAXPLAYERS];
new g_survivorDmgToTank[S3_MAXPLAYERS][S3_MAXPLAYERS];

new g_infectedKills[S3_MAXPLAYERS]; // stores the kills for each SI 
new g_infectedDmg[S3_MAXPLAYERS]; // stores the damage for each SI
new g_infectedFFDmg[S3_MAXPLAYERS]; // stores FF damage for each SI
new g_infectedHealth[S3_MAXPLAYERS];

// global variables that track CI data
new CIHealth[MAXENTITIES];        // Tracks health of every common infected. This is inefficient memory usage since not all entities (array elements) are common infected.

// global variables that deal with current game state
new g_roundEnded = false;
new g_collectStats = false;
new g_loadLate     = false;

// cvar handles

new Handle:g_roundTrackerState = INVALID_HANDLE;

/* [5.000]***************GENERAL CALLBACK FUNCTIONS*************** */
public OnPluginStart() {
	
	// events to hook into
	// HookEvent("player_hurt", Event_PlayerHurt);
	// HookEvent("player_death", Event_PlayerDeath); // not needed
	HookEvent("player_spawn", Event_PlayerSpawn);
	// HookEvent("infected_hurt", Event_InfectedHurt);
	// HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("survival_round_start", Event_RoundStart);
	// HookEvent("player_first_spawn", Event_PlayerFirstSpawn); //replaced with player_spawn
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	
	// Admin commands - these are not usable by non admin users
	RegAdminCmd("sm_resetstats", Command_ResetStats,ADMFLAG_GENERIC);

	// Debug commands for developers

	RegAdminCmd("sm_printtracked", Command_PrintTracked, ADMFLAG_GENERIC);
	RegAdminCmd("sm_statson", Command_StatsOn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_statsoff", Command_StatsOff, ADMFLAG_GENERIC);
	
	// Console/User commands - these are usable by all users
	// RegConsoleCmd("sm_stats", Command_Stats); // accepted args "!stats <name>, !stats all, !stats mvp, !stats 
	
	// cvar processing
	g_roundTrackerState = FindConVar("g_roundTrackerState");
	
	// check if plugin was loaded late
	if (g_loadLate) {
		PreparePlayersForStatsCollect();
		new String:roundState[30];
		GetConVarString(g_roundTrackerState,roundState, sizeof(roundState));
		
		if (StrEqual(ROUND_STATES[10],roundState,false) ||
		    StrEqual(ROUND_STATES[9],roundState,false) ||
			StrEqual(ROUND_STATES[7],roundState,false) ||
			StrEqual(ROUND_STATES[6],roundState,false)) { // if the game is running make sure stats can be collected
			g_collectStats = true;
		}
	}
}



public OnMapStart() {
	g_collectStats = false;
}

// This function is called before OnPluginStart. This is to check for late load

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	g_loadLate = late;
	return APLRes_Success;
}


/* [6.000]***************ADMIN COMMAND FUNCTIONS*************** */
public Action:Command_StatsOn(client, args) {
	g_collectStats = true;
	return Plugin_Handled;
}

public Action:Command_StatsOff(client, args) {
	g_collectStats = false;
	return Plugin_Handled;
}

public Action:Command_PrintTracked(client, args) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		new playerID = GetPlayerIDOfClient(i);
		if(IsClientAlive(i) && IsPlayerActive(playerID)) {
			PrintToChatAll("collectStats = %d client: %d playerID: %d playerName: %s steamID: %s %N",g_collectStats, i, playerID, g_playerName[playerID], g_playerSteamID[playerID]);
		}
	}
	return Plugin_Handled;
}

//--------------------------------------------------
// ResetStats
//!
//! \brief Use this function to reset the kill and damage arrays to zero
//--------------------------------------------------
public Action:Command_ResetStats(client, args) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		for (new j = 0; j < S3_MAXPLAYERS; j++) {
			g_survivorDmgToTank[i][j] = 0;
			if (j < 9) {
				g_survivorKills[i][j] = 0;
				g_survivorDmg[i][j] = 0;
				if (j < 8) {
					g_survivorHitGroupType1[i][j] = 0;
					g_survivorHitGroupTypeSurvivor[i][j] = 0;
				}
				if (j < 7) {
					g_survivorHitGroupType2[i][j] = 0;
				}
			}
			
			
		}
		if (i < 9) {
			g_survivorTotalKills[i] = 0;
			g_survivorTotalDmg[i] = 0;
		}
		
		g_infectedKills[i] = 0;
		g_infectedDmg[i] = 0;
		g_infectedFFDmg[i] = 0;
		g_infectedHealth[i] = 0;
		
		g_playerName[i] = "";
		g_playerSteamID[i] = "";
		g_playerTeam[i] = 0;
		g_playerActive[i] = false;
		g_survivorFFDmg[i] = 0;
		g_survivorHealth[i] = 0;
		
	}
	g_playerNextAvailableSpot = 0; 
	ResetCIHealth();
	
	if (IsClientHuman(client)) {
		PrintToChat(client,"\x01Stats have been \x04RESET");
	}
	return Plugin_Handled;
}

/* [7.000]***************CONSOLE COMMAND FUNCTIONS*************** */



/* [8.000]***************EVENT CALLBACK FUNCTIONS*************** */


// Infected Events


//--------------------------------------------------
// Event_InfectedHurt
//!
//! \brief     This calculates the damage done to common infected.
//! \details   Part of the complications in the calculation is due to the fact that real damage is not shown. Example: A weapon might do 90 damage but the zombie has only 10 health remaining. The actual damage should be 10, but the recorded amount is 90. To compensate for this, the common health are tracked in an array and the real damage is updated accordingly.
//--------------------------------------------------



// Round Events

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	Command_ResetStats(0,0);
	g_roundEnded = false;
	Command_StatsOn(0,0);
	
	// initialize survivors for stats collection
	PreparePlayersForStatsCollect();
	
#if DEBUG
	PrintToChatAll("\x01Event_RoundStart \x04FIRED[ResetStats(0,0); g_roundEnded = false; g_collectStats = true;]");
#endif
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!g_roundEnded) {
		// PrintStats(0, 10000,false);
		g_roundEnded = true;
	}
	Command_StatsOff(0,0);
}

// Player state events

public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientAlive(client)) {
		new playerID = GetPlayerIDOfClient(client);
		if (playerID == -1) { // if player doesn't exist in database
			playerID = GetNewPlayerID(client);
		}
		else if (IsValidPlayerID(playerID) && !IsPlayerActive(playerID)) { // if player is not active
			EnablePlayerID(playerID);
		}
		
		if (IsPlayerActive(playerID)) {
			SetPlayerHealth(playerID, GetClientHealth(client));
		}
	}
}


public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client   = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if (IsClientSurvivor(client) || IsClientInfected(client)) {
		new playerID = GetPlayerIDOfClient(client);
		if (IsValidPlayerID(playerID) && IsPlayerActive(playerID)) {
			DisablePlayerID(playerID);
		}
	}
}


public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	new bot    = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsClientHuman(player) && IsClientBot(bot)) {
		
		new playerID = GetPlayerIDOfClient(player);
		new botPlayerID = GetPlayerIDOfClient(bot);
		
		if (botPlayerID == -1) {
			botPlayerID = GetNewPlayerID(bot);
		}
		else if (IsValidPlayerID(botPlayerID) && !IsPlayerActive(botPlayerID)) {
			EnablePlayerID(botPlayerID); // enable stats for bot
		}
		// disable stats for player	
		DisablePlayerID(playerID);
		
	}
}

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	new bot    = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsClientSurvivor(player) && IsClientBot(bot)) {

		new playerID = GetPlayerIDOfClient(player);
		new botPlayerID = GetPlayerIDOfClient(bot);
		
		if (playerID == -1) {
			playerID = GetNewPlayerID(player);
		}
		else if (IsValidPlayerID(playerID) && !IsPlayerActive(playerID)) {
			EnablePlayerID(playerID); // enable stats for player
		}
		// disable stats for bot
		DisablePlayerID(botPlayerID);
		
	}
}


/* [9.000]***************HELPER FUNCTIONS*************** */



PreparePlayersForStatsCollect() {
	for (new i = 1; i < MaxClients; i++) {
		if (IsClientSurvivor(i) || IsClientInfected(i)) {
			new playerID = GetPlayerIDOfClient(i);
			
			
			if (playerID == -1) {
				playerID = GetNewPlayerID(i);
			}
			else if (IsValidPlayerID(playerID) && !IsPlayerActive(playerID)) {
				EnablePlayerID(playerID);
			}
			
			if (IsPlayerActive(playerID)) {
				SetPlayerHealth(playerID, GetClientHealth(i));
			}
		}
	}
}


// This rates performance based on tank damage, SI kill,s and CI kills
// There is 3 times weight given to taken damage, 2 times weight given to SI kills
// and CIKills are taken as they are.
// These added together gives a performance rating
// This function will change overtime as the plugin gets more complex
// I want to add things like kits, pills, adren, and other items used

RatePerformance(TankDamage, SIKills, CIKills) {
	/* 
	Criteria
	
	1. Tank Damage x 3 Weight
	2. SI Kills x 2 Weight
	3. CI Kills x 1 Weight
	
	*/
	new rating = 0;
	rating += (TankDamage*3);
	rating += (SIKills*2);
	rating += CIKills;
	return rating;
	
}


// prints tank damage statistics after each tank kill in the chat output 


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

//--------------------------------------------------
// ResetCIHealth
//!
//! \brief Resets the CI health array to zero
//--------------------------------------------------

ResetCIHealth() {
	for (new i = 0; i < MAXENTITIES; i++) {
		CIHealth[i] = 0;
	}
}

//--------------------------------------------------
// TotalDamage
//!
//! \brief Adds up all damages and puts the totals into the array
//!
//! \param[out] total_array An existing array of 8 integers (7 SI and 1 Common). This will store the total damage outputs.
//! \param[out] total_array An existing array of 8 integers (7 SI and 1 Common). This will store the total kill outputs.
//--------------------------------------------------

TotalDamage(total_damage_array[], total_kills_array[]) {
	// first zero out the array
	for (new i = 0; i < 8; i++) {
		total_kills_array[i] = 0;
		total_damage_array[i] = 0;
	}

	// now add all damages from the different clients that are connected and on the survivor team
	for (new i = 1; i < MaxClients; i++) {
		// if (IsClientConnected(i) && IsClientInGame(i)) {
			// new team = GetClientTeam(i);

			// if (team == TEAM_SURVIVOR && !IsFakeClient(i)) {
				// go through the 8 different types of infected (7 SI, 1 common)
		if (IsClientSurvivor(i)) {
			for (new j = 0; j < 8; j++) {
				total_kills_array[j] += survivorKills[i][j];
				total_damage_array[j] += survivorDmg[i][j];
			} // end inner for loop
		}
			// }
		// }
	} // end outer for loop
}

// This function returns the client index that corresponds to a given name (string)
GetSurvivorByName(String:name[33]) {
	for (new i = 1; i < MaxClients; i++) {
		if (IsClientSurvivor(i)) {
			new String:clientName[33];
			GetClientName(i, clientName, sizeof(clientName));
			if (StrContains(clientName, name, false) == 0) {
				return i;
			}
		}
	}
	return -1; //doesn't exist
}

/* ***** Data Management Functions ****** */

// zeros out all data for a specific playerID
WipePlayerData(playerID) {
	for (new i = 0; i < 9; i++) {
		g_survivorKills[playerID][i] = 0;
		g_survivorDmg[playerID][i] = 0;
		if (i < 8) {
			g_survivorHitGroupType1[playerID][i] = 0;
			g_survivorHitGroupTypeSurvivor[playerID][i] = 0;
		}
		if(i < 7) {
			g_survivorHitGroupType2[playerID][i] = 0;
		}
		
	}
	g_playerTeam[playerID] = TEAM_NONE;
	g_survivorFFDmg[playerID] = 0;
	g_playerName[playerID] = "";
	g_playerSteamID[playerID] = "";
}

// This function obtains a new player ID for storage purposes
// This function will also set the g_playerActive array to true and increment the counter as well SO USE THE NUMBER
// it will return -1 if the system is currently recording the maximum amount of active players
GetNewPlayerID(client) {
	if (IsClientAlive(client)) {
		new String:name[33];
		new String:steamID[20];
		new team = 0;
		GetClientName(client,name, sizeof(name));
		GetClientAuthString(client, steamID, sizeof(steamID));
		team = GetClientTeam(client);
		
		if (IsPlayerTableFull()) {
			for ( new i = 0; i < S3_MAXPLAYERS; i++) {
				if (!IsPlayerActive(i)) {
					// delete current date
					WipePlayerData(i);
					EnablePlayerID(i);
					SetPlayerInfo(i, team, name, steamID);
					return i; // if there is an inactive player then give that spot
				}
			}
		}
		else if (!IsPlayerTableFull()) {
			new newPlayerID = GetNextAvailablePlayerID();
			EnablePlayerID(newPlayerID);
			MoveNextAvailablePlayerID();
			SetPlayerInfo(newPlayerID, team, name, steamID);
			return newPlayerID; // if the player table is not full then return the next spot
		}
	}
	return -1; //basically nothing more can be recorded
}

// this gets a playerID by specifiying a client index, this player ID could be active or inactive
// you must check to see if it's active or not, and reactivate if necessary
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

GetPlayerIDBySteamID(const String:steamID[]) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		if(StrEqual(steamID, g_playerSteamID[i])) {
			return i;
		}
	}
	return -1;
}

bool:SetPlayerInfo(playerID, team, const String:name[], const String:steamID[]) {
	g_playerName[playerID] = name;
	g_playerSteamID[playerID] = steamID;
	g_playerTeam[playerID] = team;
}

bool:SetPlayerHealth(playerID, health) {
	if (IsValidPlayerID(playerID) && IsPlayerActive(playerID)) {
		if (IsPlayerSurvivor(playerID)) {
			g_survivorHealth[playerID] = health;
		}
		else if (IsPlayerInfected(playerID)) {
			g_infectedHealth[playerID] = health;
		}
	}
}

bool:IsPlayerSurvivor(playerID) {
	if (IsValidPlayerID(playerID))  {
		if (g_playerTeam[playerID] == TEAM_SURVIVOR) {
			return true;
		}
	}
	return false;
}

bool:IsPlayerInfected(playerID) {
	if (IsValidPlayerID(playerID)) {
		if (g_playerTeam[playerID] == TEAM_INFECTED) {
			return true;
		}
	}
	return false;
}

bool:IsPlayerHuman(playerID) {
	if (IsValidPlayerID(playerID)) {
		if (!StrEqual(g_playerSteamID, "BOT", false) && (strlen(g_playerSteamID) > 10)) {
			return true;
		}
	}
}

bool:IsPlayerBot(playerID) {
	if (IsValidPlayerID(playerID)) {
		if (StrEqual(g_playerSteamID, "BOT", false)) {
			return true;
		}
	}
	return false;
}


bool:RecordKill(playerID, victimType) {
	if((victimType >=0) && (victimType <= 9)) {
		g_survivorKills[playerID][victimType]++;
		g_survivorTotalKills[victimType]++;
		return true;
	}
	return false;
}

bool:RecordDamage(playerID, damage, victimType) {
	if((victimType >=0) && (victimType <= 9)) {
		g_survivorDmg[playerID][victimType] += damage;
		g_survivorTotalDmg[victimType] += damage;
		return true;
	}
	return false;
}

bool:RecordHitGroup(playerID, victimType, hitGroup) {
	if ((victimType >= 0) && (victimType <= 10)) {
		switch (victimType) {
			case 0,1,5,6,7,8: {
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

RecordFFDamage(playerID, damage) {
	g_survivorFFDmg[playerID] += damage;
}



EnablePlayerID(playerID) {
	g_playerActive[playerID] = true;
}

DisablePlayerID(playerID) {
	g_playerActive[playerID] = false;
}

// checks to see if the player array is full or not
bool:IsPlayerTableFull() {
	if (g_playerNextAvailableSpot == S3_MAXPLAYERS) {
		return true;
	}
	return false;
}

// checks to see if a player id is active by using a client index
bool:IsPlayerActiveByClient(client) {
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
bool:IsPlayerActive(playerID) {
	return g_playerActive[playerID];
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



