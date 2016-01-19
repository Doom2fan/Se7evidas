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
#include "debugFuncs.h"

#ifdef DEBUG
Script_C void S7_DebugVelocity () {
    accum x = 0, y = 0, z = 0,
        angle = 0, speed = 0;
    while (true) {
        x = GetActorVelX (0);
        y = GetActorVelY (0);
        z = GetActorVelZ (0);
        speed = x * x + y * y + z * z;
        Print ("Velocity: %k\n", FixedSqrt (speed));
        
        Delay (1);
    }
}

Script_C void S7_DebugVelocityInKmH () {
    accum x = 0, y = 0, z = 0,
        speed = 0, speed2;
    while (true) {
        x = GetActorVelX (0);
        y = GetActorVelY (0);
        z = GetActorVelZ (0);
        speed = x * x + y * y + z * z;
        speed2 = 3.6k * ((FixedSqrt (speed) * 35.0k) / 64.0k);
        Print ("Velocity: %k km/h\n", speed2);
        
        Delay (1);
    }
}

/*Script_C void S7_PrintInv (int mode) {
    string inv = "S7_PrintInv: String \"inv\" wasn't set. Error?";

    if (mode == 1) {

    } else if (mode == 2) {

    } else if (mode == 3) {

    } else {

    }

    Log (inv);
}

const string [] PrintInv_AmmoList = {
    s"S7_20gaShells",
    s"S7_Cells"
}
string void PrintInv_Ammo () {
    string result = s"";

    for (int i = 0; i < ArraySize (PrintInv_AmmoList); i++)
        result = StrParam ("%s\n%s", result, StrParam ("%s (%s)", PrintInv_AmmoList [i], CheckInventory (PrintInv_AmmoList [i])));
}*/
#endif