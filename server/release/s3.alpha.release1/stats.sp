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
*                  Improve name search
* Acknowledgements: beatslaughter   - for code from his survival helpers plugin
*                   Domino Effect   - for pre-alpha testing
*                   phoenix_advance - for pre-alpha testing 
*                   trash           - for pre-alpha testing
*                   aTastyCookie    - for pre-alpha testing
*                   Azimuth         - for pre-alpha testing
*                   
*
**************************************************************************** */

/* [1.000]***************MAIN COMPILER DIRECTIVES*************** */
#pragma semicolon 1

#include <sourcemod>
#include <sdktools> // needed to check the state of the game

#define MAXENTITIES 2048
#define S3_MAXPLAYERS 150 // maximum amount of players to track data for
#define DEBUG 0
#define DEBUG_MVP 0
// when this is 1, debug output displayed for the infected hurt event
#define INFECTED_HURT_DEBUG 0


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
new const NUM_GAMEMODES = 2;
new const String:GAME_MODES[][64] = {
	"survival",
	"hardtwentysurvival"
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
new String:g_playerName[S3_MAXPLAYERS][33];    // stores player name
new String:g_playerSteamID[S3_MAXPLAYERS][20]; // stores player steam id
new g_playerTeam[S3_MAXPLAYERS];               // stores player team
new bool:g_playerActive[S3_MAXPLAYERS];        // if player is active or not
new g_playerHealth[S3_MAXPLAYERS];
new g_playerNextAvailableSpot = 0;             // the next available spot for new player
new g_playerMaxHealth[S3_MAXPLAYERS];
new g_playerRating[S3_MAXPLAYERS];

new g_survivorKills[S3_MAXPLAYERS][9]; // stores the kills for each survivor for each SI type
new g_survivorDmg[S3_MAXPLAYERS][9];   // stores the dmg for each survivor for each SI type
new g_survivorHitGroupType1[S3_MAXPLAYERS][8]; // hit group counter for hunter, boomer, smoker, zombie, tank, witch
new g_survivorHitGroupType2[S3_MAXPLAYERS][6]; // hit group counter for jockey, charger, spitter
new g_survivorHitGroupTypeSurvivor[S3_MAXPLAYERS][8]; // hit group counter for survivors
new g_survivorFFDmg[S3_MAXPLAYERS];     // friendly fire counter
new g_survivorTotalKills[9];            // total kills
new g_survivorTotalDmg[9];              // total damage

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
new g_printTankStats = false;
new String:g_gameMode[30];
// cvar handles

new Handle:cv_roundTrackerState = INVALID_HANDLE;
new Handle:cv_collectStats      = INVALID_HANDLE;
new Handle:cv_printTankStats    = INVALID_HANDLE;

/* [5.000]***************GENERAL CALLBACK FUNCTIONS*************** */
public OnPluginStart() {
	// store current gamemode
	GetConVarString(FindConVar("mp_gamemode"), g_gameMode, sizeof(g_gameMode));
	
	if (IsSupportedGameMode(g_gameMode)) {
	
		// events to hook into
		HookEvent("player_hurt", Event_PlayerHurt);
		// HookEvent("player_death", Event_PlayerDeath); // not needed
		HookEvent("player_spawn", Event_PlayerSpawn);
		HookEvent("infected_hurt", Event_InfectedHurt);
		HookEvent("infected_death", Event_InfectedDeath);
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
		RegAdminCmd("sm_printgamemode", Command_PrintGameMode, ADMFLAG_GENERIC);
		
		// Console/User commands - these are usable by all users
		RegConsoleCmd("sm_stats", Command_Stats); // accepted args "!stats <name>, !stats all, !stats mvp, !stats 
		
		// cvar processing
		cv_roundTrackerState = FindConVar("s3_roundTrackerState");
		cv_collectStats      = FindConVar("s3_collectStats");
		cv_printTankStats    = FindConVar("s3_printTankStats");
		
		
		
		if (cv_collectStats == INVALID_HANDLE) {
			cv_collectStats = CreateConVar("s3_collectStats", "0", "0 don't collect stats, 1 collect stats");
			g_collectStats = false;
		}
		
		if (cv_printTankStats == INVALID_HANDLE) {
			cv_printTankStats = CreateConVar("s3_printTankStats", "0", "0 disable tank damage printout, 1 print tank damage stats after every tank");
			g_printTankStats = false;
		}
		
		// check if plugin was loaded late
		if (g_loadLate) {
			PreparePlayersForStatsCollect();
			new String:roundState[30];
			GetConVarString(cv_roundTrackerState,roundState, sizeof(roundState));
			
			if (cv_roundTrackerState == INVALID_HANDLE) {
				roundState = "mapstarted";
			}
			if (StrEqual(ROUND_STATES[10],roundState,false) ||
				StrEqual(ROUND_STATES[9],roundState,false) ||
				StrEqual(ROUND_STATES[7],roundState,false) ||
				StrEqual(ROUND_STATES[6],roundState,false)) { // if the game is running make sure stats can be collected
				
				Command_StatsOn(0,0);
			}
		}
	}
}

public OnMapStart() {

	Command_StatsOff(0,0);

}

// This function is called before OnPluginStart. This is to check for late load

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	g_loadLate = late;
	return APLRes_Success;
}


/* [6.000]***************ADMIN COMMAND FUNCTIONS*************** */
public Action:Command_StatsOn(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		// enable stats collection
		g_collectStats = true;
		SetConVarInt(cv_collectStats, 1);
		
		// enable tank stats
		g_printTankStats = true;
		SetConVarInt(cv_printTankStats, 1);
	}
	return Plugin_Handled;
}

public Action:Command_StatsOff(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		// disable stats collection
		g_collectStats = false;
		SetConVarInt(cv_collectStats, 0);
		
		// disable tank stats
		g_printTankStats = true;
		SetConVarInt(cv_printTankStats, 0);
	}
	return Plugin_Handled;
}

public Action:Command_PrintTracked(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		PrintToChatAll("g_collectStats = %s client:",(g_collectStats) ? "true" : "false");
		for (new i = 0; i < MaxClients; i++) {
			if(IsValidPlayerID(i) && (strlen(g_playerName[i]) > 0)) {
				PrintToChatAll("g_playerActive = %s client: %d playerID: %d playerName: %s steamID: %s",
				(g_playerActive[i]) ? "true" : "false", i, i, g_playerName[i], g_playerSteamID[i]);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_PrintGameMode(client, args) {
	PrintToChatAll("GameMode = %s", g_gameMode);
}

//--------------------------------------------------
// ResetStats
//!
//! \brief Use this function to reset the kill and damage arrays to zero
//--------------------------------------------------
public Action:Command_ResetStats(client, args) {
	if (IsGameMode("survival")) {
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
					if (j < 6) {
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
			g_playerHealth[i] = 0;
			g_playerMaxHealth[i] = 0;
		}
		g_playerNextAvailableSpot = 0; 
		ResetCIHealth();
		
		
		
		if (IsClientHuman(client)) {
			PrintToChat(client,"\x01Stats have been \x04RESET");
		}
		PreparePlayersForStatsCollect();
	}
	return Plugin_Handled;
}

/* [7.000]***************CONSOLE COMMAND FUNCTIONS*************** */

public Action:Command_Stats(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		new String:arg1[33], String:arg2[33];
		new playerToPrint;

		if (IsClientHuman(client)) { // Process this if the client is a human
			if (args == 1) {
				
				GetCmdArg(1, arg1, sizeof(arg1));
				if (StrEqual(arg1,"all")) {
					PrintStats(client, 10000,false); // print all summarized stats
				}
				else if (StrEqual(arg1, "mvp")) {
					PrintStats(client, 20000, false); // print mvp stats summarized
				}
				else if (StrEqual(arg1, "detail", false)){
					new playerID = GetPlayerIDOfClient(client);
					PrintStats(client, playerID, true); // print personal stats with detail
				}
				else if (StrEqual(arg1, "round", false)) {
					PrintStats(client, 30000, false); // print round stats w/ no detail
				}
				else if (StrEqual(arg1, "weapon", false)) {
					PrintStats(client, 40000, false); // prints
				}
				else { // prints a specific player's stats summarized
				// check to see if name matches to a client
					playerToPrint = GetSurvivorByName(arg1);
					if(playerToPrint != -1) {
						PrintStats(client, playerToPrint, false);
					}
					else {
						PrintToChat(client,"Player: \x04%s not found.", arg1);
					}
				}
			}
			else if(args == 2) {
				GetCmdArg(1, arg1, sizeof(arg1));
				GetCmdArg(2, arg2, sizeof(arg2));
				if (StrEqual(arg2, "detail")) {
					if (StrEqual(arg1,"all")) {
						PrintStats(client, 10000,true); // print all stats with detail
					}
					else if (StrEqual(arg1, "mvp")) {
						PrintStats(client, 20000, true); // print mvp stats with detail
					}
					else if (StrEqual(arg1, "round")) {
						PrintStats(client, 30000, true); // print detailed round stats
					}
					else if (StrEqual(arg1, "weapon")) {
						PrintStats(client, 40000, true); // print detailed weapon stats
					}
					else { // print a specific player's stats with detail
						playerToPrint = GetSurvivorByName(arg1);
						if(playerToPrint != -1) {
							PrintStats(client, playerToPrint, true);
						}
						else {
							PrintToChat(client,"%s not found", arg1);
						}
					}
				}
			}
			else if (args == 0) {
				new playerID = GetPlayerIDOfClient(client);
				PrintStats(client,playerID,false); // print personal stats summarized
			}
		}
	}
	return Plugin_Handled;
}



/* [8.000]***************EVENT CALLBACK FUNCTIONS*************** */

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast) {
	
	if (g_collectStats) { // collect stats if stats collection is enabled
		// other info
		new damage   = GetEventInt(event, "dmg_health");
		new hitgroup = GetEventInt(event, "hitgroup");
		
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new victimRemainingHealth = GetEventInt(event, "health");
		new victimPID = GetPlayerIDOfClient(victim);
		
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new attackerPID = GetPlayerIDOfClient(attacker);
		
		
		if ((damage > 0) && IsClientAlive(victim) && IsClientAlive(attacker) && IsValidPlayerID(attackerPID) && IsValidPlayerID(victimPID)) { // process further if damage is 0, and victim and attacker clients are real
			if (IsClientSurvivor(attacker)) {
				// process victim
				new String:victimModel[50];
				new victimTeam = GetPlayerTeam(victimPID);

				GetClientModel(victim,victimModel, sizeof(victimModel));
				
				if (victimTeam == TEAM_SURVIVOR) {
					RecordFFDamage(attackerPID, damage);
				}
				else if (victimTeam == TEAM_INFECTED) {
					
					if (StrContains(victimModel, "Hunter", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, HUNTER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),HUNTER);
						}
						else {
							RecordDamage(attackerPID,damage,HUNTER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,HUNTER);
					}
					else if (StrContains(victimModel, "Jockey", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, JOCKEY);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),JOCKEY);
						}
						else {
							RecordDamage(attackerPID,damage,JOCKEY);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,JOCKEY);
					}
					else if (StrContains(victimModel, "Charger", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, CHARGER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),CHARGER);
						}
						else {
							RecordDamage(attackerPID,damage,CHARGER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,CHARGER);
					}
					else if (StrContains(victimModel, "Spitter", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, SPITTER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),SPITTER);
						}
						else {
							RecordDamage(attackerPID,damage,SPITTER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,SPITTER);
					}
					else if (StrContains(victimModel, "Boome", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, BOOMER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),BOOMER);
						}
						else {
							RecordDamage(attackerPID,damage,BOOMER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,BOOMER);
					}
					else if (StrContains(victimModel, "Smoker", false) != -1) {
						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, SMOKER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),SMOKER);
						}
						else {
							RecordDamage(attackerPID,damage,SMOKER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,SMOKER);
					}
					else if (StrContains(victimModel, "Hulk", false) != -1) {
						if(IsTankIncapacitated(victim) && IsPlayerActive(victimPID)) {
							// PrintToChatAll("Tank Incapped. Damage = %d, Tank health = %d",GetPlayerHealth(victimPID),GetPlayerHealth(victimPID));
							
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),TANK);
							RecordKill(attackerPID,TANK);
							RecordTankDamage(attackerPID,victimPID, GetPlayerHealth(victimPID));
							
							// Print Tank Stats
							PrintTankStats(victimPID);
							
							// Manage Tank
							DisablePlayerID(victimPID);
							SetPlayerHealth(victimPID, 0);
							WipeTankStats(victimPID);
						}
						else if (IsPlayerActive(victimPID)) {
							
							RecordDamage(attackerPID,damage,TANK);
							DamagePlayer(victimPID, damage);
							RecordTankDamage(attackerPID, victimPID, damage);
							// PrintToChatAll("TD: Damage = %d, Tank health = %d",damage,GetPlayerHealth(victimPID));
						}
					}
				}
			}
			// else if (IsClientInfected(attacker)) {
				// this will be implemented later
			// }
			if (victimRemainingHealth == 0) {
				DisablePlayerID(victimPID);
				SetPlayerHealth(victimPID,0);
			}
		}
	
		
	}
}
//--------------------------------------------------
// Event_InfectedHurt
//!
//! \brief     This calculates the damage done to common infected.
//! \details   Part of the complications in the calculation is due to the fact that real damage is not shown. Example: A weapon might do 90 damage but the zombie has only 10 health remaining. The actual damage should be 10, but the recorded amount is 90. To compensate for this, the common health are tracked in an array and the real damage is updated accordingly.
//--------------------------------------------------
public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//--------------------------------------------------
	// Local Variables:
	//
	// attacker    - client index of the attacker
	// victim      - entity index of the victim common infected
	// damage      - the full damage amount the weapon did, may exceed the common's health
	// hitgroup    - 1 for headshot, etc
	// realdamage  - the calculated damage so that the damage does not exceed teh common's health
	// model_id    - The model id, which identifies if the zombies is a special type of zombie such as construction worker
	// max_hp      - The maximum hp of the zombie. This depends on the type of zombie. Special zombies have different healths other than the default health of 50 for survival mode.
	//--------------------------------------------------
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetEventInt(event, "entityid");
	new attackerPID = GetPlayerIDOfClient(attacker);
	
	// retrieve the damage and hitgroup
	new damage = GetEventInt(event, "amount");
	new original_damage = damage;
	new hitgroup = GetEventInt(event, "hitgroup");
	new type = GetEventInt(event, "type");
	new realdamage;
	new model_id;
	decl String:weapon[64];
	
	if (g_collectStats && IsValidPlayerID(attackerPID) && IsClientSurvivor(attacker)) {
		// get the attackers weapon
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		// get the model index of the damaged zombie
		model_id = GetEntProp(victim, Prop_Send, "m_nModelIndex");

		new maxhp = DEFAULT_HP;

		// check to see if the victim is a special zombie
		for (new i = 0; i < NUM_SPECIAL_ZOMBIES; i++) {

			// if it is a special zombie, change the hp accordingly
			if (model_id == SPECIAL_ZOMBIE_ID[i]) {
				maxhp = SPECIAL_ZOMBIE_HP[i];
			}
		}

		// if the CIHealth for some reason is over the max, adjust it
		CIHealth[victim] = CIHealth[victim] % maxhp;

		new bool:instakill_weapon = false;

		// run through all the instakill weapons and check
		for (new i = 0; i < NUM_INSTAKILL_WEAPONS; i++) {
			if (StrEqual(weapon, INSTAKILL_WEAPONS[i]) == true) {
				instakill_weapon = true;
			}
		}

		// Make sure not fire dmg (8 or 2056)
		// Also check to see if the shot was a headshot. If the shot was a headshot, the damage should be modified so that the shot is a killing blow. Exception: survivor zombie (ID 283).
		// As well, check if it is an insta-kill weapon, which will destroy the zombie in one shot regardless of the hitgroup.
		if ((type != 2056 && type != 8) && (GetEventInt(event, "hitgroup") == 1 || instakill_weapon == true) && model_id != 283) {
			damage = maxhp;
		}
		// if the damage is 0 (due to fire), modify the damage to a killing blow.
		// fire damage is type 2056 or type 8
		if (type == 2056 || type == 8)
		{
			// if the zombie is biohazard (440) however, zero damage applied
			if (model_id == 440)
				damage = 0;
			else
				damage = maxhp;
		}

		// Special case: survivor zombies (model ids 212 and 283) use the original damage. Change this back except for headshots.
		if ((model_id == 212 || model_id == 283) && hitgroup != 1)
		{
			damage = original_damage;
		}

		// Now check the zombie's remaining health. If the health value in the zombie health array is zero, we assume the zombie was at full health before the damage was dealt.
		if (CIHealth[victim] <= 0) {
			CIHealth[victim] = maxhp;
		}

		// if the shot is beyond the CIHealth, modify the damage so that it is simply equal to the hp (killing blow)
		if (damage > CIHealth[victim]) {
			realdamage = CIHealth[victim];
		}
		else {
			realdamage = damage; // otherwise the damage is unchanged
		}

		// decrease the health of the zombie by the realdamage.
		CIHealth[victim] -= realdamage;
		
		RecordDamage(attackerPID, realdamage, COMMON);
		RecordHitGroup(attackerPID, hitgroup, COMMON);
		// survivorDmg[attacker][COMMON] += realdamage;

		// check for a headshot
		// if (hitgroup == 1) {
			// survivorHeadShots[attacker]++;
		// }

#if INFECTED_HURT_DEBUG
		//debug
		PrintToChatAll("entID: %d CIHealth: %d original_damage: %d damage: %d realdamage: %d hitgroup: %d type: %d modelid: %d", victim, CIHealth[victim], original_damage, damage, realdamage, hitgroup, GetEventInt(event, "type"),model_id);
#endif

	}
}


public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	// attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new attackerPID = GetPlayerIDOfClient(attacker);
	// Ensure that the infected health is set to zero. This should be the case in almost all situations, however, the survivor zombie has some weird damage properties that causes it to show up having health remaining even though it is dead.
	CIHealth[GetEventInt(event, "entityid")] = 0;
	
	//Only process if the player is a legal attacker (i.e., a player)
	if (g_collectStats && IsClientSurvivor(attacker) && IsValidPlayerID(attackerPID))
	{
		RecordKill(attackerPID,COMMON);
	}
}


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
		PrintStats(0, 20000,false);
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
			new String:playerName[33];
			GetClientName(client,playerName,sizeof(playerName));
			SetPlayerName(playerID,playerName);
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
		new String:playerName[33];
		GetClientName(player,playerName,sizeof(playerName));
		SetPlayerName(playerID,playerName);
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
			new String:playerName[33];
			GetClientName(player,playerName,sizeof(playerName));
			SetPlayerName(playerID,playerName);
		}
		// disable stats for bot
		DisablePlayerID(botPlayerID);
	}
}


/* [9.000]***************HELPER FUNCTIONS*************** */

PrintStats(printToClient, option, bool:detail) {
	// client2 values
	// 100 = print mvp
	//   0 = print all summarized stats
	
	new totalSIDamage = GetTotalDamage(HUNTER) + GetTotalDamage(JOCKEY) + GetTotalDamage(CHARGER) + GetTotalDamage(SPITTER) + GetTotalDamage(SMOKER) + GetTotalDamage(BOOMER);
	new totalSIKills = GetTotalKills(HUNTER) + GetTotalKills(JOCKEY) + GetTotalKills(CHARGER) + GetTotalKills(SMOKER) + GetTotalKills(SPITTER) + GetTotalKills(BOOMER);
	switch (option) {
		case 10000: {
		/*
		Chat: !stats all [detail]
		 1111111111111111111111111111111111111111111111111
		1name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
		2SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX) <-- skip if detail flag is false
		3name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
		4SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
		5name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
		6SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
		7name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
		8SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
		9=================================================
		0[SI]: XXXX Kills [CI]: XXXXX Kills [T]: XXX Kills <-- skip if detail flag is true
		1SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
		*/
			for (new i = 0; i < S3_MAXPLAYERS; i++) {
				// process name
				new String:name[20];
				new client = GetClientOfPlayerID(i);
				if (client == -1) {
					strcopy(name, 20, g_playerName[i]);
				}
				else if ((client > 0) && (client < MaxClients)) {
					GetClientName(client,name,sizeof(name));
				}
				
				// end process name
				if (IsPlayerSurvivor(i)) {
					// process SI %
					new SIKills   = GetTotalSIKills(i);
					new Float:percentSI;

					if (totalSIKills == 0) {
						percentSI = 0.0; 
					}
					else {
						percentSI = (float(SIKills)/(float(totalSIKills)))*100.00;
					}
					// end process SI %
					
					// process CI %
					new CIKills   = GetTotalKillsByPlayer(i,COMMON);
					new Float:percentCI;
					if( GetTotalKills(COMMON) == 0) {
						percentCI = 0.0;
					}
					else {
						percentCI =(float(CIKills)/float(GetTotalKills(COMMON)))* 100.00;
					}
					// end process CI %
					
					// process Tank %
					new TankDmg   = GetTotalDamageByPlayer(i,TANK);
					new Float:percentTanks;
					if (GetTotalDamage(TANK) == 0) {
						percentTanks = 0.0;
					}
					else {
						percentTanks = ((float(TankDmg)/float(GetTotalDamage(TANK)))* 100.00);
					}
					
					// end process Tank %
					
					if (printToClient == 0) { // print to everyone
						PrintToChatAll("\x04%s \x05SI: \x01%3.0f%% \x05CI: \x01%3.0f%% \x05Tanks: \x01%3.0f%%",name, percentSI, percentCI, percentTanks);
					}
					else if(printToClient > 0) { // print to specific client
						PrintToChat(printToClient,"\x04%s \x05SI: \x01%3.0f%% \x05CI: \x01%3.0f%% \x05Tanks: \x01%3.0f%%",name, percentSI, percentCI, percentTanks);
					}
					
					// process total SI kills
					
					new playerSIDamage = GetTotalSIDamage(i); 
					
					if(detail) {
						if (printToClient == 0) {
							PrintToChatAll("\x05SI:\x03%4d \x01(%d) \x05CI:\x03%4d \x01(%7d) \x05T:\x03%4d \x01(%7d)",SIKills, playerSIDamage,
																											  CIKills, GetTotalDamageByPlayer(i,COMMON),
																											  GetTotalKillsByPlayer(i,TANK), GetTotalDamageByPlayer(i,TANK));
						}
						else if (printToClient > 0) {
							PrintToChat(printToClient,"\x05SI:\x03%4d \x01(%d) \x05CI:\x03%4d \x01(%7d) \x05T:\x03%4d \x01(%7d)",SIKills, playerSIDamage,
																											  CIKills, GetTotalDamageByPlayer(i,COMMON),
																											  GetTotalKillsByPlayer(i,TANK), GetTotalDamageByPlayer(i,TANK));
						}
					}
				}
				/* else {
					if (printToClient == 0) { 
						PrintToChatAll("\x04CURRENTLY NO STATS");
					}
					else if (printToClient > 0) {
						PrintToChat(printToClient,"\x04CURRENTLY NO STATS");
					}
				}*/
			}
			
			if (printToClient == 0) { 
				PrintToChatAll("========================================");
				if(detail) {
					PrintToChatAll("\x04SI:\x03%4d \x01kills\x01(%7d) \x04CI:\x03%4d \x01kills \x01(%7d) \x04T:\x03%4d \x01kills \x01(%7d)",totalSIKills, totalSIDamage,
																											  GetTotalKills(COMMON), GetTotalDamage(COMMON),
																											  GetTotalKills(TANK), GetTotalDamage(TANK));
				}
				else {
					PrintToChatAll("\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, GetTotalKills(COMMON), GetTotalKills(TANK));
				}
			}
			else if(printToClient > 0) {
				PrintToChat(printToClient, "========================================");
				
				if(detail) {
					PrintToChat(printToClient,"\x04SI:\x03%4d \x01kills \x01(%7d) \x04CI:\x03%4d \x01kills \x01(%7d) \x04T:\x03%4d \x01kills \x01(%7d)",totalSIKills, totalSIDamage,
																											  GetTotalKills(COMMON), GetTotalDamage(COMMON),
																											  GetTotalKills(TANK), GetTotalDamage(TANK));
				}
				else {
					PrintToChat(printToClient,"\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, GetTotalKills(COMMON), GetTotalKills(TANK));
				}
			}
		}
		case 20000: {
			/*
			Chat: !stats mvp detail
			 1111111111111111111111111111111111111111111111111
			1MVP:name567890123 (1)T:XXX% (2)SI:XXX% (3)CI:XXX% 
			2FF: XXX HS: XXXXX Total Dmg: XXXXXX			  <-- skip if detail flag is false
			3name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			4FF: XXX HS: XXXXX Total Dmg: XXXXXX
			5name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			6FF: XXX HS: XXXXX Total Dmg: XXXXXX
			7name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			8FF: XXX HS: XXXXX Total Dmg: XXXXXX
			*/
			/*
				Rank players by performance
				Rank tank damagew
				Rank SI kills
				Rank CI kills
				calculate total damage
			*/
			new players = 0;
			new playerID[S3_MAXPLAYERS];
			
			for (new i = 0; i < S3_MAXPLAYERS; i++) {
				if (IsPlayerSurvivor(i)) {
					playerID[players] = i;
					players++;
#if DEBUG_MVP
					PrintToChatAll("players = %d, playerID = %d",players, i); //  --------------------------------------------- DEBUG
#endif
					}
			}
			
			// Rate Players

			new playerRating[players];
			new ratingTracker[players][3]; // 0 is client ID and 1 is rating
			for (new j = 0; j < players; j++) {
				playerRating[j] = RatePerformance(GetTotalDamageByPlayer(playerID[j],TANK), GetTotalSIKills(playerID[j]), GetTotalKillsByPlayer(playerID[j],COMMON));
				ratingTracker[j][0] = playerID[j];
				ratingTracker[j][1] = playerRating[j];
				ratingTracker[j][2] = 0;
#if DEBUG_MVP
				PrintToChatAll("ratingTracker[%d][0] = %d,ratingTracker[%d][1] = %d",j,ratingTracker[j][0],j,ratingTracker[j][1]); //  --------------------------------------------- DEBUG
#endif
			}
			
			SortIntegers(playerRating, players, Sort_Descending);
			
			// sort damage and clientID
			new orderedInfo[players][7]; // 0 id, 1 tank damage, 2 si kills, 3 ci kills, 4 tank rank, 5 si rank, 6 ci rank
			for (new m = 0; m < players; m++) {
				
				for (new r = 0; r < 7; r++) {
					orderedInfo[m][r] = 0;
				}
#if DEBUG_MVP
				PrintToChatAll("playerRating[%d] = %d",m,playerRating[m]);
#endif			
				for (new n = 0; n < players; n++) {
					if ((playerRating[m] == ratingTracker[n][1]) && (ratingTracker[n][2] == 0)) {
						orderedInfo[m][0] = ratingTracker[n][0]; // playerID
						orderedInfo[m][1] = GetTotalDamageByPlayer(ratingTracker[n][0],TANK); // damage
						orderedInfo[m][2] = GetTotalSIKills(ratingTracker[n][0]); // SI kills
						orderedInfo[m][3] = GetTotalKillsByPlayer(ratingTracker[n][0],COMMON); // CI kills
						ratingTracker[n][2] = 1;
#if DEBUG_MVP						
						PrintToChatAll("orderedInfo[%d][0] = %d, orderedInfo[%d][1] = %d, orderedInfo[%d][2] = %d, orderedInfo[%d][3] = %d, ",m,orderedInfo[m][0],m,orderedInfo[m][1],m,orderedInfo[m][2],m,orderedInfo[m][3]);
#endif
						n = players;
					}
				}
			}
			
			// how many winners
			new winners = 1;
			for (new k = 1; k < players; k++) {
				if (playerRating[0] == playerRating[k]) {
					winners++;
				}
			}
#if DEBUG_MVP
			PrintToChatAll("winners = %d", winners);
#endif
			// Percent processing
			new Float:percent[players][3];
			for (new x = 0; x < players; x++) {
				if(GetTotalKills(COMMON) == 0) {
					percent[x][2] = 0.0;
				}
				else {
					percent[x][2] =(float(orderedInfo[x][3])/float(GetTotalKills(COMMON)))* 100.00;
				}
#if DEBUG_MVP
				 PrintToChatAll("percent[%d][2] = %f",x, percent[x][2]);
#endif				 
				if(totalSIKills == 0) {
					percent[x][1] = 0.0;
				}
				else {
					percent[x][1] =(float(orderedInfo[x][2])/float(totalSIKills))* 100.00;
				}
#if DEBUG_MVP
				 PrintToChatAll("percent[%d][1] = %f",x, percent[x][1]);
#endif
				if (GetTotalDamage(TANK) == 0) {
					percent[x][0] = 0.0;
				}
				else {
					percent[x][0] = (float(orderedInfo[x][1])/float(GetTotalDamage(TANK)))* 100.00;
				}
#if DEBUG_MVP
				PrintToChatAll("percent[%d][0] = %f",x, percent[x][0]);
#endif
				}
			
			// rank processing
			new orderedTankDamage[players];
			new orderedSIKills[players];
			new orderedCIKills[players];
			new infoTracker[players][3]; // 0 tank, 1 si, 3 ci
			
			for (new s = 0; s < players; s++) {
				orderedTankDamage[s] = 0;
				orderedSIKills[s] = 0;
				orderedCIKills[s] = 0;
				infoTracker[s][2] = 0;
				infoTracker[s][1] = 0;
				infoTracker[s][0] = 0;
			}
			
			
			// copy data
			for (new y = 0; y < players; y++) {
				orderedTankDamage[y] = GetTotalDamageByPlayer(orderedInfo[y][0],TANK);
				orderedSIKills[y] = GetTotalSIKills(orderedInfo[y][0]);
				orderedCIKills[y] = GetTotalKillsByPlayer(orderedInfo[y][0],COMMON);
			}
			
			SortIntegers(orderedTankDamage, players, Sort_Descending);
			SortIntegers(orderedSIKills, players, Sort_Descending);
			SortIntegers(orderedCIKills, players, Sort_Descending);
			new ranksOfTankDamage[players];
			new ranksOfSIKills[players];
			new ranksOfCIKills[players];
			
			new rankTank = 1;
			new rankSI = 1;
			new rankCI = 1;
			for (new q = 0; q < players; q++) {
				ranksOfTankDamage[q] = rankTank;
				ranksOfSIKills[q] = rankSI;
				ranksOfCIKills[q] = rankCI;
				
				if (orderedTankDamage[q] != orderedTankDamage[q + 1]) {
					rankTank++;
				}
				if (orderedSIKills[q] != orderedSIKills[q + 1]) {
					rankSI++;
				}
				if (orderedCIKills[q] != orderedCIKills[q + 1]) {
					rankCI++;
				}

			}
			
			// Tank Damage Rank
			for (new b = 0; b < players; b++) {
				for (new c = 0; c < players; c++) {
					if ((orderedTankDamage[b] == orderedInfo[c][1]) && (infoTracker[c][0] == 0)) {
						orderedInfo[c][4] = ranksOfTankDamage[b];
						infoTracker[c][0] = 1;
						c = players;
					}
				}
			}
			
			// SI Kills Rank
			for (new d = 0; d < players; d++) {
				for (new e = 0; e < players; e++) {
					if ((orderedSIKills[d] == orderedInfo[e][2]) && (infoTracker[e][1] == 0)) {
						orderedInfo[e][5] = ranksOfSIKills[d];
						infoTracker[e][1] = 1;
						e = players;
					}
				}
			}
			
			// CI Kills Rank
			for (new f = 0; f < players; f++) {
				for (new g = 0; g < players; g++) {
					if ((orderedCIKills[f] == orderedInfo[g][3]) && (infoTracker[g][2] == 0)) {
						orderedInfo[g][6] = ranksOfCIKills[f];
						infoTracker[g][2] = 1;
						g = players;
					}
				}
			}
			
			
			
			if((winners == players) && (printToClient == 0)) {
				PrintToChatAll("\x03[MVP CITY]");
			}
			
			new String:name[33];
			new tempClient;
			
			// Display MVP Info
			for (new l = 0; l < players; l++) {
				tempClient = GetClientOfPlayerID(orderedInfo[l][0]);
				if (tempClient == -1) {
					strcopy(name, 20, g_playerName[orderedInfo[l][0]]);
				}
				else if ((tempClient > 0) && (tempClient < MaxClients)) {
					GetClientName(tempClient,name,sizeof(name));
				}
				if (printToClient == 0) {
					if (l == 0 || (l < winners)) {
						PrintToChatAll("\x05[MVP] \x01%13s \x03(%d) \x04T: \x01%3.0f%% \x03(%d) \x04SI: \x01%3.0f%% \x03(%d) \x04CI: \x01%3.0f%% ",name,orderedInfo[l][4],percent[l][0],orderedInfo[l][5],percent[l][1],orderedInfo[l][6],percent[l][2]);
					}
					else {
						PrintToChatAll("\x01%17s \x03(%d) \x04T: \x01%3.0f%% \x03(%d) \x04SI: \x01%3.0f%% \x03(%d) \x04CI: \x01%3.0f%%",name,orderedInfo[l][4],percent[l][0],orderedInfo[l][5],percent[l][1],orderedInfo[l][6],percent[l][2]);
					}
				}
				else {
					if (l == 0 || (l < winners)) {
						PrintToChat(printToClient,"\x05[MVP] \x01%13s \x03(%d) \x04T: \x01%3.0f%% \x03(%d) \x04SI: \x01%3.0f%% \x03(%d) \x04CI: \x01%3.0f%%",name,orderedInfo[l][4],percent[l][0],orderedInfo[l][5],percent[l][1],orderedInfo[l][6],percent[l][2]);
					}
					else {
						PrintToChat(printToClient,"\x01%17s \x03(%d) \x04T: \x01%3.0f%% \x03(%d) \x04SI: \x01%3.0f%% \x03(%d) \x04CI: \x01%3.0f%%",name,orderedInfo[l][4],percent[l][0],orderedInfo[l][5],percent[l][1],orderedInfo[l][6],percent[l][2]);
					}
				}

				if (detail) {
					new totalShots = 0;
				
					for (new a = 0; a < 8; a++) {
						if (a != 0) {
							totalShots += g_survivorHitGroupType1[orderedInfo[l][0]][a];
						}
						if (a < 6) {
							totalShots += g_survivorHitGroupType2[orderedInfo[l][0]][a];
						}
					}
					new headShots = g_survivorHitGroupType1[orderedInfo[l][0]][1] + g_survivorHitGroupType2[orderedInfo[l][0]][1];
					new Float:headShotPercent = (float(headShots)/float(totalShots))*100.00;
					new allDamage = GetTotalSIDamage(orderedInfo[l][0]) + GetTotalDamageByPlayer(orderedInfo[l][0],COMMON) + GetTotalDamageByPlayer(orderedInfo[l][0],TANK);
					
					if(printToClient == 0) {
						PrintToChatAll("\x04FF: \x01%d \x04HS: \x01%3.0f%% \x04Total Dmg: \x01%d",GetFFDamage(orderedInfo[l][0]),headShotPercent, allDamage);
					}
					else {
						PrintToChat(printToClient,"\x04FF: \x01%d \x04HS: \x01%3.0f%% \x04Total Dmg: \x01%d",GetFFDamage(orderedInfo[l][0]),headShotPercent, allDamage);
					}
				}
			}
			
		}
		case 30000: {
		/*
		Chat: !stats round
		 1111111111111111111111111111111111111111111111111
		1 [JOCKEY]: XXXX  [TOTAL SI]: XXXX
		2 [SMOKER]: XXXX    [COMMON]: XXXX
		3 [BOOMER]: XXXX      [TANK]: XXXX
		4 [HUNTER]: XXXX
		5[CHARGER]: XXXX
		6[SPITTER]: XXXX
		7 
		8 
		*/
			if (printToClient == 0) {
				PrintToChatAll("\x04[Jockey]: \x01%4d \x04[Total SI]:",GetTotalKills(JOCKEY), totalSIKills);
				PrintToChatAll("\x04[Smoker]: \x01%4d \x04[Common]: \x01%d",GetTotalKills(SMOKER), GetTotalKills(COMMON));
				PrintToChatAll("\x04[Boomer]: \x01%4d \x04[Tanks]: \x01%d",GetTotalKills(BOOMER),GetTotalKills(TANK));
				PrintToChatAll("\x04[Hunter]: \x01%4d",GetTotalKills(HUNTER));
				PrintToChatAll("\x04[Charger]: \x01%4d",GetTotalKills(CHARGER));
				PrintToChatAll("\x04[Spitter]: \x01%4d",GetTotalKills(SPITTER));
			}
			else {
				PrintToChat(printToClient,"\x04[Jockey]: \x01%4d \x04[Total SI]: \x01%d",GetTotalKills(JOCKEY), totalSIKills);
				PrintToChat(printToClient,"\x04[Smoker]: \x01%4d \x04[Common]: \x01%d",GetTotalKills(SMOKER), GetTotalKills(COMMON));
				PrintToChat(printToClient,"\x04[Boomer]: \x01%4d \x04[Tanks]: \x01%d",GetTotalKills(BOOMER),GetTotalKills(TANK));
				PrintToChat(printToClient,"\x04[Hunter]: \x01%4d",GetTotalKills(HUNTER));
				PrintToChat(printToClient,"\x04[Charger]: \x01%4d",GetTotalKills(CHARGER));
				PrintToChat(printToClient,"\x04[Spitter]: \x01%4d",GetTotalKills(SPITTER));
			}
		
		}
		default: {
			// process name
			new String:name[20];
			new client = GetClientOfPlayerID(option);
			if (client == -1) {
				strcopy(name, 20, g_playerName[option]);
			}
			else if ((client > 0) && (client < MaxClients)) {
				GetClientName(client,name,sizeof(name));
			}
			// end process name
			
			// process SI %
			new SIKills   = GetTotalSIKills(option);
			new Float:percentSI;

			if (totalSIKills == 0) {
				percentSI = 0.0; 
			}
			else {
				percentSI = (float(SIKills)/(float(totalSIKills)))*100.00;
			}
			// end process SI %
			
			// process CI %
			new CIKills   = GetTotalKillsByPlayer(option,COMMON);
			new Float:percentCI;
			if( GetTotalKills(COMMON) == 0) {
				percentCI = 0.0;
			}
			else {
				percentCI =(float(CIKills)/float(GetTotalKills(COMMON)))* 100.00;
			}
			// end process CI %
			
			// process Tank %
			new TankDmg   = GetTotalDamageByPlayer(option,TANK);
			new Float:percentTanks;
			if (GetTotalDamage(TANK) == 0) {
				percentTanks = 0.0;
			}
			else {
				percentTanks = ((float(TankDmg)/float(GetTotalDamage(TANK)))* 100.00);
			}
			// end process Tank %
			
			// start  percentage damage
			new Float:PercentDamage[8];
			new Float:PercentKills[8];
			for (new i = 0; i < 8; i++) {
				new damageByPlayer = GetTotalDamageByPlayer(option,i);
				new killsByPlayer = GetTotalKillsByPlayer(option,i);
				if (damageByPlayer == 0) {
					PercentDamage[i] = 0.0;
				}
				else {
					PercentDamage[i] = (float(damageByPlayer)/float(GetTotalDamage(i)))* 100.00;
				}
				
				if (killsByPlayer == 0) {
					PercentKills[i] = 0.0;
				}
				else {
					PercentKills[i] = (float(killsByPlayer)/float(GetTotalKills(i)))* 100.00;
				}
				
			}			
			// end SI percentage kills
			if (detail) {
				/*
				Chat: !stats <name> detail
				 1111111111111111111111111111111111111111111111111
				1name456789012345678901234567 FF: XXXXX HS: XXXXXX
				2 [J] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				3 [C] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				4 [H] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				5 [B] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				6[SM] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				7[SP] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				8 [T] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX% 
				9[CI] XXXX/XXXX Kills (XXXXXXX/XXXXXXX Damage)XXX%
				*/
				// process headshots
				new totalShots = 0;
				
				for (new i = 0; i < 8; i++) {
					if (i != 0) {
						totalShots += g_survivorHitGroupType1[option][i];
					}
					if (i < 6) {
						totalShots += g_survivorHitGroupType2[option][i];
					}
				}
				new headShots = g_survivorHitGroupType1[option][1] + g_survivorHitGroupType2[option][1];
				new Float:headShotPercent = (float(headShots)/float(totalShots))*100.00;
				
				PrintToChat(printToClient,"\x04%27s FF: %d HS: %3.0f%%	",name,GetFFDamage(option),headShotPercent);
				PrintToChat(printToClient,"\x04[H] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,HUNTER),GetTotalKills(HUNTER), PercentKills[HUNTER], GetTotalDamageByPlayer(option,HUNTER),GetTotalDamage(HUNTER),PercentDamage[HUNTER]);
				PrintToChat(printToClient,"\x04[SM] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,SMOKER),GetTotalKills(SMOKER), PercentKills[SMOKER], GetTotalDamageByPlayer(option,SMOKER),GetTotalDamage(SMOKER),PercentDamage[SMOKER]);
				PrintToChat(printToClient,"\x04[B] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,BOOMER),GetTotalKills(BOOMER), PercentKills[BOOMER], GetTotalDamageByPlayer(option,BOOMER),GetTotalDamage(BOOMER),PercentDamage[BOOMER]);
				PrintToChat(printToClient,"\x04[C] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,CHARGER),GetTotalKills(CHARGER), PercentKills[CHARGER], GetTotalDamageByPlayer(option,CHARGER),GetTotalDamage(CHARGER),PercentDamage[CHARGER]);
				PrintToChat(printToClient,"\x04[J] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,JOCKEY),GetTotalKills(JOCKEY), PercentKills[JOCKEY], GetTotalDamageByPlayer(option,JOCKEY),GetTotalDamage(JOCKEY),PercentDamage[JOCKEY]);
				PrintToChat(printToClient,"\x04[SP] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,SPITTER),GetTotalKills(SPITTER), PercentKills[SPITTER], GetTotalDamageByPlayer(option,SPITTER),GetTotalDamage(SPITTER),PercentDamage[SPITTER]);
				PrintToChat(printToClient,"\x04[T] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,TANK),GetTotalKills(TANK), PercentKills[TANK], GetTotalDamageByPlayer(option,TANK),GetTotalDamage(TANK),PercentDamage[TANK]);
				PrintToChat(printToClient,"\x04[CI] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,COMMON),GetTotalKills(COMMON), PercentKills[COMMON], GetTotalDamageByPlayer(option,COMMON),GetTotalDamage(COMMON),PercentDamage[COMMON]);
				// put in totals here
			}
			else {
				/*
				Chat: !stats <name>
				 1111111111111111111111111111111111111111111111111
				1name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
				2=================================================
				3[SI]: XXX Kills [CI]: XXXXX Kills [T]: XXX Kills
				*/
				PrintToChat(printToClient,"\x04%s \x05SI: \x01%3.0f%% \x05CI: \x01%3.0f%% \x05Tanks: \x01%3.0f%%",name, percentSI, percentCI, percentTanks);
				PrintToChat(printToClient, "========================================");
				PrintToChat(printToClient,"\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, GetTotalKills(COMMON), GetTotalKills(TANK));
			}
		
		}
	}
}


PrintTankStats(victimPID) {
	if (g_collectStats && g_printTankStats) {
		new Float:percent = 0.0;
		new players = 0;
		new maxHealth = GetPlayerMaxHealth(victimPID);
		new damage[S3_MAXPLAYERS];
		new tracker[S3_MAXPLAYERS][3];
		for(new i = 0; i < S3_MAXPLAYERS; i++) {
			if (IsPlayerSurvivor(i)) {
				/*
				 1111111111111111111111111111111111111111111111111
				1name56789012345678901234567890 XXXX Damage (XXX%)
				2name56789012345678901234567890 XXXX Damage (XXX%)
				3name56789012345678901234567890 XXXX Damage (XXX%)
				4name56789012345678901234567890 XXXX Damage (XXX%)
				*/
				if (!((GetDamageToTank(i,victimPID) == 0) && !IsPlayerActive(i))) {
					damage[players]     = GetDamageToTank(i,victimPID);
					tracker[players][0] = i;
					tracker[players][1] = GetDamageToTank(i,victimPID);
					tracker[players][2] = 0;
					players++;
				//PrintToChatAll("survivorDmgToTank[i][victim] = %d, i = %d",survivorDmgToTank[i][victim], i);
				}
			}
		}
		
		// sorting
		SortIntegers(damage, S3_MAXPLAYERS, Sort_Descending);
		
		// sort damage and clientID
		new orderedInfo[players][2];
		for (new l = 0; l < players; l++) {
			for (new m = 0; m < players; m++) {
				if ((damage[l] == tracker[m][1]) && (tracker[m][2] == 0)) {
					orderedInfo[l][0] = tracker[m][0]; // playerID
					orderedInfo[l][1] = damage[l];     // damage
					tracker[m][2] = 1;
					m = players;
					//PrintToChatAll("orderedInfo[%d][0] = %d, orderedInfo[%d][1] = %d, tracker[%d][2] = %d",l,orderedInfo[l][0],l,orderedInfo[l][1],m,tracker[m][2]);
				}
			}
		}

		
		// how many winners
		new winners = 1;
		for (new k = 1; k < players; k++) {
			if (orderedInfo[0][1] == 4000) {
				winners = 1;
				break;
			}
			else if (orderedInfo[0][1] == orderedInfo[k][1]) {
				winners++;
			}
		}
		
		// display data
		if(winners == players) {
			PrintToChatAll("\x03[WINNER WINNER CHICKEN DINNER]");
		}
		
		for (new j = 0; j < players; j++) {
			
			percent = (float(orderedInfo[j][1]) / float(maxHealth))* 100.00;
			new String:name[20];
			new client = GetClientOfPlayerID(orderedInfo[j][0]);
			if (client == -1) {
				strcopy(name, 20, g_playerName[orderedInfo[j][0]]);
			}
			else if ((client > 0) && (client < MaxClients)) {
				GetClientName(client,name,sizeof(name));
			}
			
			if (j == 0) { // first one
				if (percent == 100) {
					PrintToChatAll("\x03[ULTIMATE NINJA] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
				}
				else {
					PrintToChatAll("\x03[WINNER] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
				}
			}
			else {
				if ((j < winners) && (winners > 1)) {
					PrintToChatAll("\x03[WINNER] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
				}
				else if ( j == (players-1)) {
					if (orderedInfo[j][1] == 0) {
						PrintToChatAll("\x01[NOOBTASTIC] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
					}
					else {
						PrintToChatAll("\x01[LOSER] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
					}
				}
				else {
					if (orderedInfo[j][1] == 0) {
						PrintToChatAll("\x01[NOOBTASTIC] \x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
					}
					else {
						PrintToChatAll("\x04%s \x01%d Damage \x05(%3.0f%%)", name, orderedInfo[j][1],percent);
					}
				}
			}
		}
		
	}
}


bool:IsTankIncapacitated(client) {
	if (IsIncapacitated(client) || GetClientHealth(client) < 1) return true;
	return false;
}

bool:IsIncapacitated(client) {
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}


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
				new String:name[33];
				GetClientName(i,name, sizeof(name));
				strcopy(g_playerName[playerID], 33,name);
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
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		if (IsPlayerSurvivor(i)) {
			if (StrContains(g_playerName[i], name, false) == 0) {
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
	new String:name[33];
	new String:steamID[20];
	strcopy(g_playerName[playerID], 33, name);
	strcopy(g_playerSteamID[playerID], 20, steamID);
}

// This function obtains a new player ID for storage purposes
// This function will also set the g_playerActive array to true and increment the counter as well SO USE THE NUMBER
// it will return -1 if the system is currently recording the maximum amount of active players
GetNewPlayerID(client) {
	if (IsClientAlive(client)) {
		new String:name[33];
		new String:steamID[20];
		new team = 0;
		new health = GetClientHealth(client);
		new maxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth") & 0xffff;
		GetClientName(client,name, sizeof(name));
		GetClientAuthString(client, steamID, sizeof(steamID));
		team = GetClientTeam(client);
		
		if (IsPlayerTableFull()) {
			for ( new i = 0; i < S3_MAXPLAYERS; i++) {
				if (!IsPlayerActive(i)) {
					// delete current date
					WipePlayerData(i);
					EnablePlayerID(i);
					SetPlayerInfo(i, health, maxHealth, team, name, steamID);
					return i; // if there is an inactive player then give that spot
				}
			}
		}
		else if (!IsPlayerTableFull()) {
			new newPlayerID = GetNextAvailablePlayerID();
			EnablePlayerID(newPlayerID);
			MoveNextAvailablePlayerID();
			SetPlayerInfo(newPlayerID, health, maxHealth, team, name, steamID);
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

GetDamageToTank(attackerPID, victimPID) {
	return g_survivorDmgToTank[attackerPID][victimPID];
}

GetPlayerTeam(playerID) {
	return g_playerTeam[playerID];
}

GetPlayerHealth(playerID) {
	return g_playerHealth[playerID];
}

GetClientOfPlayerID(playerID) {
	new String:steamID[20];
	new String:name[33];
	for (new i = 0; i < MaxClients; i++) {
		if (IsClientAlive(i)) {
			GetClientName(i,name,sizeof(name));
			GetClientAuthString(i,steamID,sizeof(steamID));
			if (StrEqual(steamID, g_playerSteamID[playerID],false) && StrEqual(name, g_playerName[playerID],false)	) {
				return i;
			}
		}
	}
	return -1;
}

GetPlayerMaxHealth(playerID) {
	return g_playerMaxHealth[playerID];
}

GetTotalDamage(victimType) {
	if ((victimType >= 0) && (victimType < 9)) {
		return g_survivorTotalDmg[victimType];
	}
	return 0;
}

GetTotalKills(victimType) {
	if ((victimType >= 0) && (victimType < 9)) {
		return g_survivorTotalKills[victimType];
	}
	return 0;
}

GetFFDamage(playerID) {
	return g_survivorFFDmg[playerID];
}

GetTotalSIKills(playerID) {
	return (g_survivorKills[playerID][HUNTER] + g_survivorKills[playerID][JOCKEY] + g_survivorKills[playerID][CHARGER] + g_survivorKills[playerID][SPITTER] + g_survivorKills[playerID][SMOKER] + g_survivorKills[playerID][BOOMER]);
}

GetTotalSIDamage(playerID) {
	return (g_survivorDmg[playerID][HUNTER] + g_survivorDmg[playerID][JOCKEY] + g_survivorDmg[playerID][CHARGER] + g_survivorDmg[playerID][SPITTER] + g_survivorDmg[playerID][SMOKER] + g_survivorDmg[playerID][BOOMER]);
}

GetTotalKillsByPlayer(playerID, victimType) {
	return g_survivorKills[playerID][victimType];
}

GetTotalDamageByPlayer(playerID, victimType) {
	return g_survivorDmg[playerID][victimType];
}


GetPlayerIDBySteamID(const String:steamID[]) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		if(StrEqual(steamID, g_playerSteamID[i])) {
			return i;
		}
	}
	return -1;
}

bool:SetPlayerInfo(playerID, health, maxHealth, team, const String:name[], const String:steamID[]) {
	strcopy(g_playerName[playerID], 33,name);
	strcopy(g_playerSteamID[playerID], 20,steamID);
	g_playerTeam[playerID] = team;
	g_playerHealth[playerID] = health;
	g_playerMaxHealth[playerID] = maxHealth;
}

bool:SetPlayerHealth(playerID, health) {
	if (IsValidPlayerID(playerID) && IsPlayerActive(playerID)) {
		if (IsPlayerSurvivor(playerID)) {
			g_playerHealth[playerID] = health;
		}
		else if (IsPlayerInfected(playerID)) {
			g_playerHealth[playerID] = health;
		}
	}
}

SetPlayerName(playerID, String:name[]) {
	strcopy(g_playerName[playerID],33, name);
}

SetPlayerTeam(playerID,team) {
	g_playerTeam[playerID] = team;
}

bool:DamagePlayer(playerID,damage) {
	g_playerHealth[playerID] -= damage;
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

bool:IsGameMode(const String:mode[]) {
	return StrEqual(mode, g_gameMode,false);
}

bool:IsSupportedGameMode(const String:mode[]) {
	for (new i = 0; i < 1; i++) {
		if (StrEqual(mode, GAME_MODES[i],false)) {
			return true;
		}
	}
	return false;
}

bool:RecordKill(attackerPID, victimType) {
	if((victimType >=0) && (victimType <= 9)) {
		g_survivorKills[attackerPID][victimType]++;
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

bool:RecordHitGroup(playerID, hitGroup, victimType) {
	if ((victimType >= 0) && (victimType <= 10)) {
		switch (victimType) {
			case 0,1,5,6,7,8: {
				if((hitGroup <= 7) && (hitGroup > 0)) {
					g_survivorHitGroupType1[playerID][hitGroup]++;
					return true;
				}
			}
			case 2,3,4: {
				if((hitGroup <= 5) && (hitGroup >= 0)) {
					g_survivorHitGroupType2[playerID][hitGroup]++;
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

RecordTankDamage(attackerPID, victimPID, damage) {
	g_survivorDmgToTank[attackerPID][victimPID] += damage; 
}

WipeTankStats(victimPID) {
	for (new i = 0; i < S3_MAXPLAYERS; i++) {
		g_survivorDmgToTank[i][victimPID] = 0;
	}

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
