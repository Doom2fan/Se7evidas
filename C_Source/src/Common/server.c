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
        ServerData.mapEvent = 1;// Random (1, 4);

    switch (ServerData.mapEvent) {
        case 1:
            ChangeSky (s"NEBSKY", s"");

            S7_LightLevelScript (32767,      0, 0, 64);
            S7_LightLevelScript (   -1, -32768, 0, 64);
            break;

        default:
            break;
    }
}

void UpdateServerData () {
    if (ServerData.meSecLoopDelay > 0)
        ServerData.meSecLoopDelay--;

    // Parkour stuff
    ServerData.dodgeCooldown = GetCVar      (s"S7_DodgeCooldown");
    ServerData.mjumpZMul     = GetCVarFixed (s"S7_MultiJumpZMul");

    // Save system stuff
    ServerData.noSaveLoading = GetCVar      (s"S7_NoSaveLoading");

    switch (ServerData.mapEvent) {
        case 1:
            if (ServerData.meSecLoopDelay <= 0) {
                ChangeSky (s"NEBSKY", s"");
                S7_LightLevelScript ( 32767,  16385,  0, 64);
                S7_LightLevelScript ( 16384,      0,  6, 64);
                S7_LightLevelScript (    -1, -16384, 12, 64);
                S7_LightLevelScript (-16385, -32768, 18, 64);
            }

            if (ServerData.meSecLoopDelay <= 0)
                ServerData.meSecLoopDelay = 15 * 35;
        break;

        default:
        break;
    }
}