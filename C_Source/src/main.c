/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015-???  Chronos Ouroboros
**
**  This program is free software; you can redistribute it and/or modify
**  it under the terms of the GNU General Public License as published by
**  the Free Software Foundation; either version 2 of the License, or
**  (at your option) any later version.
**
**  This program is distributed in the hope that it will be useful,
**  but WITHOUT ANY WARRANTY; without even the implied warranty of
**  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
**  GNU General Public License for more details.
**
**  You should have received a copy of the GNU General Public License along
**  with this program; if not, write to the Free Software Foundation, Inc.,
**  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
*/

#include "includes.h"

void ResetStuff (PlayerData_t *player);

Script_C void S7_ServersideOpen OPEN () {
    ServerData.version = ScriptCallString (s"S7_ACSBridge", s"GetVersion");

    #ifdef DEBUG
    Log_Str (s"Se7evidas version %S\nSe7evidas ACSVM Library compiled at %s %s.", ServerData.version, __DATE__, __TIME__);
    #endif

    if (GetCVar (s"S7_DebugMode"))
        Log_Str (s"\CgSe7evidas: Debug mode is active (S7_DebugMode)");

    if (MapData.name == NULL) {
        MapData.name = StrParam ("%tS", PRINTNAME_LEVELNAME);
        MapData.author = s"";
    }

    while (TRUE) {
        UpdateServerData (); // Update server data

        Delay (1);
    }
}
Script_C void S7_ShowMapInfo () {
    Delay (20);
    SetFont (s"BIGFONT");
    HudMessage (HUDMSG_FADEINOUT, 0, CR_RED, 0.5k, 0.625k, 4.0k, 1.0k, 1.0k, 0.0k, "%S", MapData.name);
    if (StrCmp (MapData.author, s"") != 0) {
        SetFont (s"SMALLFNT");
        HudMessage (HUDMSG_FADEINOUT, 0, CR_WHITE, 0.5k, 0.65625k, 4.0k, 1.0k, 1.0k, 0.0k, "By %S", MapData.author);
    }
}

// General stuff
Script_C void S7_ServersideEnter ENTER () {
    // Not needed or desired in TitleMaps.
    if (GameType () == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        PlayerData_t tmp;
        PlayerData [PLN] = tmp;
        player = &PlayerData [PLN];
    }

    if (!player->initialized) {
        InitializePlayer (player);
    } else {
        FadeRange (0, 0, 0, 1.0k, 0, 0, 0, 0.0k, TicsToSecs (9));
        SetPlayerProperty (FALSE, OFF, PROP_TOTALLYFROZEN);
        TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
    }

    S7_ShowMapInfo ();

    ResetPlayer (player);

    /*while (TRUE) { // Loop forever
        if (!PlayerInGame (PLN))
            return;


        Delay (1); // Wait for a tic
    }*/
}

Script_C void S7_MapStart ENTER () {
    SetHudSize (640, 480, FALSE);
    switch (MapData.mapEvent) {
        case MEVNT_GhostTown:
        break;

        case MEVNT_PowerOutage:
        break;

        case MEVNT_NuclearMeltdown:
        break;

        case MEVNT_PerfectHatred:
            SetFont (s"GARGWING");
            cstr s = CorruptText ((cstr) "Perfect Hatred");
            HudMessage (HUDMSG_FADEINOUT, 10000, CR_UNTRANSLATED, 250.1k, 320, 2.5k, 0.8k, 0.0k, 0.0k, s);
            Delay (2.5k * 35);
            for (int i = strlen (s) - 1; i >= 0; --i) {
                s [i] = 0;
                HudMessage (HUDMSG_PLAIN, 10000, CR_UNTRANSLATED, 250.1k, 320, 0.5k, 0.0k, 0.0k, 0.0k, "%s", s);
                Delay (3);
            }
        break;

        default:
        break;
    }
}

Script_C void S7_ServersideRespawn RESPAWN () {
    // Not needed or desired in TitleMaps.
    if (ServerData.gameType == GAME_TITLE_MAP || !PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript S7_ServersideRespawn: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    ResetPlayer (player);
}

Script_C void S7_ServersideDisconnect DISCONNECT (int num) {
    // Not needed or desired in TitleMaps.
    if (ServerData.gameType == GAME_TITLE_MAP)
        return;

    PlayerData_t *player = &PlayerData [num]; // Get the player's PlayerData_t struct

    if (!player) {
        DebugLog ("\CgScript S7_ServersideDisconnect: Fatal error: Invalid or NULL player struct for player %d.", num);
        return;
    }

    DisconnectPlayer (player);
}