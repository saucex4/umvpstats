/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>
new bool:survivor[MAXPLAYERS + 1];
new survivorKills[MAXPLAYERS + 1][8]; //stores the kills for each survivor for each SI type
new survivorDmg[MAXPLAYERS + 1][8];   //stores the kills for each survivor for each SI type
								     // 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
new survivorHeadShots[MAXPLAYERS + 1];
new survivorFFDmg[MAXPLAYERS + 1];
new SIHealth[MAXPLAYERS + 1];

//multiple tank support variables
new bool:SIClients[MAXPLAYERS + 1];
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
	//HookEvent("player_death", Event_PlayerDeath);
	//HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("survival_round_start", Event_RoundStart);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	
	
	//console commands
	RegConsoleCmd("sm_stats", Command_Stats);
	RegConsoleCmd("sm_resetstats", ResetStats);
	RegConsoleCmd("
}

public Action:Command_Stats(client, args) {
	PrintStats();
}

PrintStats() {
	for(new i = 1; i < MAXPLAYERS + 1; i++) {
		if(survivor[i]) {
			PrintToChatAll("%N 
							Head:%d 
							FF:%d 
							CI:%d(%d) 
							H:%d(%d) 
							J:%d(%d) 
							C:%d(%d) 
							SP:%d(%d) 
							B:%d(%d) 
							SM:%d(%d) 
							T:%d(%d)", 
							i, survivorHeadShots[i],survivorFFDmg[i],
							survivorKills[i][COMMON],survivorDmg[i][COMMON],
							survivorKills[i][HUNTER],survivorDmg[i][HUNTER],
							survivorKills[i][JOCKEY],survivorDmg[i][JOCKEY],
							survivorKills[i][CHARGER],survivorDmg[i][CHARGER],
							survivorKills[i][SPITTER],survivorDmg[i][SPITTER],
							survivorKills[i][BOOMER],survivorDmg[i][BOOMER],
							survivorKills[i][SMOKER],survivorDmg[i][SMOKER],
							survivorKills[i][TANK],survivorDmg[i][TANK]);
		}
	}
}

PrintTankStats(victim) {
	for(new i = 0; i < MAXPLAYERS + 1; i++) {
		if (survivorDmgToTank[i][victim] != 0) {
			PrintToChatAll("%N %d", i, survivorDmgToTank[i][victim]);
			survivorDmgToTank[i][victim] = 0; //reset
		}
	}
	
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	ResetStats(0,0);
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetClientOfUserId(GetEventInt(event,"userid"));
	if (id != 0) {
		if (GetClientTeam(id) == TEAM_INFECTED) {
			SIClients[id] = true;
			SIHealth[id] = GetEntProp(id, Prop_Send, "m_iMaxHealth") & 0xffff;
		}
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
	GetClientModel(victim, victimName, sizeof(victimName));
	new victimTeam = GetClientTeam(victim);
	
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	
	/*
	Conditions for collection
			1) Don't collect damage by SI
			2) Don't collect damage by Console/World
			3) Collect damage from bot survivors and player survivors
	*/
	
	if (attacker != 0) { //check if the attacker is Console/World if not then move forward
		new attackerTeam = GetClientTeam(attacker);
		if(attackerTeam == TEAM_SURVIVOR) { //survivor damage including bots
			survivor[attacker] = true;
			//record survivor attack
			if ((hitgroup == 1) && (victimTeam != TEAM_SURVIVOR)) {
				survivorHeadShots[attacker]++;
				//gets rid of number before SI name
				if (victimName[0] == '(') {
					victimName[0] = ' ';
					victimName[1] = ' ';
					victimName[2] = ' ';
				}
			}
			
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
						if ((SIHealth[victim] <= 0) || (victimRemainingHealth > SIHealth[victim])) {
							
							survivorDmgToTank[attacker][victim] += SIHealth[victim];
							survivorDmg[attacker][TANK] += SIHealth[victim];
							SIClients[victim] = false;
							SIHealth[victim] = 0;
							PrintTankStats(victim);
							survivorKills[attacker][TANK]++;
						}
						else {
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
	
}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	
	new damage = 0;
	new hitgroup;

	//Only process if the player is a legal attacker (i.e., a player)
	if (attacker && attacker <= MaxClients)
	{
		new attackerTeam = GetClientTeam(attacker);
		if(attackerTeam == TEAM_SURVIVOR) {
			survivor[attacker] = true;
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
}

public Event_InfectedDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	//attacker info
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	

	//Only process if the player is a legal attacker (i.e., a player)
	if (attacker && attacker <= MaxClients)
	{
		new attackerTeam = GetClientTeam(attacker);
		if(attackerTeam == TEAM_SURVIVOR) 
		{
			survivorKills[attacker][COMMON]++;
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	//PrintMVPStats()
}

//--------------------------------------------------
// ResetStats
//!
//! \brief Use this function to reset the kill and damage arrays to zero
//--------------------------------------------------
public Action:ResetStats(client, args) {
	for (new i = 0; i < MAXPLAYERS + 1; i++) {
		for (new j = 0; j < 8; j++) {
			survivorKills[i][j] = 0;
			survivorDmg[i][j] = 0;
			survivorDmgToTank[i][j] = 0;
		}
		survivorHeadShots[i] = 0;
		survivorFFDmg[i] = 0;
		SIClients[i] = false;
		SIHealth[i]  = 0;
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
