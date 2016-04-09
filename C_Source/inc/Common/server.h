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

#ifndef SERVER_H
#define SERVER_H

#include <ACS_ZDoom.h>

// Enums
enum {
    MEVNT_None            = 0, // This is here just so you don't have to keep track of the first event, it's not an actual event.
    MEVNT_GhostTown       = 1,
    MEVNT_PowerOutage     = 2,
    MEVNT_NuclearMeltdown = 3,
    MEVNT_PerfectHatred   = 4,
    MEVNT_LastToken          , // This is here just so you don't have to keep track of the last event, it's not an actual event.
};

// Structs
typedef struct ServerData_t {
    // Parkour stuff
    int   dodgeCooldown;
    accum mjumpZMul;
    
    // Save system stuff
    bool noSaveLoading;

    // Misc map info
    int mapCount;
} ServerData_t;

typedef struct MapData_t {
    int mapEvent;
    int meSecLoopDelay;
} MapData_t;

// Struct declarations
ServerData_t ServerData;
MapData_t map_var MapData;

// Prototypes
void SetupMapEvents   ();
void UpdateServerData ();
void UpdateMapData    ();

#endif