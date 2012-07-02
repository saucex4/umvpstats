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
*            10.000 DATABASE FUNCTIONS
* 
* Features to add: Granular Weapon Stats (requested by phoenix)
*                  [COMPLETE] Headshot % not count (requested by sauce)
*                  Granular Zombie Stats (requested by sauce)
*                  Granular Item Usage Stats (requested by sauce)
*                  Data collection via sql and sqllite databases (requested by sauce)
*                  Web interface for viewing stats (requested by sauce)
*                  [NEED TESTING] Add support for witches
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
#include <geoip>

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
new const NUM_SPECIAL_ZOMBIES = 12;
new const SPECIAL_ZOMBIE_ID[] =  {270, 440, 256, 309, 197, 259, 232, 212, 283,255,559,441};
new const SPECIAL_ZOMBIE_HP[] =  {150, 150, 150, 150, 150, 150, 50, 1000, 1000,1000,1000,1000};
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
new const NUM_GAMEMODES = 6;
new const String:GAME_MODES[][64] = {
	"survival",
	"hardtwentysurvival",
	"coop",
	"versus",
	"realism",
	"scavenge"
	/* "mutation1",
  "mutation2",  "mutation3",  "mutation4",
  "mutation5",  "mutation6",  "mutation7",
  "mutation8",  "mutation9",  "mutation10",
  "mutation11",  "mutation12",  "mutation13",
  "mutation14",  "mutation15",  "mutation16",
  "mutation17",  "mutation18",  "mutation19",
  "mutation20",  "community1",  "community2",
  "community3",  "community4",  "community5"*/
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

// Constants for map names--------------------------
new const NUM_OFFICIAL_MAPS_2 = 17;
new String:OFFICIAL_MAPS_2[][64] =
{
	"c1m4_atrium",
	"c2m1_highway",
	"c2m4_barns",
	"c2m5_concert",
	"c3m1_plankcountry",
	"c3m4_plantation",
	"c4m1_milltown_a",
	"c4m2_sugarmill",
	"c5m2_park",
	"c5m5_bridge",
	"c6m1_riverbank",
	"c6m2_bedlam",
	"c6m3_port",
	"c7m1_docks",
	"c7m3_port",
	"c8m2_subway",
	"c8m5_rooftop"
};

new String:CAMPAIGNS_2[][64] =
{
	"Dead Center",
	"Dark Carnival",
	"Dark Carnival",
	"Dark Carnival",
	"Swamp Fever",
	"Swamp Fever",
	"Hard Rain",
	"Hard Rain",
	"The Parish",
	"The Parish",
	"The Passing",
	"The Passing",
	"The Passing",
	"The Sacrifice",
	"The Sacrifice",
	"No Mercy",
	"No Mercy"
};

//! These are the human-readable map names and also the names that are stored in the survival records database - do not change
new String:OFFICIAL_MAP_NAMES_2[][64] =
{
	"Mall Atrium",
	"Motel",
	"Stadium Gate",
	"Concert",
	"Gator Village",
	"Plantation",
	"Burger Tank",
	"Sugar Mill",
	"Bus Depot",
	"Bridge",
	"Riverbank",
	"Underground",
	"Port (P)",
	"Traincar",
	"Port (S)",
	"Generator Room",
	"Rooftop"
};

//! This is the number of different item types
new const NUM_ITEM_TYPES = 6;

//! This is a list of the various types of items
new const String:ITEM_TYPES[][100] =
{
	"Health",
	"Throwable",
	"Melee Weapon",
	"Gun",
	"Ammo",
	"Explosive"
};

// Constants for modelTypes-------------------------
#define NUM_MODEL_TYPES 7
new const String:MODEL_TYPES[][64] =
{
	"Survivor",
	"Hunter",
	"Smoker",
	"Boomer",
	"Charger",
	"Jockey",
	"Spitter",
	"Tank"
};

new MODEL_TYPE_INDICES[NUM_MODEL_TYPES];

//==================================================
// TestDB SQL Commands
//==================================================

new const NUM_TEST_COMMANDS = 16;
new String:sql_test_commands[][1024] =
{
	"DROP TABLE IF EXISTS player;",
	"CREATE TABLE IF NOT EXISTS player(id, steamID VARCHAR(20) NOT NULL, name VARCHAR(32) NOT NULL, country VARCHAR(32) NULL, alias1 VARCHAR(32) NULL, alias2 VARCHAR(32) NULL, alias3 VARCHAR(32) NULL, alias4 VARCHAR(32) NULL, alias5 VARCHAR(32) NULL, alias6 VARCHAR(32) NULL, PRIMARY KEY (id));",
	"DROP TABLE IF EXISTS weapon;",
	"CREATE TABLE IF NOT EXISTS weapon(weaponID INTEGER, name VARCHAR(45), type INTEGER NULL, PRIMARY KEY (weaponID), UNIQUE (name));",
	"DROP TABLE IF EXISTS maps;",
	"CREATE TABLE IF NOT EXISTS maps(mapID INTEGER, mapName VARCHAR(45), campaignName VARCHAR(45) NULL, url VARCHAR(255) NULL, game INTEGER, PRIMARY KEY (mapID), UNIQUE (mapName, campaignName));",
	"DROP TABLE IF EXISTS record;",
	"CREATE TABLE IF NOT EXISTS record(recordID INTEGER, duration INTEGER, mapID INTEGER, PRIMARY KEY (recordID));",
	"DROP TABLE IF EXISTS gameClient;",
	"CREATE TABLE IF NOT EXISTS gameClient(entryID INTEGER, modelID INTEGER, steamID VARCHAR(20), birthTime INTEGER, deathTime INTEGER, PRIMARY KEY (entryID));",
	"DROP TABLE IF EXISTS team;",
	"CREATE TABLE IF NOT EXISTS team(teamID INTEGER, recordID INTEGER, teamType INTEGER, birthTime INTEGER, deathTime INTEGER, PRIMARY KEY (teamID));",
	"DROP TABLE IF EXISTS modelTypes;",
	"CREATE TABLE IF NOT EXISTS modelTypes(modelID INTEGER, modelName VARCHAR(40), modelType INTEGER NULL, PRIMARY KEY (modelID));",
	"DROP TABLE IF EXISTS damage;",
	"CREATE TABLE IF NOT EXISTS damage(entryID INTEGER, eventTimestamp INTEGER, recordID INTEGER, damageAmount INTEGER NULL, hitgroup INTEGER NULL, weaponID INTEGER NULL, damageType INTEGER NULL, kill INTEGER NULL, attacker INTEGER NULL, aRemainingHealth INTEGER NULL, aMaxHealth INTEGER NULL, aPositionX FLOAT NULL, aPositionY FLOAT NULL, aPositionZ FLOAT NULL, aLatency INTEGER NULL, aLoss INTEGER NULL, aChoke INTEGER NULL, aPackets INTEGER NULL, victimSteamID VARCHAR(20) NULL, vRemainingHealth INTEGER NULL, vMaxHealth VARCHAR(45) NULL, vPositionX FLOAT NULL, vPositionY FLOAT NULL, vPositionZ FLOAT NULL, vLatency INTEGER NULL, vLoss INTEGER NULL, vChoke INTEGER NULL, vPackets INTEGER NULL, PRIMARY KEY (entryID));"
};

new NUM_DEBUG_COMMANDS = 19;
new const String:DEBUG_COMMANDS[][128] =
{
	"sm_umvp_help",
	"sm_umvp_connect_test_db",
	"sm_umvp_add_player",
	"sm_umvp_add_official_maps",
	"sm_umvp_add_official_weapons",
	"sm_umvp_add_connected_players",
	"sm_umvp_add_weapon",
	"sm_umvp_add_record",
	"sm_umvp_add_team",
	"sm_umvp_add_model_types",
	"sm_umvp_add_game_client",
	"sm_umvp_get_mapid",
	"sm_umvp_output_player_table",
	"sm_umvp_output_maps_table",
	"sm_umvp_output_weapons_table",
	"sm_umvp_output_records_table",
	"sm_umvp_output_game_client_table",
	"sm_umvp_output_model_types_table",
	"sm_umvp_output_team_table",
	"sm_umvp_count_kills"
};

/* [4.000]***************GLOBAL VARIABLES*************** */

//new Handle:db = INVALID_HANDLE;                 //!< The main database
new Handle:test_db_sqlite = INVALID_HANDLE;     //!< SQLite database (for testing purposes the data is wiped every time the plugin reloads)

new Handle:survival_records_db = INVALID_HANDLE; //!< This is the SQLite database that contains the survival records
new Handle:survival_counts_db = INVALID_HANDLE; //!< This is the SQLite database that contains the item counts

// global variables that track survivor data
new String:g_playerName[S3_MAXPLAYERS][33];    // stores player name
new String:g_playerSteamID[S3_MAXPLAYERS][20]; // stores player steam id
new g_playerTeam[S3_MAXPLAYERS];               // stores player team
new bool:g_playerActive[S3_MAXPLAYERS];        // if player is active or not
new g_playerHealth[S3_MAXPLAYERS];
new g_playerNextAvailableSpot = 0;             // the next available spot for new player
new g_playerMaxHealth[S3_MAXPLAYERS];
new g_gameClientID[S3_MAXPLAYERS];             //!< The game client of the player (valid only if the player is active)
new g_playerID[S3_MAXPLAYERS];                 //!< The database player id of the current player

new g_survivorKills[S3_MAXPLAYERS][9]; // stores the kills for each survivor for each SI type
new g_survivorDmg[S3_MAXPLAYERS][9];   // stores the dmg for each survivor for each SI type
new g_survivorHitGroupType1[S3_MAXPLAYERS][8]; // hit group counter for hunter, boomer, smoker, zombie, tank, witch
new g_survivorHitGroupType2[S3_MAXPLAYERS][6]; // hit group counter for jockey, charger, spitter
new g_survivorHitGroupTypeSurvivor[S3_MAXPLAYERS][8]; // hit group counter for survivors
new g_survivorFFDmg[S3_MAXPLAYERS];     // friendly fire counter
new g_survivorTotalKills[9];            // total kills
new g_survivorTotalDmg[9];              // total damage

new g_survivorItemsUsed[S3_MAXPLAYERS][10]; // 0 pills, 1 shot, 2 medkit , 3 defib, 4 fire ammo, 5 explo ammo, 6 laser, 7 pipe, 8 molo, 9 bile

new g_survivorAmmoPickedUp[S3_MAXPLAYERS];
new g_survivorReloaded[S3_MAXPLAYERS][47];
new g_survivorScoped[S3_MAXPLAYERS][47];
new g_survivorShotsFired[S3_MAXPLAYERS][47]; // stores the number of shots fired
new g_survivorShotsHit[S3_MAXPLAYERS][47]; // stores the number of shots hit
new g_survivorCoolKills[S3_MAXPLAYERS][5]; // charger level, witch crown, hunter skeet, hunter melee skeet, tongue cut

new g_survivorDmgToTank[S3_MAXPLAYERS][S3_MAXPLAYERS];

new g_infectedKills[S3_MAXPLAYERS]; // stores the kills for each SI 
new g_infectedDmg[S3_MAXPLAYERS]; // stores the damage for each SI
new g_infectedFFDmg[S3_MAXPLAYERS]; // stores FF damage for each SI
new g_infectedHealth[S3_MAXPLAYERS];

// global variables that track CI data
new CIHealth[MAXENTITIES];        // Tracks health of every common infected. This is inefficient memory usage since not all entities (array elements) are common infected.

// global variables that deal with current game state
new bool:g_roundEnded     = false;
new bool:g_collectStats   = false;
new bool:g_loadLate       = false;
new bool:g_printTankStats = false;
new String:g_gameMode[100];
new bool:g_statsEnabled    = false;
new bool:g_printMVP       = false;
// cvar handles

new Handle:cv_roundTrackerState = INVALID_HANDLE;
new Handle:cv_statsEnabled      = INVALID_HANDLE; // cvar that determines if stats are collected
new Handle:cv_printTankStats    = INVALID_HANDLE;
new Handle:cv_printMVP          = INVALID_HANDLE;

new Handle:item_count_results = INVALID_HANDLE;
new num_item_count_results = 0;

// Record variables---------------------------------
new record_id = -1;           //!< The id of the current record in progress. This is -1 if there is no game started.
new map_id     = -1;          //!< The id of the current map. If the map is not found, the map_id will remain at -1.
new start_tick = 0;           //!< The starting tick of the current round
new end_tick = 0;             //!< The ending tick of the current round

/* [5.000]***************GENERAL CALLBACK FUNCTIONS*************** */
public OnPluginStart() {
	// store current gamemode
	GetConVarString(FindConVar("mp_gamemode"), g_gameMode, sizeof(g_gameMode));

	// events to hook into
	HookEvent("player_hurt", Event_PlayerHurt);
	// HookEvent("player_death", Event_PlayerDeath); // not needed
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("infected_hurt", Event_InfectedHurt);
	// HookEvent("infected_death", Event_InfectedDeath); // cannot differentiate witch
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("survival_round_start", Event_RoundStart);
	HookEvent("scavenge_round_start", Event_RoundStart);
	HookEvent("versus_round_start", Event_RoundStart);
	// HookEvent("player_first_spawn", Event_PlayerFirstSpawn); //replaced with player_spawn
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	HookEvent("bot_player_replace", Event_BotPlayerReplace);
	// HookEvent("witch_killed", Event_WitchDeath);
	
	// HookEvent("weapon_fire", Event_WeaponFire);
	// HookEvent("weapon_reload", Event_WeaponReload);
	// HookEvent("weapon_zoom", Event_WeaponZoom);
	
	
	// Admin commands - these are not usable by non admin users
	RegAdminCmd("sm_resetstats", Command_ResetStats,ADMFLAG_GENERIC);
	RegAdminCmd("sm_statson", Command_StatsOn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_statsoff", Command_StatsOff, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tankstatson", Command_TankStatsOn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tankstatsoff", Command_TankStatsOff, ADMFLAG_GENERIC);

	RegAdminCmd("sm_printtracked", Command_PrintTracked, ADMFLAG_GENERIC); 	// Debug commands for developers

	// Console/User commands - these are usable by all users
	RegConsoleCmd("sm_stats", Command_Stats); // accepted args "!stats <name>, !stats all, !stats mvp, !stats 
	RegConsoleCmd("sm_counts", Command_ItemCounts);
	RegConsoleCmd("sm_item_counts", Command_ItemCounts);
	RegConsoleCmd("sm_top10", Command_Top10);
	RegConsoleCmd("sm_top_stats", Command_Top10);

	// Console commands for testing SQL-----------------
	RegConsoleCmd("sm_umvp_add_player",                Command_AddPlayerToDB);
	RegConsoleCmd("sm_umvp_help",                      Command_Help);
	RegConsoleCmd("sm_umvp_connect_test_db",           Command_ConnectTestDB);
	RegConsoleCmd("sm_umvp_add_official_maps",         Command_AddOfficialMaps);
	RegConsoleCmd("sm_umvp_add_official_weapons",      Command_AddOfficialWeapons);
	RegConsoleCmd("sm_umvp_add_connected_players",     Command_AddConnectedPlayers);
	RegConsoleCmd("sm_umvp_add_weapon",                Command_AddWeapon);
	RegConsoleCmd("sm_umvp_add_record",                Command_CreateRecord);
	RegConsoleCmd("sm_umvp_add_team",                  Command_AddTeam);
	RegConsoleCmd("sm_umvp_add_model_types",           Command_AddModelTypes);
	RegConsoleCmd("sm_umvp_add_game_client",           Command_AddGameClient);
	RegConsoleCmd("sm_umvp_get_mapid",                 Command_GetCurrentMapID);
	RegConsoleCmd("sm_umvp_output_player_table",       Command_OutputPlayerTable);
	RegConsoleCmd("sm_umvp_output_maps_table",         Command_OutputMapsTable);
	RegConsoleCmd("sm_umvp_output_weapons_table",      Command_OutputWeaponTable);
	RegConsoleCmd("sm_umvp_output_records_table",      Command_OutputRecordTable);
	RegConsoleCmd("sm_umvp_output_game_client_table",  Command_OutputGameClientTable);
	RegConsoleCmd("sm_umvp_output_model_types_table",  Command_QueryModelTypesTable);
	RegConsoleCmd("sm_umvp_output_team_table",         Command_OutputTeamTable);
	RegConsoleCmd("sm_umvp_count_kills",               Command_CountKills);
	
	// cvar processing
	cv_roundTrackerState = FindConVar("s3_roundTrackerState");
	cv_statsEnabled      = FindConVar("s3_stats_enabled");
	cv_printTankStats    = FindConVar("s3_print_tank_stats");
	cv_printMVP          = FindConVar("s3_print_mvp");
	
	// initialize
	if (cv_printMVP == INVALID_HANDLE) {
		cv_printMVP = CreateConVar("s3_print_mvp", "1", "0 disable mvp printout, 1 enable mvp printout");
		SetConVarBool(cv_printMVP,true);
		g_printMVP = true;
		
	}
	else {
		g_printMVP = GetConVarBool(cv_printMVP);
	}
	
	if (cv_statsEnabled == INVALID_HANDLE) { // if there is no stats active cvar then defaults to active or true
		cv_statsEnabled = CreateConVar("s3_stats_enabled", "1", "0 don't collect stats, 1 collect stats");
		SetConVarBool(cv_statsEnabled,true);
		g_statsEnabled = true;
	}
	else {
		g_statsEnabled = GetConVarBool(cv_statsEnabled);
	}
	
	if (cv_printTankStats == INVALID_HANDLE) { // if there is no print tank stats cvar then default to active or true
		cv_printTankStats = CreateConVar("s3_print_tank_stats", "1", "0 disable tank damage printout, 1 print tank damage stats after every tank");
		SetConVarBool(cv_printTankStats,true);
		g_printTankStats = true;
	}
	else {
		g_printTankStats = GetConVarBool(cv_printTankStats);
	}
	
	
	// check if plugin was loaded late
	if (g_loadLate) {
		PreparePlayersForStatsCollect();
		new String:roundState[30];
		GetConVarString(cv_roundTrackerState,roundState, sizeof(roundState));
		if (cv_roundTrackerState == INVALID_HANDLE) {
			roundState = "mapstarted";
		}
		if (IsGameMode("coop") || IsGameMode("realism")) { // if it's a coop variant start collecting stats
			if (g_statsEnabled) {
				Command_StatsOn(0,0);
				if (g_printTankStats) {
					Command_TankStatsOn(0,0);
				}
			}
		}
		else { // if it's a round based game mode then determine action by round state
			if (StrEqual(ROUND_STATES[10],roundState,false) ||
				StrEqual(ROUND_STATES[9],roundState,false) ||
				StrEqual(ROUND_STATES[7],roundState,false) ||
				StrEqual(ROUND_STATES[6],roundState,false)) { // if the game is running make sure stats can be collected
				
				if (g_statsEnabled) {
					Command_StatsOn(0,0);
					if (g_printTankStats) {
						Command_TankStatsOn(0,0);
					}
				}
			}
			else {
				Command_StatsOff(0,0);
			}
		}
	}


	Command_ConnectTestDB(-1, 0);
	AddOfficialMaps(-1);
	AddOfficialWeapons(-1);
	AddModelTypes(-1);

	ConnectSurvivalStatsDB();
	ConnectSurvivalCountsDB();
}

public OnPluginEnd() {
	CloseHandle2(survival_records_db);
	CloseHandle2(survival_counts_db);
	CloseHandle2(item_count_results);
	CloseHandle2(test_db_sqlite);
	num_item_count_results = 0;
}

public OnMapStart() {
	GetConVarString(FindConVar("mp_gamemode"), g_gameMode, sizeof(g_gameMode));
	PrintToServer("MAP START, coop = %s realism = %s Activeplugin = %s supported = %s",IsGameMode("coop") ? "true" : "false",IsGameMode("realsim") ? "true" : "false",IsStatsPluginActive() ? "true" : "false", IsSupportedGameMode(g_gameMode) ? "true" : "false");
	if (IsSupportedGameMode(g_gameMode) && IsStatsPluginActive() && (IsGameMode("coop") || IsGameMode("realism"))) {
		Command_StatsOn(0,0);
		Command_ResetStats(0,0);
		PreparePlayersForStatsCollect();
	}
	else {
		Command_StatsOff(0,0);
	}
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
	}
	return Plugin_Handled;
}

public Action:Command_StatsOff(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		// disable stats collection
		g_collectStats = false;
	}
	return Plugin_Handled;
}

public Action:Command_TankStatsOff(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		// disable tank stats
		g_printTankStats = false;
	}
	return Plugin_Handled;
}

public Action:Command_TankStatsOn(client, args) {
	if (IsSupportedGameMode(g_gameMode)) {
		// disable tank stats
		g_printTankStats = true;
	}
	return Plugin_Handled;
}

public Action:Command_PrintTracked(client, args) {
	PrintToChatAll("g_collectStats = %s g_pluginActive = %s g_printTankStats = %s g_printMVP = %s",(g_collectStats) ? "true" : "false",(g_statsEnabled) ? "true" : "false",(g_printTankStats) ? "true" : "false",(g_printMVP) ? "true" : "false");
	for (new i = 0; i < MaxClients; i++) {
		if(IsValidPlayerID(i) && (strlen(g_playerName[i]) > 0)) {
			PrintToChatAll("g_playerActive = %s client: %d playerID: %d playerName: %s steamID: %s",
			(g_playerActive[i]) ? "true" : "false", i, i, g_playerName[i], g_playerSteamID[i]);
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
			if (j < 47) {
				if (j < 10) {
					g_survivorItemsUsed[i][j] = 0;
				}
				if (j < 9) {
					g_survivorKills[i][j] = 0;
					g_survivorDmg[i][j] = 0;
					if (j < 8) {
						g_survivorHitGroupType1[i][j] = 0;
						g_survivorHitGroupTypeSurvivor[i][j] = 0;
						if (j < 6) {
							g_survivorHitGroupType2[i][j] = 0;
							if (j < 5) {
								g_survivorCoolKills[i][j] = 0;
							}
						}
					}
				}
				g_survivorReloaded[i][j] = 0;
				g_survivorScoped[i][j] = 0;
				g_survivorShotsFired[i][j] = 0;
				g_survivorShotsHit[i][j] = 0;
			}
			
		}
		
		if (i < 9) {
			g_survivorTotalKills[i] = 0;
			g_survivorTotalDmg[i] = 0;
		}
		
		g_survivorAmmoPickedUp[i] = 0;
		
		
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

	return Plugin_Handled;
}

/* [7.000]***************CONSOLE COMMAND FUNCTIONS*************** */

public Action:Command_Stats(client, args) {
	if (IsSupportedGameMode(g_gameMode) && IsStatsPluginActive()) {
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
				else if (StrEqual(arg1, "items", false)) {
					PrintStats(client, 50000, false); // prints
				}
				else if (StrEqual(arg1, "count", false)) {
					Command_ItemCounts(client,0); // prints item counts
				}
				else if (StrEqual(arg1, "penis", false)) {
					PrintToChat(client,"\x048=============================\x01D"); // prints item counts
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
//--------------------------------------------------
//! \brief Gets the item counts for the current map and displays it to the user.
//! \details The statistics are retrived from the survival_counts sqlite database.
//--------------------------------------------------
public Action:Command_ItemCounts(client, args)
{
	if ((IsGameMode("survival") || IsGameMode("hardtwentysurvival")) && IsStatsPluginActive()) {
		decl String:mname[64];

		// get the current map name
		GetCurrentMap(mname, sizeof(mname));
		PrintToChat(client, "Searching for map %s...", mname);

		// find the human-readable name of the map from the list of official maps
		for (new i = 0; i < NUM_OFFICIAL_MAPS_2; i++)
		{
			if (StrEqual(OFFICIAL_MAPS_2[i], mname))
			{
				PrintItemCounts(client, OFFICIAL_MAP_NAMES_2[i]);
				return Plugin_Handled;
			}
		}

		PrintToChat(client, "Map %s not found in the database", mname);
	}
	return Plugin_Handled;
}

//--------------------------------------------------
//! \brief Gets the top 10 statistic for the current map and displays it to the user.
//! \details The statistics are retrived from the survival_records sqlite database.
//--------------------------------------------------
public Action:Command_Top10(client, args)
{
	if (IsGameMode("survival") && IsStatsPluginActive()) {
		decl String:mname[64];

		// get the current map name
		GetCurrentMap(mname, sizeof(mname));
		PrintToChat(client, "Searching for map %s...", mname);

		// find the human-readable name of the map from the list of official maps
		for (new i = 0; i < NUM_OFFICIAL_MAPS_2; i++)
		{
			if (StrEqual(OFFICIAL_MAPS_2[i], mname))
			{
				PrintTop10Times(client, OFFICIAL_MAP_NAMES_2[i], 10);
				return Plugin_Handled;
			}
		}

		PrintToChat(client, "Map %s not found in the database", mname);
	}
	return Plugin_Handled;
}

/* [8.000]***************EVENT CALLBACK FUNCTIONS*************** */

public Action:Event_PlayerHurt(Handle:event, String:event_name[], bool:dontBroadcast) {

	if (g_collectStats && IsStatsPluginActive()) { // collect stats if stats collection is enabled
		// other info
		new damage   = GetEventInt(event, "dmg_health");
		new hitgroup = GetEventInt(event, "hitgroup");

		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new victimRemainingHealth = GetEventInt(event, "health");
		new victimPID = GetPlayerIDOfClient(victim);

		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new attackerPID = GetPlayerIDOfClient(attacker);

		new model_type = 0;

		// getting the weapon information
		decl String:weapon[64];

		// get the attackers weapon
		GetClientWeapon(attacker, weapon, sizeof(weapon));

		// find out what the weaponid is
		new weapon_id = GetWeaponIndex(weapon);

		if ((damage > 0) && IsClientAlive(victim) && IsClientAlive(attacker) && IsValidPlayerID(attackerPID) && IsValidPlayerID(victimPID)) { // process further if damage is 0, and victim and attacker clients are real
			if (IsClientSurvivor(attacker)) {
				// process victim
				new String:victimModel[50];
				new victimTeam = GetPlayerTeam(victimPID);

				GetClientModel(victim,victimModel, sizeof(victimModel));
				
				if (victimTeam == TEAM_SURVIVOR) {
					model_type = GetModelIndex("Survivor");

					RecordFFDamage(attackerPID, damage);
				}
				else if (victimTeam == TEAM_INFECTED) {

					if (StrContains(victimModel, "Hunter", false) != -1) {
						model_type = GetModelIndex("Hunter");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, HUNTER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),HUNTER);

							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,HUNTER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,HUNTER);
					}
					else if (StrContains(victimModel, "Jockey", false) != -1) {
						model_type = GetModelIndex("Jockey");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, JOCKEY);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),JOCKEY);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,JOCKEY);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,JOCKEY);
					}
					else if (StrContains(victimModel, "Charger", false) != -1) {
						model_type = GetModelIndex("Charger");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, CHARGER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),CHARGER);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,CHARGER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,CHARGER);
					}
					else if (StrContains(victimModel, "Spitter", false) != -1) {
						model_type = GetModelIndex("Spitter");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, SPITTER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),SPITTER);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,SPITTER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,SPITTER);
					}
					else if (StrContains(victimModel, "Boome", false) != -1) {
						model_type = GetModelIndex("Boomer");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, BOOMER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),BOOMER);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,BOOMER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,BOOMER);
					}
					else if (StrContains(victimModel, "Smoker", false) != -1) {
						model_type = GetModelIndex("Smoker");

						if (victimRemainingHealth == 0) {
							RecordKill(attackerPID, SMOKER);
							RecordDamage(attackerPID,GetPlayerHealth(victimPID),SMOKER);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
						}
						else {
							RecordDamage(attackerPID,damage,SMOKER);
							DamagePlayer(victimPID, damage);
						}
						RecordHitGroup(attackerPID,hitgroup,SMOKER);
					}
					else if (StrContains(victimModel, "Hulk", false) != -1) {
						model_type = GetModelIndex("Tank");

						if(IsTankIncapacitated(victim) && IsPlayerActive(victimPID)) {
							// PrintToChatAll("Tank Incapped. Damage = %d, Tank health = %d",GetPlayerHealth(victimPID),GetPlayerHealth(victimPID));

							RecordDamage(attackerPID,GetPlayerHealth(victimPID),TANK);
							RecordKill(attackerPID,TANK);
							AddKill(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, GetWeaponIndex(weapon), hitgroup, 0, 0, 0);
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

				// record the damage into the database
				if (record_id > 0 && IsValidPlayerID(attackerPID) && weapon_id >= 0)
				{
					if (IsValidPlayerID(victimPID))
					{
						AddDamage(record_id, g_gameClientID[attackerPID], g_gameClientID[victimPID], GetSysTickCount(), damage, weapon_id, hitgroup, 0, 0, 0);
					}
					else
					{
						AddDamage(record_id, g_gameClientID[attackerPID], -1, GetSysTickCount(), damage, weapon_id, hitgroup, 0, 0, 0);
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

	if (g_collectStats && IsStatsPluginActive() && IsValidPlayerID(attackerPID) && IsClientSurvivor(attacker)) {
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

		// new String:victimModel[100];
		// GetClientModel(victim,victimModel, sizeof(victimModel));
		if ((model_id == 559) || (model_id == 255) ||(model_id == 441)) {
			RecordDamage(attackerPID, realdamage, WITCH);
			RecordHitGroup(attackerPID, hitgroup, WITCH);
		}
		else {
			RecordDamage(attackerPID, realdamage, COMMON);
			RecordHitGroup(attackerPID, hitgroup, COMMON);
		}

		// record kill if ci health is 0
		if (CIHealth[victim] == 0) {
			if ((model_id == 559) || (model_id == 255) ||(model_id == 441)) {
				RecordKill(attackerPID,WITCH);
			}
			else {
				RecordKill(attackerPID,COMMON);
			}
		}

		// survivorDmg[attacker][COMMON] += realdamage;

		// check for a headshot
		// if (hitgroup == 1) {
			// survivorHeadShots[attacker]++;
		// }

		// find out what the weaponid is
		new weapon_id = GetWeaponIndex(weapon);

		// For now use -1 for the victom id, since the victim is common infected (bot)
		// TODO: for now, the coordinates are put in 0,0,0
		if (record_id > 0 && IsValidPlayerID(attackerPID) && weapon_id >= 0)
		{
			AddDamage(record_id, g_gameClientID[attackerPID], -1, GetSysTickCount(), realdamage, weapon_id, hitgroup, 0, 0, 0);
		}

#if INFECTED_HURT_DEBUG
		//debug
		PrintToChatAll("entID: %d CIHealth: %d original_damage: %d damage: %d realdamage: %d hitgroup: %d type: %d modelid: %d maxhp: %d", victim, CIHealth[victim], original_damage, damage, realdamage, hitgroup, GetEventInt(event, "type"),model_id,(GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff));
#endif

	}
}

/*
public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	// attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new attackerPID = GetPlayerIDOfClient(attacker);
	new victim = GetEventInt(event,"infected_id");
	// Ensure that the infected health is set to zero. This should be the case in almost all situations, however, the survivor zombie has some weird damage properties that causes it to show up having health remaining even though it is dead.
	CIHealth[victim] = 0;
	new model_id = GetEntProp(victim, Prop_Send, "m_nModelIndex");
	//Only process if the player is a legal attacker (i.e., a player)
	if (g_collectStats && IsClientSurvivor(attacker) && IsValidPlayerID(attackerPID))
	{
		PrintToChatAll("model_id = %d, infected_id = %d",model_id, victim);
		if (!(model_id == 559) && !(model_id == 255) && !(model_id == 441)) {
			// RecordKill(attackerPID,WITCH);
			RecordKill(attackerPID,COMMON);
		}
	}
}*/

/*
public Event_WitchDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerPID = GetPlayerIDOfClient(attacker);
	new victim = GetEventInt(event,"witchid");
	CIHealth[victim] = 0;
	RecordKill(attackerPID,WITCH);
}
*/
// Round Events

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	PrintToServer("ROUND START");
	if (IsStatsPluginActive() && IsSupportedGameMode(g_gameMode)) {
		Command_ResetStats(0,0);
		g_roundEnded = false;
		Command_StatsOn(0,0);
		
		// initialize survivors for stats collection
		PreparePlayersForStatsCollect();

		// reset the time variables to the beginning
		ResetTimeVars();

		GetCurrentMapID(-1);

		// Add a new record
		CreateRecord(-1);

		// Add the active players into the record - making sure that all participants are in the database
		AddConnectedPlayers();

		// Add the active team into the database
		AddTeam(-1);

		// Ensure that the players that are playing are added as game clients
		AddGameClientSurvivors(-1, start_tick);
	}
#if DEBUG
	PrintToChatAll("\x01Event_RoundStart \x04FIRED[ResetStats(0,0); g_roundEnded = false; g_collectStats = true;]");
#endif
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	PrintToServer("ROUND END");
	if (IsStatsPluginActive() && IsSupportedGameMode(g_gameMode)) {
		if (!g_roundEnded && IsMVPActive()) {
			PrintStats(0, 20000,false);
			g_roundEnded = true;
		}
		Command_StatsOff(0,0);
	}

	// update the end time
	if (end_tick == start_tick)
		end_tick = GetSysTickCount();

	// update the end time for the record
	if (record_id != -1)
	{
		decl String:query[1024];
		Format(query, sizeof(query), "UPDATE record SET duration = %d WHERE recordID = %d", end_tick - start_tick, record_id);
		SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
	}

	// update the time of death for the survivors in the database
	// first obtain the players and their steam ids
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i))
			{
				new playerID = GetPlayerIDOfClient(i);
				// make sure that the player is active
				if (g_playerActive[playerID])
				{
					// set the death time

					// modify the gameclient and add this as their time of death
					decl String:query[1024];

					Format(query, sizeof(query), "UPDATE gameClient SET deathTime=%d WHERE entryID=%d", end_tick, g_gameClientID[playerID]);
					SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
				}
			}
		}
	}
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
			new String:model[100];
			GetClientModel(client,model, sizeof(model));
			if (StrContains(model,"hulk",false)) { // tank may have suicided so wipe the stats because playerid may be reused
				WipeTankStats(playerID);
			}
			SetPlayerHealth(playerID, GetClientHealth(client));


			// check to see if the player is in the database
			/*
			if (QueryForPlayer(client) == false)
			{
				// add this new player in the database
				AddNewClient(client);
			}
			*/
			AddNewClient(client);

			// now add the player into the team table

			// case: survivor
			if (IsClientSurvivor(client) || IsClientInfected(client))
			{
				decl String:steam_id[32];
				GetClientAuthString(client, steam_id, sizeof(steam_id));
				// add the player to the gameClient under the survivor model type
				// first check that the record_id is valid
				if (record_id > 0)
				{
					decl String:query[1024];
					Format(query, sizeof(query), "INSERT INTO gameClient (modelID, steamID, birthTime, deathTime) VALUES (%d, \'%s\', %d, %d)", 0, steam_id, GetSysTickCount(), -1);
					SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
				}
			}
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

			// TODO: if the player disconnected before the round ended, there needs to be an indication in the sql database that this happened.
			if (end_tick == start_tick)
			{
				// modify the gameclient and add this as their time of death
				decl String:query[1024];

				Format(query, sizeof(query), "UPDATE gameClient SET deathTime=%d WHERE entryID=%d", GetSysTickCount(), g_gameClientID[playerID]);
				SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
			}
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
			SetPlayerHealth(botPlayerID,GetClientHealth(bot));
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


// weapon events
public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsClientSurvivor(client)) {
		new playerID = GetPlayerIDOfClient(client);
		new weaponID = GetEventInt(event,"weaponid");
		new shots    = GetEventInt(event,"count");
		RecordWeaponFire(playerID, weaponID, shots);
	}
}

/* [9.000]***************HELPER FUNCTIONS*************** */

PrintStats(printToClient, option, bool:detail) {
	new totalSIDamage = GetTotalDamage(HUNTER) + GetTotalDamage(JOCKEY) + GetTotalDamage(CHARGER) + GetTotalDamage(SPITTER) + GetTotalDamage(SMOKER) + GetTotalDamage(BOOMER);
	new totalSIKills = GetTotalKills(HUNTER) + GetTotalKills(JOCKEY) + GetTotalKills(CHARGER) + GetTotalKills(SMOKER) + GetTotalKills(SPITTER) + GetTotalKills(BOOMER);
	
	if (StrEqual(g_gameMode, "coop",false) || StrEqual(g_gameMode, "versus",false) || StrEqual(g_gameMode, "realism",false)) {
		totalSIDamage += GetTotalDamage(WITCH);
		totalSIKills += GetTotalKills(WITCH);
	}

	
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
				new String:name[33];
				new client = GetClientOfPlayerID(i);
				
				if (client == -1) {
					strcopy(name, 33, g_playerName[i]);
				}
				else if ((client > 0) && (client < MaxClients)) {
					GetClientName(client,name,sizeof(name));
					strcopy(g_playerName[i], 33,name);
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
					strcopy(g_playerName[orderedInfo[l][0]], 33,name);
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
				if (StrEqual(g_gameMode, "coop",false) || StrEqual(g_gameMode, "versus",false) || StrEqual(g_gameMode, "coop",false)) {
					PrintToChatAll("\x04[Hunter]: \x01%4d \x04[Witch]: \x01%4d",GetTotalKills(HUNTER),GetTotalKills(WITCH));
				}
				else {
					PrintToChatAll("\x04[Hunter]: \x01%4d",GetTotalKills(HUNTER));
				}
				PrintToChatAll("\x04[Charger]: \x01%4d",GetTotalKills(CHARGER));
				PrintToChatAll("\x04[Spitter]: \x01%4d",GetTotalKills(SPITTER));
			}
			else {
				PrintToChat(printToClient,"\x04[Jockey]: \x01%4d \x04[Total SI]: \x01%d",GetTotalKills(JOCKEY), totalSIKills);
				PrintToChat(printToClient,"\x04[Smoker]: \x01%4d \x04[Common]: \x01%d",GetTotalKills(SMOKER), GetTotalKills(COMMON));
				PrintToChat(printToClient,"\x04[Boomer]: \x01%4d \x04[Tanks]: \x01%d",GetTotalKills(BOOMER),GetTotalKills(TANK));
				if (StrEqual(g_gameMode, "coop",false) || StrEqual(g_gameMode, "versus",false) || StrEqual(g_gameMode, "coop",false)) {
					PrintToChat(printToClient,"\x04[Hunter]: \x01%4d \x04[Witch]: \x01%4d",GetTotalKills(HUNTER),GetTotalKills(WITCH));
				}
				else {
					PrintToChat(printToClient,"\x04[Hunter]: \x01%4d",GetTotalKills(HUNTER));
				}
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
				strcopy(g_playerName[option], 33,name);
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
			new Float:PercentDamage[9];
			new Float:PercentKills[9];
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
				if (StrEqual(g_gameMode, "coop",false) || StrEqual(g_gameMode, "versus",false) || StrEqual(g_gameMode, "realism",false)) {
					PrintToChat(printToClient,"\x04[W] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",GetTotalKillsByPlayer(option,WITCH),GetTotalKills(WITCH), PercentKills[WITCH], GetTotalDamageByPlayer(option,WITCH),GetTotalDamage(WITCH),PercentDamage[WITCH]);
				}
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
				strcopy(g_playerName[orderedInfo[j][0]], 33,name);
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
	rating += (TankDamage*2);
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
			if (StrContains(g_playerName[i], name, false) != -1) {
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
	if (IsGameMode("coop") || IsGameMode("versus") || IsGameMode("realism")) {
		return (g_survivorKills[playerID][WITCH] + g_survivorKills[playerID][HUNTER] + g_survivorKills[playerID][JOCKEY] + g_survivorKills[playerID][CHARGER] + g_survivorKills[playerID][SPITTER] + g_survivorKills[playerID][SMOKER] + g_survivorKills[playerID][BOOMER]);
	}
	return (g_survivorKills[playerID][HUNTER] + g_survivorKills[playerID][JOCKEY] + g_survivorKills[playerID][CHARGER] + g_survivorKills[playerID][SPITTER] + g_survivorKills[playerID][SMOKER] + g_survivorKills[playerID][BOOMER]);
}

GetTotalSIDamage(playerID) {
	if (IsGameMode("coop") || IsGameMode("versus") || IsGameMode("realism")) {
		return (g_survivorKills[playerID][WITCH] + g_survivorDmg[playerID][HUNTER] + g_survivorDmg[playerID][JOCKEY] + g_survivorDmg[playerID][CHARGER] + g_survivorDmg[playerID][SPITTER] + g_survivorDmg[playerID][SMOKER] + g_survivorDmg[playerID][BOOMER]);
	}
	return (g_survivorKills[playerID][HUNTER] + g_survivorKills[playerID][JOCKEY] + g_survivorKills[playerID][CHARGER] + g_survivorKills[playerID][SPITTER] + g_survivorKills[playerID][SMOKER] + g_survivorKills[playerID][BOOMER]);
}

GetTotalKillsByPlayer(playerID, victimType) {
	return g_survivorKills[playerID][victimType];
}

GetTotalDamageByPlayer(playerID, victimType) {
	return g_survivorDmg[playerID][victimType];
}

GetBulletsFired(playerID, weaponID) {
	return g_survivorShotsFired[playerID][weaponID];
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
	for (new i = 0; i < NUM_GAMEMODES; i++) {
		if (StrEqual(mode, GAME_MODES[i],false)) {
			return true;
		}
	}
	return false;
}

bool:IsStatsPluginActive() {
	return g_statsEnabled;
}

bool:IsMVPActive() {
	return g_printMVP;
}



bool:RecordKill(attackerPID, victimType) {
	if((victimType >=0) && (victimType < 9)) {
		g_survivorKills[attackerPID][victimType]++;
		g_survivorTotalKills[victimType]++;
		return true;
	}
	return false;
}

bool:RecordDamage(playerID, damage, victimType) {
	if((victimType >=0) && (victimType < 9)) {
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

RecordWeaponFire(playerID,weaponID,shots) {
	g_survivorShotsFired[playerID][weaponID] += shots; 
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

//--------------------------------------------------
//! \brief given a time in milliseconds, this function will store the string representation of the time in the buffer.
//!
//! \param[in] buf                 The buffer to store the output in
//! \param[in] buflen              size of the buffer
//! \param[in] total_milliseconds  The total milliseconds to convert
//--------------------------------------------------
display_time(String:buf[], buflen, total_milliseconds)
{
	new minutes = total_milliseconds / 1000 / 60;
	new seconds = total_milliseconds / 1000 % 60;
	new ms = total_milliseconds % 1000;

	Format(buf, buflen, "%d:%02d:%02d", minutes, seconds, ms / 10);
}


/* [10.000]***************DATABASE FUNCTIONS********************* */
CloseHandle2(&Handle:target) {
	new bool:close_test = false;
	
	if(target != INVALID_HANDLE) {
		close_test = CloseHandle(target);
		if(close_test) {
			target = INVALID_HANDLE;
		}
	}
	
	return close_test;
}

ConnectSurvivalStatsDB()
{
	decl String:error[256];

	// connect to the test database (SQLite)
	new Handle:keyval = CreateKeyValues("Survival Stats Database Connect");
	KvSetString(keyval, "driver", "sqlite");
	KvSetString(keyval, "host", "localhost");
	KvSetString(keyval, "database", "survival_records");

	// used to set the username and pw
	//KvSetString(keyval, "user", "root");
	//KvSetString(keyval, "pass", "");

	CloseHandle2(survival_records_db);
	survival_records_db = SQL_ConnectCustom(keyval, error, sizeof(error), true);

	CloseHandle(keyval);
}

ConnectSurvivalCountsDB()
{
	decl String:error[256];

	// connect to the test database (SQLite)
	new Handle:keyval = CreateKeyValues("Survival Counts Database Connect");
	KvSetString(keyval, "driver", "sqlite");
	KvSetString(keyval, "host", "localhost");
	KvSetString(keyval, "database", "survival_counts");

	// used to set the username and pw
	//KvSetString(keyval, "user", "root");
	//KvSetString(keyval, "pass", "");

	CloseHandle2(survival_counts_db);
	survival_counts_db = SQL_ConnectCustom(keyval, error, sizeof(error), true);
	CloseHandle(keyval);
}

//--------------------------------------------------
// PrintItemCounts
//!
//! \brief Queries the database for the item counts and prints it to chat.
//!
//! \param[in] client The client id to output to. Use -1 for print to all
//! \param[in] map_name The map to print the top times out for. The map name should be one located in the OFFICIAL_MAP_NAMES_2 array.
//!
//! \returns true on success
//--------------------------------------------------
PrintItemCounts(client, String:map_name[])
{
	decl String:query[1024];

	Format(query, sizeof(query), "SELECT ItemType.name, Item.name, Count.count FROM Count INNER JOIN Map ON Map.id == Count.map_id INNER JOIN Item ON Item.id == Count.item_id INNER JOIN ItemType ON Item.type_id == ItemType.id  WHERE Map.name == '%s' AND Count.count > 0 ORDER BY Item.id;", map_name);

	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, client);
	WritePackString(dataPack, map_name);

	SQL_TQuery(survival_counts_db, PostQueryPrintItemCounts, query, dataPack);
}

//
public PostQueryPrintItemCounts(Handle:owner, Handle:result, const String:error[], any:data)
{
	new Handle:dataPack = data;
	// decl String:buf[200];
	decl String:item[100];
	decl String:type[100];
	decl String:map_name[100];
	new count;
	new num_results;

	// get the values out of the data pack
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	ReadPackString(dataPack, map_name, sizeof(map_name));
	CloseHandle(dataPack);

	if (result == INVALID_HANDLE)
	{
		PrintToChat(client, "Error ItemCountQuery: %s", error);
		return;
	}

	if (client > 0)
		PrintToChat(client, "Item counts for %s", map_name);

	num_results = SQL_GetRowCount(result);
	if (item_count_results == INVALID_HANDLE)
	{
		item_count_results = CreateDataPack();
	}

	num_item_count_results = 0;
	ResetPack(item_count_results);

	while (SQL_FetchRow(result))
	{
		SQL_FetchString(result, 0, type, sizeof(type));
		SQL_FetchString(result, 1, item, sizeof(item));
		count = SQL_FetchInt(result, 2);

		WritePackString(item_count_results, type);
		WritePackString(item_count_results, item);
		WritePackCell(item_count_results, count);
		num_item_count_results++;

		//Format(buf, sizeof(buf), "%s: %d", item, count);
		//if (client > 0)
			//PrintToConsole(client, buf);
	}

	if (client > 0) PrintToConsole(client, "Health-----------------");
	PrintItemCountResult(client, item_count_results, num_results, "Health");
	if (client > 0) PrintToConsole(client, "Throwable--------------");
	PrintItemCountResult(client, item_count_results, num_results, "Throwable");
	if (client > 0) PrintToConsole(client, "Melee Weapon-----------");
	PrintItemCountResult(client, item_count_results, num_results, "Melee Weapon");
	if (client > 0) PrintToConsole(client, "Gun--------------------");
	PrintItemCountResult(client, item_count_results, num_results, "Gun");
	if (client > 0) PrintToConsole(client, "Ammo-------------------");
	PrintItemCountResult(client, item_count_results, num_results, "Ammo");
	if (client > 0) PrintToConsole(client, "Explosive--------------");
	PrintItemCountResult(client, item_count_results, num_results, "Explosive");

	ShowItemCountPanel(client, item_count_results, num_results);
}

PrintItemCountResult(client, Handle:results, num_results, String:print_type[])
{
	decl String:item[100];
	decl String:type[100];
	new count;

	ResetPack(results);
	// now loop through the results however we want to and print out
	//
	// ItemType can be one of the following:
	//                     Health
	//                     Throwable
	//                     Melee Weapon
	//                     Gun
	//                     Ammo
	//                     Explosive
	for (new i = 0; i < num_results; i++)
	{
		ReadPackString(results, type, sizeof(type));
		ReadPackString(results, item, sizeof(item));
		count = ReadPackCell(results);

		if (StrEqual(type, print_type) == true)
		{
			if (client > 0)
				PrintToConsole(client, "%s: %d", item, count);
		}
	}
}

//! \brief Used to show a menu containing the resulting item counts. The results are sent in through the a datapack.
//! \param[in] client       The client to display the panel to
//! \param[in] results      The datapack handle of the results
//! \param[in] num_results  The number of results obtained from the datapack
ShowItemCountPanel(client, Handle:results, num_results)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Item Counts");
	for (new i = 0; i < NUM_ITEM_TYPES; i++)
	{
		DrawPanelItem(panel, ITEM_TYPES[i]);
	}
	SendPanelToClient(panel, client, ShowItemCountPanelHandler, 60);
	CloseHandle(panel);
}

public ShowItemCountPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//PrintToConsole(param1, "You selected item %d", param2);
		DisplayCountPanel(param1, param2-1);
	}
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled. Reason: %d", param1, param2);
	}
}

//! \brief Displays the selected item counts
//! \param[in] client The client index to display to
//! \param[in] i      The index of the item count to show
DisplayCountPanel(client, i)
{
	decl String:item[100];
	decl String:type[100];
	decl String:buf[50];
	new count;
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, ITEM_TYPES[i]);

	ResetPack(item_count_results);
	for (new j = 0; j < num_item_count_results; j++)
	{
		ReadPackString(item_count_results, type, sizeof(type));
		ReadPackString(item_count_results, item, sizeof(item));
		count = ReadPackCell(item_count_results);

		if (StrEqual(type, ITEM_TYPES[i]) == true)
		{
			Format(buf, sizeof(buf), "%s: %d", item, count);
			DrawPanelItem(panel, buf);
		}
	}
	SendPanelToClient(panel, client, DisplayCountPanelHandler, 60);

	CloseHandle(panel);
}

public DisplayCountPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	// do nothing
}

//--------------------------------------------------
// PrintTop10Times
//!
//! \brief Queries the database for the top 10 times and prints it to chat.
//!
//! \param[in] client The client id to output to. Use -1 for print to all
//! \param[in] map_name The map to print the top times out for. The map name should be one located in the OFFICIAL_MAP_NAMES_2 array.
//! \param[in] n The number of records to print out
//!
//! \returns true on success
//--------------------------------------------------
PrintTop10Times(client, String:map_name[], n)
{
	decl String:query[1024];

	Format(query, sizeof(query), "SELECT Record2.id, Record2.time, Record2.date, Player.name FROM Map INNER JOIN Record2 ON Map.id == Record2.map_id INNER JOIN Team ON Team.record_id == Record2.id INNER JOIN Player ON Player.id == Team.player_id WHERE Map.name == \'%s\' ORDER BY Record2.time DESC, Player.name COLLATE NOCASE;", map_name);

	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, client);
	WritePackCell(dataPack, n);
	WritePackString(dataPack, map_name);

	SQL_TQuery(survival_records_db, PostQueryPrintTop10Times, query, dataPack);
}

public PostQueryPrintTop10Times(Handle:owner, Handle:result, const String:error[], any:data)
{
	new const N = 3;
	new Handle:dataPack = data;
	decl String:buf[200];
	decl String:buf2[200];
	decl String:players[100];
	decl String:player[100];
	new record_id;
	new ms;
	decl String:date[32];
	decl String:time_str[32];
	decl String:map_name[100];
	new prev_id = -1;
	Format(buf, sizeof(buf), "");
	Format(players, sizeof(players), "");
	Format(player, sizeof(player), "");

	// get the values out of the data pack
	ResetPack(dataPack);
	new client = ReadPackCell(dataPack);
	new n = ReadPackCell(dataPack);
	ReadPackString(dataPack, map_name, sizeof(map_name));
	CloseHandle(dataPack);

	if (result == INVALID_HANDLE)
	{
		PrintToChat(client, "Error Top10: %s", error);
		return;
	}

	new count = 0;
	new numplayers;

	if (client > 0)
		PrintToChat(client, "Top survival times for %s", map_name);

	while (SQL_FetchRow(result))
	{
		if (prev_id == -1)
			count++;

		// get the record id, time, date, and name
		record_id = SQL_FetchInt(result, 0);
		ms = SQL_FetchInt(result, 1);
		display_time(time_str, sizeof(time_str), ms);
		SQL_FetchString(result, 2, date, sizeof(date));
		SQL_FetchString(result, 3, player, sizeof(player));

		// if the record_id is new,
		if (record_id != prev_id && prev_id != -1)
		{
			// output the record
			Format(buf, sizeof(buf), "%d) Time: %s Date: %s Players: %s", count, time_str, date, players);

			if (count <= N)
			{
				Format(buf2, sizeof(buf2), "%d) %s -- %s", count, time_str, players);
				if (client > 0)
					PrintToChat(client, buf2);
			}

			if (client > 0)
			{
				PrintToConsole(client, buf);
			}

			// reset the players string
			Format(players, sizeof(players), "");
			numplayers = 0;

			// increase the count
			count++;
			if (count > n)
				break;
		}
		// concatenate player into the players string
		if (numplayers > 0)
			StrCat(players, sizeof(players), ", ");
		StrCat(players, sizeof(players), player);
		numplayers++;

		prev_id = record_id;
	}

	// if count is smaller than n at this point, the last record didnt get printed, so print that out
	if (count <= n)
	{
		// output the record
		Format(buf, sizeof(buf), "Time: %s Date: %s Players: %s", time_str, date, players);

		if (client > 0)
		{
			PrintToConsole(client, buf);
		}
	}

	if (count <= N)
	{
		Format(buf2, sizeof(buf2), "%s -- %s", time_str, players);

		if (client > 0)
			PrintToChat(client, buf2);
	}
}

//--------------------------------------------------
// Command_ConnectTestDB
//!
//! \brief Connects to the test SQLite database
//--------------------------------------------------
public Action:Command_ConnectTestDB(client, args)
{
	decl String:error[256];

	// connect to the test database (SQLite)
	new Handle:keyval = CreateKeyValues("Test Database Connect");
	KvSetString(keyval, "driver", "sqlite");
	KvSetString(keyval, "host", "localhost");
	KvSetString(keyval, "database", "umvp_test");

	// used to set the username and pw
	//KvSetString(keyval, "user", "root");
	//KvSetString(keyval, "pass", "");

	CloseHandle2(test_db_sqlite);
	test_db_sqlite = SQL_ConnectCustom(keyval, error, sizeof(error), true);
	CloseHandle(keyval);


	for (new i = 0; i < NUM_TEST_COMMANDS; i++)
	{
		SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, sql_test_commands[i], client);
	}
	return Plugin_Handled;
}

//==================================================
// Commands
//==================================================

//--------------------------------------------------
// Command_Help
//!
//! \brief This command is used to print help of all the commands
//--------------------------------------------------
public Action:Command_Help(client, args)
{
	PrintToConsole(client, "Available Commands:");
	for (new i = 0; i < NUM_DEBUG_COMMANDS; i++)
	{
		PrintToConsole(client, DEBUG_COMMANDS[i]);
	}

	// Create a menu to output these commands
	//HelpMenu(client);

	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddTeam
//!
//! \brief Adds the current team consisting of the (up to 4) players to the team table
//--------------------------------------------------
public Action:Command_AddTeam(client, args)
{
	AddTeam(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddPlayerToDB
//!
//! \brief This command is used to add the current player to the player database
//--------------------------------------------------
public Action:Command_AddPlayerToDB(client, args)
{
	AddNewClient(client);
	PrintToConsole(client, "Player Added");

	return Plugin_Handled;
}

//--------------------------------------------------
// Command_CountKills
//!
//! \brief This command is used to count the number of kills obtained by each of the participating players
//--------------------------------------------------
public Action:Command_CountKills(client, args)
{
	CountKills(client);
}

//--------------------------------------------------
// Command_OutputMapsTable
//!
//! \brief This command is used to output the entire maps table to console.
//--------------------------------------------------
public Action:Command_OutputMapsTable(client, args)
{
	QueryMaps(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_OutputPlayerTable
//!
//! \brief This command is used to output the entire player table to console.
//--------------------------------------------------
public Action:Command_OutputPlayerTable(client, args)
{
	QueryPlayers(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_OutputWeaponTable
//!
//! \brief This command is used to output the entire weapons table to console.
//--------------------------------------------------
public Action:Command_OutputWeaponTable(client, args)
{
	QueryWeapons(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_OutputRecordTable
//!
//! \brief This command is used to output the entire records table to console.
//--------------------------------------------------
public Action:Command_OutputRecordTable(client, args)
{
	QueryRecords(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_OutputGameClientTable
//!
//! \brief This command is used to output the entire gameClient table to console.
//--------------------------------------------------
public Action:Command_OutputGameClientTable(client, args)
{
	QueryGameClients(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_OutputTeamTable
//!
//! \brief This command outputs all entries of the team table
//--------------------------------------------------
public Action:Command_OutputTeamTable(client, args)
{
	QueryTeamTable(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_QueryModelTypesTable
//!
//! \brief This command is used to output the entire modelTypes table to console.
//--------------------------------------------------
public Action:Command_QueryModelTypesTable(client, args)
{
	QueryModelTypes(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_CreateRecord
//!
//! \brief This command is used to output the entire records table to console.
//--------------------------------------------------
public Action:Command_CreateRecord(client, args)
{
	CreateRecord(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddOfficialMaps
//!
//! \brief This command is used to add the official maps into the maps table
//--------------------------------------------------
public Action:Command_AddOfficialMaps(client, args)
{
	AddOfficialMaps(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddWeapon
//!
//! \brief This command is used to add the official maps into the maps table
//--------------------------------------------------
public Action:Command_AddWeapon(client, args)
{
	decl String:weapon[128];
	// get the client's weapon
	GetClientWeapon(client, weapon, sizeof(weapon));
	AddWeapon(client, weapon);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddOfficialWeapons
//!
//! \brief This command is used to add the official weapons into the weapons table
//--------------------------------------------------
public Action:Command_AddOfficialWeapons(client, args)
{
	AddOfficialWeapons(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddConnectedPlayers
//!
//! \brief This command is used to add the official weapons into the weapons table
//--------------------------------------------------
public Action:Command_AddConnectedPlayers(client, args)
{
	new numplayers = AddConnectedPlayers();
	PrintToConsole(client, "Added %d players", numplayers);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddModelTypes
//--------------------------------------------------
public Action:Command_AddModelTypes(client, args)
{
	AddModelTypes(client);
	return Plugin_Handled;
}

//--------------------------------------------------
// Command_AddGameClient
//!
//! \brief Adds the current player as a game client. (Survivor support only a the moment)
//--------------------------------------------------
public Action:Command_AddGameClient(client, args)
{
	decl String:steamid[64];

	// get the steamid, which is used to identify players
	if (!GetClientAuthString(client, steamid, sizeof(steamid)))
		return Plugin_Handled;

	// get the time, use for birth time
	new birth_time = GetSysTickCount();
	new death_time = -1;

	// using 0 for model id
	new game_client_id = AddGameClient(client, steamid, 0, birth_time, death_time);

	PrintToConsole(client, "The new game client id is %d", game_client_id);

	return Plugin_Handled;
}

//--------------------------------------------------
// Command_GetCurrentMapID
//!
//! \brief queries the database for the current map id and prints the result to console.
//--------------------------------------------------
public Action:Command_GetCurrentMapID(client, args)
{
	new mid = GetCurrentMapID(client);
	PrintToConsole(client, "The current map id is %d", mid);
	return Plugin_Handled;
}

//==================================================
// Helper Functions and Callbacks
//==================================================

//--------------------------------------------------
// GetWeaponIndex
//!
//! \brief Given a string, looks up the weapon index in the weapons array
//! \returns index of the match or -1 if not found
//--------------------------------------------------
GetWeaponIndex(const String:weapon_name[])
{
	for (new i = 0; i < NUM_WEAPONS; i++)
	{
		if (StrContains(WEAPON_NAMES[i], weapon_name, false) != -1)
		{
			return i;
		}
	}

	return -1;
}

//--------------------------------------------------
// GetModelIndex
//!
//! \brief Given a string, looks up the model_types array for a match and returns the index of the match
//! \returns index of the match or -1 if not found
//--------------------------------------------------
GetModelIndex(const String:model_name[])
{
	for (new i = 0; i < NUM_MODEL_TYPES; i++)
	{
		if (strcmp(MODEL_TYPES[i], model_name, false) == 0)
		{
			return MODEL_TYPE_INDICES[i];
		}
	}

	return -1;
}

HelpMenu(client)
{
	new Handle:menu = CreateMenu(HelpMenuHandler);
	for (new i = 0; i < NUM_DEBUG_COMMANDS; i++)
	{
		AddMenuItem(menu, DEBUG_COMMANDS[i], DEBUG_COMMANDS[i]);
	}
	SetMenuTitle(menu, "Commands");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(menu);
}

public HelpMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		FakeClientCommand(param1, DEBUG_COMMANDS[param2-1]);
	}
	else if (action == MenuAction_Cancel)
	{
		//
	}
}

//--------------------------------------------------
// GetCurrentMapID
//!
//! \brief   Queries the database for the mapID of the current map.
//! \details Note: the variable mapID is updated by this call.
//! \returns The mapID is returned or -1 if not found.
//--------------------------------------------------
GetCurrentMapID(client)
{
	decl String:currmap[64];
	decl String:query[1024];
	decl String:error[128];

	// get the name of the current map
	GetCurrentMap(currmap, sizeof(currmap));

	if (client > 0)
		PrintToConsole(client, "Searching for map %s...", currmap);
	// query the database for this map
	Format(query, sizeof(query), "SELECT mapID FROM maps WHERE mapName = \'%s\'", currmap);
	SQL_LockDatabase(test_db_sqlite);
	new Handle:result = SQL_Query(test_db_sqlite, query);

	if (result == INVALID_HANDLE)
	{
		SQL_GetError(test_db_sqlite, error, sizeof(error));
		if (client > 0)
			PrintToConsole(client, "Error: %s", error);
		map_id = -1;
	}
	else if (SQL_FetchRow(result))
	{
		map_id = SQL_FetchInt(result, 0);
	}
	else
	{
		map_id = -1;
	}
	SQL_UnlockDatabase(test_db_sqlite);

	return map_id;
}

//--------------------------------------------------
// CreateRecord
//!
//! \brief    Creates an entry in the records table for the current game
//--------------------------------------------------
CreateRecord(client)
{
	decl String:query[1024];

	Format(query, sizeof(query), "INSERT INTO record (duration, mapID) VALUES (%d, %d); SELECT last_insert_rowid()", (end_tick - start_tick), map_id);
	SQL_TQuery(test_db_sqlite, PostQueryCreateRecord, query, client);
}

//--------------------------------------------------
// PostQueryCreateRecord
//!
//! \brief Records the resulting record id after the insertion operator
//--------------------------------------------------
public PostQueryCreateRecord(Handle:owner, Handle:result, const String:error[], any:data)
{
	new client = data;

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, "Error with query: %s", error);
	}
	else if (SQL_GetRowCount(result) > 0)
	{
		record_id = SQL_FetchInt(result, 0);

		if (client > 0)
			PrintToConsole(client, "Inserted new record %d", record_id);
	}
	else
	{
		decl String:query[1024];
		Format(query, sizeof(query), "SELECT last_insert_rowid()", (end_tick - start_tick), map_id);
		SQL_TQuery(test_db_sqlite, PostQueryCreateRecord, query, client);
	}
}

//--------------------------------------------------
// ResetTimeVars
//!
//! \brief Resets the variables that are related to tracking the time
//--------------------------------------------------
ResetTimeVars()
{
	start_tick = GetSysTickCount();
	end_tick = start_tick;
}

//--------------------------------------------------
// AddOfficialWeapons
//!
//! \brief Adds the official weapons into the weapons table
//! \param[in] client The client index of the client to output results to. Use -1 to suppress output.
//--------------------------------------------------
AddOfficialWeapons(client)
{
	decl String:query[1024];
	for (new i = 0; i < NUM_WEAPONS; i++)
	{
		if (client > 0)
		{
			PrintToConsole(client, "Inserting weapon %s...", WEAPON_NAMES[i]);
		}

		Format(query, sizeof(query), "INSERT INTO weapon (name) VALUES (\'%s\')", WEAPON_NAMES[i]);
		SQL_TQuery(test_db_sqlite, PostQueryDoNothing, query);
	}
}

//--------------------------------------------------
// AddWeapon
//!
//! \brief Adds the provided weapon into the weapons table
//! \param[in] client the client index of the player who invoked the function
//! \param[in] weapon the name of the weapon (null-terminated string)
//! \param[in] length length of weapon string
//--------------------------------------------------
AddWeapon(client, String:weapon[])
{
	decl String:query[500];
	PrintToConsole(client, "Adding weapon %s...", weapon);
	Format(query, sizeof(query), "INSERT INTO weapon (name) VALUES (\'%s\')", weapon);

	SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, client);
}

//--------------------------------------------------
// AddOfficialMaps
//!
//! \brief Adds the official maps into the maps table
//! \details Uses the global string arrays OFFICIAL_MAPS_2 and CAMPAIGNS to fill in information for the official maps.
//--------------------------------------------------
AddOfficialMaps(client)
{
	decl String:query[500];

	for (new i = 0; i < NUM_OFFICIAL_MAPS_2; i++)
	{
		// create the SQL insert command to insert the official maps
		Format(query, sizeof(query), "INSERT INTO maps (mapName, campaignName, game) VALUES (\'%s\', \'%s\', 2)", OFFICIAL_MAPS_2[i], CAMPAIGNS_2[i]);
		if (client > 0)
			PrintToConsole(client, "Adding Official Map %s...", OFFICIAL_MAPS_2[i]);
		SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, client);
	}
}

//--------------------------------------------------
// GetPlayerString
//!
//! \brief Gets the names of the (four) participating players and concatenates their names into a single string
//!
//! \param[out] buf      The string buffer to write to
//! \param[in] length    the length of the string buffer
//!
//! \author guyguy
//--------------------------------------------------
GetPlayerString(String:buf[], length)
{
	decl String:tmp[256];
	new numplayers = 0;

	Format(buf, length, "");

	//Calculate who is on what team
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i))
			{
				// add comma to separate the player names
				if (numplayers > 0)
				{
					Format(tmp, sizeof(tmp), ", ");
					StrCat(buf, length, tmp);
				}

				// get the player name and add it
				GetClientName(i, tmp, sizeof(tmp));
				StrCat(buf, length, tmp);
				numplayers++;
			}
		}
	} // end for
} // end PlayerString

//--------------------------------------------------
// AddConnectedPlayers
//!
//! \brief Adds the connected players that are on the survivor team (or infected team for versus) to the players tables
//! \returns The number of players added
//--------------------------------------------------
AddConnectedPlayers()
{
	new numplayers = 0;

	//Calculate who is on what team
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientSurvivor(i) || IsClientInfected(i))
		{
			new team = GetClientTeam(i);
			new playerID = GetPlayerIDOfClient(i);

			//if (team == TEAM_SURVIVOR && !IsFakeClient(i))
			if (IsValidPlayerID(playerID) && IsPlayerActive(playerID))
			{
				AddNewClient(i);
				numplayers++;
			}
		}
	} // end for

	return numplayers;
} // end AddConnectedPlayers

//--------------------------------------------------
// AddNewClient
//!
//! \brief Given a clientid, checks to see if a client already exists in the Players table and if not, adds the client.
//! \details Designed to work with the OnClientConnect command. For now, different player aliases are not considered.
//!
//! \param[in] client the client index
//!
//! \author guyguy
//--------------------------------------------------
AddNewClient(client)
{
	decl String:steamid[64];
	decl String:ip[64];
	decl String:country[64];
	decl String:name[64];
	decl String:query[500];

	// ensure that the client index is valid and the client is actually connected
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
		return;

	// get the steamid, which is used to identify players
	if (!GetClientAuthString(client, steamid, sizeof(steamid)))
		return;

	// get the player name
	if (!GetClientName(client, name, sizeof(name)))
		return;

	// get the ip address so the country can be determined
	if (!GetClientIP(client, ip, sizeof(ip)))
		Format(ip, sizeof(ip), "");

	// get the country
	if (!GeoipCountry(ip, country, sizeof(country)))
		Format(country, sizeof(country), "");

	new Handle:datapack = CreateDataPack();

	WritePackCell(datapack, 0);
	WritePackCell(datapack, client);
	WritePackString(datapack, steamid);
	WritePackString(datapack, name);
	WritePackString(datapack, ip);
	WritePackString(datapack, country);

	// first check to see if there are any existing values
	Format(query, sizeof(query), "SELECT * FROM player WHERE steamID == '%s' AND name == '%s'");
	SQL_TQuery(test_db_sqlite, PostQueryAddNewClient, query, datapack);
}

public PostQueryAddNewClient(Handle:owner, Handle:result, const String:error[], any:data)
{
	new step;
	new client;
	decl String:steamid[64];
	decl String:ip[64];
	decl String:country[64];
	decl String:name[64];
	decl String:query[500];

	new Handle:datapack = data;
	ResetPack(datapack);
	step = ReadPackCell(datapack);
	client = ReadPackCell(datapack);
	ReadPackString(datapack, steamid, sizeof(steamid));
	ReadPackString(datapack, name, sizeof(name));
	ReadPackString(datapack, ip, sizeof(ip));
	ReadPackString(datapack, country, sizeof(country));
	CloseHandle(datapack);

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, "PostQueryAddModelTypes: %s", error);

		PrintToServer("QueryError: %s", error);
		CloseHandle(datapack);
		return;
	}

	switch (step)
	{
		case 0:
		{
			if (SQL_GetRowCount(result) == 0)
			{
				new Handle:datapack = CreateDataPack();

				WritePackCell(datapack, 1);
				WritePackCell(datapack, client);
				WritePackString(datapack, steamid);
				WritePackString(datapack, name);
				WritePackString(datapack, ip);
				WritePackString(datapack, country);

				// create a query string for inserting the data into the table
				Format(query, sizeof(query), "INSERT INTO player (steamID, name, country) VALUES (\'%s\', \'%s\', \'%s\')", steamid, name, country);
				SQL_TQuery(test_db_sqlite, PostQueryAddNewClient, query, datapack);
			}
		}

		case 1:
		{
			SQL_LockDatabase(test_db_sqlite);
			Format(query, sizeof(query), "SELECT last_insert_rowid()");
			new Handle:result2 = SQL_Query(test_db_sqlite, query);
			if (SQL_FetchRow(result2))
			{
				if (client > 0)
					g_playerID[GetPlayerIDOfClient(client)] = SQL_FetchInt(result2, 0);
			}
			CloseHandle(result2);
			SQL_UnlockDatabase(test_db_sqlite);
		}
	}
}

//--------------------------------------------------
// AddTeam
//!
//! \brief Adds the current team consisting of the (up to 4) players to the team table
//--------------------------------------------------
AddTeam(client)
{
	decl String:steamid[64];
	decl String:name[64];
	decl String:query[128];

	// first obtain the players and their steam ids
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i))
			{
				// get the steamid
				GetClientAuthString(i, steamid, sizeof(steamid));

				// get the player name
				GetClientName(i, name, sizeof(name));

				// TODO: get the birth and death times

				// check if the record id is valid
				if (record_id == -1)
				{
					if (client > 0)
					{
						PrintToConsole(client, "Error adding the team: the record_id is invalid. No current record exists.");
					}
					PrintToServer("AddTeam() error adding the team: the record_id is invalid. No current record exists.");
					return;
				}

				Format(query, sizeof(query), "INSERT INTO team (steamID, recordID, teamType) VALUES (\'%s\', %d, %d)", steamid, record_id, TEAM_SURVIVOR);
				if (client > 0)
					PrintToConsole(client, "Adding the player %s", steamid);

				SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, client);
			}
		}
	}
}

//--------------------------------------------------
// AddModelTypes
//--------------------------------------------------
AddModelTypes(client)
{
	decl String:query[1024];

	for (new i = 0; i < NUM_MODEL_TYPES; i++)
	{
		Format(query, sizeof(query), "INSERT INTO modelTypes (modelName) VALUES (\'%s\')", MODEL_TYPES[i]);
		new Handle:datapack = CreateDataPack();
		WritePackCell(datapack, client);
		WritePackCell(datapack, i);
		SQL_TQuery(test_db_sqlite, PostQueryAddModelTypes, query, datapack);
	}
}

//--------------------------------------------------
// PostQueryAddModelTypes
//--------------------------------------------------
public PostQueryAddModelTypes(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:query[1024];
	new Handle:datapack = data;
	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	new i = ReadPackCell(datapack);

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, "PostQueryAddModelTypes: %s", error);

		PrintToServer("QueryError: %s", error);
		CloseHandle(datapack);
	}

	else if (SQL_GetRowCount(result) == 0)
	{
		Format(query, sizeof(query), "SELECT modelID, modelName FROM modelTypes WHERE modelName == '%s'", MODEL_TYPES[i]);
		SQL_TQuery(test_db_sqlite, PostQueryAddModelTypes, query, datapack);
	}
	else
	{
		MODEL_TYPE_INDICES[i] = SQL_FetchInt(result, 0);
		CloseHandle(datapack);
	}
}

//--------------------------------------------------
// AddGameClientSurvivors
//!
//! \brief Adds the current players into the gameclient table
//! \param[in]  client     The client id to report to. -1 for none.
//! \param[in]  birth_time The bith_time to set.
//--------------------------------------------------
AddGameClientSurvivors(client, birth_time)
{
	decl String:steamid[64];
	decl String:name[64];
	decl String:query[128];

	// first obtain the players and their steam ids
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i))
			{
				// get the steamid
				GetClientAuthString(i, steamid, sizeof(steamid));

				// get the player name
				GetClientName(i, name, sizeof(name));

				// use the survival round start time as the birth time

				// check if the record id is valid
				if (record_id == -1)
				{
					if (client > 0)
					{
						PrintToConsole(client, "Error adding the team: the record_id is invalid. No current record exists.");
					}
					return;
				}

				// ensure that the player is being tracked and he is an active player
				new playerID = GetPlayerIDOfClient(i);
				if (playerID == -1)
				{
					return;
				}
				if (IsValidPlayerID(playerID) && IsPlayerActive(playerID))
				{
					// save the player's entity id
					g_gameClientID[playerID] = AddGameClient(-1, steamid, 0, birth_time, -1);
				}
			}
		}
	}
}

//--------------------------------------------------
// AddGameClient
//!
//! \brief Adds a new game client into the database
//! \details The record used is the current record.
//!
//! \param[in] client          Results are reported back to this client. Use -1 for no reports.
//! \param[in] steamid         The steamid to add (use BOT for a bot)
//! \param[in] model_id        The modelid to add (use 0 for survivor)
//! \param[in] birth_time      The birth time to add
//! \param[in] death_time      The death time to add
//!
//! \returns The resulting game client id
//--------------------------------------------------
AddGameClient(client, String:steamid[], model_id, birth_time, death_time)
{
	decl String:error[256];
	decl String:query[1024];
	new game_client_id = -1;
	Format(query, sizeof(query), "INSERT INTO gameClient (modelID, steamID, birthTime, deathTime) VALUES (%d, \'%s\', %d, %d)", model_id, steamid, birth_time, death_time);
	//if (client > 0) PrintToConsole(client, query);

	SQL_LockDatabase(test_db_sqlite);
	new Handle:result = SQL_Query(test_db_sqlite, query);
	if (result == INVALID_HANDLE)
	{
		SQL_GetError(test_db_sqlite, error, sizeof(error));
		if (client > 0)
			PrintToConsole(client, "Error AddGameClient: %s", error);
	}
	else
	{
		Format(query, sizeof(query), "SELECT last_insert_rowid()");
		new Handle:result = SQL_Query(test_db_sqlite, query);
		if (SQL_FetchRow(result))
		{
			// TODO: this needs error checking
			g_playerID[GetPlayerIDBySteamID(steamid)] = SQL_FetchInt(result, 0);
		}
		CloseHandle(result);
	}
	SQL_UnlockDatabase(test_db_sqlite);

	return game_client_id;
}

//--------------------------------------------------
// AddKill
//!
//! \brief Adds an entry into the damage table with the given values. It is recorded as a kill.
//--------------------------------------------------
AddKill(record_id, attacker_id, victim_id, time, damage, weapon_id, hitgroup, x, y, z)
{
	decl String:error[256];
	decl String:query[1024];

	Format(query, sizeof(query), "INSERT INTO damage (eventTimestamp, recordID, damageAmount, hitgroup, weaponID, kill, aPositionX, aPositionY, aPositionZ) VALUES (%d, %d, %d, %d, %d, 1, %f, %f, %f)", time, record_id, damage, hitgroup, weapon_id, x, y, z);
	SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
}

//--------------------------------------------------
// AddDamage
//!
//! \brief Adds an entry into the damage table with the given values
//--------------------------------------------------
AddDamage(record_id, attacker_id, victim_id, time, damage, weapon_id, hitgroup, x, y, z)
{
	decl String:error[256];
	decl String:query[1024];

	Format(query, sizeof(query), "INSERT INTO damage (eventTimestamp, recordID, damageAmount, hitgroup, weaponID, kill, aPositionX, aPositionY, aPositionZ) VALUES (%d, %d, %d, %d, %d, %f, %f, %f)", time, record_id, damage, hitgroup, weapon_id, 0, x, y, z);
	SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, -1);
}

//--------------------------------------------------
// QueryWeapons
//!
//! \brief Queries the database for the weapons in the weapon table
//--------------------------------------------------
QueryWeapons(client)
{
	PrintToConsole(client, "Outputting Weapons Table...");
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT weaponID, name FROM weapon ORDER BY weaponID");
	SQL_TQuery(test_db_sqlite, PostQueryPlayers, query, client);
}

//--------------------------------------------------
// PostQueryWeapons
//!
//! \brief This is the callback used to handle the query from the QueryWeapons function. It will create a string of all the weapons in the database.
//--------------------------------------------------
public PostQueryWeapons(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:buf[256];
	decl String:weaponid[64];
	decl String:name[64];
	new client = data;

	if (result == INVALID_HANDLE)
	{
		PrintToConsole(client, error);
		return;
	}

	new length = SQL_GetRowCount(result);

	new Handle:dataPackHandle = CreateDataPack();

	while (SQL_FetchRow(result))
	{
		SQL_FetchString(result, 0, weaponid, sizeof(weaponid));
		SQL_FetchString(result, 1, name, sizeof(name));
		Format(buf, sizeof(buf), "%s %s", weaponid, name);
		WritePackString(dataPackHandle, buf);
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryForPlayer
//!
//! \brief     Queries the database for a specific player.
//! \param[in] cid     The client id of the player to query
//! \returns           True if the player exists within the database, false otherwise
//--------------------------------------------------
QueryForPlayer(cid)
{
	decl String:steamid[32];
	decl String:query[500];
	bool player_exists = false;

	// get the steamd for the player
	if (GetClientAuthString(cid, steamid, sizeof(steamid)) == false)
		return false;

	// query the database for a player matching
	Format(query, sizeof(query), "SELECT steamID FROM player WHERE steamID == '%s'", steamid);

	LockDatabase(test_db_sqlite);

	Handle:result = SQL_Query(test_db_sqlite, query);

	if (result == INVALID_HANDLE)
	{
		new String error[255];
		SQL_GetError(test_db_sqlite, error, sizeof(error));
		PrintToServer("QueryForPlayer failed query: %s", error);
	}
	else
	{
		// if there is at least one result, true
		if (SQL_GetRowCount(test_db_sqlite) > 0)
		{
			player_exists = true;
		}
		CloseHandle(result);
	}

	UnlockDatabase(test_db_sqlite);

	return player_exists;
}

//--------------------------------------------------
// QueryPlayers
//!
//! \brief Queries the database for the players in the players table
//--------------------------------------------------
QueryPlayers(client)
{
	PrintToConsole(client, "Outputting Players Table...");
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT steamID, name FROM player ORDER BY steamID");
	SQL_TQuery(test_db_sqlite, PostQueryPlayers, query, client);
}

//--------------------------------------------------
// PostQueryPlayers
//!
//! \brief This is the callback used to handle the query from the QueryPlayers function. It will create a string of all the players in the database.
//--------------------------------------------------
public PostQueryPlayers(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:buf[256];
	decl String:steamid[64];
	decl String:name[64];
	new client = data;

	if (result == INVALID_HANDLE)
	{
		PrintToConsole(client, error);
		return;
	}

	new length = SQL_GetRowCount(result);

	PrintToConsole(client, "%d results", length);

	new Handle:dataPackHandle = CreateDataPack();

	while (SQL_FetchRow(result))
	{
		SQL_FetchString(result, 0, steamid, sizeof(steamid));
		SQL_FetchString(result, 1, name, sizeof(name));
		Format(buf, sizeof(buf), "%s %s", steamid, name);
		WritePackString(dataPackHandle, buf);
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryMaps
//!
//! \brief Queries the database for the maps in the maps table
//--------------------------------------------------
QueryMaps(client)
{
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT mapName, campaignName FROM maps ORDER BY mapName");
	SQL_TQuery(test_db_sqlite, PostQueryMaps, query, client);
}

//--------------------------------------------------
// PostQueryMaps
//!
//! \brief This is the callback used to handle the query from the QueryPlayers function. It will create a string of all the players in the database.
//--------------------------------------------------
public PostQueryMaps(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:buf[256];
	decl String:mapName[64];
	decl String:campaignName[64];

	new length = 0;
	new client = data;

	new Handle:dataPackHandle = CreateDataPack();
	PrintToConsole(client, "%d Results...", SQL_GetRowCount(result));

	while (SQL_FetchRow(result))
	{
		SQL_FetchString(result, 0, mapName, sizeof(mapName));
		SQL_FetchString(result, 1, campaignName, sizeof(campaignName));
		Format(buf, sizeof(buf), "%s %s", mapName, campaignName);
		WritePackString(dataPackHandle, buf);
		length++;
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryRecords
//!
//! \brief Queries the database for the records in the records table
//--------------------------------------------------
QueryRecords(client)
{
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT recordID, duration, mapID FROM record ORDER BY recordID");
	SQL_TQuery(test_db_sqlite, PostQueryRecords, query, client);
}

//--------------------------------------------------
// PostQueryRecords
//!
//! \brief Queries the database for the records in the records table
//--------------------------------------------------
public PostQueryRecords(Handle:owner, Handle:result, const String:error[], any:data)

{
	decl String:buf[256];
	new recordID;
	new duration;
	new mapID;

	new length = 0;
	new client = data;

	new Handle:dataPackHandle = CreateDataPack();
	if (client > 0)
		PrintToConsole(client, "%d Results...", SQL_GetRowCount(result));

	while (SQL_FetchRow(result))
	{
		recordID = SQL_FetchInt(result, 0);
		duration = SQL_FetchInt(result, 1);
		mapID = SQL_FetchInt(result, 2);

		Format(buf, sizeof(buf), "id: %d dur: %d mapid: %d", recordID, duration, mapID);
		WritePackString(dataPackHandle, buf);
		length++;
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryGameClients
//!
//! \brief Queries the GameClient table for entries
//--------------------------------------------------
QueryGameClients(client)
{
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT entryID, modelID, steamID, birthTime, deathTime FROM gameClient ORDER BY entryID");
	SQL_TQuery(test_db_sqlite, PostQueryGameClients, query, client);
}

//--------------------------------------------------
// PostQueryGameClients
//!
//! \brief This is the callback used to handle the query from the QueryGameClients function. It will create a string of all the records in the database.
//--------------------------------------------------
public PostQueryGameClients(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:buf[256];
	new entryID;
	new modelID;
	new String:steamID[64];
	new birthTime;
	new deathTime;

	new length = 0;
	new client = data;

	new Handle:dataPackHandle = CreateDataPack();
	if (client > 0)
		PrintToConsole(client, "%d Results...", SQL_GetRowCount(result));

	while (SQL_FetchRow(result))
	{
		entryID = SQL_FetchInt(result, 0);
		modelID = SQL_FetchInt(result, 1);
		SQL_FetchString(result, 2, steamID, sizeof(steamID));
		birthTime = SQL_FetchInt(result, 3);
		deathTime = SQL_FetchInt(result, 4);

		Format(buf, sizeof(buf), "id: %d modelID: %d steadid: %s birthTime: %d deathTime: %d", entryID, modelID, steamID, birthTime, deathTime);
		WritePackString(dataPackHandle, buf);
		length++;
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryModelTypes
//!
//! \brief Queries the ModelTypes table for entries
//--------------------------------------------------
QueryModelTypes(client)
{
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT modelID, modelName, modelType FROM modelTypes ORDER BY modelID");
	SQL_TQuery(test_db_sqlite, PostQueryModelTypes, query, client);
}

//--------------------------------------------------
// PostQueryModelTypes
//!
//! \brief This callback displays the results of the query
//--------------------------------------------------
public PostQueryModelTypes(Handle:owner, Handle:result, const String:error[], any:data)
{
	decl String:buf[256];
	new modelID;
	new String:modelName[64];
	new modelType;

	new length = 0;
	new client = data;

	new Handle:dataPackHandle = CreateDataPack();
	if (client > 0)
		PrintToConsole(client, "%d Results...", SQL_GetRowCount(result));

	while (SQL_FetchRow(result))
	{
		modelID = SQL_FetchInt(result, 0);
		SQL_FetchString(result, 1, modelName, sizeof(modelName));
		modelType = SQL_FetchInt(result, 2);

		Format(buf, sizeof(buf), "id: %d modelName: %s modelType: %d", modelID, modelName, modelType);
		WritePackString(dataPackHandle, buf);
		length++;
	}

	// call output to console function
	OutputDataPackStrings(client, dataPackHandle, length);

	CloseHandle(dataPackHandle);
}

//--------------------------------------------------
// QueryTeamTable
//!
//! \brief Used to query the team table for entries. It will output the entries to the client's console.
//--------------------------------------------------
QueryTeamTable(client)
{
	decl String:query[500];

	// create a query string for querying the data
	Format(query, sizeof(query), "SELECT teamID, recordID, teamType, birthTime, deathTime FROM team ORDER BY recordID, teamID");
	SQL_TQuery(test_db_sqlite, PostQueryTeamTable, query, client);
}

public PostQueryTeamTable(Handle:owner, Handle:result, const String:error[], any:data)
{
	new client = data;

	decl String:buf[512];
	new teamID;
	new recordID;
	new teamType;
	new birthTime;
	new deathTime;

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, "error %s", error);
		return;
	}

	while (SQL_FetchRow(result))
	{
		teamID    = SQL_FetchInt(result, 0);
		recordID  = SQL_FetchInt(result, 1);
		teamType  = SQL_FetchInt(result, 2);
		birthTime = SQL_FetchInt(result, 3);
		deathTime = SQL_FetchInt(result, 4);

		Format(buf, sizeof(buf), "teamID: %d recordID: %d teamType: %d birthTime: %d deathTime: %d", teamID, recordID, teamType, birthTime, deathTime);
		if (client > 0)
			PrintToConsole(client, buf);
	}
}

//--------------------------------------------------
// CountKills
//
//! \brief Counts the kills for the different clients and reports it.
//! \details This is a debug function to test the functionality of the database. Compare this with regular kill stats.
//! \param[in] client  The client to report results to
//--------------------------------------------------
CountKills(client)
{
	decl String:query[600];
	// make sure the record_id is valid
	if (record_id <= 0)
		return;

	// count the kills for each individual (active) player
	// TODO: right now, only survivors are supported
	for (new i = 0; i < S3_MAXPLAYERS; i++)
	{
		new id = GetClientOfPlayerID(i);
		if (IsClientAlive(id) && IsValidPlayerID(i))
		{
			new Handle:datapack = CreateDataPack();
			WritePackCell(datapack, client);
			WritePackCell(datapack, i);

			// find all the damage entries that are kills
			Format(query, sizeof(query), "SELECT * FROM damage WHERE recordID == %d AND kill == 1 AND attacker == %d", record_id, g_playerID[i]);
			SQL_TQuery(test_db_sqlite, PostQueryCountKills, query, datapack);
		}
	}
}

//--------------------------------------------------
// PostQueryCountKills
//--------------------------------------------------
public PostQueryCountKills(Handle:owner, Handle:result, const String:error[], any:data)
{
	new Handle:datapack = data;

	ResetPack(datapack);
	new client = ReadPackCell(datapack);
	new i = ReadPackCell(datapack);

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, "PostQueryCountKills error: %s", error);
		PrintToServer("PostQueryCountKills error: %s", error);
		CloseHandle(datapack);
		return;
	}

	new count = SQL_GetRowCount(result);
	if (client > 0)
	{
		PrintToChat(client, "Player %s (%d) has %d kills", g_playerName[i], i, count);
	}

	CloseHandle(datapack);
}

//--------------------------------------------------
// OutputDataPackStrings
//!
//! \brief Outputs the strings contained within a datapack to console.
//!
//! \param[in] client          The client index to send to
//! \param[in] dataPackHandle  The handle to an existing datapack that consists of only strings.
//! \param[in] length          The number of strings contained within the datapack.
//--------------------------------------------------
OutputDataPackStrings(client, Handle:dataPackHandle, length)
{
	new i;
	decl String:buf[250];

	if (client <= 0)
		return;

	ResetPack(dataPackHandle);

	for (i = 0; i < length; i++)
	{
		ReadPackString(dataPackHandle, buf, sizeof(buf));
		PrintToConsole(client, buf);
	}
}

//--------------------------------------------------
// PostQueryPrintErrors
//!
//! \brief Callback that prints out any errors that occur
//!
//! \param[in] data the client index
//--------------------------------------------------
public PostQueryPrintErrors(Handle:owner, Handle:result, const String:error[], any:data)
{
	new client = data;

	if (result == INVALID_HANDLE)
	{
		if (client > 0)
			PrintToConsole(client, error);

		PrintToServer("QueryError: %s", error);
	}
}

//--------------------------------------------------
// PostQueryDoNothing
//!
//! \brief Callback required for SQL queries, which does nothing
//--------------------------------------------------
public PostQueryDoNothing(Handle:owner, Handle:result, const String:error[], any:data)
{
	//
}
