/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>
new survivorKills[MAXPLAYERS + 1][8]; //stores the kills for each survivor for each SI type
new survivorDmg[MAXPLAYERS + 1][8];   //stores the kills for each survivor for each SI type
								     // 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
new survivorHeadShots[MAXPLAYERS + 1];
new survivorFFDmg[MAXPLAYERS + 1];


//multiple tank support variables
new bool:tankClients[MAXPLAYERS + 1];
new tankHealth[MAXPLAYERS + 1];
new survivorDmgToTank[MAXPLAYERS + 1][MAXPLAYERS +1];

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
	HookEvent("survival_round_start", Event_RoundStart);
	RegConsoleCmd("sm_stats", Command_Kills);

}
	survivorKills[MAXPLAYERS + 1][8];
	survivorDmg[MAXPLAYERS + 1][8];
								     // 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
	survivorHeadShots[MAXPLAYERS + 1];
	survivorFFDmg[MAXPLAYERS + 1];

public Action:Command_Kills(client, args) {
	PrintStats();
}

PrintStats() {
	
}

PrintTankStats() {

}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	ResetStats();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:victimName[40];
	GetClientName(victim, victimName, strlen(victimName));
	
	if (StrContains(victimName, "Tank") != -1) {
		PrintTankStats()
	}
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//other info
	new hitgroup = GetEventInt(event, "hitgroup");
	new damage   = GetEventInt(event, "dmg_health");

	//victim info
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new victimRemainingHealth = GetEventInt(event, "health");
	new String:victimName[40];
	GetClientName(victim, victimName, strlen(victimName));
	new victimTeam = GetClientTeam(victim);
	
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

		if(attackerTeam == TEAM_SURVIVOR) { //survivor damage including bots
			
			//record survivor attack
			if (hitgroup == 1) {
				survivorHeadShots[attacker]++;
				//gets rid of number before SI name
				if (victimName[0] == '(') {
					victimName[0] = ' ';
					victimName[1] = ' ';
					victimName[2] = ' ';
				}
				PrintToChatAll("HEADSHOT by %N on %N",attacker, TrimString(victimName));
			}
			
			if (victimTeam == TEAM_SURVIVOR) { //record friendly fire
				survivorFFDmg[attacker] += damage;
			}
			else if(damage > 0) { //record damage
				// 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
				if (StrContains(victimName, "Hunter") != -1) {
					survivorDmg[attacker][HUNTER] += damage;
                }
                else if (StrContains(victimName, "Jockey") != -1) {
					survivorDmg[attacker][JOCKEY] += damage;
                }
                else if (StrContains(victimName, "Charger") != -1) {
					survivorDmg[attacker][CHARGER] += damage;
                }
                else if (StrContains(victimName, "Spitter") != -1) {
					survivorDmg[attacker][SPITTER] += damage;
                }
                else if (StrContains(victimName, "Boomer") != -1) {
					survivorDmg[attacker][BOOMER] += damage;
                }
                else if (StrContains(victimName, "Smoker") != -1) {
					survivorDmg[attacker][SMOKER] += damage;
                }
                else if (StrContains(victimName, "Tank") != -1) {
					//deal with multiple tanks here
					if (tankClients[victim]) { //if this tank is alive record
						if (tankHealth[victim] <= 0) {
							tankClients[victim] = false;
							tankHealth[victim] = 0;
						}
						else {
							tankHealth[victim] -= damage;
							survivorDmg[attacker][TANK] += damage;
							survivorDmgToTank[attacker][victim] -= damage; //Do we count the damage that exceeds the tank's health?
						}
					}
                }
				
			}
			
			//record kill
			if(victimRemainingHealth == 0) {
				// 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
				if (StrContains(victimName, "Hunter") != -1)
                {
                    survivorKills[attacker][HUNTER]++;
                }
                else if (StrContains(victimName, "Jockey") != -1)
                {
                     survivorKills[attacker][JOCKEY]++;
                }
                else if (StrContains(victimName, "Charger") != -1)
                {
                    survivorKills[attacker][CHARGER]++;
                }
                else if (StrContains(victimName, "Spitter") != -1)
                {
					survivorKills[attacker][SPITTER]++;
                }
                else if (StrContains(victimName, "Boomer") != -1)
                {
					survivorKills[attacker][BOOMER]++;
                }
                else if (StrContains(victimName, "Smoker") != -1)
                {
					survivorKills[attacker][SMOKER]++;
                }
                else if (StrContains(victimName, "Tank") != -1)
                {
					survivorKills[attacker][TANK]++;
                }
				
			}
		}
		//else if(strcmp(attackerSteamID,"BOT",false) && (attackerTeam == 2)) { don't need to record}
	}
	//else {} Do nothing when it's console/world
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new tankId = GetEventInt(event,"tankid");
	tankClients[tankId] = true;
	tankHealth[tankId] = GetEntProp(tankId, Prop_Send, "m_iMaxHealth") & 0xffff;
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
	PrintStats();
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
		tankClients[i] = false;
		tankHealth[i]  = 0;
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
