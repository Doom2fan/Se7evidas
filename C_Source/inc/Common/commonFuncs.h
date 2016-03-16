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

#ifndef COMMONFUNCS_H
#define COMMONFUNCS_H

#include <ACS_ZDoom.h>

// Macros
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

// Prototypes
bool S7_PlayerNumEqualConsolePlayer (int playerNum);

int KeyUp      (int key);
int KeyDown    (int key);
int KeyPressed (int key);

int UnusedTID (int start, int end);

accum GetVelocity ();

bool SetInventory (string name, int amount);

// ================ Math ================
// Clamping
int   Clamp      (int x, int min, int max);
accum ClampAccum (accum x, accum min, accum max);
// Scaling
int   ScaleValue      (int   x,   int fromMin,   int fromMax,   int toMin,   int toMax);
accum ScaleValueAccum (accum x, accum fromMin, accum fromMax, accum toMin, accum toMax);
// Distance between two XYZ coordinates
accum Distance2 (accum actor1X, accum actor1Y, accum actor1Z,
                 accum actor2X, accum actor2Y, accum actor2Z);
// String to value conversion
int   StrToInt  (string source);
bool *StrToBool (string source);

long accum LongFixedSqrt (long accum x);

#endif