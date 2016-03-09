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

#ifndef THUMPER_H
#define THUMPER_H

#include <ACS_ZDoom.h>

// Prototypes
int  Thumper_GetUnifiedPool    ();
int  Thumper_GetUnifiedPoolMax ();
void Thumper_GiveShell (int typeI, int amount);
void Thumper_TakeShell (int typeI, int amount);
void Thumper_Script           (PlayerData_t *player);
void Thumper_ScriptClientside (PlayerData_t *player);

// Variables/Stuff
#define TH_POOLNAMES_MAX 7
const string Thumper_PoolNames [] = {
    s"____Error____-Report-this",
    s"S7_Thumper_PExp",
    s"S7_Thumper_PFrag",
    s"S7_Thumper_PTherm",
    s"S7_Thumper_PFlare",
    s"S7_Thumper_PCluster",
    s"S7_Thumper_PNail",
    s"S7_Thumper_PNGas",
    s"____Error____-Report-this",
    s"____Error____-Report-this",
    s"____Error____-Report-this",
    s"____Error____-Report-this",
};

#endif