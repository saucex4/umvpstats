/**********************************
* This is just a test playground for various events in l4d2.
***********************************/


#pragma semicolon 1

#include <sourcemod>

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
	
	
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new victimteam = GetClientTeam(victim);
	new health = GetEventInt(event, "health");
	new maxhealth = GetEntProp(victim, Prop_Send, "m_iMaxHealth") & 0xffff;
	
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new attackerteam = GetClientTeam(attacker);
	new attackerentid = GetEventInt(event, "attackerentid");
	new damagetype = GetEventInt(event,"type");
	new attackerhealth = GetClientHealth(attacker);
	new attackermaxhealth = GetEntProp(attacker, Prop_Send, "m_iMaxHealth") & 0xffff;
	
	new String:weapon[50]; 
	GetEventString(event, "weapon", weapon, 50);
	new damage = GetEventInt(event, "dmg_health");
	
	new hitgroup = GetEventInt(event,"hitgroup");
	// \x01 or \x02 default
	// \x03 light-green
	// \x04 orange 
	// \x05  green
	PrintToChatAll("\x03%d \x01dmg to \x04[T:%d][cid:%d] %N (%d/%d) \x01by  \x05[T:%d][cid:%d][eid:%d] %N (%d/%d) with %s : Hitgroup = %d, type = %d", damage, victimteam, victim, victim, health, maxhealth, attackerteam, attacker, attackerentid, attacker, attackerhealth, attackermaxhealth, weapon, hitgroup, damagetype);

}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weapon[50]; 
	GetEventString(event, "weapon", weapon, 50);
	if (GetEventBool(event,"headshot")) {
		PrintToChatAll("\x05HEADSHOT! \x04[%d] %N \x01was killed by %N with %s", victim, victim, attacker, weapon);
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

