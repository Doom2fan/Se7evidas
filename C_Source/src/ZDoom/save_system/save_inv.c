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
#include "misc/CSC.h"
#include "save_system/save.h"
#include "save_system/save_inv.h"

void InvUpdAmmoMax (int playerNum) {
    PlayerData_t *player = &PlayerData [playerNum]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgFunction InvUpdAmmoMax: Fatal error: Invalid or NULL player struct");
        return;
    }

    UpdatePlayerData (player);
    UpdateAmmoMax (player);
}

bool SaveSys_SaveInventory (int playerNum, SavedData_t *data, SaveInv_InvDef *invDef) {
    string output = s"";
    for (int i = 0; i < invDef->invArrSize; i++)
        output = StrParam ("%S%.4x%.8x", output, i, CheckInventory (invDef->invInfoArr [i].name));

    // Add compression to this someday maybe
    int index = 1;
    SetUserCVarString (playerNum, StrParam ("%S%d", invDef->cvarName, index++), StrMid (output, 0, invDef->cvarMaxLen));
    output = StrMid (output, invDef->cvarMaxLen, StrLen (output) + invDef->cvarMaxLen);
    while (TRUE) {
        if (StrLen (output) < invDef->cvarMaxLen)
            break;
        if (index >= invDef->maxCVars)
            return FALSE;

        SetUserCVarString (playerNum, StrParam ("%S%d", invDef->cvarName, index++), StrMid (output, 0, invDef->cvarMaxLen));
        output = StrMid (output, invDef->cvarMaxLen, StrLen (output) + invDef->cvarMaxLen);
    }
    if (StrLen (output) > 1) {
        if (index >= invDef->maxCVars)
            return FALSE;

        SetUserCVarString (playerNum, StrParam ("%S%d", invDef->cvarName, index++), StrMid (output, 0, invDef->cvarMaxLen));
        output = StrMid (output, invDef->cvarMaxLen, StrLen (output) + invDef->cvarMaxLen);
    }
    for (; index < invDef->maxCVars; index++)
        SetUserCVarString (playerNum, StrParam ("%S%d", invDef->cvarName, index), s"");

    return TRUE;
}

// 4 + 8
#define INV_ENTRY_LEN 12
bool SaveSys_LoadInventory (int playerNum, SavedData_t *data, SaveInv_InvDef *invDef) {
    string           input = s""; // Define input and initialize it to ""
    SaveInv_InvInfo *prev  = NULL;
    SaveInv_InvInfo *cur   = NULL;
    int             *offset; *offset = 0;

    for (int i = 0; i < invDef->maxCVars; i++) // Loop through the inventory data CVars
        input = StrParam ("%S%S", input, GetUserCVarString (playerNum, StrParam ("%S%d", invDef->cvarName, i + 1)));

    int length = StrLen (input);
    int count = length / INV_ENTRY_LEN;

    if (length % INV_ENTRY_LEN > 0)
        return FALSE;

    for (int i = 0; i < count; i++) {
        int type = SaveSys_ReadInt (input, offset, 4);
        int amount = SaveSys_ReadInt (input, offset, 8);

        if (type < 0 || type > invDef->invArrSize)
            return FALSE;

        SaveInv_InvInfo *inv = allocAndClear (sizeof (SaveInv_InvInfo)); // Define inv pointer and point it to a new memory area
        inv->name = invDef->invInfoArr [type].name;
        inv->amount = amount;
        inv->callback = invDef->invInfoArr [type].callback;
        inv->next = prev;
        prev = inv;
    }
    
    if (StrLen (input) < *offset)
        return FALSE;

    cur = prev;
    while (TRUE) {
        if (!cur)
            break;

        SetInventory (cur->name, cur->amount);
        if (cur->callback)
            cur->callback (playerNum);
        // Update prev and cur
        prev = cur;
        cur = cur->next;
        // Free prev
        prev->next = NULL;
        free (prev);
    }

    return TRUE;
}