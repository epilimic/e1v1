#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <left4downtown>

new tank;
new rock;
new bool:waitingForBoomer = false;
new Float:rockVel[3];
new Float:bpos[3];
new Float:bangles[3];
new Handle: hSDKCallSetClass = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "boomer throw",
	author = "Pan Xiaohai <- is shitty",
	description = "tanks throw BOOMERS - for epilimic's 1v1",
	version = "buttsecs",
	url = "http://buttsecs.org"
}

CheatCommand(const String:command[]) {
        new commandFlags = GetCommandFlags(command);
        SetCommandFlags(command, commandFlags & ~FCVAR_CHEAT);
        FakeClientCommand(tank, "%s", command);
        SetCommandFlags(command, commandFlags);
}

CreateBoomer() {
	CheatCommand("z_spawn boomer auto");

	new dude = CreateFakeClient("InfectedBot");
	if (!dude) return;

	ChangeClientTeam(dude, 3);
	CreateTimer(0.1, KickBitch, dude);

//	SDKCall(hSDKCallSetClass, dude, 2);
//	PrintToChatAll("%d zc", GetEntProp(dude, Prop_Send, "m_zombieClass"));
}

public Action:KickBitch(Handle:timer, any:client) {
	KickClient(client);
}

public Action:player_Death(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client)) {
		KickClient(client);
	}
}

public OnPluginStart() {
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(LoadGameConfigFile("l4d2_random"), SDKConf_Signature, "SetClass");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	hSDKCallSetClass = EndPrepSDKCall();

	HookEvent("ability_use", ability_use);
	HookEvent("player_death", player_Death);
}

public Action:ability_use(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[32];
	GetEventString(event, "ability", s, 32);
	if(StrEqual(s, "ability_throw", true))
	{
		tank = GetClientOfUserId(GetEventInt(event, "userid"));
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (tank && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum")>=0)
	{
		rock=entity;
		CreateTimer(0.01, TraceRock, _, TIMER_REPEAT);
	} else
	if (StrEqual(classname, "boomer") && waitingForBoomer) {
		waitingForBoomer = false;
		CreateTimer(0.01, Timed_TeleportBoomer, entity);
		RemoveEdict(rock);
	}
}

public Action:Timed_TeleportBoomer(Handle:timer, any:entity) {
		ScaleVector(rockVel, 2.0);
		TeleportEntity(entity, bpos, bangles, rockVel);
}

stock countBoomers() {
	new count = 0;
	for (new i = 1; i < MaxClients; i++) {
		if (IsValidEntity(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 2 && GetClientTeam(i) == 3 && IsClientInGame(i) && IsFakeClient(i)) {
			count++;
		}
	}
	return count;
}

public Action:TraceRock(Handle:timer, any:data) {	
	if (IsValidEdict(rock))
	{
		GetEntPropVector(rock, Prop_Send, "m_vecVelocity", rockVel);
		new Float:v = GetVectorLength(rockVel);

		if (v <= 500.0)
		{	
			return Plugin_Continue;
		}

		GetEntPropVector(rock, Prop_Send, "m_vecOrigin", bpos);
		bpos[2] += 60.0;
		GetVectorAngles(rockVel, bangles);
//		GetEntPropVector(rock, Prop_Send, "m_angRotation", bangles);

		waitingForBoomer = true;
//		if (countBoomers() >= 4) {
			CreateBoomer();
//		}
//		L4D2_SpawnSpecial(2, bpos, bangles);
	}
	return Plugin_Stop;
}

public Action:L4D_OnSpawnSpecial(&zombieClass, const Float:vector[3], const Float:qangle[3]) {
	if (zombieClass == 2 && waitingForBoomer) {
	}
}

stock bool:StuckCheck(ent,  Float:pos[3])
{
	new Float:vAngles[3] = { -90.0, 0.0, 0.0 };
	new Float:endPos[3];

	new Handle:trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, ent);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(endPos, trace);
		if(GetVectorDistance(endPos, pos) > 100.0)return true;
	}
	return false;
}
 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}