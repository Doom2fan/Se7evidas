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

#ifndef COMMONFUNCS_H
#define COMMONFUNCS_H

#include <ACS_ZDoom.h>
#include "includes.h"

typedef char * cstr;

typedef struct StrToIntValue {
    bool valid;
    int value;
} StrToIntValue;

typedef struct StrToLongIntValue {
    bool valid;
    long int value;
} StrToLongIntValue;

typedef struct CharNibble {
    char character;
    char nibble;
} CharNibble;

// Macros
#define atanA(x) VectorAngle (1.0k, x)
#define atan2A(x, y) VectorAngle (x, y)

#define TicsToSecs(tics) (TICUNITA * tics)

#define SetInventoryForced(name, amount) \
( \
 TakeInventory (name, 0x7FFFFFFF), \
 GiveInventory (name, amount) \
)

#define FormatStr(strIn, format, ...) \
( \
 vsprintf ((char *) strIn, (char const *) format, __VA_ARGS__) \
)

#define ArraySize(array) sizeof (array) / sizeof (*array)

#define BoundsCheck(var, min, max) (var >= min && var < max)

// Accum-float conversion
#define FloatToAccum(f)      ((accum) ((f) * (65536)))
#define AccumToFloat(f)      (((float)  f) / (65536.0f))
#define AccumToDouble(f)     (((double) f) / (65536.0))
// Long accum-float conversion
#define FloatToLongAccum(f)      ((long accum) ((f) * (4294967296)))
#define LongAccumToFloat(f)      (((float)  f) / (4294967296.0f))
#define LongAccumToDouble(f)     (((double) f) / (4294967296.0))

// Externs
__addrdef extern __gbl_arr global_var;
__addrdef extern __mod_arr    map_var;
extern char CorruptionCharList [];
extern CharNibble HexToNibbleList [];

// Prototypes
/* Physics */
vec3_k GetActorPositionVec (int tid);
Script_LS vec3_k GetActivatorPointerPos (int pointer);
vec5_k GetActorInfoVec (int tid);
Script_LS vec5_k GetActivatorPointerInfo (int pointer);
/* Keys */
// Up/Down
bool KeyUp          (int key);
bool KeyDown        (int key);
// Pressed/Released
bool KeyPressed     (int key);
bool KeyPressed2    (int buttons, int oldbuttons, int key);
bool KeyReleased    (int key);
bool KeyReleased2   (int buttons, int oldbuttons, int key);
/* Keys (MOD versions) */
// Up/Down
bool KeyUpMOD       (int key);
bool KeyDownMOD     (int key);
// Pressed/Released
bool KeyPressedMOD  (int key);
bool KeyReleasedMOD (int key);
/* Player info */
bool S7_PlayerNumEqualConsolePlayer (int playerNum);
int  GetMaxStamina (struct PlayerData_t *player);
int  GetMaxMana    (struct PlayerData_t *player);
/* Memory */
void *allocAndClear (size_t size);
/* Misc */
int   UnusedTID (int start, int end);
accum GetVelocity ();
bool  SetInventory (string name, int amount);

// ================ Text Manipulation ================
cstr CorruptText (cstr text);
cstr CorruptTextCase (cstr text);

// ================ Math ================
/* Basic functions that ZDoom doesn't have for some reason */
int   PowI (int   x, int y);
accum PowA (accum x, int y);
/* Min/max */
int Min (int a, int b);
int Max (int a, int b);
/* Clamping */
int   Clamp      (int x, int min, int max);
accum ClampAccum (accum x, accum min, accum max);
/* Scaling */
int   ScaleValue      (int   x,   int fromMin,   int fromMax,   int toMin,   int toMax);
accum ScaleValueAccum (accum x, accum fromMin, accum fromMax, accum toMin, accum toMax);
/* String to value conversion */
StrToIntValue  StrToIntHex (char __str_ars const *restrict source); // int
StrToIntValue CStrToIntHex (cstr   source);
StrToLongIntValue  StrToLongIntHex (char __str_ars const *restrict source); // long int
StrToLongIntValue CStrToLongIntHex (cstr   source);
StrToIntValue StrToIntDec (string source);
bool *StrToBool (string source);
/* Trigonometry */
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z, // Distance between two XYZ coordinates
                 accum actor2X, accum actor2Y, accum actor2Z);
accum Distance2Vec (vec3_k vec1, vec3_k vec2);
accum Distance2D (accum actor1X, accum actor1Y, accum actor2X, accum actor2Y); // Distance between two XY coordinates
accum Distance2DVec (vec2_k vec1, vec2_k vec2);
accum Distance2DTID (int tid1, int tid2);
vec3_k GetEulerAngles (vec3_k p1, vec3_k p2); // Euler angles as a vec3
// bool InterceptShotPitchInRange (accum speed, accum grav, vec3_k p1, vec3_k p2);
bool InterceptShotPitch (accum speed, accum grav, vec3_k p1, vec3_k p2, vec2_k *ret); // Gets the pitch a projectile needs to be fired at from p1 to hit p2 while accounting for gravity
bool InterceptShotPosition (vec2_k sPos, vec2_k tPos, vec2_k tVel, double sProjectile, vec2_k *solution); // Gets the position a project needs to be fired at from sPos to hit tPos while accounting for velocity
/* Misc */
long accum LongFixedSqrt (long accum x);
int Random2 (int x, int y);

// This is just for zandro compat or something
int CustGetUserCVar (int num, string cvar);
accum CustGetUserCVarFixed (int num, string cvar);
string CustGetUserCVarString (int num, string cvar);

#endif