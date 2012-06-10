/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>
new survivorKills[MAXPLAYERS + 1][8] //stores the kills for each survivor for each SI type
new survivorDmg[MAXPLAYERS + 1][8] //stores the kills for each survivor for each SI type
									   // 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
new survivorHeadShots[MAXPLAYERS + 1];
new survivorFFDmg[MAXPLAYERS + 1];

//Constants for different SI types
new const COMMON  = 0;
new const HUNTER  = 1;
new const JOCKEY  = 2;
new const CHARGER = 3;
new const SPITTER = 4;
new const BOOMER  = 5;
new const SMOKER  = 6;
new const TANK    = 7;

// Constants for the different teams----------------
const TEAM_NONE       = 0;
const TEAM_SPECTATOR  = 1;
const TEAM_SURVIVOR   = 2;
const TEAM_INFECTED   = 3;


public Plugin:myinfo = {
		   name = "stats",
		 author = "sauce",
	description = "Stats for survival kills",
		version = "0.0.1"
};


public OnPluginStart() {
	
	//Pre-Alpha events to hook into
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_end ", Event_RoundEnd);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//other info
	new hitgroup = GetEventInt(event, "hitgroup");
	new damage   = GetEventInt(event, "dmg_health");

	//victim info
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new victimRemainingHealth = GetEventInt(event, "health");
	new victimName[40];
	GetClientName(victim, victimName, strlen(victimName));
	
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:attackerSteamID[21];
	GetClientAuthString(attacker,attackerSteamID, strlen(attackerSteamID));
	new attackerTeam = GetClientTeam(attacker);
	
	/*
	Conditions for collection
			1) Don't collect damage by SI
			2) Don't collect damage by Console/World
			3) Collect damage from bot survivors and player survivors
	*/
	
	if (attacker != 0) { //check if the attacker is Console/World if not then move forward

		if(attackerTeam == 1) { //survivor damage including bots
			//record survivor attack
			if (hitgroup == 1) {
				survivorHeadShots[]++
				
				//gets rid of number before SI name
				if (victimName[0] == "(") {
					victimName[0] = "";
					victimName[1] = "";
					victimName[2] = "";
				}
				PrintToChatAll("HEADSHOT by %N on %N",attacker, TrimString(victimName));
			}
		}
		//else if(strcmp(attackerSteamID,"BOT",false) && (attackerTeam == 2)) { don't need to record}
	}
	//else {} Do nothing when it's console/world
	
	
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:attackerSteamID[21];

	GetClientAuthString(attacker, attackerSteamID, sizeof(attackerSteamID));
	new attackerTeam = GetClientTeam(attacker);
	new damage = 0;
	new hitgroup;

	//Only process if the player is a legal attacker (i.e., a player)
	if (attacker && attacker <= MaxClients)
	{
		// retrieve the damage and hitgroup
		damage    = GetEventInt(event, "amount");
		hitgroup  = GetEventInt(event, "hitgroup");

		survivorDmg[attacker][COMMON] += damage;

		// check for a headshot
		if (hitgroup == 1) {
			survivorHeadShots[attacker]++;
		}
	}
}

public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:attackerSteamID[21];
	GetClientAuthString(attacker, attackerSteamID, sizeof(attackerSteamID));
	new attackerTeam = GetClientTeam(attacker);

	//Only process if the player is a legal attacker (i.e., a player)
	if (attacker && attacker <= MaxClients)
	{
		survivorKills[attacker][COMMON]++;
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	/*
	# Name                             |SI     |CI      |Tank
	1 12345678901234567890123456789012|100 100%|500 100%|100%
	2 12345678901234567890123456789012|100 100%|500 100%|100%
	3 12345678901234567890123456789012|100 100%|500 100%|100%
	4 12345678901234567890123456789012|100 100%|500 100%|100%
	1111111111111111111111111111111111111111111111111111111
	*/
}

//--------------------------------------------------
// ResetStats
//!
//! \brief Use this function to reset the kill and damage arrays to zero
//--------------------------------------------------
ResetStats() {
	for (new i = 0; i < MAXPLAYERS + 1; i++) {
		for (new j = 0; j < 8; j++) {
			survivorKills[i][j] = 0;
			survivorDmg[i][j] = 0;
		}
		survivorHeadShots[i] = 0;
		survivorFFDmg[i] = 0;
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
		total_array[i] = 0;
	}

	// now add all damages from the different clients that are connected and on the survivor team
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			new team = GetClientTeam(i);

			if (team == TEAM_SURVIVOR && !IsFakeClient(i)) {
				// go through the 8 different types of infected (7 SI, 1 common)
				for (new j = 0; j < 8; j++) {
					total_kills_array[j] += survivorKills[i][j];
					total_damage_array[j] += survivorDmg[i][j];
				} // end inner for loop
			}
		}
	} // end outer for loop
}
