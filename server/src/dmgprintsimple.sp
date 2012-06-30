/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

//==================================================
// Includes
//==================================================
#include <sourcemod>
#include <geoip>

//==================================================
// Globals
//==================================================
new Handle:db = INVALID_HANDLE;                 //!< The main database
new Handle:test_db_sqlite = INVALID_HANDLE;     //!< SQLite database (for testing purposes the data is wiped every time the plugin reloads)

new Handle:umvp_enabled = INVALID_HANDLE; //!< Handle to the umvp_enabled cvar

// Record variables---------------------------------
new record_id = -1;           //!< The id of the current record in progress. This is -1 if there is no game started.
new map_id     = -1;          //!< The id of the current map. If the map is not found, the map_id will remain at -1.
new start_tick = 0;           //!< The starting tick of the current round
new end_tick = 0;             //!< The ending tick of the current round

new hurtCounter = 0;

// Constants for the different teams----------------
new const TEAM_NONE       = 0;
new const TEAM_SPECTATOR  = 1;
new const TEAM_SURVIVOR   = 2;
new const TEAM_INFECTED   = 3;

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

// Constants for modelTypes-------------------------
new const NUM_MODEL_TYPES = 7;
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
	HookEvent("round_end", Event_RoundEnd);
	//HookEvent("round_end_message", Event_RoundEndMessage);
	//HookEvent("vote_started", Event_VoteStarted);
	//HookEvent("vote_cast_yes", Event_VoteCastYes);
	//HookEvent("vote_cast_no", Event_VoteCastNo);
	HookEvent("survival_round_start", Event_SurvivalRoundStart);
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

	HookEvent("player_spawn", Event_PlayerSpawn);

	// Console commands added by the plugin-------------
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

	// Console variables added by the plugin------------
	// TODO: during testing, the main functionality is disabled by default. Enable this in the future?
	umvp_enabled = CreateConVar("umvp_enabled", "0", "Determines whether the umvp plugin is enabled", 0, true, 0.0, true, 1.0); // min value 0, max 1

	Command_ConnectTestDB(-1, 0);
	AddOfficialMaps(-1);
	AddOfficialWeapons(-1);
	AddModelTypes(-1);
	PrepareConnection();
}

public OnPluginEnd() {
	CloseHandle2(db);
	CloseHandle2(test_db_sqlite);
}

//==================================================
// Event Handlers
//==================================================

public OnMapStart()
{
	GetCurrentMapID(-1);
}

public OnClientPostAdminCheck(client)
{
	AddNewClient(client);
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

//! \brief Records the tick at which the survival round has started.
public Action:Event_SurvivalRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// reset the time variables to the beginning
	ResetTimeVars();

	// ensure that the connected players are in the database by adding them
	AddConnectedPlayers();

	// Add a new record
	CreateRecord(-1);

	// Add in a new team
	AddTeam(-1);

	// Add in gameclients
	AddGameClientSurvivors();
	return Plugin_Handled;
}

//! \brief Records the tick at which the round has ended.
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (end_tick == start_tick)
		end_tick = GetSysTickCount();

	return Plugin_Handled;
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
*/

public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new id = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsClientInfected(id))
	{
	}
	else if (IsClientSurvivor(id))
	{
		//
	}
	return Plugin_Handled;
}

//==================================================
// TestDB SQL Commands
//==================================================

new const NUM_TEST_COMMANDS = 16;
new String:sql_test_commands[][1024] =
{
	"DROP TABLE IF EXISTS player;",
	"CREATE TABLE IF NOT EXISTS player(steamID VARCHAR(20) NOT NULL, name VARCHAR(32) NOT NULL, country VARCHAR(32) NULL, alias1 VARCHAR(32) NULL, alias2 VARCHAR(32) NULL, alias3 VARCHAR(32) NULL, alias4 VARCHAR(32) NULL, alias5 VARCHAR(32) NULL, alias6 VARCHAR(32) NULL, PRIMARY KEY (steamID));",
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
	PrintToConsole(client, "Available Commands:");
	PrintToConsole(client, "sm_umvp_help");
	PrintToConsole(client, "sm_umvp_connect_test_db");
	PrintToConsole(client, "sm_umvp_add_player");
	PrintToConsole(client, "sm_umvp_add_official_maps");
	PrintToConsole(client, "sm_umvp_add_official_weapons");
	PrintToConsole(client, "sm_umvp_add_connected_players");
	PrintToConsole(client, "sm_umvp_add_weapon");
	PrintToConsole(client, "sm_umvp_add_record");
	PrintToConsole(client, "sm_umvp_add_team");
	PrintToConsole(client, "sm_umvp_add_model_types");
	PrintToConsole(client, "sm_umvp_add_game_client");
	PrintToConsole(client, "sm_umvp_get_mapid");
	PrintToConsole(client, "sm_umvp_output_player_table");
	PrintToConsole(client, "sm_umvp_output_maps_table");
	PrintToConsole(client, "sm_umvp_output_weapons_table");
	PrintToConsole(client, "sm_umvp_output_records_table");
	PrintToConsole(client, "sm_umvp_output_game_client_table");
	PrintToConsole(client, "sm_umvp_output_model_types_table");
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
		SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, sql_test_commands[i], client);
	}
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
//! \brief This command is used to add the players into the players table
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
//! \brief Adds the connected players that are on the survivor team to the players tables
//! \returns The number of players added
//--------------------------------------------------
AddConnectedPlayers()
{
	new numplayers = 0;

	//Calculate who is on what team
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i))
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

	// get the ip address so the country can be determined
	if (!GetClientIP(client, ip, sizeof(ip)))
		return;

	// get the country
	if (!GeoipCountry(ip, country, sizeof(country)))
		Format(country, sizeof(country), "");

	// get the player name
	if (!GetClientName(client, name, sizeof(name)))
		return;

	// create a query string for inserting the data into the table
	Format(query, sizeof(query), "REPLACE INTO player (steamID, name, country) VALUES (\'%s\', \'%s\', \'%s\')", steamid, name, country);
	SQL_TQuery(test_db_sqlite, PostQueryDoNothing, query);
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
		SQL_TQuery(test_db_sqlite, PostQueryPrintErrors, query, client);
	}
}

//--------------------------------------------------
// AddGameClientSurvivors
//!
//! \brief Adds the current players into the gameclient table
//--------------------------------------------------
AddGameClientSurvivors()
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

				AddGameClient(-1, steamid, 0, start_tick, -1);
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
		if (SQL_FetchRow(result) > 0)
		{
			game_client_id = SQL_FetchInt(result, 0);
		}
		CloseHandle(result);
	}
	SQL_UnlockDatabase(test_db_sqlite);

	return game_client_id;
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

	if (result == INVALID_HANDLE && client > 0)
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

//--------------------------------------------------
// Client Status Functions
//--------------------------------------------------

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
