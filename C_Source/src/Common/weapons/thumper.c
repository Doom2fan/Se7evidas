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
#include "weapons/weapon_stuff.h"
#include "systems/stamina.h"
#include "weapons/thumper.h"

// help
// ;-;

#define SELPOOLTOKEN s"S7_ThumperSelectedPool"
#define CHAMBEREDTOKEN s"S7_ThumperChambered"
#define CURRENTSHELLTOKEN s"S7_ThumperCurrentShell"

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

/* Mag scripts */

Script_C bool S7_ThumperFull () {
    if (!PlayerInGame (PLN))
        return TRUE;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperFull: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return FALSE;
    }

    if (player->thumperDef.magIndex == 3) // If the current mag index is 3 (the max)...
        return TRUE; // Return true
    else // If not...
        return FALSE; // Return false
}

Script_C int S7_ThumperGetNext () {
    if (!PlayerInGame (PLN))
        return S7_TH_None;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperGetNext: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return S7_TH_None;
    }

    if (player->thumperDef.magIndex == -1) // If there's no ammo left in the mag...
        return S7_TH_None; // Return none

    return player->thumperDef.magShells [player->thumperDef.magIndex]; // Return the next shell in the mag
}

/* Chamber scripts */

Script_C int S7_ThumperGetChamber () {
    if (!PlayerInGame (PLN))
        return S7_TH_None;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperGetChamber: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return S7_TH_None;
    }

    return player->thumperDef.currentShell; // Return the current shell
}

Script_C void S7_ThumperConsumeChamber () {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperConsumeChamber: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    player->thumperDef.currentShell = S7_TH_None; // Set the current shell to none
    TakeInventory (CHAMBEREDTOKEN, 1); // Take 1 CHAMBEREDTOKEN/Consume the shell in the chamber
}

Script_C void S7_ThumperPump () {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperPump: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    player->thumperDef.currentShell = player->thumperDef.magShells [player->thumperDef.magIndex]; // Set the current shell to the next shell in the mag
    player->thumperDef.magShells [player->thumperDef.magIndex] = S7_TH_None; // Set the next shell in the mag to none
    player->thumperDef.magIndex--; // Decrement the mag index by 1
    GiveInventory (CHAMBEREDTOKEN, 1); // Give 1 CHAMBEREDTOKEN/Chamber the gun
    SetInventory (CURRENTSHELLTOKEN, player->thumperDef.currentShell); // Set CURRENTSHELLTOKEN to the current shell
}

/* Ammo pool scripts */

Script_C int S7_ThumperNextPool () {
    return CheckInventory (Thumper_PoolNames [CheckInventory (SELPOOLTOKEN) + 1]); // Return the amount of grenades in the currently selected pool
}

int ThumperCyclePools_DoCycle (int current) {
    bool looped = FALSE;
    int i = current + 1;
    while (TRUE) {
        if (CheckInventory (Thumper_PoolNames [i]) > 0)
            return i;

        if (i == current && looped)
            return -1;
        else if (i >= TH_POOLNAMES_MAX) {
            if (!looped) {
                i = 0;
                looped = TRUE;
            } else
                return -1;
        }

        i++;
    }

    return -1;
}

Script_C bool S7_ThumperCyclePools () {
    int currentPool = CheckInventory (SELPOOLTOKEN) + 1; // Get the selected pool

    int nextPool = ThumperCyclePools_DoCycle (currentPool);

    if (nextPool < 1 || currentPool == nextPool)
        return FALSE;
    else {
        SetInventory (SELPOOLTOKEN, nextPool - 1);
        return TRUE;
    }
}

Script_C void S7_ThumperPerformReload () {
    if (!PlayerInGame (PLN))
        return;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript S7_ThumperPerformReload: Fatal error: Invalid or NULL player struct for player %d.", PLN);
        return;
    }

    int currentPool = CheckInventory (SELPOOLTOKEN) + 1; // Get the selected pool
    if (currentPool > 7) // If the selected pool is greater than 7...
        currentPool = 7; // Set it to 7

    player->thumperDef.magShells [++player->thumperDef.magIndex] = currentPool; // Set the next shell in the mag to the same as the selected pool while incrementing the mag index
    TakeInventory (Thumper_PoolNames [currentPool], 1); // Take 1 from the selected pool
}

int Thumper_GetUnifiedPool () {
    int unifiedPool;

    for (int i = 1; i <= TH_POOLNAMES_MAX; i++)
        unifiedPool += CheckInventory (Thumper_PoolNames [i]);

    return unifiedPool;
}

int Thumper_GetUnifiedPoolMax () {
    if (!PlayerInGame (PLN))
        return NULL;

    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (!player) {
        Log ("\CgScript Thumper_GetUnifiedPoolMax: Fatal error: Invalid or NULL player struct.");
        return NULL;
    }

    return 5 * player->ammoMax;
}

void Thumper_GiveShell (int typeI, int amount) {
    string type = Thumper_PoolNames [typeI];

    if (Thumper_GetUnifiedPool () + amount > Thumper_GetUnifiedPoolMax ())
        return;

    GiveInventory (type, amount);
}

void Thumper_TakeShell (int typeI, int amount) {
    string type = Thumper_PoolNames [typeI];

    TakeInventory (type, amount);
}

Script_C void S7_ThumperGiveShell (int type, int amount) {
    Thumper_GiveShell (type, amount);
}

void Thumper_Script (PlayerData_t *player) {
    if (!player)
        return;

    SetInventory (s"S7_Thumper_PUnified", Thumper_GetUnifiedPool ());
}

void Thumper_ScriptClientside (PlayerData_t *player) {
    if (!player)
        return;

    SetInventory (s"S7_ThumperMag", player->thumperDef.magIndex + 1 + (player->thumperDef.currentShell != S7_TH_None ? 1 : 0));

    int magN = 1;
    for (int i = 0; i <= player->thumperDef.magIndex; i++) {
        string mag = StrParam ("S7_ThumperMag%d", magN++);

        SetInventory (mag, player->thumperDef.magShells [i]);
    }
    string chamber = StrParam ("S7_ThumperMag%d", magN++);
    SetInventory (chamber, player->thumperDef.currentShell);
    if (magN < 6) {
        for (int j = magN - 1; j < 5; j++) {
            string mag = StrParam ("S7_ThumperMag%d", magN++);

            if (mag != S7_TH_None)
                SetInventory (mag, 0);
        }
    }
}