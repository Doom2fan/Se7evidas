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

#ifndef INCLUDES_H
#define INCLUDES_H

// Defines/Macros
#ifdef DEBUG
    #ifdef NDEBUG
        #undef NDEBUG
    #endif
#else
    #ifndef NDEBUG
        #define NDEBUG
    #endif
#endif

//#define GetUserCVar(num, cvar) CustGetUserCVar (num, cvar)
//#define GetUserCVarFixed(num, cvar) CustGetUserCVarFixed (num, cvar)
//#define GetUserCVarString(num, cvar) CustGetUserCVarString (num, cvar)
#define PLN PlayerNumber()
// The size is actually this minus the length of "<cvar name>="
#define MAXCVARSIZ 253

// ZDoom related defines
#define TICSINSEC  35.7142
#define TICSINSECA 35.7142k
#define BASE_GRAVITY 81.92k
#define BASE_GRAVITYF 81.92f

#define TICUNIT  0.028
#define TICUNITA 0.028k

#define Gender_Male  0
#define Gender_Fem   1
#define Gender_Other 2
#define Gender_Herm  3

#define M_PIk 3.141592653589793238462643383279502884k
#define M_PI_2k 1.570796326794896619231321691639751442k

#define PlayerClass_Scout 0

#define BASEAMMOMAX 6

#define MOD_VERSION_CSTR    "0.1"
#define MOD_VERSION_STRING s"0.1"
#define MOD_VERSION_MAJOR   0
#define MOD_VERSION_MINOR   1
#define MOD_VERSION_FLOAT   MOD_VERSION_MAJOR.MOD_VERSION_MINOR

// Actor properties
#define APROP_NoTarget  19
#define APROP_NoTrigger 23

// Shop system stuff
#define CASHDIVPOINT 1000
#define CASHLESSERMAX 999
#define CASHGREATERMAX 30000
#define CASHMAXAMOUNT (CASHGREATERMAX * CASHDIVPOINT)

// Actor names
// Spriting system
#define STAMINATOKEN         s"S7_Stamina"
#define SPRINTWEAPON         s"S7_SprintWeapon"
#define SPRINTINGTOKEN       s"S7_Sprinting"
// XP System
#define XPS_LEVELTOKEN       s"S7_XP_System_Level"
#define XPS_EXPTOKEN         s"S7_XP_System_Experience"
#define XPS_ATTRPOINTSTOKEN  s"S7_XP_System_AttributePoints"
#define XPS_STRENGTHTOKEN    s"S7_Stats_System_Strength"
#define XPS_AGILITYTOKEN     s"S7_Stats_System_Agility"
#define XPS_VITALITYTOKEN    s"S7_Stats_System_Vitality"
#define XPS_DEFENSETOKEN     s"S7_Stats_System_Defense"
#define XPS_WILLTOKEN        s"S7_Stats_System_Will"
#define XPS_MAGICTOKEN       s"S7_Stats_System_Magic"
#define XPS_TECHTOKEN        s"S7_Stats_System_Technology"
// Shop system
#define CASHTOKENLESSER      s"S7_CashLesser"
#define CASHTOKENGREATER     s"S7_CashGreater"
// Weapon stuff
#define QUICKMELEEWEAPON     s"S7_QuickMelee"
// Misc
#define BERSERKTOKEN         s"S7_BerserkToken"
#define MANATOKEN            s"S7_Mana"
#define CANTEENITEM          s"S7_Canteen"
#define DYINGTOKEN           s"S7_Dying"
#define ISDEADTOKEN          s"S7_IsDead"
#define FAKEMONSTOKEN        s"S7_NotRealMonster"
#define UNDERWATERTOKEN      s"S7_IsUnderwater"
#define AIRTIMETOKEN         s"S7_AirTime"
#define DISABLEHUDTOKEN      s"S7_DisableHud"
#define MJUMP_MAXTOKEN       s"S7_MultiJump_Max"
#define SLANCE_BEAMGRABTOKEN s"S7_SoulLance_BeamGrabbed"

// Script types
#define UNLOADING    [[script ("Unloading") ]]
#define RETURN       [[script ("Return") ]]
#define RESPAWN      [[script ("Respawn") ]]
#define IS_SCRIPT(n) [[address(n), call("SScriptI")]]
#define SS_SCRIPT    [[call("SScriptS")]]
#define ACS_SS_SCRIPT EXTACS SS_SCRIPT
#define Script_CS    ACS_SS_SCRIPT
#define Script_LS    SS_SCRIPT

// Includes
#include <float.h>
#include <assert.h>
#include "common/util.h"
#include "common/util_math.h"
#include "common/types.h"
#include "common/enum.h"
#include "misc/construct.h"
#include "common/commonFuncs.h"
#include "misc/debugFuncs.h"
#ifndef SERVER_C
#include "common/server.h"
#endif
#ifndef PLAYER_C
#include "common/player.h"
#endif

// Misc
#define TNT1A0 s"TNT1A0"

// Typedefs
typedef char * cstr;

// Externs
extern bool RunningInZDoom;
extern bool RunningInZandronum;

// Prototypes
void PukeScriptFunction (int number, int arg0, int arg1, int arg2);

#endif