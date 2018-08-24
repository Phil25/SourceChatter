#pragma semicolon 1

#include <sourcechatter>

#undef REQUIRE_PLUGIN
#include <ccc>
#include <updater>


#define PLUGIN_VERSION	"1.0.0"

#define UPDATE_URL	"https://phil25.github.io/SourceChatter/game/addons/sourcemod/updatefile_generic.txt"

#define LIB_SC "SourceChatter"
#define LIB_CCC "ccc"
#define LIB_UPDATER "updater"


bool g_bCore = false;
bool g_bCCC = false;
bool g_bTeamChat[MAXPLAYERS+1] = {false, ...};


public Plugin myinfo = {
	name		= "SourceChatter Generic Events",
	author		= "Phil25",
	description	= "Source Chatter module - generic Source engine events",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=310211"
};


public void OnPluginStart(){
	CreateConVar("sm_sourcechatter_generic_version", PLUGIN_VERSION, "Current Source Chatter generic module version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	AddCommandListener(Event_OnSayAll, "say");
	AddCommandListener(Event_OnSayTeam, "say_team");

	HookEvent("player_say", Event_PlayerSay, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Post);
}

public void OnAllPluginsLoaded(){
	g_bCore = LibraryExists(LIB_SC);
	g_bCCC = LibraryExists(LIB_CCC);

	if(LibraryExists(LIB_UPDATER))
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryAdded(const char[] sLibName){
	if(StrEqual(sLibName, LIB_SC))
		g_bCore = true;

	else if(StrEqual(sLibName, LIB_CCC))
		g_bCCC = true;

	else if(StrEqual(sLibName, LIB_UPDATER))
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryRemoved(const char[] sLibName){
	if(StrEqual(sLibName, LIB_SC))
		g_bCore = false;

	else if(StrEqual(sLibName, LIB_CCC))
		g_bCCC = false;
}

public Action Event_OnSayAll(int client, const char[] sCmd, int args){
	g_bTeamChat[client] = false;
	return Plugin_Continue;
}

public Action Event_OnSayTeam(int client, const char[] sCmd, int args){
	g_bTeamChat[client] = true;
	return Plugin_Continue;
}

public Action Event_PlayerSay(Handle hEvent, const char[] sName, bool bDontBroadcast){
	if(!g_bCore)
		return Plugin_Continue;

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	char sMsg[255];
	GetEventString(hEvent, "text", sMsg, 255);

	UploadSayMessage(client, sMsg, g_bTeamChat[client]);
	return Plugin_Continue;
}

void UploadSayMessage(int client, const char[] sMsg, bool bTeam=false){
	if(client == 0){
		SC_PushMessage("[b]Console[/b]: %s", sMsg);
		return;
	}

	if(!g_bCCC){
		SC_PushMessage("%s%s[b][color=#%06x]%N[/color][/b]: %s",
			IsPlayerAlive(client) ? "" : "*DEAD* ",
			bTeam ? "(TEAM) " : "",
			SC_GetTeamColorOfClient(client), client, sMsg
		);
		return;
	}

	char sTag[32];
	CCC_GetTag(client, sTag, 32);
	int	iTagColor = CCC_GetColor(client, CCC_TagColor);

	SC_PushMessage("%s%s[b][color=#%06x]%s[/color][color=#%06x]%N[/color][/b]: %s",
		IsPlayerAlive(client) ? "" : "*DEAD* ",
		bTeam ? "(TEAM) " : "",
		iTagColor, sTag, SC_GetTeamColorOfClient(client), client, sMsg
	);
}

public void OnClientConnected(int client){
	SC_PushMessage("[color=#%06x][i][b]%N[/b] joined the game.[/i][/color]", SC_GetInfoColor(), client);
}

public Action Event_PlayerDisconnect(Handle hEvent, const char[] sName, bool bDontBroadcast){
	if(!g_bCore)
		return Plugin_Continue;

	char sPlayerName[MAX_NAME_LENGTH], sReason[32];
	GetEventString(hEvent, "name", sPlayerName, MAX_NAME_LENGTH);
	GetEventString(hEvent, "reason", sReason, 32);

	SC_PushMessage("[color=#%06x][i][b]%s[/b] left the game. (%s)[/i][/color]", SC_GetInfoColor(), sPlayerName, sReason);
	return Plugin_Continue;
}

public Action Event_PlayerChangeName(Handle hEvent, const char[] sName, bool bDontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client == 0)
		return Plugin_Continue;

	char sOld[MAX_NAME_LENGTH], sNew[MAX_NAME_LENGTH];
	GetEventString(hEvent, "oldname", sOld, MAX_NAME_LENGTH);
	GetEventString(hEvent, "newname", sNew, MAX_NAME_LENGTH);

	int iColor = SC_GetTeamColorOfClient(client);
	SC_PushMessage("* [color=#%06x][b]%s[/b][/color] changed name to [color=#%06x][b]%s[/b][/color]", iColor, sOld, iColor, sNew);

	return Plugin_Continue;
}
