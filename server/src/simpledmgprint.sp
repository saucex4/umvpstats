/* *********************************
* Prints out damage and various other event variables, as well as distance to target
* KNOW ISSUE: Tank death spits out garbage damage information.
********************************** */

#pragma semicolon 1

#include <sourcemod>

// global variables
new bool:g_enabled = false;

public Plugin:myinfo = 
{
		   name = "Simple Damage Print",
		 author = "sauce",
	description = "Prints out damage dealt",
		version = "1.0"
};

public OnPluginStart()
{
	HookEvent("infected_hurt", Event_InfectedHurt);
	HookEvent("player_hurt", Event_PlayerHurt);
	RegConsoleCmd("sm_dmgprinton", Command_DmgPrintOn);
	RegConsoleCmd("sm_dmgprintoff", Command_DmgPrintOff);
}

public Action:Command_DmgPrintOn(client, args) {
	PrintToChatAll("\x01Simple Damage Print \x05ENABLED.");
	g_enabled = true;
}

public Action:Command_DmgPrintOff(client, args) {
	PrintToChatAll("\x01Simple Damage Print \x04DISABLED.");
	g_enabled = false;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_enabled) {
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		new victim   = GetClientOfUserId(GetEventInt(event,"userid"));
		new victimRemainingHealth = GetClientHealth(victim);
		new victimMaxHealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff;
		new damage   = GetEventInt(event, "dmg_health");
		new hitgroup = GetEventInt(event, "hitgroup");
		
		if (IsClientAlive(attacker) && IsClientAlive(victim)) {
			new Float:attackerOrigin[3];
			new Float:victimOrigin[3];
			
			GetClientAbsOrigin(attacker,attackerOrigin);
			GetClientAbsOrigin(victim,victimOrigin);
			new Float:distance = GetVectorDistance(attackerOrigin, victimOrigin);
			PrintToChatAll("\x04att: \x01%N \x04vic: \x01%N \x04(\x01%d/%d\x04) \x05dmg \x01= \x03%d \x05hitgroup \x01= \x03%d \x05dist. \x01= \x03%f",attacker, victim, victimRemainingHealth, victimMaxHealth, damage, hitgroup, distance);
		}
	}
}

public Event_InfectedHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	if (g_enabled) {
		new attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
		new hitgroup = GetEventInt(event, "hitgroup");
		new damage = GetEventInt(event, "amount");
		new victim = GetEventInt(event, "entityid");
		new model_id = GetEntProp(victim, Prop_Send, "m_nModelIndex");
		if (IsClientAlive(attacker)) {
			new Float:attackerOrigin[3];
			new Float:victimOrigin[3];
			GetClientAbsOrigin(attacker,attackerOrigin);
			GetEntPropVector(GetEventInt(event,"entityid"), Prop_Send, "m_vecOrigin", victimOrigin);
			new Float:distance = GetVectorDistance(attackerOrigin, victimOrigin);
			PrintToChatAll("\x04att: \x01%N \x05dmg \x01= \x03%d \x05hitgroup \x01= \x03%d \x05dist. \x01= \x03%f mid = %d",attacker, damage, hitgroup, distance, model_id);
		}
	}
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

