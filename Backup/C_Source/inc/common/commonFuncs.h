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

#ifdef DEBUG
#define DebugLog(...) Log (__VA_ARGS__)
#else
#define DebugLog(...) 
#endif

// Accum-float conversion
#define FloatToAccum(f)      ((accum) ((f) * (65536)))
#define AccumToFloat(f)      (((float)  f) / (65536.0f))
#define AccumToDouble(f)     (((double) f) / (65536.0))
// Long accum-float conversion
#define FloatToLongAccum(f)      ((long accum) ((f) * (4294967296)))
#define LongAccumToFloat(f)      (((float)  f) / (4294967296.0f))
#define LongAccumToDouble(f)     (((double) f) / (4294967296.0))

// CVar checking
#define CheckCheats() (GameType () == GAME_SINGLE_PLAYER || ((GameType () & (GAME_NET_COOPERATIVE | GAME_NET_DEATHMATCH)) != 0 && GetCVar (s"sv_cheats")))

// Externs
__addrdef extern __gbl_arr global_var;
__addrdef extern __mod_arr    map_var;
extern char CorruptionCharList [];

// Prototypes
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
/* Trigonometry */
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z, // Distance between two XYZ coordinates
                 accum actor2X, accum actor2Y, accum actor2Z);
accum Distance2D (accum actor1X, accum actor1Y, accum actor2X, accum actor2Y); // Distance between two XY coordinates
accum Distance2DTID (int tid1, int tid2);
/* Misc */
long accum LongFixedSqrt (long accum x);
int Random2 (int x, int y);

#endif