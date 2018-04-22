Note: This is the old version

# Ponyville Live! Presents the PVL SourceMod Pony Radio Player

Ponyville Live!, the MLP fandom's largest multimedia network, is pleased to present all of our Pony and Brony music themed radio stations in a fantastic and easy to use sourcemod plugin!

This radio player is similar in design to other sourcemod radios but requires no php site or backend to work and features live song info downloaded directly into the game.

### Features

* Live In-game Song Info
* No visible MOTD screens
* Persistent playback across map changes
* Both menu and command based Radio selection
* Both menu and command based Volume Control
* Active listener count of stations
* Chat updates of song changes
* Chat ads that there is a radio with variable frequency
* 24/7 Pony music on 8 Radio Stations (more to come, no update needed)

### Screenshots

![Main Radio Menu](https://raw.githubusercontent.com/BravelyBlue/PVLive-SourceMod/master/docs/radio_menu.png)

Main `!radio` Menu

![Volume Menu](https://raw.githubusercontent.com/BravelyBlue/PVLive-SourceMod/master/docs/volume_menu.png)

`!volume` Menu

![Song Updates](https://raw.githubusercontent.com/BravelyBlue/PVLive-SourceMod/master/docs/song_updates.png)

Live in game updates of song info

### Commands

* `!sm_radio` Open station select menu
* `!sm_radio` [partial station name] Tune directly to a station
* `!sm_radiooff` If you need to pause the pony
* `!sm_vol` or `!sm_volume` Open volume select menu
* `!sm_vol [0-100]` Set volume manually
* `!sm_np` or `!sm_nowplaying` View current song info in chat, or all currently playing song if no station is tuned to
* `!sm_radiohelp` Informs the player they need to enable html motds and have flash for other browsers installed

### Admin Commands

* `!sm_radioall` Unmutes all players, and tunes them to whatever station the admin is listening to

### Auto-Generated Config

* Auto generated config: PVLPonyRadio.cfg

CVars:

* `CreateConVar("PonyRadio_updatetimer", "15.0", "How often to check for new song info in seconds",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 15.0, true, 60.0);`
* `CreateConVar("PonyRadio_volume", "30", "Default Volume Percent",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);`
* `CreateConVar("PonyRadio_Advertchance", "50", "Chance of advertisement of radio playing ",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 100.0);`

### TODO List

* Make a `sm_resume` command to quickly reload station stream in case another plugin uses the motd page
* Make a `sm_mute` command
* Auto Adjust character output to menu
* Make an Admin command to cease playpack for everypony
* Minor code tweaks
* In game announcements of scheduled programming
* Make cURL version
* Make Socket version
* Make customizable version with php and SQL to edit stations and work on non source 2009 games

### Known Issues

Radio selection menu is maxed at 1024 chars

### Requirements

Requires SteamTools extension for downloading of song info, which only works on Source 2009 games

### Installation

Stick the ponyradio.smx in your sourcemod/plugins folder

This source will not compile on site as it requires the SteamTools.inc and colors.inc. Please download the source and compile manually or download the .smx
