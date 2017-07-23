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
        DebugLog ("\CgScript Thumper_GetUnifiedPoolMax: Fatal error: Invalid or NULL player struct.");
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