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