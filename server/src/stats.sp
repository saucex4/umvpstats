/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>
new bool:survivor[MAXPLAYERS + 1];    // active survivors
new survivorKills[MAXPLAYERS + 1][8]; // stores the kills for each survivor for each SI type
new survivorDmg[MAXPLAYERS + 1][8];   // stores the kills for each survivor for each SI type
								      // 0) common 1) hunter 2) jockey 3) charger 4) spitter 5) boomer 6) smoker 7) tank
new survivorHeadShots[MAXPLAYERS + 1]; // headshot counter
new survivorFFDmg[MAXPLAYERS + 1];     // friendly fire counter
new SIHealth[MAXPLAYERS + 1];         // tracks SI + Tank health

// multiple tank support variables
new bool:SIClients[MAXPLAYERS + 1];   // current clients that are SI
new survivorDmgToTank[MAXPLAYERS + 1][MAXPLAYERS +1]; // tracks individual dmg to tank by survivor for multiple tank support

// Constants for different SI types
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

// Other vars
new roundEnded = false;
new collectStats = false;

public Plugin:myinfo = {
		   name = "stats",
		 author = "sauce",
	description = "Stats for survival kills",
		version = "0.0.1"
};


public OnPluginStart() {
	
	//events to hook into
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("survival_round_start", Event_RoundStart);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	
	//console commands
	RegConsoleCmd("sm_stats", Command_Stats); // accepted args "!stats <name>, !stats all, !stats mvp, !stats 
	RegConsoleCmd("sm_resetstats", ResetStats);
}

/********** COMMAND FUNCTIONS ***********/

public Action:Command_Stats(client, args) {
	new String:arg1[33], String:arg2[33];
	new clientToPrint;
	
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
		else { // prints a specific player's stats summarized
			// check to see if name matches to a client
			clientToPrint = FindSurvivorClient(arg1);
			if(clientToPrint != -1) {
				PrintStats(client, clientToPrint, false);
			}
			else {
				PrintToChat(client,"%s not found", arg1);
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
			else { // print a specific player's stats with detail
				clientToPrint = FindSurvivorClient(arg1);
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

bool:ExtendStr(String:str, String:buffer, length, bool:pre=true, const String:insert[]=" ") {
	if (length > 0) {
		new howmany = length - strlen(str);
		new String:prefix[howmany];
		
		for (new i = 0; i < howmany; i++) {
			prefix[i] = insert;
		}
		if (pre) {
			StrCat(buffer, length, prefix);
			StrCat(buffer, length, str);
		}
		else {
			StrCat(buffer, length, str);
			StrCat(buffer, length, prefix);
		}
		return true;
	}
	return false;
} 

PrintStats(printToClient, option, bool:detail ) {
	// client2 values
	// 100 = print mvp
	//   0 = print all summarized stats
	if (detail) {
		switch (option) {
			case 0: {
			/*
			Chat: !stats detail
			 1111111111111111111111111111111111111111111111111
			1name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
			2SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
			3name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
			4SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
			5name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
			6SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
			7name567890123456789 SI: XXX% CI: XXX% Tanks: XXX%
			8SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
			9=================================================
			0SI:XXXX(XXXXXXX) CI:XXXX(XXXXXXX) T:XXXX(XXXXXXX)
			*/
			}
			case 10000: {
			/*
			Chat: !stats mvp detail
			 1111111111111111111111111111111111111111111111111
			1MVP:name567890123 (1)T:XXX% (2)SI:XXX% (3)CI:XXX% 
			2FF: XXX HS: XXXXX Total Dmg: XXXXXX
			3name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			4FF: XXX HS: XXXXX Total Dmg: XXXXXX
			5name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			6FF: XXX HS: XXXXX Total Dmg: XXXXXX
			7name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			8FF: XXX HS: XXXXX Total Dmg: XXXXXX
			*/
			}
			default: {
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
			}
		}
	}
	else if(!detail) {
		switch (option) {
			case 0: {
			/*
			Chat: !stats
			 1111111111111111111111111111111111111111111111111
			1name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
			2name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
			3name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
			4name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
			5=================================================
			6[SI]: XXX Kills [CI]: XXXXX Kills [T]: XXX Kills
			7
			8
			
			*/
			}
			case 100: {
			/*
			Chat: !stats mvp
			 1111111111111111111111111111111111111111111111111
			1MVP:name567890123 (1)T:XXX% (2)SI:XXX% (3)CI:XXX% 
			2name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			3name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			4name5678901234567 (1)T:XXX% (1)SI:XXX% (1)CI:XXX%
			5=================================================
			6[SI]: XXX Kills [CI]: XXXXX Kills [T]: XXX Kills
			7
			8
			*/
			}
			default: {
			/*
			Chat: !stats <name>
			 1111111111111111111111111111111111111111111111111
			1name456789012345678 SI: XXX% CI: XXX% Tanks: XXX%
			2=================================================
			3[SI]: XXX Kills [CI]: XXXXX Kills [T]: XXX Kills
			4
			5
			6
			7
			8
			*/
			}
		}
	}
	
	if (printToClient == 0) { // print to everyone
	
	}
	else if(printToClient > 0) { // print to specific client
	
	}
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
		survivor[i] = false;
		SIClients[i] = false;
		SIHealth[i]  = 0;
	}
}



/********** EVENT FUNCTIONS ***********/

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	ResetStats(0,0);
	roundEnded = false;
	collectStats = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!roundEnded) {
		PrintStats(0, 10000,false);
		roundEnded = true;
	}
	collectStats = false;
}

public Event_PlayerFirstSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new id = GetClientOfUserId(GetEventInt(event,"userid"));
	if (id != 0) { // track health for SI
		if (GetClientTeam(id) == TEAM_INFECTED) {
			SIClients[id] = true;
			SIHealth[id] = GetEntProp(id, Prop_Send, "m_iMaxHealth") & 0xffff;
		}
	}
	else if (id > 0) { // actively collecting stats
		if (GetClientTeam(id) == TEAM_SURVIVOR) {
			survivor[id] = true;
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
	
	if ((attacker != 0) && collectStats) { //check if the attacker is Console/World if not then move forward
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
	if (attacker && (attacker <= MaxClients) && (collectStats))
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
	if (attacker && (attacker <= MaxClients) && collectStats)
	{
		new attackerTeam = GetClientTeam(attacker);
		if(attackerTeam == TEAM_SURVIVOR) 
		{
			survivorKills[attacker][COMMON]++;
		}
	}
}




/********** HELPER FUNCTIONS ***********/

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


PrintTankStats(victim) {
	for(new i = 0; i < MAXPLAYERS + 1; i++) {
		if (survivorDmgToTank[i][victim] != 0) {
			/*
			 1111111111111111111111111111111111111111111111111
			1name56789012345678901234567890 XXXX Damage (XXX%)
			2name56789012345678901234567890 XXXX Damage (XXX%)
			3name56789012345678901234567890 XXXX Damage (XXX%)
			4name56789012345678901234567890 XXXX Damage (XXX%)
			*/
			PrintToChatAll("%N %d", i, survivorDmgToTank[i][victim]);
			survivorDmgToTank[i][victim] = 0; //reset
		}
	}
	
}

FindSurvivorClient(String:name[33]) {
	for (new i = 1; i < MAXPLAYERS +1; i++) {
		if (GetClientTeam(i) == TEAM_SURVIVOR) {
			new String:clientName[33];
			GetClientName(i, clientName, sizeof(clientName));
			if (StrContains(name, clientName, false) == 0) {
				return i;
			}
		}
	}
	return -1; //doesn't exist
}