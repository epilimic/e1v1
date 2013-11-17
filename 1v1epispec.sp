#include <sourcemod>
#include <sdktools>
public OnClientPutInServer(client) {
if (GetTeamClientCount(3) >= 1 && GetTeamClientCount(2) >= 1){
ChangeClientTeam(client, 1);
}
}