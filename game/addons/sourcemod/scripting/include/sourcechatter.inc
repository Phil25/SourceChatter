#if defined _sourcechatter_included
	#endinput
#endif
#define _sourcechatter_included

public SharedPlugin __pl_sourcechatter = {
	name = "SourceChatter",
	file = "SourceChatter.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_sourcechatter_SetNTVOptional(){
	MarkNativeAsOptional("SC_PushMessage");
	MarkNativeAsOptional("SC_GetTeamColor");
	MarkNativeAsOptional("SC_GetTeamColorOfClient");
	MarkNativeAsOptional("SC_SetTeamColor");
	MarkNativeAsOptional("SC_GetInfoColor");
	MarkNativeAsOptional("SC_SetInfoColor");

	MarkNativeAsOptional("SC_AddChatter");
	MarkNativeAsOptional("SC_RemoveChatter");
	MarkNativeAsOptional("SC_GetChatterAttrib");
	MarkNativeAsOptional("SC_SetChatterAttrib");
	MarkNativeAsOptional("SC_UnsetChatterAttrib");
	MarkNativeAsOptional("SC_UnsetAllChatterAttribs");
	MarkNativeAsOptional("SC_CommitChatterEdit");
}
#endif


enum ChatterAttrib{
	Chatter_Auth = 0,
	Chatter_Flags,
	Chatter_Name,
	Chatter_Tag,
	Chatter_TagColor,
	Chatter_AddedBy,
	Chatter_SIZE
};


/**
* Pushes the message to be displayed.
* Messages support BBCode formatting.
* Remember about %06x when formatting integer representation of color.
*
* @param sMessage	Message
* @param ...		Format parameters
* @return			0 on success, 1 on null database, 2 on empty string, 3 on too lengthy string
*/
native int SC_PushMessage(const char[] sMessage, any ...);

/**
* Get team color.
*
* @param iTeam		Team number (0-3)
* @return			Integer representation of the color
*/
native int SC_GetTeamColor(int iTeam);

/**
* Get team color of client. Safe to call on invalid clients.
* Invalid client returns color of team 0 (unknown).
*
* @param client		Client index
* @return			Integer representation of the color
*/
native int SC_GetTeamColorOfClient(int client);

/**
* Set team color.
* Initially set to Team Fortess 2 colors.
* Note: Use StringToInt(str, 16) to convert a hexadecimal string.
*
* @param iTeam		Team number (0-3)
* @param iColor		Integer representation of the color (see note)
* @noreturn
*/
native int SC_SetTeamColor(int iTeam, int iColor);

/**
* Get info color.
* Color of the information messages in chat, usually grey.
*
* @return	Integer representation of the color
*/
native int SC_GetInfoColor();

/**
* Set info color
* Color of the information messages in chat, usually grey.
* Note: Use StringToInt(str, 16) to convert a hexadecimal string.
*
* @param iColor		Integer representation of the color (see note)
* @noreturn
*/
native int SC_SetInfoColor(int iColor);


/**
* Add user to Source Chatter.
*
* @param chatter	Chatter object
* @return			true on success, false on no database connection
*/
native bool SC_AddChatter(Chatter chatter);

/**
* Remove user from Source Chatter.
*
* @param chatter	Chatter object
* @return			true on success, false on no database connection
*/
native bool SC_RemoveChatter(Chatter chatter);

/**
* Get attribute of the user.
*
* @param chatter	Chatter object
* @param attrib		Attribute to get
* @param sBuffer	Buffer to store the value in
* @param iBufferLen	Length of the buffer
* @return			true on success, false if not set
*/
native bool SC_GetChatterAttrib(Chatter chatter, ChatterAttrib attrib, char[] sBuffer, int iBufferLen);

/**
* Set attribute of a Chatter and make it eligible for updating upon committing changes.
*
* @param chatter	Chatter object
* @param attrib		Attribute to set
* @param sValue		Value to set the attribute to
* @return			true on success, false otherwise
*/
native bool SC_SetChatterAttrib(Chatter chatter, ChatterAttrib attrib, const char[] sValue);

/**
* Unset attribute of a Chatter making it not eligible for updating upon committing changes.
* Cannot unset Chatter_Auth.
*
* @param chatter	Chatter object
* @param attrib		Attribute to unset
* @return			true on success, false if attribute not set
*/
native bool SC_UnsetChatterAttrib(Chatter chatter, ChatterAttrib attrib);

/**
* Unset all attribute of a Chatter so nothing will be updated upon committing changes.
* Does not unset Chatter_Auth.
*
* @param chatter	Chatter object
* @return			true if anything was unset, false otherwise
*/
native bool SC_UnsetAllChatterAttribs(Chatter chatter);

/**
* Commit all the edits of a Chatter.
*
* @param chatter	Chatter object
* @return			0 on success, 1 on nothing to update, 2 on no database connection
*/
native int SC_CommitChatterEdit(Chatter chatter);

/* Objet-oriented wrapper for Chatter management */
methodmap Chatter < StringMap{

	// Creates a Chatter. Chatter inherits from StringMap and holds
	// values of attributes. Attributes are idenfied by ChatterAttrib
	// enum and are the only mean of accessing Chatter's properties.
	//
	// First attribute to set is the SteamID64 identifier under "auth64"
	// It is guaranteed to always be set to something, may also be blank.
	//
	// The Chatter must be freed via delete or CloseHandle().
	//
	// @param sSteamID64	Steam ID 64 identifier of the user, may initially be empty
	// @return				Chatter object
	public Chatter(const char[] sSteamID64){
		StringMap map = new StringMap();
		map.SetString("auth64", sSteamID64); // "auth64" hardcoded from ChatterAttrib enum
		return view_as<Chatter>(map);
	}

	// Get the count of set attributes omitting the auth64 one
	property int Size{
		public get(){
			return this.Size -1;
		}
	}

	// Set attribute of a Chatter and make it eligible for updating upon committing changes.
	//
	// @param attrib	Attribute to set
	// @param sValue	Value to set the attribute to
	// @return			true on success, false otherwise
	public bool Set(ChatterAttrib attrib, const char[] sValue){
		return SC_SetChatterAttrib(this, attrib, sValue);
	}

	// Get attribute of the user.
	//
	// @param attrib		Attribute to get
	// @param sBuffer		Buffer to store the value in
	// @param iBufferLen	Length of the buffer
	// @return				true on success, false if not set
	public bool Get(ChatterAttrib attrib, char[] sBuffer, int iBufferLen){
		return SC_GetChatterAttrib(this, attrib, sBuffer, iBufferLen);
	}

	// Unset attribute of a Chatter making it not eligible for updating upon committing changes.
	// Cannot unset Chatter_Auth.
	//
	// @param attrib	Attribute to unset
	// @return			true on success, false if attribute not set
	public bool Unset(ChatterAttrib attrib){
		return SC_UnsetChatterAttrib(this, attrib);
	}

	// Unset all attribute of a Chatter so nothing will be updated upon committing changes.
	// Does not unset Chatter_Auth.
	//
	// @return	true if anything was unset, false otherwise
	public bool UnsetAll(){
		return SC_UnsetAllChatterAttribs(this);
	}

	// Add user to Source Chatter.
	//
	// @return	true on success, false on no database connection
	public bool Add(){
		return SC_AddChatter(this);
	}

	// Remove user from Source Chatter.
	//
	// @return	true on success, false on no database connection
	public bool Remove(){
		return SC_RemoveChatter(this);
	}

	// Commit all the edits of a Chatter.
	//
	// @return	0 on success, 1 on nothing to update, 2 on no database connection
	public int CommitEdit(){
		return SC_CommitChatterEdit(this);
	}
}
