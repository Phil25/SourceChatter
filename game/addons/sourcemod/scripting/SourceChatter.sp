#pragma semicolon 1

//#define VOICE
//#define DEBUG
//#define DEBUG_SCOREBOARD


#include <sourcechatter>

#include <sdktools>
#include <geoip>

#if defined VOICE
#include <voicehook2>
#endif

#undef REQUIRE_PLUGIN
#include <updater>


#define PLUGIN_VERSION	"1.0.1"

#define UPDATE_URL	"https://phil25.github.io/SourceChatter/game/addons/sourcemod/updatefile.txt"

#define CONS_PREFIX	"[SC]"
#define CHAT_PREFIX	"\x03[SC]\x01"

#define Q_SIZE		511
#define TOKEN_SIZE	16

#define COLOR_LEN	6
#define MSG_LEN		210
#define MSG_LEN_ESC	421
#define NAM_LEN_ESC	65

#define UPDATE_INTERVAL	2.0

#define TABLE_CHAT		"sc_chat"
#define TABLE_USERS		"sc_users"
#define TABLE_PLAYERS	"sc_players"

#define CHATTER_FILTER_FLAGS COMMAND_FILTER_NO_MULTI|COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS

#define SC_DEFAULT_TEAM0	2236962 // hex: "222222"
#define SC_DEFAULT_TEAM1	11711154 // hex: "b2b2b2"
#define SC_DEFAULT_TEAM2	12845056 // hex: "c40000"
#define SC_DEFAULT_TEAM3	19199 // hex: "004aff"
#define SC_DEFAULT_INFO		5000268 // hex: "4c4c4c"


enum EClientAttrib{
	EClientAttrib_Team,
	EClientAttrib_Score,
	EClientAttrib_Class,
	EClientAttrib_Ping,
	EClientAttrib_Status,
	EClientAttrib_SIZE
};

int g_iClientAttribs[MAXPLAYERS+1][EClientAttrib_SIZE];
char g_sAttribNames[EClientAttrib_SIZE][16] = {
	"team", "score", "class", "ping", "status"
};

/* Used to store temporary attributes before updating a user with them */
char g_sChatterAttribNames[Chatter_SIZE][16] = {
	"auth64", "flags", "name", "tag", "tag_color", "added_by"
};
char g_sChatterAttribDefaults[Chatter_SIZE][MAX_NAME_LENGTH] = {
	"0", "", "unspecified", "", "ffffff", "0"
};

/* TF2 class enum offsets numbered accoring to their appearance in-game */
int g_iTF2Class[10] = {0, 1, 8, 2, 4, 7, 5, 3, 9, 6};

/* Team colors */
int g_iColors[4] = {SC_DEFAULT_TEAM0, SC_DEFAULT_TEAM1, SC_DEFAULT_TEAM2, SC_DEFAULT_TEAM3};
int g_iInfoColor = SC_DEFAULT_INFO;

ConVar g_hCvarToken = null;
char g_sToken[TOKEN_SIZE] = "none";

ConVar g_hCvarGroupFlag = null;
int g_iGroupFlag = 0; // 0 = unset

Database hDb = null;
Handle g_hUpdateTimer = null;
int g_iResource = -1;

bool g_bRegistered[MAXPLAYERS+1] = {false, ...};
char g_sAuth64[MAXPLAYERS+1][24];
char g_sIp[MAXPLAYERS+1][16];
char g_sCountry[MAXPLAYERS+1][3];
int g_iUserId[MAXPLAYERS+1];

bool g_bNewName[MAXPLAYERS+1] = {false, ...};
bool g_bTalking[MAXPLAYERS+1] = {false, ...};

/* Mod-specific stuff */
char g_sPropScore[32] = "m_iScore";


public Plugin myinfo = {
	name		= "SourceChatter",
	author		= "Phil25",
	description	= "Webpanel in-game chat replication.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?t=310211"
};


public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErrMax){
	RegPluginLibrary("SourceChatter");

	CreateNative("SC_PushMessage", Native_SC_PushMessage);
	CreateNative("SC_GetTeamColor", Native_SC_GetTeamColor);
	CreateNative("SC_GetTeamColorOfClient", Native_SC_GetTeamColorOfClient);
	CreateNative("SC_SetTeamColor", Native_SC_SetTeamColor);
	CreateNative("SC_GetInfoColor", Native_SC_GetInfoColor);
	CreateNative("SC_SetInfoColor", Native_SC_SetInfoColor);

	CreateNative("SC_AddChatter", Native_SC_AddChatter);
	CreateNative("SC_RemoveChatter", Native_SC_RemoveChatter);
	CreateNative("SC_GetChatterAttrib", Native_SC_GetChatterAttrib);
	CreateNative("SC_SetChatterAttrib", Native_SC_SetChatterAttrib);
	CreateNative("SC_UnsetChatterAttrib", Native_SC_UnsetChatterAttrib);
	CreateNative("SC_UnsetAllChatterAttribs", Native_SC_UnsetAllChatterAttribs);
	CreateNative("SC_CommitChatterEdit", Native_SC_CommitChatterEdit);

	return APLRes_Success;
}

public void OnPluginStart(){
	LoadTranslations("common.phrases");
	SetupModSpecificStuff();
	RegisterCvars();
	Database.Connect(Callback_OnConnect, "source_chatter");
	RegisterCommands();
	HookEvent("player_changename", Event_PlayerChangeName, EventHookMode_Post);
}

public void OnAllPluginsLoaded(){
	if(LibraryExists("updater"))
		Updater_AddPlugin(UPDATE_URL);
}

public void OnLibraryAdded(const char[] sLibName){
	if(StrEqual(sLibName, "updater"))
		Updater_AddPlugin(UPDATE_URL);
}

/* this function sets up engine-specific properties */
void SetupModSpecificStuff(){
	EngineVersion iVersion = GetEngineVersion();
	switch(iVersion){
		case Engine_TF2:
			strcopy(g_sPropScore, sizeof(g_sPropScore), "m_iTotalScore");
	}
}

void RegisterCvars(){
	CreateConVar("sm_sourcechatter_version", PLUGIN_VERSION, "Current Source Chatter version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	g_hCvarToken = CreateConVar("sm_sourcechatter_token", "none", "Server token", FCVAR_NOTIFY);
	g_hCvarToken.AddChangeHook(ConVarChange_Token);
	g_hCvarToken.GetString(g_sToken, TOKEN_SIZE);

	g_hCvarGroupFlag = CreateConVar("sm_sourcechatter_group", "", "Flag string identifying a group member", FCVAR_NOTIFY);
	g_hCvarGroupFlag.AddChangeHook(ConVarChange_GroupFlag);

	char sGroupFlag[8];
	g_hCvarGroupFlag.GetString(sGroupFlag, 8);
	g_iGroupFlag = ReadFlagString(sGroupFlag);
}

void RegisterCommands(){
	RegServerCmd("say_as", Command_SayAs, "Run chat message from unconnected person.", ADMFLAG_RCON);
	RegServerCmd("cmd_as", Command_CmdAs, "Run command from unconnected person.", ADMFLAG_RCON);

	RegAdminCmd("sm_addchatter", Command_AddChatter, ADMFLAG_ROOT);
	RegAdminCmd("sm_removechatter", Command_RemoveChatter, ADMFLAG_ROOT);
	RegAdminCmd("sm_editchatter", Command_EditChatter, ADMFLAG_ROOT);
}

public void ConVarChange_Token(ConVar hCvar, const char[] sOld, const char[] sNew){
	if(strlen(sNew) > TOKEN_SIZE)
		ThrowError("Cannot change to token of size larger than %d", TOKEN_SIZE);
	strcopy(g_sToken, TOKEN_SIZE, sNew);
}

public void ConVarChange_GroupFlag(ConVar hCvar, const char[] sOld, const char[] sNew){
	g_iGroupFlag = ReadFlagString(sNew);
}

public void OnMapStart(){
	g_iResource = GetPlayerResourceEntity();
}

public Action Command_SayAs(int args){
	if(args < 5){
		ReplyToCommand(0, "[SM] Usage: say_as <tag_color_hex> <tag> <name> <flags> <msg> <...>*");
		return Plugin_Handled;
	}

	char[][] sArgs = new char[args][MAX_NAME_LENGTH];
	for(int i = 0; i < args; i++)
		GetCmdArg(i +1, sArgs[i], MAX_NAME_LENGTH);

	char sMsg[255];
	strcopy(sMsg, 255, sArgs[4]);
	for(int i = 5; i < args; i++)
		Format(sMsg, 255, "%s %s", sMsg, sArgs[i]);

	switch(sMsg[0]){
		case '!':
			CmdFromMsg(sArgs[2], sArgs[3], "!", sMsg);

		case '/':{
			CmdFromMsg(sArgs[2], sArgs[3], "/", sMsg);
			return Plugin_Handled;
		}
	}

	ReplaceString(sMsg, 255, " ' ", "'");
	ReplaceString(sMsg, 255, " : ", ":");
	SayAs(sArgs[0], sArgs[1], sArgs[2], sMsg);

	return Plugin_Handled;
}

void SayAs(const char[] sTagColorEx, const char[] sTag, const char[] sName, const char[] sMsg){
	PrintToServer("] %s: %s", sName, sMsg);

	char sTagColor[COLOR_LEN+1]; // failsafe against improper tag color length
	strcopy(sTagColor, COLOR_LEN+1, strlen(sTagColorEx) < COLOR_LEN ? g_sChatterAttribDefaults[Chatter_TagColor] : sTagColorEx);

	PrintToChatAll("\x07%s%s\x01\x04%s\x01 :  \x0700e5e5%s", sTagColor, sTag, sName, sMsg);

	if(strlen(sTag) > 0)
		PushMessage("[b][color=#%s]%s[/color][color=#147500]%s[/color][/b]: %s", sTagColor, sTag, sName, sMsg);
	else PushMessage("[b][color=#147500]%s[/color][/b]: %s", sName, sMsg);
}

public Action Command_CmdAs(int args){
	if(args < 3){
		ReplyToCommand(0, "[SM] Usage: cmd_as <name> <flags> <cmd> <...>*");
		return Plugin_Handled;
	}

	char[][] sArgs = new char[args][MAX_NAME_LENGTH];
	for(int i = 0; i < args; i++)
		GetCmdArg(i +1, sArgs[i], MAX_NAME_LENGTH);

	char sCmd[255];
	strcopy(sCmd, 255, sArgs[2]);
	for(int i = 3; i < args; i++)
		Format(sCmd, 255, "%s %s", sCmd, sArgs[i]);

	CmdAs(sArgs[0], sArgs[1], sCmd);

	return Plugin_Handled;
}

void CmdFromMsg(const char[] sName, const char[] sFlags, const char[] sPrefix, const char[] sMsg){
	char sCmd[255];
	strcopy(sCmd, 255, sMsg);
	ReplaceString(sCmd, 255, sPrefix, "");
	CmdAs(sName, sFlags, sCmd, HasPrefix(sCmd));
}

void CmdAs(const char[] sName, const char[] sFlags, char[] sCmd, bool bHasPrefix=true){
	if(!bHasPrefix)
		Format(sCmd, 255, "sm_%s", sCmd);

	char sCmdName[MAX_NAME_LENGTH]; // get cmd name without arguments
	SplitString(sCmd, " ", sCmdName, MAX_NAME_LENGTH);

	if(!CheckCommandAccessFlags(sCmdName, sFlags)){
		PushMessage("[b]%s[/b]: You have no access to [i]%s[/i].", sName, sCmdName);
		return;
	}

	ServerCommand(sCmd);
	PushMessage("[b]%s[/b] executed: [i]%s[/i]", sName, sCmd);
}

public Action Command_AddChatter(int client, int args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_addchatter <steamid64/player> <flags>* <name>* <tag>* <tagcolor>*");
		return Plugin_Handled;
	}

	Chatter chatter = new Chatter("");

	char sBuffer[MAX_NAME_LENGTH] = "0";
	if(client != 0){
		GetClientAuthId(client, AuthId_SteamID64, sBuffer, MAX_NAME_LENGTH);
		chatter.Set(Chatter_AddedBy, sBuffer);
	}

	if(args > 1){ // flags provided
		GetCmdArg(2, sBuffer, MAX_NAME_LENGTH);
		chatter.Set(Chatter_Flags, sBuffer);

		if(args > 2){ // name provided
			GetCmdArg(3, sBuffer, MAX_NAME_LENGTH);
			chatter.Set(Chatter_Name, sBuffer);

			if(args > 3){ // tag provided
				GetCmdArg(4, sBuffer, MAX_NAME_LENGTH);
				chatter.Set(Chatter_Tag, sBuffer);

				if(args > 4){ // tag color provided
					GetCmdArg(5, sBuffer, MAX_NAME_LENGTH);
					chatter.Set(Chatter_TagColor, sBuffer);
				}
			}
		}
	}

	char sTrg[MAX_NAME_LENGTH];
	GetCmdArg(1, sTrg, MAX_NAME_LENGTH);
	if(IsValidSteamId64(sTrg)){
		chatter.Set(Chatter_Auth, sTrg);
		if(AddChatter(chatter))
			ReplyToCommandEx(client, "Adding %s.", sTrg);
		else ReplyToCommandEx(client, "Cannot add chatter: not connected to database.");

		delete chatter;
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "SteamID64 invalid, matching a player...");
	char sTrgName[MAX_TARGET_LENGTH];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, CHATTER_FILTER_FLAGS, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0){
		ReplyToTargetError(client, iTrgCount);

		delete chatter;
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "Adding %N to chatters...", aTrgList[0]);

	char sAuth64[24];
	GetClientAuthId(aTrgList[0], AuthId_SteamID64, sAuth64, 24);
	if(!IsCharNumeric(sAuth64[0])){
		ReplyToCommandEx(client, "Client not authorized.");

		delete chatter;
		return Plugin_Handled;
	}

	chatter.Set(Chatter_Auth, sAuth64);
	if(AddChatter(chatter))
		ReplyToCommandEx(client, "Adding %s.", sAuth64);
	else ReplyToCommandEx(client, "Cannot add chatter: not connected to database.");

	delete chatter;
	return Plugin_Handled;
}

bool AddChatter(Chatter& chatter){
	if(hDb == null)
		return false;

	char sBuffer[MAX_NAME_LENGTH], sQ[Q_SIZE];
	chatter.Get(Chatter_Auth, sBuffer, MAX_NAME_LENGTH);
	hDb.Format(sQ, Q_SIZE, "INSERT INTO " ... TABLE_USERS ... " VALUES ('%s'", sBuffer);

	for(ChatterAttrib attr = view_as<ChatterAttrib>(1); attr < Chatter_SIZE; ++attr){
		if(!chatter.Get(attr, sBuffer, MAX_NAME_LENGTH))
			strcopy(sBuffer, MAX_NAME_LENGTH, g_sChatterAttribDefaults[attr]);

		hDb.Format(sQ, Q_SIZE, "%!s, '%s'", sQ, sBuffer);
	}
	FormatEx(sQ, Q_SIZE, "%s)", sQ);

#if defined DEBUG
	Debug("Adding chatter: %s", sQ);
	hDb.Query(Callback_OnAddChatter, sQ);
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	return true;
}

public Action Command_RemoveChatter(int client, int args){
	if(args < 1){
		ReplyToCommand(client, "[SM] Usage: sm_removechatter <steamid64/player>");
		return Plugin_Handled;
	}

	char sTrg[MAX_NAME_LENGTH];
	GetCmdArg(1, sTrg, MAX_NAME_LENGTH);
	if(IsValidSteamId64(sTrg)){
		Chatter chatter = new Chatter(sTrg);
		if(RemoveChatter(chatter))
			ReplyToCommandEx(client, "Removing %s from chatters.", sTrg);
		else ReplyToCommandEx(client, "Cannot remove chatter: not connected to database.");

		delete chatter;
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "SteamID64 invalid, matching a player...");
	char sTrgName[MAX_TARGET_LENGTH];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, CHATTER_FILTER_FLAGS, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0){
		ReplyToTargetError(client, iTrgCount);
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "Removing %N from chatters...", aTrgList[0]);

	char sAuth64[24];
	GetClientAuthId(aTrgList[0], AuthId_SteamID64, sAuth64, 24);
	if(!IsCharNumeric(sAuth64[0])){
		ReplyToCommandEx(client, "Client not authorized.");
		return Plugin_Handled;
	}

	Chatter chatter = new Chatter(sAuth64);
	if(RemoveChatter(chatter))
		ReplyToCommandEx(client, "Removing %s from chatters.", sAuth64);
	else ReplyToCommandEx(client, "Cannot remove chatter: not connected to database.");

	delete chatter;
	return Plugin_Handled;
}

bool RemoveChatter(Chatter& chatter){
	if(hDb == null)
		return false;

	char sAuth[24];
	chatter.Get(Chatter_Auth, sAuth, 24);

	char sQ[Q_SIZE];
	hDb.Format(sQ, Q_SIZE, "DELETE FROM " ... TABLE_USERS ... " WHERE auth64='%s'", sAuth);

#if defined DEBUG
	Debug("Removing chatter: %s", sQ);
	hDb.Query(Callback_OnRemoveChatter, sQ);
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	return true;
}

public Action Command_EditChatter(int client, int args){
	if(args < 2){
		ReplyToCommand(client, "[SM] Usage: sm_editchatter <steamid64> <attribname:value> ...*");
		ReplyToCommand(client, "[SM] Attrib names: flags, name, tag, tag_color, added_by; Ex: \"name:Some Name\"");
		return Plugin_Handled;
	}

	Chatter chatter = new Chatter("");
	char sAttrib[64];
	bool bChange = false;
	for(int i = 2; i <= args; ++i){
		GetCmdArg(i, sAttrib, 64);
		if(!SetChatterAttribFromString(chatter, sAttrib))
			ReplyToCommandEx(client, "Omitting incorrect arg: %s", sAttrib);
		else bChange = true;
	}

	if(!bChange){
		ReplyToCommandEx(client, "No attributes selected for update.");

		delete chatter;
		return Plugin_Handled;
	}

	char sTrg[MAX_NAME_LENGTH];
	GetCmdArg(1, sTrg, MAX_NAME_LENGTH);
	if(IsValidSteamId64(sTrg)){
		chatter.Set(Chatter_Auth, sTrg);
		if(chatter.CommitEdit() == 0)
			ReplyToCommandEx(client, "Updating chatter %s.", sTrg);
		else ReplyToCommandEx(client, "Cannot update chatter: not connected to database.");

		delete chatter;
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "SteamID64 invalid, matching a player...");
	char sTrgName[MAX_TARGET_LENGTH];
	int	 aTrgList[MAXPLAYERS], iTrgCount;
	bool bNameMultiLang;

	if((iTrgCount = ProcessTargetString(sTrg, client, aTrgList, MAXPLAYERS, CHATTER_FILTER_FLAGS, sTrgName, sizeof(sTrgName), bNameMultiLang)) <= 0){
		ReplyToTargetError(client, iTrgCount);

		delete chatter;
		return Plugin_Handled;
	}

	ReplyToCommandEx(client, "Updating chatter %N...", aTrgList[0]);

	char sAuth64[24];
	GetClientAuthId(aTrgList[0], AuthId_SteamID64, sAuth64, 24);
	if(!IsCharNumeric(sAuth64[0])){
		ReplyToCommandEx(client, "Client not authorized.");

		delete chatter;
		return Plugin_Handled;
	}

	chatter.Set(Chatter_Auth, sAuth64);
	if(chatter.CommitEdit() == 0)
		ReplyToCommandEx(client, "Updated chatter %s.", sAuth64);
	else ReplyToCommandEx(client, "Cannot update chatter: not connected to database.");

	delete chatter;
	return Plugin_Handled;
}

bool SetChatterAttribFromString(Chatter& chatter, const char[] sAttribString){
	char sParts[2][MAX_NAME_LENGTH];
	if(ExplodeString(sAttribString, ":", sParts, 2, MAX_NAME_LENGTH) != 2)
		return false;

	int iSize = view_as<int>(Chatter_SIZE);
	int i = 0; // start from 1, omit auth
	while(++i < iSize)
		if(StrEqual(g_sChatterAttribNames[i], sParts[0])){
			chatter.Set(view_as<ChatterAttrib>(i), sParts[1]);
			break;
		}

	return i != iSize;
}

int CommitChatterEdit(Chatter& chatter){
	if(hDb == null)
		return 2;

	char sQ[Q_SIZE] = "UPDATE " ... TABLE_USERS ... " SET ";

	bool bChange = false;
	char sValue[MAX_NAME_LENGTH];
	for(ChatterAttrib attr = view_as<ChatterAttrib>(1); attr < Chatter_SIZE; ++attr){ // start 1, omit auth
		if(!chatter.Get(attr, sValue, MAX_NAME_LENGTH))
			continue;

		hDb.Format(sQ, Q_SIZE, "%!s%s %s='%s'", sQ, bChange ? "," : "", g_sChatterAttribNames[attr], sValue);
		bChange = true;
	}

	if(!bChange)
		return 1;

	chatter.Get(Chatter_Auth, sValue, MAX_NAME_LENGTH);
	hDb.Format(sQ, Q_SIZE, "%!s WHERE auth64='%s'", sQ, sValue);

#if defined DEBUG
	Debug("Saving and updating chatter %s: %s", sValue, sQ);
	hDb.Query(Callback_OnSaveAndUpateChatter, sQ);
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	return 0;
}

public void OnClientPutInServer(int client){
	if(!IsFakeClient(client))
		RegisterPlayer(client);
}

public void OnClientDisconnect(int client){
	if(!IsFakeClient(client))
		UnregisterPlayer(client);
}

public Action Event_PlayerChangeName(Handle hEvent, const char[] sName, bool bDontBroadcast){
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_bNewName[client] = true;
	return Plugin_Continue;
}

public Action Timer_UpdatePlayers(Handle hTimer, any aData){
	if(hDb == null){ // stop timer if connection to DB is lost
		g_hUpdateTimer = null;
		return Plugin_Stop;
	}

	UpdatePlayers();
	return Plugin_Continue;
}

void UpdatePlayers(){
	bool bChange = false;
	Transaction hTxn = SQL_CreateTransaction();
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			if(UpdatePlayer(hTxn, i))
				bChange = true;

	if(bChange){
#if defined DEBUG_SCOREBOARD
		Debug("Executing update players transaction");
		hDb.Execute(hTxn, Callback_OnUpdatePlayersSuccess, Callback_OnUpdatePlayersFailure);
#else
		hDb.Execute(hTxn);
#endif
	}else delete hTxn; // ^ deletes handle automatically
}

bool UpdatePlayer(Transaction& hTxn, int client){
	if(!g_bRegistered[client])
		return false;

	char sQ[Q_SIZE];
	FormatEx(sQ, Q_SIZE, "UPDATE " ... TABLE_PLAYERS ... " SET");

	bool bChange = CheckAndAppendName(client, sQ);
	for(EClientAttrib eAttr = view_as<EClientAttrib>(0); eAttr < EClientAttrib_SIZE; eAttr++)
		bChange |= CheckAndAppendAttribute(client, eAttr, sQ, bChange);

	if(!bChange)
		return false;

	FormatEx(sQ, Q_SIZE, "%s WHERE token='%s' AND userid='%d'", sQ, g_sToken, g_iUserId[client]);
	hTxn.AddQuery(sQ);
	return true;
}

/* must be first */
bool CheckAndAppendName(int client, char[] sQ){
	if(!g_bNewName[client])
		return false;

	hDb.Format(sQ, Q_SIZE, "%s name='%N'", sQ, client);
	g_bNewName[client] = false;
	return true;
}

/* check for attributes AFTER the name */
bool CheckAndAppendAttribute(int client, EClientAttrib eAttrib, char[] sQ, bool bChangeSoFar){
	int iNew = FetchAttrib(client, eAttrib);
	if(GetAttrib(client, eAttrib) == iNew)
		return false;

	AppendAttribute(sQ, Q_SIZE, g_sAttribNames[view_as<int>(eAttrib)], iNew, !bChangeSoFar);
	SetAttrib(client, eAttrib, iNew);
	return true;
}

void AppendAttribute(char[] sQ, int iLen, const char[] sName, int iVal, bool bFirst){
	FormatEx(sQ, iLen, "%s%s %s='%d'", sQ, bFirst ? "" : ",", sName, iVal);
}

void RegisterAllPlayers(){
	Transaction hTxn = SQL_CreateTransaction();
	char sQ[Q_SIZE];
	hDb.Format(sQ, Q_SIZE, "DELETE FROM " ... TABLE_PLAYERS ... " WHERE token='%s'", g_sToken);
	hTxn.AddQuery(sQ);

	for(int i = 1; i <= MaxClients; i++){
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;

		SetClientConstants(i);
		FetchAllAttribs(i);

		hDb.Format(sQ, Q_SIZE,
			"INSERT INTO " ... TABLE_PLAYERS ... " (userid, token, auth64, ip, name, team, score, class, ping, status, country) VALUES \
			('%d', '%s', '%s', '%s', '%N', \
			'%d', '%d', '%d', \
			'%d', '%d', '%s')",
			g_iUserId[i], g_sToken, g_sAuth64[i], g_sIp[i], i,
			GetAttrib(i, EClientAttrib_Team), GetAttrib(i, EClientAttrib_Score), GetAttrib(i, EClientAttrib_Class),
			GetAttrib(i, EClientAttrib_Ping), GetAttrib(i, EClientAttrib_Status), g_sCountry[i]
		);

		hTxn.AddQuery(sQ);
		g_bRegistered[i] = true;
	}

#if defined DEBUG_SCOREBOARD
	Debug("Executing register all players transaction");
	hDb.Execute(hTxn, Callback_OnRegisterAllPlayersSuccess, Callback_OnRegisterAllPlayersFailure);
#else
	hDb.Execute(hTxn);
#endif

	if(g_hUpdateTimer == null)
		g_hUpdateTimer = CreateTimer(UPDATE_INTERVAL, Timer_UpdatePlayers, 0, TIMER_REPEAT);
}

void SetClientConstants(int client){
	GetClientAuthId(client, AuthId_SteamID64, g_sAuth64[client], 24);
	GetClientIP(client, g_sIp[client], 16);
	g_iUserId[client] = GetClientUserId(client);
	GeoipCode2(g_sIp[client], g_sCountry[client]);
}

void RegisterPlayer(int client){
	if(hDb == null)
		return;

	if(g_bRegistered[client])
		return;

	SetClientConstants(client);

	char sQ[Q_SIZE];
	hDb.Format(sQ, Q_SIZE,
		"INSERT INTO " ... TABLE_PLAYERS ... " (userid, token, auth64, ip, name, country) \
		VALUES ('%d', '%s', '%s', '%s', '%N', '%s')",
		g_iUserId[client], g_sToken, g_sAuth64[client], g_sIp[client], client, g_sCountry[client]
	);

#if defined DEBUG
	Debug("Registering %L: %s", client, sQ);
	hDb.Query(Callback_OnRegisterPlayer, sQ, GetClientUserId(client));
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	g_bRegistered[client] = true;
}

void UnregisterPlayer(int client){
	if(!g_bRegistered[client])
		return;

	char sQ[Q_SIZE];
	hDb.Format(sQ, Q_SIZE, "DELETE FROM " ... TABLE_PLAYERS ... " WHERE userid='%d' AND token='%s'", g_iUserId[client], g_sToken);

#if defined DEBUG
	Debug("Unregistering %L: %s", client, sQ);
	hDb.Query(Callback_OnUnregisterPlayer, sQ);
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	g_bRegistered[client] = false;
}

bool PushMessage(const char[] sPreQ, any ...){
	if(hDb == null)
		return false;

	char sMsg[MSG_LEN];
	VFormat(sMsg, MSG_LEN, sPreQ, 2);

	char sQ[Q_SIZE];
	hDb.Format(sQ, Q_SIZE, "INSERT INTO " ... TABLE_CHAT ... " (token, time, msg) VALUES('%s', UNIX_TIMESTAMP(), '%s')", g_sToken, sMsg);

#if defined DEBUG
	Debug("Pushing message \"%s\": %s", sMsg, sQ);
	hDb.Query(Callback_OnPushMessage, sQ);
#else
	hDb.Query(Callback_Whatever, sQ);
#endif

	return true;
}


/* CALLBACKS */

public void Callback_OnConnect(Database db, const char[] sError, any data){
	if(db != null){
		PrintToServer("%s Connection to database established!", CONS_PREFIX);
		hDb = db;
		hDb.SetCharset("utf8");
		RegisterAllPlayers();
	}else LogError("%s Database connection failure:\n%s", CONS_PREFIX, sError);
}

#if defined DEBUG
public void Callback_OnAddChatter(Database db, DBResultSet dbRes, const char[] sError, any data){
	Debug("Added chatter: %s", sError);
}

public void Callback_OnRemoveChatter(Database db, DBResultSet dbRes, const char[] sError, any data){
	Debug("Removed chatter: %s", sError);
}

public void Callback_OnSaveAndUpateChatter(Database db, DBResultSet dbRes, const char[] sError, any data){
	Debug("Saved and updated chatter: %s", sError);
}

public void Callback_OnRegisterPlayer(Database db, DBResultSet dbRes, const char[] sError, any iUserId){
	int client = GetClientOfUserId(iUserId);
	if(client == 0)
		Debug("Registered player %d(disconnected): %s", iUserId, sError);
	else Debug("Registered player %d(%L): %s", iUserId, client, sError);
}

public void Callback_OnUnregisterPlayer(Database db, DBResultSet dbRes, const char[] sError, any data){
	Debug("Unregistered player: %s", sError);
}

public void Callback_OnPushMessage(Database db, DBResultSet dbRes, const char[] sError, any data){
	Debug("Pushed message: %s", sError);
}
#else
public void Callback_Whatever(Database db, DBResultSet dbRes, const char[] sError, any data){}
#endif

#if defined DEBUG_SCOREBOARD
public void Callback_OnUpdatePlayersSuccess(Database db, any data, int iNumQueries, DBResultSet[] dbResSet, any[] queryData){
	Debug("Successfully updated players. Executed %d queries.", iNumQueries);
}

public void Callback_OnUpdatePlayersFailure(Database db, any data, int iNumQueries, const char[] sError, int iFailIndex, any[] queryData){
	Debug("Failed on updating players. Executed %d queries. Error %d: %s", iNumQueries, iFailIndex, sError);
}

public void Callback_OnRegisterAllPlayersSuccess(Database db, any data, int iNumQueries, DBResultSet[] dbResSet, any[] queryData){
	Debug("Successfully registered all players. %d queries involved.", iNumQueries);
}

public void Callback_OnRegisterAllPlayersFailure(Database db, any data, int iNumQueries, const char[] sError, int iFailIndex, any[] queryData){
	Debug("Failed on registering all players. %d queries involved. Error %d: %s", iNumQueries, iFailIndex, sError);
}
#endif

#if defined VOICE

public void OnBroadcastVoice(int client, const char[] sData, int iBytes){
	g_bTalking[client] = true;
}

#endif


/* NATIVES */

public int Native_SC_PushMessage(Handle hPlugin, int iNumParams){
	int iLen;
	GetNativeStringLength(1, iLen);
	if(iLen <= 0) return 2;
	if(iLen > MSG_LEN) return 3;

	char sFormatString[MSG_LEN], sMsg[MSG_LEN];
	GetNativeString(1, sFormatString, MSG_LEN);
	FormatNativeString(0, 0, 2, MSG_LEN, _, sMsg, sFormatString);

	return PushMessage(sMsg) ? 0 : 1;
}

public int Native_SC_GetTeamColor(Handle hPlugin, int iNumParams){
	int iTeam = GetNativeCell(1);
	if(!(0 <= iTeam < 4))
		ThrowNativeError(0, "Invalid team: %d", iTeam);

	return g_iColors[iTeam];
}

public int Native_SC_GetTeamColorOfClient(Handle hPlugin, int iNumParams){
	int client = GetNativeCell(1);
	if(!(1 <= client <= MaxClients))
		return g_iColors[0];

	if(!IsClientInGame(client))
		return g_iColors[0];

	return g_iColors[GetClientTeam(client)];
}

public int Native_SC_SetTeamColor(Handle hPlugin, int iNumParams){
	int iTeam = GetNativeCell(1);
	if(!(0 <= iTeam < 4))
		ThrowNativeError(0, "Invalid team: %d", iTeam);

	g_iColors[iTeam] = GetNativeCell(2);
	return 0;
}

public int Native_SC_GetInfoColor(Handle hPlugin, int iNumParams){
	return g_iInfoColor;
}

public int Native_SC_SetInfoColor(Handle hPlugin, int iNumParams){
	g_iInfoColor = GetNativeCell(1);
	return 0;
}

public int Native_SC_AddChatter(Handle hPlugin, int iNumParams){
	Chatter chatter = view_as<Chatter>(GetNativeCell(1));
	return AddChatter(chatter);
}

public int Native_SC_RemoveChatter(Handle hPlugin, int iNumParams){
	Chatter chatter = view_as<Chatter>(GetNativeCell(1));
	return RemoveChatter(chatter);
}

public int Native_SC_GetChatterAttrib(Handle hPlugin, int iNumParams){
	StringMap chatter = view_as<StringMap>(GetNativeCell(1));
	int i = GetNativeCell(2);
	if(!(0 <= i < view_as<int>(Chatter_SIZE)))
		ThrowNativeError(0, "ChatterAttrib out of range.");

	char sBuffer[MAX_NAME_LENGTH];
	bool bResult = chatter.GetString(g_sChatterAttribNames[i], sBuffer, MAX_NAME_LENGTH);

	SetNativeString(3, sBuffer, GetNativeCell(4));
	return bResult;
}

public int Native_SC_SetChatterAttrib(Handle hPlugin, int iNumParams){
	StringMap chatter = view_as<StringMap>(GetNativeCell(1));
	int i = GetNativeCell(2);
	if(!(0 <= i < view_as<int>(Chatter_SIZE)))
		ThrowNativeError(0, "ChatterAttrib out of range.");

	char sValue[MAX_NAME_LENGTH];
	GetNativeString(3, sValue, MAX_NAME_LENGTH);
	return chatter.SetString(g_sChatterAttribNames[i], sValue);
}

public int Native_SC_UnsetChatterAttrib(Handle hPlugin, int iNumParams){
	ChatterAttrib attrib = view_as<ChatterAttrib>(GetNativeCell(2));
	if(attrib == Chatter_Auth)
		ThrowNativeError(0, "Chatter_Auth attribute must always be set");

	StringMap chatter = view_as<StringMap>(GetNativeCell(1));
	return chatter.Remove(g_sChatterAttribNames[attrib]);
}

public int Native_SC_UnsetAllChatterAttribs(Handle hPlugin, int iNumParams){
	Chatter chatter = view_as<Chatter>(GetNativeCell(1));
	bool bSuccess = false;
	for(ChatterAttrib attr = view_as<ChatterAttrib>(1); attr < Chatter_SIZE; ++attr)
		bSuccess |= chatter.Unset(attr);
	return bSuccess;
}

public int Native_SC_CommitChatterEdit(Handle hPlugin, int iNumParams){
	Chatter chatter = view_as<Chatter>(GetNativeCell(1));
	return CommitChatterEdit(chatter);
}


/* MISC FUNCTIONS */

bool HasPrefix(const char[] sCmd){
	return
		strlen(sCmd) > 3 &&
		sCmd[0] == 's' &&
		sCmd[1] == 'm' &&
		sCmd[2] == '_';
}

bool CheckCommandAccessFlags(const char[] sCmd, const char[] sFlags){
	AdminId hAdmin = CreateAdmin("");

	int i = -1;
	AdminFlag eFlag;
	while(sFlags[++i] != '\0')
		if(FindFlagByChar(sFlags[i], eFlag))
			hAdmin.SetFlag(eFlag, true);

	bool bResult = CheckAccess(hAdmin, sCmd, 0, false);
	RemoveAdmin(hAdmin);
	return bResult;
}

int GetAttrib(int client, EClientAttrib eAttrib){
	return g_iClientAttribs[client][view_as<int>(eAttrib)];
}

void SetAttrib(int client, EClientAttrib eAttrib, int iVal){
	g_iClientAttribs[client][view_as<int>(eAttrib)] = iVal;
}

int FetchAttrib(int client, EClientAttrib eAttrib){
	switch(eAttrib){
		case EClientAttrib_Team: return GetClientTeam(client);
		case EClientAttrib_Score: return GetScore(client);
		case EClientAttrib_Class: return GetClass(client);
		case EClientAttrib_Ping: return GetPing(client);
		case EClientAttrib_Status: return GetStatus(client);
	}
	return 0;
}

void FetchAllAttribs(int client){
	for(EClientAttrib eAttr = view_as<EClientAttrib>(0); eAttr < EClientAttrib_SIZE; eAttr++)
		SetAttrib(client, eAttr, FetchAttrib(client, eAttr));
}

void ReplyToCommandEx(int client, const char[] sFormat, any ...){
	char sReply[255];
	VFormat(sReply, 255, sFormat, 3);
	if(GetCmdReplySource() == SM_REPLY_TO_CONSOLE)
		ReplyToCommand(client, "%s %s", CONS_PREFIX, sReply);
	else ReplyToCommand(client, "%s %s", CHAT_PREFIX, sReply);
}

#if defined DEBUG

void Debug(const char[] sFormat, any ...){
	char sMessage[255];
	VFormat(sMessage, 255, sFormat, 2);
	PrintToChatAll("\x04[DEBUG]\x01 %s", sMessage);
	PrintToServer("[DEBUG] %s", sMessage);
}

#endif

// Get flags for the player, ex. in the group, is voicechatting, is dead
int GetStatus(int client){
	int isTalking = g_bTalking[client];
	int isDead = !IsPlayerAlive(client);
	int inGroup = InGroup(client);

	g_bTalking[client] = false;
	return isTalking << 2 | isDead << 1 | inGroup;
}

bool InGroup(int client){
	if(g_iGroupFlag <= 0) return false;
	return CheckCommandAccess(client, "", g_iGroupFlag, true);
}

int GetClass(int client){
	int iClass = GetEntProp(client, Prop_Send, "m_iClass");
	return (0 <= iClass < 10) ? g_iTF2Class[iClass] : 0;
}

int GetScore(int client){
	if(g_iResource == -1) return 0;
	return GetEntProp(g_iResource, Prop_Send, g_sPropScore, _, client);
}

int GetPing(int client){
	if(g_iResource == -1) return 0;
	return GetEntProp(g_iResource, Prop_Send, "m_iPing", _, client);
}

bool IsValidSteamId64(const char[] sAuth){
	int i = -1;
	while(sAuth[++i] != '\0')
		if(!IsCharNumeric(sAuth[i]) || i > 24)
			return false;
	return true;
}
