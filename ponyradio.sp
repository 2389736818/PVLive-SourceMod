/*
CHANGE LOG
7/25/13		Converted SQL queries for nowplaying data 
				to now use an http download of a txt file instead
			Added an autogen config file called...um...something
7/26/13		Switched to using SteamTools from cURL due to VC++ issues
7/27/13		Fixed HTTP caching issue with download
7/28/13		Fixed bug with calling station by name
			Fixed bug with station info storage array
8/7/13		Fixed bug with sending client in timer rather than clienid
			Fixed bug of using IsClientConnected rather than IsClientInGame
TO DO LIST
	Make a sm_resume command to quickly reload station stream in case another plugin uses the html page
	Make a sm_mute command
	Make an Admin command to cease playpack for everypony
*/
#pragma semicolon 1
#pragma dynamic 131072			//cause damn http download be big
#include <sourcemod>
#include <colors>
#include <steamtools>

#define PLUGIN_VERSION "3.2.4"

public Plugin:myinfo = 
{
	name = "[ANY]Ponyville Live Radio",
	author = "WeAreBorg",
	description = "Bucking awesome now with no SQL",
	version = PLUGIN_VERSION,
	url = "www.ponyvillelive.com"
}

new Handle:A_Station = INVALID_HANDLE;		//why are there 5 arrays?
new Handle:A_Song = INVALID_HANDLE;			//Because Ponies drove me to drink
new Handle:A_Artist = INVALID_HANDLE;
new Handle:A_ID = INVALID_HANDLE;
new Handle:A_Listeners = INVALID_HANDLE;
new HTTPRequestHandle:g_HTTPRequest = INVALID_HTTP_HANDLE;	//formerly INVALID_HTTP_HANDLE

new Handle:g_timer = INVALID_HANDLE;
new Handle:g_volume = INVALID_HANDLE;
new Handle:g_Adverts = INVALID_HANDLE;

new tunedstation[MAXPLAYERS] = -1;			//this is the arrayid
new tunedvolume[MAXPLAYERS];
new reconnect[MAXPLAYERS];			
new menucycle[MAXPLAYERS] = 0;				//for turning panels in multipage menus		

public OnPluginStart()
{
	CreateConVar("PonyRadio_version", PLUGIN_VERSION, "Installed version of Pony Radio on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_timer = CreateConVar("PonyRadio_updatetimer", "15.0", "How often to check for new song info in seconds",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 15.0, true, 60.0);
	g_volume = CreateConVar("PonyRadio_volume", "30", "Default Volume Percent",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	g_Adverts = CreateConVar("PonyRadio_Advertchance", "50", "Chance of advertisement of radio playing ",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	RegConsoleCmd("sm_radio", DisplayStations);
	RegConsoleCmd("sm_pvl", DisplayStations);
	RegConsoleCmd("sm_RADIO", DisplayStations);				//stupid ad.....
	RegAdminCmd("sm_radioall", RadioAll, ADMFLAG_SLAY);
	RegConsoleCmd("sm_radiooff", EndTransmission);
	RegConsoleCmd("sm_radiostop", EndTransmission);
	RegConsoleCmd("sm_radiohelp", FlashTest);
	RegConsoleCmd("sm_nowplaying", GetSongs);
	RegConsoleCmd("sm_np", GetSongs);
	RegConsoleCmd("sm_vol", SetVolume);
	RegConsoleCmd("sm_volume", SetVolume);
	RegConsoleCmd("sm_volup", SetVolumeUp);
	RegConsoleCmd("sm_voldown", SetVolumeDown);
	RegConsoleCmd("sm_volumeup", SetVolumeUp);
	RegConsoleCmd("sm_volumedown", SetVolumeDown);
	
	AutoExecConfig(true, "PVLPonyRadio");

	HookEvent("player_connect", Event_PlayerConnect);
	HookEvent("player_spawn", Hook_PlayerSpawn);	
	
	A_Station = CreateArray( 32 );
	A_Song = CreateArray( 100 );
	A_Artist = CreateArray( 100 );
	A_ID = CreateArray();
	A_Listeners = CreateArray();
	for(new i=1;i < MaxClients;i++) tunedstation[i] = -1;
	
	UpdateStations();
	CreateTimer(GetConVarFloat(g_timer), HTTPTimer, _, TIMER_REPEAT);
}

public Action:HTTPTimer(Handle:timer)
{
	UpdateStations();
}

public OnClientConnected(client)
{
	reconnect[client] = 0;
}

public Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event,"userid"));
	tunedvolume[client] = 0;
	tunedstation[client] = -1;
}

public Hook_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) //restart radio if they had it playing on first spawn
{
	//launch station precache
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

/*
	
	if (reconnect[client] == 2) {
		if(tunedstation[client] == -1) tunedstation[client] = GetRandomInt(0, GetArraySize( A_ID ));
		//need to time it cause too close to class select menu
		CreateTimer(15.0, RestartRadioTimer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	} 	
*/
	reconnect[client]++;
	
	
}

public Action:RestartRadioTimer(Handle:timer, any: clientid)
{
	new client = GetClientOfUserId(clientid);
	if (tunedvolume[client] != 0) OutputSongs(client, tunedstation[client]);
	PlayerOTD(client);
}


public UpdateStations()
{
	//download nowplaying data
	if (g_HTTPRequest != INVALID_HTTP_HANDLE) g_HTTPRequest = INVALID_HTTP_HANDLE;
	
	//as seen on www.ponyvillelive.com
	g_HTTPRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://ponyvillelive.com/sourcemod/sourcemod.php");
	
	//asherkin is awesome
	Steam_SetHTTPRequestHeaderValue(g_HTTPRequest, "Pragma", "no-cache");
	Steam_SetHTTPRequestHeaderValue(g_HTTPRequest, "Cache-Control", "no-cache");
	Steam_SendHTTPRequest(g_HTTPRequest, OnDownloadComplete);
}

public OnDownloadComplete(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode)
{
	if (HTTPRequest != g_HTTPRequest || !requestSuccessful || statusCode != HTTPStatusCode_OK)
	{
		LogError("[PVL Pony Radio] Something went wrong with the HTTP download");	//I need some real error handling
		return;
	}
	decl String:data[6000];
	
	Steam_GetHTTPResponseBodyData(g_HTTPRequest, data, sizeof(data));
	
	Steam_ReleaseHTTPRequest(g_HTTPRequest);
	g_HTTPRequest = INVALID_HTTP_HANDLE;
	
	//Begin the fun
	
	//new String:HTTPStations[9][1000] = {"", "", "", "", "", "", "", "", "" }; //TODO: fix this
	new String:HTTPStations[18][1000];
	//id|Station Name|listeners|title|artist|...
	
	//First Explode into separate stations' data to protect against errors. Silver Eagles idea
	ExplodeString(data,"<>",HTTPStations, sizeof(HTTPStations), sizeof(HTTPStations[]));	//I wanted a fancy delimiter with strange UTF-8 chars
	
	new stationid;
	new listeners;
	new String:station[32];
	new String:artist[100];
	new String:song[100];
	new String:Lsong[100];
	new count = 0;			//This is the array id
	
	new Float:AnnounceDelay = 10.0;		//Some tweaking to make sure song is announced when its actually playing
	
	decl String:TempArray[5][100];
	new count_b = 0;
	while (count_b < 18 && strlen(HTTPStations[count_b]) > 20)		//need to catch some trash chars too
	{
		//Explode each station data string based on seperate delimiter
		//id|Station Name|listeners|title|artist|...
		
		ExplodeString(HTTPStations[count_b],"|",TempArray, sizeof(TempArray), sizeof(TempArray[]));
		
		stationid = StringToInt(TempArray[0]);
		strcopy(station, sizeof(station), TempArray[1]);
		listeners = StringToInt(TempArray[2]);
		strcopy(song, sizeof(song), TempArray[3]);
		strcopy(artist, sizeof(artist), TempArray[4]);
		
		count_b++;
	
		//if (FindValueInArray(A_ID, stationid) == -1)		//Had some bs hitting this field
		if (FindStringInArray(A_Station, station) == -1){
			PushArrayCell( A_ID, stationid);
			PushArrayString( A_Station, station );
			PushArrayString( A_Song, song );						//if we start with NULLs w/e
			PushArrayString( A_Artist, artist );					//no more SQL queries...
			PushArrayCell( A_Listeners, listeners);
		} else {
			GetArrayString(A_Song, count, Lsong, sizeof(Lsong) ); 	//hold stations 'old' song
				
			SetArrayCell( A_Listeners, count, listeners);
			if (strlen(song) > 0) {
				SetArrayString(A_Song, count, song);				
			} else SetArrayString(A_Song, count, "Unknown");		//If returned a NULL set to Unknown
				
			if (strlen(artist) > 0) {
				SetArrayString(A_Artist, count, artist);
			} else SetArrayString(A_Artist, count, "Unknown");		//If returned a NULL set to Unknown
				
			if (!StrEqual(Lsong, song)) {							//If both return NULL assume error and dont announce
				if (strlen(song) > 0 && strlen(artist) > 0)CreateTimer(AnnounceDelay, DelayAnnounceSong, count);
			}	
		}		
		count++;
	}
} 

public Action:DelayAnnounceSong(Handle:timer, any:arrayid)
{
	AnnounceSong(arrayid);
}

public AnnounceSong(arrayid)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && tunedstation[i] == arrayid)
		{
			if (tunedvolume[i] != 0)
			{
				OutputSongs(i, arrayid);
			} else
			{
				new chance = GetRandomInt(0,100);
				if (chance > GetConVarInt(g_Adverts)) CPrintToChat(i, "[{green}PVL Radio{default}] Type{lightgreen} !radio{default} to tune in now and hear some great {olive}Pony Music {default}from {lightgreen}Ponyville Live!");
			}
		}
	}
}

public Action:DisplayStations(client, args)				//this is the !radio command
{
	UpdateStations();
	CPrintToChat(client,"[{green}PVL Radio{default}] Type {olive}!radio [station] {default}to skip menu, {olive}!radiooff{default} to stop, {olive}!vol {default}, {olive}!vol [0-100]{default}, {olive}!volup{default}, or {olive}!voldown{default},{default}to set volume.");
	CPrintToChat(client,"[{green}PVL Radio{default}] Type {olive}!np {default}for song info, or {olive}!radiohelp{default} for help.");

	new String:station[32];
	new stationid = -1;
	menucycle[client] = 0;
	
	if (args > 0) {
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new size = GetArraySize( A_Station );
		for (new i = 0; i < size; i++) {
			GetArrayString( A_Station, i, station, sizeof(station) );
			if (StrContains(station, arg1, false) != -1 && stationid == -1) stationid = i;
			else if (StrContains(station, arg1) != -1 && stationid != -1) {
				CPrintToChat(client,"[{green}PVL Radio{default}] More than one radio station matches that name.");
				break;
			}
		}

		if (stationid == -1) {
			CPrintToChat(client,"[{green}PVL Radio{default}] No radio station matches that name.");
		}
		else if (stationid != -1) {
			tunedstation[client] = stationid;
			if (tunedvolume[client] == 0) tunedvolume[client] = GetConVarInt(g_volume);
			PlayerOTD(client);
		}
	}
	
	if (stationid <= 0) {
		
		RadioMenu(client); 
	}
}

//I'm so sorry about this abuse of panels
	
public RadioMenu(client)
{
	//cycle is a crude count for menus
	//menu can only have 1024 chars
	new String:artist[18];
	new String:song[25];
	new String:buffer_A[255];
	new String:station[32];
	
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Ponyville Live!");

	new size = GetArraySize( A_Station );					//size of array
	if (8*menucycle[client] > size) menucycle[client] = 0;	//if they hit next at last page, menucycle still gets increased. This catches a startpoint greater than the size
	new startpoint = 8*menucycle[client];					//if this is not the first panel we'll display the next set of eight 				0,8,16
	new endpoint = startpoint + 8;							//by default the endpoint is 8 away from startpoint cause 9 options + 10th next		8,16,24
		
	if (endpoint > size) {									//lets not try and display more stations then there are shall we?
		endpoint = size;							
	}

	//PrintToChat(client,"[PVL Radio Debug] Your menu cycle is %d thus startpoint is %d and endpoint is %d",menucycle[client],startpoint,endpoint);
	
	for (new i = startpoint; i < endpoint; i++) {
		GetArrayString( A_Station, i, station, sizeof(station) );
		GetArrayString( A_Song, i, song, sizeof(song) );
		GetArrayString( A_Artist, i, artist, sizeof(artist) );
		//	👂 ੭  ୭ ᠀ ᧙ ☊ ♫   Yeah....just try and guess what i was doing here
		Format(buffer_A, sizeof(buffer_A), "%s  ☊%d", station, GetArrayCell(A_Listeners,i)); 
		DrawPanelItem(panel, buffer_A);
		
		//Truncate artist/song if they fill their strings
		new artist_size = sizeof(artist)-1;
		if (strlen(artist) == artist_size) {
			artist[artist_size] = '\0';
			artist[artist_size-1] = '.';
			artist[artist_size-2] = '.';
			artist[artist_size-3] = '.';
		}
		new song_size = sizeof(song)-1;
		if (strlen(song) == song_size) {
			song[song_size] = '\0';
			song[song_size-1] = '.';
			song[song_size-2] = '.';
			song[song_size-3] = '.';
		}
		Format(buffer_A, sizeof(buffer_A), "%s--%s", artist, song); 
		DrawPanelText(panel, buffer_A);	
	}
	
	DrawPanelItem(panel, "Next");
	DrawPanelItem(panel, "Cancel");
	SendPanelToClient(panel, client, PanelHandler, 45);
}

 
public PanelHandler(Handle:panel, MenuAction:action, client, selection)	//changed from param1 and param2
{
	if (action == MenuAction_Select)
	{	
		new size = GetArraySize( A_Station );			//size of array
		new LastSongDisplayed = 8;							

		if ((8*menucycle[client])+8 > size) {		//if the "next" position is greater than the remaining stations		8>18	16>18	24>18
			LastSongDisplayed = size%8;									
		}
		if (selection == (LastSongDisplayed+1)) {	//if selecting "next"
			menucycle[client]++;
			RadioMenu(client);
		}
		else if (selection > 0 && selection <= LastSongDisplayed) {
			tunedstation[client] = (selection+(8*menucycle[client]) - 1);	//subtract one to account for menu reposition
			if (tunedvolume[client] == 0) tunedvolume[client] = GetConVarInt(g_volume);		//reset volume to default if muted
			PlayerOTD(client);  
		}
	} 
	CloseHandle(panel);
}

public Action:RadioAll(client, args)
{
	if(tunedstation[client] != -1)
	{
		for(new i=1; i < MAXPLAYERS; i++) {
			if (reconnect[i] > 2) {
				CPrintToChat(i,"[{green}PVL Radio{default}] An admin has turned on your radio! Type {olive}!radiooff{default} to end playback, {olive}!vol{default} to set volume or open vol menu, {olive}!np{default} for current song info");
				tunedstation[i] = tunedstation[client];
				if (tunedvolume[i] < 5) tunedvolume[i] = GetConVarInt(g_volume);
				PlayerOTD(i);
			}
		}
	}
	else {
		CPrintToChat(client,"[{green}PVL Radio{default}] Listen to a radio yourself first!");	//yay for laziness
	}
}

public PlayerOTD(client)				//where the magic happens
{
	new URLId = GetStationID(tunedstation[client] );
	if (URLId != -1) {
		new String:url[128];
		Format(url, sizeof(url), "http://ponyvillelive.com/index/tunein/id/%d/showonlystation/true/volume/%d/autoplay/true", URLId, tunedvolume[client] );

		new Handle:setup = CreateKeyValues("data");	
	
		KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
		KvSetString(setup, "title", "PVL Player");
		KvSetString(setup, "msg", url);

		ShowVGUIPanel(client, "info", setup, false);
		CloseHandle(setup);
	}
}

public Action:SetVolume(client, args)
{
	if (args == 0)
	{	
		DisplayVolumeMenu(client);
	} else {
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		new volume = StringToInt(arg1);
		if (volume < 0) volume = 0;
		if (volume > 100) volume = 100;
		new old = tunedvolume[client];
		tunedvolume[client] = volume;
		
		if (old == volume){
			CPrintToChat(client, "[{green}PVL Radio{default}] Volume is Already set to {olive}%d", volume);
		} else {
			if(tunedstation[client] != -1) PlayerOTD(client);
			CPrintToChat(client, "[{green}PVL Radio{default}] Volume set to {olive}%d", volume);
		}
	}
}

public Action:SetVolumeUp(client, args)
{
	tunedvolume[client] = tunedvolume[client] + 15;
	if (tunedvolume[client] > 100) tunedvolume[client] = 100;
	
	if(tunedstation[client] != -1) PlayerOTD(client);
	CPrintToChat(client, "[{green}PVL Radio{default}] Volume set to {olive}%d", tunedvolume[client]);
}

public Action:SetVolumeDown(client, args)
{
	tunedvolume[client] = tunedvolume[client] - 15;
	if (tunedvolume[client] < 0) tunedvolume[client] = 0;
	
	if(tunedstation[client] != -1) PlayerOTD(client);
	if (tunedvolume[client] == 0) 
	{
		CPrintToChat(client, "[{green}PVL Radio{default}] Volume {olive}Muted");
	}
	else CPrintToChat(client, "[{green}PVL Radio{default}] Volume set to {olive}%d", tunedvolume[client]);
}

DisplayVolumeMenu(client) 
{
	new Handle:menu = CreateMenu(MenuHandler_VolumeMenu);
	decl String:buffer_A[100];
	Format (buffer_A, sizeof(buffer_A), "PVL Volume current:%d", tunedvolume[client]);
	SetMenuTitle(menu, buffer_A);
	AddMenuItem(menu, "100", "100");
	AddMenuItem(menu, "85", "85");
	AddMenuItem(menu, "70", "70");
	AddMenuItem(menu, "55", "55");
	AddMenuItem(menu, "40", "40");
	AddMenuItem(menu, "25", "25");
	AddMenuItem(menu, "10", "10");
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_VolumeMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if( action == MenuAction_Cancel )
	{
		if( param2 == MenuCancel_ExitBack )
		{
			CloseHandle(menu);
		}
	}
	else if (action == MenuAction_Select){
		decl String:info[128];
		GetMenuItem(menu, param2, info, sizeof(info));
		tunedvolume[param1] = StringToInt(info);
		if(tunedstation[param1] != -1) PlayerOTD(param1);
	}
}	

public Action:GetSongs(client, args)
{
	UpdateStations();
	new id = tunedstation[client];
	if (args > 0)
	{	
		new String:arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		id = StringToInt(arg1) - 1;
	}
	new size = GetArraySize( A_Station );
	if (tunedvolume[client] == 0) id = -1; 
	if (id > (size - 1) || id < -1) {
		ReplyToCommand(client, "Invalid Station input");
	} else OutputSongs(client, id);
}

public OutputSongs(client, id)	//array id
{
	new String:station[32];
	new String:artist[100];
	new String:song[100];
	new size = GetArraySize( A_Station );
	if (id == -1)
	{
		for (new i = 0; i < size; i++) { 					//if they aren't listening to a station, 
			GetArrayString( A_Station, i, station, sizeof(station) );
			GetArrayString( A_Song, i, song, sizeof(song) );
			GetArrayString( A_Artist, i, artist, sizeof(artist) );
			//prevent updating song info if there is info
			CPrintToChat(client, "[{green}PVL Radio{default}] {lightgreen}%s{default} is playing {olive}%s {default}-- {lightgreen}%s", station, artist, song);
		}	
	} else {
		GetArrayString( A_Station, id, station, sizeof(station) );
		GetArrayString( A_Song, id, song, sizeof(song) );
		GetArrayString( A_Artist, id, artist, sizeof(artist) );
		CPrintToChat(client, "[{green}PVL Radio{default}] {lightgreen}%s{default} is playing {olive}%s {default}-- {lightgreen}%s", station, artist, song);
	}
	return;
}

public Action:EndTransmission(client, args)
{
	tunedstation[client] = -1;
	new Handle:setup = CreateKeyValues("data");	
	
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "title", "PVL Player");
	KvSetString(setup, "msg", "about:blank");
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
}

public Action:FlashTest(client, args)
{
	CPrintToChat(client, "[{green}PVL Radio{default}] Make sure you have flash installed for OTHER BROWSERS.");
	CPrintToChat(client, "If you can't see the radio page at all, go to {olive}Options -> Multiplayer -> Advanced {default} then scroll down and uncheck {olive} Disable HTML MOTDs");
}

stock GetStationID(arrayid)
{
	if (GetArraySize(A_ID) > 0) {
		return GetArrayCell(A_ID, arrayid);
	}
	else return -1;
}