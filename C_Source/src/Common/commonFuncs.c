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

#include "util.h"
#include "util_math.h"
#include "commonFuncs.h"
#undef SHORT_NAMES

int KeyUp (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if (~buttons & key)
        return 1;
    
    return 0;
}

int KeyDown (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if (buttons & key)
        return 1;
    
    return 0;
}

int KeyPressed (int key) {
    int buttons     = GetPlayerInput (-1, INPUT_BUTTONS);
    int oldbuttons  = GetPlayerInput (-1, INPUT_OLDBUTTONS);
    int newbuttons  = (buttons ^ oldbuttons) & buttons;

    if (newbuttons & key)
        return 1;
    
    return 0;
}

int KeyPressed2 (int buttons, int oldbuttons, int key) {
    int newbuttons  = (buttons ^ oldbuttons) & buttons;

    if (newbuttons & key)
        return 1;
    
    return 0;
}

int UnusedTID (int start, int end) {
    int ret = start - 1;
    int tidNum;
    if (start > end) {
        start ^= end;
        end ^= start;
        start ^= end;
    } // good ol' XOR swap
    while (ret++ != end) {
        if (ThingCount (0, ret) == 0)
            return ret;
    }
    
    return -1;
}

accum GetVelocity () { // I dunno who made this...
    accum vel;
    accum x = GetActorVelX (0);
    accum y = GetActorVelY (0);
    accum angle = VectorAngle (x, y);
    
    if (((angle + 0.125k) % 0.5k) > 0.25k)
        vel = y / Sin (angle);
    else
        vel = x / Cos (angle);
    
    return vel;
}

int Clamp (int x, int min, int max) {
    int realMin = min;
    int realMax = max;
    
    if (min > max) {
        realMax = min;
        realMin = max;
    }
    
    if (x > realMax)
        return realMax;
    else if (x < realMin)
        return realMin;
    else
        return x;
}

accum ClampAccum (accum x, accum min, accum max) {
    accum realMin = min;
    accum realMax = max;
    
    if (min > max) {
        realMax = min;
        realMin = max;
    }
    
    if (x > realMax)
        return realMax;
    else if (x < realMin)
        return realMin;
    else
        return x;
}

int ScaleValue (int x, int fromMin, int fromMax, int toMin, int toMax) {
    return (x - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
}

accum ScaleValueAccum (accum x, accum fromMin, accum fromMax, accum toMin, accum toMax) {
    return (x - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
}

bool SetInventory (string name, int amount) {
    int currentAmount = CheckInventory (name);

    if (currentAmount == amount) {
        return FALSE;
    } else if (currentAmount > amount)
        TakeInventory (name, currentAmount - amount);
    else if (currentAmount < amount)
        GiveInventory (name, amount - currentAmount);
    
    return TRUE;
}

accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z,
                 accum actor2X, accum actor2Y, accum actor2Z) {
    return VectorLength (actor1Z - actor2Z, VectorLength (actor1X - actor2X, actor1Y - actor2Y));
}