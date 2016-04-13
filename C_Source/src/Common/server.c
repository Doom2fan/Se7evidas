/*
**  Se7evidas - A GZDoom mod
**  Copyright (C) 2015  Chronos Ouroboros
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

#define SERVER_C
#include "includes.h"
#undef SERVER_C
#include "server.h"

Script_C void S7_LightLevelScript (int start, int end, int time, int lvl) {
    Delay (time);

    for (int i = start; i >= end; i--) {
        Light_ChangeToValue (i, lvl);
        Light_Stop (i);
    }
}

void SetupMapEvents () {
    if (ServerData.mapCount > 0)// && Random (FALSE, TRUE))
        MapData.mapEvent = MEVNT_GhostTown;// Random (MEVNT_None + 1, MEVNT_LastToken - 1);
    else
        MapData.mapEvent = MEVNT_None;

    switch (MapData.mapEvent) {
        case MEVNT_PowerOutage:
            ChangeSky (s"NEBSKY", s""); // Change the sky

            S7_LightLevelScript (32767,      0, 0, 64); // Change the light level to 64
            S7_LightLevelScript (   -1, -32768, 0, 64);
        break;

        case MEVNT_PerfectHatred:
            ChangeSky (s"ATWSKY", s""); // Change the sky

            S7_LightLevelScript (32767,      0, 0, 1); // Change the light level to 1
            S7_LightLevelScript (   -1, -32768, 0, 1);
        break;

        case MEVNT_GhostTown: {
            int tid = UniqueTID (); // Get an unused TID

            SetMusic (s""); // Remove the music
            Spawn (s"MapSpot", 0.0k, 0.0k, 0.0k, tid, 0); // Spawn a mapspot
            PlaySound (tid, s"World/Wind", CHAN_BODY | CHAN_LISTENERZ | CHAN_NOPAUSE, 1.0k, TRUE, 0.0k); // Play a wind sound on it
            Thing_ChangeTID (tid, 0); // Change the mapspot's TID to 0
        }
        break;

        case MEVNT_LastToken:
            DebugMsg (s"\CgGot MEVNT_LastToken as the map event.");
            MapData.mapEvent = Random (MEVNT_None + 1, MEVNT_LastToken - 1);
        break;

        default:
        break;
    }
}

void UpdateServerData () {
    // Parkour stuff
    ServerData.dodgeCooldown = GetCVar      (s"S7_DodgeCooldown");
    ServerData.mjumpZMul     = GetCVarFixed (s"S7_MultiJumpZMul");

    // Save system stuff
    ServerData.noSaveLoading = GetCVar      (s"S7_NoSaveLoading");
}

#define ME_CLSLoop(sky, light) \
    if (MapData.meSecLoopDelay <= 0) { \
        ChangeSky (sky, s""); \
        S7_LightLevelScript ( 32767,  16385,  0, light); \
        S7_LightLevelScript ( 16384,      0,  6, light); \
        S7_LightLevelScript (    -1, -16384, 12, light); \
        S7_LightLevelScript (-16385, -32768, 18, light); \
    } \
    if (MapData.meSecLoopDelay <= 0) \
        MapData.meSecLoopDelay = 15 * 35

void UpdateMapData () {
    if (MapData.meSecLoopDelay > 0)
        MapData.meSecLoopDelay--;

    switch (MapData.mapEvent) {
        case MEVNT_PowerOutage:
            ME_CLSLoop (s"NEBSKY", 64); // Change the sky; Change the light level to 64
        break;

        case MEVNT_PerfectHatred:
            ME_CLSLoop (s"ATWSKY", 1); // Change the sky; Change the light level to 1
        break;

        case MEVNT_GhostTown:
            SetMusic (s""); // Remove the music
        break;

        case MEVNT_LastToken:
            DebugMsg (s"\CgGot MEVNT_LastToken as the map event.");
            MapData.mapEvent = Random (MEVNT_None + 1, MEVNT_LastToken - 1);
        break;

        default:
        break;
    }
}