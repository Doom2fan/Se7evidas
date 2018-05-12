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

#ifndef SERVER_H
#define SERVER_H

#include <ACS_ZDoom.h>

// Enums
enum {
    MEVNT_None            = 0, // This is here just in case you need to check it for some reason.
    MEVNT_GhostTown          ,
    MEVNT_PowerOutage        ,
    MEVNT_NuclearMeltdown    ,
    MEVNT_PerfectHatred      ,
    MEVNT_LastToken          , // This is here just so you don't have to keep track of the last event, it's not an actual event.
};

// Structs
typedef struct ServerData_t {
    string version;

    int gameType;
} ServerData_t;

typedef struct MapData_t {
    string name;
    string author;

    int mapEvent;
} MapData_t;

// Struct declarations
extern ServerData_t ServerData;
extern MapData_t map_var MapData;

// Prototypes
void UpdateServerData ();
Script_C void S7_SetMapInfo (string name, string author);

#endif