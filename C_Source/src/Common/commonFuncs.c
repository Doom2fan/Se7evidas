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
#include "commonFuncs.h"
#undef SHORT_NAMES

// Address spaces
__addrdef __gbl_arr global_var;
__addrdef __mod_arr    map_var;

/* Keys */
int KeyUp (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if (~buttons & key) return 1;
    
    return 0;
}
int KeyDown (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if (buttons & key) return 1;
    
    return 0;
}
int KeyPressed (int key) {
    return KeyPressed2 (GetPlayerInput (-1, INPUT_BUTTONS), GetPlayerInput (-1, INPUT_OLDBUTTONS), key);
}
int KeyPressed2 (int buttons, int oldbuttons, int key) {
    int newbuttons  = (buttons ^ oldbuttons) & buttons;

    if (newbuttons & key) return 1;
    
    return 0;
}

/* Player info */
int GetMaxStamina (PlayerData_t *player) {
    PlayerData_t *p = !player ? &PlayerData [PLN] : player;

    return 150 + 22 * p->xpSystem.agilityLVL;
}
int GetMaxMana (PlayerData_t *player) {
    PlayerData_t *p = !player ? &PlayerData [PLN] : player;

    return 250 + 37 * p->xpSystem.magicLVL;
}

/* Memory */
void *allocAndClear (size_t size) {
    int *allocMem = malloc (size);

    for (int i = 0; i < size; i++)
        allocMem [i] = 0;

    return allocMem;
}

/* Misc */
int UnusedTID (int start, int end) {
    int ret = start - 1,
        tidNum;
    if (start > end) {
        start ^= end;
        end   ^= start;
        start ^= end;
    } // good ol' XOR swap
    while (ret++ != end) {
        if (ThingCount (0, ret) == 0) return ret;
    }
    
    return -1;
}
accum GetVelocity () { // I dunno who made this...
    accum vel,
          x = GetActorVelX (0),
          y = GetActorVelY (0),
          angle = atan2A (x, y);
    
    if (((angle + 0.125k) % 0.5k) > 0.25k) vel = y / Sin (angle);
    else                                   vel = x / Cos (angle);
    
    return vel;
}
bool SetInventory (string name, int amount) {
    int currentAmount = CheckInventory (name);

    if (currentAmount == amount) return FALSE;
    else if (currentAmount > amount) TakeInventory (name, currentAmount - amount);
    else if (currentAmount < amount) GiveInventory (name, amount - currentAmount);
    
    return TRUE;
}

//-------------------------------------------------------------------------------------------
//
// Math
//
//-------------------------------------------------------------------------------------------
/* Clamping */
int Clamp (int x, int min, int max) {
    int realMin = min,
        realMax = max;
    
    if (min > max) { realMax = min; realMin = max; }
    
         if (x > realMax) return realMax;
    else if (x < realMin) return realMin;
    else                  return x;
}
accum ClampAccum (accum x, accum min, accum max) {
    accum realMin = min,
          realMax = max;
    
    if (min > max) { realMax = min; realMin = max; }
    
         if (x > realMax) return realMax;
    else if (x < realMin) return realMin;
    else                  return x;
}

/* Scaling */
int ScaleValue (int x, int fromMin, int fromMax, int toMin, int toMax) {
    return (x - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
}
accum ScaleValueAccum (accum x, accum fromMin, accum fromMax, accum toMin, accum toMax) {
    return (x - fromMin) * (toMax - toMin) / (fromMax - fromMin) + toMin;
}

/* String to value conversion */
int StrToInt (string source) {
    int    length = StrLen (source),
           ret = 0,
           j = 0;
    string strArr;
    bool   negative = FALSE;

    for (int i = length - 1; i >= 0; i--) {
        string curChar = StrMid (source, i, 1);
        
        if (i == 0 && StrCmp (curChar, s"-") == 0) {
            negative = TRUE;
        } else if (i == 0 && StrCmp (curChar, s"+") == 0) {
            negative = FALSE;
        } else {
            strArr = StrParam ("%S%S", strArr, curChar);
            j++;
        }
    }

    for (int i = 0; i < j; i++) {
        string numStr = StrMid (strArr, i, 1);
        int mul = 1, num = 0;

        for (int k = 1; k <= i; k++)
            mul *= 10;

        if (StrCmp (numStr, s"1") == 0) num = 1;
        else if (StrCmp (numStr, s"2") == 0) num = 2;
        else if (StrCmp (numStr, s"3") == 0) num = 3;
        else if (StrCmp (numStr, s"4") == 0) num = 4;
        else if (StrCmp (numStr, s"5") == 0) num = 5;
        else if (StrCmp (numStr, s"6") == 0) num = 6;
        else if (StrCmp (numStr, s"7") == 0) num = 7;
        else if (StrCmp (numStr, s"8") == 0) num = 8;
        else if (StrCmp (numStr, s"9") == 0) num = 9;
        else if (StrCmp (numStr, s"0") == 0) num = 0;
        else return 0;

        ret += (num * mul);
    }

    if (negative) ret = -ret;

    return ret;
}
bool *StrToBool (string source) {
    bool *ret;

         if (StrICmp (source, s"true")  || StrICmp (source, s"t") || StrCmp (source, s"1")) *ret = TRUE;
    else if (StrICmp (source, s"false") || StrICmp (source, s"f") || StrCmp (source, s"0")) *ret = FALSE;
    else                                                                                     ret = NULL;

    return ret;
}

/* Trigonometry */
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z,
                 accum actor2X, accum actor2Y, accum actor2Z) {
    return VectorLength (actor1Z - actor2Z, VectorLength (actor1X - actor2X, actor1Y - actor2Y));
}
vec3_k GetEulerAngles (vec3_k p1, vec3_k p2) {
    vec3_k ret;

    // Roll
    ret.x = 0.0k;
    // Pitch
    ret.y = atan2A (VectorLength (p1.x - p2.x, p1.y - p2.y), p1.z - p2.z);
    // Yaw/Angle
    ret.z = atan2A (p1.x - p2.x, p1.y - p2.y);

    return ret;
}

/* Misc */
long accum LongFixedSqrt (long accum x) {
    if (x <= 3 && x > 0) return 1.0lk;
    else if (x < 0)      return 0.0lk;

    int oldAns = x >> 1,                     // initial guess
        newAns = (oldAns + x / oldAns) >> 1; // first iteration

    // main iterative method
    while (newAns < oldAns) {
        oldAns = newAns;
        newAns = (oldAns + x / oldAns) >> 1;
    }

    return oldAns;
}
int Random2 (int x, int y) {
    return (rand () % (y + 1)) + x;
}