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

#include "includes.h"
#include "common/player.h" // Just to make sure

PlayerData_t PlayerData [MAX_PLAYERS];

string PD_Gender [] = {
    s"GEN_MALE",
    s"GEN_FEM",
    s"GEN_OTHER",
    s"GEN_HERM",
};
int PD_Gender_Length = ArraySize (PD_Gender);

PD_AmmoType_t PD_AmmoTypes [] = {
    {
        .name = s"S7_9mmCartridges",
        .magSize = 75,
    },
    {
        .name = s"S7_45ACPCartridges",
        .magSize = 62,
    },
    {
        .name = s"S7_44MCartridges",
        .magSize = 6,
    },
    {
        .name = s"S7_762x39Cartridges",
        .magSize = 35,
    },
    {
        .name = s"S7_20gaShells",
        .magSize = 10,
    },
    {
        .name = s"S7_12gaShells",
        .magSize = 12,
    },
    {
        .name = s"S7_Cells",
        .magSize = 36,
    },
    {
        .name = s"S7_FBSysCells",
        .magSize = 23,
    },
    {
        .name = s"S7_Thumper_PExp",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PFrag",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PTherm",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PFlare",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PCluster",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PNail",
        .magSize = 5,
    },
    {
        .name = s"S7_Thumper_PNGas",
        .magSize = 5,
    },
};
int PD_AmmoTypes_Length = ArraySize (PD_AmmoTypes);

string ReqClientsideCVars [] [2] = {
    { s"screenblocks", s"S7_Screenblocks", },
};
int ReqClientsideCVars_Length = ArraySize (ReqClientsideCVars);