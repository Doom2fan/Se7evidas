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

/* Physics */
vec3_k GetActorPositionVec (int tid) {
    vec3_k ret;

    ret.x = GetActorX (tid);
    ret.y = GetActorY (tid);
    ret.z = GetActorZ (tid);

    return ret;
}
Script_LS vec3_k GetActivatorPointerPos (int pointer) {
    SetActivator (0, pointer);
    return GetActorPositionVec (0);
}
vec5_k GetActorInfoVec (int tid) {
    vec5_k ret;

    ret.x = GetActorX (tid);
    ret.y = GetActorY (tid);
    ret.z = GetActorZ (tid);
    ret.w = GetActorProperty (0, APROP_Radius);
    ret.h = GetActorProperty (0, APROP_Height);

    return ret;
}
Script_LS vec5_k GetActivatorPointerInfo (int pointer) {
    SetActivator (0, pointer);
    return GetActorInfoVec (0);
}

/* Keys */
int KeyUp (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if ((~buttons & key) == key) return 1;

    return 0;
}
int KeyDown (int key) {
    int buttons = GetPlayerInput (-1, INPUT_BUTTONS);

    if ((buttons & key) == key) return 1;

    return 0;
}
int KeyPressed (int key) {
    return KeyPressed2 (GetPlayerInput (-1, INPUT_BUTTONS), GetPlayerInput (-1, INPUT_OLDBUTTONS), key);
}
int KeyPressed2 (int buttons, int oldbuttons, int key) {
    int newbuttons = (buttons ^ oldbuttons) & buttons;

    if ((newbuttons & key) == key) return 1;

    return 0;
}
int KeyUpMOD (int key) {
    int buttons = GetPlayerInput (-1, MODINPUT_BUTTONS);

    if ((~buttons & key) == key) return 1;

    return 0;
}
int KeyDownMOD (int key) {
    int buttons = GetPlayerInput (-1, MODINPUT_BUTTONS);

    if ((buttons & key) == key) return 1;

    return 0;
}
int KeyPressedMOD (int key) {
    if (!RunningInZandronum) {
        return KeyPressed2 (GetPlayerInput (-1, MODINPUT_BUTTONS), GetPlayerInput (-1, MODINPUT_OLDBUTTONS), key);
    } else { // This is really hacky, but a lot of the Zandrocrap fixes are anyway, heh.
        int buttonsMOD = GetPlayerInput (-1, MODINPUT_BUTTONS), oldButtonsMOD = GetPlayerInput (-1, MODINPUT_OLDBUTTONS),
        buttons = GetPlayerInput (-1, INPUT_BUTTONS);
        if (buttons != buttonsMOD && buttonsMOD == 0)
            return 0;
        else
            return KeyPressed2 (buttonsMOD, oldButtonsMOD, key);
    }
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

/* String to value conversion */
CharNibble HexToNibbleList [] = {
    { s"0", '0', (char) 0x00 }, // 0-9
    { s"1", '1', (char) 0x01 },
    { s"2", '2', (char) 0x02 },
    { s"3", '3', (char) 0x03 },
    { s"4", '4', (char) 0x04 },
    { s"5", '5', (char) 0x05 },
    { s"6", '6', (char) 0x06 },
    { s"7", '7', (char) 0x07 },
    { s"8", '8', (char) 0x08 },
    { s"9", '9', (char) 0x09 },
    { s"A", 'A', (char) 0x0A }, // A-F (Uppercase)
    { s"B", 'B', (char) 0x0B },
    { s"C", 'C', (char) 0x0C },
    { s"D", 'D', (char) 0x0D },
    { s"E", 'E', (char) 0x0E },
    { s"F", 'F', (char) 0x0F },
    { s"a", 'a', (char) 0x0A }, // a-f (Lowercase)
    { s"b", 'b', (char) 0x0B },
    { s"c", 'c', (char) 0x0C },
    { s"d", 'd', (char) 0x0D },
    { s"e", 'e', (char) 0x0E },
    { s"f", 'f', (char) 0x0F },
};

StrToIntValue StrToIntHex (string source) {
    int length = StrLen (source);
    StrToIntValue ret;
    StrToLongIntValue tmpVal = StrToLongIntHex (source);
    if (length > 8 || length <= 0 || !tmpVal.valid) { // Nibbles in a long int: 32 / 8 * 2
        ret.valid = FALSE; // Just to make sure
        ret.value = 0xBAADBEEF;
        return ret;
    }
    ret.valid = TRUE;
    ret.value = (int) tmpVal.value;
    return ret;
}

StrToLongIntValue StrToLongIntHex (string source) {
    long int val = 0;
    int j = 0, length = StrLen (source), offset = length - 1;
    bool found = FALSE;
    StrToLongIntValue ret;
    ret.valid = FALSE;
    ret.value = 0xBAADBEEF;

    if (length > 16 || length <= 0) { // Nibbles in a long int: 64 / 8 * 2
        ret.valid = FALSE; // Just to make sure
        ret.value = 0xBAADBEEF;
        return ret;
    }

    for (int i = 0; i < length; i++, offset--) {
        found = FALSE;
        for (j = 0; j < ArraySize (HexToNibbleList); j++) {
            if (StrCmp (StrMid (source, i, 1), HexToNibbleList [j].charStr) == 0) {
                val |= HexToNibbleList [j].nibble << (offset * 4);
                found = TRUE;
                break;
            }
        }
        if (found == FALSE) {
            ret.valid = FALSE; // Just to make sure
            ret.value = 0xBAADBEEF;
            return ret;
        }
    }

    ret.valid = true;
    ret.value = val;
    return ret;
}

StrToIntValue CStrToIntHex (cstr source) {
    int length = strlen (source);
    StrToIntValue ret;
    StrToLongIntValue tmpVal = CStrToLongIntHex (source);
    if (length > 8 || length <= 0 || !tmpVal.valid) { // Nibbles in a long int: 32 / 8 * 2
        ret.valid = FALSE; // Just to make sure
        ret.value = 0xBAADBEEF;
        return ret;
    }
    ret.valid = TRUE;
    ret.value = (int) tmpVal.value;
    return ret;
}
StrToLongIntValue CStrToLongIntHex (cstr source) {
    long int val = 0;
    int j = 0, length = strlen (source), offset = length - 1;
    bool found = FALSE;
    StrToLongIntValue ret;
    ret.valid = FALSE;
    ret.value = 0xBAADBEEF;

    if (length > 16 || length <= 0) { // Nibbles in a long int: 64 / 8 * 2
        ret.valid = FALSE; // Just to make sure
        ret.value = 0xBAADBEEF;
        return ret;
    }

    for (int i = 0; i < length; i++, offset--) {
        found = FALSE;
        for (j = 0; j < ArraySize (HexToNibbleList); j++) {
            if (source [i] == HexToNibbleList [j].charChar) {
                val |= HexToNibbleList [j].nibble << (offset * 4);
                found = TRUE;
                break;
            }
        }
        if (found == FALSE) {
            ret.valid = FALSE; // Just to make sure
            ret.value = 0xBAADBEEF;
            return ret;
        }
    }

    ret.valid = true;
    ret.value = val;
    return ret;
}

StrToIntValue StrToIntDec (string source) {
    int length = StrLen (source), val = 0, j = 0;
    string strArr;
    bool   negative = FALSE;
    StrToIntValue ret;

    for (int i = length - 1; i >= 0; i--) {
        string curChar = StrMid (source, i, 1);

        if (i == 0 && StrCmp (curChar, s"-") == 0)
            negative = TRUE;
        else if (i == 0 && StrCmp (curChar, s"+") == 0)
            negative = FALSE;
        else {
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
        else {
            ret.valid = false;
            ret.value = 0xBAADBEEF;
            return ret;
        }

        val += (num * mul);
    }

    if (negative) val = -val;

    ret.valid = true;
    ret.value = val;
    return ret;
}
bool *StrToBool (string source) {
    bool ret;

    if (StrICmp (source, s"true")  || StrICmp (source, s"t") || StrCmp (source, s"1"))
        ret = TRUE;
    else if (StrICmp (source, s"false") || StrICmp (source, s"f") || StrCmp (source, s"0"))
        ret = FALSE;
    else
        return NULL;

    return &ret;
}

/* Trigonometry */
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z,
                 accum actor2X, accum actor2Y, accum actor2Z) {
    return VectorLength (actor1Z - actor2Z, VectorLength (actor1X - actor2X, actor1Y - actor2Y));
}
accum Distance2Vec (vec3_k vec1, vec3_k vec2) {
    return Distance2 (vec1.x, vec1.y, vec1.z, vec2.x, vec2.y, vec2.z);
}

accum Distance2D (accum actor1X, accum actor1Y, accum actor2X, accum actor2Y) {
    return VectorLength (actor1X - actor2X, actor1Y - actor2Y);
}
accum Distance2DVec (vec2_k vec1, vec2_k vec2) {
    return Distance2D (vec1.x, vec1.y, vec2.x, vec2.y);
}
accum Distance2DTID (int tid1, int tid2) {
    return Distance2D (GetActorX (tid1), GetActorY (tid1), GetActorX (tid2), GetActorY (tid2));
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
/*bool PitchGravProjInRange (accum speed, accum grav, vec5_k sInfo, vec5_k tInfo, vec2_k pSize) {
    for (accum i = -1.0k; i <= 1.0k; i += 0.05) {
        vec2_k proj, target;
        proj.x = 0; proj.y = 0;
        target.x = Distance2D (sInfo.x, sInfo.y, tInfo.x, tInfo.y); target.y = AbsA (sInfo.z - tInfo.z);

        accum velX = speed,
              velY = speed;
        if (AbsA (proj.x - target.x) < (pSize.x / 2 + target.w / 2) && AbsA (proj.y - target.y) < (pSize.y / 2 + target.h / 2))
            return TRUE;
    }

    return FALSE;
}*/
/*bool PitchGravProjInRange (accum speed, accum grav, vec3_k p1, vec3_k p2) {
    double v = (double) speed, g = ((double) grav) * BASE_GRAVITYF;
    double x = (double) (pow (p1.x - p2.x, 2) + pow (p1.y - p2.y, 2)), y = abs ((double) (p1.z - p2.z));
    double sq = pow (v, 4) - g * (g * pow (x, 2) + 2 * y * pow (v, 2));
    
    return sq > 0.0 && !isnan (sq) && !isinf (sq);
}*/
vec2_k PitchGravProj (accum speed, accum grav, vec3_k p1, vec3_k p2) {
    long accum v = speed, g = grav * BASE_GRAVITY;
    long accum x = Distance2D (p1.x, p1.y, p2.x, p2.y), y = AbsA (p1.z - p2.z);
    vec2_k ret;

    long accum sq = PowA (v, 4) - g * (g * PowA (x, 2) + 2 * y * PowA (v, 2));
    ret.x = atanA (v * v + ((accum) LongFixedSqrt (sq)) / (g * x));
    ret.y = atanA (v * v - ((accum) LongFixedSqrt (sq)) / (g * x));

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

#undef GetUserCVar
#undef GetUserCVarFixed
#undef GetUserCVarString

int CustGetUserCVar (int num, string cvar) {
    if (RunningInZDoom)
        return GetUserCVar (num, cvar);
    else
        return GetCVar (cvar);
}

accum CustGetUserCVarFixed (int num, string cvar) {
    if (RunningInZDoom)
        return GetUserCVarFixed (num, cvar);
    else
        return GetCVarFixed (cvar);
}

string CustGetUserCVarString (int num, string cvar) {
    if (RunningInZDoom)
        return GetUserCVarString (num, cvar);
    else
        return GetCVarString (cvar);
}