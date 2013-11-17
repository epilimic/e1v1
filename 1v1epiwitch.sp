#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
#include <colors>
 
 
#define TEAM_SURVIVOR           2 
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8

static const String:CLASSNAME_INFECTED[]  	= "infected";
static const String:CLASSNAME_WITCH[]	 	= "witch";

new Handle: hPluginEnabled;
new bool: bPluginEnabled;

//new Handle: hWitchDamage;       // how much damage the witch does to survivor (in total)
//new float: fWitchDamage;               

new iDidDamageWitch;            // for keeping track how much 'crown damage' was

public Plugin:myinfo = 
{
	name = "epilimic's 1v1 witch crown tracker",
	author = "Tabun - THE MAN",
	description = "Displays some damage tracking info.",
	version = "0.1a",
	url = "nope"
}


public OnPluginStart()
{
        // Cvars
        hPluginEnabled = CreateConVar("sm_witchreport_enabled", "1", "Enable the damage report for witch damage.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
        bPluginEnabled = GetConVarBool(hPluginEnabled);
        
        //hWitchDamage = CreateConVar("sm_easywitch_damage", "100.0", "Damage witch does on first and only strike." );
        //fWitchDamage = float: GetConVarFloat(hWitchDamage);
        
        HookEvent("witch_killed", witch_killed); 
        HookEvent("infected_hurt" ,InfectedHurt_Event, EventHookMode_Post);
	
        HookEvent("round_start", round_start);
        HookEvent("round_end", round_end);
        HookEvent("finale_win", round_end);
        HookEvent("mission_lost", round_end);
        HookEvent("map_transition",  round_end);
        
        // prevent witch from doing the incap -- nope, done with onTakeDamage
        //HookEvent("player_incapacitated_start", Event_WitchIncap);
    
        iDidDamageWitch = 0;
}

public OnClientPostAdminCheck(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, CLASSNAME_INFECTED, false) || StrEqual(classname, CLASSNAME_WITCH, false))
	{
		SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

/* -------------------------------
 *      ROUND START / END
 * ------------------------------- */
public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
        bPluginEnabled = GetConVarBool(hPluginEnabled);
        iDidDamageWitch = 0;
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{        
        iDidDamageWitch = 0;
}
public OnMapStart()
{
        bPluginEnabled = GetConVarBool(hPluginEnabled);
        iDidDamageWitch = 0;
}
 

/* --------------------------------------
 *      Catching/reporting dmg to WITCH
 * -------------------------------------- */
public Action:InfectedHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!bPluginEnabled) { return Plugin_Continue; }
    
    // catch damage done to witch
    new victimEntId = GetEventInt(event, "entityid");

    if (IsWitch(victimEntId))
    {
        new attackerId = GetEventInt(event, "attacker");
        new attacker = GetClientOfUserId(attackerId);
        new damageDone = GetEventInt(event, "amount");
        
        if (attackerId && IsClientAndInGame(attacker) && GetClientTeam(attacker) == TEAM_SURVIVOR)
        {
            iDidDamageWitch += damageDone;
        }
    }
    return Plugin_Continue;
}

public Action:witch_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
        if (!bPluginEnabled) { return Plugin_Continue; }
        
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	//crown?
	if (!GetEventBool(event, "oneshot"))
	{
            //miss message
            CPrintToChat(client, "{default}-{blue}e's 1v1{default}- {green}draw!");
            iDidDamageWitch = 0;        // just in case there is more than 1 witch, later
            return Plugin_Continue;
	}
	
	//print a message
	CPrintToChatAll("{default}-{blue}e's 1v1{default}- {olive}Witch {blue}cr0wned for {green}%d {blue}damage!", iDidDamageWitch);
        iDidDamageWitch = 0;            // just in case there is more than 1 witch, later
	
	return Plugin_Continue;
}

/* --------------------------------------
 *     handle witch incapping player
 * -------------------------------------- */

/*
public Event_WitchIncap(Handle:event, const String:n[], bool:dB)
{
        if (!bPluginEnabled) { return Plugin_Continue; }

	new type = GetEventInt(event, "type");
	if (type != 4){ return Plugin_Continue; }       // Witch damage type: 4
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
        PrintToChatAll("witch incaps player.");
    
        return Plugin_Changed; 
}
*/

/* --------------------------------------
 *     take damage mod ?
 * -------------------------------------- */

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
        if (!bPluginEnabled) { return Plugin_Continue; }
        
	if (!inflictor || !attacker || !victim || !IsValidEdict(victim) || !IsValidEdict(inflictor)) { return Plugin_Continue; }
	
	decl String:classname[64];
	//new bool:bHumanAttacker = false;
        new bool:bIsWitchAttack = false;
	
	if (attacker <= MaxClients && IsClientInGame(attacker))
	{
            /*
		do nothing
            */
	}
	else // case: other entity inflicts damage (eg throwable, ability)
	{
		GetEdictClassname(inflictor, classname, sizeof(classname));
		
                if (StrEqual(classname, CLASSNAME_WITCH))
                {
                    bIsWitchAttack = true;
                }
	}
	
	
	new teamvictim;
	new bool:bHumanVictim = (victim <= MaxClients && IsClientInGame(victim));
	
	if (bHumanVictim) // case: attacker witch or common, victim human player
	{
		teamvictim = GetClientTeam(victim);
		if (teamvictim == TEAM_SURVIVOR)
		{
            // this is prolly where we want to do shit
            if (bIsWitchAttack)
            {
                // kill witch
                CPrintToChatAll("{default}-{blue}e's 1v1{default}- {blue}you only did {green}%d {blue}damage to the {olive}witch{blue}.", iDidDamageWitch);
                iDidDamageWitch = 0;
                
                return Plugin_Continue;
            }
		}
	}
        
        return Plugin_Continue;
}


/* --------------------------------------
 *     shared functions
 * -------------------------------------- */
 
bool:IsClientAndInGame(index)
{
    return (index > 0 && index <= MaxClients && IsClientInGame(index));
}

stock bool:IsWitch(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "witch");
    }
    return false;
}