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
#include "weapons/weap_data.h"
#include "misc/debugFuncs.h"

Script_C void S7_DebugVelocity NET () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    accum x = 0, y = 0, z = 0,
        angle = 0, speed = 0;
    while (TRUE) {
        x = GetActorVelX (0);
        y = GetActorVelY (0);
        z = GetActorVelZ (0);
        speed = x * x + y * y + z * z;
        Print ("Velocity: %k\n", FixedSqrt (speed));

        Delay (1);
    }
}

Script_C void S7_DebugVelocityInKmH NET () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    accum x = 0, y = 0, z = 0,
        speed = 0, speed2;
    while (TRUE) {
        x = GetActorVelX (0);
        y = GetActorVelY (0);
        z = GetActorVelZ (0);
        speed = x * x + y * y + z * z;
        speed2 = 3.6k * ((FixedSqrt (speed) * 35.0k) / 64.0k);
        Print ("Velocity: %k km/h\n", speed2);

        Delay (1);
    }
}

string PrintInv_Generic (string inStr, const string arr [], int arrSize) {
    string ret = inStr;

    for (int i = 0; i < arrSize; i++)
        if (CheckInventory (arr [i]))
            ret = StrParam ("%S\n  %S (%d)", ret, arr [i], CheckInventory (arr [i]));

    return ret;
}
string PrintInv_Weapons (string inStr) {
    string ret = inStr;

    for (int i = 0; i < WeaponNames_Length; i++)
        if (CheckInventory (WeaponNames [i]))
            ret = StrParam ("%S\n  %S", ret, WeaponNames [i]);

    return ret;
}
Script_C void S7_PrintInv NET (int mode) {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    string inv = s"S7_PrintInv: String \"inv\" wasn't set. Error?";

    switch (mode) {
        case 1:
            inv = PrintInv_Generic (s"Ammo:", AmmoNames, AmmoNames_Length);
        break;
        
        case 2:
            inv = PrintInv_Weapons (s"Weapons:");
        break;

        case 3:
            inv = PrintInv_Generic (s"Ammo in weapons:", ClipNames, ClipNames_Length);
        break;

        case 4: break;

        default:
            inv = PrintInv_Generic (s"Ammo:", AmmoNames, AmmoNames_Length);
            inv = PrintInv_Weapons (StrParam ("%S\n\nWeapons:", inv));
            inv = PrintInv_Generic (StrParam ("%S\n\nAmmo in weapons:", inv), ClipNames, ClipNames_Length);
        break;
    }

    Log ("%S", inv);
}

Script_C void S7_PrintServerData NET () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    Log ("ServerData = {\n \
    debugMode = %s; \
    dodgeCooldown = %d;\n \
    mjumpZMul = %kk;\n \
    noSaveLoading = %s;\n \
    mapCount = %d;\n};",
    ServerData.debugMode ? "TRUE" : "FALSE", ServerData.dodgeCooldown, ServerData.mjumpZMul, ServerData.noSaveLoading ? "TRUE" : "FALSE", ServerData.mapCount);
}
Script_C void S7_PrintMapData NET () {
    if (!CheckCheats () || !PlayerInGame (PLN))
        return;

    Log ("MapData = {\n \
    name = \"%S\";\n \
    author = \"%S\";\n \
    mapEvent = %d;\n \
    meSecLoopDelay = %d;\n \
    mapEventSet = %S;\n};",
    MapData.name, MapData.author, MapData.mapEvent, MapData.meSecLoopDelay, MapData.mapEventSet ? s"TRUE" : s"FALSE");
}

/*enum {
};*/

void DebugOptsPlayer (PlayerData_t *player, bool debugOn, int debugOpts) {
    if (!player) {
        DebugLog ("\CgFunction DebugOptsPlayer: Fatal error: Invalid or NULL player struct.");
        return;
    }

    if (!debugOn || !CheckCheats ())
        return;
}