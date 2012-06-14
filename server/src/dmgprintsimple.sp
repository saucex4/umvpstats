/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

//==================================================
// Includes
//==================================================
#include <sourcemod>

//==================================================
// Globals
//==================================================
new Handle:db = INVALID_HANDLE;
new Handle:test_db_sqlite = INVALID_HANDLE;

new Handle:umvp_enabled = INVALID_HANDLE; //!< Handle to the umvp_enabled cvar

new hurtCounter = 0;

// Constants for the different teams----------------
new const TEAM_NONE       = 0;
new const TEAM_SPECTATOR  = 1;
new const TEAM_SURVIVOR   = 2;
new const TEAM_INFECTED   = 3;

// Constants for map names--------------------------
new const NUM_OFFICIAL_MAPS_2 = 10;
new String:OFFICIAL_MAPS_2[][64] =
{
	"c2m1_highway",
	"c2m4_barns",
	"c2m5_concert",
	"c3m1_plankcountry",
	"c3m4_plantation",
	"c4m1_milltown_a",
	"c4m2_milltown_b",
	"c5m2_park",
	"c5m5_bridge",
	"c1m4_atrium"
};
new String:CAMPAIGNS_2[][64] =
{
	"Dark Carnival",
	"Dark Carnival",
	"Dark Carnival",
	"Swamp Fever",
	"Swamp Fever",
	"Hard Rain",
	"Hard Rain",
	"Bus Depot",
	"Bus Depot",
	"Dead Center"
};

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
new const NUM_INSTAKILL_WEAPONS = 4;
new const String:INSTAKILL_WEAPONS[][64] =
{
	"weapon_sniper_awp",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_hunting_rifle"
};

public Plugin:myinfo = 
{
		   name = "Damage Print",
		 author = "sauce",
	description = "Prints out damage dealt",
		version = "0.0.1"
};

public OnPluginStart()
{
	// World Events-------------------------------------
	//HookEvent("round_end", Event_RoundEnd);
	//HookEvent("round_end_message", Event_RoundEndMessage);
	//HookEvent("vote_started", Event_VoteStarted);
	//HookEvent("vote_cast_yes", Event_VoteCastYes);
	//HookEvent("vote_cast_no", Event_VoteCastNo);
	//HookEvent("survival_round_start", Event_SurvivalRoundStart);
	//HookEvent("scavenge_round_start", Event_ScavengeRoundStart);
	//HookEvent("scavenge_round_halftime", Event_ScavengeHalfTime);
	//HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished);
	//HookEvent("versus_round_start", Event_VersusRoundStart);
	//HookEvent("scavenge_match_finished", Event_ScavengeMatchFinished);
	//HookEvent("versus_match_finished", Event_VersusMatchFinished);
	//HookEvent("survival_at_30mins", Event_SurvivalAt30Min);
	
	// Survivor Events----------------------------------
	//HookEvent("weapon_fire", Event_WeaponFire);
	//HookEvent("weapon_reload", Event_WeaponReload);
	//HookEvent("weapon_zoom", Event_WeaponZoom);
	//HookEvent("ammo_pickup", Event_AmmoPickup);
	//HookEvent("item_pickup", Event_ItemPickup);
	//HookEvent("player_footstep", Event_PlayerFootstep);
	//HookEvent("player_jump", Event_PlayerJump);
	//HookEvent("player_blind", Event_PlayerBlind);
	//HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	//HookEvent("door_open", Event_DoorOpen);
	//HookEvent("door_close", Event_DoorClose);
	//HookEvent("rescue_door_open", Event_RescueDoorOpen);
	//HookEvent("waiting_checkpoint_door_used", Event_WaitingCheckpointDoorUsed);
	//HookEvent("waiting_door_used_versus", Event_WaitingDoorUsedVersus);
	//HookEvent("waiting_checkpoint_button_used", Event_WaitingCheckpointButtonUsed);
	//HookEvent("success_checkpoint_button_used", Event_SuccessCheckpointButtonUsed);
	//HookEvent("heal_begin", Event_HealBegin);
	//HookEvent("heal_success", Event_HealSuccess);
	//HookEvent("heal_interrupted", Event_HealInterrupted);
	//HookEvent("pills_used", Event_PillsUsed);
	//HookEvent("pills_used_fail", Event_PillsUsedFail);
	//HookEvent("defibrillator_begin", Event_DefibrillatorAttempt);
	//HookEvent("defibrillator_used", Event_DefibrillatorUsed);
	//HookEvent("defibrillator_used_fail", Event_DefibrillatorUsedFail);
	//HookEvent("defibrillator_interrupted", Event_DefibrillatorInterrupted);
	//HookEvent("upgrade_pack_begin", Event_UpgradePackBegin);
	//HookEvent("upgrade_pack_used", Event_UpgradePackUsed);
	//HookEvent("adrenaline_used", Event_AdrenalineUsed);
	//HookEvent("revive_begin", Event_ReviveBegin);
	//HookEvent("revive_success", Event_ReviveSuccess);
	//HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	//HookEvent("player_shoved", Event_PlayerShoved);
	//HookEvent("player_now_it", Event_PlayerNowIt); //have to try this one
	//HookEvent("witch_harasser_set", Event_WitchHarasserSet);
	//HookEvent("melee_kill", Event_MeleeKill);
	//HookEvent("survivor_call_for_help", Event_SurvivorCallForHelp);
	//HookEvent("survivor_rescued", Event_SurvivorRescuded);
	//HookEvent("break_breakable", Event_BreakBreakable);
	//HookEvent("gascan_pour_completed", Event_GascanPourCompleted);
	//HookEvent("gascan_dropped", Event_GascanDropped);
	//HookEvent("gascan_pour_interrupted", Event_GascanPourInterrupted);
	//HookEvent("friendly_fire", Event_FriendlyFire);
	//HookEvent("weapon_pickup", Event_WeaponPickup);
	//HookEvent("hunter_punched", Event_HunterPunched);
	//HookEvent("hunter_headshot", Event_HunterHeadShot);
	//HookEvent("zombie_ignited", Event_ZombieIgnited);
	//HookEvent("boomer_exploded", Event_BoomerExploded);
	//HookEvent("upgrade_incendiary_ammo", Event_UpgradeIncendiaryAmmo);
	//HookEvent("upgrade_explosive_ammo", Event_UpgradeExplosiveAmmo);
	//HookEvent("receive_upgrade", Event_ReceiveUpgrade);
	//HookEvent("mounted_gun_start", Event_MountedGunStart);
	//HookEvent("mounted_gun_overheated", Event_MountedGunOverheated);
	//HookEvent("entered_spit", Event_EnteredSpit);
	//HookEvent("punched_clown", Event_PunchedClown);
	//HookEvent("infected_decapitated", Event_InfectedDecap);
	//HookEvent("upgrade_pack_added", Event_UpgradePackAdded);
	//HookEvent("vomit_bomb_tank", Event_VomitBombTank);
	//HookEvent("triggered_car_alarm", Event_TriggeredCarAlarm);
	//HookEvent("molotov_thrown", Event_MolotovThrown);
	
	// Special infected Events--------------------------
	//HookEvent("ability_use", Event_AbilityUse);
	//HookEvent("tank_spawn", Event_TankSpawn);
	//HookEvent("charger_killed", Event_ChargerKilled);
	//HookEvent("hunter_killed", Event_HunterKilled);
	//HookEvent("spitter_killed", Event_SpitterKilled);
	//HookEvent("jockey_killed", Event_JockeyKilled);
	//HookEvent("tank_killed", Event_TankKilled);
	//HookEvent("infected_hurt", Event_InfectedHurt);
	//HookEvent("infected_death", Event_InfectedDeath);
	//HookEvent("witch_killed", Event_WitchKilled);
	//HookEvent("tongue_grab", Event_TongueGrab);
	//HookEvent("tongue_release", Event_TongueRelease);
	//HookEvent("choke_start", Event_ChokeEnd);
	//HookEvent("choke_stopped", Event_ChokeStopped);
	//HookEvent("tongue_pull_stopped", Event_TonguePullStopped);
	//HookEvent("lunge_shove", Event_LungeShove);
	//HookEvent("lunge_pounce", Event_LungePounce);
	//HookEvent("pounce_end", Event_PounceEnd);
	//HookEvent("fatal_vomit", Event_FatalVomit);
	//HookEvent("spit_burst", Event_SpitBurst);
	//HookEvent("jockey_ride", Event_JockeyRide);
	//HookEvent("jockey_ride_end", Event_JockeyRideEnd);
	//HookEvent("charger_charge_start", Event_ChargerChargeStart);
	//HookEvent("charger_charge_end", Event_ChargerChargeEnd);
	//HookEvent("charger_carry_start", Event_ChargerCarryStart);
	//HookEvent("charger_carry_end", Event_ChargerCarryEnd);
	//HookEvent("charger_impact", Event_ChargerImpact);
	//HookEvent("charger_pummel_start", Event_ChargerPummelStart);
	//HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	//HookEvent("stashwhacker_game_won", Event_StashWhackerGameWon);
	//HookEvent("foot_lock_opened", Event_FootLockerOpened);
	
	// Events for both----------------------------------
	//HookEvent("player_falldamage", Event_PlayerFallDamage);
	//HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	//HookEvent("player_talking_state", Event_PlayerTalkingState);
	//HookEvent("gas_can_forced_drop", Event_GasCanForcedDrop);
	//HookEvent("scavenge_gas_can_destroyed", Event_ScavengeGasCanDestroyed);
	
	//HookEvent("smoker_killed", Event_SmokerKilled); //does not exist
	//HookEvent("boomer_killed", Event_BoomerKilled); //does not exist

	// Console commands added by the plugin-------------
	RegConsoleCmd("sm_umvp_add_player", Command_AddPlayerToDB);
	RegConsoleCmd("sm_umvp_output_player_table", Command_OutputPlayerTable);
	RegConsoleCmd("sm_umvp_help", Command_Help);
	RegConsoleCmd("sm_umvp_connect_test_db", Command_ConnectTestDB);
	RegConsoleCmd("sm_umvp_add_official_maps", Command_AddOfficialMaps);
	RegConsoleCmd("sm_umvp_add_official_weapons", Command_AddOfficialWeapons);
	RegConsoleCmd("sm_umvp_add_weapon", Command_AddWeapon);
	RegConsoleCmd("sm_umvp_output_maps_table", Command_OutputMapsTable);
	RegConsoleCmd("sm_umvp_output_weapons_table", Command_OutputWeaponTable);

	// Console variables added by the plugin------------
	// TODO: during testing, the main functionality is disabled by default. Enable this in the future?
	umvp_enabled = CreateConVar("umvp_enabled", "0", "Determines whether the umvp plugin is enabled", 0, true, 0.0, true, 1.0); // min value 0, max 1

	Command_ConnectTestDB(-1, 0);
	PrepareConnection();
}

public OnPluginEnd() {
	CloseHandle2(db);
	CloseHandle2(test_db_sqlite);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new enabled;
	enabled = GetConVarInt(umvp_enabled);

	if (enabled == 0)
		return;

	hurtCounter++;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:victimName[50]; 
	GetEventString(event, "userid",victimName, strlen(victimName));
	new victimteam = GetClientTeam(victim);
	new health = GetEventInt(event, "health");
	new maxhealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff;
	
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:attackerName[50];
	GetEventString(event, "attacker", attackerName, strlen(attackerName));
	
	
	new attackerteam;
	new attackerhealth;
	new attackermaxhealth;
	 
	if (attacker != 0) {
		attackerteam = GetClientTeam(attacker);
		attackerhealth = GetClientHealth(attacker);
		attackermaxhealth = GetEntProp(attacker, Prop_Send, "m_iMaxHealth") & 0xffff;
	}
	else {
		attackerteam = -1;
		attackerhealth = 0;
		attackermaxhealth = 0;
	}
	
	new attackerentid = GetEventInt(event, "attackerentid");
	new damagetype = GetEventInt(event,"type");
	
	
	new String:weapon[50];
	GetEventString(event, "weapon", weapon, 50);
	new damage = GetEventInt(event, "dmg_health");
	
	new hitgroup = GetEventInt(event,"hitgroup");
	// \x01 or \x02 default
	// \x03 light-green
	// \x04 orange 
	// \x05  green
	
	PrepareConnection();
	new String:queryStr[1024];
	new String:chatOutput[1024];
	
	Format(queryStr, sizeof(queryStr), "INSERT INTO `stats`.`playerhurt` (`damage`, `victimTeam`, `victimId`, `victimName`, `victimHealthLeft`, `victimMaxHealth`, `attackerTeam`, `attackerId`, `attackerName`, `attackerEntId`, `attackerHealthLeft`, `attackerMaxHealth`, `attackerWeapon`, `hitgroup`, `damageType`, `entryId`) VALUES ('%d','%d','%d','%N','%d','%d','%d','%d','%N','%d','%d','%d','%s','%d','%d','%d');",damage, victimteam, victim, victim, health, maxhealth, attackerteam, attacker, attacker, attackerentid , attackerhealth, attackermaxhealth, weapon, hitgroup, damagetype, hurtCounter);
	Format(chatOutput, sizeof(chatOutput), "\x01[%d] RECORDED: \x03%d \x01dmg to \x04[T:%d][cid:%d] %N (%d/%d) \x01by  \x05[T:%d][cid:%d][eid:%d] %N (%d/%d) with %s : Hitgroup = %d, type = %d", hurtCounter, damage, victimteam, victim, victim, health, maxhealth, attackerteam, attacker, attackerentid, attacker, attackerhealth, attackermaxhealth, weapon, hitgroup, damagetype);
	//PrintToServer(queryStr);
	//PrintToChatAll(chatOutput);
	new Handle:datapack = CreateDataPack();
	WritePackString(datapack,chatOutput);
	SQL_TQuery(db, PostQuery, queryStr, datapack, DBPrio_Low);
	
	
	//new String:steamId[256];
	//GetClientAuthString(attacker,steamId,sizeof(steamId));
	//new String:vicsteamId[256];
	//GetClientAuthString(victim,vicsteamId,sizeof(vicsteamId));
	//PrintToChatAll("Attacker Steam ID: %s, Victim Steam ID: %s", steamId,vicsteamId);
}


/*
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[50]; 
	GetEventString(event, "weapon", weapon, 50);
	if (GetEventBool(event,"headshot")) {
		PrintHintTextToAll("\x05HEADSHOT! \x04[%d] %N \x01was killed by %N with %s", victim, victim, attacker, weapon);
	}
	else {
		PrintToChatAll("\x04[%d] %N \x01was killed by %N with %s", victim, victim, attacker, weapon);
	}
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	//new health = GetEventInt(event, "health");
	new maxhealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff;
	
	PrintToChatAll("\x04[%d] %N (%d/%d)\x01has spawned", victim, victim, maxhealth, maxhealth);
}
*/

public PostQuery(Handle:owner, Handle:result, const String:error[], any:datapack) {
	new String:dataStr[1024];
	ResetPack(datapack, false);
	ReadPackString(datapack, dataStr, sizeof(dataStr));
	CloseHandle(datapack);
	if(strlen(error) > 0) {
		PrintToServer("QUERY FAILED! Error: %s", error);
	}
	else {
		//PrintToChatAll("printing %s", dataStr);
	}
	return;
}

new conn_last_init = 0;
bool:PrepareConnection() {
	if(db != INVALID_HANDLE) {
		return true;
	} else {
		if(GetTime() - conn_last_init > 10) {
			conn_last_init = GetTime();
			
			//decl String:conn_name[128];
			//GetConVarString(cv_db_conn_name, conn_name, sizeof(conn_name));
			//if(strlen(conn_name) > 0) {
			SQL_TConnect(PostConnect, "stats");
			//} else {
				//SQL_TConnect(PostConnect, "default");
			//}
		}
		return false;
	}
}

public PostConnect(Handle:owner, Handle:conn, const String:error[], any:data) {
	if(conn == INVALID_HANDLE) {
		PrintToServer("[UMVPS] Failed to connect to SQL database.  Error: %s", error);
		LogError("Failed to connect to SQL database.  Error: %s", error);
	}
	else {
		db = conn;
	}
}

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


/*
public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));	
	new String:weapon[50]; 
	GetClientWeapon(attacker, weapon, 50);
	new damage = GetEventInt(event, "amount");
	//new entityId = GetEventInt(event, "entityid");
	// \x01 or \x02 default
	// \x03 light-green
	// \x04 orange
	// \x05  green
	PrintToChatAll("\x03%d \x01dmg to \x01by \x05[%d] %N with %s", damage, attacker,attacker,weapon);
}

public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {


}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	
}
*/

//==================================================
// TestDB SQL Commands
//==================================================

new const NUM_TEST_COMMANDS = 16;
new String:sql_test_commands[][1024] =
{
	"DROP TABLE IF EXISTS player;",
	"CREATE TABLE IF NOT EXISTS player(steamID VARCHAR(20) NOT NULL, name VARCHAR(32) NOT NULL, url VARCHAR(32) NULL, alias1 VARCHAR(32) NULL, alias2 VARCHAR(32) NULL, alias3 VARCHAR(32) NULL, alias4 VARCHAR(32) NULL, alias5 VARCHAR(32) NULL, alias6 VARCHAR(32) NULL, PRIMARY KEY (steamID));",
	"DROP TABLE IF EXISTS weapon;",
	"CREATE TABLE IF NOT EXISTS weapon(weaponID INTEGER, name VARCHAR(45), type INTEGER NULL, PRIMARY KEY (weaponID), UNIQUE (name));",
	"DROP TABLE IF EXISTS maps;",
	"CREATE TABLE IF NOT EXISTS maps(mapID INTEGER, mapName VARCHAR(45), campaignName VARCHAR(45) NULL, url VARCHAR(255) NULL, game INTEGER, PRIMARY KEY (mapID), UNIQUE (mapName, campaignName));",
	"DROP TABLE IF EXISTS record;",
	"CREATE TABLE IF NOT EXISTS record(recordID INTEGER, duration INTEGER, mapID INTEGER, PRIMARY KEY (recordID));",
	"DROP TABLE IF EXISTS gameClient;",
	"CREATE TABLE IF NOT EXISTS gameClient(entryID INTEGER, modelID INTEGER, steamID VARCHAR(20), birthTime INTEGER, deathTime INTEGER, PRIMARY KEY (entryID));",
	"DROP TABLE IF EXISTS team;",
	"CREATE TABLE IF NOT EXISTS team(teamID INTEGER, steamID VARCHAR(20), recordID INTEGER, teamType INTEGER, birthTime INTEGER, deathTime INTEGER, PRIMARY KEY (teamID));",
	"DROP TABLE IF EXISTS modelTypes;",
	"CREATE TABLE IF NOT EXISTS modelTypes(modelID INTEGER, steamID VARCHAR(45), modelType INTEGER, PRIMARY KEY (modelID));",
	"DROP TABLE IF EXISTS damage;",
	"CREATE TABLE IF NOT EXISTS damage(entryID INTEGER, eventTimestamp INTEGER, recordID INTEGER, damageAmount INTEGER NULL, hitgroup INTEGER, weaponID INTEGER, damageType INTEGER, kill INTEGER, attacker INTEGER, aRemainingHealth INTEGER, aMaxHealth INTEGER, aPositionX FLOAT, aPositionY FLOAT, aPositionZ FLOAT, aLatency INTEGER, aLoss INTEGER, aChoke INTEGER, aPackets INTEGER, victimSteamID VARCHAR(20), vRemainingHealth INTEGER, vMaxHealth VARCHAR(45), vPositionX FLOAT, vPositionY FLOAT, vPositionZ FLOAT, vLatency INTEGER, vLoss INTEGER, vChoke INTEGER, vPackets INTEGER, PRIMARY KEY (entryID));"
};

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
	PrintToChat(client, "Available Commands:");
	PrintToChat(client, "sm_umvp_help");
	PrintToChat(client, "sm_umvp_connect_test_db");
	PrintToChat(client, "sm_umvp_add_player");
	PrintToChat(client, "sm_umvp_add_official_maps");
	PrintToChat(client, "sm_umvp_add_official_weapons");
	PrintToChat(client, "sm_umvp_add_weapon");
	PrintToChat(client, "sm_umvp_output_player_table");
	PrintToChat(client, "sm_umvp_output_maps_table");
	PrintToChat(client, "sm_umvp_output_weapons_table");
	return Plugin_Handled;
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
		new Handle:query;
		if (!(SQL_FastQuery(test_db_sqlite, sql_test_commands[i])))
		{
			SQL_GetError(test_db_sqlite, error, sizeof(error));
			if (client > 0)
				PrintToConsole(client, error);
		}
		CloseHandle2(query);
	}
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
//! \brief This command is used to output the entire player table to console.
//--------------------------------------------------
public Action:Command_OutputWeaponTable(client, args)
{
	QueryWeapons(client);
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

//==================================================
// Helper Functions and Callbacks
//==================================================

//--------------------------------------------------
// AddOfficialWeapons
//!
//! \brief Adds the official weapons into the weapons table
//! \param[in] client The client index of the client to output results to. Use -1 to suppress output.
//--------------------------------------------------
AddOfficialWeapons(client)
{
	decl String:query[128];
	for (new i = 0; i < NUM_WEAPONS; i++)
	{
		if (client > 0)
		{
			PrintToChat(client, "Inserting weapon %s...", WEAPON_NAMES[i]);
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
	decl String:query[128];
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
	new String:country[64];
	decl String:name[64];
	decl String:query[500];

	// ensure that the client index is valid and the client is actually connected
	if (client < 1 || client > MaxClients || !IsClientConnected(client))
		return;

	// get the steamid, which is used to identify players
	if (!GetClientAuthString(client, steamid, sizeof(steamid)))
		return;

	// get the ip address so the country can be determined
	if (!GetClientIP(client, ip, sizeof(ip)))
		return;

	// get the country
	//if (!GeoipCountry(ip, country, sizeof(country)))
		//return;

	// get the player name
	if (!GetClientName(client, name, sizeof(name)))
		return;

	// create a query string for inserting the data into the table
	Format(query, sizeof(query), "REPLACE INTO player (steamID, name) VALUES (\'%s\', \'%s\')", steamid, name);
	SQL_TQuery(test_db_sqlite, PostQueryDoNothing, query);
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

	PrintToChat(client, "%d results", length);

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
	PrintToChat(client, "%d Results...", SQL_GetRowCount(result));

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
		PrintToConsole(client, error);
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
