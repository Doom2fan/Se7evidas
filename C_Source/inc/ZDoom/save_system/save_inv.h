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

#ifndef SAVE_INV_H
#define SAVE_INV_H

#include <ACS_ZDoom.h>
#include "save_system/save_invdata.h"

// Typedefs
typedef struct SaveInv_InvInfo SaveInv_InvInfo;
typedef struct SaveInv_InvDef  SaveInv_InvDef;

// Structs
struct SaveInv_InvInfo {
    string name;
    int amount;
    void (*callback) (int playerNum);
    SaveInv_InvInfo *next;
};

struct SaveInv_InvDef {
    string cvarName;
    int maxCVars;
    int cvarMaxLen;
    int invArrSize;
    SaveInv_InvInfo *invInfoArr;
};

// Prototypes
void InvUpdAmmoMax (int playerNum);
bool SaveSys_SaveInventory (int playerNum, SavedData_t *data, SaveInv_InvDef *invDef);
bool SaveSys_LoadInventory (int playerNum, SavedData_t *data, SaveInv_InvDef *invDef);

#endif