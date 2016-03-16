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
#include "monster_stuff.h"

Script_C void S7_EmpressScript () {
    if (!CheckInventory (EMPIDENT))
        return;

    int invulnDelay,
        ballsCount,
        newHealth, health;

    newHealth = GetActorProperty (0, APROP_Health);
    health = EMPMHEALTH;
    while (TRUE) {
        ballsCount = CheckInventory (s"S7_EmpressBalls");
        health += -(0x7FFFFFFF - newHealth);

        if (health > EMPINVLIMIT || ballsCount > 0) {
            SetInventory (EMPINVTOKEN, FALSE);
            if (ballsCount > 0)
                invulnDelay = EMPINVDELAY;
        } else if (invulnDelay) {
            SetInventory (EMPINVTOKEN, FALSE);
            invulnDelay--;
        } else if (health <= EMPINVLIMIT && ballsCount < 1 && invulnDelay < 1)
            SetInventory (EMPINVTOKEN, TRUE);

        SetUserVariable (0, EMPHPVAR, health);

        Delay (1);

        if (!CheckInventory (ISDEADTOKEN)) {
            newHealth = GetActorProperty (0, APROP_Health);
            SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
        } else {
            newHealth = 0x7FFFFFFF;

            if (GetActorProperty (0, APROP_Health) > 0) {
                SetActorProperty (0, APROP_Health, 0x7FFFFFFF);
            }
        }
    }
}

/*Script_C void S7_SLanceBeamGrab () {
    accum x1 = GetActorX (0), y1 = GetActorY (0), z1 = GetActorZ (0);
    accum x2, y2, z2, xDiff, yDiff, zDiff;
    long accum angel, bitch;
    int flickerDelay = Random (8, 35 * 2);
    bool justFlickered = FALSE;

    SetActivatorToTarget (0);

    while (TRUE) {
        if (!CheckInventory (s"S7_SoulLance_BeamGrabbed"))
            break;

        if (flickerDelay < 1) {
            GiveInventory (DISABLEHUDTOKEN, 1);
            flickerDelay = Random (8, 35 * 2);
            justFlickered = TRUE;
        } else {
            flickerDelay--;
        }

        x2 = GetActorX (0); y2 = GetActorY (0); z2 = GetActorZ (0);
        xDiff = x1 - x2; yDiff = y1 - y2; zDiff = z1 - z2;
        angel = FixedSqrt ((long accum) xDiff * xDiff + yDiff * yDiff);
        bitch = FixedSqrt ((long accum) xDiff * xDiff + yDiff * yDiff + zDiff * zDiff);
        //bitch = ScaleValueAccum (bitch, -1.0k, 1.0k, -0.25k, 0.25k);

        SetActorAngle (0, ScaleValueAccum (angel, 0.0k, 360.0k, 0.0k, 1.0k));
        //SetActorPitch (0, (accum) -(ScaleValueAccum (bitch, -1.0k, 1.0k, -0.25k, 0.25k)));
        PrintBold ("%k", (accum) angel);

        Delay (1);

        if (justFlickered) {
            TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
            justFlickered = FALSE;
        }
    }
}*/

Script_C void S7_SLanceBeamGrabP2 (vec3_k *holderPos, bool *stopNow);

Script_C void S7_SLanceBeamGrab () {
    vec3_k holderPos;
    bool stopNow = FALSE;

    holderPos.x = GetActorX (0);
    holderPos.y = GetActorY (0);
    holderPos.z = GetActorZ (0);

    S7_SLanceBeamGrabP2 (&holderPos, &stopNow);

    while (TRUE) {
        if (stopNow)
            break;

        holderPos.x = GetActorX (0);
        holderPos.y = GetActorY (0);
        holderPos.z = GetActorZ (0);

        Delay (1);
    }
}

Script_C void S7_SLanceBeamGrabP2 (vec3_k *holderPos, bool *stopNow) {
    SetActivatorToTarget (0);

    vec3_k playerPos, posDiff;
    accum angle, bitch;
    int flickerDelay = Random (8, 35 * 2);
    bool justFlickered = FALSE;

    while (TRUE) {
        /*if (!CheckInventory (s"S7_SoulLance_BeamGrabbed")) {
            *stopNow = TRUE;
            break;
        }*/

        if (flickerDelay < 1) {
            GiveInventory (DISABLEHUDTOKEN, 1);
            flickerDelay = Random (8, 35 * 2);
            justFlickered = TRUE;
        } else {
            flickerDelay--;
        }

        playerPos.x = GetActorX (0);
        playerPos.y = GetActorY (0);
        playerPos.z = GetActorZ (0);
        posDiff.x = (holderPos->x) - playerPos.x;
        posDiff.y = (holderPos->y) - playerPos.y;
        posDiff.z = (holderPos->z) - playerPos.z;

        angle = VectorAngle (posDiff.x, posDiff.y);
        bitch = -VectorAngle (angle, posDiff.z);

        /*if (bitch > 0.0k)
            bitch = ScaleValueAccum (bitch, 0.0k, 0.75k, 0.0k, -0.25k);*/

        PrintBold ("%k", bitch);

        Delay (1);
        
        SetActorAngle (0, angle);
        SetActorPitch (0, bitch);

        if (justFlickered) {
            TakeInventory (DISABLEHUDTOKEN, 0x7FFFFFFF);
            justFlickered = FALSE;
        }
    }
}

Script_C void FloatTest () {
    long accum lk = 262144.0lk;

    PrintBold ("%k %k", (accum) lk, (accum) LongFixedSqrt (lk));
}