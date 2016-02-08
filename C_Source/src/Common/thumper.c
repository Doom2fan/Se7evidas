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
#include "weapon_stuff.h"
#include "stamina.h"
#include "thumper.h"

// help
// ;-;

string Thumper_PoolNames [] = {
    s"____Error____-Report-this",
    s"S7_Thumper_PExp",
    s"S7_Thumper_PFrag",
    s"S7_Thumper_PTherm",
    s"S7_Thumper_PFlare",
    s"S7_Thumper_PCluster",
    s"S7_Thumper_PNail",
    s"S7_Thumper_PNGas"
};

/* Mag scripts */

Script_C bool S7_ThumperFull () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    if (player->thumperDef.magIndex == 3) // If the current mag index is 3 (the max)...
        return TRUE; // Return true
    else // If not...
        return FALSE; // Return false
}

Script_C int S7_ThumperGetNext () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    
    if (player->thumperDef.magIndex == -1) // If there's no ammo left in the mag...
        return S7_TH_None; // Return none

    return player->thumperDef.magShells [player->thumperDef.magIndex]; // Return the next shell in the mag
}

/* Chamber scripts */

Script_C int S7_ThumperGetChamber () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    
    return player->thumperDef.currentShell; // Return the current shell
}

Script_C void S7_ThumperConsumeChamber () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct
    
    player->thumperDef.currentShell = S7_TH_None; // Set the current shell to none
    TakeInventory (s"S7_ThumperChambered", 1); // Take 1 S7_ThumperChambered/Consume the shell in the chamber
}

Script_C void S7_ThumperPump () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    player->thumperDef.currentShell = player->thumperDef.magShells [player->thumperDef.magIndex]; // Set the current shell to the next shell in the mag
    player->thumperDef.magShells [player->thumperDef.magIndex] = S7_TH_None; // Set the next shell in the mag to none
    player->thumperDef.magIndex--; // Decrement the mag index by 1
    GiveInventory (s"S7_ThumperChambered", 1); // Give 1 S7_ThumperChambered/Chamber the gun
}

/* Ammo pool scripts */

Script_C int S7_ThumperNextPool () {
    return CheckInventory (Thumper_PoolNames [CheckInventory (s"S7_ThumperSelectedPool") + 1]); // Return the amount of grenades in the currently selected pool
}

Script_C void S7_ThumperCyclePools () {
    int currentPool = CheckInventory (s"S7_ThumperSelectedPool") + 1; // Get the selected pool

    if (currentPool >= 7) // If the current pool is the last one...
        TakeInventory (s"S7_ThumperSelectedPool", 999); // Take all S7_ThumperSelectedPool
    else // If not...
        GiveInventory (s"S7_ThumperSelectedPool", 1); // Give 1 S7_ThumperSelectedPool
}

Script_C void S7_ThumperPerformReload () {
    PlayerData_t *player = &PlayerData [PLN]; // Get the player's PlayerData_t struct

    int currentPool = CheckInventory (s"S7_ThumperSelectedPool") + 1; // Get the selected pool
    if (currentPool > 7) // If the selected pool is greater than 7...
        currentPool = 7; // Set it to 7

    if (S7_ThumperNextPool () < 1) { // If there's less than 1 grenade left in the ammo pool...
        Log ("S7_ThumperPerformReload: Something went wrong. Please report this and the steps to reproduce it."); // Log it
        return; // Return
    }

    player->thumperDef.magIndex++; // Increment the mag index by 1
    player->thumperDef.magShells [player->thumperDef.magIndex] = currentPool; // Set the next shell in the mag to the same as the selected pool
    TakeInventory (Thumper_PoolNames [currentPool], 1); // Take 1 from the selected pool
}

int Thumper_GetUnifiedPool () {
    int unifiedPool;

    for (int i = 1; i < ArraySize (Thumper_PoolNames); i++) {
        unifiedPool += CheckInventory (Thumper_PoolNames [i]);
    }

    return unifiedPool;
}

int Thumper_GetUnifiedPoolMax () {
    if (CheckInventory (s"Backpack"))
        return 40;
    else
        return 30;
}

int Thumper_GiveShell (int typeI, int amount) {
    string type = Thumper_PoolNames [typeI];

    if (Thumper_GetUnifiedPool () + amount > Thumper_GetUnifiedPoolMax ()) {
        return FALSE;
    } else {
        GiveInventory (type, amount);
        return TRUE;
    }
}

Script_C int S7_ThumperGiveShell (int type, int amount) {
    return Thumper_GiveShell (type, amount);
}

void Thumper_Script (PlayerData_t *player) {
    int unifiedPool = Thumper_GetUnifiedPool ();
    if (CheckInventory (s"S7_Thumper_PUnified") != unifiedPool) {
        SetInventory (s"S7_Thumper_PUnified", unifiedPool);
    }
}

void Thumper_ScriptClientside (PlayerData_t *player) {
    int i = 1;
    for (; i <= player->thumperDef.magIndex; i++) {
        string mag = StrParam ("S7_ThumperMag%d", i);

        if (CheckInventory (mag) != player->thumperDef.magShells [i]) {
            SetInventory (mag, player->thumperDef.magShells [i]);
        }
    }
    string chamber = StrParam ("S7_ThumperMag%d", i);
    i++;
    for (int j = i; j <= 5; j++) {
        string mag = StrParam ("S7_ThumperMag%d", i);

        TakeInventory (mag, 999);
    }
}