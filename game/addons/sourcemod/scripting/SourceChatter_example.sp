#pragma semicolon 1

#include <sourcechatter>


#define SC_LIB "SourceChatter"


bool g_bCoreLoaded = false;


public Plugin myinfo = {
	name		= "SourceChatter Example",
	author		= "Phil25",
	description	= "Example of integration with Source Chatter"
};


public void OnAllPluginsLoaded(){
	SetCoreLoaded(LibraryExists(SC_LIB));
}

public void OnLibraryAdded(const char[] sName){
	if(StrEqual(sName, SC_LIB))
		SetCoreLoaded(true);
}

public void OnLibraryRemoved(const char[] sName){
	if(StrEqual(sName, SC_LIB))
		SetCoreLoaded(false);
}

void SetCoreLoaded(bool bSet){
	if(bSet && !g_bCoreLoaded)
		OnSourceChatterStart();
	g_bCoreLoaded = bSet;
}

/* Source Chatter was found */
void OnSourceChatterStart(){
	SC_PushMessage("This is a message from external plugin.");

	// Set individual team color, initially set to Team Fortress 2 colors
	//SC_SetTeamColor(0, StringToInt("ffffff", 16));
	//SC_SetTeamColor(1, StringToInt("ff0000", 16));
	//SC_SetTeamColor(2, StringToInt("00ff00", 16));
	//SC_SetTeamColor(3, StringToInt("0000ff", 16));

	// Add a chatter: instantiate with steamid64. Can be set later, but the filed must exist
	//Chatter chatter = new Chatter("123456789"); // steamid can be altered with Chatter_Auth
	//chatter.Set(Chatter_Flags, "abc");
	//chatter.Set(Chatter_Name, "Test Dude");
	//chatter.Set(Chatter_Tag, "[Test] ");
	//chatter.Set(Chatter_TagColor, "ff0000");
	//chatter.Set(Chatter_Addedby, "123456789");

	// Edit a chatter
	//chatter.Set(Chatter_Flags, "z");
	//chatter.Set(Chatter_Name, "Guy");
	//chatter.Set(Chatter_TagColor, "00ff00");
	//chatter.CommitEdit();

	// Remove a chatter
	//chatter.Remove();
	//delete chatter;
}
