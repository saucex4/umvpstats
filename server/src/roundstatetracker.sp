#pragma semicolon 1

#include <sourcemod>

new Handle:g_roundTrackerState = INVALID_HANDLE;

public Plugin:myinfo = {
		   name = "Round State Tracker",
		 author = "sauce",
	description = "Tracks the state of a round in L4D2",
		version = "0.0.1"
};


public OnPluginStart() {
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	HookEvent("round_start_pre_entity",Event_RoundStartPreEntity);
	HookEvent("round_start_post_nav",Event_RoundStartPostNav);
	HookEvent("round_end",Event_RoundEnd);
	HookEvent("scavenge_round_start",Event_ScavengeRoundStart);
	HookEvent("scavenge_round_halftime",Event_ScavengeRoundHalfTime);
	HookEvent("scavenge_round_finished",Event_ScavengeRoundFinished);
	HookEvent("versus_round_start",Event_VersusRoundStart);
	HookEvent("survival_round_start",Event_SurvivalRoundStart);
	
	g_roundTrackerState = CreateConVar("s3_roundTrackerState","nothing","What is the current state of the round");
}

public OnMapStart() {
	SetGameRoundState("mapstarted");
}

public OnMapEnd() {
	SetGameRoundState("mapended");
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("roundfreezeend");
}

public Event_RoundStartPreEntity(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("roundstartpreentity");
}

public Event_RoundStartPostNav(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("roundstartpostnav");
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("roundend");
}

public Event_ScavengeRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("scavengeroundstart");
}

public Event_ScavengeRoundHalfTime(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("scavengeroundhalftime");
}

public Event_ScavengeRoundFinished(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("scavengeroundfinished");
}

public Event_VersusRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("versusroundstart");
}

public Event_SurvivalRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	SetGameRoundState("survivalroundstart");
}

SetGameRoundState(const String:roundState[]) {
	SetConVarString(g_roundTrackerState, roundState);
}