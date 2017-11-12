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

#define SERVER_C
#include "includes.h"
#undef SERVER_C
#include "common/server.h"

ServerData_t ServerData;
MapData_t map_var MapData;

Script_C void S7_LightLevelScript (int start, int end, int time, int lvl) {
    Delay (time);

    for (int i = start; i >= end; i--) {
        Light_ChangeToValue (i, lvl);
        Light_Stop (i);
    }
}

Script_C void S7_SetMapInfo (string name, string author) {
    MapData.name = name;
    MapData.author = author;
}

Script_C int S7_GetMapEvent () {
    return 0;
}

void UpdateServerData () {
    ServerData.debugMode = GetCVar (s"S7_DebugMode");

    // Game info
    ServerData.gameType = GameType ();

    // Parkour stuff
    ServerData.mjumpZMul     = GetCVarFixed (s"S7_MultiJumpZMul");

    // RPG system stuff
    ServerData.maxLevel = GetCVar (s"S7_MaxLevel");
    ServerData.avgLevel     = 1;
    ServerData.highestLevel = 1;
    ServerData.lowestLevel  = 0;
}