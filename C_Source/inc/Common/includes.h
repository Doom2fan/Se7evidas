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

#ifndef INCLUDES_H
#define INCLUDES_H

// Includes
#include "util.h"
#include "util_math.h"
#include "commonFuncs.h"
#include "enum.h"
#ifndef SERVER_C
#include "server.h"
#endif
#ifndef PLAYER_C
#include "player.h"
#endif

// Defines/Macros
#define PLN PlayerNumber()
// The size is actually this minus the length of "<cvar name>="
#define MAXCVARSIZ 253

#define TICSINSEC 35.7142
#define TICSINSECA 35.7142k

#define TICUNIT 0.028
#define TICUNITA 0.028k

#define Gender_Male  0
#define Gender_Fem   1
#define Gender_Other 2
#define Gender_Herm  3

#define BASEAMMOMAX 6

// Actor names
// Spriting system
#define STAMINATOKEN s"S7_Stamina"
#define SPRINTWEAPON s"S7_SprintWeapon"
#define SPRINTINGTOKEN s"S7_Sprinting"
// XP System
#define XPS_LEVELTOKEN s"S7_XP_System_Level"
#define XPS_EXPTOKEN s"S7_XP_System_Experience"
#define XPS_ATTRPOINTSTOKEN s"S7_XP_System_AttributePoints"
#define XPS_STRENGTHTOKEN s"S7_Stats_System_Strength"
#define XPS_STAMINATOKEN s"S7_Stats_System_Stamina"
// Shop system
#define CASHTOKEN s"S7_Cash"
// Weapon stuff
#define QUICKMELEEWEAPON s"S7_QuickMelee"
// Misc
#define DYINGTOKEN s"S7_Dying"
#define UNDERWATERTOKEN s"S7_IsUnderwater"
#define AIRTIMETOKEN s"S7_AirTime"
#define MJUMP_MAXTOKEN s"S7_MultiJump_Max"

// Script types
#define UNLOADING [[script ("Unloading") ]]
#define RETURN [[script ("Return") ]]
#define RESPAWN [[script ("Respawn") ]]

__addrdef extern  __gbl_arr GlobalVar;

// Misc
#define TNT1A0 s"TNT1A0"

#endif