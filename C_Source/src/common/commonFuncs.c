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
#include "common/commonFuncs.h"
#undef SHORT_NAMES

// Address spaces
__addrdef __gbl_arr global_var;
__addrdef __mod_arr    map_var;

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
    while (ret++ != end)
        if (ThingCount (0, ret) == 0)
            return ret;

    return -1;
}
accum GetVelocity () { // I dunno who made this...
    accum vel,
          x = GetActorVelX (0),
          y = GetActorVelY (0),
          angle = atan2A (x, y);

    if (((angle + 0.125k) % 0.5k) > 0.25k) vel = y / SinA (angle);
    else                                   vel = x / CosA (angle);

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
// Text manipulation
//
//-------------------------------------------------------------------------------------------

char CorruptionCharList [] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890-=!@#$%%&*()_+[]{}\\,.;/|<>:?";

cstr CorruptText (cstr text) {
    int length = strlen (text);
    int maxChars = Random (6, length / 2);
    cstr ret = malloc (length);
    strcpy (text, ret);
    for (int i = 0; i < maxChars; i++)
        ret [Random (0, length - 2)] = CorruptionCharList [Random (0, sizeof (CorruptionCharList) - 2)];

    return ret;
}

char CaseCorruptionCharListUpper [] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
char CaseCorruptionCharListLower [] = "abcdefghijklmnopqrstuvwxyz";

cstr CorruptTextCase (cstr text) {
    return text;
    /*int length = strlen (text);
    int retLen = length + 1;
    char ret [retLen];

    ret [length + 1] = '\0';
    for (int i = 0; i < length + 1; i++) {
        ret [i] = text [i];
        if (ret [i] == '\0')
            break;

        if (Random (0, 255) > 32)
            continue;

        for (int j = 0; j < sizeof (CaseCorruptionCharListUpper); j++) {
            if (ret [i] == CaseCorruptionCharListUpper [j])
                ret [i] = CaseCorruptionCharListLower [j];
            else if (ret [i] == CaseCorruptionCharListLower [j])
                ret [i] = CaseCorruptionCharListUpper [j];
        }
    }

    return (cstr) &ret;*/
}

//-------------------------------------------------------------------------------------------
//
// Math
//
//-------------------------------------------------------------------------------------------
/* Basic functions that ZDoom doesn't have for some reason */
#define CPow_Impl(exp) for (int i = 1; i < exp; i++) { ret *= x; }
int PowI (int x, int y) {
    int ret = x;

    if (y == 0) {
        assert (x != 0);
        ret = 1.0k;
    } else if (y < 0) {
        CPow_Impl (abs (y));
        ret = 1.0k / ret;
    } else {
        CPow_Impl (y);
    }

    return ret;
}
accum PowA (accum x, int y) {
    accum ret = x;

    if (y == 0) {
        assert (x != 0);
        ret = 1.0k;
    } else if (y < 0) {
        CPow_Impl (AbsA (y));
        ret = 1.0k / ret;
    } else {
        CPow_Impl (y);
    }

    return ret;
}

/* Min/max */
int Min (int a, int b) {
    return a < b ? b : a;
}
int Max (int a, int b) {
    return a < b ? a : b;
}

/* Clamping */
int Clamp (int x, int min, int max) {
    if (min > max) {
        min ^= max;
        max ^= min;
        min ^= max;
    }

         if (x > max) return max;
    else if (x < min) return min;
    else              return x;
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

/* Trigonometry */
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z,
                 accum actor2X, accum actor2Y, accum actor2Z) {
    return VectorLength (actor1Z - actor2Z, VectorLength (actor1X - actor2X, actor1Y - actor2Y));
}

accum Distance2D (accum actor1X, accum actor1Y, accum actor2X, accum actor2Y) {
    return VectorLength (actor1X - actor2X, actor1Y - actor2Y);
}
accum Distance2DTID (int tid1, int tid2) {
    return Distance2D (GetActorX (tid1), GetActorY (tid1), GetActorX (tid2), GetActorY (tid2));
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