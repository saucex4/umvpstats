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
new bool:survivor[MAXPLAYERS];    // active survivors
new String:survivorName[MAXPLAYERS][33];
new String:survivorSteamID[MAXPLAYERS][20];  // stores active survivors steam ID
new survivorKills[MAXPLAYERS][8]; // stores the kills for each survivor for each SI type
new survivorDmg[MAXPLAYERS][8];   // stores the dmg for each survivor for each SI type
new survivorHeadShots[MAXPLAYERS]; // headshot counter
new survivorFFDmg[MAXPLAYERS];     // friendly fire counter

// global variables that track SI data
new SIHealth[MAXPLAYERS];         // tracks SI + Tank health
new bool:SIClients[MAXPLAYERS];   // current clients that are SI
new survivorDmgToTank[MAXPLAYERS][MAXPLAYERS]; // tracks individual dmg to tank by survivor for multiple tank support

// global variables that track CI data
new CIHealth[MAXENTITIES];        // Tracks health of every common infected. This is inefficient memory usage since not all entities (array elements) are common infected.

// global variables that store data of players that are no longer playing
new storedSurvivorKills[50][8];
new storedSurvivorDmg[50][8];
new storedSurvivorHeadShots[50];
new storedSurvivorFFDmg[50];
new String:storedSurvivorSteamID[50][20];
new String:storedSurvivorName[50][33];
new storedSurvivorDmgToTank[50][MAXPLAYERS];
new bool:storedSurvivor[50];

// global variables that deal with current game state
new roundEnded = false;
new collectStats = false;
new loadLate     = false;

// cvar handles

new Handle:g_roundTrackerState = INVALID_HANDLE;

/* [5.000]***************GENERAL CALLBACK FUNCTIONS*************** */
public OnPluginStart() {
	
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

	RegAdminCmd("sm_printclients", Command_PrintClients, ADMFLAG_GENERIC); // Prints all clients w/ client index and name
	RegAdminCmd("sm_printbyname", Command_PrintClientByName, ADMFLAG_GENERIC); // Print a client by name
	RegAdminCmd("sm_printclientbyindex", Command_PrintClientByIndex, ADMFLAG_GENERIC); // Print a client by client index
	RegAdminCmd("sm_printsurvivor", Command_PrintSurvivor, ADMFLAG_GENERIC);
	RegAdminCmd("sm_statson", Command_StatsOn, ADMFLAG_GENERIC);
	RegAdminCmd("sm_statsoff", Command_StatsOff, ADMFLAG_GENERIC);
	
	// Console/User commands - these are usable by all users
	RegConsoleCmd("sm_stats", Command_Stats); // accepted args "!stats <name>, !stats all, !stats mvp, !stats 
	
	
	// cvar processing
	g_roundTrackerState = FindConVar("g_roundTrackerState");
	
	// check if plugin was loaded late
	if (loadLate) {
		for (new i = 0 ; i < MaxClients; i++) {
			if (IsClientSurvivor(i)) { // collect stats for the survivors
				StartStatsForClient(i);
			}
		}
		new String:roundState[30];
		GetConVarString(g_roundTrackerState,roundState, sizeof(roundState));
		
		if (StrEqual(ROUND_STATES[10],roundState,false) ||
		    StrEqual(ROUND_STATES[9],roundState,false) ||
			StrEqual(ROUND_STATES[7],roundState,false) ||
			StrEqual(ROUND_STATES[6],roundState,false)) { // if the game is running make sure stats can be collected
			collectStats = true;
		}
	}
	
}

public OnMapStart() {
	collectStats = false;
}

// This function is called before OnPluginStart. This is to check for late load

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	loadLate = late;
	return APLRes_Success;
}


/* [6.000]***************ADMIN COMMAND FUNCTIONS*************** */
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

public Action:Command_PrintSurvivor(client, args) {
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientAlive(i) && survivor[i]) {
			PrintToChatAll("[%d] %N",i,i);
		}
	}
	return Plugin_Handled;
}

public Action:Command_StatsOn(client, args) {
	collectStats = true;
	return Plugin_Handled;
}

public Action:Command_StatsOff(client, args) {
	collectStats = false;
	return Plugin_Handled;
}

//--------------------------------------------------
// ResetStats
//!
//! \brief Use this function to reset the kill and damage arrays to zero
//--------------------------------------------------
public Action:Command_ResetStats(client, args) {
	for (new i = 0; i < MaxClients; i++) {
		for (new j = 0; j < 8; j++) {
			survivorKills[i][j] = 0; // zero out all survivor kills of every type
			survivorDmg[i][j] = 0; // zero out all survivor damage of every type
			survivorDmgToTank[i][j] = 0; // zero out all survivor tank damage for all tanks
		}
		survivorHeadShots[i] = 0; // zero out headshot count
		survivorFFDmg[i] = 0;     // zero out friendly fire damage
		SIClients[i] = false;     // zero out all tracked SI
		SIHealth[i]  = 0;         // zero out all tracked SI health
	}
	ResetCIHealth();
	if (IsClientHuman(client)) {
		PrintToChat(client,"\x01Stats have been \x04RESET");
	}
	return Plugin_Handled;
}

/* [7.000]***************CONSOLE COMMAND FUNCTIONS*************** */
public Action:Command_Stats(client, args) {

	new String:arg1[33], String:arg2[33];
	new clientToPrint;
	
	// initialize survivors for stats collect if necessary
	for (new i = 0; i < MaxClients; i++) {
		if (IsClientSurvivor(i) && !survivor[i]) {
			survivor[i] = true;
		}
	}
	
	if (IsClientHuman(client)) { // Process this if the client is a human
		if (args == 1) {
			
			GetCmdArg(1, arg1, sizeof(arg1));
			if (StrEqual(arg1,"all")) {
				PrintStats(client, 0,false); // print all summarized stats
			}
			else if (StrEqual(arg1, "mvp")) {
				PrintStats(client, 10000, false); // print mvp stats summarized
			}
			else if (StrEqual(arg1, "detail", false)){
				PrintStats(client, client, true); // print personal stats with detail
			}
			else if (StrEqual(arg1, "round", false)) {
				PrintStats(client, 20000, false); // print round stats w/ no detail
			}
			else if (StrEqual(arg1, "weapon", false)) {
				PrintStats(client, 30000, false); // prints
			}
			else { // prints a specific player's stats summarized
				// check to see if name matches to a client
				clientToPrint = GetSurvivorByName(arg1);
				if(clientToPrint != -1) {
					PrintStats(client, clientToPrint, false);
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
					PrintStats(client, 0,true); // print all stats with detail
				}
				else if (StrEqual(arg1, "mvp")) {
					PrintStats(client, 10000, true); // print mvp stats with detail
				}
				else if (StrEqual(arg1, "round")) {
					PrintStats(client, 20000, true); // print detailed round stats
				}
				else if (StrEqual(arg1, "weapon")) {
					PrintStats(client, 30000, true); // print detailed weapon stats
				}
				else { // print a specific player's stats with detail
					clientToPrint = GetSurvivorByName(arg1);
					if(clientToPrint != -1) {
						PrintStats(client, clientToPrint, true);
					}
					else {
						PrintToChat(client,"%s not found", arg1);
					}
				}
			}
		}
		else if (args == 0) {
			PrintStats(client,client,false); // print personal stats summarized
		}
	}
	return Plugin_Handled;
}


/* [8.000]***************EVENT CALLBACK FUNCTIONS*************** */


// Infected Events
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//other info
	new hitgroup = GetEventInt(event, "hitgroup");
	new damage   = GetEventInt(event, "dmg_health");

	//victim info
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new victimRemainingHealth = GetEventInt(event, "health");
	new String:victimName[40];
	GetClientModel(victim, victimName, sizeof(victimName));
	new victimTeam = GetClientTeam(victim);
	
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	// new attackerSteamID[20];
	// new attackerName[33];
	
	// GetClientAuthString(attacker,attackerSteamID,sizeof(attackerSteamID));
	// GetClientName(attacker,attackerName,sizeof(attackerName));
	/*
	Conditions for collection
			1) Don't collect damage by SI
			2) Don't collect damage by Console/World
			3) Collect damage from bot survivors and player survivors
	*/
	
	if (IsClientSurvivor(attacker) && collectStats) { // check if the attacker is Console/World if not then move forward

#if DEBUG
		PrintToChatAll("a = %d, dmg = %d, vic = %d, hg = %d",attacker, damage,victim, hitgroup);
#endif
		if (!IsCollectingStats(attacker)) {
			StartStatsForClient(attacker);
		}
		
		// record headshot
		if ((hitgroup == 1) && (victimTeam != TEAM_SURVIVOR)) {
			survivorHeadShots[attacker]++;
		}
		
		// record friendly fire
		if (victimTeam == TEAM_SURVIVOR) { //record friendly fire
			survivorFFDmg[attacker] += damage;
		}
		
		if((damage > 0) && (victimTeam == TEAM_INFECTED)) { //record damage
			if (StrContains(victimName, "Hunter", false) != -1) {
				if (victimRemainingHealth == 0) { //kill shot
					survivorDmg[attacker][HUNTER] += SIHealth[victim];
					survivorKills[attacker][HUNTER]++;
				}
				else {
					survivorDmg[attacker][HUNTER] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Jockey", false) != -1) {
				if (victimRemainingHealth == 0) {
					survivorDmg[attacker][JOCKEY] += SIHealth[victim];
					survivorKills[attacker][JOCKEY]++;
				}
				else {
					survivorDmg[attacker][JOCKEY] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Charger", false) != -1) {
				if (victimRemainingHealth == 0) { //kill shot
					survivorDmg[attacker][CHARGER] += SIHealth[victim];
					survivorKills[attacker][CHARGER]++;
				}
				else {
					survivorDmg[attacker][CHARGER] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Spitter", false) != -1) {
				if (victimRemainingHealth == 0) { //kill shot
					survivorDmg[attacker][SPITTER] += SIHealth[victim];
					survivorKills[attacker][SPITTER]++;
				}
				else {
					survivorDmg[attacker][SPITTER] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Boomer", false) != -1) {
				if (victimRemainingHealth == 0) { //kill shot
					survivorDmg[attacker][BOOMER] += SIHealth[victim];
					survivorKills[attacker][BOOMER]++;
				}
				else {
					survivorDmg[attacker][BOOMER] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Smoker", false) != -1) {
				if (victimRemainingHealth == 0) { //kill shot
					survivorDmg[attacker][SMOKER] += SIHealth[victim];
					survivorKills[attacker][SMOKER]++;
				}
				else {
					survivorDmg[attacker][SMOKER] += damage;
					SIHealth[victim] -= damage;
				}
			}
			else if (StrContains(victimName, "Hulk", false) != -1) {
				//deal with multiple tanks here
				if (SIClients[victim]) { //if this tank is alive record
					// if ((SIHealth[victim] <= 0) || (victimRemainingHealth > SIHealth[victim])) {
					
					// if (damage >= SIHealth[victim]) {
					if (IsTankIncapacitated(victim)) {
#if DEBUG
						PrintToChatAll("%N %d/%d",victim, victimRemainingHealth, (GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff));
#endif	
						survivorDmgToTank[attacker][victim] += SIHealth[victim];
						survivorDmg[attacker][TANK] += SIHealth[victim];
						SIClients[victim] = false;
						SIHealth[victim] = 0;
						PrintTankStats(victim);
						for (new x = 0; x < MAXPLAYERS; x++) {
							survivorDmgToTank[x][victim] = 0;
						}
						survivorKills[attacker][TANK]++;
					}
					else { // if (SIClients[victim]) {
#if DEBUG
						PrintToChatAll("%N %d/%d",victim, victimRemainingHealth, (GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff));
#endif
						SIHealth[victim] -= damage;
						survivorDmg[attacker][TANK] += damage;
						survivorDmgToTank[attacker][victim] += damage; //Do we count the damage that exceeds the tank's health?
					}
				}
			}
		}
		
		//reset SI Tracking variables on kill
		if(victimRemainingHealth == 0) {
			SIClients[victim] = false;
			SIHealth[victim] = 0;
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

	// retrieve the damage and hitgroup
	new damage = GetEventInt(event, "amount");
	new original_damage = damage;
	new hitgroup = GetEventInt(event, "hitgroup");
	new type = GetEventInt(event, "type");
	new realdamage;
	new model_id;
	decl String:weapon[64];
	
	if (IsClientSurvivor(attacker) && collectStats) {
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

		//Only process if the player is a legal attacker (i.e., a player)
		
		if (!IsCollectingStats(attacker)) {
			StartStatsForClient(attacker);
		}
		
		survivorDmg[attacker][COMMON] += realdamage;

		// check for a headshot
		if (hitgroup == 1) {
			survivorHeadShots[attacker]++;
		}

#if INFECTED_HURT_DEBUG
		//debug
		PrintToChatAll("entID: %d CIHealth: %d original_damage: %d damage: %d realdamage: %d hitgroup: %d type: %d modelid: %d", victim, CIHealth[victim], original_damage, damage, realdamage, hitgroup, GetEventInt(event, "type"),model_id);
#endif

	}
}

public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	// Ensure that the infected health is set to zero. This should be the case in almost all situations, however, the survivor zombie has some weird damage properties that causes it to show up having health remaining even though it is dead.
	CIHealth[GetEventInt(event, infected_id)] = 0;
	
	//Only process if the player is a legal attacker (i.e., a player)
	if (IsClientSurvivor(attacker) && collectStats)
	{
		if (!IsCollectingStats(attacker)) {
			StartStatsForClient(attacker);
		}
		survivorKills[attacker][COMMON]++;
	}
}


public Action:Event_PlayerIncapacitated(Handle:event, String:event_name[], bool:dontBroadcast) {
	new victim					= GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInfected(victim) && SIClients[victim]) {
		SIClients[victim] = false;
		SIHealth[victim] = 0;
		for (new z = 0; z < MaxClients; z++) {
			survivorDmgToTank[z][victim] = 0;
		}
	}
}

public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast) {
	new id = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInfected(id)) {
		new String:name[33];
		GetClientModel(id,name,sizeof(name));
		SIClients[id] = true;
		SIHealth[id] = GetEntProp(id, Prop_Send, "m_iMaxHealth") & 0xffff;
		if (StrContains(name, "Hulk", false) != -1) {
			for (new x = 0; x < MAXPLAYERS; x++) {
				survivorDmgToTank[x][id] = 0;
			}
		}
	}
	else if(IsClientSurvivor(id)) {
		StartStatsForClient(id);
		
		new String:playerName[33];
		new String:playerSteamID[20];
		
		GetClientName(id, playerName, sizeof(playerName));
		GetClientAuthString(id, playerSteamID, sizeof(playerSteamID));
		
		RetrieveStats(playerName, playerSteamID, id);
	}
}

// Round Events

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	Command_ResetStats(0,0);
	roundEnded = false;
	collectStats = true;
	
	// initialize survivors for stats collection
	for (new i = 0; i < MaxClients; i++) {
		if(IsClientSurvivor(i)) {
			StartStatsForClient(i);
		}
	}
	
#if DEBUG
	PrintToChatAll("\x01Event_RoundStart \x04FIRED[ResetStats(0,0); roundEnded = false; collectStats = true;]");
#endif
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!roundEnded) {
		PrintStats(0, 10000,false);
		roundEnded = true;
	}
	collectStats = false;
}

// Player state events

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if(IsClientSurvivor(client) && IsCollectingStats(client)) {
		StopStatsForClient(client);
	}
}


public Event_PlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	new bot    = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsClientSurvivor(player) && IsClientBot(bot)) {
		new String:playerName[33];
		new String:playerSteamID[20];
		
		GetClientName(bot, playerName, sizeof(playerName));
		GetClientAuthString(bot, playerSteamID, sizeof(playerSteamID));
		
		StartStatsForClient(bot);
		RetrieveStats(playerName,playerSteamID,player);
		
		StopStatsForClient(player);
		StoreStats(player);
		
	}
}

public Event_BotPlayerReplace(Handle:event, const String:name[], bool:dontBroadcast) {
	new player = GetClientOfUserId(GetEventInt(event, "player"));
	new bot    = GetClientOfUserId(GetEventInt(event, "bot"));
	if (IsClientSurvivor(player) && IsClientBot(bot)) {
		
		new String:playerName[33];
		new String:playerSteamID[20];
		GetClientName(player, playerName, sizeof(playerName));
		GetClientAuthString(player, playerSteamID, sizeof(playerSteamID));
		
		StopStatsForClient(bot);
		StoreStats(bot);
		
		StartStatsForClient(player);
		RetrieveStats(playerName,playerSteamID,player);
	}
}


/* [9.000]***************HELPER FUNCTIONS*************** */

bool:IsTankIncapacitated(client) {
	if (IsIncapacitated(client) || GetClientHealth(client) < 1) return true;
	return false;
}

bool:IsIncapacitated(client) {
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

PrintStats(printToClient, option, bool:detail) {
	// client2 values
	// 100 = print mvp
	//   0 = print all summarized stats
	new totalDamage[8];
	new totalKills[8];
	
	TotalDamage(totalDamage, totalKills);
	new totalSIDamage = totalDamage[HUNTER] + totalDamage[JOCKEY] + totalDamage[CHARGER] + totalDamage[SPITTER] + totalDamage[SMOKER] + totalDamage[BOOMER];
	new totalSIKills = totalKills[HUNTER] + totalKills[JOCKEY] + totalKills[CHARGER] + totalKills[SMOKER] + totalKills[SPITTER] + totalKills[BOOMER];
	switch (option) {
		case 0: {
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
			for (new i = 1; i < MaxClients; i++) {
				// process name
				new String:name[20];
				
				// end process name
				if (IsCollectingStats(i)) {
					GetClientName(i,name, sizeof(name));
					// process SI %
					new SIKills   = survivorKills[i][HUNTER] + survivorKills[i][JOCKEY] + survivorKills[i][CHARGER] + survivorKills[i][SMOKER] + survivorKills[i][SPITTER] + survivorKills[i][BOOMER];
					new Float:percentSI;

					if (totalSIKills == 0) {
						percentSI = 0.0; 
					}
					else {
						percentSI = (float(SIKills)/(float(totalSIKills)))*100.00;
					}
					// end process SI %
					
					// process CI %
					new CIKills   = survivorKills[i][COMMON];
					new Float:percentCI;
					if(totalKills[COMMON] == 0) {
						percentCI = 0.0;
					}
					else {
						percentCI =(float(CIKills)/float(totalKills[COMMON]))* 100.00;
					}
					// end process CI %
					
					// process Tank %
					new TankDmg   = survivorDmg[i][TANK];
					new Float:percentTanks;
					if (totalDamage[TANK] == 0) {
						percentTanks = 0.0;
					}
					else {
						percentTanks = ((float(TankDmg)/float(totalDamage[TANK]))* 100.00);
					}
					
					// end process Tank %
					
					if (printToClient == 0) { // print to everyone
						PrintToChatAll("\x04%s \x05SI: \x01%3.0f%% \x05CI: \x01%3.0f%% \x05Tanks: \x01%3.0f%%",name, percentSI, percentCI, percentTanks);
					}
					else if(printToClient > 0) { // print to specific client
						PrintToChat(printToClient,"\x04%s \x05SI: \x01%3.0f%% \x05CI: \x01%3.0f%% \x05Tanks: \x01%3.0f%%",name, percentSI, percentCI, percentTanks);
					}
					
					// process total SI kills
					
					new clientSIDamage = survivorDmg[i][HUNTER] + survivorDmg[i][JOCKEY] + survivorDmg[i][CHARGER] + survivorDmg[i][SPITTER] + survivorDmg[i][SMOKER] + survivorDmg[i][BOOMER];
					
					if(detail) {
						if (printToClient == 0) {
							PrintToChatAll("\x05SI:\x03%4d \x01(%d) \x05CI:\x03%4d \x01(%7d) \x05T:\x03%4d \x01(%7d)",SIKills, clientSIDamage,
																											  CIKills, survivorDmg[i][COMMON],
																											  survivorKills[i][TANK], survivorDmg[i][TANK]);
						}
						else if (printToClient > 0) {
							PrintToChat(printToClient,"\x05SI:\x03%4d \x01(%d) \x05CI:\x03%4d \x01(%7d) \x05T:\x03%4d \x01(%7d)",SIKills, clientSIDamage,
																											  CIKills, survivorDmg[i][COMMON],
																											  survivorKills[i][TANK], survivorDmg[i][TANK]);
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
																											  totalKills[COMMON], totalDamage[COMMON],
																											  totalKills[TANK], totalDamage[TANK]);
				}
				else {
					PrintToChatAll("\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, totalKills[COMMON], totalKills[TANK]);
				}
			}
			else if(printToClient > 0) {
				PrintToChat(printToClient, "========================================");
				
				if(detail) {
					PrintToChat(printToClient,"\x04SI:\x03%4d \x01kills \x01(%7d) \x04CI:\x03%4d \x01kills \x01(%7d) \x04T:\x03%4d \x01kills \x01(%7d)",totalSIKills, totalSIDamage,
																											  totalKills[COMMON], totalDamage[COMMON],
																											  totalKills[TANK], totalDamage[TANK]);
				}
				else {
					PrintToChat(printToClient,"\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, totalKills[COMMON], totalKills[TANK]);
				}
			}
		}
		case 10000: {
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
			new players = 0;
			new clientTankDamage[MaxClients];
			new clientSIKills[MaxClients];
			new clientCIKills[MaxClients];
			new clientID[MaxClients];
			
			for (new i = 0; i < MaxClients; i++) {
				if (survivor[i]) {
					//clientTankDamage[players] = survivorDmg[i][TANK];
					//clientSIKills[players]    = survivorKills[i][HUNTER] + survivorKills[i][CHARGER] + survivorKills[i][JOCKEY] + survivorKills[i][SMOKER] + survivorKills[i][SPITTER] + survivorKills[i][BOOMER]; 
					//clientCIKills[players]    = survivorKills[i][COMMON];
					clientID[players]         = i;
					players++;
				}
			}
			
			// Rate Players
			
			new rating[players];
			for (new j = 0; j < players; j++) {
				rating[j] = RatePlayer(clientID[j]);
			}
			
			// Copy array
			new ratingCopy[players];
			for (new k = 0; k < players; k++) {
				ratingCopy[k] = rating[k];
			}
			
			// Sort Rate
			SortInteger(ratingCopy, players, Sort_Descending);
			
			new first = true;
			// Display MVP Info
			for (new l = 0; l < players; l++) {
				if (printToClient == 0) {
					if (first) {
						first = false;
						PrintToChatAll("\x05MVP:%13N (%d)T:%d%% (%d)SI:%d%% (%d)CI:%d%% ",);
					}
					else {
						PrintToChatAll("\x04%13N (%d)T:%d%% (%d)SI:%d%% (%d)CI:%d%% ",);
					}
				}
				else {
					if (first) {
						first = false;
						PrintToChat(printToClient,"\x04MVP:%13N (%d)T:%d%% (%d)SI:%d%% (%d)CI:%d%% ",);
					}
					else {
						PrintToChat(printToClient,"\x04%17N (%d)T:%d%% (%d)SI:%d%% (%d)CI:%d%% ",);
					}
				}
				
				if (detail) {
					if(printToClient == 0) {
						PrintToChatAll("\x04FF: \x01%d \x04HS: \x01%d \x04Total Dmg: \x01%d",)
					}
					else {
						PrintToChat(printToClient,\x04FF: \x01%d \x04HS: \x01%d \x04Total Dmg: \x01%d",);
					}
				}
			}
			*/
		}
		case 20000: {
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
				PrintToChatAll("\x04[JOCKEY]: \x01%4d \x04[TOTAL SI]:",totalKills[JOCKEY], totalSIKills);
				PrintToChatAll("\x04[SMOKER]: \x01%4d \x04[COMMON]: \x01%d",totalKills[SMOKER], totalKills[COMMON]);
				PrintToChatAll("\x04[BOOMER]: \x01%4d \x04[TANKS]: \x01%d",totalKills[BOOMER],totalKills[TANK]);
				PrintToChatAll("\x04[HUNTER]: \x01%4d",totalKills[HUNTER]);
				PrintToChatAll("\x04[CHARGER]: \x01%4d",totalKills[CHARGER]);
				PrintToChatAll("\x04[SPITTER]: \x01%4d",totalKills[SPITTER]);
			}
			else {
				PrintToChat(printToClient,"\x04[JOCKEY]: \x01%4d \x04[TOTAL SI]: \x01%d",totalKills[JOCKEY], totalSIKills);
				PrintToChat(printToClient,"\x04[SMOKER]: \x01%4d \x04[COMMON]: \x01%d",totalKills[SMOKER], totalKills[COMMON]);
				PrintToChat(printToClient,"\x04[BOOMER]: \x01%4d \x04[TANKS]: \x01%d",totalKills[BOOMER],totalKills[TANK]);
				PrintToChat(printToClient,"\x04[HUNTER]: \x01%4d",totalKills[HUNTER]);
				PrintToChat(printToClient,"\x04[CHARGER]: \x01%4d",totalKills[CHARGER]);
				PrintToChat(printToClient,"\x04[SPITTER]: \x01%4d",totalKills[SPITTER]);
			}
		
		}
		default: {
			// process name
			new String:name[20];
			GetClientName(option,name, sizeof(name));
			// end process name
			
			// process SI %
			new SIKills   = survivorKills[option][HUNTER] + survivorKills[option][JOCKEY] + survivorKills[option][CHARGER] + survivorKills[option][SMOKER] + survivorKills[option][SPITTER] + survivorKills[option][BOOMER];
			new Float:percentSI;

			if (totalSIKills == 0) {
				percentSI = 0.0; 
			}
			else {
				percentSI = (float(SIKills)/(float(totalSIKills)))*100.00;
			}
			// end process SI %
			
			// process CI %
			new CIKills   = survivorKills[option][COMMON];
			new Float:percentCI;
			if(totalKills[COMMON] == 0) {
				percentCI = 0.0;
			}
			else {
				percentCI =(float(CIKills)/float(totalKills[COMMON]))*100.00;
			}
			// end process CI %
			
			// process Tank %
			new TankDmg   = survivorDmg[option][TANK];
			new Float:percentTanks;
			if (totalDamage[TANK] == 0) {
				percentTanks = 0.0;
			}
			else {
				percentTanks = ((float(TankDmg)/float(totalDamage[TANK]))*100.00);
			}
			// end process Tank %
			
			// start  percentage damage
			new Float:PercentDamage[8];
			new Float:PercentKills[8];
			for (new i = 0; i < 8; i++) {
				if (survivorDmg[option][i] == 0) {
					PercentDamage[i] = 0.0;
				}
				else {
					PercentDamage[i] = (float(survivorDmg[option][i])/float(totalDamage[i]))* 100.00;
				}
				
				if (survivorKills[option][i] == 0) {
					PercentKills[i] = 0.0;
				}
				else {
					PercentKills[i] = (float(survivorKills[option][i])/float(totalKills[i]))* 100.00;
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
				PrintToChat(printToClient,"\x04%27s FF: %d HS: %d",name,survivorFFDmg[option],survivorHeadShots[option]);
				PrintToChat(printToClient,"\x04[H] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][HUNTER],totalKills[HUNTER], PercentKills[HUNTER], survivorDmg[option][HUNTER],totalDamage[HUNTER],PercentDamage[HUNTER]);
				PrintToChat(printToClient,"\x04[SM] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][SMOKER],totalKills[SMOKER], PercentKills[SMOKER], survivorDmg[option][SMOKER],totalDamage[SMOKER],PercentDamage[SMOKER]);
				PrintToChat(printToClient,"\x04[B] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][BOOMER],totalKills[BOOMER], PercentKills[BOOMER], survivorDmg[option][BOOMER],totalDamage[BOOMER],PercentDamage[BOOMER]);
				PrintToChat(printToClient,"\x04[C] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][CHARGER],totalKills[CHARGER], PercentKills[CHARGER], survivorDmg[option][CHARGER],totalDamage[CHARGER],PercentDamage[CHARGER]);
				PrintToChat(printToClient,"\x04[J] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][JOCKEY],totalKills[JOCKEY], PercentKills[JOCKEY], survivorDmg[option][JOCKEY],totalDamage[JOCKEY],PercentDamage[JOCKEY]);
				PrintToChat(printToClient,"\x04[SP] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][SPITTER],totalKills[SPITTER], PercentKills[SPITTER], survivorDmg[option][SPITTER],totalDamage[SPITTER],PercentDamage[SPITTER]);
				PrintToChat(printToClient,"\x04[T] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][TANK],totalKills[TANK], PercentKills[TANK], survivorDmg[option][TANK],totalDamage[TANK],PercentDamage[TANK]);
				PrintToChat(printToClient,"\x04[CI] \x01%d/%d \x05Kills \x03%3.0f%% \x01(%d/%d \x05Damage) \x03%3.0f%%",survivorKills[option][COMMON],totalKills[COMMON], PercentKills[COMMON], survivorDmg[option][COMMON],totalDamage[COMMON],PercentDamage[COMMON]);
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
				PrintToChat(printToClient,"\x04[SI]: \x01%4d \x05Kills \x04[CI]: \x01%5d \x05Kills \x04[T]: \x01%3d \x05Kills", totalSIKills, totalKills[COMMON], totalKills[TANK]);
			}
		
		}
	}
}

// Initializes necessary global variables for stats collection for a particular client index

IsCollectingStats(client) {
	if (survivor[client]) {
		return true;
	}
	return false;
}

StopStatsForClient(client) {
	survivor[client] = false;
}

StartStatsForClient(client) {
	if (IsClientSurvivor(client)) {
		GetClientName(client, survivorName[client], 33);
		GetClientAuthString(client, survivorSteamID[client], 20);
		survivor[client] = true;
	}
}

// stores statistics in storage variables. this can be used when player disconnects
// or changes to spectator such that total statistics are unaffected

bool:StoreStats(client) {
	
	for (new i = 0; i < 50; i++) {
		if (!storedSurvivor[i]) {
			for (new j = 0; j < 8; j++) {
				storedSurvivorKills[i][j] = survivorKills[client][j];
				storedSurvivorDmg[i][j]   = survivorDmg[client][j];
			}
			
			storedSurvivorHeadShots[i] = survivorHeadShots[client];
			storedSurvivorFFDmg[i]     = survivorFFDmg[client];
			storedSurvivorSteamID[i]   = survivorSteamID[client];
			storedSurvivorName[i]      = survivorName[client];
			
			for (new k = 0; k < MaxClients; k++) {
				storedSurvivorDmgToTank[i][k] = survivorDmgToTank[client][k];
			}
			storedSurvivor[i] = true;
			return true;
		}
	}
	return false;
}

// retrieves stored statistics of a certain steam ID, name, and inputs 
// all data in global variables with a specific client index

bool:RetrieveStats(const String:name[], const String:steamID[], client) {
	for (new i = 0; i < 50; i++) {
		if (StrEqual(storedSurvivorSteamID[i], steamID, true) && (StrEqual(storedSurvivorName[i],name,false))) {
			for (new j = 0; j < 8; j++) {
				survivorKills[client][j] = storedSurvivorKills[i][j];
				survivorDmg[client][j]   = storedSurvivorDmg[i][j];
			}
			
			survivorHeadShots[client]  = storedSurvivorHeadShots[i];
			survivorFFDmg[client]      = storedSurvivorFFDmg[i];
			survivorSteamID[client]    = storedSurvivorSteamID[i];
			survivorName[client]       = storedSurvivorName[i];
			
			for (new k = 0; k < MaxClients; k++) {
				storedSurvivorDmgToTank[i][k] = survivorDmgToTank[client][k];
			}
			storedSurvivor[i] = true;
			return true;
		}
	}
	return false;
}

// prints tank damage statistics after each tank kill in the chat output 

PrintTankStats(victim) {
	new Float:percent = 0.0;
	new maxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff;
	new players = 0;
	new damage[MaxClients];
	new tracker[MaxClients][3];
	for(new i = 1; i < MaxClients; i++) {
		if (IsClientSurvivor(i) && IsCollectingStats(i)) {
			/*
			 1111111111111111111111111111111111111111111111111
			1name56789012345678901234567890 XXXX Damage (XXX%)
			2name56789012345678901234567890 XXXX Damage (XXX%)
			3name56789012345678901234567890 XXXX Damage (XXX%)
			4name56789012345678901234567890 XXXX Damage (XXX%)
			*/
			damage[players]     = survivorDmgToTank[i][victim];
			tracker[players][0] = i;
			tracker[players][1] = survivorDmgToTank[i][victim];
			tracker[players][2] = 0;
			players++;
			//PrintToChatAll("survivorDmgToTank[i][victim] = %d, i = %d",survivorDmgToTank[i][victim], i);
		
		}
	}
	
	// sorting
	SortIntegers(damage, MaxClients, Sort_Descending);
	
	
	// sort damage and clientID
	new orderedInfo[players][2];
	for (new l = 0; l < players; l++) {
		for (new m = 0; m < players; m++) {
			if ((damage[l] == tracker[m][1]) && (tracker[m][2] == 0)) {
				orderedInfo[l][0] = tracker[m][0]; // clientID
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
		
		if (j == 0) { // first one
			if (orderedInfo[j][1],percent == 100) {
				PrintToChatAll("\x03[ULTIMATE NINJA] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
			}
			else {
				PrintToChatAll("\x03[WINNER] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
			}
		}
		else {
			if ((j < winners) && (winners > 1)) {
				PrintToChatAll("\x03[WINNER] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
			}
			else if ( j == (players-1)) {
				if (orderedInfo[j][1] == 0) {
					PrintToChatAll("\x01[NOOBTASTIC] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
				}
				else {
					PrintToChatAll("\x01[LOSER] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
				}
			}
			else {
				if (orderedInfo[j][1] == 0) {
					PrintToChatAll("\x01[NOOBTASTIC] \x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
				}
				else {
					PrintToChatAll("\x04%N \x01%d Damage \x05(%3.0f%%)", orderedInfo[j][0], orderedInfo[j][1],percent);
				}
			}
		}
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

bool:ResetStatsByClient(client) {
	if (IsClientHuman(client)) {
		survivor[client]          = false;
		survivorHeadShots[client] = 0;
		survivorFFDmg[client]     = 0;
		survivorName[client]      = "";
		survivorSteamID[client]   = "";
		for (new i = 0; i < MaxClients; i++) {
			if (i < 8) {
				survivorKills[client][i] = 0;
				survivorDmg[client][i] = 0;
			}
			survivorDmgToTank[client][i] = 0;
		}
		return true;
	}
	return false;
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
