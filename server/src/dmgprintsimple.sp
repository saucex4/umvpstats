/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>

new Handle:db = INVALID_HANDLE;
new hurtCounter = 0;

public Plugin:myinfo = 
{
		   name = "Damage Print",
		 author = "sauce",
	description = "Prints out damage dealt",
		version = "0.0.1"
};

public OnPluginStart()
{
	//World Events
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
	
	//Survivor Events
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
	
	//Special infected Events
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
	
	//Events for both
	//HookEvent("player_falldamage", Event_PlayerFallDamage);
	//HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	//HookEvent("player_talking_state", Event_PlayerTalkingState);
	//HookEvent("gas_can_forced_drop", Event_GasCanForcedDrop);
	//HookEvent("scavenge_gas_can_destroyed", Event_ScavengeGasCanDestroyed);
	
	//HookEvent("smoker_killed", Event_SmokerKilled); //does not exist
	//HookEvent("boomer_killed", Event_BoomerKilled); //does not exist
	PrepareConnection();
}

public OnPluginEnd() {
	CloseHandle2(db);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
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
				if (numplayers > 0)
				{
					Format(tmp, sizeof(tmp), ", ");
					StrCat(buf, length, tmp);
				}

				GetClientName(i, tmp, sizeof(tmp));
				StrCat(buf, length, tmp);
				numplayers++;
			}
		}
	}
}

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
		return;

	// get the player name
	if (!GetClientName(client, name, sizeof(name)))
		return;

	// create a query string for inserting the data into the table
	Format(query, sizeof(query), "REPLACE INTO player (steamID, name) VALUES (%s, %s)", steamid, name);
	SQL_TQuery(db, PostQueryDoNothing, query);
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
