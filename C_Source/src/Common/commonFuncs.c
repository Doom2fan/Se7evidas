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
#undef ACS_SHORT_NAMES

int KeyUp (int key) {
    int buttons = ACS_GetPlayerInput (-1, INPUT_BUTTONS);

    if (~buttons & key)
        return 1;
    
    return 0;
}

int KeyDown (int key) {
    int buttons = ACS_GetPlayerInput (-1, INPUT_BUTTONS);

    if (buttons & key)
        return 1;
    
    return 0;
}

int KeyPressed (int key) {
    int buttons     = ACS_GetPlayerInput (-1, INPUT_BUTTONS);
    int oldbuttons  = ACS_GetPlayerInput (-1, INPUT_OLDBUTTONS);
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
        if (ACS_ThingCount (0, ret) == 0)
            return ret;
    }
    
    return -1;
}

// I dunno who made this...
int GetVelocity () {
    int vel;
    int x = ACS_GetActorVelX (0);
    int y = ACS_GetActorVelY (0);
    int angle = ACS_VectorAngle (x, y);
    
    if (((angle + 0.125k) % 0.5k) > 0.25k)
        vel = y / ACS_Sin (angle);
    else
        vel = x / ACS_Cos (angle);
    
    return vel >> 16;
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